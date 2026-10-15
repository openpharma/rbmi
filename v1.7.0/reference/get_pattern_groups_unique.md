# Get Pattern Summary

Takes a dataset of pattern information and creates a summary dataset of
it with just 1 row per pattern

## Usage

``` r
get_pattern_groups_unique(patterns)
```

## Arguments

- patterns:

  A `data.frame` with the columns `pgroup`, `pattern` and `group`

## Details

- The column `pgroup` must be a numeric vector indicating which pattern
  group the patient belongs to

- The column `pattern` must be a character string of `0`'s or `1`'s. It
  must be identical for all rows within the same `pgroup`

- The column `group` must be a character / numeric vector indicating
  which covariance group the observation belongs to. It must be
  identical within the same `pgroup`
