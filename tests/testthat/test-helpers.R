library(testthat)

test_that("utilities exports behave sensibly", {
  expect_true(is.character(extract_covariates(c("v1", "v2:v3"))))
  expect_setequal(extract_covariates(c("v1", "v2:v3")), c("v1", "v2", "v3"))
  f <- as_simple_formula("y", c("a", "b"))
  expect_s3_class(f, "formula")
})

test_that("pool helpers and CI functions", {
  expect_equal(get_pool_components("rubin"), c("est", "df", "se"))
  rr <- rubin_rules(ests = c(1, 2, 3), ses = c(1, 1, 1), v_com = 10)
  expect_named(rr, c("est_point", "var_t", "df"))
  pc <- parametric_ci(1, 1, 0.05, "two.sided", qnorm, pnorm)
  expect_named(pc, c("est", "ci", "se", "pvalue"))
  tr_in <- list(list(a = list(est = 1, se = 2)), list(a = list(est = 3, se = 4)))
  tr_out <- transpose_results(tr_in, c("est", "se"))
  expect_true(is.list(tr_out))
  expect_named(tr_out, "a")
})

test_that("as_analysis constructs analysis object", {
  method <- list(n_samples = 3, D = 1)
  class(method) <- c("method", "bayes")
  results <- list(
  list(par1 = list(est = 1, df = 1, se = 2)),
  list(par1 = list(est = 2, df = 1, se = 2)),
  list(par1 = list(est = 3, df = 1, se = 2))
  )
  ana <- as_analysis(results, method = method, delta = NULL, fun = NULL, fun_name = "fn")
  expect_s3_class(ana, "analysis")
})
