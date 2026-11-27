# Extract draws from a Stan fit object for count outcome

Extract draws from a Stan fit object for count outcome

## Usage

``` r
extract_draws_count(stan_fit, n_samples)
```

## Arguments

- stan_fit:

  An
  [`rstan::stanfit`](https://mc-stan.org/rstan/reference/stanfit-class.html)
  object produced by the count model.

- n_samples:

  Number of posterior draws to retain.

## Value

A named list with `beta` and `phi` components. Each component is a list
with one element per retained posterior draw.
