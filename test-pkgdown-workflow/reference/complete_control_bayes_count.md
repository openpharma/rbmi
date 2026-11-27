# Complete Stan control options for count outcomes

Complete Stan control options for count outcomes

## Usage

``` r
complete_control_bayes_count(control, n_samples, quiet)
```

## Arguments

- control:

  A named list of arguments passed to
  [`rstan::sampling()`](https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html).

- n_samples:

  Number of retained posterior draws requested by the user.

- quiet:

  Logical indicating whether Stan progress output is suppressed.

## Value

The completed `control` list, including calculated `iter` and `refresh`
values and a count-compatible initialization setting.
