suppressPackageStartupMessages({
    library(dplyr)
    library(testthat)
    library(tibble)
})

n <- 10
nv <- 3

covars <- tibble(
    subjid = 1:n,
    age = rnorm(n),
    group = factor(
        sample(c("A", "B"), size = n, replace = TRUE),
        levels = c("A", "B")
    ),
    sex = factor(
        sample(c("M", "F"), size = n, replace = TRUE),
        levels = c("M", "F")
    ),
    strata = c("A", "A", "A", "A", "A", "A", "A", "A", "B", "B")
)

dat <- tibble(
    subjid = rep.int(1:n, nv)
) %>%
    left_join(covars, by = "subjid") %>%
    mutate(
        outcome = rnorm(
            n(),
            age * 3 + (as.numeric(sex) - 1) * 3 + (as.numeric(group) - 1) * 4,
            sd = 3
        )
    ) %>%
    arrange(subjid) %>%
    group_by(subjid) %>%
    mutate(visit = factor(paste0("Visit ", seq_len(n())))) %>%
    ungroup() %>%
    mutate(subjid = factor(subjid))

dat[c(1, 2, 3, 4, 5, 7), "outcome"] <- NA


vars <- set_vars(
    outcome = "outcome",
    visit = "visit",
    subjid = "subjid",
    group = "group",
    strata = "strata",
    strategy = "strategy",
    covariates = c("sex", "age")
)

dat_period <- dat %>%
    mutate(
        period = factor(as.integer(visit)),
        duration = rep(c(2, 0, 1), times = n)
    )

vars_period <- set_vars(
    outcome = "outcome",
    period = "period",
    duration = "duration",
    subjid = "subjid",
    group = "group",
    strata = "strata",
    strategy = "strategy",
    covariates = c("sex", "age")
)


make_period_review_data <- function() {
    data.frame(
        id = factor(rep(c("a", "b"), each = 3)),
        group = factor(
            rep(c("Control", "Active"), each = 3),
            levels = c("Control", "Active")
        ),
        period = rep(c(2, 6, 12), 2),
        duration = 1,
        outcome = c(3, 4, NA, 4, 5, NA)
    )
}


test_that("numeric periods are rejected and a separate numeric trend is preserved", {
    withr::local_options(contrasts = c("contr.treatment", "contr.poly"))
    data <- make_period_review_data()
    vars <- set_vars(
        subjid = "id", period = "period", duration = "duration", covariates = "period"
    )

    expect_error(
        longDataConstructor$new(data, vars),
        "Variable `period` should be of type factor"
    )

    data$time <- data$period
    data$period <- factor(data$period, levels = c(2, 6, 12))
    vars$covariates <- "time"
    ld <- longDataConstructor$new(data, vars)
    design <- as_model_df(ld$data, ld$formula)[, -1, drop = FALSE]
    expect_identical(
        model_term_names(ld$data, ld$formula),
        c("(Intercept)", "groupActive", "time")
    )
    # Period 12 has no observed counts, but the time trend is identifiable.
    stan_data <- prepare_stan_data_count(
        design, ld$data$id, ld$data$duration, ld$data$outcome, ld$data$group,
        same_cov = TRUE
    )
    expect_equal(stan_data$P, 3)

    completed <- ld$get_data(imputation_df(
        imputation_single(id = "a", values = 5),
        imputation_single(id = "b", values = 6)
    ))
    expect_identical(completed$time, rep(c(2, 6, 12), 2))
    expect_identical(completed$time >= 6, rep(c(FALSE, TRUE, TRUE), 2))
})


test_that("period factors retain custom contrasts and ordered status", {
    withr::local_options(contrasts = c("contr.treatment", "contr.poly"))
    data <- make_period_review_data()
    vars <- set_vars(
        subjid = "id", period = "period", duration = "duration", covariates = "period"
    )

    for (ordered in c(FALSE, TRUE)) {
        data$period <- factor(data$period, levels = c(2, 6, 12), ordered = ordered)
        stats::contrasts(data$period, how.many = 1) <-
            stats::contr.poly(3)[, 1, drop = FALSE]

        ld <- longDataConstructor$new(data, vars)
        expect_identical(ld$get_data()$period, data$period)
        expect_identical(
            model_term_names(ld$get_data(), ld$formula),
            c("(Intercept)", "groupActive", "period.L")
        )

        completed <- ld$get_data(imputation_df(
            imputation_single(id = "a", values = 5),
            imputation_single(id = "b", values = 6)
        ))
        expect_identical(completed$period, data$period)
    }
})


