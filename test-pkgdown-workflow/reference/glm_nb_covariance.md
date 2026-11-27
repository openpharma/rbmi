# Covariance matrix for a negative binomial regression model

Computes the inverse observed information for the regression
coefficients and the negative binomial shape parameter. Unlike the usual
covariance returned by `glm.nb`, this calculation does not assume that
the regression coefficients and the estimated dispersion are
independent.

## Usage

``` r
glm_nb_covariance(model)
```

## Arguments

- model:

  A model fitted by
  [`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html) with
  `x = TRUE`.

## Value

A covariance matrix containing the regression coefficients and an
additional `dispersion` row and column.

## Details

The inverse is computed blockwise through the Schur complement of the
coefficient block, i.e. the information about the shape parameter that
is not shared with the coefficients. When the data are close to Poisson,
the shape estimate is very large and this information is a small
difference of nearly equal terms; inverting the full matrix then fails
or returns negative variances. A nonpositive or nonfinite Schur
complement can reflect numerical cancellation or an invalid fitted
optimum; it does not by itself establish that the shape parameter is
unidentified. In this case, the coefficient covariance is computed with
the shape parameter held fixed, and the `dispersion` row and column are
set to `NA`. This fallback is not the inverse of the joint observed
information.
