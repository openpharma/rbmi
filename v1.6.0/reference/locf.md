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

## Examples

``` r
if (FALSE) { # \dontrun{
locf(c(NA, 1, 2, 3, NA, 4)) # Returns c(NA, 1, 2, 3, 3, 4)
} # }
```
