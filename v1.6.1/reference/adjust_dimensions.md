# Adjust Dimensions of Prior Parameters for Stan Usage

This function adjusts the dimensions of prior parameters based on
whether the same covariance structure is used for all groups, and
whether the parameters are lists of matrices or numeric vectors. This is
really only necessary to deal with some peculiarities of how Stan
handles arrays and vectors. See
[`prepare_prior_params()`](https://openpharma.github.io/rbmi/reference/prepare_prior_params.md)
where this is used.

## Usage

``` r
adjust_dimensions(same_cov, param_list)
```

## Arguments

- same_cov:

  A logical indicating whether the same covariance structure is used for
  all groups. If `TRUE`, the function will return the parameters only
  once.

- param_list:

  A list of parameters, which can be matrices or numeric vectors. Note
  that this contains one element for each group, independent of
  `same_cov`.

## Value

The parameters adjusted to the appropriate dimensions for Stan.
