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

test_that("control_bayes warns if several chains start at the MMRM estimates", {
    expect_warning(
        control_bayes(chains = 2, init = "mmrm"),
        "starts all 2 chains at the same values"
    )
    expect_no_warning(control_bayes(chains = 2))
    expect_no_warning(control_bayes(chains = 1, init = "mmrm"))
})

test_that("prepare_init_vals returns MMRM estimates in Stan names and shapes", {
    sigma <- list(
        A = matrix(c(4, 1, 0.5, 1, 5, 1.5, 0.5, 1.5, 6), nrow = 3),
        B = matrix(c(2, 0.4, 0.2, 0.4, 3, 0.6, 0.2, 0.6, 4), nrow = 3)
    )
    # Mimics fit_mmrm(): per-group lists, repeated if same_cov = TRUE.
    mmrm_initial <- function(...) {
        pars <- list(...)
        structure(
            c(list(beta = c(1, 2), sigma = sigma), pars),
            cov_param_names = c("sigma", names(pars))
        )
    }
    init <- function(
        mmrm,
        covariance,
        prior_cov = "default",
        G = 2,
        chains = 1
    ) {
        prepare_init_vals(
            stan_data = list(R = diag(2, nrow = 2), G = G),
            mmrm_initial = mmrm,
            chains = chains,
            covariance = covariance,
            prior_cov = prior_cov
        )
    }

    us <- init(mmrm_initial(), "us")
    expect_length(us, 1)
    us <- us[[1]]
    expect_setequal(names(us), c("theta", "Sigma"))
    expect_equal(us$theta, c(2, 4))
    expect_equal(dim(us$Sigma), c(2, 3, 3))
    expect_equal(us$Sigma[1, , ], sigma$A)
    expect_equal(us$Sigma[2, , ], sigma$B)

    lkj <- init(mmrm_initial(), "us", prior_cov = "lkj")[[1]]
    expect_setequal(names(lkj), c("theta", "vars", "corr_chol"))
    expect_equal(lkj$vars, rbind(diag(sigma$A), diag(sigma$B)))
    expect_equal(dim(lkj$corr_chol), c(2, 3, 3))
    for (g in 1:2) {
        corr_chol <- lkj$corr_chol[g, , ]
        expect_equal(corr_chol[upper.tri(corr_chol)], rep(0, 3))
        expect_equal(corr_chol %*% t(corr_chol), cov2cor(sigma[[g]]))
    }

    ar1 <- init(
        mmrm_initial(sd = list(A = 2, B = 1.5), rho = list(A = 0.3, B = -0.2)),
        "ar1"
    )[[1]]
    expect_setequal(names(ar1), c("theta", "var_const", "rho"))
    expect_equal(ar1$var_const, array(c(4, 2.25), dim = 2))
    expect_equal(ar1$rho, array(c(0.3, -0.2), dim = 2))

    # Only `sds` is given, so `$sd` would partial-match it.
    csh <- init(
        mmrm_initial(
            sds = list(A = 1:3, B = c(2, 2, 2)),
            rho = list(A = 0.3, B = 0.1)
        ),
        "csh"
    )[[1]]
    expect_setequal(names(csh), c("theta", "vars", "rho"))
    expect_equal(csh$vars, rbind(c(1, 4, 9), c(4, 4, 4)))
    expect_equal(csh$rho, array(c(0.3, 0.1), dim = 2))

    toep <- init(
        mmrm_initial(
            sd = list(A = 2, B = 1),
            rhos = list(A = c(0.3, 0.1), B = c(0.2, -0.1))
        ),
        "toep"
    )[[1]]
    expect_setequal(names(toep), c("theta", "var_const", "rhos"))
    expect_equal(toep$var_const, array(c(4, 1), dim = 2))
    expect_equal(toep$rhos, rbind(c(0.3, 0.1), c(0.2, -0.1)))

    adh <- init(
        mmrm_initial(
            sds = list(A = 1:3, B = 3:1),
            rhos = list(A = c(0.3, 0.1), B = c(0.2, 0.5))
        ),
        "adh"
    )[[1]]
    expect_setequal(names(adh), c("theta", "vars", "rhos"))
    expect_equal(adh$vars, rbind(c(1, 4, 9), c(9, 4, 1)))
    expect_equal(adh$rhos, rbind(c(0.3, 0.1), c(0.2, 0.5)))

    # same_cov = TRUE: the Stan models have a single group.
    shared <- init(
        mmrm_initial(sd = list(A = 2, B = 2), rho = list(A = 0.3, B = 0.3)),
        "cs",
        G = 1,
        chains = 2
    )
    expect_length(shared, 2)
    expect_identical(shared[[1]], shared[[2]])
    expect_equal(shared[[1]]$var_const, array(4, dim = 1))
    expect_equal(shared[[1]]$rho, array(0.3, dim = 1))
    us_shared <- init(mmrm_initial(), "us", G = 1)[[1]]
    expect_equal(dim(us_shared$Sigma), c(1, 3, 3))
    expect_equal(us_shared$Sigma[1, , ], sigma$A)
})

