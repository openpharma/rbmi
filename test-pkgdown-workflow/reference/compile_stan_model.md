# Compile a Stan model

Compiles rendered Stan code, optionally using the rbmi model cache.
Cached filenames include a hash of the model code and relevant package
versions so stale compiled models are not reused. The
random-number-generator state is restored after compilation because Stan
compilation can modify it.

## Usage

``` r
compile_stan_model(model_string, model_name)
```

## Arguments

- model_string:

  Rendered Stan model code.

- model_name:

  Name passed to
  [`rstan::stan_model()`](https://mc-stan.org/rstan/reference/stan_model.html).

## Value

A compiled `rstan::stanmodel` object.
