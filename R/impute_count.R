#' Impute missing count outcomes
#'
#' For count outcomes, missing positive-duration cells are sampled sequentially
#' from their conditional negative binomial distributions given the observed
#' cells and any previously imputed cells for the same subject. Missing cells
#' are visited in period-factor level order. The model uses the dispersion
#' parameterisation `Var(Y) = mu + phi * mu^2`.
#'
#' @rdname impute
#' @export
impute.draws_count <- function(
    draws,
    references = NULL,
    update_strategy = NULL,
    strategies = getStrategies()
) {
    validate(draws)

    assert_that(
        is.null(update_strategy),
        msg = "`update_strategy` is not currently supported for count outcomes"
    )

    data <- draws$data$clone(deep = TRUE)
    strategy_by_id <- unlist(data$strategies, use.names = TRUE)
    supported_strategies <- c("MAR", "JR", "CR")
    unsupported <- setdiff(unique(strategy_by_id), supported_strategies)
    assert_that(
        length(unsupported) == 0,
        msg = sprintf(
            "Count outcomes currently support the following imputation strategies: %s",
            paste0("`", supported_strategies, "`", collapse = ", ")
        )
    )

    if (is.null(references)) {
        assert_that(
            all(strategy_by_id == "MAR"),
            msg = paste(
                "You have set a non-MAR imputation strategy.",
                "Please specify the references using the argument `references`"
            )
        )
        references <- levels(data$data[[data$vars$group]])
        names(references) <- references
    }
    references <- add_class(references, "references")
    validate(references, data$data[[data$vars$group]])

    groups_by_id <- vapply(data$group, as.character, character(1))
    assert_that(
        all(groups_by_id %in% names(references)),
        msg = "`references` must provide a mapping for every treatment group"
    )

    prepared <- prepare_count_imputation_data(
        data = data,
        references = references,
        strategy_by_id = strategy_by_id
    )

    imputations <- lapply(draws$samples, function(sample) {
        imputed_values <- sample_count_outcomes(prepared, sample)
        imputation_df(lapply(sample$ids, function(id) {
            subject_rows <- prepared$id == id
            imputation_single(
                id = id,
                values = imputed_values[subject_rows & prepared$is_missing]
            )
        }))
    })
    imputations <- do.call(imputation_list_df, imputations)

    result <- as_imputation(
        imputations = imputations,
        data = data,
        method = draws$method,
        references = references
    )
    class(result) <- c("imputation_count", class(result))
    validate(result)
    result
}


#' @describeIn print.imputation Print the number of patients with positive
#'   duration in each period for count endpoints. Zero-duration rows are
#'   structural placeholders and are not counted.
#' @export
print.imputation_count <- function(x, ...) {
    data <- x$data$data
    vars <- x$data$vars
    periods <- x$data$periods
    period <- as.character(data[[vars$period]])
    duration <- data[[vars$duration]]
    subjid <- data[[vars$subjid]]

    n_patients <- vapply(
        periods,
        function(current_period) {
            rows <- period == current_period & duration > 0
            length(unique(subjid[rows]))
        },
        integer(1)
    )
    width <- max(nchar(periods))
    period_strings <- sprintf(
        paste0("%-", width, "s: %s"),
        periods,
        n_patients
    )

    ref_from <- names(x$references)
    ref_to <- x$references
    width <- max(nchar(ref_from))
    ref_strings <- sprintf(
        paste0("%-", width, "s -> %s"),
        ref_from,
        ref_to
    )

    n_imp <- length(x$imputations)
    n_imp_string <- ife(
        has_class(x$method, "condmean"),
        sprintf("1 + %s", n_imp - 1),
        as.character(n_imp)
    )

    string <- c(
        "",
        "Imputation Object",
        "-----------------",
        sprintf("Number of Imputed Datasets: %s", n_imp_string),
        "Endpoint Type: count",
        "Number of Patients with Positive Duration by Period:",
        sprintf("    %s", period_strings),
        "References:",
        sprintf("    %s", ref_strings),
        ""
    )

    cat(string, sep = "\n")
    return(invisible(x))
}


