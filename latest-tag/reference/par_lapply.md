# Parallelise `lapply`

Simple wrapper around `lapply` and
[`parallel::clusterApplyLB`](https://rdrr.io/r/parallel/clusterApply.html)
to abstract away the logic of deciding which one to use

## Usage

``` r
par_lapply(cl, fun, x, ...)
```

## Arguments

- cl:

  Cluster created by
  [`parallel::makeCluster()`](https://rdrr.io/r/parallel/makeCluster.html)
  or `NULL`

- fun:

  Function to be run

- x:

  object to be looped over

- ...:

  extra arguments passed to `fun`