test_that("character periods require explicit factor order in ragged data", {
    data <- make_period_review_data()
    data$period <- rep(c("1", "2", "10"), 2)
    data <- data[c(6, 3, 4, 2, 1), ]
    vars <- set_vars(subjid = "id", period = "period", duration = "duration")

    expect_error(
        longDataConstructor$new(data, vars),
        "Variable `period` should be of type factor"
    )

    data$period <- factor(data$period, levels = c("1", "2", "10"))
    ld <- longDataConstructor$new(data, vars)
    expect_identical(ld$periods, c("1", "2", "10"))
    expect_identical(as.character(ld$get_data()$period), c("1", "2", "10", "1", "10"))
})


test_that("extract_covariates", {
    expect_equal(extract_covariates("age"), "age")
    expect_equal(extract_covariates(c("age", "sex")), c("age", "sex"))
    expect_equal(extract_covariates(c("age:sex")), c("age", "sex"))
    expect_equal(extract_covariates(c("age*sex")), c("age", "sex"))
    expect_equal(extract_covariates(c("age", "age*sex")), c("age", "sex"))
    expect_equal(extract_covariates(c("age", " age*sex ")), c("age", "sex"))
    expect_equal(extract_covariates(c("age", " age *sex ")), c("age", "sex"))
    expect_equal(extract_covariates(c("age", " age * sex")), c("age", "sex"))
    expect_equal(extract_covariates(c("age", " age :   sex ")), c("age", "sex"))
    expect_equal(extract_covariates(""), character(0))
})


test_that("validate.ivars", {
    expect_true(validate(vars))
    expect_true(validate(vars_period))

    expect_error(
        set_vars(period = "period"),
        "`vars\\$duration`"
    )

    expect_error(
        set_vars(visit = "visit", period = "period", duration = "duration"),
        "Only one of `visit` and `period`"
    )

    vars2 <- vars
    vars2$subjid <- NULL
    expect_error(validate(vars2))

    vars2 <- vars
    vars2$outcome <- NULL
    expect_error(validate(vars2))

    vars2 <- vars
    vars2$group <- NULL
    expect_error(validate(vars2))

    vars2 <- vars
    vars2$visit <- NULL
    expect_error(validate(vars2))

    vars2 <- vars_period
    vars2$duration <- NULL
    expect_error(validate(vars2))

    vars2 <- vars_period
    vars2$duration <- c("duration", "duration2")
    expect_error(validate(vars2))

    vars2 <- vars
    vars2$strata <- 1
    expect_error(validate(vars2))

    vars2 <- vars
    vars2$strata <- NULL
    expect_true(validate(vars2))

    vars2 <- vars
    vars2$covariates <- 1
    expect_error(validate(vars2))

    vars2 <- vars
    vars2$covariates <- NULL
    expect_true(validate(vars2))

    vars2 <- vars
    vars2$subjid <- c("v1", "v2")
    expect_error(validate(vars2))
})


test_that("validate_datalong_varExists", {
    expect_true(validate_datalong_varExists(dat, vars))
    expect_true(validate_datalong_varExists(dat_period, vars_period))

    dat2 <- dat
    dat2$subjid <- NULL
    expect_error(validate_datalong_varExists(dat2, vars))

    dat2 <- dat
    dat2$age <- NULL
    expect_error(validate_datalong_varExists(dat2, vars))

    dat2 <- dat
    dat2$group <- NULL
    expect_error(validate_datalong_varExists(dat2, vars))

    dat2 <- dat
    dat2$sex <- NULL
    expect_error(validate_datalong_varExists(dat2, vars))

    dat2 <- dat
    dat2$strata <- NULL
    expect_error(validate_datalong_varExists(dat2, vars))

    dat2 <- dat
    dat2$outcome <- NULL
    expect_error(validate_datalong_varExists(dat2, vars))

    dat2 <- dat
    dat2$visit <- NULL
    expect_error(validate_datalong_varExists(dat2, vars))

    dat2 <- dat_period
    dat2$duration <- NULL
    expect_error(validate_datalong_varExists(dat2, vars_period))
})


