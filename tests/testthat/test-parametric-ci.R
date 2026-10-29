test_that("normal confidence functions use the parameter scale and retain metadata", {
    point <- -5
    scale <- 2
    qfun <- function(p) qnorm(p, mean = point, sd = scale)
    pfun <- function(q, lower.tail = TRUE) {
        pnorm(q, mean = point, sd = scale, lower.tail = lower.tail)
    }

    for (alternative in c("two.sided", "greater", "less")) {
        observed <- parametric_ci(
            point, NA_real_, 0.05, alternative, qfun, pfun, null = 1
        )
        expected_ci <- switch(
            alternative,
            two.sided = point + c(-1, 1) * scale * qnorm(0.975),
            greater = c(-Inf, point + scale * qnorm(0.95)),
            less = c(point - scale * qnorm(0.95), Inf)
        )
        expected_pvalue <- switch(
            alternative,
            two.sided = 2 * pnorm(-3),
            greater = pnorm(3),
            less = pnorm(-3)
        )

        expect_equal(observed, list(
            est = point,
            ci = expected_ci,
            se = NA_real_,
            pvalue = expected_pvalue
        ))
        expect_lte(observed$ci[1], observed$ci[2])
    }
})


test_that("t confidence functions agree with t.test for zero and nonzero nulls", {
    x <- c(-7, -6, -5, -4, -3)
    point <- mean(x)
    se <- sd(x) / sqrt(length(x))
    df <- length(x) - 1
    qfun <- function(p) point + se * qt(p, df = df)
    pfun <- function(q, lower.tail = TRUE) {
        pt((q - point) / se, df = df, lower.tail = lower.tail)
    }

    for (null in c(0, -4, point)) {
        for (alternative in c("two.sided", "greater", "less")) {
            observed <- parametric_ci(
                point, se, 0.05, alternative, qfun, pfun, null = null
            )
            reference <- t.test(x, mu = null, alternative = alternative)

            # Preserve the existing one-sided bound convention.
            bound_alternative <- switch(
                alternative,
                two.sided = "two.sided",
                greater = "less",
                less = "greater"
            )
            reference_ci <- t.test(x, alternative = bound_alternative)$conf.int

            expect_equal(observed$pvalue, reference$p.value)
            expect_equal(observed$ci, as.numeric(reference_ci))
        }
    }

    expect_equal(
        parametric_ci(point, se, 0.05, "two.sided", qfun, pfun),
        parametric_ci(point, se, 0.05, "two.sided", qfun, pfun, null = 0)
    )
})


test_that("confidence functions need not be symmetric or have unbounded support", {
    qfun <- function(p) qexp(p, rate = 2)
    pfun <- function(q, lower.tail = TRUE) {
        pexp(q, rate = 2, lower.tail = lower.tail)
    }

    for (alternative in c("two.sided", "greater", "less")) {
        observed <- parametric_ci(
            0.5, 0.5, 0.05, alternative, qfun, pfun, null = 0.25
        )
        expected_ci <- switch(
            alternative,
            two.sided = -log(c(0.975, 0.025)) / 2,
            greater = c(0, -log(0.05) / 2),
            less = c(-log(0.95) / 2, Inf)
        )
        expected_pvalue <- switch(
            alternative,
            two.sided = 2 * (1 - exp(-0.5)),
            greater = 1 - exp(-0.5),
            less = exp(-0.5)
        )

        expect_equal(observed$ci, expected_ci)
        expect_equal(observed$pvalue, expected_pvalue)
    }
})


test_that("small p-values retain precision in both tails", {
    for (point in c(-20, 20)) {
        qfun <- function(p) qnorm(p, mean = point)
        pfun <- function(q, lower.tail = TRUE) {
            pnorm(q, mean = point, lower.tail = lower.tail)
        }
        alternative <- if (point > 0) "greater" else "less"
        one_sided <- parametric_ci(point, 1, 0.05, alternative, qfun, pfun)
        two_sided <- parametric_ci(point, 1, 0.05, "two.sided", qfun, pfun)
        expected <- pnorm(-20)

        expect_gt(one_sided$pvalue, 0)
        expect_equal(one_sided$pvalue / expected, 1)
        expect_equal(two_sided$pvalue / expected, 2)
    }
})


test_that("normal pooling preserves undefined results when the SE is zero", {
    for (point in c(-1, 0, 1)) {
        ests <- c(point, 1, 1, 1)
        p_less <- if (point == 0) NaN else as.numeric(point > 0)

        for (alternative in c("two.sided", "greater", "less")) {
            expected <- list(
                est = point,
                ci = switch(
                    alternative,
                    two.sided = c(point, point),
                    greater = c(NaN, point),
                    less = c(point, NaN)
                ),
                se = 0,
                pvalue = switch(
                    alternative,
                    two.sided = if (point == 0) NaN else 0,
                    greater = 1 - p_less,
                    less = p_less
                )
            )
            bootstrap <- pool_bootstrap_normal(ests, 0.95, alternative)
            jackknife <- pool_internal.jackknife(
                list(est = ests), conf.level = 0.95, alternative = alternative
            )

            expect_identical(bootstrap, expected)
            expect_identical(jackknife, expected)
        }
    }
})
