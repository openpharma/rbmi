# Derive conditional multivariate normal parameters

Takes parameters for a multivariate normal distribution and observed
values to calculate the conditional distribution for the unobserved
values.

## Usage

``` r
get_conditional_parameters(pars, values)
```

## Arguments

- pars:

  a `list` with elements `mu` and `sigma` defining the mean vector and
  covariance matrix respectively.

- values:

  a vector of observed values to condition on, must be same length as
  `pars$mu`. Missing values must be represented by an `NA`.

## Value

A list with the conditional distribution parameters:

- `mu` - The conditional mean vector.

- `sigma` - The conditional covariance matrix.
