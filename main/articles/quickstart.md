# rbmi: Quickstart

## 1 Introduction

The purpose of this vignette is to provide a 15 minute quickstart guide
to the core functions of the `rbmi` package.

The `rbmi` package consists of 4 core functions (plus several helper
functions) which are typically called in sequence:

- [`draws()`](https://openpharma.github.io/rbmi/reference/draws.md) -
  fits the imputation models and stores their parameters
- [`impute()`](https://openpharma.github.io/rbmi/reference/impute.md) -
  creates multiple imputed datasets
- [`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md) -
  analyses each of the multiple imputed datasets
- [`pool()`](https://openpharma.github.io/rbmi/reference/pool.md) -
  combines the analysis results across imputed datasets into a single
  statistic

This example in this vignette makes use of Bayesian multiple imputation;
this functionality requires the installation of the suggested package
[`rstan`](https://CRAN.R-project.org/package=rstan).

    install.packages("rstan")

## 2 The Data

We use a publicly available example dataset from an antidepressant
clinical trial of an active drug versus placebo. The relevant endpoint
is the Hamilton 17-item depression rating scale (HAMD17) which was
assessed at baseline and at weeks 1, 2, 4, and 6. Study drug
discontinuation occurred in 24% of subjects from the active drug and 26%
of subjects from placebo. All data after study drug discontinuation are
missing and there is a single additional intermittent missing
observation.

``` r

library(rbmi)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

data("antidepressant_data")
dat <- antidepressant_data
```

We consider an imputation model with the mean change from baseline in
the HAMD17 score as the outcome (variable `CHANGE` in the dataset). The
following covariates are included in the imputation model: the treatment
group (`THERAPY`), the (categorical) visit (`VISIT`), treatment-by-visit
interactions, the baseline HAMD17 score (`BASVAL`), and baseline HAMD17
score-by-visit interactions. A common unstructured covariance matrix
structure is assumed for both groups. The analysis model is an ANCOVA
model with the treatment group as the primary factor and adjustment for
the baseline HAMD17 score.

`rbmi` expects its input dataset to be complete; that is, there must be
one row per subject for each visit. Missing outcome values should be
coded as `NA`, while missing covariate values are not allowed. If the
dataset is incomplete, then the
[`expand_locf()`](https://openpharma.github.io/rbmi/reference/expand.md)
helper function can be used to add any missing rows, using LOCF
imputation to carry forward the observed baseline covariate values to
visits with missing outcomes. Rows corresponding to missing outcomes are
not present in the antidepressant trial dataset. To address this we will
therefore use the
[`expand_locf()`](https://openpharma.github.io/rbmi/reference/expand.md)
function as follows:

``` r


# Use expand_locf to add rows corresponding to visits with missing outcomes to the dataset
dat <- expand_locf(
    dat,
    PATIENT = levels(dat$PATIENT), # expand by PATIENT and VISIT 
    VISIT = levels(dat$VISIT),
    vars = c("BASVAL", "THERAPY"), # fill with LOCF BASVAL and THERAPY
    group = c("PATIENT"),
    order = c("PATIENT", "VISIT")
)
```

## 3 Draws

The [`draws()`](https://openpharma.github.io/rbmi/reference/draws.md)
function fits the imputation models and stores the corresponding
parameter estimates or Bayesian posterior parameter draws. The three
main inputs to the
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md)
function are:

- `data` - The primary longitudinal data.frame containing the outcome
  variable and all covariates.
- `data_ice` - A data.frame which specifies the first visit affected by
  an intercurrent event (ICE) and the imputation strategy for handling
  missing outcome data after the ICE. At most one ICE which is to be
  imputed by a non-MAR strategy is allowed per subject.
- `method` - The statistical method used to fit the imputation models
  and to create imputed datasets.

For the antidepressant trial data, the dataset `data_ice` is not
provided. However, it can be derived because, in this dataset, the
subject’s first visit affected by the ICE “study drug discontinuation”
corresponds to the first terminal missing observation. We first derive
the dataset `data_ice` and then create 150 Bayesian posterior draws of
the imputation model parameters.

For this example, we assume that the imputation strategy after the ICE
is Jump To Reference (JR) for all subjects and that 150 multiple imputed
datasets using Bayesian posterior draws from the imputation model are to
be created.

``` r

# create data_ice and set the imputation strategy to JR for
# each patient with at least one missing observation
dat_ice <- dat %>% 
    arrange(PATIENT, VISIT) %>% 
    filter(is.na(CHANGE)) %>% 
    group_by(PATIENT) %>% 
    slice(1) %>%
    ungroup() %>% 
    select(PATIENT, VISIT) %>% 
    mutate(strategy = "JR")

# In this dataset, subject 3618 has an intermittent missing values which does not correspond
# to a study drug discontinuation. We therefore remove this subject from `dat_ice`. 
# (In the later imputation step, it will automatically be imputed under the default MAR assumption.)
dat_ice <- dat_ice[-which(dat_ice$PATIENT == 3618),]

dat_ice
#> # A tibble: 43 × 3
#>    PATIENT VISIT strategy
#>    <fct>   <fct> <chr>   
#>  1 1513    5     JR      
#>  2 1514    5     JR      
#>  3 1517    5     JR      
#>  4 1804    7     JR      
#>  5 2104    7     JR      
#>  6 2118    5     JR      
#>  7 2218    6     JR      
#>  8 2230    6     JR      
#>  9 2721    5     JR      
#> 10 2729    5     JR      
#> # ℹ 33 more rows

# Define the names of key variables in our dataset and
# the covariates included in the imputation model using `set_vars()`
# Note that the covariates argument can also include interaction terms
vars <- set_vars(
    outcome = "CHANGE",
    visit = "VISIT",
    subjid = "PATIENT",
    group = "THERAPY",
    covariates = c("BASVAL*VISIT", "THERAPY*VISIT")
)

# Define which imputation method to use (here: Bayesian multiple imputation with 150 imputed datsets)
method <- method_bayes(
    n_samples = 150,
    control = control_bayes(
        warmup = 200,
        thin = 5,
        seed = 1821 # Seed to be used by Stan
    )
)

# Create samples for the imputation parameters by running the draws() function
set.seed(987)
drawObj <- draws(
    data = dat,
    data_ice = dat_ice,
    vars = vars,
    method = method,
    quiet = TRUE
)
drawObj
#> 
#> Draws Object
#> ------------
#> Number of Samples: 150
#> Number of Failed Samples: 0
#> Model Formula: CHANGE ~ 1 + THERAPY + VISIT + BASVAL * VISIT + THERAPY * VISIT
#> Imputation Type: random
#> Method:
#>     name: Bayes
#>     covariance: us
#>     same_cov: TRUE
#>     n_samples: 150
#>     prior_cov: default
#> Controls:
#>     warmup: 200
#>     thin: 5
#>     chains: 1
#>     init: mmrm
#>     seed: 1821
```

Note the use of
[`set_vars()`](https://openpharma.github.io/rbmi/reference/set_vars.md)
which specifies the names of the key variables within the dataset and
the imputation model. Additionally, note that whilst `vars$group` and
`vars$visit` are added as terms to the imputation model by default,
their interaction is not, thus the inclusion of `group * visit` in the
list of covariates.

Available imputation methods include:

- Bayesian multiple imputation -
  [`method_bayes()`](https://openpharma.github.io/rbmi/reference/method.md)
- Approximate Bayesian multiple imputation -
  [`method_approxbayes()`](https://openpharma.github.io/rbmi/reference/method.md)
- Conditional mean imputation (bootstrap) -
  `method_condmean(type = "bootstrap")`
- Conditional mean imputation (jackknife) -
  `method_condmean(type = "jackknife")`
- Bootstrapped multiple imputation - `method = method_bmlmi()`

For a comparison of these methods, we refer to the `stat_specs` vignette
(Section 3.10).

“statistical specifications” vignette (Section 3.10):
[`vignette("stat_specs",package="rbmi")`](https://openpharma.github.io/rbmi/articles/stat_specs.md).

Available imputation strategies include:

- Missing At Random - `"MAR"`
- Jump to Reference - `"JR"`
- Copy Reference - `"CR"`
- Copy Increments from Reference - `"CIR"`
- Last Mean Carried Forward - `"LMCF"`

## 4 Impute

The next step is to use the parameters from the imputation model to
generate the imputed datasets. This is done via the
[`impute()`](https://openpharma.github.io/rbmi/reference/impute.md)
function. The function only has two key inputs: the imputation model
output from
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md) and
the reference groups relevant to reference-based imputation methods.
It’s usage is thus:

``` r

imputeObj <- impute(
    drawObj,
    references = c("DRUG" = "PLACEBO", "PLACEBO" = "PLACEBO")
)
imputeObj
#> 
#> Imputation Object
#> -----------------
#> Number of Imputed Datasets: 150
#> Fraction of Missing Data (Original Dataset):
#>     4:   0%
#>     5:   8%
#>     6:  13%
#>     7:  25%
#> References:
#>     DRUG    -> PLACEBO
#>     PLACEBO -> PLACEBO
```

In this instance, we are specifying that the `PLACEBO` group should be
the reference group for itself as well as for the `DRUG` group (as is
standard for imputation using reference-based methods).

Generally speaking, there is no need to see or directly interact with
the imputed datasets. However, if you do wish to inspect them, they can
be extracted from the imputation object using the
[`extract_imputed_dfs()`](https://openpharma.github.io/rbmi/reference/extract_imputed_dfs.md)
helper function, i.e.:

``` r

imputed_dfs <- extract_imputed_dfs(imputeObj)
head(imputed_dfs[[10]], 12) # first 12 rows of 10th imputed dataset
#>     PATIENT HAMATOTL PGIIMP RELDAYS VISIT THERAPY GENDER POOLINV BASVAL
#> 1  new_pt_1       21      2       7     4    DRUG      F     006     32
#> 2  new_pt_1       19      2      14     5    DRUG      F     006     32
#> 3  new_pt_1       21      3      28     6    DRUG      F     006     32
#> 4  new_pt_1       17      4      42     7    DRUG      F     006     32
#> 5  new_pt_2       18      3       7     4 PLACEBO      F     006     14
#> 6  new_pt_2       18      2      15     5 PLACEBO      F     006     14
#> 7  new_pt_2       14      3      29     6 PLACEBO      F     006     14
#> 8  new_pt_2        8      2      42     7 PLACEBO      F     006     14
#> 9  new_pt_3       18      3       7     4    DRUG      F     006     21
#> 10 new_pt_3       17      3      14     5    DRUG      F     006     21
#> 11 new_pt_3       12      3      28     6    DRUG      F     006     21
#> 12 new_pt_3        9      3      44     7    DRUG      F     006     21
#>    HAMDTL17 CHANGE
#> 1        21    -11
#> 2        20    -12
#> 3        19    -13
#> 4        17    -15
#> 5        11     -3
#> 6        14      0
#> 7         9     -5
#> 8         5     -9
#> 9        20     -1
#> 10       18     -3
#> 11       16     -5
#> 12       13     -8
```

Note that in the case of
[`method_bayes()`](https://openpharma.github.io/rbmi/reference/method.md)
or
[`method_approxbayes()`](https://openpharma.github.io/rbmi/reference/method.md),
all imputed datasets correspond to random imputations on the original
dataset. For
[`method_condmean()`](https://openpharma.github.io/rbmi/reference/method.md),
the first imputed dataset will always correspond to the completed
original dataset containing all subjects. For
`method_condmean(type="jackknife")`, the remaining datasets correspond
to conditional mean imputations on leave-one-subject-out datasets,
whereas for `method_condmean(type="bootstrap")`, each subsequent dataset
corresponds to a conditional mean imputation on a bootstrapped datasets.
For
[`method_bmlmi()`](https://openpharma.github.io/rbmi/reference/method.md),
all the imputed datasets correspond to sets of random imputations on
bootstrapped datasets.

## 5 Analyse

The next step is to run the analysis model on each imputed dataset. This
is done by defining an analysis function and then calling
[`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md) to
apply this function to each imputed dataset. For this vignette we use
the [`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md)
function provided by the `rbmi` package which fits a separate ANCOVA
model for the outcomes from each visit and returns a treatment effect
estimate and corresponding least square means for each group per visit.

``` r

anaObj <- analyse(
    imputeObj,
    ancova,
    vars = set_vars(
        subjid = "PATIENT",
        outcome = "CHANGE",
        visit = "VISIT",
        group = "THERAPY",
        covariates = c("BASVAL")
    )
)
anaObj
#> 
#> Analysis Object
#> ---------------
#> Number of Results: 150
#> Analysis Function: ancova
#> Delta Applied: FALSE
#> Analysis Estimates:
#>     trt_4
#>     lsm_ref_4
#>     lsm_alt_4
#>     trt_5
#>     lsm_ref_5
#>     lsm_alt_5
#>     trt_6
#>     lsm_ref_6
#>     lsm_alt_6
#>     trt_7
#>     lsm_ref_7
#>     lsm_alt_7
```

Note that, similar to
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md), the
[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md)
function uses the
[`set_vars()`](https://openpharma.github.io/rbmi/reference/set_vars.md)
function which determines the names of the key variables within the data
and the covariates (in addition to the treatment group) for which the
analysis model will be adjusted.

Please also note that the names of the analysis estimates contain `ref`
and `alt` to refer to the two treatment arms. In particular `ref` refers
to the first factor level of `vars$group` which does not necessarily
coincide with the control arm. In this example, since
`levels(dat[[vars$group]]) = c("DRUG", PLACEBO`), the results associated
with `ref` correspond to the intervention arm, while those associated
with `alt` correspond to the control arm.

Additionally, we can use the `delta` argument of
[`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md) to
perform a delta adjustments of the imputed datasets prior to the
analysis. In brief, this is implemented by specifying a data.frame that
contains the amount of adjustment to be added to each longitudinal
outcome for each subject and visit, i.e.  the data.frame must contain
the columns `subjid`, `visit`, and `delta`.

It is appreciated that carrying out this procedure is potentially
tedious, therefore the
[`delta_template()`](https://openpharma.github.io/rbmi/reference/delta_template.md)
helper function has been provided to simplify it. In particular,
[`delta_template()`](https://openpharma.github.io/rbmi/reference/delta_template.md)
returns a shell `data.frame` where the delta-adjustment is set to 0 for
all patients. Additionally
[`delta_template()`](https://openpharma.github.io/rbmi/reference/delta_template.md)
adds several meta-variables onto the shell `data.frame` which can be
used for manual derivation or manipulation of the delta-adjustment.

For example lets say we want to add a delta-value of 5 to all imputed
values (i.e. those values which were missing in the original dataset) in
the drug arm. That could then be implemented as follows:

``` r

# For reference show the additional meta variables provided
delta_template(imputeObj) %>% as_tibble()
#> # A tibble: 688 × 8
#>    PATIENT VISIT THERAPY is_mar is_missing is_post_ice strategy delta
#>    <fct>   <fct> <fct>   <lgl>  <lgl>      <lgl>       <chr>    <dbl>
#>  1 1503    4     DRUG    TRUE   FALSE      FALSE       NA           0
#>  2 1503    5     DRUG    TRUE   FALSE      FALSE       NA           0
#>  3 1503    6     DRUG    TRUE   FALSE      FALSE       NA           0
#>  4 1503    7     DRUG    TRUE   FALSE      FALSE       NA           0
#>  5 1507    4     PLACEBO TRUE   FALSE      FALSE       NA           0
#>  6 1507    5     PLACEBO TRUE   FALSE      FALSE       NA           0
#>  7 1507    6     PLACEBO TRUE   FALSE      FALSE       NA           0
#>  8 1507    7     PLACEBO TRUE   FALSE      FALSE       NA           0
#>  9 1509    4     DRUG    TRUE   FALSE      FALSE       NA           0
#> 10 1509    5     DRUG    TRUE   FALSE      FALSE       NA           0
#> # ℹ 678 more rows

delta_df <- delta_template(imputeObj) %>%
    as_tibble() %>% 
    mutate(delta = if_else(THERAPY == "DRUG" & is_missing , 5, 0)) %>% 
    select(PATIENT, VISIT, delta)
    
delta_df
#> # A tibble: 688 × 3
#>    PATIENT VISIT delta
#>    <fct>   <fct> <dbl>
#>  1 1503    4         0
#>  2 1503    5         0
#>  3 1503    6         0
#>  4 1503    7         0
#>  5 1507    4         0
#>  6 1507    5         0
#>  7 1507    6         0
#>  8 1507    7         0
#>  9 1509    4         0
#> 10 1509    5         0
#> # ℹ 678 more rows

anaObj_delta <- analyse(
    imputeObj,
    ancova,
    delta = delta_df,
    vars = set_vars(
        subjid = "PATIENT",
        outcome = "CHANGE",
        visit = "VISIT",
        group = "THERAPY",
        covariates = c("BASVAL")
    )
)
```

## 6 Pool

Finally, the
[`pool()`](https://openpharma.github.io/rbmi/reference/pool.md) function
can be used to summarise the analysis results across multiple imputed
datasets to provide an overall statistic with a standard error,
confidence intervals and a p-value for the hypothesis test of the null
hypothesis that the effect is equal to 0.

Note that the pooling method is automatically derived based on the
method that was specified in the original call to
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md):

- For
  [`method_bayes()`](https://openpharma.github.io/rbmi/reference/method.md)
  or
  [`method_approxbayes()`](https://openpharma.github.io/rbmi/reference/method.md)
  pooling and inference are based on Rubin’s rules.
- For `method_condmean(type = "bootstrap")` inference is either based on
  a normal approximation using the bootstrap standard error
  (`pool(..., type = "normal")`) or on the bootstrap percentiles
  (`pool(..., type = "percentile")`).
- For `method_condmean(type = "jackknife")` inference is based on a
  normal approximation using the jackknife estimate of the standard
  error.
- For `method = method_bmlmi()` inference is according to the methods
  described by von Hippel and Bartlett (see the `stat_specs` vignette
  for details)

Since we have used Bayesian multiple imputation in this vignette, the
[`pool()`](https://openpharma.github.io/rbmi/reference/pool.md) function
will automatically use Rubin’s rules.

``` r

poolObj <- pool(
    anaObj, 
    conf.level = 0.95, 
    alternative = "two.sided"
)
poolObj
#> 
#> Pool Object
#> -----------
#> Number of Results Combined: 150
#> Method: rubin
#> Confidence Level: 0.95
#> Alternative: two.sided
#> 
#> Results:
#> 
#>   ==================================================
#>    parameter   est     se     lci     uci     pval  
#>   --------------------------------------------------
#>      trt_4    -0.092  0.683  -1.439  1.256   0.893  
#>    lsm_ref_4  -1.616  0.486  -2.576  -0.656  0.001  
#>    lsm_alt_4  -1.708  0.475  -2.645  -0.77   <0.001 
#>      trt_5    1.335   0.922  -0.486  3.155    0.15  
#>    lsm_ref_5  -4.151  0.659  -5.452  -2.85   <0.001 
#>    lsm_alt_5  -2.817  0.646  -4.092  -1.541  <0.001 
#>      trt_6    1.954   0.995  -0.011   3.92   0.051  
#>    lsm_ref_6  -6.097  0.712  -7.503  -4.69   <0.001 
#>    lsm_alt_6  -4.142  0.703  -5.532  -2.753  <0.001 
#>      trt_7    2.178   1.108  -0.012  4.367   0.051  
#>    lsm_ref_7  -6.979  0.815  -8.591  -5.368  <0.001 
#>    lsm_alt_7  -4.802  0.781  -6.346  -3.257  <0.001 
#>   --------------------------------------------------
```

The table of values shown in the print message for `poolObj` can also be
extracted using the
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) function:

``` r

as.data.frame(poolObj)
#>    parameter         est        se         lci        uci         pval
#> 1      trt_4 -0.09180645 0.6826279 -1.43949684  1.2558839 8.931772e-01
#> 2  lsm_ref_4 -1.61581996 0.4862316 -2.57577141 -0.6558685 1.093708e-03
#> 3  lsm_alt_4 -1.70762640 0.4749573 -2.64531931 -0.7699335 4.262148e-04
#> 4      trt_5  1.33455043 0.9216123 -0.48555141  3.1546523 1.495580e-01
#> 5  lsm_ref_5 -4.15126657 0.6587725 -5.45235955 -2.8501736 2.782521e-09
#> 6  lsm_alt_5 -2.81671614 0.6458260 -4.09231775 -1.5411145 2.326660e-05
#> 7      trt_6  1.95433860 0.9951257 -0.01148677  3.9201640 5.133700e-02
#> 8  lsm_ref_6 -6.09654698 0.7120571 -7.50329905 -4.6897949 1.113203e-14
#> 9  lsm_alt_6 -4.14220838 0.7032457 -5.53183875 -2.7525780 2.470517e-08
#> 10     trt_7  2.17771720 1.1081169 -0.01202864  4.3674630 5.125541e-02
#> 11 lsm_ref_7 -6.97939079 0.8150110 -8.59099212 -5.3677895 1.983053e-14
#> 12 lsm_alt_7 -4.80167359 0.7814073 -6.34622034 -3.2571268 7.466459e-09
```

These outputs gives an estimated difference of 2.178 (95% CI -0.012 to
4.367) between the two groups at the last visit with an associated
p-value of 0.051.

## 7 Code

We report below all the code presented in this vignette.

``` r

library(rbmi)
library(dplyr)

data("antidepressant_data")
dat <- antidepressant_data

# Use expand_locf to add rows corresponding to visits with missing outcomes to the dataset
dat <- expand_locf(
    dat,
    PATIENT = levels(dat$PATIENT), # expand by PATIENT and VISIT 
    VISIT = levels(dat$VISIT),
    vars = c("BASVAL", "THERAPY"), # fill with LOCF BASVAL and THERAPY
    group = c("PATIENT"),
    order = c("PATIENT", "VISIT")
)

# Create data_ice and set the imputation strategy to JR for
# each patient with at least one missing observation
dat_ice <- dat %>% 
    arrange(PATIENT, VISIT) %>% 
    filter(is.na(CHANGE)) %>% 
    group_by(PATIENT) %>% 
    slice(1) %>%
    ungroup() %>% 
    select(PATIENT, VISIT) %>% 
    mutate(strategy = "JR")

# In this dataset, subject 3618 has an intermittent missing values which does not correspond
# to a study drug discontinuation. We therefore remove this subject from `dat_ice`. 
# (In the later imputation step, it will automatically be imputed under the default MAR assumption.)
dat_ice <- dat_ice[-which(dat_ice$PATIENT == 3618),]

# Define the names of key variables in our dataset using `set_vars()`
# and the covariates included in the imputation model
# Note that the covariates argument can also include interaction terms
vars <- set_vars(
    outcome = "CHANGE",
    visit = "VISIT",
    subjid = "PATIENT",
    group = "THERAPY",
    covariates = c("BASVAL*VISIT", "THERAPY*VISIT")
)

# Define which imputation method to use (here: Bayesian multiple imputation with 150 imputed datsets)
method <- method_bayes(
    n_samples = 150,
    control = control_bayes(
        warmup = 200,
        thin = 5,
        seed = 1821 # Seed to be used by Stan
    )
)

# Create samples for the imputation parameters by running the draws() function
set.seed(987)
drawObj <- draws(
    data = dat,
    data_ice = dat_ice,
    vars = vars,
    method = method,
    quiet = TRUE
)

# Impute the data
imputeObj <- impute(
    drawObj,
    references = c("DRUG" = "PLACEBO", "PLACEBO" = "PLACEBO")
)

# Fit the analysis model on each imputed dataset
anaObj <- analyse(
    imputeObj,
    ancova,
    vars = set_vars(
        subjid = "PATIENT",
        outcome = "CHANGE",
        visit = "VISIT",
        group = "THERAPY",
        covariates = c("BASVAL")
    )
)

# Apply a delta adjustment

# Add a delta-value of 5 to all imputed values (i.e. those values
# which were missing in the original dataset) in the drug arm.
delta_df <- delta_template(imputeObj) %>%
    as_tibble() %>% 
    mutate(delta = if_else(THERAPY == "DRUG" & is_missing , 5, 0)) %>% 
    select(PATIENT, VISIT, delta)

# Repeat the analyses with the adjusted values
anaObj_delta <- analyse(
    imputeObj,
    ancova,
    delta = delta_df,
    vars = set_vars(
        subjid = "PATIENT",
        outcome = "CHANGE",
        visit = "VISIT",
        group = "THERAPY",
        covariates = c("BASVAL")
    )
)

# Pool the results
poolObj <- pool(
    anaObj,
    conf.level = 0.95,
    alternative = "two.sided"
)
```
