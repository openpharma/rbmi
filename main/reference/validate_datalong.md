# Validate a longdata object

Validate a longdata object

## Usage

``` r
validate_datalong(data, vars)

validate_datalong_varExists(data, vars)

validate_datalong_types(data, vars)

validate_datalong_notMissing(data, vars)

validate_datalong_complete(data, vars)

validate_datalong_unifromStrata(data, vars)

validate_dataice(data, data_ice, vars, update = FALSE)
```

## Arguments

- data:

  a `data.frame` containing the longitudinal outcome data + covariates
  for multiple subjects

- vars:

  a `vars` object as created by
  [`set_vars()`](https://insightsengineering.github.io/rbmi/reference/set_vars.md)

- data_ice:

  a `data.frame` containing the subjects ICE data. See
  [`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md)
  for details.

- update:

  logical, indicates if the ICE data is being set for the first time or
  if an update is being applied

## Details

These functions are used to validate various different parts of the
longdata object to be used in
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md),
[`impute()`](https://insightsengineering.github.io/rbmi/reference/impute.md),
[`analyse()`](https://insightsengineering.github.io/rbmi/reference/analyse.md)
and
[`pool()`](https://insightsengineering.github.io/rbmi/reference/pool.md).
In particular:

- validate_datalong_varExists - Checks that each variable listed in
  `vars` actually exists in the `data`

- validate_datalong_types - Checks that the types of each key variable
  is as expected i.e. that visit is a factor variable

- validate_datalong_notMissing - Checks that none of the key variables
  (except the outcome variable) contain any missing values

- validate_datalong_complete - Checks that `data` is complete i.e. there
  is 1 row for each subject \* visit combination. e.g. that
  `nrow(data) == length(unique(subjects)) * length(unique(visits))`

- validate_datalong_unifromStrata - Checks to make sure that any
  variables listed as stratification variables do not vary over time.
  e.g. that subjects don't switch between stratification groups.
