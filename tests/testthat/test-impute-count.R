suppressPackageStartupMessages({
    library(testthat)
})


make_count_draws <- function(strategy = "JR") {
    dat <- data.frame(
        id = factor(
            rep(c("control", "active"), each = 3),
            levels = c("control", "active")
        ),
        period = rep(as.character(1:3), 2),
        duration = c(1, 1, 1, 1, 1, 1),
        outcome = c(2, 3, NA, 1, 2, NA),
        group = factor(
            rep(c("Control", "Active"), each = 3),
            levels = c("Control", "Active")
        )
    )
    vars <- set_vars(
        subjid = "id",
        period = "period",
        duration = "duration",
        outcome = "outcome",
        group = "group"
    )
    longdata <- longDataConstructor$new(dat, vars)
    longdata$set_strategies(data.frame(
        id = "active",
        strategy = strategy
    ))

    sample <- sample_single_count(
        ids = longdata$ids,
        beta = c(log(2), log(2)),
        phi = 0.5
    )
    result <- as_draws(
        method = method_bayes(n_samples = 1),
        samples = sample_list(sample),
        data = longdata,
        formula = longdata$formula
    )
    class(result) <- c("draws_count", class(result))
    result
}


test_that("count imputation samples the conditional negative binomial", {
    draws <- make_count_draws("JR")
    references <- c("Control" = "Control", "Active" = "Control")

    set.seed(731)
    expected <- stats::rnbinom(
        n = 2,
        size = c(2 + 5, 2 + 3),
        prob = c(
            (2 + 4) / (2 + 4 + 2),
            (2 + 8) / (2 + 8 + 2)
        )
    )
    set.seed(731)
    result <- impute(draws, references)
    completed <- extract_imputed_dfs(result)[[1]]

    expect_s3_class(result, "imputation_count")
    expect_equal(
        completed$outcome[completed$period == "3"],
        expected
    )
    expect_true(all(completed$outcome == trunc(completed$outcome)))
})


test_that("CR uses reference means for the conditioning periods", {
    draws <- make_count_draws("CR")
    references <- c("Control" = "Control", "Active" = "Control")
    prepared <- prepare_count_imputation_data(
        data = draws$data,
        references = add_class(references, "references"),
        strategy_by_id = unlist(draws$data$strategies)
    )

    set.seed(902)
    expected <- stats::rnbinom(
        n = 2,
        size = c(2 + 5, 2 + 3),
        prob = c(
            (2 + 4) / (2 + 4 + 2),
            (2 + 4) / (2 + 4 + 2)
        )
    )
    set.seed(902)
    actual <- sample_count_outcomes(prepared, draws$samples[[1]])

    expect_equal(actual[prepared$period == "3"], expected)
})


test_that("zero-duration missing count cells are completed with zero", {
    draws <- make_count_draws("JR")
    period_two_active <-
        draws$data$data$id == "active" & draws$data$data$period == "2"
    draws$data$data$duration[period_two_active] <- 0
    draws$data$data$outcome[period_two_active] <- NA
    draws$data$values$active[2] <- NA
    draws$data$is_missing$active[2] <- TRUE

    result <- impute(
        draws,
        c("Control" = "Control", "Active" = "Control")
    )
    completed <- extract_imputed_dfs(result)[[1]]

    expect_equal(completed$outcome[completed$duration == 0], 0)
})


test_that("count imputation validates references and supported strategies", {
    expect_error(
        impute(make_count_draws("JR")),
        "specify the references"
    )
    expect_error(
        impute(
            make_count_draws("CIR"),
            c("Control" = "Control", "Active" = "Control")
        ),
        "currently support"
    )
})
