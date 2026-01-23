# Internal Pool Methods

Dispatches pool methods based upon results object class. See
[`pool()`](https://openpharma.github.io/rbmi/reference/pool.md) for
details.

## Usage

``` r
pool_internal(results, conf.level, alternative, type, D)

# S3 method for class 'jackknife'
pool_internal(results, conf.level, alternative, type, D)

# S3 method for class 'bootstrap'
pool_internal(
  results,
  conf.level,
  alternative,
  type = c("percentile", "normal"),
  D
)

# S3 method for class 'bmlmi'
pool_internal(results, conf.level, alternative, type, D)

# S3 method for class 'rubin'
pool_internal(results, conf.level, alternative, type, D)
```

## Arguments

- results:

  a list of results i.e. the `x$results` element of an `analyse` object
  created by
  [`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md)).

- conf.level:

  confidence level of the returned confidence interval. Must be a single
  number between 0 and 1. Default is 0.95.

- alternative:

  a character string specifying the alternative hypothesis, must be one
  of `"two.sided"` (default), `"greater"` or `"less"`.

- type:

  a character string of either `"percentile"` (default) or `"normal"`.
  Determines what method should be used to calculate the bootstrap
  confidence intervals. See details. Only used if
  `method_condmean(type = "bootstrap")` was specified in the original
  call to
  [`draws()`](https://openpharma.github.io/rbmi/reference/draws.md).

- D:

  numeric representing the number of imputations between each bootstrap
  sample in the BMLMI method.
