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
    inv_phi <- 1 / sample$phi
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
