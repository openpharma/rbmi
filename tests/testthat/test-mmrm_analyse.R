suppressPackageStartupMessages({
    library(dplyr)
    library(testthat)
    library(tibble)
})


# ---- helpers ----------------------------------------------------------------

make_mmrm_data <- function(n = 80, n_arms = 2, seed = 101) {
    set.seed(seed)
    sigma <- as_vcov(c(3, 4, 5), c(0.4, 0.5, 0.3))
    arms  <- LETTERS[seq_len(n_arms)]
    covars <- tibble(
        id    = seq_len(n),
        age   = rnorm(n),
        sex   = factor(sample(c("M", "F"), n, replace = TRUE)),
        group = factor(sample(arms, n, replace = TRUE), levels = arms)
    )
    mvtnorm::rmvnorm(n, sigma = sigma) |>
        as_tibble(.name_repair = "minimal") |>
        setNames(paste0("visit_", 1:3)) |>
        mutate(id = seq_len(n())) |>
        tidyr::pivot_longer(
            cols      = starts_with("visit_"),
            names_to  = "visit",
            values_to = "outcome"
        ) |>
        mutate(visit = factor(visit)) |>
        left_join(covars, by = "id") |>
        mutate(
            outcome = outcome + 5 + 2 * age + 3 * f2n(sex) +
                4 * (as.integer(group) - 1),
            id = factor(id)
        )
}


# ---- output structure -------------------------------------------------------

test_that("mmrm_analyse returns correct names for 2-arm case", {
    dat  <- make_mmrm_data(n_arms = 2)
    vars <- set_vars(
        subjid     = "id",
        outcome    = "outcome",
        group      = "group",
        visit      = "visit",
        covariates = c("age", "sex")
    )

    res <- mmrm_analyse(dat, vars)

    visits <- levels(dat$visit)
    expected_names <- unlist(lapply(visits, function(v) {
        c(paste0("var_B_", v), paste0("trt_B_", v),
          paste0("lsm_A_", v), paste0("lsm_B_", v))
    }))
    expect_equal(names(res), expected_names)
})


test_that("mmrm_analyse returns correct names for 3-arm case", {
    dat  <- make_mmrm_data(n_arms = 3)
    vars <- set_vars(
        subjid     = "id",
        outcome    = "outcome",
        group      = "group",
        visit      = "visit",
        covariates = c("age")
    )

    res <- mmrm_analyse(dat, vars)

    visits <- levels(dat$visit)
    expected_names <- unlist(lapply(visits, function(v) {
        c(
            paste0("var_B_", v), paste0("var_C_", v),
            paste0("trt_B_", v), paste0("trt_C_", v),
            paste0("lsm_A_", v), paste0("lsm_B_", v), paste0("lsm_C_", v)
        )
    }))
    expect_equal(names(res), expected_names)
})


test_that("each element of mmrm_analyse result has est, se, df", {
    dat  <- make_mmrm_data(n_arms = 2)
    vars <- set_vars(
        subjid     = "id",
        outcome    = "outcome",
        group      = "group",
        visit      = "visit",
        covariates = c("age", "sex")
    )

    res <- mmrm_analyse(dat, vars)

    for (nm in names(res)) {
        expect_true(is.list(res[[nm]]), info = nm)
        expect_true(all(c("est", "se", "df") %in% names(res[[nm]])), info = nm)
        expect_true(is.numeric(res[[nm]]$est), info = nm)
    }
})


# ---- var entries ------------------------------------------------------------

test_that("var_* est matches VarCorr diagonal", {
    dat  <- make_mmrm_data(n_arms = 2)
    vars <- set_vars(
        subjid     = "id",
        outcome    = "outcome",
        group      = "group",
        visit      = "visit",
        covariates = c("age")
    )

    res <- mmrm_analyse(dat, vars)

    # Refit manually to get VarCorr
    fit <- mmrm::mmrm(
        outcome ~ group + visit + age + us(visit | id),
        data = dat
    )
    vc <- mmrm::VarCorr(fit)

    for (v in levels(dat$visit)) {
        expect_equal(
            res[[paste0("var_B_", v)]]$est,
            vc[v, v],
            tolerance = 1e-6,
            info = v
        )
    }
})


