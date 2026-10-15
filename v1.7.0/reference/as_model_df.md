# Expand `data.frame` into a design matrix

Expands out a `data.frame` using a formula to create a design matrix.
Key details are that it will always place the outcome variable into the
first column of the return object.

## Usage

``` r
as_model_df(dat, frm)
```

## Arguments

- dat:

  a data.frame

- frm:

  a formula

## Details

The outcome column may contain NA, but none of the other variables
listed in the formula should contain missing values
