# Negative Binomial Regression for Count Outcomes

Fits a negative binomial regression model to a completed count-outcome
dataset. The period-specific counts and durations are first summed
within each subject. The model is then fitted to the total count with
the logarithm of total duration as an offset.

## Usage

``` r
neg_bin_regression(data, vars)
```

## Arguments

- data:

  A completed count-outcome `data.frame`, normally supplied by
  [`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md).
  It must contain one row per subject and period.

- vars:

  A `vars` object created by
  [`set_vars()`](https://openpharma.github.io/rbmi/reference/set_vars.md).
  The `subjid`, `outcome`, `group`, `period`, and `duration` elements
  are required. Any variables in `covariates` must be constant within
  subject.

## Value

A named list with one element for every fitted regression coefficient.
Each element contains the coefficient estimate (`est`) on the log-rate
scale, its standard error (`se`), and infinite degrees of freedom (`df`)
for asymptotic normal inference. The offset and negative binomial
dispersion parameter are not included.

## Details

All regression coefficients are returned on the model's log-rate scale
so that they can be pooled with Rubin's rules by
[`pool()`](https://openpharma.github.io/rbmi/reference/pool.md). For
reporting, `neg_bin_regression()` has an exponential transformation
attached, so
[`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md)
and [`pool()`](https://openpharma.github.io/rbmi/reference/pool.md)
report its pooled parameters on the rate-ratio scale by default,
labelled as the rate scale via `scale = "rate"` in the transformation
attribute. This includes the intercept, the treatment-group
coefficients, and coefficients for any other terms in `vars$covariates`.
The first level of `vars$group` is used as the reference group.

The model is
`total count ~ treatment group + covariates + offset(log(total duration))`.
It is fitted by maximum likelihood using
[`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html). The
covariance matrix jointly accounts for estimation of the regression
coefficients and the negative binomial dispersion parameter, matching
the calculation used by SAS `PROC GENMOD`.

The outcome column keeps the name supplied in `vars$outcome`; imputation
replaces its missing values in place. `neg_bin_regression()` performs
the subject-level aggregation internally, so a separate `Imputed_Count`
column is neither created nor required.

## See also

[`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md),
[`pool()`](https://openpharma.github.io/rbmi/reference/pool.md),
[`set_vars()`](https://openpharma.github.io/rbmi/reference/set_vars.md),
[`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html)
