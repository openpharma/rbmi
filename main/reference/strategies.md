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
