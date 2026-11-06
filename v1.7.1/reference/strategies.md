# Strategies

These functions are used to implement various reference based imputation
strategies by combining a subjects own distribution with that of a
reference distribution based upon which of their visits failed to meet
the Missing-at-Random (MAR) assumption.

## Usage

``` r
strategy_MAR(pars_group, pars_ref, index_mar)

strategy_JR(pars_group, pars_ref, index_mar)

strategy_CR(pars_group, pars_ref, index_mar)

strategy_CIR(pars_group, pars_ref, index_mar)

strategy_LMCF(pars_group, pars_ref, index_mar)
```

## Arguments

- pars_group:

  A list of parameters for the subject's group. See details.

- pars_ref:

  A list of parameters for the subject's reference group. See details.

- index_mar:

  A logical vector indicating which visits meet the MAR assumption for
  the subject. I.e. this identifies the observations after a non-MAR
  intercurrent event (ICE).

## Value

A list with elements `mu` (a numeric vector of means) and `sigma` (a
covariance matrix) giving the parameters of the subject's imputation
distribution, formed by combining their own group's parameters
(`pars_group`) with the reference group's parameters (`pars_ref`)
according to the chosen strategy.

## Details

`pars_group` and `pars_ref` both must be a list containing elements `mu`
and `sigma`. `mu` must be a numeric vector and `sigma` must be a square
matrix symmetric covariance matrix with dimensions equal to the length
of `mu` and `index_mar`. e.g.

    list(
        mu = c(1,2,3),
        sigma = matrix(c(4,3,2,3,5,4,2,4,6), nrow = 3, ncol = 3)
    )

Users can define their own strategy functions and include them via the
`strategies` argument to
[`impute()`](https://openpharma.github.io/rbmi/reference/impute.md)
using
[`getStrategies()`](https://openpharma.github.io/rbmi/reference/getStrategies.md).
That being said the following strategies are available "out the box":

- Missing at Random (MAR)

- Jump to Reference (JR)

- Copy Reference (CR)

- Copy Increments in Reference (CIR)

- Last Mean Carried Forward (LMCF)

## Examples

``` r
# Parameters of the subject's own group and of the reference group
pars_group <- list(
    mu = c(1, 2, 3),
    sigma = as_vcov(c(1, 3, 2), c(0.4, 0.5, 0.45))
)
pars_ref <- list(
    mu = c(5, 6, 7),
    sigma = as_vcov(c(2, 1, 1), c(0.7, 0.8, 0.5))
)

# The first two visits meet the MAR assumption, the third does not
index_mar <- c(TRUE, TRUE, FALSE)

# Combine the parameters according to the different strategies
strategy_MAR(pars_group, pars_ref, index_mar)
#> $mu
#> [1] 1 2 3
#> 
#> $sigma
#>      [,1] [,2] [,3]
#> [1,]  1.0  1.2  1.0
#> [2,]  1.2  9.0  2.7
#> [3,]  1.0  2.7  4.0
#> 
strategy_JR(pars_group, pars_ref, index_mar)
#> $mu
#> [1] 1 2 7
#> 
#> $sigma
#>      [,1]       [,2]       [,3]
#> [1,]  1.0  1.2000000  0.3000000
#> [2,]  1.2  9.0000000 -0.5294118
#> [3,]  0.3 -0.5294118  0.5475779
#> 
strategy_CR(pars_group, pars_ref, index_mar)
#> $mu
#> [1] 5 6 7
#> 
#> $sigma
#>      [,1] [,2] [,3]
#> [1,]  4.0  1.4  1.6
#> [2,]  1.4  1.0  0.5
#> [3,]  1.6  0.5  1.0
#> 
strategy_CIR(pars_group, pars_ref, index_mar)
#> $mu
#> [1] 1 2 3
#> 
#> $sigma
#>      [,1]       [,2]       [,3]
#> [1,]  1.0  1.2000000  0.3000000
#> [2,]  1.2  9.0000000 -0.5294118
#> [3,]  0.3 -0.5294118  0.5475779
#> 
strategy_LMCF(pars_group, pars_ref, index_mar)
#> $mu
#> [1] 1 2 2
#> 
#> $sigma
#>      [,1] [,2] [,3]
#> [1,]  1.0  1.2  1.0
#> [2,]  1.2  9.0  2.7
#> [3,]  1.0  2.7  4.0
#> 
```
