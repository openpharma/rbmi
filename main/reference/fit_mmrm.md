# Fit a MMRM model

Fits a MMRM model allowing for different covariance structures using
[`mmrm::mmrm()`](https://openpharma.github.io/mmrm/latest-tag/reference/mmrm.html).
Returns a `list` of key model parameters `beta`, `sigma` and an
additional element `failed` indicating whether or not the fit failed to
converge. If the fit did fail to converge `beta` and `sigma` will not be
present.

## Usage

``` r
fit_mmrm(
  designmat,
  outcome,
  subjid,
  visit,
  group,
  cov_struct = c("us", "ad", "adh", "ar1", "ar1h", "cs", "csh", "toep", "toeph"),
  REML = TRUE,
  same_cov = TRUE
)
```

## Arguments

- designmat:

  a `data.frame` or `matrix` containing the covariates to use in the
  MMRM model. Dummy variables must already be expanded out, i.e. via
  [`stats::model.matrix()`](https://rdrr.io/r/stats/model.matrix.html).
  Cannot contain any missing values

- outcome:

  a numeric vector. The outcome value to be regressed on in the MMRM
  model.

- subjid:

  a character / factor vector. The subject identifier used to link
  separate visits that belong to the same subject.

- visit:

  a character / factor vector. Indicates which visit the outcome value
  occurred on.

- group:

  a character / factor vector. Indicates which treatment group the
  patient belongs to. Will internally be converted to a factor if it is
  a character vector.

- cov_struct:

  a character value. Specifies which covariance structure to use. Must
  be one of `"us"` (default), `"ad"`, `"adh"`, `"ar1"`, `"ar1h"`,
  `"cs"`, `"csh"`, `"toep"`, or `"toeph"`)

- REML:

  logical. Specifies whether restricted maximum likelihood should be
  used

- same_cov:

  logical. Used to specify if a shared or individual covariance matrix
  should be used per `group`
