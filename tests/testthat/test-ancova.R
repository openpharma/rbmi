suppressPackageStartupMessages({
    library(dplyr)
    library(testthat)
    library(tibble)
})


test_that("ancova", {
    ##################
    #
    # Basic usage
    #
    #

    set.seed(101)

    n <- 1000
    dat <- tibble(
        visit = "vis1",
        age1 = rnorm(n),
        age2 = rnorm(n),
        grp = factor(sample(c("A", "B"), size = n, replace = TRUE)),
        out = rnorm(n, mean = 50 + 3 * f2n(grp) + 4 * age1 + 8 * age2, sd = 20)
    )

    mod <- lm(out ~ age1 + age2 + grp, data = dat)

    result_expected <- list(
        "trt_vis1" = list(
            "est" = mod$coefficients[[4]],
            "se" = sqrt(vcov(mod)[4, 4]),
            "df" = df.residual(mod)
        )
    )
    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = c("age1", "age2"),
            visit = "visit"
        )
    )["trt_vis1"]

    expect_equal(result_expected, result_actual)

    ##################
    #
    # No Covariates
    #
    #

    set.seed(101)

    n <- 1000
    dat <- tibble(
        ivis = " 1",
        age1 = rnorm(n),
        age2 = rnorm(n),
        grp = factor(sample(c("A", "B"), size = n, replace = TRUE)),
        out = rnorm(n, mean = 50 + 3 * f2n(grp) + 4 * age1 + 8 * age2, sd = 20)
    )

    mod <- lm(out ~ grp, data = dat)

    result_expected <- list(
        "trt_ 1" = list(
            "est" = mod$coefficients[[2]],
            "se" = sqrt(vcov(mod)[2, 2]),
            "df" = df.residual(mod)
        )
    )
    result_actual <- ancova(
        dat,
        list(outcome = "out", group = "grp", visit = "ivis")
    )["trt_ 1"]

    expect_equal(result_expected, result_actual)

    ##################
    #
    # Single visit
    #
    #

    n <- 1000
    dat <- tibble(
        age1 = rnorm(n),
        age2 = rnorm(n),
        vis = "visit 1",
        grp = factor(sample(c("A", "B"), size = n, replace = TRUE)),
        out = rnorm(n, mean = 50 + 3 * f2n(grp) + 4 * age1 + 8 * age2, sd = 20)
    )

    mod <- lm(out ~ age1 + age2 + grp, data = dat)

    result_expected <- list(
        "trt_visit 1" = list(
            "est" = mod$coefficients[[4]],
            "se" = sqrt(vcov(mod)[4, 4]),
            "df" = df.residual(mod)
        )
    )

    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = c("age1", "age2"),
            visit = "vis"
        ),
        visits = "visit 1"
    )["trt_visit 1"]

    expect_equal(result_expected, result_actual)

    ##################
    #
    # Multiple Visits
    #
    #

    n <- 1000
    dat <- tibble(
        age1 = rnorm(n),
        age2 = rnorm(n),
        vis = sample(c("visit 1", "visit 2"), size = n, replace = TRUE),
        grp = factor(sample(c("A", "B"), size = n, replace = TRUE)),
        out = rnorm(n, mean = 50 + 3 * f2n(grp) + 4 * age1 + 8 * age2, sd = 20)
    )

    mod <- lm(out ~ age1 + age2 + grp, data = filter(dat, vis == "visit 1"))

    result_expected <- list(
        "trt_visit 1" = list(
            "est" = mod$coefficients[[4]],
            "se" = sqrt(vcov(mod)[4, 4]),
            "df" = df.residual(mod)
        )
    )

    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = c("age1", "age2"),
            visit = "vis"
        ),
        visits = "visit 1"
    )["trt_visit 1"]

    expect_equal(result_expected, result_actual)

    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = c("age1", "age2"),
            visit = "vis"
        ),
        visits = c("visit 1", "visit 2")
    )["trt_visit 1"]

    expect_equal(result_expected, result_actual)

    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = c("age1", "age2"),
            visit = "vis"
        ),
        visits = c("visit 1", "visit 2")
    )

    mod <- lm(out ~ age1 + age2 + grp, data = filter(dat, vis == "visit 2"))

    result_expected <- list(
        "trt_visit 2" = list(
            "est" = mod$coefficients[[4]],
            "se" = sqrt(vcov(mod)[4, 4]),
            "df" = df.residual(mod)
        )
    )

    expect_equal(result_expected, result_actual["trt_visit 2"])

    expect_equal(
        names(result_actual),
        c(
            "trt_visit 1",
            "lsm_ref_visit 1",
            "lsm_alt_visit 1",
            "trt_visit 2",
            "lsm_ref_visit 2",
            "lsm_alt_visit 2"
        )
    )

    ##################
    #
    # Visit variable handling
    #
    #

    n <- 1000
    dat <- tibble(
        age1 = rnorm(n),
        age2 = rnorm(n),
        vis = sample(c("visit 1", "visit 2"), size = n, replace = TRUE),
        grp = factor(sample(c("A", "B"), size = n, replace = TRUE)),
        out = rnorm(n, mean = 50 + 3 * f2n(grp) + 4 * age1 + 8 * age2, sd = 20)
    )

    vars <- set_vars(
        outcome = "out",
        group = "grp",
        covariates = c("age1", "age2")
    )

    vars$visit <- "vi"

    expect_error(
        ancova(dat, vars, visits = "k"),
        regex = "`vi`"
    )

    vars$visit <- "vis"

    expect_error(
        ancova(dat, vars, visits = "k"),
        regex = "`k`"
    )
})


