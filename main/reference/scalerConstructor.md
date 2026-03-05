# R6 Class for scaling (and un-scaling) design matrices

Scales a design matrix so that all non-categorical columns have a mean
of 0 and an standard deviation of 1.

## Details

The object initialisation is used to determine the relevant means and
standard deviations to scale by and then the scaling (and un-scaling)
itself is performed by the relevant object methods.

Un-scaling is done on linear model Beta and Sigma coefficients. For this
purpose the first column on the dataset to be scaled is assumed to be
the outcome variable with all other variables assumed to be
post-transformation predictor variables (i.e. all dummy variables have
already been expanded).

## Public fields

- `centre`:

  Vector of column means. The first value is the outcome variable, all
  other variables are the predictors.

- `scales`:

  Vector of column standard deviations. The first value is the outcome
  variable, all other variables are the predictors.

## Methods

### Public methods

- [`scalerConstructor$new()`](#method-scaler-new)

- [`scalerConstructor$scale()`](#method-scaler-scale)

- [`scalerConstructor$unscale_sigma()`](#method-scaler-unscale_sigma)

- [`scalerConstructor$unscale_beta()`](#method-scaler-unscale_beta)

- [`scalerConstructor$clone()`](#method-scaler-clone)

------------------------------------------------------------------------

### Method `new()`

Uses `dat` to determine the relevant column means and standard
deviations to use when scaling and un-scaling future datasets.
Implicitly assumes that new datasets have the same column order as `dat`

#### Usage

    scalerConstructor$new(dat)

#### Arguments

- `dat`:

  A `data.frame` or matrix. All columns must be numeric (i.e dummy
  variables, must have already been expanded out).

#### Details

Categorical columns (as determined by those who's values are entirely
`1` or `0`) will not be scaled. This is achieved by setting the
corresponding values of centre to `0` and scale to `1`.

------------------------------------------------------------------------

### Method [`scale()`](https://rdrr.io/r/base/scale.html)

Scales a dataset so that all continuous variables have a mean of 0 and a
standard deviation of 1.

#### Usage

    scalerConstructor$scale(dat)

#### Arguments

- `dat`:

  A `data.frame` or matrix whose columns are all numeric (i.e. dummy
  variables have all been expanded out) and whose columns are in the
  same order as the dataset used in the initialization function.

------------------------------------------------------------------------

### Method `unscale_sigma()`

Unscales a sigma value (or matrix) as estimated by a linear model using
a design matrix scaled by this object. This function only works if the
first column of the initialisation `data.frame` was the outcome
variable.

#### Usage

    scalerConstructor$unscale_sigma(sigma)

#### Arguments

- `sigma`:

  A numeric value or matrix.

#### Returns

A numeric value or matrix

------------------------------------------------------------------------

### Method `unscale_beta()`

Unscales a beta value (or vector) as estimated by a linear model using a
design matrix scaled by this object. This function only works if the
first column of the initialization `data.frame` was the outcome
variable.

#### Usage

    scalerConstructor$unscale_beta(beta)

#### Arguments

- `beta`:

  A numeric vector of beta coefficients as estimated from a linear
  model.

#### Returns

A numeric vector.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    scalerConstructor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
