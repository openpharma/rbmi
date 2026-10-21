suppressPackageStartupMessages({
    library(testthat)
})


test_that("count likelihood remains accurate near the Poisson limit", {
    skip_if_not(is_core_test())

    # A subject with two cells checks the joint likelihood; totals of zero
    # and one also exercise the empty finite-product cases.
    stan_data <- list(
        N = 3L,
        R = 4L,
        P = 1L,
        G = 3L,
        group = 1:3,
        subject = c(1L, 1L, 2L, 3L),
        y = c(1L, 2L, 0L, 1L),
        X = matrix(1, 4, 1),
        log_offset = log(c(1, 2, 1, 1))
    )
    beta <- array(log(0.7), dim = 1)
    fit <- rstan::sampling(
        get_stan_model_count(),
        data = stan_data,
        chains = 1,
        iter = 1,
        warmup = 0,
        algorithm = "Fixed_param",
        init = list(list(beta = beta, phi = rep(0.5, 3))),
        seed = 42,
        refresh = 0
    )
    dispersion <- c(0.5, 1e-4, 1e-8, 1e-12, 2 * .Machine$double.eps)
    actual <- vapply(dispersion, function(phi) {
        parameters <- rstan::unconstrain_pars(
            fit,
            list(beta = beta, phi = rep(phi, 3))
        )
        rstan::log_prob(fit, parameters, adjust_transform = FALSE)
    }, numeric(1))
    expected <- vapply(dispersion, function(phi) {
        # Independent reference: negative-binomial subject totals and the
        # multinomial allocation of the first subject's total across cells.
        sum(dnbinom(
            c(3, 0, 1), size = 1 / phi, mu = c(2.1, 0.7, 0.7), log = TRUE
        )) + dmultinom(c(1, 2), prob = c(1, 2), log = TRUE) +
            3 * dgamma(phi, shape = 0.0001, rate = 0.0001, log = TRUE)
    }, numeric(1))

    # Stan omits constants that do not depend on parameters.
    expect_equal(actual - actual[1], expected - expected[1], tolerance = 1e-10)
})


test_that("count Stan model is reused from the model cache", {
    skip_if_not(is_core_test())

    local_cache_dir <- withr::local_tempdir()
    withr::local_options(
        rbmi.enable_cache = TRUE,
        rbmi.cache_dir = local_cache_dir
    )

    set.seed(4812)
    expected_random_value <- stats::runif(1)
    set.seed(4812)
    first_model <- expect_silent(get_stan_model_count())
    expect_equal(stats::runif(1), expected_random_value)
    expect_s4_class(first_model, "stanmodel")

    stan_files <- list.files(
        local_cache_dir,
        pattern = "^rbmi_count_model_.*[.]stan$",
        full.names = TRUE
    )
    expect_length(stan_files, 1)
    rds_file <- sub("[.]stan$", ".rds", stan_files)
    expect_true(file.exists(rds_file))

    # Let rstan unload the first model's DSO so it can safely restore the
    # serialized model on the next call.
    rm(first_model)
    invisible(gc())

    old_stan_time <- as.POSIXct("2000-01-01", tz = "UTC")
    future_rds_time <- Sys.time() + 3600
    Sys.setFileTime(stan_files, old_stan_time)
    Sys.setFileTime(rds_file, future_rds_time)

    second_model <- expect_silent(get_stan_model_count())
    expect_s4_class(second_model, "stanmodel")
    expect_equal(
        as.numeric(file.info(stan_files)$mtime),
        as.numeric(old_stan_time)
    )
    expect_equal(
        as.numeric(file.info(rds_file)$mtime),
        as.numeric(future_rds_time)
    )
})


test_that("count MCMC returns named group-specific dispersion draws", {
    skip_if_not(is_core_test())

    dat <- utils::read.csv(system.file(
        "extdata",
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
