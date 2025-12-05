# Convert list of [`imputation_list_single()`](https://insightsengineering.github.io/rbmi/reference/imputation_list_single.md) objects to an [`imputation_list_df()`](https://insightsengineering.github.io/rbmi/reference/imputation_list_df.md) object (i.e. a list of [`imputation_df()`](https://insightsengineering.github.io/rbmi/reference/imputation_df.md) objects's)

Convert list of
[`imputation_list_single()`](https://insightsengineering.github.io/rbmi/reference/imputation_list_single.md)
objects to an
[`imputation_list_df()`](https://insightsengineering.github.io/rbmi/reference/imputation_list_df.md)
object (i.e. a list of
[`imputation_df()`](https://insightsengineering.github.io/rbmi/reference/imputation_df.md)
objects's)

## Usage

``` r
convert_to_imputation_list_df(imputes, sample_ids)
```

## Arguments

- imputes:

  a list of
  [`imputation_list_single()`](https://insightsengineering.github.io/rbmi/reference/imputation_list_single.md)
  objects

- sample_ids:

  A list with 1 element per required imputation_df. Each element must
  contain a vector of "ID"'s which correspond to the
  [`imputation_single()`](https://insightsengineering.github.io/rbmi/reference/imputation_single.md)
  ID's that are required for that dataset. The total number of ID's must
  by equal to the total number of rows within all of
  `imputes$imputations`

  To accommodate for
  [`method_bmlmi()`](https://insightsengineering.github.io/rbmi/reference/method.md)
  the
  [`impute_data_individual()`](https://insightsengineering.github.io/rbmi/reference/impute_data_individual.md)
  function returns a list of
  [`imputation_list_single()`](https://insightsengineering.github.io/rbmi/reference/imputation_list_single.md)
  objects with 1 object per each subject.

  [`imputation_list_single()`](https://insightsengineering.github.io/rbmi/reference/imputation_list_single.md)
  stores the subjects imputations as a matrix where the columns of the
  matrix correspond to the D of
  [`method_bmlmi()`](https://insightsengineering.github.io/rbmi/reference/method.md).
  Note that all other methods (i.e. `methods_*()`) are a special case of
  this with D = 1. The number of rows in the matrix varies for each
  subject and is equal to the number of times the patient was selected
  for imputation (for non-conditional mean methods this should be 1 per
  subject per imputed dataset).

  This function is best illustrated by an example:

      imputes = list(
          imputation_list_single(
              id = "Tom",
              imputations = matrix(
                   imputation_single_t_1_1,  imputation_single_t_1_2,
                   imputation_single_t_2_1,  imputation_single_t_2_2,
                   imputation_single_t_3_1,  imputation_single_t_3_2
              )
          ),
          imputation_list_single(
              id = "Tom",
              imputations = matrix(
                   imputation_single_h_1_1,  imputation_single_h_1_2,
              )
          )
      )

      sample_ids <- list(
          c("Tom", "Harry", "Tom"),
          c("Tom")
      )

  Then `convert_to_imputation_df(imputes, sample_ids)` would result in:

      imputation_list_df(
          imputation_df(
              imputation_single_t_1_1,
              imputation_single_h_1_1,
              imputation_single_t_2_1
          ),
          imputation_df(
              imputation_single_t_1_2,
              imputation_single_h_1_2,
              imputation_single_t_2_2
          ),
          imputation_df(
              imputation_single_t_3_1
          ),
          imputation_df(
              imputation_single_t_3_2
          )
      )

  Note that the different repetitions (i.e. the value set for D) are
  grouped together sequentially.
