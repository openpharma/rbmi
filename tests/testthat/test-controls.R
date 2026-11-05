test_that("control_bayes", {
    set.seed(123)

    result <- control_bayes()
    expect_equal(
        control_bayes(),
        list(
            warmup = 200,
            thin = 50,
            chains = 1,
            init = "auto",
            seed = 1756553742
        )
    )
    set.seed(123)
    result <- control_bayes()
    expect_equal(
        control_bayes(verbose = TRUE),
        list(
            warmup = 200,
            thin = 50,
            chains = 1,
            init = "auto",
            seed = 1756553742,
            verbose = TRUE
        )
    )
    expect_error(
        control_bayes(n_samples = 1000),
        "specify the number of samples directly"
    )
    expect_error(
        control_bayes(iter = 1000),
        "specify the number of samples directly"
    )
    expect_error(
        control_bayes(refresh = 1000),
        "of the `refresh` argument here"
    )
})

test_that("prepare_init_vals works as expected", {
    # We use dummy inputs here for simplicity.
    stan_data <- list(R = matrix(2, nrow = 1, ncol = 1))
    mmrm_initial <- structure(
        list(
            beta = 4,
            sigma = list(matrix(c(1, 0, 0, 2), nrow = 2)),
            tau = 3
        ),
        cov_param_names = c("sigma", "tau")
    )

    result_us_default <- prepare_init_vals(
        stan_data = stan_data,
        mmrm_initial = mmrm_initial,
        chains = 1,
        covariance = "us",
        prior_cov = "default"
    )
    expected_us_default <- list(
        list(theta = 8, sigma = mmrm_initial$sigma, tau = mmrm_initial$tau)
    )
    expect_identical(result_us_default, expected_us_default)

    result_us_lkj <- prepare_init_vals(
        stan_data = stan_data,
        mmrm_initial = mmrm_initial,
        chains = 1,
        covariance = "us",
        prior_cov = "lkj"
    )
    expected_us_lkj <- list(
        list(
            theta = 8,
            sigma = mmrm_initial$sigma,
            tau = mmrm_initial$tau,
            sds = list(c(1, sqrt(2))),
            corr_chol = list(diag(2))
        )
    )
    expect_identical(result_us_lkj, expected_us_lkj)
})

test_that("complete_control_bayes_common works as expected", {
    result <- complete_control_bayes_common(
        control = control_bayes(init = "random"),
        n_samples = 1000,
        quiet = FALSE
    )

    expect_true(is.list(result))
    expect_equal(result$iter, result$warmup + result$thin * 1000)
    expect_equal(result$refresh, ceiling(result$iter / 10))
    expect_identical(result$init, "random")
})

test_that("complete_control_bayes_common validates forbidden arguments", {
    expect_error(
        complete_control_bayes_common(
            control = c(control_bayes(), list(iter = 1000)),
            n_samples = 10,
            quiet = TRUE
        ),
        "must not be specified directly"
    )

    expect_error(
        complete_control_bayes_common(
            control = c(control_bayes(), list(refresh = 1000)),
            n_samples = 10,
            quiet = TRUE
        ),
        "must not be specified directly"
    )

    expect_error(
        complete_control_bayes_common(
            control = c(control_bayes(), list(object = 1)),
            n_samples = 10,
            quiet = TRUE
        ),
        "must not be specified"
    )
})

test_that("complete_control_bayes works as expected", {
    control <- control_bayes()
    # We use dummy inputs here for simplicity.
    stan_data <- list(R = matrix(1, nrow = 1, ncol = 1))
    mmrm_initial <- structure(
        list(beta = 1, sigma = 1, tau = 1),
        cov_param_names = c("sigma", "tau")
    )
    result <- complete_control_bayes(
        control = control,
        n_samples = 1000,
        quiet = TRUE,
        stan_data = stan_data,
        mmrm_initial = mmrm_initial,
        covariance = "us",
        prior_cov = "default"
    )
    expect_true(is.list(result))
    expect_true(
        is.list(result$init),
        setequal(names(result$init), c("theta", "sigma", "tau"))
    )
    expect_identical(attr(result, "initialisation"), "mmrm")
})


test_that("count control uses random initialization for auto", {
    result <- complete_control_bayes_count(
        control = control_bayes(),
        n_samples = 4,
        quiet = TRUE
    )

    expect_identical(result$init, "random")
    expect_equal(result$iter, result$warmup + result$thin * 4)
})


test_that("auto resolves by outcome and chain count", {
    control <- complete_control_bayes_common(
        control_bayes(chains = 1), 4, TRUE, outcome = "continuous"
    )
    expect_identical(control$init, "mmrm")
    expect_identical(attr(control, "initialisation"), "mmrm")
    control <- complete_control_bayes_common(
        control_bayes(chains = 2), 4, TRUE, outcome = "continuous"
    )
    expect_identical(control$init, "random")
    expect_identical(attr(control, "initialisation"), "random")
    control <- complete_control_bayes_common(
        control_bayes(chains = 1), 4, TRUE, outcome = "count"
    )
    expect_identical(control$init, "random")
    expect_identical(attr(control, "initialisation"), "random")
    control <- complete_control_bayes_common(
        control_bayes(chains = 2), 4, TRUE, outcome = "count"
    )
    expect_identical(control$init, "random")
    expect_identical(attr(control, "initialisation"), "random")
    expect_error(
        complete_control_bayes_count(control_bayes(init = "mmrm"), 4, TRUE),
        "requires continuous outcomes"
    )
})


test_that("both model controls preserve custom Stan initialisers", {
    initialisers <- list(
        "random", "0", 0, list(list(beta = c(0, 0), phi = 1)),
        function(chain_id) stop("Must not evaluate during control completion")
    )
    for (init in initialisers) {
        control <- control_bayes(init = init)
        expect_identical(complete_control_bayes_count(control, 4, TRUE)$init, init)
        expect_identical(complete_control_bayes(control, 4, TRUE)$init, init)
    }
})


test_that("count initialisers reach the sampling boundary unchanged", {
    skip_if_not_installed("rstan")
    received <- NULL
    local_mocked_bindings(get_stan_model_count = function() NULL, .package = "rbmi")
    local_mocked_bindings(
        sampling = function(object, ..., init) {
            received <<- init
            stop("sampling intercepted")
        },
        .package = "rstan"
    )
    for (init in list("auto", "0", 0, list(list(beta = 0, phi = 1)),
                      function(chain_id) list(phi = 1))) {
        expect_error(
            fit_mcmc(
                outcome_type = "count",
                designmat = matrix(1, 2, 1),
                outcome = c(1, 2),
                group = factor(c("A", "A")),
                subjid = factor(c("a", "b")),
                visit = factor(c(1, 1)),
                duration = c(1, 1),
                method = method_bayes(control = control_bayes(init = init)),
                scaler = list()
            ),
            "sampling intercepted"
        )
        expect_identical(received, if (identical(init, "auto")) "random" else init)
    }
})
