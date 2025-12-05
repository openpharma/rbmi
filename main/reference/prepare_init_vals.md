# Preparation of Initial Values for MCMC Sampler

This function is used by
[`complete_control_bayes()`](https://insightsengineering.github.io/rbmi/reference/complete_control_bayes.md)
when the `init` argument is set to `"mmrm"`.

## Usage

``` r
prepare_init_vals(stan_data, mmrm_initial, chains, covariance, prior_cov)
```

## Arguments

- stan_data:

  A list containing the Stan data.

- mmrm_initial:

  A list containing the initial values from the MMRM, including
  attribute `cov_param_names` specifying the names of the covariance
  parameters.

- chains:

  The number of chains.

- covariance:

  A character string indicating the type of covariance structure.

- prior_cov:

  A character string indicating the type of prior for the covariance
  parameters.

## Value

A list of initial values for the MCMC sampler.