test_that("ancova - basic 3-group functionality", {
    set.seed(201)

    n <- 900
    dat <- tibble(
        visit = "vis1",
        age = rnorm(n),
        sex = factor(sample(c("M", "F"), size = n, replace = TRUE)),
        grp = factor(sample(
            c("Control", "Trt1", "Trt2"),
            size = n,
            replace = TRUE
        )),
        out = rnorm(
            n,
            mean = 50 +
                2 * age +
                3 * f2n(sex) +
                4 * (grp == "Trt1") +
                6 * (grp == "Trt2"),
            sd = 10
        )
    )

    # Manual model for comparison
    mod <- lm(out ~ age + sex + grp, data = dat)

    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = c("age", "sex"),
            visit = "visit"
        )
    )

    # Check output structure (ref/alt/alt2 naming)
    expected_names <- c(
        "trt_vis1",
        "trt_alt2_vis1", # Treatment effects vs reference
        "lsm_ref_vis1",
        "lsm_alt_vis1",
        "lsm_alt2_vis1" # LSMeans for all groups
    )
    expect_equal(sort(names(result_actual)), sort(expected_names))

    expected_trt <- list(
        est = coef(mod)[["grpTrt1"]],
        se = sqrt(vcov(mod)["grpTrt1", "grpTrt1"]),
        df = df.residual(mod)
    )
    expect_equal(result_actual$trt_vis1, expected_trt)

    expected_trt_alt2 <- list(
        est = coef(mod)[["grpTrt2"]],
        se = sqrt(vcov(mod)["grpTrt2", "grpTrt2"]),
        df = df.residual(mod)
    )
    expect_equal(result_actual$trt_alt2_vis1, expected_trt_alt2)
})


test_that("ancova - 4-group functionality", {
    set.seed(301)

    n <- 800
    grp_levels <- c("Placebo", "Low", "Medium", "High")
    dat <- tibble(
        visit = "baseline",
        baseline_score = rnorm(n, mean = 30, sd = 8),
        grp = factor(
            sample(grp_levels, size = n, replace = TRUE),
            levels = grp_levels
        ),
        out = rnorm(
            n,
            mean = 20 +
                0.7 * baseline_score +
                2 * (grp == "Low") +
                5 * (grp == "Medium") +
                8 * (grp == "High"),
            sd = 6
        )
    )

    # Manual model for comparison
    mod <- lm(out ~ baseline_score + grp, data = dat)

    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = "baseline_score",
            visit = "visit"
        )
    )

    # Check we have all expected components
    expected_names <- c(
        "trt_baseline",
        "trt_alt2_baseline",
        "trt_alt3_baseline", # 3 treatment effects
        "lsm_ref_baseline",
        "lsm_alt_baseline",
        "lsm_alt2_baseline",
        "lsm_alt3_baseline" # 4 LSMeans
    )
    expect_equal(sort(names(result_actual)), sort(expected_names))

    # Verify treatment effects
    expect_equal(
        result_actual$trt_baseline$est,
        coef(mod)[["grpLow"]],
        tolerance = 1e-10
    )
    expect_equal(
        result_actual$trt_alt2_baseline$est,
        coef(mod)[["grpMedium"]],
        tolerance = 1e-10
    )
    expect_equal(
        result_actual$trt_alt3_baseline$est,
        coef(mod)[["grpHigh"]],
        tolerance = 1e-10
    )
})


