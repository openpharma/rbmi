test_that("count dispersion lower bound is configurable and validated", {
    prepare <- function() {
        prepare_stan_data_count(
            ddat = matrix(1, 2, 1),
            subjid = c("1", "2"),
            period = c(1, 1),
            duration = c(1, 1),
            outcome = c(1, 2),
            group = factor(c("Control", "Active")),
            same_cov = TRUE
        )
    }

    withr::local_options(rbmi.count_phi_lower = NULL)
    set_options()
    expect_identical(getOption("rbmi.count_phi_lower"), 1e-6)
    expect_identical(prepare()$phi_lower, 1e-6)

    options(rbmi.count_phi_lower = 1e-4)
    set_options()
    expect_identical(prepare()$phi_lower, 1e-4)

    invalid <- list(0, -1, Inf, -Inf, NA_real_, NaN, "1e-6", TRUE,
                    numeric(), c(1e-6, 1e-4))
    for (value in invalid) {
        options(rbmi.count_phi_lower = value)
        expect_error(prepare(), "rbmi.count_phi_lower")
    }
})
