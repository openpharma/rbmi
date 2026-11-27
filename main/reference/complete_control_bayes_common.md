# Complete Common Stan Control Options for Bayesian Methods

This function completes the control options list for Bayesian methods by
setting the number of iterations, refresh rate, and initial values based
on the provided arguments.

## Usage

``` r
complete_control_bayes_common(
  control,
  n_samples,
  quiet,
  outcome = c("continuous", "count")
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

- outcome:

  Outcome type used to resolve the initialisation policy.

## Value

A completed control options list including computed `iter` and `refresh`
values and resolved `init`. The `initialisation` attribute retains the
resolved policy before model-specific expansion of starting values.