test_that("ancova - LSMeans with group interactions (multi-arm)", {
    set.seed(401)

    grp_levels <- c("Control", "Treatment1", "Treatment2")
    sex_levels <- c("Male", "Female")
    n <- 600
    dat <- tibble(
        visit = "week12",
        age = rnorm(n, mean = 45, sd = 12),
        sex = factor(
            sample(sex_levels, size = n, replace = TRUE),
            levels = sex_levels
        ),
        grp = factor(
            sample(grp_levels, size = n, replace = TRUE),
            levels = grp_levels
        ),
        # Create interaction effect between group and sex
        out = rnorm(
            n,
            mean = 40 +
                0.5 * age +
                3 * (sex == "Female") +
                5 * (grp == "Treatment1") +
                7 * (grp == "Treatment2") +
                # Group-sex interactions
                2 * (grp == "Treatment1" & sex == "Female") +
                -1 * (grp == "Treatment2" & sex == "Female"),
            sd = 8
        )
    )

    # Test with group*sex interaction in covariates
    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = c("age", "sex", "grp*sex"),
            visit = "visit"
        )
    )

    mod <- lm(out ~ age + sex + grp + grp:sex, data = dat)

    # Check structure
    expected_names <- c(
        "trt_week12",
        "trt_alt2_week12",
        "lsm_ref_week12",
        "lsm_alt_week12",
        "lsm_alt2_week12"
    )
    expect_equal(sort(names(result_actual)), sort(expected_names))

    suppressMessages({
        emmean_counter <- as.data.frame(
            emmeans::emmeans(mod, "grp", counterfactual = "grp")
        )
    })

    expected <- as.list(emmean_counter[
        emmean_counter$grp == "Control",
        c("emmean", "SE", "df")
    ])
    names(expected) <- c("est", "se", "df")
    expect_equal(result_actual$lsm_ref_week12, expected)

    expected <- as.list(emmean_counter[
        emmean_counter$grp == "Treatment1",
        c("emmean", "SE", "df")
    ])
    names(expected) <- c("est", "se", "df")
    expect_equal(result_actual$lsm_alt_week12, expected)

    expected <- as.list(emmean_counter[
        emmean_counter$grp == "Treatment2",
        c("emmean", "SE", "df")
    ])
    names(expected) <- c("est", "se", "df")
    expect_equal(result_actual$lsm_alt2_week12, expected)

    # Same again but with a different weighting scheme
    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = c("age", "sex", "grp*sex"),
            visit = "visit"
        ),
        weights = "equal"
    )
    suppressMessages({
        emmean_counter <- as.data.frame(
            emmeans::emmeans(mod, "grp", "grp")
        )
    })
    expected <- as.list(emmean_counter[
        emmean_counter$grp == "Control",
        c("emmean", "SE", "df")
    ])
    names(expected) <- c("est", "se", "df")
    expect_equal(result_actual$lsm_ref_week12, expected)

    expected <- as.list(emmean_counter[
        emmean_counter$grp == "Treatment1",
        c("emmean", "SE", "df")
    ])
    names(expected) <- c("est", "se", "df")
    expect_equal(result_actual$lsm_alt_week12, expected)

    expected <- as.list(emmean_counter[
        emmean_counter$grp == "Treatment2",
        c("emmean", "SE", "df")
    ])
    names(expected) <- c("est", "se", "df")
    expect_equal(result_actual$lsm_alt2_week12, expected)
})


test_that("ancova - multiple visits (multi-arm)", {
    set.seed(601)

    n_per_visit <- 200
    grp_levels <- c("A", "B", "C")
    dat <- bind_rows(
        tibble(
            visit = "visit1",
            age = rnorm(n_per_visit),
            grp = factor(
                sample(grp_levels, size = n_per_visit, replace = TRUE),
                levels = grp_levels
            ),
            out = rnorm(
                n_per_visit,
                mean = 20 + 2 * age + 3 * (grp == "B") + 5 * (grp == "C"),
                sd = 4
            )
        ),
        tibble(
            visit = "visit2",
            age = rnorm(n_per_visit),
            grp = factor(sample(
                c("A", "B", "C"),
                size = n_per_visit,
                replace = TRUE
            )),
            out = rnorm(
                n_per_visit,
                mean = 25 + 2 * age + 4 * (grp == "B") + 7 * (grp == "C"),
                sd = 4
            )
        )
    )

    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = "age",
            visit = "visit"
        )
    )

    # Check we have results for both visits
    visit1_names <- grep("_visit1$", names(result_actual), value = TRUE)
    visit2_names <- grep("_visit2$", names(result_actual), value = TRUE)

    expect_length(visit1_names, 5) # 2 treatment effects + 3 LSMeans
    expect_length(visit2_names, 5) # 2 treatment effects + 3 LSMeans

    expected_names <- c(
        "trt_visit1",
        "trt_alt2_visit1",
        "lsm_ref_visit1",
        "lsm_alt_visit1",
        "lsm_alt2_visit1",
        "trt_visit2",
        "trt_alt2_visit2",
        "lsm_ref_visit2",
        "lsm_alt_visit2",
        "lsm_alt2_visit2"
    )
    expect_true(all(expected_names %in% names(result_actual)))
})


