# Diagnostics of the MCMC based on ESS

Check the quality of the MCMC draws from the posterior distribution by
checking whether the relative ESS is sufficiently large.

## Usage

``` r
check_ESS(stan_fit, n_draws, threshold_lowESS = 0.4)
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

`check_ESS()` works as follows:

1.  Extract the ESS from `stan_fit` for each parameter of the model.

2.  Compute the relative ESS (i.e. the ESS divided by the number of
    draws).

3.  Check whether for any of the parameter the ESS is lower than
    `threshold`. If for at least one parameter the relative ESS is below
    the threshold, a warning is thrown.
