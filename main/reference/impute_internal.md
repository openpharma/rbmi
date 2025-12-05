# Create imputed datasets

This is the work horse function that implements most of the
functionality of impute. See the user level function
[`impute()`](https://insightsengineering.github.io/rbmi/reference/impute.md)
for further details.

## Usage

``` r
impute_internal(
  draws,
  references = NULL,
  update_strategy,
  strategies,
  condmean
)
```

## Arguments

- draws:

  A `draws` object created by
  [`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).

- references:

  A named vector. Identifies the references to be used for
  reference-based imputation methods. Should be of the form
  `c("Group1" = "Reference1", "Group2" = "Reference2")`. If `NULL`
  (default), the references are assumed to be of the form
  `c("Group1" = "Group1", "Group2" = "Group2")`. This argument cannot be
  `NULL` if an imputation strategy (as defined by
  `data_ice[[vars$strategy]]` in the call to
  [draws](https://insightsengineering.github.io/rbmi/reference/draws.md))
  other than `MAR` is set.

- update_strategy:

  An optional `data.frame`. Updates the imputation method that was
  originally set via the `data_ice` option in
  [`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).
  See the details section for more information.

- strategies:

  A named list of functions. Defines the imputation functions to be
  used. The names of the list should mirror the values specified in
  `strategy` column of `data_ice`. Default =
  [`getStrategies()`](https://insightsengineering.github.io/rbmi/reference/getStrategies.md).
  See
  [`getStrategies()`](https://insightsengineering.github.io/rbmi/reference/getStrategies.md)
  for more details.

- condmean:

  logical. If TRUE will impute using the conditional mean values, if
  values will impute by taking a random draw from the multivariate
  normal distribution.