test_that("ancova - no covariates (multi-arm)", {
    set.seed(701)

    n <- 300
    grp_levels <- c("Control", "Low", "High")
    dat <- tibble(
        visit = "final",
        grp = factor(
            sample(grp_levels, size = n, replace = TRUE),
            levels = grp_levels
        ),
        out = rnorm(
            n,
            mean = 40 + 3 * (grp == "Low") + 8 * (grp == "High"),
            sd = 6
        )
    )

    result_actual <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = NULL,
            visit = "visit"
        )
    )

    # Manual model for comparison
    mod <- lm(out ~ grp, data = dat)

    # Check treatment effects
    expect_equal(
        result_actual$trt_final$est,
        coef(mod)[["grpLow"]],
        tolerance = 1e-10
    )
    expect_equal(
        result_actual$trt_alt2_final$est,
        coef(mod)[["grpHigh"]],
        tolerance = 1e-10
    )

    # Check we have all expected components
    expected_names <- c(
        "trt_final",
        "trt_alt2_final",
        "lsm_ref_final",
        "lsm_alt_final",
        "lsm_alt2_final"
    )
    expect_equal(sort(names(result_actual)), sort(expected_names))
})


test_that("ancova - error handling (multi-arm)", {
    set.seed(801)

    n <- 100
    dat <- tibble(
        visit = "v1",
        age = rnorm(n),
        grp = factor(sample(c("A", "B"), size = n, replace = TRUE)), # Only 2 groups
        out = rnorm(n)
    )

    # Should work with 2 groups (minimum requirement)
    expect_no_error({
        result <- ancova(
            dat,
            list(
                outcome = "out",
                group = "grp",
                covariates = "age",
                visit = "visit"
            )
        )
    })

    # Test with single group - should fail
    dat_single_group <- dat
    dat_single_group$grp <- factor(rep("A", n))

    expect_error(
        ancova(
            dat_single_group,
            list(
                outcome = "out",
                group = "grp",
                covariates = "age",
                visit = "visit"
            )
        ),
        regexp = "must be a factor variable with two or more levels"
    )

    # Test reserved variable name conflict
    dat_conflict <- dat
    dat_conflict$rbmiGroup <- 1

    expect_error(
        ancova(
            dat_conflict,
            list(
                outcome = "out",
                group = "grp",
                covariates = c("age", "rbmiGroup"),
                visit = "visit"
            )
        ),
        regexp = "rbmiGroup.*reserved variable name"
    )
})


test_that("ancova - custom group_contrasts", {
    set.seed(151)

    n <- 900
    grp_levels <- c("Placebo", "A", "B")
    dat <- tibble(
        visit = "v1",
        age = rnorm(n),
        grp = factor(
            sample(grp_levels, size = n, replace = TRUE),
            levels = grp_levels
        ),
        out = rnorm(
            n,
            mean = 50 + 2 * age + 3 * (grp == "A") + 6 * (grp == "B"),
            sd = 8
        )
    )

    mod <- lm(out ~ age + grp, data = dat)
    vc <- vcov(mod)

    res <- ancova(
        dat,
        list(
            outcome = "out",
            group = "grp",
            covariates = "age",
            visit = "visit",
            group_contrasts = list(
                c("A", "Placebo"),
                c("B", "Placebo"),
                c("B", "A")
            )
        )
    )

    # A - Placebo => alt vs ref => "trt"
    # B - Placebo => alt2 vs ref => "trt_alt2"
    # B - A       => alt2 vs alt => "trt_alt2_alt"
    expect_true(all(
        c("trt_v1", "trt_alt2_v1", "trt_alt2_alt_v1") %in% names(res)
    ))

    expect_equal(res$trt_v1$est, coef(mod)[["grpA"]])
    expect_equal(res$trt_alt2_v1$est, coef(mod)[["grpB"]])
    expect_equal(
        res$trt_alt2_alt_v1$est,
        coef(mod)[["grpB"]] - coef(mod)[["grpA"]]
    )

    se_ba <- sqrt(
        vc["grpB", "grpB"] + vc["grpA", "grpA"] - 2 * vc["grpB", "grpA"]
    )
    expect_equal(res$trt_alt2_alt_v1$se, se_ba)

    # Referencing a level that is not present should error
    expect_error(
        ancova(
            dat,
            list(
                outcome = "out",
                group = "grp",
                covariates = "age",
                visit = "visit",
                group_contrasts = list(c("A", "Z"))
            )
        ),
        regexp = "not present in the data"
    )
})