test_that("validate_datalong_types", {
    expect_true(validate_datalong_types(dat, vars))
    expect_true(validate_datalong_types(dat_period, vars_period))

    dat2 <- dat
    dat2$subjid <- rnorm(nrow(dat))
    expect_error(validate_datalong_types(dat2, vars))

    dat2 <- dat
    dat2$subjid <- as.character(dat$subjid)
    expect_error(validate_datalong_types(dat2, vars))

    dat2 <- dat
    dat2$subjid <- factor(dat$subjid)
    expect_true(validate_datalong_types(dat2, vars))

    dat2 <- dat
    dat2$group <- rnorm(nrow(dat))
    expect_error(validate_datalong_types(dat2, vars))

    dat2 <- dat
    dat2$group <- factor(dat$subjid)
    expect_true(validate_datalong_types(dat2, vars))

    dat2 <- dat
    dat2$outcome <- as.character(dat$outcome)
    expect_error(validate_datalong_types(dat2, vars))

    dat2 <- dat
    dat2$outcome <- as.factor(dat$outcome)
    expect_error(validate_datalong_types(dat2, vars))

    dat2 <- dat
    dat2$visit <- rnorm(nrow(dat))
    expect_error(validate_datalong_types(dat2, vars))

    dat2 <- dat
    dat2$visit <- as.character(dat$visit)
    expect_error(validate_datalong_types(dat2, vars))

    # Show that we can catch covariates that only have 1 level
    dat2 <- dat
    dat2$sex <- factor("M")
    expect_error(validate_datalong_types(dat2, vars), "`sex`")

    # Show that covariate 1 level checks only apply to covariates
    dat2 <- dat
    dat2$group <- factor("A")
    expect_true(validate_datalong_types(dat2, vars))

    # But then show that it will catch group if it is listed as a covariate
    dat2 <- dat
    dat2$group <- factor("A")
    vars2 <- vars
    vars2$covariates <- c(vars2$covariates, "group*sex")
    expect_error(validate_datalong_types(dat2, vars2), "`group`")

    # Show that stratification variables are not affected by this
    dat2 <- dat
    dat2$strata <- factor("A")
    expect_true(validate_datalong_types(dat2, vars))

    # Show that the visit variable is not affected by this
    dat2 <- dat
    dat2$visit <- factor("A")
    expect_true(validate_datalong_types(dat2, vars))

    # Group, visit and period variables must have data rows for every level.
    dat2 <- dat[dat$visit != "Visit 1", ]
    expect_error(
        validate_datalong_types(dat2, vars),
        "`visit`"
    )
    dat2 <- dat[dat$group == "B", ]
    expect_error(
        validate_datalong_types(dat2, vars),
        "`group`"
    )

    dat2 <- dat_period[dat_period$period != "3", ]
    expect_error(
        validate_datalong_types(dat2, vars_period),
        "The number of levels in variable `period` is different than the number of observed levels"
    )

    dat2 <- dat_period
    dat2$duration[1] <- -1
    expect_error(validate_datalong_types(dat2, vars_period), "`duration`")

    dat2 <- dat_period
    dat2$duration[1] <- Inf
    expect_error(validate_datalong_types(dat2, vars_period), "`duration`")

    dat2 <- dat_period
    dat2$duration <- as.character(dat2$duration)
    expect_error(validate_datalong_types(dat2, vars_period), "`duration`")
})


