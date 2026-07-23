# Set simulation parameters of a study group.

This function provides input arguments for each study group needed to
simulate data with
[`simulate_data()`](https://openpharma.github.io/rbmi/reference/simulate_data.md).
[`simulate_data()`](https://openpharma.github.io/rbmi/reference/simulate_data.md)
generates data for a two-arms clinical trial with longitudinal
continuous outcomes and two intercurrent events (ICEs). ICE1 may be
thought of as a discontinuation from study treatment due to study drug
or condition related (SDCR) reasons. ICE2 may be thought of as
discontinuation from study treatment due to uninformative study
drop-out, i.e. due to not study drug or condition related (NSDCR)
reasons and outcome data after ICE2 is always missing.

## Usage

``` r
set_simul_pars(
  mu,
  sigma,
  n,
  prob_ice1 = 0,
  or_outcome_ice1 = 1,
  prob_post_ice1_dropout = 0,
  prob_ice2 = 0,
  prob_miss = 0
)
```

## Arguments

- mu:

  Numeric vector describing the mean outcome trajectory at each visit
  (including baseline) assuming no ICEs.

- sigma:

  Covariance matrix of the outcome trajectory assuming no ICEs.

- n:

  Number of subjects belonging to the group.

- prob_ice1:

  Numeric vector that specifies the probability of experiencing ICE1
  (discontinuation from study treatment due to SDCR reasons) after each
  visit for a subject with observed outcome at that visit equal to the
  mean at baseline (`mu[1]`). If a single numeric is provided, then the
  same probability is applied to each visit.

- or_outcome_ice1:

  Numeric value that specifies the odds ratio of experiencing ICE1 after
  each visit corresponding to a +1 higher value of the observed outcome
  at that visit.

- prob_post_ice1_dropout:

  Numeric value that specifies the probability of study drop-out
  following ICE1. If a subject is simulated to drop-out after ICE1, all
  outcomes after ICE1 are set to missing.

- prob_ice2:

  Numeric that specifies an additional probability that a post-baseline
  visit is affected by study drop-out. Outcome data at the subject's
  first simulated visit affected by study drop-out and all subsequent
  visits are set to missing. This generates a second intercurrent event
  ICE2, which may be thought as treatment discontinuation due to NSDCR
  reasons with subsequent drop-out. If for a subject, both ICE1 and ICE2
  are simulated to occur, then it is assumed that only the earlier of
  them counts. In case both ICEs are simulated to occur at the same
  time, it is assumed that ICE1 counts. This means that a single subject
  can experience either ICE1 or ICE2, but not both of them.

- prob_miss:

  Numeric value that specifies an additional probability for a given
  post-baseline observation to be missing. This can be used to produce
  "intermittent" missing values which are not associated with any ICE.

## Value

A `simul_pars` object which is a named list containing the simulation
parameters.

## Details

For the details, please see
[`simulate_data()`](https://openpharma.github.io/rbmi/reference/simulate_data.md).

## See also

[`simulate_data()`](https://openpharma.github.io/rbmi/reference/simulate_data.md)

## Examples

``` r
# Simulation parameters for a group with 5 visits (including baseline)
time <- c(0, 3, 6, 9, 12)

# Mean outcome trajectory
mu <- c(50.0, 52.5, 55.0, 57.5, 60.0)

# Covariance matrix implied by a random intercept and slope model
sd_error <- 2.5
covRE <- rbind(
    c(25.0, 6.25),
    c(6.25, 25.0)
)
sigma <- cbind(1, time / 12) %*% covRE %*% rbind(1, time / 12) +
    diag(sd_error^2, nrow = length(time))

set_simul_pars(
    mu = mu,
    sigma = sigma,
    n = 100,
    prob_ice1 = 0.03,
    or_outcome_ice1 = 1.10,
    prob_post_ice1_dropout = 0.5
)
#> $mu
#> [1] 50.0 52.5 55.0 57.5 60.0
#> 
#> $sigma
#>         [,1]    [,2]    [,3]    [,4]    [,5]
#> [1,] 31.2500 26.5625 28.1250 29.6875 31.2500
#> [2,] 26.5625 35.9375 32.8125 35.9375 39.0625
#> [3,] 28.1250 32.8125 43.7500 42.1875 46.8750
#> [4,] 29.6875 35.9375 42.1875 54.6875 54.6875
#> [5,] 31.2500 39.0625 46.8750 54.6875 68.7500
#> 
#> $n
#> [1] 100
#> 
#> $prob_ice1
#> [1] 0.03
#> 
#> $or_outcome_ice1
#> [1] 1.1
#> 
#> $prob_post_ice1_dropout
#> [1] 0.5
#> 
#> $prob_ice2
#> [1] 0
#> 
#> $prob_miss
#> [1] 0
#> 
#> attr(,"class")
#> [1] "simul_pars"
```