test_that("stack_by_group puts groups first and keeps vector shapes", {
    expect_equal(stack_by_group(list(1:3, 4:6)), rbind(1:3, 4:6))
    # With two visits, `rhos` has one element per group: `array[G] vector[1]`.
    expect_equal(stack_by_group(list(A = 0.3, B = 0.2)), matrix(c(0.3, 0.2)))
    expect_equal(dim(stack_by_group(list(matrix(1)))), c(1, 1, 1))
    m <- matrix(1:6, nrow = 2)
    expect_equal(stack_by_group(list(m, 2 * m))[2, , ], 2 * m)
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

test_that("complete_control_bayes works as expected", {
    control <- control_bayes()
    # We use dummy inputs here for simplicity.
    stan_data <- list(R = matrix(1, nrow = 1, ncol = 1), G = 1)
    mmrm_initial <- structure(
        list(beta = 1, sigma = list(matrix(1))),
        cov_param_names = "sigma"
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
    expect_identical(attr(result, "initialisation"), "mmrm")
    expect_length(result$init, 1)
    expect_setequal(names(result$init[[1]]), c("theta", "Sigma"))
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
        control_bayes(chains = 1),
        4,
        TRUE,
        outcome = "continuous"
    )
    expect_identical(control$init, "mmrm")
    expect_identical(attr(control, "initialisation"), "mmrm")
    control <- complete_control_bayes_common(
        control_bayes(chains = 2),
        4,
        TRUE,
        outcome = "continuous"
    )
    expect_identical(control$init, "random")
    expect_identical(attr(control, "initialisation"), "random")
    control <- complete_control_bayes_common(
        control_bayes(chains = 1),
        4,
        TRUE,
        outcome = "count"
    )
    expect_identical(control$init, "random")
    expect_identical(attr(control, "initialisation"), "random")
    control <- complete_control_bayes_common(
        control_bayes(chains = 2),
        4,
        TRUE,
        outcome = "count"
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
        "random",
        "0",
        0,
        list(list(beta = c(0, 0), phi = 1)),
        function(chain_id) stop("Must not evaluate during control completion")
    )
    for (init in initialisers) {
        control <- control_bayes(init = init)
        expect_identical(
            complete_control_bayes_count(control, 4, TRUE)$init,
            init
        )
        expect_identical(complete_control_bayes(control, 4, TRUE)$init, init)
    }
})


test_that("count initialisers reach the sampling boundary unchanged", {
    skip_if_not_installed("rstan")
    received <- NULL
    local_mocked_bindings(
        get_stan_model_count = function() NULL,
        .package = "rbmi"
    )
    local_mocked_bindings(
        sampling = function(object, ..., init) {
            received <<- init
            stop("sampling intercepted")
        },
        .package = "rstan"
    )
    for (init in list(
        "auto",
        "0",
        0,
        list(list(beta = 0, phi = 1)),
        function(chain_id) list(phi = 1)
    )) {
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
        expect_identical(
            received,
            if (identical(init, "auto")) "random" else init
        )
    }
})
