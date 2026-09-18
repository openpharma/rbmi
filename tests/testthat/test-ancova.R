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
                a_vs_pbo = c("A", "Placebo"),
                b_vs_pbo = c("B", "Placebo"),
                b_vs_a = c("B", "A")
            )
        )
    )

    # Explicit contrasts are named; the names become the parameter names.
    expect_true(all(
        c("a_vs_pbo_v1", "b_vs_pbo_v1", "b_vs_a_v1") %in% names(res)
    ))

    expect_equal(res$a_vs_pbo_v1$est, coef(mod)[["grpA"]])
    expect_equal(res$b_vs_pbo_v1$est, coef(mod)[["grpB"]])
    expect_equal(
        res$b_vs_a_v1$est,
        coef(mod)[["grpB"]] - coef(mod)[["grpA"]]
    )

    se_ba <- sqrt(
        vc["grpB", "grpB"] + vc["grpA", "grpA"] - 2 * vc["grpB", "grpA"]
    )
    expect_equal(res$b_vs_a_v1$se, se_ba)

    # Referencing a level that is not present should error
    expect_error(
        ancova(
            dat,
            list(
                outcome = "out",
                group = "grp",
                covariates = "age",
                visit = "visit",
                group_contrasts = list(a_vs_z = c("A", "Z"))
            )
        ),
        regexp = "not present in the data"
    )

    # A contrast name colliding with the lsm_ prefix should error
    expect_error(
        ancova(
            dat,
            list(
                outcome = "out",
                group = "grp",
                covariates = "age",
                visit = "visit",
                group_contrasts = list(lsm_ref = c("A", "Placebo"))
            )
        ),
        regexp = "reserved for least-squares means"
    )
})


