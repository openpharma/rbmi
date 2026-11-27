# Simulate longitudinal count data

Simulates data from the negative multinomial model used for count
outcomes in `rbmi`. Each subject has a gamma-distributed frailty shared
by all periods, so the marginal period counts are negative binomial and
counts from the same subject are correlated.

## Usage

``` r
simulate_count_data(
  n = 100,
  groups = c("Control", "Intervention"),
  periods = as.character(1:3),
  log_rates = NULL,
  duration = 1,
  phi = 0.5,
  baseline_effect = 0,
  prob_miss = 0
)
```

## Arguments

- n:

  Number of subjects per treatment group. Either one positive integer or
  one positive integer for each element of `groups`.

- groups:

  Character vector containing the treatment-group levels.

- periods:

  Character, numeric, or factor vector containing the ordered period
  values.

- log_rates:

  Numeric matrix of marginal log event rates, with one row per treatment
  group and one column per period. If `NULL`, all log rates are 0.

- duration:

  Positive numeric exposure for each period. Either a scalar or a vector
  with one value per period.

- phi:

  Positive frailty variance, or dispersion parameter. Either a scalar
  shared by all groups or one value per treatment group. Conditional on
  its frailty, a subject's period counts are independent Poisson
  variables. The frailty has mean 1 and variance `phi`.

- baseline_effect:

  Numeric coefficient for a standard-normal, subject-level baseline
  covariate on the log-rate scale.

- prob_miss:

  Probability that the outcome is missing in each period. Either a
  scalar or one value per period. Missingness is generated independently
  after the complete counts have been simulated.

## Value

A `data.frame` with one row per subject and period and columns `id`,
`period`, `duration`, `group`, `baseline`, `outcome_full`, and
`outcome`. The `outcome_full` column contains the count before
missingness is applied.

## Examples

``` r
set.seed(123)
log_rates <- rbind(
    Control = log(c(1.0, 0.8, 0.8)),
    Intervention = log(c(1.4, 1.2, 1.2))
)
data <- simulate_count_data(
    n = 20,
    groups = rownames(log_rates),
    periods = as.character(1:3),
    log_rates = log_rates,
    duration = c(1, 1, 1),
    phi = 0.4,
    prob_miss = c(0, 0, 0.3)
)
head(data)
#>     id period duration   group   baseline outcome_full outcome
#> 1 id_1      1        1 Control -0.5604756            0       0
#> 2 id_1      2        1 Control -0.5604756            1       1
#> 3 id_1      3        1 Control -0.5604756            0       0
#> 4 id_2      1        1 Control -0.2301775            1       1
#> 5 id_2      2        1 Control -0.2301775            1       1
#> 6 id_2      3        1 Control -0.2301775            0      NA
```