test_that("validate_datalong_notMissing", {
    expect_true(validate_datalong_notMissing(dat, vars))
    expect_true(validate_datalong_notMissing(dat_period, vars_period))

    dat2 <- dat
    dat2$age[c(1, 2, 3)] <- NA
    expect_error(validate_datalong_notMissing(dat2, vars))

    dat2 <- dat
    dat2$group[c(1, 2, 3)] <- NA
    expect_error(validate_datalong_notMissing(dat2, vars))

    dat2 <- dat
    dat2$visit[c(1, 2, 3)] <- NA
    expect_error(validate_datalong_notMissing(dat2, vars))

    dat2 <- dat
    dat2$subjid[c(1, 2, 3)] <- NA
    expect_error(validate_datalong_notMissing(dat2, vars))

    dat2 <- dat
    dat2$sex[c(1, 2, 3)] <- NA
    expect_error(validate_datalong_notMissing(dat2, vars))

    dat2 <- dat
    dat2$strata[c(1, 2, 3)] <- NA
    expect_error(validate_datalong_notMissing(dat2, vars))

    dat2 <- dat_period
    dat2$duration[c(1, 2, 3)] <- NA
    expect_error(
        validate_datalong_notMissing(dat2, vars_period),
        "Variable duration contains missing data"
    )

    dat2 <- dat_period
    dat2$period[c(1, 2, 3)] <- NA
    expect_error(validate_datalong_notMissing(dat2, vars_period))
})


test_that("validate_datalong_complete", {
    expect_true(validate_datalong_complete(dat, vars))
    expect_true(validate_datalong_complete(dat_period, vars_period))

    ### Duplicate visits per patient
    dat2 <- bind_rows(dat, dat)
    expect_error(validate_datalong_complete(dat2, vars))

    dat2 <- dat
    dat2 <- dat2[-1, ]
    expect_error(validate_datalong_complete(dat2, vars))

    ### Completely remove 1 visit (should check against the levels)
    dat2 <- dat %>% dplyr::filter(visit != "Visit 1")
    expect_error(validate_datalong_complete(dat2, vars))

    dat2 <- dat_period[-1, ]
    expect_true(validate_datalong_complete(dat2, vars_period))
    expect_s3_class(longDataConstructor$new(dat2, vars_period), "longdata")

    dat2 <- bind_rows(dat_period, dat_period[1, ])
    expect_error(validate_datalong_complete(dat2, vars_period), "duplicated")
})


test_that("validate_datalong_uniformStrata", {
    expect_true(validate_datalong_uniformStrata(dat, vars))

    vars2 <- vars
    vars2$strata <- character(0)
    expect_true(validate_datalong_uniformStrata(dat, vars2))

    dat2 <- dat
    dat2$strata[[1]] <- "AXS"
    expect_error(validate_datalong_uniformStrata(dat2, vars))
})


test_that("validate_data_long", {
    expect_true(validate_datalong(dat, vars))
    expect_true(validate_datalong(dat_period, vars_period))

    dat2 <- dat_period
    dat2$duration[1] <- NA_real_
    expect_error(
        validate_datalong(dat2, vars_period),
        "Variable duration contains missing data"
    )
})


test_that("validate_data_ice", {
    di <- data.frame(
        subjid = c("1", "1"),
        strategy = c("MAR", "MAR"),
        visit = c("Visit 1"),
        stringsAsFactors = FALSE
    )

    expect_error(
        validate_dataice(dat, di, vars),
        regexp = "must contain at most 1 row per"
    )

    di <- data.frame(
        subjid = c("1", "2"),
        strategy = c("MAR", "MAR"),
        visit = c("Visit 20"),
        stringsAsFactors = FALSE
    )

    expect_error(
        validate_dataice(dat, di, vars),
        regexp = "vars\\$visit.*contains values that are"
    )

    di <- data.frame(
        subjid = c("1", "2"),
        strategy = c("MAR", NA),
        visit = c("Visit 1"),
        stringsAsFactors = FALSE
    )

    expect_error(
        validate_dataice(dat, di, vars),
        regexp = "vars\\$strategy.* must be a non"
    )

    di <- data.frame(
        subjid = c("1", "abc"),
        strategy = c("MAR", "CR"),
        visit = c("Visit 1"),
        stringsAsFactors = FALSE
    )

    expect_error(
        validate_dataice(dat, di, vars),
        regexp = "vars\\$subjid.* contains values that aren't"
    )

    di <- data.frame(
        subjid = c("1", "2"),
        strategy = c("MAR", "CR"),
        visit = c("Visit 1"),
        stringsAsFactors = FALSE
    )

    expect_true(validate_dataice(dat, di, vars))

    di <- data.frame(
        subjid = c("1", "2"),
        strategy = c("MAR", "CR"),
        visit = c("Visit 122"),
        stringsAsFactors = FALSE
    )

    expect_true(validate_dataice(dat, di, vars, update = TRUE))
})
