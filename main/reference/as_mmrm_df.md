# Creates a "MMRM" ready dataset

Converts a design matrix + key variables into a common format In
particular this function does the following:

- Renames all covariates as `V1`, `V2`, etc to avoid issues of special
  characters in variable names

- Ensures all key variables are of the right type

- Inserts the `outcome`, `visit` and `subjid` variables into the
  `data.frame` naming them as `outcome`, `visit` and `subjid`

- If provided will also insert the group variable into the `data.frame`
  named as `group`

## Usage

``` r
as_mmrm_df(designmat, outcome, visit, subjid, group = NULL)
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

- visit:

  a character / factor vector. Indicates which visit the outcome value
  occurred on.

- subjid:

  a character / factor vector. The subject identifier used to link
  separate visits that belong to the same subject.

- group:

  a character / factor vector. Indicates which treatment group the
  patient belongs to. Will internally be converted to a factor if it is
  a character vector.
