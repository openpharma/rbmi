# Internal MCSE Computations

These functions are used by
[`mcse()`](https://insightsengineering.github.io/rbmi/reference/pool.md)
to compute the Monte Carlo standard error using the Jackknife approach.

## Usage

``` r
mcse_jackknife(results, omit_index, conf.level, alternative)

jackknife_se(pars_jackknife)

mcse_combine_all_pars(jackknife_results)
```

## Arguments

- results:

  an analysis object created by
  [`analyse()`](https://insightsengineering.github.io/rbmi/reference/analyse.md).

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
