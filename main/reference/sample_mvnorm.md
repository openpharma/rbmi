# Sample random values from the multivariate normal distribution

Sample random values from the multivariate normal distribution

## Usage

``` r
sample_mvnorm(mu, sigma)
```

## Arguments

- mu:

  mean vector

- sigma:

  covariance matrix

  Samples multivariate normal variables by multiplying univariate random
  normal variables by the Cholesky decomposition of the covariance
  matrix.

  If mu is length 1 then just uses `rnorm` instead.
