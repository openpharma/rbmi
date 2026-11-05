test_that("Schur inversion agrees with direct inversion", {
    # Include a scalar leading block and an indefinite full matrix: the
    # helper performs the algebra; the caller decides whether it is suitable.
    for (a in list(matrix(2), matrix(c(4, 1, 1, 3), 2))) {
        b <- seq_len(nrow(a)) / 2
        for (d in c(3, -1)) {
            full <- rbind(cbind(a, b), c(b, d))

            expect_equal(
                schur_inverse(a, b, d),
                unname(solve(full))
            )
        }
    }
})


test_that("Schur inversion returns NULL for zero and nonfinite complements", {
    for (c in c(1, NA_real_, NaN, Inf, -Inf)) {
        expect_null(schur_inverse(matrix(1), 1, c))
    }
})
