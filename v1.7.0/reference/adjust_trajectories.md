# Adjust trajectories due to the intercurrent event (ICE)

Adjust trajectories due to the intercurrent event (ICE)

## Usage

``` r
adjust_trajectories(
  distr_pars_group,
  outcome,
  ids,
  ind_ice,
  strategy_fun,
  distr_pars_ref = NULL
)
```

## Arguments

- distr_pars_group:

  Named list containing the simulation parameters of the multivariate
  normal distribution assumed for the given treatment group. It contains
  the following elements:

  - `mu`: Numeric vector indicating the mean outcome trajectory. It
    should include the outcome at baseline.

  - `sigma` Covariance matrix of the outcome trajectory.

- outcome:

  Numeric variable that specifies the longitudinal outcome.

- ids:

  Factor variable that specifies the id of each subject.

- ind_ice:

  A binary variable that takes value `1` if the corresponding outcome is
  affected by the ICE and `0` otherwise.

- strategy_fun:

  Function implementing trajectories after the intercurrent event (ICE).
  Must be one of
  [`getStrategies()`](https://openpharma.github.io/rbmi/reference/getStrategies.md).
  See
  [`getStrategies()`](https://openpharma.github.io/rbmi/reference/getStrategies.md)
  for details.

- distr_pars_ref:

  Optional. Named list containing the simulation parameters of the
  reference arm. It contains the following elements:

  - `mu`: Numeric vector indicating the mean outcome trajectory assuming
    no ICEs. It should include the outcome at baseline.

  - `sigma` Covariance matrix of the outcome trajectory assuming no
    ICEs.

## Value

A numeric vector containing the adjusted trajectories.

## See also

[`adjust_trajectories_single()`](https://openpharma.github.io/rbmi/reference/adjust_trajectories_single.md).
