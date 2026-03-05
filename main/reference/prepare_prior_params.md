# Prepare Prior Parameters for Covariance Model Prior Distribution

Based on the `covariance` and `prior_cov` choices, this function
prepares the prior parameters for the covariance model.

## Usage

``` r
prepare_prior_params(stan_data, covariance, prior_cov, mmrm_initial, same_cov)
```

## Arguments

- stan_data:

  A list containing the Stan data, to which the prior parameters will be
  added.

- covariance:

  A character string indicating the covariance structure (e.g., `"us"`,
  `"ar1"`).

- prior_cov:

  A character string indicating the prior covariance type (e.g.,
  `"default"`, `"lkj"`).

- mmrm_initial:

  A list containing the initial MMRM fit results, which includes the
  relevant frequentist estimates.

- same_cov:

  A logical indicating whether to use the same covariance structure for
  all groups.

## Value

Modified `stan_data` with prior parameters added.
