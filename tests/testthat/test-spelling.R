test_that("spelling", {
    skip_if_not(is_core_test())
    skip_on_covr()

    if (requireNamespace('spelling', quietly = TRUE)) {
        pkg <- test_path("../../")
        if (!file.exists(file.path(pkg, "DESCRIPTION"))) {
            pkg <- file.path(pkg, "00_pkg_src", .packageName)
        }

        results <- spelling::spell_check_package(pkg, vignettes = TRUE)

        if (nrow(results) > 0) {
            printed_results <- paste(
                capture.output(print(results)),
                collapse = "\n"
            )
            stop(
                "Potential spelling errors:\n",
                printed_results,
                "\n",
                "If these are false positive, run `spelling::update_wordlist()`.",
                call. = FALSE
            )
        } else {
            testthat::expect_all_true(nrow(results) == 0)
        }
    }
})
