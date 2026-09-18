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

[`library`](https://rdrr.io/r/base/library.html)`(`[`rbmi`](https://openpharma.github.io/rbmi/)`)`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`` ``#> `` ``#> Attaching package: 'dplyr'`` ``#> The following objects are masked from 'package:stats':`` ``#> `` ``#> filter, lag`` ``#> The following objects are masked from 'package:base':`` ``#> `` ``#> intersect, setdiff, setequal, union`` `` `[`data`](https://rdrr.io/r/utils/data.html)`(``"antidepressant_data"``)`` ``dat`` ``<-`` ``antidepressant_data`

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

` ``# Use expand_locf to add rows corresponding to visits with missing outcomes to the dataset`` ``dat`` ``<-`` `[`expand_locf`](https://openpharma.github.io/rbmi/reference/expand.md)`(`` `` ``dat``,`` `` PATIENT ``=`` `[`levels`](https://rdrr.io/r/base/levels.html)`(``dat``$``PATIENT``)``, ``# expand by PATIENT and VISIT `` `` VISIT ``=`` `[`levels`](https://rdrr.io/r/base/levels.html)`(``dat``$``VISIT``)``,`` `` vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BASVAL"``, ``"THERAPY"``)``, ``# fill with LOCF BASVAL and THERAPY`` `` group ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"PATIENT"``)``,`` `` order ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"PATIENT"``, ``"VISIT"``)`` ``)`

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

`# create data_ice and set the imputation strategy to JR for`` ``# each patient with at least one missing observation`` ``dat_ice`` ``<-`` ``dat`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(``PATIENT``, ``VISIT``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(`[`is.na`](https://rdrr.io/r/base/NA.html)`(``CHANGE``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``PATIENT``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`slice`](https://dplyr.tidyverse.org/reference/slice.html)`(``1``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `[`ungroup`](https://dplyr.tidyverse.org/reference/group_by.html)`(``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``PATIENT``, ``VISIT``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``strategy ``=`` ``"JR"``)`` `` ``# In this dataset, subject 3618 has an intermittent missing values which does not correspond`` ``` # to a study drug discontinuation. We therefore remove this subject from `dat_ice`.  ``` ``# (In the later imputation step, it will automatically be imputed under the default MAR assumption.)`` ``dat_ice`` ``<-`` ``dat_ice``[``-`[`which`](https://rdrr.io/r/base/which.html)`(``dat_ice``$``PATIENT`` ``==`` ``3618``)``,``]`` `` ``dat_ice`` ``#> ``# A tibble: 43 × 3`` ``#> PATIENT VISIT strategy`` ``#> ``<fct>`` ``<fct>`` ``<chr>`` `` ``#> `` 1`` 1513 5 JR `` ``#> `` 2`` 1514 5 JR `` ``#> `` 3`` 1517 5 JR `` ``#> `` 4`` 1804 7 JR `` ``#> `` 5`` 2104 7 JR `` ``#> `` 6`` 2118 5 JR `` ``#> `` 7`` 2218 6 JR `` ``#> `` 8`` 2230 6 JR `` ``#> `` 9`` 2721 5 JR `` ``#> ``10`` 2729 5 JR `` ``#> ``# ℹ 33 more rows`` `` ``# Define the names of key variables in our dataset and`` ``` # the covariates included in the imputation model using `set_vars()` ``` ``# Note that the covariates argument can also include interaction terms`` ``vars`` ``<-`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`` `` outcome ``=`` ``"CHANGE"``,`` `` visit ``=`` ``"VISIT"``,`` `` subjid ``=`` ``"PATIENT"``,`` `` group ``=`` ``"THERAPY"``,`` `` covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BASVAL*VISIT"``, ``"THERAPY*VISIT"``)`` ``)`` `` ``# Define which imputation method to use (here: Bayesian multiple imputation with 150 imputed datsets)`` ``method`` ``<-`` `[`method_bayes`](https://openpharma.github.io/rbmi/reference/method.md)`(`` `` n_samples ``=`` ``150``,`` `` control ``=`` `[`control_bayes`](https://openpharma.github.io/rbmi/reference/control.md)`(`` `` warmup ``=`` ``200``,`` `` thin ``=`` ``5``,`` `` seed ``=`` ``1821`` ``# Seed to be used by Stan`` `` ``)`` ``)`` `` ``# Create samples for the imputation parameters by running the draws() function`` `[`set.seed`](https://rdrr.io/r/base/Random.html)`(``987``)`` ``drawObj`` ``<-`` `[`draws`](https://openpharma.github.io/rbmi/reference/draws.md)`(`` `` data ``=`` ``dat``,`` `` data_ice ``=`` ``dat_ice``,`` `` vars ``=`` ``vars``,`` `` method ``=`` ``method``,`` `` quiet ``=`` ``TRUE`` ``)`` ``#> Trying to compile a simple C file`` ``#> Running /usr/local/lib/R/bin/R CMD SHLIB foo.c`` ``#> using C compiler: ‘gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0’`` ``#> gcc -std=gnu2x -I"/usr/local/lib/R/include" -DNDEBUG -I"/usr/local/lib/R/site-library/Rcpp/include/" -I"/usr/local/lib/R/site-library/RcppEigen/include/" -I"/usr/local/lib/R/site-library/RcppEigen/include/unsupported" -I"/usr/local/lib/R/site-library/BH/include" -I"/usr/local/lib/R/site-library/StanHeaders/include/src/" -I"/usr/local/lib/R/site-library/StanHeaders/include/" -I"/usr/local/lib/R/site-library/RcppParallel/include/" -DRCPP_PARALLEL_USE_TBB=1 -DTBB_INTERFACE_NEW -I/usr/local/lib/R/site-library/RcppParallel/include -I"/usr/local/lib/R/site-library/rstan/include" -DEIGEN_NO_DEBUG -DBOOST_DISABLE_ASSERTS -DBOOST_PENDING_INTEGER_LOG2_HPP -DSTAN_THREADS -DUSE_STANC3 -DSTRICT_R_HEADERS -DBOOST_PHOENIX_NO_VARIADIC_EXPRESSION -D_HAS_AUTO_PTR_ETC=0 -include '/usr/local/lib/R/site-library/StanHeaders/include/stan/math/prim/fun/Eigen.hpp' -D_REENTRANT -DRCPP_PARALLEL_USE_TBB=1 -I/usr/local/include -fpic -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g -c foo.c -o foo.o`` ``#> In file included from <command-line>:`` ``#> /usr/local/lib/R/site-library/StanHeaders/include/stan/math/prim/fun/Eigen.hpp:3:10: fatal error: stdexcept: No such file or directory`` ``#> 3 | #include <stdexcept>`` ``#> | ^~~~~~~~~~~`` ``#> compilation terminated.`` ``#> make: *** [/usr/local/lib/R/etc/Makeconf:190: foo.o] Error 1`` ``drawObj`` ``#> `` ``#> Draws Object`` ``#> ------------`` ``#> Number of Samples: 150`` ``#> Number of Failed Samples: 0`` ``#> Model Formula: CHANGE ~ 1 + THERAPY + VISIT + BASVAL * VISIT + THERAPY * VISIT`` ``#> Imputation Type: random`` ``#> Method:`` ``#> name: Bayes`` ``#> covariance: us`` ``#> same_cov: TRUE`` ``#> n_samples: 150`` ``#> prior_cov: default`` ``#> Controls:`` ``#> warmup: 200`` ``#> thin: 5`` ``#> chains: 1`` ``#> init: mmrm`` ``#> seed: 1821`

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

`imputeObj`` ``<-`` `[`impute`](https://openpharma.github.io/rbmi/reference/impute.md)`(`` `` ``drawObj``,`` `` references ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"DRUG"`` ``=`` ``"PLACEBO"``, ``"PLACEBO"`` ``=`` ``"PLACEBO"``)`` ``)`` ``imputeObj`` ``#> `` ``#> Imputation Object`` ``#> -----------------`` ``#> Number of Imputed Datasets: 150`` ``#> Fraction of Missing Data (Original Dataset):`` ``#> 4: 0%`` ``#> 5: 8%`` ``#> 6: 13%`` ``#> 7: 25%`` ``#> References:`` ``#> DRUG -> PLACEBO`` ``#> PLACEBO -> PLACEBO`

In this instance, we are specifying that the `PLACEBO` group should be
the reference group for itself as well as for the `DRUG` group (as is
standard for imputation using reference-based methods).

Generally speaking, there is no need to see or directly interact with
the imputed datasets. However, if you do wish to inspect them, they can
be extracted from the imputation object using the
[`extract_imputed_dfs()`](https://openpharma.github.io/rbmi/reference/extract_imputed_dfs.md)
helper function, i.e.:

`imputed_dfs`` ``<-`` `[`extract_imputed_dfs`](https://openpharma.github.io/rbmi/reference/extract_imputed_dfs.md)`(``imputeObj``)`` `[`head`](https://rdrr.io/r/utils/head.html)`(``imputed_dfs``[[``10``]``]``, ``12``)`` ``# first 12 rows of 10th imputed dataset`` ``#> PATIENT HAMATOTL PGIIMP RELDAYS VISIT THERAPY GENDER POOLINV BASVAL`` ``#> 1 new_pt_1 21 2 7 4 DRUG F 006 32`` ``#> 2 new_pt_1 19 2 14 5 DRUG F 006 32`` ``#> 3 new_pt_1 21 3 28 6 DRUG F 006 32`` ``#> 4 new_pt_1 17 4 42 7 DRUG F 006 32`` ``#> 5 new_pt_2 18 3 7 4 PLACEBO F 006 14`` ``#> 6 new_pt_2 18 2 15 5 PLACEBO F 006 14`` ``#> 7 new_pt_2 14 3 29 6 PLACEBO F 006 14`` ``#> 8 new_pt_2 8 2 42 7 PLACEBO F 006 14`` ``#> 9 new_pt_3 18 3 7 4 DRUG F 006 21`` ``#> 10 new_pt_3 17 3 14 5 DRUG F 006 21`` ``#> 11 new_pt_3 12 3 28 6 DRUG F 006 21`` ``#> 12 new_pt_3 9 3 44 7 DRUG F 006 21`` ``#> HAMDTL17 CHANGE`` ``#> 1 21 -11`` ``#> 2 20 -12`` ``#> 3 19 -13`` ``#> 4 17 -15`` ``#> 5 11 -3`` ``#> 6 14 0`` ``#> 7 9 -5`` ``#> 8 5 -9`` ``#> 9 20 -1`` ``#> 10 18 -3`` ``#> 11 16 -5`` ``#> 12 13 -8`

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

`anaObj`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(`` `` ``imputeObj``,`` `` ``ancova``,`` `` vars ``=`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`` `` subjid ``=`` ``"PATIENT"``,`` `` outcome ``=`` ``"CHANGE"``,`` `` visit ``=`` ``"VISIT"``,`` `` group ``=`` ``"THERAPY"``,`` `` covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BASVAL"``)`` `` ``)`` ``)`` ``anaObj`` ``#> `` ``#> Analysis Object`` ``#> ---------------`` ``#> Number of Results: 150`` ``#> Analysis Function: ancova`` ``#> Delta Applied: FALSE`` ``#> Analysis Estimates:`` ``#> trt_4`` ``#> lsm_ref_4`` ``#> lsm_alt_4`` ``#> trt_5`` ``#> lsm_ref_5`` ``#> lsm_alt_5`` ``#> trt_6`` ``#> lsm_ref_6`` ``#> lsm_alt_6`` ``#> trt_7`` ``#> lsm_ref_7`` ``#> lsm_alt_7`

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

Note that
[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md)
supports the analysis of two or more treatment arms. For more than two
arms the `ref` / `alt` naming scheme is extended so that `alt2`, `alt3`,
… represent the third, fourth, … factor levels; e.g. the resulting list
will contain entries such as `lsm_alt2_day40` (the least square mean for
the third factor level at the `"day40"` visit) and, for treatment
effects, `trt_alt2_day40` (the third factor level compared to the
reference level at the `"day40"` visit). By default a treatment effect
is estimated for every non-reference group versus the reference group; a
bespoke set of contrasts can be requested via the `group_contrasts`
argument of
[`set_vars()`](https://openpharma.github.io/rbmi/reference/set_vars.md).
Custom contrasts must be named, and the names become the output
parameter names. For example, with three arms `"Placebo"`, `"Low"` and
`"High"`:

`vars`` ``<-`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`` `` outcome ``=`` ``"outcome"``,`` `` group ``=`` ``"group"``,`` `` visit ``=`` ``"visit"``,`` `` covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BASVAL"``)``,`` `` group_contrasts ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` low_vs_pbo ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Low"``, ``"Placebo"``)``,`` `` high_vs_pbo ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"High"``, ``"Placebo"``)``,`` `` high_vs_low ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"High"``, ``"Low"``)`` `` ``)`` ``)`` ``anaObj`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(``imputeObj``, ``ancova``, vars ``=`` ``vars``)`

Contrasts need not be pairwise. A contrast can also be specified as a
named numeric weight vector over the group levels (summing to zero) –
for example to compare the average of the two active arms against
`"Placebo"`. The list name becomes the parameter name and is carried
through to the `contrast_label` column of the
[`pool()`](https://openpharma.github.io/rbmi/reference/pool.md) output:

`vars`` ``<-`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`` `` outcome ``=`` ``"outcome"``,`` `` group ``=`` ``"group"``,`` `` visit ``=`` ``"visit"``,`` `` covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BASVAL"``)``,`` `` group_contrasts ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` pooled_vs_pbo ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``Placebo ``=`` ``-``1``, Low ``=`` ``0.5``, High ``=`` ``0.5``)`` `` ``)`` ``)`` ``anaObj`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(``imputeObj``, ``ancova``, vars ``=`` ``vars``)`

See the documentation for
[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md) and
[`set_vars()`](https://openpharma.github.io/rbmi/reference/set_vars.md)
for more details.

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

`# For reference show the additional meta variables provided`` `[`delta_template`](https://openpharma.github.io/rbmi/reference/delta_template.md)`(``imputeObj``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `[`as_tibble`](https://tibble.tidyverse.org/reference/as_tibble.html)`(``)`` ``#> ``# A tibble: 688 × 8`` ``#> PATIENT VISIT THERAPY is_mar is_missing is_post_ice strategy delta`` ``#> ``<fct>`` ``<fct>`` ``<fct>`` ``<lgl>`` ``<lgl>`` ``<lgl>`` ``<chr>`` ``<dbl>`` ``#> `` 1`` 1503 4 DRUG TRUE FALSE FALSE ``NA`` 0`` ``#> `` 2`` 1503 5 DRUG TRUE FALSE FALSE ``NA`` 0`` ``#> `` 3`` 1503 6 DRUG TRUE FALSE FALSE ``NA`` 0`` ``#> `` 4`` 1503 7 DRUG TRUE FALSE FALSE ``NA`` 0`` ``#> `` 5`` 1507 4 PLACEBO TRUE FALSE FALSE ``NA`` 0`` ``#> `` 6`` 1507 5 PLACEBO TRUE FALSE FALSE ``NA`` 0`` ``#> `` 7`` 1507 6 PLACEBO TRUE FALSE FALSE ``NA`` 0`` ``#> `` 8`` 1507 7 PLACEBO TRUE FALSE FALSE ``NA`` 0`` ``#> `` 9`` 1509 4 DRUG TRUE FALSE FALSE ``NA`` 0`` ``#> ``10`` 1509 5 DRUG TRUE FALSE FALSE ``NA`` 0`` ``#> ``# ℹ 678 more rows`` `` ``delta_df`` ``<-`` `[`delta_template`](https://openpharma.github.io/rbmi/reference/delta_template.md)`(``imputeObj``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `[`as_tibble`](https://tibble.tidyverse.org/reference/as_tibble.html)`(``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``delta ``=`` `[`if_else`](https://dplyr.tidyverse.org/reference/if_else.html)`(``THERAPY`` ``==`` ``"DRUG"`` ``&`` ``is_missing`` , ``5``, ``0``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``PATIENT``, ``VISIT``, ``delta``)`` `` `` ``delta_df`` ``#> ``# A tibble: 688 × 3`` ``#> PATIENT VISIT delta`` ``#> ``<fct>`` ``<fct>`` ``<dbl>`` ``#> `` 1`` 1503 4 0`` ``#> `` 2`` 1503 5 0`` ``#> `` 3`` 1503 6 0`` ``#> `` 4`` 1503 7 0`` ``#> `` 5`` 1507 4 0`` ``#> `` 6`` 1507 5 0`` ``#> `` 7`` 1507 6 0`` ``#> `` 8`` 1507 7 0`` ``#> `` 9`` 1509 4 0`` ``#> ``10`` 1509 5 0`` ``#> ``# ℹ 678 more rows`` `` ``anaObj_delta`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(`` `` ``imputeObj``,`` `` ``ancova``,`` `` delta ``=`` ``delta_df``,`` `` vars ``=`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`` `` subjid ``=`` ``"PATIENT"``,`` `` outcome ``=`` ``"CHANGE"``,`` `` visit ``=`` ``"VISIT"``,`` `` group ``=`` ``"THERAPY"``,`` `` covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BASVAL"``)`` `` ``)`` ``)`

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

`poolObj`` ``<-`` `[`pool`](https://openpharma.github.io/rbmi/reference/pool.md)`(`` `` ``anaObj``, `` `` conf.level ``=`` ``0.95``, `` `` alternative ``=`` ``"two.sided"`` ``)`` ``poolObj`` ``#> `` ``#> Pool Object`` ``#> -----------`` ``#> Number of Results Combined: 150`` ``#> Method: rubin`` ``#> Confidence Level: 0.95`` ``#> Alternative: two.sided`` ``#> `` ``#> Results:`` ``#> `` ``#> ==================================================`` ``#> parameter est se lci uci pval `` ``#> --------------------------------------------------`` ``#> trt_4 -0.092 0.683 -1.439 1.256 0.893 `` ``#> lsm_ref_4 -1.616 0.486 -2.576 -0.656 0.001 `` ``#> lsm_alt_4 -1.708 0.475 -2.645 -0.77 <0.001 `` ``#> trt_5 1.327 0.924 -0.498 3.152 0.153 `` ``#> lsm_ref_5 -4.136 0.66 -5.44 -2.833 <0.001 `` ``#> lsm_alt_5 -2.809 0.648 -4.088 -1.53 <0.001 `` ``#> trt_6 1.941 0.998 -0.03 3.913 0.054 `` ``#> lsm_ref_6 -6.072 0.715 -7.484 -4.661 <0.001 `` ``#> lsm_alt_6 -4.131 0.703 -5.52 -2.743 <0.001 `` ``#> trt_7 2.144 1.113 -0.055 4.343 0.056 `` ``#> lsm_ref_7 -6.957 0.824 -8.587 -5.328 <0.001 `` ``#> lsm_alt_7 -4.813 0.789 -6.372 -3.254 <0.001 `` ``#> --------------------------------------------------`

The table of values shown in the print message for `poolObj` can also be
extracted using the
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) function:

[`as.data.frame`](https://rdrr.io/r/base/as.data.frame.html)`(``poolObj``)`` ``#> parameter est se lci uci pval`` ``#> 1 trt_4 -0.09180645 0.6826279 -1.43949684 1.2558839 8.931772e-01`` ``#> 2 lsm_ref_4 -1.61581996 0.4862316 -2.57577141 -0.6558685 1.093708e-03`` ``#> 3 lsm_alt_4 -1.70762640 0.4749573 -2.64531931 -0.7699335 4.262148e-04`` ``#> 4 trt_5 1.32723764 0.9241937 -0.49800291 3.1524782 1.529321e-01`` ``#> 5 lsm_ref_5 -4.13649538 0.6601196 -5.44026204 -2.8327287 3.344702e-09`` ``#> 6 lsm_alt_5 -2.80925774 0.6475532 -4.08829766 -1.5302178 2.560202e-05`` ``#> 7 trt_6 1.94133157 0.9980466 -0.03027256 3.9129357 5.357780e-02`` ``#> 8 lsm_ref_6 -6.07238291 0.7145539 -7.48408866 -4.6606772 1.632466e-14`` ``#> 9 lsm_alt_6 -4.13105134 0.7027330 -5.51957849 -2.7425242 2.581725e-08`` ``#> 10 trt_7 2.14433243 1.1127032 -0.05460848 4.3432733 5.588916e-02`` ``#> 11 lsm_ref_7 -6.95743202 0.8238679 -8.58689879 -5.3279652 4.417042e-14`` ``#> 12 lsm_alt_7 -4.81309959 0.7885152 -6.37195427 -3.2542449 9.491930e-09`` ``#> estimate_type group group_level_1 group_level_2 contrast_label visit`` ``#> 1 contrast THERAPY PLACEBO DRUG <NA> 4`` ``#> 2 lsm THERAPY DRUG <NA> <NA> 4`` ``#> 3 lsm THERAPY PLACEBO <NA> <NA> 4`` ``#> 4 contrast THERAPY PLACEBO DRUG <NA> 5`` ``#> 5 lsm THERAPY DRUG <NA> <NA> 5`` ``#> 6 lsm THERAPY PLACEBO <NA> <NA> 5`` ``#> 7 contrast THERAPY PLACEBO DRUG <NA> 6`` ``#> 8 lsm THERAPY DRUG <NA> <NA> 6`` ``#> 9 lsm THERAPY PLACEBO <NA> <NA> 6`` ``#> 10 contrast THERAPY PLACEBO DRUG <NA> 7`` ``#> 11 lsm THERAPY DRUG <NA> <NA> 7`` ``#> 12 lsm THERAPY PLACEBO <NA> <NA> 7`

These outputs gives an estimated difference of 2.144 (95% CI -0.055 to
4.343) between the two groups at the last visit with an associated
p-value of 0.056.

## 7 Code

We report below all the code presented in this vignette.

[`library`](https://rdrr.io/r/base/library.html)`(`[`rbmi`](https://openpharma.github.io/rbmi/)`)`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`` `` `[`data`](https://rdrr.io/r/utils/data.html)`(``"antidepressant_data"``)`` ``dat`` ``<-`` ``antidepressant_data`` `` ``# Use expand_locf to add rows corresponding to visits with missing outcomes to the dataset`` ``dat`` ``<-`` `[`expand_locf`](https://openpharma.github.io/rbmi/reference/expand.md)`(`` `` ``dat``,`` `` PATIENT ``=`` `[`levels`](https://rdrr.io/r/base/levels.html)`(``dat``$``PATIENT``)``, ``# expand by PATIENT and VISIT `` `` VISIT ``=`` `[`levels`](https://rdrr.io/r/base/levels.html)`(``dat``$``VISIT``)``,`` `` vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BASVAL"``, ``"THERAPY"``)``, ``# fill with LOCF BASVAL and THERAPY`` `` group ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"PATIENT"``)``,`` `` order ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"PATIENT"``, ``"VISIT"``)`` ``)`` `` ``# Create data_ice and set the imputation strategy to JR for`` ``# each patient with at least one missing observation`` ``dat_ice`` ``<-`` ``dat`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(``PATIENT``, ``VISIT``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(`[`is.na`](https://rdrr.io/r/base/NA.html)`(``CHANGE``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``PATIENT``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`slice`](https://dplyr.tidyverse.org/reference/slice.html)`(``1``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `[`ungroup`](https://dplyr.tidyverse.org/reference/group_by.html)`(``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``PATIENT``, ``VISIT``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``strategy ``=`` ``"JR"``)`` `` ``# In this dataset, subject 3618 has an intermittent missing values which does not correspond`` ``` # to a study drug discontinuation. We therefore remove this subject from `dat_ice`.  ``` ``# (In the later imputation step, it will automatically be imputed under the default MAR assumption.)`` ``dat_ice`` ``<-`` ``dat_ice``[``-`[`which`](https://rdrr.io/r/base/which.html)`(``dat_ice``$``PATIENT`` ``==`` ``3618``)``,``]`` `` ``` # Define the names of key variables in our dataset using `set_vars()` ``` ``# and the covariates included in the imputation model`` ``# Note that the covariates argument can also include interaction terms`` ``vars`` ``<-`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`` `` outcome ``=`` ``"CHANGE"``,`` `` visit ``=`` ``"VISIT"``,`` `` subjid ``=`` ``"PATIENT"``,`` `` group ``=`` ``"THERAPY"``,`` `` covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BASVAL*VISIT"``, ``"THERAPY*VISIT"``)`` ``)`` `` ``# Define which imputation method to use (here: Bayesian multiple imputation with 150 imputed datsets)`` ``method`` ``<-`` `[`method_bayes`](https://openpharma.github.io/rbmi/reference/method.md)`(`` `` n_samples ``=`` ``150``,`` `` control ``=`` `[`control_bayes`](https://openpharma.github.io/rbmi/reference/control.md)`(`` `` warmup ``=`` ``200``,`` `` thin ``=`` ``5``,`` `` seed ``=`` ``1821`` ``# Seed to be used by Stan`` `` ``)`` ``)`` `` ``# Create samples for the imputation parameters by running the draws() function`` `[`set.seed`](https://rdrr.io/r/base/Random.html)`(``987``)`` ``drawObj`` ``<-`` `[`draws`](https://openpharma.github.io/rbmi/reference/draws.md)`(`` `` data ``=`` ``dat``,`` `` data_ice ``=`` ``dat_ice``,`` `` vars ``=`` ``vars``,`` `` method ``=`` ``method``,`` `` quiet ``=`` ``TRUE`` ``)`` `` ``# Impute the data`` ``imputeObj`` ``<-`` `[`impute`](https://openpharma.github.io/rbmi/reference/impute.md)`(`` `` ``drawObj``,`` `` references ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"DRUG"`` ``=`` ``"PLACEBO"``, ``"PLACEBO"`` ``=`` ``"PLACEBO"``)`` ``)`` `` ``# Fit the analysis model on each imputed dataset`` ``anaObj`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(`` `` ``imputeObj``,`` `` ``ancova``,`` `` vars ``=`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`` `` subjid ``=`` ``"PATIENT"``,`` `` outcome ``=`` ``"CHANGE"``,`` `` visit ``=`` ``"VISIT"``,`` `` group ``=`` ``"THERAPY"``,`` `` covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BASVAL"``)`` `` ``)`` ``)`` `` ``# Apply a delta adjustment`` `` ``# Add a delta-value of 5 to all imputed values (i.e. those values`` ``# which were missing in the original dataset) in the drug arm.`` ``delta_df`` ``<-`` `[`delta_template`](https://openpharma.github.io/rbmi/reference/delta_template.md)`(``imputeObj``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `[`as_tibble`](https://tibble.tidyverse.org/reference/as_tibble.html)`(``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``delta ``=`` `[`if_else`](https://dplyr.tidyverse.org/reference/if_else.html)`(``THERAPY`` ``==`` ``"DRUG"`` ``&`` ``is_missing`` , ``5``, ``0``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `` `` `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``PATIENT``, ``VISIT``, ``delta``)`` `` ``# Repeat the analyses with the adjusted values`` ``anaObj_delta`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(`` `` ``imputeObj``,`` `` ``ancova``,`` `` delta ``=`` ``delta_df``,`` `` vars ``=`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`` `` subjid ``=`` ``"PATIENT"``,`` `` outcome ``=`` ``"CHANGE"``,`` `` visit ``=`` ``"VISIT"``,`` `` group ``=`` ``"THERAPY"``,`` `` covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BASVAL"``)`` `` ``)`` ``)`` `` ``# Pool the results`` ``poolObj`` ``<-`` `[`pool`](https://openpharma.github.io/rbmi/reference/pool.md)`(`` `` ``anaObj``,`` `` conf.level ``=`` ``0.95``,`` `` alternative ``=`` ``"two.sided"`` ``)`