test_that("set_vars validates group_contrasts", {
    expect_silent(set_vars(group = "grp", group_contrasts = list(c("A", "B"))))
    expect_null(set_vars(group = "grp")$group_contrasts)

    expect_error(
        set_vars(group = "grp", group_contrasts = list(c("A"))),
        regexp = "group_contrasts"
    )
    expect_error(
        set_vars(group = "grp", group_contrasts = list(1:2)),
        regexp = "group_contrasts"
    )
    expect_error(
        set_vars(group = "grp", group_contrasts = c("A", "B")),
        regexp = "group_contrasts"
    )
})


test_that("as.data.frame.pool appends ancova metadata columns", {
    pars <- list(
        trt_v1 = list(est = 1, se = 0.5, ci = c(0, 2), pvalue = 0.05),
        lsm_ref_v1 = list(est = 10, se = 1, ci = c(8, 12), pvalue = 0.001)
    )
    par_meta <- data.frame(
        parameter = c("trt_v1", "lsm_ref_v1"),
        estimate_type = c("contrast", "lsm"),
        group = "grp",
        group_level_1 = c("B", "A"),
        group_level_2 = c("A", NA),
        visit = "v1",
        stringsAsFactors = FALSE
    )

    pool_with_meta <- structure(
        list(pars = pars, par_meta = par_meta),
        class = "pool"
    )
    df <- as.data.frame(pool_with_meta)
    expect_equal(
        names(df),
        c(
            "parameter",
            "est",
            "se",
            "lci",
            "uci",
            "pval",
            "estimate_type",
            "group",
            "group_level_1",
            "group_level_2",
            "visit"
        )
    )
    expect_equal(df$estimate_type, c("contrast", "lsm"))
    expect_equal(df$group_level_1, c("B", "A"))
    expect_equal(df$group_level_2, c("A", NA))

    # Without metadata the classic 6-column data.frame is returned
    pool_no_meta <- structure(list(pars = pars), class = "pool")
    df2 <- as.data.frame(pool_no_meta)
    expect_equal(names(df2), c("parameter", "est", "se", "lci", "uci", "pval"))
})


test_that("as.data.frame.pool errors when metadata does not match parameters", {
    pars <- list(
        trt_v1 = list(est = 1, se = 0.5, ci = c(0, 2), pvalue = 0.05),
        lsm_ref_v1 = list(est = 10, se = 1, ci = c(8, 12), pvalue = 0.001)
    )
    # Metadata is missing an entry for `lsm_ref_v1`, which must not be silently
    # filled with `NA` columns.
    par_meta <- data.frame(
        parameter = "trt_v1",
        estimate_type = "contrast",
        group = "grp",
        group_level_1 = "B",
        group_level_2 = "A",
        visit = "v1",
        stringsAsFactors = FALSE
    )
    pool_bad_meta <- structure(
        list(pars = pars, par_meta = par_meta),
        class = "pool"
    )
    expect_error(
        as.data.frame(pool_bad_meta),
        regexp = "without matching metadata"
    )
})


