# Control the computational details of the imputation methods

These functions control lower level computational details of the
imputation methods.

## Usage

``` r
control_bayes(
  warmup = 200,
  thin = 50,
  chains = 1,
  init = "auto",
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

  Initialisation policy or Stan initial values; see the details.

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

- The default `init = "auto"` uses MMRM estimates for continuous
  outcomes with one chain, and random initialisation otherwise. (With
  more than one chain, `"mmrm"` starts all chains at the same values,
  which makes convergence diagnostics such as R-hat less reliable, so a
  warning is given.) Explicit `"mmrm"` initialisation is only supported
  for continuous outcomes. Other `init` values are passed unchanged to
  [`rstan::sampling()`](https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html):
  `"random"`, `0` or `"0"` (zero on Stan's unconstrained scale), a list
  of named lists (one per chain), or a function returning a named list,
  optionally accepting `chain_id`. Omitted parameters use Stan's random
  initialisation. Custom lists and functions must use the internal Stan
  parameterisation and constrained parameter scales. For counts, `beta`
  follows the internally scaled design matrix column order, and `phi`
  has one value per dispersion group (one when `same_cov = TRUE`),
  strictly greater than `.Machine$double.eps`. For continuous outcomes,
  initial values use `theta` and covariance-specific parameters. Note
  that these are not coefficients on the original data scale.

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
#> [1] "auto"
#> 
#> $seed
#> [1] 1050152937
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
#> [1] "auto"
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
#> [1] "auto"
#> 
#> $control$seed
#> [1] 1821
#> 
#> 
#> attr(,"class")
#> [1] "method" "bayes" 
```
