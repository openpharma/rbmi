# P-value of percentile bootstrap

Determines the (not necessarily unique) quantile (type=6) of "est" which
gives a value of 0 From this, derive the p-value corresponding to the
percentile bootstrap via inversion.

## Usage

``` r
pval_percentile(est)
```

## Arguments

- est:

  a numeric vector of point estimates from each bootstrap sample.

## Value

A named numeric vector of length 2 containing the p-value for H_0:
theta=0 vs H_A: theta\>0 (`"pval_greater"`) and the p-value for H_0:
theta=0 vs H_A: theta\<0 (`"pval_less"`).

## Details

The p-value for H_0: theta=0 vs H_A: theta\>0 is the value `alpha` for
which `q_alpha = 0`. If there is at least one estimate equal to zero it
returns the largest `alpha` such that `q_alpha = 0`. If all bootstrap
estimates are \> 0 it returns 0; if all bootstrap estimates are \< 0 it
returns 1. Analogous reasoning is applied for the p-value for H_0:
theta=0 vs H_A: theta\<0.
