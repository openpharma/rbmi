# Build the ANCOVA contrast design matrix

Creates one complete model-matrix row per treatment-group level. Numeric
covariates are set to zero, logical covariates to `FALSE`, and factor
covariates to their first level. The fitted model's contrast coding is
retained so that differences between rows include all required
interaction coefficients.

## Usage

``` r
ancova_contrast_design(model, data, outcome)
```

## Arguments

- model:

  A fitted `lm` model containing the internal `rbmiGroup` factor.

- data:

  The raw model data used to fit `model`, including the untransformed
  predictor columns required to evaluate transformed terms.

- outcome:

  Character, the outcome variable name.

## Value

A numeric model matrix with one row per `rbmiGroup` level.
