# Define controlled imputation strategies for count outcomes

`count_strategy()` defines how the model-based mean for a missing count
is obtained and optionally adjusted during imputation. The `base`
strategy is applied first. A `rate_multiplier` then multiplies its
model-based mean, or `fixed_rate` replaces that mean by a fixed event
rate.

## Usage

``` r
count_strategy(
  base = c("MAR", "JR", "CR"),
  rate_multiplier = 1,
  fixed_rate = NULL,
  fixed_rate_scale = c("rate", "lambda"),
  period = NULL
)

get_count_strategies(...)
```

## Arguments

- base:

  Character. The base count imputation strategy, one of `"MAR"`, `"JR"`,
  or `"CR"`.

- rate_multiplier:

  A non-negative numeric scalar multiplying the model-based mean for
  affected missing cells.

- fixed_rate:

  `NULL` or a non-negative numeric scalar. When set, it replaces the
  model-based rate of affected missing cells. Its meaning depends on
  `fixed_rate_scale`; see the section on fixed rates.

- fixed_rate_scale:

  The scale of `fixed_rate`: `"rate"` (default), an event rate per unit
  of duration, or `"lambda"`, the negative-multinomial lambda scale.
  Must only be specified together with `fixed_rate`.

- period:

  `NULL` or a vector of period values. If supplied, the rate adjustment
  is restricted to missing cells in these periods. The base strategy
  still applies to other missing periods.

- ...:

  Named `count_strategy` objects to add to the built-in strategies.

## Value

`count_strategy()` returns a `count_strategy` object.
`get_count_strategies()` returns a named list of these objects for use
in the `strategies` argument of
[`impute()`](https://openpharma.github.io/rbmi/reference/impute.md).

## Details

`get_count_strategies()` returns the built-in MAR, JR and CR count
strategies together with any named user-defined strategies supplied
through `...`. For count outcomes, the strategy is assigned at the
subject level and applies to every missing positive-duration period for
that subject. No ICE time is supplied or inferred; consequently, JR and
CR are not restricted to periods after an ICE.

## Fixed rates and SAS compatibility

With the default `fixed_rate_scale = "rate"`, `fixed_rate` is a marginal
event rate per unit of the duration variable: a missing cell with
exposure `L` has unconditional mean `L * fixed_rate`, the same for every
posterior draw, treatment arm and base strategy.

`fixed_rate_scale = "lambda"` reproduces the fixed-rate option of the
SAS macro `NM_Rand13.sas` (Roger, 2021), which fixes the rate on the
negative-multinomial lambda scale. The unconditional mean is then
`L * fixed_rate / phi`, where `phi` is the dispersion parameter of the
current posterior draw (from the subject's arm for MAR, and from the
mapped reference arm for JR and CR). The implied event rate therefore
changes from draw to draw and between arms, and becomes arbitrarily
large as `phi` approaches zero (nearly Poisson data).
[`impute()`](https://openpharma.github.io/rbmi/reference/impute.md)
warns when the SAS lambda implies a rate more than 100 times the
model-based rate of the same cell in any posterior draw. Use this scale
only to reproduce SAS results.

For both scales, the imputed count is drawn conditionally on the
subject's observed cells. Its conditional mean is the unconditional mean
multiplied by `(1 / phi + y_obs) / (1 / phi + mu_obs)`, where `y_obs`
and `mu_obs` are the subject's observed total count and its model-based
mean.

## References

Roger JH (2021). NegMult20210313: SAS macros for imputation of recurrent
event data for partially observed off-treatment data. DIA Missing Data
Working Group.

## Examples

``` r
fixed_rate <- count_strategy(
    base = "MAR",
    fixed_rate = 0.003,
    period = "3"
)
fixed_lambda <- count_strategy(
    base = "MAR",
    fixed_rate = 0.0021,
    fixed_rate_scale = "lambda",
    period = "3"
)
double_rate <- count_strategy(
    base = "MAR",
    rate_multiplier = 2,
    period = "3"
)
get_count_strategies(
    FIXED_RATE = fixed_rate,
    FIXED_LAMBDA = fixed_lambda,
    DOUBLE_RATE = double_rate
)
#> $MAR
#> $base
#> [1] "MAR"
#> 
#> $rate_multiplier
#> [1] 1
#> 
#> $fixed_rate
#> [1] NA
#> 
#> $fixed_rate_scale
#> [1] NA
#> 
#> $period
#> NULL
#> 
#> attr(,"class")
#> [1] "count_strategy" "list"          
#> 
#> $JR
#> $base
#> [1] "JR"
#> 
#> $rate_multiplier
#> [1] 1
#> 
#> $fixed_rate
#> [1] NA
#> 
#> $fixed_rate_scale
#> [1] NA
#> 
#> $period
#> NULL
#> 
#> attr(,"class")
#> [1] "count_strategy" "list"          
#> 
#> $CR
#> $base
#> [1] "CR"
#> 
#> $rate_multiplier
#> [1] 1
#> 
#> $fixed_rate
#> [1] NA
#> 
#> $fixed_rate_scale
#> [1] NA
#> 
#> $period
#> NULL
#> 
#> attr(,"class")
#> [1] "count_strategy" "list"          
#> 
#> $FIXED_RATE
#> $base
#> [1] "MAR"
#> 
#> $rate_multiplier
#> [1] 1
#> 
#> $fixed_rate
#> [1] 0.003
#> 
#> $fixed_rate_scale
#> [1] "rate"
#> 
#> $period
#> [1] "3"
#> 
#> attr(,"class")
#> [1] "count_strategy" "list"          
#> 
#> $FIXED_LAMBDA
#> $base
#> [1] "MAR"
#> 
#> $rate_multiplier
#> [1] 1
#> 
#> $fixed_rate
#> [1] 0.0021
#> 
#> $fixed_rate_scale
#> [1] "lambda"
#> 
#> $period
#> [1] "3"
#> 
#> attr(,"class")
#> [1] "count_strategy" "list"          
#> 
#> $DOUBLE_RATE
#> $base
#> [1] "MAR"
#> 
#> $rate_multiplier
#> [1] 2
#> 
#> $fixed_rate
#> [1] NA
#> 
#> $fixed_rate_scale
#> [1] NA
#> 
#> $period
#> [1] "3"
#> 
#> attr(,"class")
#> [1] "count_strategy" "list"          
#> 
```
