# Create a pooled-parameter transformation

Creates the transformation specification used by
[`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md)
from an expression in `x`. The expression is evaluated on the pooled
estimate and confidence limits; its symbolic derivative, obtained with
[`D()`](https://rdrr.io/r/stats/deriv.html), is used to calculate the
transformed standard error by the delta method. The transformation must
be monotone over every pooled confidence interval.

## Usage

``` r
use_transform(
  expression,
  scale = paste(deparse(substitute(expression)), collapse = " ")
)
```

## Arguments

- expression:

  An expression in `x` defining a vectorized transformation, for example
  `exp(x)`.

- scale:

  Single non-empty string naming the transformed scale, for example
  `"rate"`. Used when printing pooled results and their Monte Carlo
  standard errors. Defaults to the deparsed transformation expression.

## Value

A list containing `transform` and `derivative` functions and the `scale`
label, suitable for the `transform` argument of
[`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md).

## Examples

``` r
use_transform(exp(x), scale = "rate")
#> $scale
#> [1] "rate"
#> 
#> $transform
#> function(x) {
#>             eval(
#>                 transform_expression,
#>                 envir = list(x = x),
#>                 enclos = environment()
#>             )
#>         }
#> <environment: 0x56248b67c910>
#> 
#> $derivative
#> function(x) {
#>             value <- eval(
#>                 derivative_expression,
#>                 envir = list(x = x),
#>                 enclos = environment()
#>             )
#>             if (length(value) == 1) {
#>                 rep(value, length(x))
#>             } else {
#>                 value
#>             }
#>         }
#> <environment: 0x56248b67c910>
#> 
use_transform(-x)
#> $scale
#> [1] "-x"
#> 
#> $transform
#> function(x) {
#>             eval(
#>                 transform_expression,
#>                 envir = list(x = x),
#>                 enclos = environment()
#>             )
#>         }
#> <bytecode: 0x562482088400>
#> <environment: 0x56248a001ca0>
#> 
#> $derivative
#> function(x) {
#>             value <- eval(
#>                 derivative_expression,
#>                 envir = list(x = x),
#>                 enclos = environment()
#>             )
#>             if (length(value) == 1) {
#>                 rep(value, length(x))
#>             } else {
#>                 value
#>             }
#>         }
#> <bytecode: 0x56248b3087a0>
#> <environment: 0x56248a001ca0>
#> 
```
