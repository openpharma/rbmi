#' Impute missing count outcomes
#'
#' For count outcomes, missing period-3 counts are sampled from their conditional
#' negative binomial distribution given the observed period-1 and period-2
#' counts. The model uses the dispersion parameterisation
#' `Var(Y) = mu + phi * mu^2`.
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
#' @keywords internal
prepare_count_imputation_data <- function(data, references, strategy_by_id) {
    vars <- data$vars
    dat <- data$data
    id <- as.character(dat[[vars$subjid]])
    period <- as.character(dat[[vars$period]])
    duration <- dat[[vars$duration]]
    outcome <- dat[[vars$outcome]]
    is_missing <- is.na(outcome)

    assert_that(
        identical(data$periods, valid_periods()),
        all(duration[period %in% c("1", "2") & is_missing] == 0),
        all(period[duration > 0 & is_missing] == "3"),
        msg = paste(
            "For count outcomes, positive-duration missing values are only",
            "supported in period 3"
        )
    )

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
    use_reference_observed <- strategy == "CR" & period %in% c("1", "2")
    use_reference_missing <- strategy %in% c("JR", "CR") & period == "3"
    design_observed <- design_own
    design_missing <- design_own
    design_observed[use_reference_observed, ] <-
        design_reference[use_reference_observed, , drop = FALSE]
    design_missing[use_reference_missing, ] <-
        design_reference[use_reference_missing, , drop = FALSE]

    list(
        id = id,
        subject_ids = data$ids,
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
#' @keywords internal
sample_count_outcomes <- function(prepared, sample) {
    validate(sample)
    assert_that(
        length(sample$beta) == ncol(prepared$design_observed),
        msg = "The count-model coefficient draw is incompatible with the design matrix"
    )

    observed_period <- prepared$period %in% c("1", "2")
    observed_available <- observed_period & !prepared$is_missing
    missing_period <- prepared$period == "3" & prepared$is_missing
    needs_random_draw <- missing_period & prepared$duration > 0

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
    observed_count_total <- rowsum(
        observed_count,
        group = prepared$id,
        reorder = FALSE
    )[, 1]
    observed_mu_total <- rowsum(
        mu_observed,
        group = prepared$id,
        reorder = FALSE
    )[, 1]

    missing_rows <- which(needs_random_draw)[
        match(prepared$subject_ids, prepared$id[needs_random_draw])
    ]
    subjects_to_impute <- !is.na(missing_rows)
    phi_group <- ifelse(
        prepared$strategy[missing_rows[subjects_to_impute]] %in% c("JR", "CR"),
        prepared$reference_group[missing_rows[subjects_to_impute]],
        prepared$own_group[missing_rows[subjects_to_impute]]
    )
    if (length(sample$phi) == 1) {
        inv_phi <- rep(1 / sample$phi, sum(subjects_to_impute))
    } else {
        assert_that(
            all(phi_group %in% names(sample$phi)),
            msg = "The count-model dispersion draws do not cover all required treatment groups"
        )
        inv_phi <- 1 / unname(sample$phi[phi_group])
    }
    size <- inv_phi + observed_count_total[subjects_to_impute]
    missing_mu <- mu_missing[missing_rows[subjects_to_impute]]
    conditioning_mass <- inv_phi + observed_mu_total[subjects_to_impute]
    prob <- conditioning_mass / (conditioning_mass + missing_mu)

    assert_that(
        all(is.finite(size)),
        all(size > 0),
        all(is.finite(prob)),
        all(prob > 0 & prob <= 1),
        msg = "Invalid conditional negative binomial parameters"
    )

    result <- numeric(length(prepared$id))
    result[needs_random_draw] <- stats::rnbinom(
        n = sum(subjects_to_impute),
        size = size,
        prob = prob
    )
    result
}
