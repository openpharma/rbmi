# Check the rank of a continuous imputation model design

Checks that the design matrix has full column rank among rows with
observed outcomes, including zero and negative values. If it is rank
deficient, stops with an error naming columns that are zero or linearly
dependent on other columns in those rows.

## Usage

``` r
check_continuous_design_rank(designmat, outcome, term_names = NULL)
```

## Arguments

- designmat:

  A numeric matrix or data.frame containing the model design.

- outcome:

  A numeric outcome vector, with missing values indicated by `NA`.

- term_names:

  Optional model-matrix column names for error messages. If `NULL`, uses
  the column names of `designmat`, or numbered column labels when those
  are unavailable.

## Value

Invisibly returns `NULL` if the observed-outcome design has full column
rank; otherwise raises an error.
