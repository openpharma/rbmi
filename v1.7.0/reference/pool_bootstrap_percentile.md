# Bootstrap Pooling via Percentiles

Get point estimate, confidence interval and p-value using percentiles.
Note that quantile "type=6" is used, see
[`stats::quantile()`](https://rdrr.io/r/stats/quantile.html) for
details.

## Usage

``` r
pool_bootstrap_percentile(est, conf.level, alternative)
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

The point estimate is taken to be the first element of `est`. The
remaining n-1 values of `est` are then used to generate the confidence
intervals.
