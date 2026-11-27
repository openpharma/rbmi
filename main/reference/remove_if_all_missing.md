# Remove subjects from dataset if they have no observed values

This function takes a `data.frame` with variables `visit`, `outcome` &
`subjid`. It then removes all rows for a given `subjid` if they don't
have any non-missing values for `outcome`.

## Usage

``` r
remove_if_all_missing(dat, timevar = "visit")
```

## Arguments

- dat:

  a `data.frame`

- timevar:

  the name of the time variable (e.g. `visit` or `period`) to use
