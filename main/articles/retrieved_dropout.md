# rbmi: Implementation of retrieved-dropout models using rbmi

This vignette describes how retrieved dropout models which include
time-varying intercurrent event (ICE) indicators can be implemented in
the `rbmi` package.

## 1 Retrieved dropout models in a nutshell

Retrieved dropout models have been proposed for the analysis of
estimands using the treatment policy strategy for addressing an ICE. In
these models, missing outcomes are multiply imputed conditional upon
whether they occur pre- or post-ICE. Retrieved dropout models typically
rely on an extended missing-at-random (MAR) assumption, i.e., they
assume that missing outcome data is similar to observed data from
subjects in the same treatment group with the same observed outcome
history, and the same ICE status. For a more comprehensive description
and evaluation of retrieved dropout models, we refer to Guizzaro et al.
([2021](#ref-Guizzaro2021)), Polverejan and Dragalin
([2020](#ref-PolverejanDragalin2020)), Noci et al.
([2023](#ref-Noci2021)), Drury et al. ([2024](#ref-Drury2024)), and Bell
et al. ([2025](#ref-Bell2024)). Broadly, these publications find that
retrieved dropout models reduce bias compared to alternative analysis
approaches based on imputation under a basic MAR assumption or a
reference-based missing data assumption. However, several issues of
retrieved dropout models have also been highlighted. Retrieved dropout
models require that enough post-ICE data is collected to inform the
imputation model. Even with relatively small amounts of missingness,
complex retrieved dropout models may face identifiability issues.
Another drawback to these models in general is the loss of power
relative to reference-based imputation methods, which becomes meaningful
for post-ICE observation percentages below 50% and increases at an
accelerating rate as this percentage decreases ([Bell et al.
2025](#ref-Bell2024)).

## 2 Data simulation using function `simulate_data()`

For the purposes of this vignette we will first create a simulated
dataset with the `rbmi` function
[`simulate_data()`](https://openpharma.github.io/rbmi/reference/simulate_data.md).
The
[`simulate_data()`](https://openpharma.github.io/rbmi/reference/simulate_data.md)
function generates data from a randomized clinical trial with
longitudinal continuous outcomes and up to two different types of ICEs.

Specifically, we simulate a 1:1 randomized trial of an active drug
(intervention) versus placebo (control) with 100 subjects per group and
4 post-baseline assessments (3-monthly visits until 12 months):

- The mean outcome trajectory in the placebo group increases linearly
  from 50 at baseline (visit 0) to 60 at visit 4, i.e. the slope is 10
  points/year (or 2.5 points every 3 months).
- The mean outcome trajectory in the intervention group is identical to
  the placebo group up to month 6. From month 6 onward, the slope
  decreases by 50% to 5 points/year (i.e. 1.25 points every 3 months).
- The covariance structure of the baseline and follow-up values in both
  groups is implied by a random intercept and slope model with a
  standard deviation of 5 for both the intercept and the slope, and a
  correlation of 0.25. In addition, an independent residual error with
  standard deviation 2.5 is added to each assessment.  
- The probability of the intercurrent event study drug discontinuation
  after each visit is calculated according to a logistic model which
  depends on the observed outcome at that visit. Specifically, a
  visit-wise discontinuation probability of 3% and 4% in the control and
  intervention group, respectively, is specified in case the observed
  outcome is equal to 50 (the mean value at baseline). The odds of a
  discontinuation is simulated to increase by +10% for each +1 point
  increase of the observed outcome.
- Study drug discontinuation is simulated to have no effect on the mean
  trajectory in the placebo group. In the intervention group, subjects
  who discontinue follow the slope of the mean trajectory from the
  placebo group from that time point onward. This is compatible with a
  copy increments in reference (CIR) assumption.
- Study dropout at the study drug discontinuation visit occurs with a
  probability of 50% leading to missing outcome data from that time
  point onward.

The function
[`simulate_data()`](https://openpharma.github.io/rbmi/reference/simulate_data.md)
requires 3 arguments (see the function documentation
[`help(simulate_data)`](https://openpharma.github.io/rbmi/reference/simulate_data.md)
for more details):

- `pars_c`: The simulation parameters of the control group.
- `pars_t`: The simulation parameters of the intervention group.
- `post_ice1_traj`: Specifies how observed outcomes after ICE1 are
  simulated.

Below, we report how data according to the specifications above can be
simulated with function
[`simulate_data()`](https://openpharma.github.io/rbmi/reference/simulate_data.md):

``` r

library(rbmi)
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r

set.seed(1392)

time <- c(0, 3, 6, 9, 12)

# Mean trajectory control
muC <- c(50.0, 52.5, 55.0, 57.5, 60.0)

# Mean trajectory intervention
muT <- c(50.0, 52.5, 55.0, 56.25, 57.50)

# Create Sigma
sd_error <- 2.5
covRE <- rbind(
  c(25.0, 6.25),
  c(6.25, 25.0)
)

Sigma <- cbind(1, time / 12) %*%
    covRE %*% rbind(1, time / 12) +
    diag(sd_error^2, nrow = length(time))

# Set simulation parameters of the control group
parsC <- set_simul_pars(
    mu = muC,
    sigma = Sigma,
    n = 100, # sample size
    prob_ice1 = 0.03, # prob of discontinuation for outcome equal to 50
    or_outcome_ice1 = 1.10,  # +1 point increase => +10% odds of discontinuation
    prob_post_ice1_dropout = 0.5 # dropout rate following discontinuation
)

# Set simulation parameters of the intervention group
parsT <- parsC
parsT$mu <- muT
parsT$prob_ice1 <- 0.04

# Simulate data
data <- simulate_data(
    pars_c = parsC,
    pars_t = parsT,
    post_ice1_traj = "CIR" # Assumption about post-ice trajectory
) %>%
  select(-c(outcome_noICE, ind_ice2)) # remove unncessary columns
  

head(data)
```

    ##     id visit   group outcome_bl ind_ice1 dropout_ice1  outcome
    ## 1 id_1     0 Control   53.35397        0            0 53.35397
    ## 2 id_1     1 Control   53.35397        0            0 55.15100
    ## 3 id_1     2 Control   53.35397        0            0 59.81038
    ## 4 id_1     3 Control   53.35397        0            0 61.59709
    ## 5 id_1     4 Control   53.35397        0            0 67.08044
    ## 6 id_2     0 Control   53.31025        0            0 53.31025

The frequency of the ICE and proportion of data collected after the ICE
impacts the variance of the treatment effect for retrieved dropout
models. For example, a large proportion of ICE combined with a small
proportion of data collected after the ICE might result in substantial
variance inflation, especially for more complex retrieved dropout
models.

The proportion of subjects with an ICE and the proportion of subjects
who withdrew from the simulated study is summarized below:

``` r

# Compute endpoint of interest: change from baseline
data <- data %>% 
  filter(visit != "0") %>%
  mutate(
    change = outcome - outcome_bl,
    visit = factor(visit, levels = unique(visit))
  )
      

data %>%
  group_by(visit) %>% 
  summarise(
    freq_disc_ctrl = mean(ind_ice1[group == "Control"] == 1),
    freq_dropout_ctrl = mean(dropout_ice1[group == "Control"] == 1),
    freq_disc_interv = mean(ind_ice1[group == "Intervention"] == 1),
    freq_dropout_interv = mean(dropout_ice1[group == "Intervention"] == 1)
  )
```

    ## # A tibble: 4 × 5
    ##   visit freq_disc_ctrl freq_dropout_ctrl freq_disc_interv freq_dropout_interv
    ##   <fct>          <dbl>             <dbl>            <dbl>               <dbl>
    ## 1 1               0.03              0.01             0.06                0.03
    ## 2 2               0.1               0.03             0.1                 0.04
    ## 3 3               0.19              0.09             0.17                0.06
    ## 4 4               0.23              0.12             0.24                0.1

For this study 23% of the study participants discontinued from study
treatment in the control arm and 24% in the intervention arm.
Approximately half of the participants who discontinued from treatment
dropped-out from the study at the discontinuation visit leading to
missing outcomes at subsequent visits.

## 3 Estimators based on retrieved dropout models

We consider retrieved dropout methods which model pre- and post-ICE
outcomes jointly by including time-varying ICE indicators in the
imputation model, i.e. we allow the occurrence of the ICE to impact the
mean structure but not the covariance matrix. Imputation of missing
outcomes is then performed under a MAR assumption including all observed
data. For the analysis of the completed data, we use a standard ANCOVA
model of the outcome at each follow-up visit, respectively, with
treatment assignment as the main covariate and adjustment for the
baseline outcome.

Specifically, we consider the following imputation models:

- **Imputation under a basic MAR assumption (basic MAR)**: This model
  ignores whether an outcome is observed pre- or post-ICE, i.e. it is
  not a retrieved dropout model. Rather, it is asymptotically equivalent
  to a standard MMRM model and analogous to the “MI1” model in Bell et
  al. ([2025](#ref-Bell2024)). The only difference to the “MI1” model is
  that `rbmi` is not based on sequential imputation but rather, all
  missing outcomes are imputed simultaneously based on a MMRM-type
  imputation model. We include baseline outcome by visit and treatment
  group by visit interaction terms in the imputation model which is of
  the form: `change ~ outcome_bl*visit + group*visit`.
- **Retrieved dropout model 1 (RD1)**: This model uses the following
  imputation model:
  `change ~ outcome_bl*visit + group*visit + time_since_ice1*group`,
  where `time_since_ice1` is set to 0 up to the treatment
  discontinuation and to the time from treatment discontinuation (in
  months) at subsequent visits. This implies a change in the slope of
  the outcome trajectories after the ICE, which is modeled separately
  for each treatment arm. This model is similar to the “TV2-MAR”
  estimator in Noci et al. ([2023](#ref-Noci2021)). Compared to the
  basic MAR model, this model requires estimation of 2 additional
  parameters.
- **Retrieved dropout model 2 (RD2)**: This model uses the following
  imputation model:
  `change ~ outcome_bl*visit + group*visit + ind_ice1*group*visit`. This
  assumes a constant shift in outcomes after the ICE, which is modeled
  separately for each treatment arm and each visit. This model is
  analogous to the “MI2” model in Bell et al. ([2025](#ref-Bell2024)).
  Compared to the basic MAR model, this model requires estimation of 2
  times “number of visits” additional parameters. It makes different
  though rather weaker assumptions than the RD1 model but might also be
  harder to fit if post-ICE data collection is sparse at some visits.

## 4 Implementation of the defined retrieved dropout models in `rbmi`

`rbmi` supports the inclusion of time-varying covariates in the
imputation model. The only requirement is that the time-varying
covariate is non-missing at all visits including those where the outcome
might be missing. Imputation is performed under a (extended) MAR
assumption. Therefore, all imputation approaches implemented in `rbmi`
are valid and should yield comparable estimators and standard errors.
For this vignette, we used the conditional mean imputation approach
combined with the jackknife.

### 4.1 Basic MAR model

``` r

# Define key variables for the imputation and analysis models
vars <- set_vars(
  subjid = "id",
  visit = "visit",
  outcome = "change",
  group = "group",
  covariates = c("outcome_bl*visit", "group*visit")
)

vars_an <- vars
vars_an$covariates <- "outcome_bl"

# Define imputation method
method <- method_condmean(type = "jackknife")

draw_obj <- draws(
  data = data,
  data_ice = NULL,
  vars = vars,
  method = method,
  quiet = TRUE
)

impute_obj <- impute(
  draw_obj
)

ana_obj <- analyse(
  impute_obj,
  vars = vars_an
)

pool_obj_basicMAR <- pool(ana_obj)
pool_obj_basicMAR
```

    ## 
    ## Pool Object
    ## -----------
    ## Number of Results Combined: 1 + 200
    ## Method: jackknife
    ## Confidence Level: 0.95
    ## Alternative: two.sided
    ## 
    ## Results:
    ## 
    ##   ==================================================
    ##    parameter   est     se     lci     uci     pval  
    ##   --------------------------------------------------
    ##      trt_1    -0.991  0.557  -2.083  0.101   0.075  
    ##    lsm_ref_1  3.117   0.401  2.331   3.902   <0.001 
    ##    lsm_alt_1  2.126   0.391   1.36   2.892   <0.001 
    ##      trt_2    -0.937  0.611  -2.134   0.26   0.125  
    ##    lsm_ref_2  5.814   0.447  4.938    6.69   <0.001 
    ##    lsm_alt_2  4.877   0.414  4.066   5.688   <0.001 
    ##      trt_3    -1.491  0.743  -2.948  -0.034  0.045  
    ##    lsm_ref_3  7.725   0.526  6.694   8.757   <0.001 
    ##    lsm_alt_3  6.234   0.522  5.211   7.258   <0.001 
    ##      trt_4    -2.872  0.945  -4.723  -1.02   0.002  
    ##    lsm_ref_4  10.787  0.661  9.491   12.083  <0.001 
    ##    lsm_alt_4  7.915   0.67   6.603   9.228   <0.001 
    ##   --------------------------------------------------

### 4.2 Retrieved dropout model 1 (RD1)

``` r

# derive variable "time_since_ice1" (time since ICE in months)
data <- data %>% 
  group_by(id) %>% 
  mutate(time_since_ice1 = cumsum(ind_ice1)*3)

vars$covariates <- c("outcome_bl*visit", "group*visit", "time_since_ice1*group")

draw_obj <- draws(
  data = data,
  data_ice = NULL,
  vars = vars,
  method = method,
  quiet = TRUE
)

impute_obj <- impute(
  draw_obj
)

ana_obj <- analyse(
  impute_obj,
  vars = vars_an
)

pool_obj_RD1 <- pool(ana_obj)
pool_obj_RD1
```

    ## 
    ## Pool Object
    ## -----------
    ## Number of Results Combined: 1 + 200
    ## Method: jackknife
    ## Confidence Level: 0.95
    ## Alternative: two.sided
    ## 
    ## Results:
    ## 
    ##   ==================================================
    ##    parameter   est     se     lci     uci     pval  
    ##   --------------------------------------------------
    ##      trt_1    -0.931  0.558  -2.025  0.163   0.095  
    ##    lsm_ref_1  3.119    0.4   2.334   3.903   <0.001 
    ##    lsm_alt_1  2.188   0.393  1.419   2.957   <0.001 
    ##      trt_2    -0.805  0.616  -2.013  0.403   0.192  
    ##    lsm_ref_2  5.822   0.445  4.949   6.695   <0.001 
    ##    lsm_alt_2  5.017   0.424  4.186   5.849   <0.001 
    ##      trt_3    -1.263  0.758  -2.748  0.222   0.096  
    ##    lsm_ref_3  7.749   0.52   6.729   8.768   <0.001 
    ##    lsm_alt_3  6.486   0.549   5.41   7.562   <0.001 
    ##      trt_4    -2.506  0.969  -4.406  -0.606   0.01  
    ##    lsm_ref_4  10.837  0.653  9.558   12.116  <0.001 
    ##    lsm_alt_4  8.331   0.718  6.924   9.737   <0.001 
    ##   --------------------------------------------------

### 4.3 Retrieved dropout model 2 (RD2)

``` r

vars$covariates <- c("outcome_bl*visit", "group*visit", "ind_ice1*group*visit")

draw_obj <- draws(
  data = data,
  data_ice = NULL,
  vars = vars,
  method = method,
  quiet = TRUE
)

impute_obj <- impute(
  draw_obj
)

ana_obj <- analyse(
  impute_obj,
  vars = vars_an
)

pool_obj_RD2 <- pool(ana_obj)
pool_obj_RD2
```

    ## 
    ## Pool Object
    ## -----------
    ## Number of Results Combined: 1 + 200
    ## Method: jackknife
    ## Confidence Level: 0.95
    ## Alternative: two.sided
    ## 
    ## Results:
    ## 
    ##   ==================================================
    ##    parameter   est     se     lci     uci     pval  
    ##   --------------------------------------------------
    ##      trt_1    -0.927  0.558  -2.021  0.167   0.097  
    ##    lsm_ref_1  3.125    0.4   2.341   3.908   <0.001 
    ##    lsm_alt_1  2.198   0.395  1.424   2.972   <0.001 
    ##      trt_2    -0.889  0.612  -2.089  0.311   0.146  
    ##    lsm_ref_2  5.837   0.443   4.97   6.705   <0.001 
    ##    lsm_alt_2  4.948   0.421  4.124   5.772   <0.001 
    ##      trt_3    -1.305  0.757  -2.788  0.178   0.085  
    ##    lsm_ref_3  7.648   0.54    6.59   8.707   <0.001 
    ##    lsm_alt_3  6.343   0.528  5.308   7.378   <0.001 
    ##      trt_4    -2.617  0.975  -4.528  -0.706  0.007  
    ##    lsm_ref_4  10.883  0.665   9.58   12.186  <0.001 
    ##    lsm_alt_4  8.267   0.715  6.866   9.667   <0.001 
    ##   --------------------------------------------------

### 4.4 Brief summary of results

The point estimators of the treatment effect at the last visit were
-2.872, -2.506, and -2.617 for the basic MAR, RD1, and RD2 estimators,
respectively, i.e. slightly smaller for the retrieved dropout models
compared to the basic MAR model. The corresponding standard errors of
the 3 estimators were 0.945, 0.969, and 0.975, i.e. slightly larger for
the retrieved dropout models compared to the basic MAR model.

## References

Bell, James, Thomas Drury, Tobias Mütze, et al. 2025. “Estimation
Methods for Estimands Using the Treatment Policy Strategy; a Simulation
Study Based on the PIONEER 1 Trial.” *Pharmaceutical Statistics* 24 (2):
e2472. https://doi.org/<https://doi.org/10.1002/pst.2472>.

Drury, Thomas, Juan J Abellan, Nicky Best, and Ian R White. 2024.
“Estimation of Treatment Policy Estimands for Continuous Outcomes Using
Off-Treatment Sequential Multiple Imputation.” *Pharmaceutical
Statistics*.

Guizzaro, Lorenzo, Frank Pétavy, Robin Ristl, and Ciro Gallo. 2021. “The
Use of a Variable Representing Compliance Improves Accuracy of
Estimation of the Effect of Treatment Allocation Regardless of
Discontinuation in Trials with Incomplete Follow-up.” *Statistics in
Biopharmaceutical Research* 13 (1): 119–27.

Noci, Alessandro, Marcel Wolbers, Markus Abt, et al. 2023. “A Comparison
of Estimand and Estimation Strategies for Clinical Trials in Early
Parkinson’s Disease.” *Statistics in Biopharmaceutical Research* 15 (3):
491–501.

Polverejan, Elena, and Vladimir Dragalin. 2020. “Aligning Treatment
Policy Estimands and Estimators—a Simulation Study in Alzheimer’s
Disease.” *Statistics in Biopharmaceutical Research* 12 (2): 142–54.
