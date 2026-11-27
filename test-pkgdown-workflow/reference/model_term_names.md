# Column names of the model matrix used by `as_model_df()`

[`as_model_df()`](https://openpharma.github.io/rbmi/reference/as_model_df.md)
renames the design columns to `V1`, `V2`, ...; this returns the original
term names, e.g. for error messages.

## Usage

``` r
model_term_names(dat, frm)
```

## Arguments

- dat:

  a data.frame

- frm:

  a formula

## Value

A character vector of model-matrix column names.