test_that("set_vars validates group_contrasts", {
    expect_silent(set_vars(
        group = "grp",
        group_contrasts = list(ab = c("A", "B"))
    ))
    expect_null(set_vars(group = "grp")$group_contrasts)

    # Explicit contrasts must be named
    expect_error(
        set_vars(group = "grp", group_contrasts = list(c("A", "B"))),
        regexp = "named"
    )
    missing_name <- list(c("A", "B"))
    names(missing_name) <- NA_character_
    expect_error(
        set_vars(group = "grp", group_contrasts = missing_name),
        regexp = "named"
    )
    expect_error(
        ancova_resolve_contrasts(
            missing_name,
            orig_levels = c("A", "B"),
            labels = c("ref", "alt")
        ),
        regexp = "named"
    )
    expect_error(
        set_vars(group = "grp", group_contrasts = list(ab = c("A"))),
        regexp = "group_contrasts"
    )
    expect_error(
        set_vars(group = "grp", group_contrasts = list(x = "A")),
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


test_that("ancova_linear_contrast reproduces coefficient contrasts (treatment coding)", {
    # Intercept model, treatment coding: reference level is absorbed by the
    # intercept and has coefficients rbmiGroupL2, rbmiGroupL3.
    beta <- c(`(Intercept)` = 50, age = 2, rbmiGroupL2 = 3, rbmiGroupL3 = 6)
    vc <- diag(length(beta))
    dimnames(vc) <- list(names(beta), names(beta))
    cmat <- stats::contr.treatment(3) # rows L1..L3, cols L2, L3
    rownames(cmat) <- c("L1", "L2", "L3")
    contrast_design <- cbind(`(Intercept)` = 1, age = 0, cmat)
    colnames(contrast_design)[3:4] <- c("rbmiGroupL2", "rbmiGroupL3")

    # alt vs ref: weights c(-1, 1, 0) -> coef(rbmiGroupL2)
    r1 <- ancova_linear_contrast(c(-1, 1, 0), beta, vc, 100, contrast_design)
    expect_equal(r1$est, 3)
    expect_equal(r1$se, 1) # sqrt(v_L2) with unit diagonal

    # alt2 vs alt: weights c(0, -1, 1) -> coef(rbmiGroupL3) - coef(rbmiGroupL2)
    r2 <- ancova_linear_contrast(c(0, -1, 1), beta, vc, 100, contrast_design)
    expect_equal(r2$est, 3)
    expect_equal(r2$se, sqrt(2)) # v_L3 + v_L2 - 2 v_23 = 1 + 1 - 0

    # pooled: 0.5*L2 + 0.5*L3 - L1 -> 0.5*3 + 0.5*6
    r3 <- ancova_linear_contrast(
        c(-1, 0.5, 0.5),
        beta,
        vc,
        100,
        contrast_design
    )
    expect_equal(r3$est, 0.5 * 3 + 0.5 * 6)
})


test_that("ancova_linear_contrast fails loudly on invalid arguments", {
    beta <- c(`(Intercept)` = 50, rbmiGroupL2 = 3, rbmiGroupL3 = 6)
    vc <- diag(length(beta))
    dimnames(vc) <- list(names(beta), names(beta))
    cmat <- stats::contr.treatment(3)
    rownames(cmat) <- c("L1", "L2", "L3")
    contrast_design <- cbind(`(Intercept)` = 1, cmat)
    colnames(contrast_design)[2:3] <- c("rbmiGroupL2", "rbmiGroupL3")

    # Weights that do not sum to zero
    expect_error(
        ancova_linear_contrast(c(1, 0, 0), beta, vc, 100, contrast_design),
        regexp = "sum to zero"
    )

    # Wrong number of weights
    expect_error(
        ancova_linear_contrast(c(-1, 1), beta, vc, 100, contrast_design),
        regexp = "one entry per group level"
    )

    # A required group coefficient is aliased (NA) -> rank-deficient
    beta_na <- beta
    beta_na[["rbmiGroupL3"]] <- NA_real_
    expect_error(
        ancova_linear_contrast(c(-1, 0, 1), beta_na, vc, 100, contrast_design),
        regexp = "rank-deficient"
    )

    # A group coefficient missing from the vcov matrix -> rank-deficient
    vc_bad <- vc[
        c("(Intercept)", "rbmiGroupL2"),
        c("(Intercept)", "rbmiGroupL2")
    ]
    expect_error(
        ancova_linear_contrast(c(-1, 0, 1), beta, vc_bad, 100, contrast_design),
        regexp = "rank-deficient"
    )
})


test_that("ancova_contrast_design builds complete reference rows", {
    dat <- data.frame(
        out = seq_len(8),
        rbmiGroup = factor(rep(c("L1", "L2"), each = 4)),
        sex = factor(rep(c("Female", "Male"), 4)),
        age = rep(c(-2, -1, 1, 2), 2)
    )
    expected_data <- data.frame(
        rbmiGroup = factor(c("L1", "L2"), levels = c("L1", "L2")),
        sex = factor(c("Female", "Female"), levels = c("Female", "Male")),
        age = c(0, 0)
    )

    mod_treatment <- lm(out ~ rbmiGroup * sex + I(age^2), data = dat)
    design_treatment <- ancova_contrast_design(mod_treatment, dat, "out")
    expected_treatment <- model.matrix(
        delete.response(terms(mod_treatment)),
        expected_data,
        contrasts.arg = mod_treatment$contrasts,
        xlev = mod_treatment$xlevels
    )

    expect_equal(design_treatment, expected_treatment)
    expect_equal(unname(design_treatment[, "I(age^2)"]), c(0, 0))
    expect_equal(
        unname(design_treatment[, "rbmiGroupL2:sexMale"]),
        c(0, 0)
    )

    contrasts(dat$rbmiGroup) <- contr.sum(2)
    contrasts(dat$sex) <- contr.sum(2)
    mod_sum <- lm(out ~ rbmiGroup * sex + I(age^2), data = dat)
    design_sum <- ancova_contrast_design(mod_sum, dat, "out")
    expected_sum <- model.matrix(
        delete.response(terms(mod_sum)),
        expected_data,
        contrasts.arg = mod_sum$contrasts,
        xlev = mod_sum$xlevels
    )

    expect_equal(design_sum, expected_sum)
    expect_equal(unname(design_sum[, "I(age^2)"]), c(0, 0))
    expect_equal(unname(design_sum[, "rbmiGroup1:sex1"]), c(1, -1))
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


test_that("custom ancova contrasts pool distinct completed datasets", {
    set.seed(402)
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
        visit = "visit",
        group_contrasts = list(
            b_vs_a = c("B", "A"),
            active_vs_pbo = c(Placebo = -1, A = 0.5, B = 0.5)
        )
    )

    shifts <- c(-2, 0, 3)
    analyses <- lapply(shifts, function(shift) {
        completed <- dat
        completed$out <- completed$out + shift * (completed$grp == "B")
        ancova(completed, vars)
    })
    meta <- attr(analyses[[1]], "rbmi_par_meta")
    ana_obj <- as_analysis(
        results = analyses,
        method = method_bayes(n_samples = length(analyses)),
        par_meta = meta
    )
    pooled <- pool(ana_obj)
    pooled_df <- as.data.frame(pooled)

    for (parameter in c("b_vs_a_v1", "active_vs_pbo_v1")) {
        estimates <- vapply(
            analyses,
            function(x) x[[parameter]]$est,
            numeric(1)
        )
        ses <- vapply(analyses, function(x) x[[parameter]]$se, numeric(1))
        dfs <- vapply(analyses, function(x) x[[parameter]]$df, numeric(1))
        expected <- rubin_rules(
            estimates,
            ses,
            unique(dfs),
            method = "barnard-rubin"
        )
        actual <- pooled_df[pooled_df$parameter == parameter, ]

        expect_gt(var(estimates), 0)
        expect_equal(actual$est, expected$est_point)
        expect_equal(actual$se^2, expected$var_t)

        standardised <- estimates -
            if (parameter == "b_vs_a_v1") shifts else shifts / 2
        expect_equal(
            standardised,
            rep(mean(standardised), 3),
            tolerance = sqrt(.Machine$double.eps)
        )
    }

    pairwise_meta <- pooled_df[pooled_df$parameter == "b_vs_a_v1", ]
    expect_equal(pairwise_meta$estimate_type, "contrast")
    expect_equal(pairwise_meta$contrast_label, "b_vs_a")
    expect_equal(pairwise_meta$group_level_1, "B")
    expect_equal(pairwise_meta$group_level_2, "A")
    expect_equal(pairwise_meta$visit, "v1")

    weighted_meta <- pooled_df[
        pooled_df$parameter == "active_vs_pbo_v1",
    ]
    expect_equal(weighted_meta$estimate_type, "contrast")
    expect_equal(weighted_meta$contrast_label, "active_vs_pbo")
    expect_true(is.na(weighted_meta$group_level_1))
    expect_true(is.na(weighted_meta$group_level_2))
    expect_equal(weighted_meta$visit, "v1")
})


test_that("ancova - weight-vector (pooled) contrasts", {
    set.seed(451)
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
        set_vars(
            outcome = "out",
            group = "grp",
            covariates = "age",
            visit = "visit",
            group_contrasts = list(
                pooled_vs_pbo = c(Placebo = -1, A = 0.5, B = 0.5)
            )
        )
    )

    expect_true("pooled_vs_pbo_v1" %in% names(res))
    # 0.5 * coef(A) + 0.5 * coef(B)  (Placebo is the reference)
    expect_equal(
        res$pooled_vs_pbo_v1$est,
        0.5 * coef(mod)[["grpA"]] + 0.5 * coef(mod)[["grpB"]]
    )
    lvec <- c(0.5, 0.5)
    v <- vc[c("grpA", "grpB"), c("grpA", "grpB")]
    expect_equal(res$pooled_vs_pbo_v1$se, sqrt(drop(t(lvec) %*% v %*% lvec)))

    # An unnamed weight vector must error
    expect_error(
        ancova(
            dat,
            set_vars(
                outcome = "out",
                group = "grp",
                covariates = "age",
                visit = "visit",
                group_contrasts = list(c(Placebo = -1, A = 0.5, B = 0.5))
            )
        ),
        regexp = "named"
    )
})


test_that("ancova - contrasts are invariant to the active contrasts coding", {
    set.seed(452)
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
    vars <- set_vars(
        outcome = "out",
        group = "grp",
        covariates = "age",
        visit = "visit",
        group_contrasts = list(
            a_vs_pbo = c("A", "Placebo"),
            pooled = c(Placebo = -1, A = 0.5, B = 0.5)
        )
    )

    res_default <- ancova(dat, vars)

    old <- options(contrasts = c("contr.sum", "contr.poly"))
    on.exit(options(old), add = TRUE)
    res_sum <- ancova(dat, vars)

    expect_equal(res_sum$a_vs_pbo_v1$est, res_default$a_vs_pbo_v1$est)
    expect_equal(res_sum$a_vs_pbo_v1$se, res_default$a_vs_pbo_v1$se)
    expect_equal(res_sum$pooled_v1$est, res_default$pooled_v1$est)
    expect_equal(res_sum$pooled_v1$se, res_default$pooled_v1$se)
})


test_that("ancova - factor interactions are invariant to contrast coding", {
    set.seed(454)
    n <- 800
    dat <- tibble(
        visit = "v1",
        sex = factor(rep(c("Female", "Male"), each = n / 2)),
        grp = factor(rep(rep(c("Placebo", "Active"), each = n / 4), 2)),
        out = 20 +
            2 * (grp == "Active") +
            4 * (sex == "Male") +
            10 * (grp == "Active") * (sex == "Male") +
            rnorm(n)
    )
    vars <- set_vars(
        outcome = "out",
        group = "grp",
        covariates = "grp * sex",
        visit = "visit"
    )

    old <- options(contrasts = c("contr.treatment", "contr.poly"))
    on.exit(options(old), add = TRUE)
    res_treatment <- ancova(dat, vars)

    options(contrasts = c("contr.sum", "contr.poly"))
    res_sum <- ancova(dat, vars)

    expect_equal(res_sum$trt_v1$est, res_treatment$trt_v1$est)
    expect_equal(res_sum$trt_v1$se, res_treatment$trt_v1$se)
})


test_that("ancova - treatment contrasts support transformed covariates", {
    set.seed(455)
    n <- 400
    dat <- tibble(
        visit = "v1",
        age = rnorm(n),
        grp = factor(
            rep(c("Placebo", "Active"), each = n / 2),
            levels = c("Placebo", "Active")
        ),
        out = 20 + 3 * (grp == "Active") + 2 * age^2 + rnorm(n)
    )
    vars <- set_vars(
        outcome = "out",
        group = "grp",
        covariates = "I(age^2)",
        visit = "visit"
    )
    mod <- lm(out ~ grp + I(age^2), data = dat)

    res <- ancova(dat, vars)

    expect_equal(res$trt_v1$est, coef(mod)[["grpActive"]])
    expect_equal(res$trt_v1$se, sqrt(vcov(mod)["grpActive", "grpActive"]))
})


test_that("ancova - final parameter names are unique across visits", {
    dat <- tibble(
        visit = rep(c("a_b", "b"), each = 8),
        grp = factor(rep(rep(c("Placebo", "Active"), each = 4), 2)),
        out = c(seq_len(8), seq_len(8) * 2)
    )
    vars <- set_vars(
        outcome = "out",
        group = "grp",
        visit = "visit",
        group_contrasts = list(
            foo = c("Active", "Placebo"),
            foo_a = c("Active", "Placebo")
        )
    )

    expect_error(
        ancova(dat, vars),
        regexp = "Contrast names and visit names must produce unique parameter names"
    )
})


test_that("ancova - named contrasts populate the contrast_label metadata", {
    set.seed(453)
    n <- 300
    grp_levels <- c("Placebo", "A", "B")
    dat <- tibble(
        visit = "v1",
        age = rnorm(n),
        grp = factor(
            sample(grp_levels, size = n, replace = TRUE),
            levels = grp_levels
        ),
        out = rnorm(n, mean = 50 + 2 * age, sd = 8)
    )
    vars <- set_vars(
        outcome = "out",
        group = "grp",
        covariates = "age",
        visit = "visit",
        group_contrasts = list(
            A_vs_PBO = c("A", "Placebo"),
            pooled = c(Placebo = -1, A = 0.5, B = 0.5)
        )
    )
    ana <- ancova(dat, vars)
    meta <- attr(ana, "rbmi_par_meta")

    # Named pairwise contrast: the label is the parameter name and contrast_label.
    row_a <- meta[meta$parameter == "A_vs_PBO_v1", ]
    expect_equal(row_a$contrast_label, "A_vs_PBO")
    expect_equal(row_a$group_level_1, "A")
    expect_equal(row_a$group_level_2, "Placebo")

    # Weight-vector contrast uses the label as the parameter name; levels are NA.
    row_p <- meta[meta$parameter == "pooled_v1", ]
    expect_equal(row_p$contrast_label, "pooled")
    expect_true(is.na(row_p$group_level_1))
    expect_true(is.na(row_p$group_level_2))

    # contrast_label flows through pool() -> as.data.frame()
    ana_obj <- as_analysis(
        results = replicate(3, ana, simplify = FALSE),
        method = method_bayes(n_samples = 3),
        par_meta = meta
    )
    df <- as.data.frame(pool(ana_obj))
    expect_true("contrast_label" %in% names(df))
    expect_equal(df$contrast_label[df$parameter == "pooled_v1"], "pooled")
})
