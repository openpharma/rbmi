# Diagnostics of the MCMC based on HMC-related measures.

Check that:

1.  There are no divergent iterations.

2.  The Bayesian Fraction of Missing Information (BFMI) is sufficiently
    low.

3.  The number of iterations that saturated the max treedepth is zero.

Please see
[`rstan::check_hmc_diagnostics()`](https://mc-stan.org/rstan/reference/check_hmc_diagnostics.html)
for details.

## Usage

``` r
check_hmc_diagn(stan_fit)
```

## Arguments

- stan_fit:

  A `stanfit` object.

## Value

A warning message in case of detected problems.
