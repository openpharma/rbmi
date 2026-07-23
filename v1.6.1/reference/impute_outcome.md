# Sample outcome value

Draws a random sample from a multivariate normal distribution.

## Usage

``` r
impute_outcome(conditional_parameters, n_imputations = 1, condmean = FALSE)
```

## Arguments

- conditional_parameters:

  a list with elements `mu` and `sigma` which contain the mean vector
  and covariance matrix to sample from.

- n_imputations:

  numeric representing the number of random samples from the
  multivariate normal distribution to be performed. Default is `1`.

- condmean:

  should conditional mean imputation be performed (as opposed to random
  sampling)