#' Prepare fixed inputs for conditional count imputation
#'
#' @param data A `longdata` object containing the original count data and model
#'   formula.
#' @param references A validated named reference-group mapping.
#' @param strategy_by_id A named character vector containing one imputation
#'   strategy per subject.
#'
#' @return A list of row-aligned observed and missing design matrices, outcome
#'   and duration values, subject indices, treatment groups, references, and
#'   imputation strategies used by [sample_count_outcomes()].
#'
#' @keywords internal
prepare_count_imputation_data <- function(data, references, strategy_by_id) {
    vars <- data$vars
    dat <- data$data
    id <- as.character(dat[[vars$subjid]])
    period <- as.character(dat[[vars$period]])
    duration <- dat[[vars$duration]]
    outcome <- dat[[vars$outcome]]
    is_missing <- is.na(outcome)

    subject_index <- match(id, data$ids)
    assert_that(!anyNA(subject_index))

    design_own <- as.matrix(as_model_df(dat, data$formula)[, -1, drop = FALSE])
    dat_reference <- dat
    reference_group <- unname(references[as.character(dat[[vars$group]])])
    own_group <- as.character(dat[[vars$group]])
    dat_reference[[vars$group]] <- factor(
        reference_group,
        levels = levels(dat[[vars$group]])
    )
    design_reference <- as.matrix(
        as_model_df(dat_reference, data$formula)[, -1, drop = FALSE]
    )

    strategy <- unname(strategy_by_id[id])
    use_reference_observed <- strategy == "CR" & !is_missing
    use_reference_missing <- strategy %in% c("JR", "CR") & is_missing
    design_observed <- design_own
    design_missing <- design_own
    design_observed[use_reference_observed, ] <-
        design_reference[use_reference_observed, , drop = FALSE]
    design_missing[use_reference_missing, ] <-
        design_reference[use_reference_missing, , drop = FALSE]

    list(
        id = id,
        subject_ids = data$ids,
        subject_index = subject_index,
        period = period,
        duration = duration,
        outcome = outcome,
        is_missing = is_missing,
        own_group = own_group,
        reference_group = reference_group,
        strategy = strategy,
        design_observed = design_observed,
        design_missing = design_missing
    )
}


#' Sample missing counts for one posterior parameter draw
#'
#' @param prepared The fixed imputation inputs returned by
#'   [prepare_count_imputation_data()].
#' @param sample A `sample_single_count` posterior draw containing regression
#'   coefficients and dispersion parameters.
#'
#' @return A numeric vector aligned with the rows of `prepared`. Observed rows
#'   contain zero, zero-duration missing rows contain zero, and
#'   positive-duration missing rows contain the sampled counts.
#'
#' @keywords internal
sample_count_outcomes <- function(prepared, sample) {
    validate(sample)
    assert_that(
        length(sample$beta) == ncol(prepared$design_observed),
        msg = "The count-model coefficient draw is incompatible with the design matrix"
    )

    observed_available <- !prepared$is_missing & prepared$duration > 0
    needs_random_draw <- prepared$is_missing & prepared$duration > 0

    mu_observed <- numeric(length(prepared$id))
    mu_observed[observed_available] <- prepared$duration[observed_available] * exp(
        prepared$design_observed[observed_available, , drop = FALSE] %*%
            sample$beta
    )
    mu_missing <- numeric(length(prepared$id))
    mu_missing[needs_random_draw] <- prepared$duration[needs_random_draw] * exp(
        prepared$design_missing[needs_random_draw, , drop = FALSE] %*%
            sample$beta
    )

    observed_count <- ifelse(observed_available, prepared$outcome, 0)
    sum_by_subject <- function(x) {
        totals <- numeric(length(prepared$subject_ids))
        grouped <- rowsum(x, prepared$subject_index, reorder = FALSE)
        totals[as.integer(rownames(grouped))] <- grouped[, 1]
        totals
    }
    observed_count_total <- sum_by_subject(observed_count)
    observed_mu_total <- sum_by_subject(mu_observed)

    result <- numeric(length(prepared$id))
    missing_rows_by_subject <- split(
        which(needs_random_draw),
        factor(
            prepared$subject_index[needs_random_draw],
            levels = seq_along(prepared$subject_ids)
        ),
        drop = TRUE
    )

    for (missing_rows in missing_rows_by_subject) {
        subject <- prepared$subject_index[missing_rows[1]]
        phi_group <- ife(
            prepared$strategy[missing_rows[1]] %in% c("JR", "CR"),
            prepared$reference_group[missing_rows[1]],
            prepared$own_group[missing_rows[1]]
        )
        if (length(sample$phi) == 1) {
            inv_phi <- 1 / sample$phi
        } else {
            assert_that(
                phi_group %in% names(sample$phi),
                msg = paste(
                    "The count-model dispersion draws do not cover all",
                    "required treatment groups"
                )
            )
            inv_phi <- 1 / unname(sample$phi[phi_group])
        }

        size <- inv_phi + observed_count_total[subject]
        conditioning_mass <- inv_phi + observed_mu_total[subject]
        for (missing_row in missing_rows) {
            prob <- conditioning_mass /
                (conditioning_mass + mu_missing[missing_row])
            assert_that(
                is.finite(size),
                size > 0,
                is.finite(prob),
                prob > 0 & prob <= 1,
                msg = "Invalid conditional negative binomial parameters"
            )
            draw <- stats::rnbinom(1, size = size, prob = prob)
            result[missing_row] <- draw
            size <- size + draw
            conditioning_mass <- conditioning_mass + mu_missing[missing_row]
        }
    }
    result
}
