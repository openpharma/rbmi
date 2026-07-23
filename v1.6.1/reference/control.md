# Control the computational details of the imputation methods

These functions control lower level computational details of the
imputation methods.

## Usage

``` r
control_bayes(
  warmup = 200,
  thin = 50,
  chains = 1,
  init = ifelse(chains > 1, "random", "mmrm"),
  seed = sample.int(.Machine$integer.max, 1),
  ...
)
```

## Arguments

- warmup:

  a numeric, the number of warmup iterations for the MCMC sampler.

- thin:

  a numeric, the thinning rate of the MCMC sampler.

- chains:

  a numeric, the number of chains to run in parallel.

- init:

  a character string, the method used to initialise the MCMC sampler,
  see the details.

- seed:

  a numeric, the seed used to initialise the MCMC sampler.

- ...:

  additional arguments to be passed to
  [`rstan::sampling()`](https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html).

## Value

A named list of control parameters (`warmup`, `thin`, `chains`, `init`,
`seed` and any additional arguments passed via `...`) that control the
MCMC sampler used by
[`method_bayes()`](https://openpharma.github.io/rbmi/reference/method.md).

## Details

Currently only the Bayesian imputation via
[`method_bayes()`](https://openpharma.github.io/rbmi/reference/method.md)
uses a control function:

- The `init` argument can be set to `"random"` to randomly initialise
  the sampler with `rstan` default values or to `"mmrm"` to initialise
  the sampler with the maximum likelihood estimate values of the MMRM.

- The `seed` argument is used to set the seed for the MCMC sampler. By
  default, a random seed is generated, such that outside invocation of
  the [`set.seed()`](https://rdrr.io/r/base/Random.html) call can
  effectively set the seed.

- The samples are split across the chains, such that each chain produces
  `n_samples / chains` (rounded up) samples. The total number of samples
  that will be returned across all chains is `n_samples` as specified in
  [`method_bayes()`](https://openpharma.github.io/rbmi/reference/method.md).

- Therefore, the additional parameters passed to
  [`rstan::sampling()`](https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html)
  must not contain `n_samples` or `iter`. Instead, the number of samples
  must only be provided directly via the `n_samples` argument of
  [`method_bayes()`](https://openpharma.github.io/rbmi/reference/method.md).
  Similarly, the `refresh` argument is also not allowed here, instead
  use the `quiet` argument directly in
  [`draws()`](https://openpharma.github.io/rbmi/reference/draws.md).

## Note

For full reproducibility of the imputation results, it is required to
use a [`set.seed()`](https://rdrr.io/r/base/Random.html) call before
defining the `control` list, and calling the
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md)
function. It is not sufficient to merely set the `seed` argument in the
`control` list.

## Examples

``` r
# Default control settings
control_bayes()
#> $warmup
#> [1] 200
#> 
#> $thin
#> [1] 50
#> 
#> $chains
#> [1] 1
#> 
#> $init
#> [1] "mmrm"
#> 
#> $seed
#> [1] 1867699052
#> 

# Customise the warmup, thinning and seed used by the MCMC sampler
control_bayes(warmup = 200, thin = 5, seed = 1821)
#> $warmup
#> [1] 200
#> 
#> $thin
#> [1] 5
#> 
#> $chains
#> [1] 1
#> 
#> $init
#> [1] "mmrm"
#> 
#> $seed
#> [1] 1821
#> 

# Pass the control settings on to method_bayes()
method_bayes(
    n_samples = 150,
    control = control_bayes(warmup = 200, thin = 5, seed = 1821)
)
#> $covariance
#> [1] "us"
#> 
#> $same_cov
#> [1] TRUE
#> 
#> $n_samples
#> [1] 150
#> 
#> $prior_cov
#> [1] "default"
#> 
#> $control
#> $control$warmup
#> [1] 200
#> 
#> $control$thin
#> [1] 5
#> 
#> $control$chains
#> [1] 1
#> 
#> $control$init
#> [1] "mmrm"
#> 
#> $control$seed
#> [1] 1821
#> 
#> 
#> attr(,"class")
#> [1] "method" "bayes" 
```
