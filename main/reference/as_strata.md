# Create vector of Stratas

Collapse multiple categorical variables into distinct unique categories.
e.g.

    as_strata(c(1,1,2,2,2,1), c(5,6,5,5,6,5))

would return

    c(1,2,3,3,4,1)

## Usage

``` r
as_strata(...)
```

## Arguments

- ...:

  numeric/character/factor vectors of the same length

## Examples

``` r
if (FALSE) { # \dontrun{
as_strata(c(1,1,2,2,2,1), c(5,6,5,5,6,5))
} # }
```
