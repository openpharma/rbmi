# Create MMRM formula

Derives the MMRM model formula from the structure of `mmrm_df`. returns
a formula object of the form:

## Usage

``` r
as_mmrm_formula(mmrm_df, cov_struct)
```

## Arguments

- mmrm_df:

  an `mmrm` `data.frame` as created by
  [`as_mmrm_df()`](https://openpharma.github.io/rbmi/reference/as_mmrm_df.md)

- cov_struct:

  Character - The covariance structure to be used, must be one of `"us"`
  (default), `"ad"`, `"adh"`, `"ar1"`, `"ar1h"`, `"cs"`, `"csh"`,
  `"toep"`, or `"toeph"`)

## Details

    outcome ~ 0 + V1 + V2 + V4 + ... + us(visit | group / subjid)
