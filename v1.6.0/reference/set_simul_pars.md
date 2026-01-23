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
drop-out, i.e. due to not study drug or condition related (NSDRC)
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
  ICE2, which may be thought as treatment discontinuation due to NSDRC
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