# ---- trt estimates ----------------------------------------------------------

test_that("trt_* est matches emmeans contrast", {
    dat  <- make_mmrm_data(n_arms = 2)
    vars <- set_vars(
        subjid     = "id",
        outcome    = "outcome",
        group      = "group",
        visit      = "visit",
        covariates = c("age")
    )

    res <- mmrm_analyse(dat, vars)

    fit <- mmrm::mmrm(
        outcome ~ group + visit + age + us(visit | id),
        data = dat
    )

    for (v in levels(dat$visit)) {
        em  <- emmeans::emmeans(fit, "group", by = "visit",
                                at = list(visit = v), weights = "proportional")
        con <- as.data.frame(emmeans::contrast(em, "trt.vs.ctrl", ref = "A"))
        expect_equal(
            res[[paste0("trt_B_", v)]]$est,
            con[con$contrast == "B - A", "estimate"],
            tolerance = 1e-6,
            info = v
        )
    }
})


# ---- visit subsetting -------------------------------------------------------

test_that("visits argument restricts output to requested visits", {
    dat  <- make_mmrm_data(n_arms = 2)
    vars <- set_vars(
        subjid  = "id",
        outcome = "outcome",
        group   = "group",
        visit   = "visit"
    )

    res <- mmrm_analyse(dat, vars, visits = c("visit_1", "visit_2"))

    expect_true(all(grepl("visit_1$|visit_2$", names(res))))
    expect_false(any(grepl("visit_3", names(res))))
})


test_that("invalid visit raises an error", {
    dat  <- make_mmrm_data(n_arms = 2)
    vars <- set_vars(
        subjid  = "id",
        outcome = "outcome",
        group   = "group",
        visit   = "visit"
    )

    expect_error(
        mmrm_analyse(dat, vars, visits = "visit_99"),
        regexp = "visit_99"
    )
})


# ---- cov_struct argument ----------------------------------------------------

test_that("cov_struct argument is passed through to mmrm", {
    dat  <- make_mmrm_data(n_arms = 2)
    vars <- set_vars(
        subjid  = "id",
        outcome = "outcome",
        group   = "group",
        visit   = "visit"
    )

    # ar1 should fit without error and return the same structure
    res <- mmrm_analyse(dat, vars, cov_struct = "ar1")
    expect_true(length(res) > 0)
    expect_true(all(c("est", "se", "df") %in% names(res[[1]])))
})


# ---- integration with analyse() / pool() ------------------------------------

test_that("mmrm_analyse integrates with analyse() and pool() for approxbayes", {
    skip_if_not(is_core_test())

    dat <- simulate_test_data(n = 100) |>
        as_tibble() |>
        mutate(outcome = if_else(rbinom(n(), 1, 0.2) == 1, NA_real_, outcome))

    dat <- expand_locf(
        dat,
        id    = levels(dat$id),
        visit = levels(dat$visit),
        vars  = c("age", "group", "sex"),
        group = c("id"),
        order = c("id", "visit")
    )

    dat_ice <- dat |>
        arrange(id, visit) |>
        filter(is.na(outcome)) |>
        group_by(id) |>
        slice(1) |>
        ungroup() |>
        select(id, visit) |>
        mutate(strategy = "JR")

    vars <- set_vars(
        outcome    = "outcome",
        visit      = "visit",
        subjid     = "id",
        group      = "group",
        covariates = c("sex", "age")
    )

    method <- method_approxbayes(n_samples = 5)

    set.seed(42)
    draw_obj   <- draws(
        data      = group_by(dat, id),
        data_ice  = group_by(dat_ice, id),
        vars      = vars,
        method    = method,
        quiet     = TRUE
    )
    impute_obj <- impute(draw_obj, references = c("A" = "A", "B" = "A"))

    ana_obj  <- analyse(impute_obj, fun = mmrm_analyse, vars = vars)
    pool_obj <- pool(ana_obj)

    expect_true(inherits(pool_obj, "pool"))
    expect_true(length(pool_obj$pars) > 0)

    # All parameter names should follow the arm-labelled convention
    par_names <- names(pool_obj$pars)
    expect_true(all(grepl("^(var|trt|lsm)_", par_names)))
})
