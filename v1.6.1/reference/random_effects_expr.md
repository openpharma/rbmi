# Construct random effects formula

Constructs a character representation of the random effects formula for
fitting a MMRM for subject by visit in the format required for
[`mmrm::mmrm()`](https://openpharma.github.io/mmrm/latest-tag/reference/mmrm.html).

## Usage

``` r
random_effects_expr(
  cov_struct = c("us", "ad", "adh", "ar1", "ar1h", "cs", "csh", "toep", "toeph"),
  cov_by_group = FALSE
)
```

## Arguments

- cov_struct:

  Character - The covariance structure to be used, must be one of `"us"`
  (default), `"ad"`, `"adh"`, `"ar1"`, `"ar1h"`, `"cs"`, `"csh"`,
  `"toep"`, or `"toeph"`)

- cov_by_group:

  Boolean - Whenever or not to use separate covariances per each group
  level

## Details

For example assuming the user specified a covariance structure of "us"
and that no groups were provided this will return

    us(visit | subjid)

If `cov_by_group` is set to `FALSE` then this indicates that separate
covariance matrices are required per group and as such the following
will be returned:

    us( visit | group / subjid )
