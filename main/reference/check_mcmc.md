# Diagnostics of the MCMC

Diagnostics of the MCMC

## Usage

``` r
check_mcmc(stan_fit, n_draws, threshold_lowESS = 0.4)
```

## Arguments

- stan_fit:

  A `stanfit` object.

- n_draws:

  Number of MCMC draws.

- threshold_lowESS:

  A number in `[0,1]` indicating the minimum acceptable value of the
  relative ESS. See details.

## Value

A warning message in case of detected problems.

## Details

Performs checks of the quality of the MCMC. See
[`check_ESS()`](https://insightsengineering.github.io/rbmi/reference/check_ESS.md)
and
[`check_hmc_diagn()`](https://insightsengineering.github.io/rbmi/reference/check_hmc_diagn.md)
for details.
