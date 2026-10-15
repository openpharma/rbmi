# Get Compiled Stan Object

Gets a compiled Stan object that can be used with
[`rstan::sampling()`](https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html),
based on the choice of the covariance structure and the prior on the
parameters.

## Usage

``` r
get_stan_model(covariance, prior_cov)
```

## Arguments

- covariance:

  A string indicating the covariance structure to be used.

- prior_cov:

  A string indicating the prior on the covariance parameters.

## Value

The compiled Stan model object.
