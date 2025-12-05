# rbmi: Inference with Conditional Mean Imputation

## 1 Introduction

As described in section 3.10.2 of the statistical specifications of the
package
([`vignette(topic = "stat_specs", package = "rbmi")`](https://insightsengineering.github.io/rbmi/articles/stat_specs.md)),
two different types of variance estimators have been proposed for
reference-based imputation methods in the statistical literature
(Bartlett ([2023](#ref-Bartlett2021))). The first is the frequentist
variance which describes the actual repeated sampling variability of the
estimator and results in inference which is correct in the frequentist
sense, i.e. hypothesis tests have accurate type I error control and
confidence intervals have correct coverage probabilities under repeated
sampling if the reference-based assumption is correctly specified
(Bartlett ([2023](#ref-Bartlett2021)), Wolbers et al.
([2022](#ref-Wolbers2021))). Reference-based missing data assumption are
strong and borrow information from the control arm for imputation in the
active arm. As a consequence, the size of frequentist standard errors
for treatment effects may decrease with increasing amounts of missing
data. The second is the so-called “information-anchored” variance which
was originally proposed in the context of sensitivity analyses (Cro,
Carpenter, and Kenward ([2019](#ref-CroEtAl2019))). This variance
estimator is based on disentangling point estimation and variance
estimation altogether. The resulting information-anchored variance is
typically very similar to the variance under missing-at-random (MAR)
imputation and increases with increasing amounts of missing data at
approximately the same rate as MAR imputation. However, the
information-anchored variance does not reflect the actual variability of
the reference-based estimator and the resulting frequentist inference is
highly conservative resulting in a substantial power loss.

Reference-based conditional mean imputation combined with a resampling
method such as the jackknife or the bootstrap was first introduced in
Wolbers et al. ([2022](#ref-Wolbers2021)). This approach naturally
targets the frequentist variance. The information-anchored variance is
typically estimated using Rubin’s rules for Bayesian multiple imputation
which are not applicable within the conditional mean imputation
framework. However, an alternative information-anchored variance
proposed by Lu ([2021](#ref-Lu2021)) can easily be obtained as we show
below. The basic idea of Lu ([2021](#ref-Lu2021)) is to obtain the
information-anchored variance via a MAR imputation combined with a
delta-adjustment where delta is selected in a data-driven way to match
the reference-based estimator. For conditional mean imputation, the
proposal by Lu ([2021](#ref-Lu2021)) can be implemented by choosing the
delta-adjustment as the difference between the conditional mean
imputation under the chosen reference-based assumption and MAR on the
original dataset. The variance can then be obtained via the jackknife or
the bootstrap while keeping the delta-adjustment fixed. The resulting
variance estimate is very similar to Rubin’s variance. Moreover, as
shown in Cro, Carpenter, and Kenward ([2019](#ref-CroEtAl2019)), the
variance of MAR-imputation combined with a delta-adjustment achieves
even better information-anchoring properties than Rubin’s variance for
reference-based imputation. Reference-based missing data assumptions are
strong and borrow information from the control arm for imputation in the
active arm.

This vignette demonstrates first how to obtain frequentist inference
using reference-based conditional mean imputation using `rbmi`, and then
shows that an information-anchored inference can also be easily
implemented using the package.

## 2 Data and model specification

We use a publicly available example dataset from an antidepressant
clinical trial of an active drug versus placebo. The relevant endpoint
is the Hamilton 17-item depression rating scale (HAMD17) which was
assessed at baseline and at weeks 1, 2, 4, and 6. Study drug
discontinuation occurred in 24% of subjects from the active drug and 26%
of subjects from placebo. All data after study drug discontinuation are
missing and there is a single additional intermittent missing
observation.

We consider an imputation model with the mean change from baseline in
the HAMD17 score as the outcome (variable CHANGE in the dataset). The
following covariates are included in the imputation model: the treatment
group (THERAPY), the (categorical) visit (VISIT), treatment-by-visit
interactions, the baseline HAMD17 score (BASVAL), and baseline HAMD17
score-by-visit interactions. A common unstructured covariance matrix
structure is assumed for both groups. The analysis model is an ANCOVA
model with the treatment group as the primary factor and adjustment for
the baseline HAMD17 score. For this example, we assume that the
imputation strategy after the ICE “study-drug discontinuation” is Jump
To Reference (JR) for all subjects and the imputation is based on
conditional mean imputation combined with jackknife resampling (but the
bootstrap could also have been selected).

## 3 Reference-based conditional mean imputation - frequentist inference

Conditional mean imputation combined with a resampling method such as
jackknife or bootstrap naturally targets a frequentist estimation of the
standard error of the treatment effect, thus providing a valid
frequentist inference. Here we provide the code to obtain frequentist
inference for reference-based conditional mean imputation using `rbmi`.

The code used in this section is almost identical to the code in the
quickstart vignette
([`vignette(topic = "quickstart", package = "rbmi")`](https://insightsengineering.github.io/rbmi/articles/quickstart.md))
except that we use conditional mean imputation combined with the
jackknife (`method_condmean(type = "jackknife")`) here rather than
Bayesian multiple imputation
([`method_bayes()`](https://insightsengineering.github.io/rbmi/reference/method.md)).
We therefore refer to that vignette and the help files for the
individual functions for further explanations and details.

### 3.1 Draws

We will make use of
[`rbmi::expand_locf()`](https://insightsengineering.github.io/rbmi/reference/expand.md)
to expand the dataset in order to have one row per subject per visit
with missing outcomes denoted as `NA`. We will then construct the
`data_ice`, `vars` and `method` input arguments to the first core `rbmi`
function,
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).
Finally, we call the function
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md)
to derive the parameter estimates of the base imputation model for the
full dataset and all leave-one-subject-out samples.

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

dat <- antidepressant_data

# Use expand_locf to add rows corresponding to visits with missing outcomes to
# the dataset
dat <- expand_locf(
  dat,
  PATIENT = levels(dat$PATIENT), # expand by PATIENT and VISIT 
  VISIT = levels(dat$VISIT),
  vars = c("BASVAL", "THERAPY"), # fill with LOCF BASVAL and THERAPY
  group = c("PATIENT"),
  order = c("PATIENT", "VISIT")
)

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

# In this dataset, subject 3618 has an intermittent missing values which
# does not correspond to a study drug discontinuation. We therefore remove
# this subject from `dat_ice`. (In the later imputation step, it will
# automatically be imputed under the default MAR assumption.)
dat_ice <- dat_ice[-which(dat_ice$PATIENT == 3618),]

# Define the names of key variables in our dataset and
# the covariates included in the imputation model using `set_vars()`
vars <- set_vars(
  outcome = "CHANGE",
  visit = "VISIT",
  subjid = "PATIENT",
  group = "THERAPY",
  covariates = c("BASVAL*VISIT", "THERAPY*VISIT")
)

# Define which imputation method to use (here: conditional mean imputation
# with jackknife as resampling) 
method <- method_condmean(type = "jackknife")

# Create samples for the imputation parameters by running the draws() function
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
#> Number of Samples: 1 + 172
#> Number of Failed Samples: 0
#> Model Formula: CHANGE ~ 1 + THERAPY + VISIT + BASVAL * VISIT + THERAPY * VISIT
#> Imputation Type: condmean
#> Method:
#>     name: Conditional Mean
#>     covariance: us
#>     threshold: 0.01
#>     same_cov: TRUE
#>     REML: TRUE
#>     type: jackknife
```

### 3.2 Impute

We can use now the function
[`impute()`](https://insightsengineering.github.io/rbmi/reference/impute.md)
to perform the imputation of the original dataset and of each
leave-one-out samples using the results obtained at the previous step.

``` r
references <- c("DRUG" = "PLACEBO", "PLACEBO" = "PLACEBO")
imputeObj <- impute(drawObj, references)
imputeObj
#> 
#> Imputation Object
#> -----------------
#> Number of Imputed Datasets: 1 + 172
#> Fraction of Missing Data (Original Dataset):
#>     4:   0%
#>     5:   8%
#>     6:  13%
#>     7:  25%
#> References:
#>     DRUG    -> PLACEBO
#>     PLACEBO -> PLACEBO
```

### 3.3 Analyse

Once the datasets have been imputed, we can call the
[`analyse()`](https://insightsengineering.github.io/rbmi/reference/analyse.md)
function to apply the complete-data analysis model (here ANCOVA) to each
imputed dataset.

``` r

# Set analysis variables using `rbmi` function "set_vars"
vars_an <- set_vars(
  group = vars$group,
  visit = vars$visit,
  outcome = vars$outcome,
  covariates = "BASVAL"
)

# Analyse MAR imputation with derived delta adjustment
anaObj <- analyse(
  imputeObj,
  rbmi::ancova,
  vars = vars_an
)
anaObj
#> 
#> Analysis Object
#> ---------------
#> Number of Results: 1 + 172
#> Analysis Function: rbmi::ancova
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

### 3.4 Pool

Finally, we can extract the treatment effect estimates and perform
inference using the jackknife variance estimator. This is done by
calling the
[`pool()`](https://insightsengineering.github.io/rbmi/reference/pool.md)
function.

``` r
poolObj <- pool(anaObj)
poolObj
#> 
#> Pool Object
#> -----------
#> Number of Results Combined: 1 + 172
#> Method: jackknife
#> Confidence Level: 0.95
#> Alternative: two.sided
#> 
#> Results:
#> 
#>   ==================================================
#>    parameter   est     se     lci     uci     pval  
#>   --------------------------------------------------
#>      trt_4    -0.092  0.695  -1.453   1.27   0.895  
#>    lsm_ref_4  -1.616  0.588  -2.767  -0.464  0.006  
#>    lsm_alt_4  -1.708  0.396  -2.484  -0.931  <0.001 
#>      trt_5    1.305   0.878  -0.416  3.027   0.137  
#>    lsm_ref_5  -4.133  0.688  -5.481  -2.785  <0.001 
#>    lsm_alt_5  -2.828  0.604  -4.011  -1.645  <0.001 
#>      trt_6    1.929   0.862  0.239   3.619   0.025  
#>    lsm_ref_6  -6.088  0.671  -7.402  -4.773  <0.001 
#>    lsm_alt_6  -4.159  0.686  -5.503  -2.815  <0.001 
#>      trt_7    2.126   0.858  0.444   3.807   0.013  
#>    lsm_ref_7  -6.965  0.685  -8.307  -5.622  <0.001 
#>    lsm_alt_7  -4.839  0.762  -6.333  -3.346  <0.001 
#>   --------------------------------------------------
```

This gives an estimated treatment effect of 2.13 (95% CI 0.44 to 3.81)
at the last visit with an associated p-value of 0.013.

## 4 Reference-based conditional mean imputation - information-anchored inference

In this section, we present how the estimation process based on
conditional mean imputation combined with the jackknife can be adapted
to obtain an information-anchored variance following the proposal by Lu
([2021](#ref-Lu2021)).

### 4.1 Draws

The code for the pre-processing of the dataset and for the “draws” step
is equivalent to the code provided for the frequentist inference. Please
refer to [that section](#draws) for details about this step.

``` r

library(rbmi)
library(dplyr)

dat <- antidepressant_data

# Use expand_locf to add rows corresponding to visits with missing outcomes to
# the dataset
dat <- expand_locf(
  dat,
  PATIENT = levels(dat$PATIENT), # expand by PATIENT and VISIT 
  VISIT = levels(dat$VISIT),
  vars = c("BASVAL", "THERAPY"), # fill with LOCF BASVAL and THERAPY
  group = c("PATIENT"),
  order = c("PATIENT", "VISIT")
)

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

# In this dataset, subject 3618 has an intermittent missing values which
# does not correspond to a study drug discontinuation. We therefore remove
# this subject from `dat_ice`. (In the later imputation step, it will
# automatically be imputed under the default MAR assumption.)
dat_ice <- dat_ice[-which(dat_ice$PATIENT == 3618),]

# Define the names of key variables in our dataset and
# the covariates included in the imputation model using `set_vars()`
vars <- set_vars(
  outcome = "CHANGE",
  visit = "VISIT",
  subjid = "PATIENT",
  group = "THERAPY",
  covariates = c("BASVAL*VISIT", "THERAPY*VISIT")
)

# Define which imputation method to use (here: conditional mean imputation
# with jackknife as resampling) 
method <- method_condmean(type = "jackknife")

# Create samples for the imputation parameters by running the draws() function
drawObj <- draws(
  data = dat,
  data_ice = dat_ice,
  vars = vars,
  method = method,
  quiet = TRUE
)
drawObj
```

### 4.2 Imputation step including calculation of delta-adjustment

The proposal by Lu ([2021](#ref-Lu2021)) is to replace the
reference-based imputation by a MAR imputation combined with a
delta-adjustment where delta is selected in a data-driven way to match
the reference-based estimator. In `rbmi`, this is implemented by first
performing the imputation under the defined reference-based imputation
strategy (here JR) as well as under MAR separately. Second, the
delta-adjustment is defined as the difference between the conditional
mean imputation under reference-based and MAR imputation, respectively,
on the original dataset.

To simplify the implementation, we have written a function
`get_delta_match_refBased` that performs this step. The function takes
as input arguments the `draws` object, `data_ice` (i.e. the `data.frame`
containing the information about the intercurrent events and the
imputation strategies), and `references`, a named vector that identifies
the references to be used for reference-based imputation methods. The
function returns a list containing the imputation objects under both
reference-based and MAR imputation, plus a `data.frame` which contains
the delta-adjustment.

``` r

#' Get delta adjustment that matches reference-based imputation
#' 
#' @param draws: A `draws` object created by `draws()`.
#' @param data_ice: `data.frame` containing the information about the intercurrent
#' events and the imputation strategies. Must represent the desired imputation
#' strategy and not the MAR-variant.
#' @param references: A named vector. Identifies the references to be used
#' for reference-based imputation methods.
#' 
#' @return 
#' The function returns a list containing the imputation objects under both
#' reference-based and MAR imputation, plus a `data.frame` which contains the
#' delta-adjustment.
#' 
#' @seealso `draws()`, `impute()`.
get_delta_match_refBased <- function(draws, data_ice, references) {
  
  # Impute according to `data_ice`
  imputeObj <- impute(
    draws = drawObj,
    update_strategy = data_ice,
    references = references
  )
  
  vars <- imputeObj$data$vars
  
  # Access imputed dataset (index=1 for method_condmean(type = "jackknife"))
  cmi <- extract_imputed_dfs(imputeObj, index = 1, idmap = TRUE)[[1]]
  idmap <- attributes(cmi)$idmap
  cmi <- cmi[, c(vars$subjid, vars$visit, vars$outcome)]
  colnames(cmi)[colnames(cmi) == vars$outcome] <- "y_imp"
  
  # Map back original patients id since `rbmi` re-code ids to ensure id uniqueness
  
  cmi[[vars$subjid]] <- idmap[match(cmi[[vars$subjid]], names(idmap))]
  
  # Derive conditional mean imputations under MAR
  dat_ice_MAR <- data_ice 
  dat_ice_MAR[[vars$strategy]] <- "MAR"
  
  # Impute under MAR 
  # Note that in this specific context, it is desirable that an update   

  # from a reference-based strategy to MAR uses the exact same data for 
  # fitting the imputation models, i.e. that available post-ICE data are 
  # omitted from the imputation model for both. This is the case when    
  # using argument update_strategy in function impute(). 
  # However, for other settings (i.e. if one is interested in switching to
  # a standard MAR imputation strategy altogether), this behavior is  
  # undesirable and, consequently, the function throws a warning which 
  # we suppress here. 
  suppressWarnings(
    imputeObj_MAR <- impute(
      draws,
      update_strategy = dat_ice_MAR
    )
  ) 
  
  # Access imputed dataset (index=1 for method_condmean(type = "jackknife"))
  cmi_MAR <- extract_imputed_dfs(imputeObj_MAR, index = 1, idmap = TRUE)[[1]]
  idmap <- attributes(cmi_MAR)$idmap
  cmi_MAR <- cmi_MAR[, c(vars$subjid, vars$visit, vars$outcome)]
  colnames(cmi_MAR)[colnames(cmi_MAR) == vars$outcome] <- "y_MAR"
  
  # Map back original patients id since `rbmi` re-code ids to ensure id uniqueness
  cmi_MAR[[vars$subjid]] <- idmap[match(cmi_MAR[[vars$subjid]], names(idmap))]
  
  # Derive delta adjustment "aligned with ref-based imputation",
  # i.e. difference between ref-based imputation and MAR imputation
  delta_adjust <- merge(cmi, cmi_MAR, by = c(vars$subjid, vars$visit), all = TRUE)
  delta_adjust$delta <- delta_adjust$y_imp - delta_adjust$y_MAR

  ret_obj <- list(
    imputeObj = imputeObj,
    imputeObj_MAR = imputeObj_MAR,
    delta_adjust = delta_adjust
  )
  
  return(ret_obj)
}

references <- c("DRUG" = "PLACEBO", "PLACEBO" = "PLACEBO")

res_delta_adjust <- get_delta_match_refBased(drawObj, dat_ice, references)
```

### 4.3 Analyse

We use the function
[`analyse()`](https://insightsengineering.github.io/rbmi/reference/analyse.md)
to add the delta-adjustment and perform the analysis of the imputed
datasets under MAR.
[`analyse()`](https://insightsengineering.github.io/rbmi/reference/analyse.md)
will take as the input argument
`imputations = res_delta_adjust$imputeObj_MAR`, i.e. the imputation
object corresponding to the MAR imputation (and not the JR imputation).
The argument `delta` can be used to add a delta-adjustment prior to the
analysis and we set this to the delta-adjustment obtained in the
previous step: `delta = res_delta_adjust$delta_adjust`.

``` r

# Set analysis variables using `rbmi` function "set_vars"
vars_an <- set_vars(
  group = vars$group,
  visit = vars$visit,
  outcome = vars$outcome,
  covariates = "BASVAL"
)

# Analyse MAR imputation with derived delta adjustment
anaObj_MAR_delta <- analyse(
  res_delta_adjust$imputeObj_MAR,
  rbmi::ancova,
  delta = res_delta_adjust$delta_adjust,
  vars = vars_an
)
```

### 4.4 Pool

We can finally use the
[`pool()`](https://insightsengineering.github.io/rbmi/reference/pool.md)
function to extract the treatment effect estimate (as well as the
estimated marginal means) at each visit and apply the jackknife variance
estimator to the analysis estimates from all the imputed leave-one-out
samples.

``` r

poolObj_MAR_delta <- pool(anaObj_MAR_delta)
poolObj_MAR_delta
#> 
#> Pool Object
#> -----------
#> Number of Results Combined: 1 + 172
#> Method: jackknife
#> Confidence Level: 0.95
#> Alternative: two.sided
#> 
#> Results:
#> 
#>   ==================================================
#>    parameter   est     se     lci     uci     pval  
#>   --------------------------------------------------
#>      trt_4    -0.092  0.695  -1.453   1.27   0.895  
#>    lsm_ref_4  -1.616  0.588  -2.767  -0.464  0.006  
#>    lsm_alt_4  -1.708  0.396  -2.484  -0.931  <0.001 
#>      trt_5    1.305   0.944  -0.545  3.156   0.167  
#>    lsm_ref_5  -4.133  0.738  -5.579  -2.687  <0.001 
#>    lsm_alt_5  -2.828  0.603  -4.01   -1.646  <0.001 
#>      trt_6    1.929   0.993  -0.018  3.876   0.052  
#>    lsm_ref_6  -6.088  0.758  -7.574  -4.602  <0.001 
#>    lsm_alt_6  -4.159  0.686  -5.504  -2.813  <0.001 
#>      trt_7    2.126   1.123  -0.076  4.327   0.058  
#>    lsm_ref_7  -6.965  0.85   -8.63   -5.299  <0.001 
#>    lsm_alt_7  -4.839  0.763  -6.335  -3.343  <0.001 
#>   --------------------------------------------------
```

This gives an estimated treatment effect of 2.13 (95% CI -0.08 to 4.33)
at the last visit with an associated p-value of 0.058. Per construction
of the delta-adjustment, the point estimate is identical to the
frequentist analysis. However, its standard error is much larger (1.12
vs. 0.86). Indeed, the information-anchored standard error (and the
resulting inference) is very similar to the results for Baysesian
multiple imputation using Rubin’s rules for which a standard error of
1.13 was reported in the quickstart vignette
(`vignette(topic = "quickstart", package = "rbmi"`). Of note, as shown
e.g. in Wolbers et al. ([2022](#ref-Wolbers2021)), hypothesis testing
based on the information-anchored inference is very conservative,
i.e. the actual type I error is much lower than the nominal value.
Hence, confidence intervals and \\p\\-values based on
information-anchored inference should be interpreted with caution.

## References

Bartlett, Jonathan W. 2023. “Reference-Based Multiple Imputation - What
Is the Right Variance and How to Estimate It.” *Statistics in
Biopharmaceutical Research* 15 (1): 178–86.

Cro, Suzie, James R Carpenter, and Michael G Kenward. 2019.
“Information-Anchored Sensitivity Analysis: Theory and Application.”
*Journal of the Royal Statistical Society: Series A (Statistics in
Society)* 182 (2): 623–45.

Lu, Kaifeng. 2021. “An Alternative Implementation of Reference-Based
Controlled Imputation Procedures.” *Statistics in Biopharmaceutical
Research* 13 (4): 483–91.

Wolbers, Marcel, Alessandro Noci, Paul Delmar, Craig Gower-Page, Sean
Yiu, and Jonathan W Bartlett. 2022. “Standard and Reference-Based
Conditional Mean Imputation.” *Pharmaceutical Statistics* 21 (6):
1246–57.
