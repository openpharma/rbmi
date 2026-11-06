# Simulate intercurrent event

Simulate intercurrent event

## Usage

``` r
simulate_ice(outcome, visits, ids, prob_ice, or_outcome_ice, baseline_mean)
```

## Arguments

- outcome:

  Numeric variable that specifies the longitudinal outcome for a single
  group.

- visits:

  Factor variable that specifies the visit of each assessment.

- ids:

  Factor variable that specifies the id of each subject.

- prob_ice:

  Numeric vector that specifies for each visit the probability of
  experiencing the ICE after the current visit for a subject with
  outcome equal to the mean at baseline. If a single numeric is
  provided, then the same probability is applied to each visit.

- or_outcome_ice:

  Numeric value that specifies the odds ratio of the ICE corresponding
  to a +1 higher value of the outcome at the visit.

- baseline_mean:

  Mean outcome value at baseline.

## Value

A binary variable that takes value `1` if the corresponding outcome is
affected by the ICE and `0` otherwise.

## Details

The probability of the ICE after each visit is modelled according to the
following logistic regression model:
`~ 1 + I(visit == 0) + ... + I(visit == n_visits-1) + I((x-alpha))`
where:

- `n_visits` is the number of visits (including baseline).

- `alpha` is the baseline outcome mean set via argument `baseline_mean`.
  The term `I((x-alpha))` specifies the dependency of the probability of
  the ICE on the current outcome value. The corresponding regression
  coefficients of the logistic model are defined as follows: The
  intercept is set to 0, the coefficients corresponding to
  discontinuation after each visit for a subject with outcome equal to
  the mean at baseline are set according to parameter `or_outcome_ice`,
  and the regression coefficient associated with the covariate
  `I((x-alpha))` is set to `log(or_outcome_ice)`.