test_that("ancova_linear_contrast subtracts the reference under intercept-less models", {
    # In the usual intercept model the reference level has no explicit
    # coefficient (it is absorbed by the intercept), so contrasts against it
    # reduce to the minuend coefficient.
    beta_int <- c(`(Intercept)` = 50, age = 2, rbmiGroupL2 = 3, rbmiGroupL3 = 6)
    vc_int <- diag(length(beta_int))
    dimnames(vc_int) <- list(names(beta_int), names(beta_int))
    r_int <- ancova_linear_contrast(
        2,
        1,
        beta_int,
        vc_int,
        100,
        c("L1", "L2", "L3")
    )
    expect_equal(r_int$est, 3) # alt vs ref == coef(rbmiGroupL2)

    # In a no-intercept model every level (including the reference) gets its own
    # coefficient; the reference must still be subtracted rather than returning
    # the minuend group's absolute mean.
    beta_noint <- c(
        age = 2,
        rbmiGroupL1 = 50,
        rbmiGroupL2 = 53,
        rbmiGroupL3 = 56
    )
    vc_noint <- diag(length(beta_noint))
    dimnames(vc_noint) <- list(names(beta_noint), names(beta_noint))
    r_noint <- ancova_linear_contrast(
        2,
        1,
        beta_noint,
        vc_noint,
        100,
        c("L1", "L2", "L3")
    )
    expect_equal(r_noint$est, 3) # 53 - 50, not 53
    # SE uses both coefficients: sqrt(v_L2 + v_L1) with unit diagonal == sqrt(2)
    expect_equal(r_noint$se, sqrt(2))
})


test_that("ancova_linear_contrast fails loudly on invalid arguments", {
    beta <- c(`(Intercept)` = 50, rbmiGroupL2 = 3)
    vc <- diag(length(beta))
    dimnames(vc) <- list(names(beta), names(beta))

    # Out-of-range contrast index
    expect_error(
        ancova_linear_contrast(3, 1, beta, vc, 100, c("L1", "L2")),
        regexp = "out of range"
    )

    # Coefficient / vcov name misalignment (e.g. an aliased term dropped from vcov)
    vc_bad <- vc[1, 1, drop = FALSE]
    expect_error(
        ancova_linear_contrast(2, 1, beta, vc_bad, 100, c("L1", "L2")),
        regexp = "aligned by name and dimension"
    )

    # A required (non-reference) coefficient is missing / aliased -> rank-deficient
    beta_na <- c(`(Intercept)` = 50, rbmiGroupL2 = NA_real_)
    vc_na <- diag(length(beta_na))
    dimnames(vc_na) <- list(names(beta_na), names(beta_na))
    expect_error(
        ancova_linear_contrast(2, 1, beta_na, vc_na, 100, c("L1", "L2")),
        regexp = "rank-deficient"
    )
})


test_that("ancova metadata propagates through pool() -> as.data.frame() (integration)", {
    set.seed(401)
    n <- 300
    grp_levels <- c("Placebo", "A", "B")
    dat <- tibble(
        visit = "v1",
        age = rnorm(n),
        grp = factor(
            sample(grp_levels, size = n, replace = TRUE),
            levels = grp_levels
        ),
        out = rnorm(
            n,
            mean = 50 + 2 * age + 3 * (grp == "A") + 6 * (grp == "B"),
            sd = 8
        )
    )
    vars <- set_vars(
        outcome = "out",
        group = "grp",
        covariates = "age",
        visit = "visit"
    )

    # Real ANCOVA output carries the per-parameter metadata attribute.
    ana <- ancova(dat, vars)
    meta <- attr(ana, "rbmi_par_meta")
    expect_false(is.null(meta))

    # Emulate `analyse()` collecting per-sample results, then pool with Rubin's
    # rules and materialise as a data.frame. This exercises the real
    # ancova() -> pool() -> as.data.frame() metadata-propagation path.
    ana_obj <- as_analysis(
        results = replicate(3, ana, simplify = FALSE),
        method = method_bayes(n_samples = 3),
        par_meta = meta
    )
    pool_obj <- pool(ana_obj)
    df <- as.data.frame(pool_obj)

    expect_true(all(
        c(
            "estimate_type",
            "group",
            "group_level_1",
            "group_level_2",
            "visit"
        ) %in%
            names(df)
    ))
    # Multi-arm parameters are all present and correctly typed.
    expect_setequal(
        df$parameter,
        c(
            "trt_v1",
            "trt_alt2_v1",
            "lsm_ref_v1",
            "lsm_alt_v1",
            "lsm_alt2_v1"
        )
    )
    # Metadata is aligned to the correct rows (no NA drift).
    trt_row <- df[df$parameter == "trt_alt2_v1", ]
    expect_equal(trt_row$estimate_type, "contrast")
    expect_equal(trt_row$group_level_1, "B")
    expect_equal(trt_row$group_level_2, "Placebo")
    expect_equal(trt_row$group, "grp")
    expect_equal(trt_row$visit, "v1")
    lsm_row <- df[df$parameter == "lsm_alt2_v1", ]
    expect_equal(lsm_row$estimate_type, "lsm")
    expect_equal(lsm_row$group_level_1, "B")
    expect_true(is.na(lsm_row$group_level_2))
})
