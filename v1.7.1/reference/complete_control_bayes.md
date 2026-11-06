# Completion of the Control Options List

This function completes the control options list for Bayesian methods by
setting the number of iterations, refresh rate, and initial values based
on the provided arguments.

## Usage

``` r
complete_control_bayes(
  control,
  n_samples,
  quiet,
  stan_data,
  mmrm_initial,
  covariance,
  prior_cov
)
```

## Arguments

- control:

  A list containing part of the control options. Must not contain
  `iter`, `refresh`, `object`, `data`, or `pars`.

- n_samples:

  Number of samples to be drawn.

- quiet:

  A logical indicating whether to suppress output during sampling.

- stan_data:

  A list containing the Stan data.

- mmrm_initial:

  A list containing the initial values from the MMRM.

- covariance:

  A character string indicating the type of covariance structure.

- prior_cov:

  A character string indicating the type of prior for the covariance
  parameters.

## Value

A completed control options list with the necessary parameters for
Bayesian sampling.
