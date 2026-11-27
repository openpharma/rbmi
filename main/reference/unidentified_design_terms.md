# Identify linearly dependent design columns

Uses a pivoted QR decomposition to identify columns that are zero or
linear combinations of other columns. The caller selects the rows
relevant to its model. When no rows are supplied, all columns are
unidentified.

## Usage

``` r
unidentified_design_terms(designmat, term_names = NULL)
```

## Arguments

- designmat:

  A numeric matrix or data.frame containing the model design.

- term_names:

  Optional column names. If `NULL`, uses the column names of
  `designmat`, or numbered column labels when those are unavailable.

## Value

A character vector naming the dependent columns selected by the QR
pivot, or `character(0)` when the matrix has full column rank. The
selected columns are one possible set of dependent columns, not a unique
attribution of the rank deficiency.
