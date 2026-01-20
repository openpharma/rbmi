# Extract draws from a `stanfit` object

Extract draws from a `stanfit` object and convert them into lists.

The function
[`rstan::extract()`](https://mc-stan.org/rstan/reference/stanfit-method-extract.html)
returns the draws for a given parameter as an array. This function calls
[`rstan::extract()`](https://mc-stan.org/rstan/reference/stanfit-method-extract.html)
to extract the draws from a `stanfit` object and then convert the arrays
into lists.

## Usage

``` r
extract_draws(stan_fit, n_samples)
```

## Arguments

- stan_fit:

  A `stanfit` object.

- n_samples:

  Number of MCMC draws.

## Value

A named list of length 2 containing:

- `beta`: a list of length equal to `n_samples` containing the draws
  from the posterior distribution of the regression coefficients.

- `sigma`: a list of length equal to `n_samples` containing the draws
  from the posterior distribution of the covariance matrices. Each
  element of the list is a list with length equal to 1 if
  `same_cov = TRUE` or equal to the number of groups if
  `same_cov = FALSE`.
