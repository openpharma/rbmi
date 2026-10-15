# Check for Valid Covariance and Prior Combination

This function checks if the specified covariance structure and prior
combination is valid.

## Usage

``` r
is_valid_covariance_prior(prior_cov, covariance)
```

## Arguments

- prior_cov:

  A character string indicating the prior covariance type.

- covariance:

  A character string indicating the covariance structure.

## Value

Logical scalar indicating if the combination is valid, with a `msg`
attribute in case it is not.
