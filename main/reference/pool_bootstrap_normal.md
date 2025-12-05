# Bootstrap Pooling via normal approximation

Get point estimate, confidence interval and p-value using the normal
approximation.

## Usage

``` r
pool_bootstrap_normal(est, conf.level, alternative)
```

## Arguments

- est:

  a numeric vector of point estimates from each bootstrap sample.

- conf.level:

  confidence level of the returned confidence interval. Must be a single
  number between 0 and 1. Default is 0.95.

- alternative:

  a character string specifying the alternative hypothesis, must be one
  of `"two.sided"` (default), `"greater"` or `"less"`.

## Details

The point estimate is taken to be the first element of est. The
remaining n-1 values of est are then used to generate the confidence
intervals.
