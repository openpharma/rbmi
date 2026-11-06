# Internal MCSE Computations

These functions are used by
[`mcse()`](https://openpharma.github.io/rbmi/reference/pool.md) to
compute the Monte Carlo standard error using the Jackknife approach.

## Usage

``` r
mcse_jackknife(results, omit_index, conf.level, alternative)

jackknife_se(pars_jackknife)

mcse_combine_all_pars(jackknife_results)
```

## Arguments

- results:

  an analysis object created by
  [`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md).

- omit_index:

  the index of the result to omit.

- conf.level:

  confidence level of the returned confidence interval. Must be a single
  number between 0 and 1. Default is 0.95.

- alternative:

  a character string specifying the alternative hypothesis, must be one
  of `"two.sided"` (default), `"greater"` or `"less"`.

- pars_jackknife:

  the numeric vector of the jackknife results.

- jackknife_results:

  the list of jackknife results of all parameters, in the same format as
  the pooled parameter estimates.

## Value

`mcse_jackknife()` returns the pooled parameter estimates (in the same
structure as the `pars` element of a
[`pool()`](https://openpharma.github.io/rbmi/reference/pool.md) object)
recomputed with the `omit_index`-th result left out.

`jackknife_se()` returns the numeric scalar jackknife standard error
computed from `pars_jackknife`.

`mcse_combine_all_pars()` returns a list mirroring the structure of the
pooled parameters in which each statistic is replaced by its jackknife
Monte Carlo standard error.
