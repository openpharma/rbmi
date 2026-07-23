# Sample Patient Ids

Performs a stratified bootstrap sample of IDS ensuring the return vector
is the same length as the input vector

## Usage

``` r
sample_ids(ids, strata = rep(1, length(ids)))
```

## Arguments

- ids:

  vector to sample from

- strata:

  strata indicator, ids are sampled within each strata ensuring the that
  the numbers of each strata are maintained

## Examples

``` r
if (FALSE) { # \dontrun{
sample_ids( c("a", "b", "c", "d"), strata = c(1,1,2,2))
} # }
```
