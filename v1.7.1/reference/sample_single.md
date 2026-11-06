# Create object of `sample_single` class

Creates an object of class `sample_single` which is a named list
containing the input parameters and validate them.

## Usage

``` r
sample_single(
  ids,
  beta = NA,
  sigma = NA,
  theta = NA,
  failed = any(is.na(beta)),
  ids_samp = ids
)
```

## Arguments

- ids:

  Vector of characters containing the ids of the subjects included in
  the original dataset.

- beta:

  Numeric vector of estimated regression coefficients.

- sigma:

  List of estimated covariance matrices (one for each level of
  `vars$group`).

- theta:

  Numeric vector of transformed covariances.

- failed:

  Logical. `TRUE` if the model fit failed.

- ids_samp:

  Vector of characters containing the ids of the subjects included in
  the given sample.

## Value

A named list of class `sample_single`. It contains the following:

- `ids` vector of characters containing the ids of the subjects included
  in the original dataset.

- `beta` numeric vector of estimated regression coefficients.

- `sigma` list of estimated covariance matrices (one for each level of
  `vars$group`).

- `theta` numeric vector of transformed covariances.

- `failed` logical. `TRUE` if the model fit failed.

- `ids_samp` vector of characters containing the ids of the subjects
  included in the given sample.
