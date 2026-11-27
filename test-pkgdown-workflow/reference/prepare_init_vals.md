# Preparation of Initial Values for MCMC Sampler

This function is used by
[`complete_control_bayes()`](https://openpharma.github.io/rbmi/reference/complete_control_bayes.md)
when the `init` argument is set to `"mmrm"`. It converts the MMRM
estimates to the names and shapes of the parameters of the Stan model:
`theta`, plus `Sigma` (`"us"`), `corr_chol` and `vars` (`"us"` with LKJ
prior), `var_const` (homogeneous variance structures) or `vars`
(heterogeneous variance structures), and `rho` or `rhos` (correlation
parameters).

## Usage

``` r
prepare_init_vals(stan_data, mmrm_initial, chains, covariance, prior_cov)
```

## Arguments

- stan_data:

  A list containing the Stan data, including the number of covariance
  groups `G`.

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

A list of initial values for the MCMC sampler, one per chain.
