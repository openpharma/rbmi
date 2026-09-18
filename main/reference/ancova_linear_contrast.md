# Compute a single ANCOVA linear contrast

Evaluates a linear contrast over the group levels as a linear
combination of the model coefficients. The group-level weights are
applied to complete model design rows evaluated at the covariate
reference point, so interactions are included and the result is
independent of the active `contrasts` coding.

## Usage

``` r
ancova_linear_contrast(weights, beta, vcov_mod, df_res, contrast_design)
```

## Arguments

- weights:

  Numeric weight vector over the group levels (factor order), summing to
  zero.

- beta:

  Numeric vector of model coefficients.

- vcov_mod:

  Variance-covariance matrix of the model coefficients.

- df_res:

  Residual degrees of freedom.

- contrast_design:

  Numeric model matrix with one row per group level, evaluated at the
  covariate reference point, and one column per model coefficient.

## Value

A list with elements `est`, `se` and `df`.

## Details

The contrast is evaluated at the covariate reference (covariate = 0):
covariate main-effect and interaction columns receive zero weight and
cancel for a sum-to-zero contrast. Group-by-covariate interaction
columns are included when they are non-zero at that reference point. A
required coefficient that is missing, aliased (`NA`) or absent from the
variance-covariance matrix indicates a rank-deficient design and
triggers an error rather than a silently dropped term.
