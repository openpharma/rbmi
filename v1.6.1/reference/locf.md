# Last Observation Carried Forward

Returns a vector after applied last observation carried forward
imputation.

## Usage

``` r
locf(x)
```

## Arguments

- x:

  a vector.

## Value

A vector of the same length as `x` in which each `NA` has been replaced
by the most recent preceding non-`NA` value. Leading `NA`s (those with
no earlier value to carry forward) are left unchanged.

## Examples

``` r
if (FALSE) { # \dontrun{
locf(c(NA, 1, 2, 3, NA, 4)) # Returns c(NA, 1, 2, 3, 3, 4)
} # }
```
