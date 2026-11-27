# Prepare fixed inputs for conditional count imputation

Prepare fixed inputs for conditional count imputation

## Usage

``` r
prepare_count_imputation_data(
  data,
  references,
  strategy_by_id,
  strategy_specs_by_id = NULL
)
```

## Arguments

- data:

  A `longdata` object containing the original count data and model
  formula.

- references:

  A validated named reference-group mapping.

- strategy_by_id:

  A named character vector containing one imputation strategy per
  subject.

- strategy_specs_by_id:

  `NULL` or a named list of `count_strategy` objects containing the
  controlled-imputation settings for each subject.

## Value

A list of row-aligned observed and missing design matrices, outcome and
duration values, subject indices, treatment groups, references, and
imputation strategies used by
[`sample_count_outcomes()`](https://openpharma.github.io/rbmi/reference/sample_count_outcomes.md).
