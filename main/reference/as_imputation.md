# Create an imputation object

This function creates the object that is returned from
[`impute()`](https://insightsengineering.github.io/rbmi/reference/impute.md).
Essentially it is a glorified wrapper around
[`list()`](https://rdrr.io/r/base/list.html) ensuring that the required
elements have been set and that the class is added as expected.

## Usage

``` r
as_imputation(imputations, data, method, references)
```

## Arguments

- imputations:

  A list of `imputations_list`'s as created by
  [`imputation_df()`](https://insightsengineering.github.io/rbmi/reference/imputation_df.md)

- data:

  A `longdata` object as created by
  [`longDataConstructor()`](https://insightsengineering.github.io/rbmi/reference/longDataConstructor.md)

- method:

  A `method` object as created by
  [`method_condmean()`](https://insightsengineering.github.io/rbmi/reference/method.md),
  [`method_bayes()`](https://insightsengineering.github.io/rbmi/reference/method.md)
  or
  [`method_approxbayes()`](https://insightsengineering.github.io/rbmi/reference/method.md)

- references:

  A named vector. Identifies the references to be used when generating
  the imputed values. Should be of the form
  `c("Group" = "Reference", "Group" = "Reference")`.
