suppressPackageStartupMessages({
    library(testthat)
})


test_that("count MCMC returns named group-specific dispersion draws", {
    skip_if_not(is_core_test())

    dat <- utils::read.csv(system.file(
        "data",
        "sim_rogeretal.csv",
        package = "rbmi"
    ))
    dat <- dat[, c(
        "patient",
        "period",
        "TreatLab",
        "OnOff",
        "Length",
        "BaseCount",
        "Observed_Count"
    )]
    dat$patient <- factor(dat$patient)
    dat$period <- as.character(dat$period)
    dat$TreatLab <- factor(
        dat$TreatLab,
        levels = c("Placebo", "100mg", "300mg")
    )
    dat <- expand_locf(
        dat,
        patient = levels(dat$patient),
        period = as.character(1:3),
        vars = c("TreatLab", "BaseCount"),
        group = "patient",
        order = c("patient", "period")
    )
    dat$OnOff <- factor(
        ifelse(dat$period == "1", "On", "Off"),
        levels = c("On", "Off")
    )
    dat$Length[is.na(dat$Length)] <- 0

    dat_ice <- unique(
        dat[dat$period == "3" & dat$Length > 0, "patient", drop = FALSE]
    )
    dat_ice$strategy <- "MAR"
    vars <- set_vars(
        outcome = "Observed_Count",
        subjid = "patient",
        period = "period",
        duration = "Length",
        group = "TreatLab",
        covariates = c("TreatLab:OnOff", "TreatLab:BaseCount")
    )
    method <- method_bayes(
        same_cov = FALSE,
        n_samples = 2,
        control = control_bayes(
            warmup = 30,
            thin = 1,
            chains = 1,
            seed = 1821,
            control = list(adapt_delta = 0.9)
        )
    )

    result <- suppressWarnings(draws(
        outcome = "count",
        data = dat,
        data_ice = dat_ice,
        vars = vars,
        method = method,
        quiet = TRUE
    ))

    expect_s3_class(result, "draws_count")
    expect_length(result$samples, 2)
    expect_true(all(vapply(
        result$samples,
        function(x) identical(names(x$phi), levels(dat$TreatLab)),
        logical(1)
    )))
})
