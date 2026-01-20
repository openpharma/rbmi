# Transpose imputations

Takes an `imputation_df` object and transposes it e.g.

    list(
        list(id = "a", values = c(1,2,3)),
        list(id = "b", values = c(4,5,6)
        )
    )

## Usage

``` r
transpose_imputations(imputations)
```

## Arguments

- imputations:

  An `imputation_df` object created by
  [`imputation_df()`](https://openpharma.github.io/rbmi/reference/imputation_df.md)

## Details

becomes

    list(
        ids = c("a", "b"),
        values = c(1,2,3,4,5,6)
    )
