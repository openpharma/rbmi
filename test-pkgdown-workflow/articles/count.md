# rbmi: Modeling count data

Now we’ll walk through how count data can be modeled using the `rbmi`
package. The following sections will cover the necessary steps to
prepare your data, draw parameter samples, impute missing values, and
pool estimates across multiple imputations. For the statistical method
details please see the [separate
vignette](https://openpharma.github.io/rbmi/articles/stat_specs_counts.md).
The runtimes reported below are elapsed times measured when this
vignette is built and will vary with the computing environment.

## 1 The Data

We use the simulated example data set generated with the
`NM_Simdata2.sas` macro by James Roger previously available from the
[LSHTM
website](https://www.lshtm.ac.uk/research/centres-projects-groups/missing-data)
(they host content for DIA SWG on Estimands and Missing Data). The data
contain three treatment arms and up to three rows per patient,
corresponding to the on-treatment, off-treatment but observed, and
post-withdrawal periods.

The simulation was informed by characteristics of the METREO study of
mepolizumab in eosinophilic chronic obstructive pulmonary disease, but
these are not trial data and the simulated treatment effects should not
be interpreted as METREO results. Patients either complete follow-up on
treatment, discontinue treatment and remain observed until the end of
follow-up, discontinue treatment and remain observed for a time before
withdrawing, or discontinue treatment and withdraw immediately. Period 1
represents time on treatment, period 2 observed time off treatment, and
period 3 unobserved time after withdrawal. Counts were also simulated
for period 3 and retained as the complete-data truth for evaluating the
analysis, although they are set to missing in the observed outcome.

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`rbmi`](https://openpharma.github.io/rbmi/)`)`\
\
`dat_count_raw`` ``<-`` `[`read.csv`](https://rdrr.io/r/utils/read.table.html)`(`\
`    `[`system.file`](https://rdrr.io/r/base/system.file.html)`(``"extdata"``, ``"sim_rogeretal.csv"``, package ``=`` ``"rbmi"``)`\
`)`\
`dat_count`` ``<-`` ``dat_count_raw`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`select`](https://dplyr.tidyverse.org/reference/select.html)`(`\
`        ``patient``,`\
`        ``period``,`\
`        ``TreatLab``,`\
`        ``OnOff``,`\
`        ``Length``,`\
`        ``BaseCount``,`\
`        ``Observed_Count`\
`    ``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `\
`    `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`        patient ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``patient``)``,`\
`        period ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``period``, levels ``=`` ``1``:``3``)``,`\
`        TreatLab ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``TreatLab``, levels ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Placebo"``, ``"100mg"``, ``"300mg"``)``)``,`\
`        OnOff ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``OnOff``, levels ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"On"``, ``"Off"``)``)`\
`    ``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `\
`    `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(``patient``, ``period``)`\
[`head`](https://rdrr.io/r/utils/head.html)`(``dat_count``)`\
`#>   patient period TreatLab OnOff Length BaseCount Observed_Count`\
`#> 1       1      1  Placebo    On    367         1              2`\
`#> 2       2      1  Placebo    On    360         4              1`\
`#> 3       3      1  Placebo    On    372         5              2`\
`#> 4       4      1  Placebo    On    358         7              3`\
`#> 5       5      1  Placebo    On    370         3              1`\
`#> 6       6      1  Placebo    On    370         3              2`

The variables retained for this example are:

- `patient`: patient identifier.
- `period`: follow-up period (1 = on treatment, 2 = off treatment but
  observed, and 3 = off treatment and unobserved).
- `TreatLab`: randomized treatment group (`Placebo`, `100mg`, or
  `300mg`).
- `OnOff`: indicator of whether the patient was on or off treatment
  during the period.
- `Length`: time spent in the period, in days.
- `BaseCount`: number of events experienced during the year before the
  study, used as a baseline covariate.
- `Observed_Count`: observed number of events during the period; this is
  missing for period 3 because that period occurs after withdrawal.

The source data omit periods with zero length. We use
[`expand_locf()`](https://openpharma.github.io/rbmi/reference/expand.md)
to add these rows so that every patient has all three periods. The
treatment arm and baseline count are carried forward, while `OnOff` is
derived from the period. Added rows have zero length and a missing
observed count.

The period column supplied to
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md) must
be a factor with no unused levels. Set the levels in the order in which
periods should be processed. `rbmi` keeps the factor’s ordered status
and any custom contrasts. To model a continuous trend, include a
separate numeric period column as a covariate.

\
`dat_count_filled`` ``<-`` ``dat_count`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`expand_locf`](https://openpharma.github.io/rbmi/reference/expand.md)`(`\
`        patient ``=`` `[`levels`](https://rdrr.io/r/base/levels.html)`(``dat_count``$``patient``)``,`\
`        period ``=`` `[`levels`](https://rdrr.io/r/base/levels.html)`(``dat_count``$``period``)``,`\
`        vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"TreatLab"``, ``"BaseCount"``)``,`\
`        group ``=`` ``"patient"``,`\
`        order ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"patient"``, ``"period"``)`\
`    ``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `\
`    `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`        OnOff ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(`\
`            `[`ifelse`](https://rdrr.io/r/base/ifelse.html)`(``period`` ``==`` ``"1"``, ``"On"``, ``"Off"``)``,`\
`            levels ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"On"``, ``"Off"``)`\
`        ``)``,`\
`        Length ``=`` `[`ifelse`](https://rdrr.io/r/base/ifelse.html)`(`[`is.na`](https://rdrr.io/r/base/NA.html)`(``Length``)``, ``0``, ``Length``)`\
`    ``)`

SAS reference results for the models illustrated below were computed
with the SAS macros `NM_Reg22.sas` and `NM_Rand13.sas` by James H. Roger
(2021). Note that these can be downloaded as part of the archive
`NegMult20210313`
[here](https://lshtm.sharepoint.com/:u:/s/MissingDataPublicFiles/EVXl7TLAirxPvKQsdKoU25YBiG3enVCAOZm_8TOBq0DYAA?e=abaKGl)
available under “Imputation of Recurrent event data for partial observed
off-treatment data” on the [DIA Missing Data
website](https://www.lshtm.ac.uk/research/centres-projects-groups/missing-data#dia-missing-data).
The results are included as a CSV file with the package. We retain the
two active-treatment versus placebo contrasts, so they can be compared
directly with the pooled `rbmi` estimates. The assertions below stop
vignette precompilation if any relative difference from SAS exceeds
`0.005` for rate ratios and confidence limits, or `0.10` for p-values.
These tolerances allow for Monte Carlo variation between the two
implementations and across computing environments. Comparisons use
unrounded results and match contrasts by name. When a comparison fails,
inspect the Stan diagnostics before increasing the number of
imputations: additional draws from a chain that has not converged do not
resolve the discrepancy.

\
`sas_results`` ``<-`` `[`read.csv`](https://rdrr.io/r/utils/read.table.html)`(`\
`    `[`system.file`](https://rdrr.io/r/base/system.file.html)`(``"extdata"``, ``"results.csv"``, package ``=`` ``"rbmi"``)``,`\
`    check.names ``=`` ``FALSE`\
`)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(`\
`        ``(``TreatLab`` ``==`` ``"100mg"`` ``&`` ``` `_TreatLab` ``` ``==`` ``"Placebo"``)`` ``|`\
`            ``(``TreatLab`` ``==`` ``"300mg"`` ``&`` ``` `_TreatLab` ``` ``==`` ``"Placebo"``)`\
`    ``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`transmute`](https://dplyr.tidyverse.org/reference/transmute.html)`(`\
`        model ``=`` ``Label``,`\
`        comparison ``=`` `[`paste`](https://rdrr.io/r/base/paste.html)`(``TreatLab``, ``"vs"``, ``` `_TreatLab` ```)``,`\
`        sas_rate_ratio ``=`` ``EXP_Est``,`\
`        sas_lower_95 ``=`` ``Low_95PCT``,`\
`        sas_upper_95 ``=`` ``Upp_95PCT``,`\
`        sas_p_value ``=`` ``Pvalue`\
`    ``)`\
\
`check_rate_ratio_results`` ``<-`` ``function``(``x``, ``sas_model``)`` ``{`\
`    ``expected_comparisons`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(`\
`        ``"100mg vs Placebo"``,`\
`        ``"300mg vs Placebo"`\
`    ``)`\
`    ``sas_subset`` ``<-`` ``dplyr``::`[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``sas_results``, ``model`` ``==`` ``sas_model``)`\
`    `[`stopifnot`](https://rdrr.io/r/base/stopifnot.html)`(`\
`        `[`setequal`](https://generics.r-lib.org/reference/setops.html)`(``x``$``comparison``, ``expected_comparisons``)``,`\
`        `[`nrow`](https://rdrr.io/r/base/nrow.html)`(``x``)`` ``==`` ``2``,`\
`        `[`all`](https://rdrr.io/r/base/all.html)`(`[`is.finite`](https://rdrr.io/r/base/is.finite.html)`(`[`as.matrix`](https://rdrr.io/r/base/matrix.html)`(``x``[``, `[`setdiff`](https://generics.r-lib.org/reference/setops.html)`(`[`names`](https://rdrr.io/r/base/names.html)`(``x``)``, ``"comparison"``)``]``)``)``)``,`\
`        `[`all`](https://rdrr.io/r/base/all.html)`(``x``[[``2``]``]`` ``>`` ``0``)``,`\
`        `[`all`](https://rdrr.io/r/base/all.html)`(``x``[[``3``]``]`` ``<`` ``x``[[``2``]``]``)``,`\
`        `[`all`](https://rdrr.io/r/base/all.html)`(``x``[[``2``]``]`` ``<`` ``x``[[``4``]``]``)``,`\
`        `[`all`](https://rdrr.io/r/base/all.html)`(``x``[[``5``]``]`` ``>=`` ``0`` ``&`` ``x``[[``5``]``]`` ``<=`` ``1``)``,`\
`        `[`setequal`](https://generics.r-lib.org/reference/setops.html)`(``sas_subset``$``comparison``, ``expected_comparisons``)``,`\
`        `[`nrow`](https://rdrr.io/r/base/nrow.html)`(``sas_subset``)`` ``==`` ``2``,`\
`        `[`all`](https://rdrr.io/r/base/all.html)`(`[`is.finite`](https://rdrr.io/r/base/is.finite.html)`(`[`as.matrix`](https://rdrr.io/r/base/matrix.html)`(`\
`            ``sas_subset``[``, `[`setdiff`](https://generics.r-lib.org/reference/setops.html)`(`[`names`](https://rdrr.io/r/base/names.html)`(``sas_subset``)``, `[`c`](https://rdrr.io/r/base/c.html)`(``"model"``, ``"comparison"``)``)``]`\
`        ``)``)``)`\
`    ``)`\
`    ``# Match contrasts explicitly because SAS and rbmi may order them differently.`\
`    ``sas_subset`` ``<-`` ``sas_subset``[`[`match`](https://rdrr.io/r/base/match.html)`(``x``$``comparison``, ``sas_subset``$``comparison``)``, ``]`\
`    ``statistics`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``"rate_ratio"``, ``"lower_95"``, ``"upper_95"``, ``"p_value"``)`\
`    ``relative_tolerance`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.005``, ``0.005``, ``0.005``, ``0.10``)`\
`    ``for`` ``(``i`` ``in`` `[`seq_along`](https://rdrr.io/r/base/seq.html)`(``statistics``)``)`` ``{`\
`        ``actual`` ``<-`` ``x``[[``i`` ``+`` ``1``]``]`\
`        ``expected`` ``<-`` ``sas_subset``[[`[`paste0`](https://rdrr.io/r/base/paste.html)`(``"sas_"``, ``statistics``[``i``]``)``]``]`\
`        ``difference`` ``<-`` `[`abs`](https://rdrr.io/r/base/MathFun.html)`(``actual`` ``-`` ``expected``)`\
`        ``failed`` ``<-`` `[`which`](https://rdrr.io/r/base/which.html)`(``difference`` ``>`` ``relative_tolerance``[``i``]`` ``*`` `[`abs`](https://rdrr.io/r/base/MathFun.html)`(``expected``)``)`\
`        ``if`` ``(`[`length`](https://rdrr.io/r/base/length.html)`(``failed``)``)`` ``{`\
`            `[`stop`](https://rdrr.io/r/base/stop.html)`(`\
`                `[`sprintf`](https://rdrr.io/r/base/sprintf.html)`(`\
`                    `[`paste0`](https://rdrr.io/r/base/paste.html)`(`\
`                        ``"SAS comparison failed for %s (%s), %s: "``,`\
`                        ``"rbmi = %.8g, SAS = %.8g, relative tolerance = %g"`\
`                    ``)``,`\
`                    ``sas_model``,`\
`                    ``x``$``comparison``[``failed``[``1``]``]``,`\
`                    ``statistics``[``i``]``,`\
`                    ``actual``[``failed``[``1``]``]``,`\
`                    ``expected``[``failed``[``1``]``]``,`\
`                    ``relative_tolerance``[``i``]`\
`                ``)``,`\
`                call. ``=`` ``FALSE`\
`            ``)`\
`        ``}`\
`    ``}`\
`    `[`invisible`](https://rdrr.io/r/base/invisible.html)`(``x``)`\
`}`

## 2 Draws

The inputs to the
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md)
function are now:

- `data`: The data frame as prepared above.
- `data_ice`: Subject-specific imputation strategies for missing count
  periods
- `vars`: The variables to be used in the model
- `method`: Here we can only use
  [`method_bayes()`](https://openpharma.github.io/rbmi/reference/method.md)
  for fully Bayesian multiple imputation for our count data
- `outcome` (new): The outcome type, which defaults to “continuous”, but
  here we will choose “count”

For count outcomes, `data_ice` contains only the subject ID and strategy
columns; it has no period or visit column. It does not record an
intercurrent-event (ICE) time, and no ICE time is inferred from
`duration`. The strategy assigned to a subject applies to every missing
positive-duration period for that subject. Consequently, `JR` and `CR`
are reference-based assumptions for all of that subject’s missing
periods, rather than post-ICE-only assumptions. Use `MAR` for subjects
whose missing periods should retain their randomized-arm trajectory.

### 2.1 Imputation strategies

Here we just use the same imputation strategy for all patients, but we
would also be able to provide different strategies for each patient.

Let’s use the Missing At Random (MAR) strategy for all patients with
positive post-withdrawal exposure in period 3. This matches the first
model in the “Another case with three periods” analysis, where the
period-3 design matrix retains each patient’s randomized treatment arm:

\
`dat_ice`` ``<-`` ``dat_count_filled`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `\
`    `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``period`` ``==`` ``"3"``, ``Length`` ``>`` ``0``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``patient``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`distinct`](https://dplyr.tidyverse.org/reference/distinct.html)`(``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `\
`    `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`        strategy ``=`` ``"MAR"`\
`    ``)`

### 2.2 Variables

Next we define the variables to be used in the model.

\
`vars`` ``<-`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`\
`    outcome ``=`` ``"Observed_Count"``,`\
`    subjid ``=`` ``"patient"``,`\
`    period ``=`` ``"period"``,`\
`    duration ``=`` ``"Length"``,`\
`    group ``=`` ``"TreatLab"``,`\
`    covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"TreatLab * OnOff"``, ``"BaseCount"``)`\
`)`

Note that here we can also specify interaction terms in the `covariates`
argument, which will then be included in the draws step model.

### 2.3 Method

We just use the standard Bayesian method options:

\
`method`` ``<-`` `[`method_bayes`](https://openpharma.github.io/rbmi/reference/method.md)`(`\
`    n_samples ``=`` ``1000``,`\
`    control ``=`` `[`control_bayes`](https://openpharma.github.io/rbmi/reference/control.md)`(`\
`        warmup ``=`` ``200``,`\
`        thin ``=`` ``5``,`\
`        seed ``=`` ``1821`` ``# Seed to be used by Stan`\
`    ``)`\
`)`

### 2.4 Sampling

Finally we can call the
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md)
function to draw samples from the posterior distribution of the model
parameters:

\
[`set.seed`](https://rdrr.io/r/base/Random.html)`(``987``)`\
`drawObj`` ``<-`` `[`draws`](https://openpharma.github.io/rbmi/reference/draws.md)`(`\
`    outcome ``=`` ``"count"``,`\
`    data ``=`` ``dat_count_filled``,`\
`    data_ice ``=`` ``dat_ice``,`\
`    vars ``=`` ``vars``,`\
`    method ``=`` ``method``,`\
`    quiet ``=`` ``TRUE`\
`)`\
`#> Trying to compile a simple C file`\
`#> Running /usr/local/lib/R/bin/R CMD SHLIB foo.c`\
`#> using C compiler: ‘gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0’`\
`#> gcc -std=gnu2x -I"/usr/local/lib/R/include" -DNDEBUG   -I"/usr/local/lib/R/site-library/Rcpp/include/"  -I"/usr/local/lib/R/site-library/RcppEigen/include/"  -I"/usr/local/lib/R/site-library/RcppEigen/include/unsupported"  -I"/usr/local/lib/R/site-library/BH/include" -I"/usr/local/lib/R/site-library/StanHeaders/include/src/"  -I"/usr/local/lib/R/site-library/StanHeaders/include/"  -I"/usr/local/lib/R/site-library/RcppParallel/include/" -DRCPP_PARALLEL_USE_TBB=1 -DTBB_INTERFACE_NEW -I/usr/local/lib/R/site-library/RcppParallel/include -I"/usr/local/lib/R/site-library/rstan/include" -DEIGEN_NO_DEBUG  -DBOOST_DISABLE_ASSERTS  -DBOOST_PENDING_INTEGER_LOG2_HPP  -DSTAN_THREADS  -DUSE_STANC3 -DSTRICT_R_HEADERS  -DBOOST_PHOENIX_NO_VARIADIC_EXPRESSION  -D_HAS_AUTO_PTR_ETC=0  -include '/usr/local/lib/R/site-library/StanHeaders/include/stan/math/prim/fun/Eigen.hpp'  -D_REENTRANT -DRCPP_PARALLEL_USE_TBB=1   -I/usr/local/include    -fpic  -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c foo.c -o foo.o`\
`#> In file included from <command-line>:`\
`#> /usr/local/lib/R/site-library/StanHeaders/include/stan/math/prim/fun/Eigen.hpp:3:10: fatal error: stdexcept: No such file or directory`\
`#>     3 | #include <stdexcept>`\
`#>       |          ^~~~~~~~~~~`\
`#> compilation terminated.`\
`#> make: *** [/usr/local/lib/R/etc/Makeconf:190: foo.o] Error 1`

\
`drawObj`\
`#> `\
`#> Draws Object`\
`#> ------------`\
`#> Number of Samples: 1000`\
`#> Number of Failed Samples: 0`\
`#> Model Formula: Observed_Count ~ 1 + TreatLab + TreatLab * OnOff + BaseCount + offset(log(Length))`\
`#> Endpoint Type: count`\
`#> Imputation Type: random`\
`#> Method:`\
`#>     name: Bayes`\
`#>     same_cov: TRUE`\
`#>     n_samples: 1000`\
`#> Controls:`\
`#>     warmup: 200`\
`#>     thin: 5`\
`#>     chains: 1`\
`#>     init: random (auto)`\
`#>     seed: 1821`

## 3 Impute

Now we basically just run the imputation:

\
`imputeObj`` ``<-`` `[`impute`](https://openpharma.github.io/rbmi/reference/impute.md)`(``drawObj``)`

\
`imputeObj`\
`#> `\
`#> Imputation Object`\
`#> -----------------`\
`#> Number of Imputed Datasets: 1000`\
`#> Endpoint Type: count`\
`#> Number of Patients with Positive Duration by Period:`\
`#>     1: 674`\
`#>     2: 58`\
`#>     3: 83`\
`#> References:`\
`#>     Placebo -> Placebo`\
`#>     100mg   -> 100mg`\
`#>     300mg   -> 300mg`

## 4 Analyse

Then the next step is the analysis of the imputed data. We can use a
similar negative binomial regression model as above, however here we
don’t have anymore the `OnOff` variable, because we have imputed the
post-withdrawal periods. So we just use baseline count as additional
covariate, next to the treatment group. The imputed values replace the
missing values in the original outcome column. We therefore keep
`Observed_Count` as the outcome name. The analysis function sums this
outcome and `Length` over periods for each patient before fitting the
model; it does not require a separate `Imputed_Count` column.

\
`ana_vars`` ``<-`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`\
`    outcome ``=`` ``"Observed_Count"``,`\
`    subjid ``=`` ``"patient"``,`\
`    period ``=`` ``"period"``,`\
`    duration ``=`` ``"Length"``,`\
`    group ``=`` ``"TreatLab"``,`\
`    covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"BaseCount"``)`\
`)`

\
`anaObj`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(`\
`    ``imputeObj``,`\
`    ``neg_bin_regression``,`\
`    vars ``=`` ``ana_vars`\
`)`

Additive delta adjustments to completed counts are not supported. For
count sensitivity analyses, use rate multipliers in
[`count_strategy()`](https://openpharma.github.io/rbmi/reference/count_strategy.md)
when specifying the imputation strategies.

## 5 Pool

Finally we can pool all regression coefficients across the multiple
imputations. Pooling is performed on the log-rate scale using Rubin’s
rules, with confidence intervals and p-values based on a t distribution
with the pooled degrees of freedom.

\
`poolObj`` ``<-`` `[`pool`](https://openpharma.github.io/rbmi/reference/pool.md)`(`\
`    ``anaObj``,`\
`    conf.level ``=`` ``0.95``,`\
`    alternative ``=`` ``"two.sided"`\
`)`

\
`poolObj`\
`#> `\
`#> Pool Object`\
`#> -----------`\
`#> Number of Results Combined: 1000`\
`#> Method: rubin`\
`#> Rubin df method: barnard-rubin`\
`#> Confidence Level: 0.95`\
`#> Alternative: two.sided`\
`#> `\
`` #> Results (transformed to the rate scale; original-scale results are in `$pars`): ``\
`#> `\
`#>   ===================================================`\
`#>      parameter     est    se     lci    uci    pval  `\
`#>   ---------------------------------------------------`\
`#>     (Intercept)   0.003    0    0.002  0.003  <0.001 `\
`#>    TreatLab100mg  0.765  0.086  0.614  0.953  0.017  `\
`#>    TreatLab300mg  0.837  0.09   0.678  1.033  0.098  `\
`#>      BaseCount    1.214  0.024  1.168  1.261  <0.001 `\
`#>   ---------------------------------------------------`

The displayed results have been exponentiated to obtain rate ratios. The
original log-rate-scale results remain available in `poolObj$pars`, and
can be shown with the `print` option `scale = "original"`:

\
[`print`](https://rdrr.io/r/base/print.html)`(``poolObj``, scale ``=`` ``"original"``)`\
`#> `\
`#> Pool Object`\
`#> -----------`\
`#> Number of Results Combined: 1000`\
`#> Method: rubin`\
`#> Rubin df method: barnard-rubin`\
`#> Confidence Level: 0.95`\
`#> Alternative: two.sided`\
`#> `\
`#> Results:`\
`#> `\
`#>   ======================================================`\
`#>      parameter     est     se     lci     uci     pval  `\
`#>   ------------------------------------------------------`\
`#>     (Intercept)   -5.981  0.093  -6.163  -5.799  <0.001 `\
`#>    TreatLab100mg  -0.268  0.112  -0.487  -0.048  0.017  `\
`#>    TreatLab300mg  -0.178  0.107  -0.388  0.033   0.098  `\
`#>      BaseCount    0.194   0.019  0.156   0.232   <0.001 `\
`#>   ------------------------------------------------------`

We can also look at the Monte Carlo standard errors for the results:

\
[`mcse`](https://openpharma.github.io/rbmi/reference/pool.md)`(``poolObj``, ``anaObj``)`\
`#> `\
`#> Monte Carlo Standard Errors for Pooled Estimates (mcse Object)`\
`#> -----------`\
`#> Number of Results Combined: 1000`\
`#> `\
`` #> Results (transformed to the rate scale; original-scale results are in `$pars`): ``\
`#> `\
`#>   ====================================================`\
`#>      parameter     est   se   lci    uci      pval    `\
`#>   ----------------------------------------------------`\
`#>     (Intercept)     0    0     0      0    < 0.000001 `\
`#>    TreatLab100mg  0.001  0   0.001  0.001   0.00053   `\
`#>    TreatLab300mg  0.001  0   0.001  0.001   0.00202   `\
`#>      BaseCount      0    0     0      0    < 0.000001 `\
`#>   ----------------------------------------------------`

## 6 Comparison with SAS results

The corresponding SAS results are labelled
`NM_Reg: Treat*OnOff BaseCount`.

\
`rate_ratios_shared`` ``<-`` `[`as.data.frame`](https://rdrr.io/r/base/as.data.frame.html)`(``poolObj``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``parameter`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"TreatLab100mg"``, ``"TreatLab300mg"``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`transmute`](https://dplyr.tidyverse.org/reference/transmute.html)`(`\
`        comparison ``=`` ``dplyr``::`[`recode`](https://dplyr.tidyverse.org/reference/recode.html)`(`\
`            ``parameter``,`\
`            TreatLab100mg ``=`` ``"100mg vs Placebo"``,`\
`            TreatLab300mg ``=`` ``"300mg vs Placebo"`\
`        ``)``,`\
`        rbmi_rate_ratio ``=`` ``est``,`\
`        rbmi_lower_95 ``=`` ``lci``,`\
`        rbmi_upper_95 ``=`` ``uci``,`\
`        rbmi_p_value ``=`` ``pval`\
`    ``)`\
`check_rate_ratio_results``(`\
`    ``rate_ratios_shared``,`\
`    ``"NM_Reg: Treat*OnOff BaseCount"`\
`)`\
\
`dplyr``::`[`left_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html)`(`\
`    ``rate_ratios_shared``,`\
`    ``dplyr``::`[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``sas_results``, ``model`` ``==`` ``"NM_Reg: Treat*OnOff BaseCount"``)``,`\
`    by ``=`` ``"comparison"`\
`)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``-``model``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `\
`    ``dplyr``::`[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``dplyr``::`[`across`](https://dplyr.tidyverse.org/reference/across.html)`(``dplyr``::`[`where`](https://tidyselect.r-lib.org/reference/where.html)`(``is.numeric``)``, ``~`` `[`round`](https://rdrr.io/r/base/Round.html)`(``.x``, ``4``)``)``)`\
`#>         comparison rbmi_rate_ratio rbmi_lower_95 rbmi_upper_95 rbmi_p_value`\
`#> 1 100mg vs Placebo          0.7651        0.6142        0.9531       0.0169`\
`#> 2 300mg vs Placebo          0.8373        0.6785        1.0334       0.0981`\
`#>   sas_rate_ratio sas_lower_95 sas_upper_95 sas_p_value`\
`#> 1         0.7663       0.6150       0.9548      0.0177`\
`#> 2         0.8382       0.6792       1.0344      0.1000`

Runtime: draw 78.08 seconds, impute 23.13 seconds, analyse 84.29
seconds, and pool 0.13 seconds.

## 7 Additional modeling options

### 7.1 Separate draw model sampling for each treatment group

The default count model uses one dispersion/frailty parameter across all
treatment groups. To estimate a separate parameter for each group, set
`same_cov = FALSE` in
[`method_bayes()`](https://openpharma.github.io/rbmi/reference/method.md).
The name is retained for consistency with continuous-outcome models; for
count outcomes it controls whether `phi` is shared between groups.

To make the complete imputation model separate by treatment arm, all
fixed effects must also be interacted with treatment. For the example
data this is:

\
`vars_by_arm`` ``<-`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`\
`    outcome ``=`` ``"Observed_Count"``,`\
`    subjid ``=`` ``"patient"``,`\
`    period ``=`` ``"period"``,`\
`    duration ``=`` ``"Length"``,`\
`    group ``=`` ``"TreatLab"``,`\
`    covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`\
`        ``"TreatLab:OnOff"``,`\
`        ``"TreatLab:BaseCount"`\
`    ``)`\
`)`\
\
`method_by_arm`` ``<-`` `[`method_bayes`](https://openpharma.github.io/rbmi/reference/method.md)`(`\
`    same_cov ``=`` ``FALSE``,`\
`    n_samples ``=`` ``1000``,`\
`    control ``=`` `[`control_bayes`](https://openpharma.github.io/rbmi/reference/control.md)`(`\
`        warmup ``=`` ``200``,`\
`        thin ``=`` ``5``,`\
`        seed ``=`` ``1821`\
`    ``)`\
`)`

\
[`set.seed`](https://rdrr.io/r/base/Random.html)`(``987``)`\
`drawObj_by_arm`` ``<-`` `[`draws`](https://openpharma.github.io/rbmi/reference/draws.md)`(`\
`    outcome ``=`` ``"count"``,`\
`    data ``=`` ``dat_count_filled``,`\
`    data_ice ``=`` ``dat_ice``,`\
`    vars ``=`` ``vars_by_arm``,`\
`    method ``=`` ``method_by_arm``,`\
`    quiet ``=`` ``TRUE`\
`)`\
`#> recompiling to avoid crashing R session`\
`#> Trying to compile a simple C file`\
`#> Running /usr/local/lib/R/bin/R CMD SHLIB foo.c`\
`#> using C compiler: ‘gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0’`\
`#> gcc -std=gnu2x -I"/usr/local/lib/R/include" -DNDEBUG   -I"/usr/local/lib/R/site-library/Rcpp/include/"  -I"/usr/local/lib/R/site-library/RcppEigen/include/"  -I"/usr/local/lib/R/site-library/RcppEigen/include/unsupported"  -I"/usr/local/lib/R/site-library/BH/include" -I"/usr/local/lib/R/site-library/StanHeaders/include/src/"  -I"/usr/local/lib/R/site-library/StanHeaders/include/"  -I"/usr/local/lib/R/site-library/RcppParallel/include/" -DRCPP_PARALLEL_USE_TBB=1 -DTBB_INTERFACE_NEW -I/usr/local/lib/R/site-library/RcppParallel/include -I"/usr/local/lib/R/site-library/rstan/include" -DEIGEN_NO_DEBUG  -DBOOST_DISABLE_ASSERTS  -DBOOST_PENDING_INTEGER_LOG2_HPP  -DSTAN_THREADS  -DUSE_STANC3 -DSTRICT_R_HEADERS  -DBOOST_PHOENIX_NO_VARIADIC_EXPRESSION  -D_HAS_AUTO_PTR_ETC=0  -include '/usr/local/lib/R/site-library/StanHeaders/include/stan/math/prim/fun/Eigen.hpp'  -D_REENTRANT -DRCPP_PARALLEL_USE_TBB=1   -I/usr/local/include    -fpic  -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c foo.c -o foo.o`\
`#> In file included from <command-line>:`\
`#> /usr/local/lib/R/site-library/StanHeaders/include/stan/math/prim/fun/Eigen.hpp:3:10: fatal error: stdexcept: No such file or directory`\
`#>     3 | #include <stdexcept>`\
`#>       |          ^~~~~~~~~~~`\
`#> compilation terminated.`\
`#> make: *** [/usr/local/lib/R/etc/Makeconf:190: foo.o] Error 1`

This is fitted in one Stan call, but with treatment-specific fixed
effects and independent treatment-specific `phi` parameters the
posterior factorizes by arm. It therefore represents the same
statistical model as fitting each arm separately, while retaining a
single rbmi draws object and the usual downstream workflow.

For MAR imputation, each subject uses the `phi` for their randomized
treatment arm. For JR and CR, the mapped reference arm’s `phi` is used
for the whole subject-level conditional distribution. In particular, JR
still calculates the observed-cell means from the subject’s
randomized-arm design, but uses the reference-arm `phi` when
conditioning on those observed cells and when drawing the missing cells.
JR therefore combines the randomized-arm observed mean trajectory with
the reference arm’s frailty distribution; it is not only a design-matrix
substitution for missing periods. This distinction disappears with the
default shared `phi`.

#### 7.1.1 Impute

The downstream workflow is unchanged. Setting the seed immediately
before
[`impute()`](https://openpharma.github.io/rbmi/reference/impute.md)
makes the conditional negative-binomial draws reproducible.

\
[`set.seed`](https://rdrr.io/r/base/Random.html)`(``123``)`\
`imputeObj_by_arm`` ``<-`` `[`impute`](https://openpharma.github.io/rbmi/reference/impute.md)`(``drawObj_by_arm``)`

#### 7.1.2 Analyse and pool

The treatment-policy analysis still combines all randomized treatment
arms and uses the same analysis model as above. Only the imputation
model has changed.

\
`anaObj_by_arm`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(`\
`    ``imputeObj_by_arm``,`\
`    ``neg_bin_regression``,`\
`    vars ``=`` ``ana_vars`\
`)`

\
`poolObj_by_arm`` ``<-`` `[`pool`](https://openpharma.github.io/rbmi/reference/pool.md)`(`\
`    ``anaObj_by_arm``,`\
`    conf.level ``=`` ``0.95``,`\
`    alternative ``=`` ``"two.sided"`\
`)`

\
`poolObj_by_arm`\
`#> `\
`#> Pool Object`\
`#> -----------`\
`#> Number of Results Combined: 1000`\
`#> Method: rubin`\
`#> Rubin df method: barnard-rubin`\
`#> Confidence Level: 0.95`\
`#> Alternative: two.sided`\
`#> `\
`` #> Results (transformed to the rate scale; original-scale results are in `$pars`): ``\
`#> `\
`#>   ===================================================`\
`#>      parameter     est    se     lci    uci    pval  `\
`#>   ---------------------------------------------------`\
`#>     (Intercept)   0.003    0    0.002  0.003  <0.001 `\
`#>    TreatLab100mg  0.768  0.085  0.618  0.955  0.018  `\
`#>    TreatLab300mg  0.839  0.089  0.681  1.033  0.099  `\
`#>      BaseCount    1.214  0.023  1.169  1.261  <0.001 `\
`#>   ---------------------------------------------------`

For comparison with implementations that report treatment effects as
rate ratios, extract the transformed pooled results:

\
`rate_ratios_by_arm`` ``<-`` `[`as.data.frame`](https://rdrr.io/r/base/as.data.frame.html)`(``poolObj_by_arm``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``parameter`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"TreatLab100mg"``, ``"TreatLab300mg"``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`transmute`](https://dplyr.tidyverse.org/reference/transmute.html)`(`\
`        comparison ``=`` `[`recode`](https://dplyr.tidyverse.org/reference/recode.html)`(`\
`            ``parameter``,`\
`            TreatLab100mg ``=`` ``"100mg vs Placebo"``,`\
`            TreatLab300mg ``=`` ``"300mg vs Placebo"`\
`        ``)``,`\
`        rate_ratio ``=`` ``est``,`\
`        lower_95 ``=`` ``lci``,`\
`        upper_95 ``=`` ``uci``,`\
`        p_value ``=`` ``pval`\
`    ``)`\
`check_rate_ratio_results``(`\
`    ``rate_ratios_by_arm``,`\
`    ``"NM_Reg: Separate for each Treat."`\
`)`\
`rate_ratios_by_arm`\
`#>         comparison rate_ratio  lower_95  upper_95    p_value`\
`#> 1 100mg vs Placebo  0.7682772 0.6177404 0.9554982 0.01783257`\
`#> 2 300mg vs Placebo  0.8388777 0.6810196 1.0333268 0.09858468`

#### 7.1.3 Comparison with SAS results

The corresponding SAS results are labelled
`NM_Reg: Separate for each Treat.`.

\
`dplyr``::`[`left_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html)`(`\
`    ``rate_ratios_by_arm`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`        ``dplyr``::`[`rename`](https://dplyr.tidyverse.org/reference/rename.html)`(`\
`            rbmi_rate_ratio ``=`` ``rate_ratio``,`\
`            rbmi_lower_95 ``=`` ``lower_95``,`\
`            rbmi_upper_95 ``=`` ``upper_95``,`\
`            rbmi_p_value ``=`` ``p_value`\
`        ``)``,`\
`    ``dplyr``::`[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``sas_results``, ``model`` ``==`` ``"NM_Reg: Separate for each Treat."``)``,`\
`    by ``=`` ``"comparison"`\
`)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``-``model``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `\
`    ``dplyr``::`[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``dplyr``::`[`across`](https://dplyr.tidyverse.org/reference/across.html)`(``dplyr``::`[`where`](https://tidyselect.r-lib.org/reference/where.html)`(``is.numeric``)``, ``~`` `[`round`](https://rdrr.io/r/base/Round.html)`(``.x``, ``4``)``)``)`\
`#>         comparison rbmi_rate_ratio rbmi_lower_95 rbmi_upper_95 rbmi_p_value`\
`#> 1 100mg vs Placebo          0.7683        0.6177        0.9555       0.0178`\
`#> 2 300mg vs Placebo          0.8389        0.6810        1.0333       0.0986`\
`#>   sas_rate_ratio sas_lower_95 sas_upper_95 sas_p_value`\
`#> 1         0.7668       0.6164       0.9539      0.0172`\
`#> 2         0.8362       0.6786       1.0305      0.0933`

Runtime: draw 82.57 seconds, impute 24.12 seconds, analyse 85.32
seconds, and pool 0.14 seconds.

### 7.2 Treatment interaction terms on all model covariates

This model also gives each treatment arm its own on- and off-treatment
rates and baseline-count slope. Unlike the preceding model, all arms are
fitted in one model, so they share a single dispersion/frailty
parameter. This matches the `Separate each Treat. Shared frai` model in
the SAS reference analysis.

#### 7.2.1 Draw and impute

`rbmi` adds an intercept and the `TreatLab` main effect to the requested
interactions, so the model formula is
`~ 1 + TreatLab + TreatLab:OnOff + TreatLab:BaseCount` (printed below).
The interactions with `TreatLab` give each randomized treatment arm a
separate coefficient for every covariate; `same_cov = TRUE` (the
default) retains the shared count-model dispersion parameter.

For this comparison we use four chains and 4,000 imputations to reduce
Monte Carlo variation in the confidence limits relative to the SAS
tolerance.

\
`vars_all_treatment_interactions`` ``<-`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`\
`    outcome ``=`` ``"Observed_Count"``,`\
`    subjid ``=`` ``"patient"``,`\
`    period ``=`` ``"period"``,`\
`    duration ``=`` ``"Length"``,`\
`    group ``=`` ``"TreatLab"``,`\
`    covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`\
`        ``"TreatLab:OnOff"``,`\
`        ``"TreatLab:BaseCount"`\
`    ``)`\
`)`

\
[`set.seed`](https://rdrr.io/r/base/Random.html)`(``987``)`\
`drawObj_all_treatment_interactions`` ``<-`` `[`draws`](https://openpharma.github.io/rbmi/reference/draws.md)`(`\
`    outcome ``=`` ``"count"``,`\
`    data ``=`` ``dat_count_filled``,`\
`    data_ice ``=`` ``dat_ice``,`\
`    vars ``=`` ``vars_all_treatment_interactions``,`\
`    method ``=`` `[`method_bayes`](https://openpharma.github.io/rbmi/reference/method.md)`(`\
`        n_samples ``=`` ``4000``,`\
`        control ``=`` `[`control_bayes`](https://openpharma.github.io/rbmi/reference/control.md)`(`\
`            chains ``=`` ``4``,`\
`            warmup ``=`` ``500``,`\
`            thin ``=`` ``1``,`\
`            seed ``=`` ``1821`\
`        ``)`\
`    ``)``,`\
`    quiet ``=`` ``TRUE`\
`)`\
`#> recompiling to avoid crashing R session`\
`#> Trying to compile a simple C file`\
`#> Running /usr/local/lib/R/bin/R CMD SHLIB foo.c`\
`#> using C compiler: ‘gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0’`\
`#> gcc -std=gnu2x -I"/usr/local/lib/R/include" -DNDEBUG   -I"/usr/local/lib/R/site-library/Rcpp/include/"  -I"/usr/local/lib/R/site-library/RcppEigen/include/"  -I"/usr/local/lib/R/site-library/RcppEigen/include/unsupported"  -I"/usr/local/lib/R/site-library/BH/include" -I"/usr/local/lib/R/site-library/StanHeaders/include/src/"  -I"/usr/local/lib/R/site-library/StanHeaders/include/"  -I"/usr/local/lib/R/site-library/RcppParallel/include/" -DRCPP_PARALLEL_USE_TBB=1 -DTBB_INTERFACE_NEW -I/usr/local/lib/R/site-library/RcppParallel/include -I"/usr/local/lib/R/site-library/rstan/include" -DEIGEN_NO_DEBUG  -DBOOST_DISABLE_ASSERTS  -DBOOST_PENDING_INTEGER_LOG2_HPP  -DSTAN_THREADS  -DUSE_STANC3 -DSTRICT_R_HEADERS  -DBOOST_PHOENIX_NO_VARIADIC_EXPRESSION  -D_HAS_AUTO_PTR_ETC=0  -include '/usr/local/lib/R/site-library/StanHeaders/include/stan/math/prim/fun/Eigen.hpp'  -D_REENTRANT -DRCPP_PARALLEL_USE_TBB=1   -I/usr/local/include    -fpic  -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c foo.c -o foo.o`\
`#> In file included from <command-line>:`\
`#> /usr/local/lib/R/site-library/StanHeaders/include/stan/math/prim/fun/Eigen.hpp:3:10: fatal error: stdexcept: No such file or directory`\
`#>     3 | #include <stdexcept>`\
`#>       |          ^~~~~~~~~~~`\
`#> compilation terminated.`\
`#> make: *** [/usr/local/lib/R/etc/Makeconf:190: foo.o] Error 1`\
`drawObj_all_treatment_interactions``$``formula`\
`#> Observed_Count ~ 1 + TreatLab + TreatLab:OnOff + TreatLab:BaseCount`

\
[`set.seed`](https://rdrr.io/r/base/Random.html)`(``123``)`\
`imputeObj_all_treatment_interactions`` ``<-`` `[`impute`](https://openpharma.github.io/rbmi/reference/impute.md)`(`\
`    ``drawObj_all_treatment_interactions`\
`)`

#### 7.2.2 Analyse and pool

The treatment-policy analysis model is unchanged: it uses randomized
treatment and baseline count, without distinguishing on- and
off-treatment periods.

\
`anaObj_all_treatment_interactions`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(`\
`    ``imputeObj_all_treatment_interactions``,`\
`    ``neg_bin_regression``,`\
`    vars ``=`` ``ana_vars`\
`)`

\
`poolObj_all_treatment_interactions`` ``<-`` `[`pool`](https://openpharma.github.io/rbmi/reference/pool.md)`(`\
`    ``anaObj_all_treatment_interactions``,`\
`    conf.level ``=`` ``0.95``,`\
`    alternative ``=`` ``"two.sided"`\
`)`

\
`poolObj_all_treatment_interactions`\
`#> `\
`#> Pool Object`\
`#> -----------`\
`#> Number of Results Combined: 4000`\
`#> Method: rubin`\
`#> Rubin df method: barnard-rubin`\
`#> Confidence Level: 0.95`\
`#> Alternative: two.sided`\
`#> `\
`` #> Results (transformed to the rate scale; original-scale results are in `$pars`): ``\
`#> `\
`#>   ===================================================`\
`#>      parameter     est    se     lci    uci    pval  `\
`#>   ---------------------------------------------------`\
`#>     (Intercept)   0.003    0    0.002  0.003  <0.001 `\
`#>    TreatLab100mg  0.766  0.086  0.615  0.955  0.018  `\
`#>    TreatLab300mg  0.837  0.09   0.678  1.033  0.097  `\
`#>      BaseCount    1.215  0.024  1.169  1.262  <0.001 `\
`#>   ---------------------------------------------------`

#### 7.2.3 Comparison with SAS results

The corresponding SAS results are labelled
`Separate each Treat. Shared frai`.

\
`rate_ratios_all_treatment_interactions`` ``<-`` `[`as.data.frame`](https://rdrr.io/r/base/as.data.frame.html)`(`\
`    ``poolObj_all_treatment_interactions`\
`)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``parameter`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"TreatLab100mg"``, ``"TreatLab300mg"``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`transmute`](https://dplyr.tidyverse.org/reference/transmute.html)`(`\
`        comparison ``=`` ``dplyr``::`[`recode`](https://dplyr.tidyverse.org/reference/recode.html)`(`\
`            ``parameter``,`\
`            TreatLab100mg ``=`` ``"100mg vs Placebo"``,`\
`            TreatLab300mg ``=`` ``"300mg vs Placebo"`\
`        ``)``,`\
`        rbmi_rate_ratio ``=`` ``est``,`\
`        rbmi_lower_95 ``=`` ``lci``,`\
`        rbmi_upper_95 ``=`` ``uci``,`\
`        rbmi_p_value ``=`` ``pval`\
`    ``)`\
`check_rate_ratio_results``(`\
`    ``rate_ratios_all_treatment_interactions``,`\
`    ``"Separate each Treat. Shared frai"`\
`)`\
\
`dplyr``::`[`left_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html)`(`\
`    ``rate_ratios_all_treatment_interactions``,`\
`    ``dplyr``::`[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(`\
`        ``sas_results``,`\
`        ``model`` ``==`` ``"Separate each Treat. Shared frai"`\
`    ``)``,`\
`    by ``=`` ``"comparison"`\
`)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``-``model``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `\
`    ``dplyr``::`[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``dplyr``::`[`across`](https://dplyr.tidyverse.org/reference/across.html)`(``dplyr``::`[`where`](https://tidyselect.r-lib.org/reference/where.html)`(``is.numeric``)``, ``~`` `[`round`](https://rdrr.io/r/base/Round.html)`(``.x``, ``4``)``)``)`\
`#>         comparison rbmi_rate_ratio rbmi_lower_95 rbmi_upper_95 rbmi_p_value`\
`#> 1 100mg vs Placebo          0.7665        0.6153        0.9547       0.0176`\
`#> 2 300mg vs Placebo          0.8367        0.6779        1.0326       0.0967`\
`#>   sas_rate_ratio sas_lower_95 sas_upper_95 sas_p_value`\
`#> 1         0.7656       0.6138       0.9549      0.0178`\
`#> 2         0.8351       0.6761       1.0315      0.0945`

Runtime: draw 85.46 seconds, impute 95.71 seconds, analyse 335.07
seconds, and pool 0.53 seconds.

### 7.3 More complex model which also splits time by season

The preceding models use the original three periods. We can also split
those periods into smaller calendar cells and include a recurring
seasonal effect in the imputation model. This is a genuinely ragged
representation: patients need not contribute the same interval
identifiers, and a withdrawn patient can have several missing cells.

The source data include `Times1`–`Times20`, one-based event-day offsets
within each original period: a value of 1 denotes the first day of that
period and a value of `Length` denotes its last day. There is one
non-missing `Times` value for each event in `Observed_Count`, with the
remaining columns left missing; the simulation allowed at most 20 events
per period. The start of a period on the study calendar is
`StartDate + Lengthsofar`, so an event’s calendar day is
`StartDate + Lengthsofar + TimesN - 1`. Although simulated event times
also exist for the unobserved third period as part of the complete-data
truth, `Observed_Count` is missing there and the split cell outcomes
remain missing.

[`split_time()`](https://openpharma.github.io/rbmi/reference/split_time.md)
uses these offsets to allocate each observed aggregate count to 91-day
cells. A fixed width of 91 days reproduces the quarter definition in the
SAS example. For other applications, `interval` can instead be `"week"`,
`"month"`, `"quarter"`, or `"year"`; calendar months, quarters, and
years require a `Date` start variable.

\
`dat_count_season`` ``<-`` ``dat_count_raw`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`        patient ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``patient``)``,`\
`        TreatLab ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``TreatLab``, levels ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Placebo"``, ``"100mg"``, ``"300mg"``)``)``,`\
`        OnOff ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``OnOff``, levels ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"On"``, ``"Off"``)``)``,`\
`        cell_start ``=`` ``StartDate`` ``+`` ``Lengthsofar`\
`    ``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`split_time`](https://openpharma.github.io/rbmi/reference/split_time.md)`(`\
`        start ``=`` ``"cell_start"``,`\
`        duration ``=`` ``"Length"``,`\
`        outcome ``=`` ``"Observed_Count"``,`\
`        event_times ``=`` `[`paste0`](https://rdrr.io/r/base/paste.html)`(``"Times"``, ``1``:``20``)``,`\
`        interval ``=`` ``91``,`\
`        origin ``=`` ``0``,`\
`        period ``=`` ``"period"`\
`    ``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`        Quarter ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``1`` ``+`` ``split_interval`` `[`%%`](https://rdrr.io/r/base/Arithmetic.html)` ``4``, levels ``=`` ``1``:``4``)`\
`    ``)`\
\
[`nrow`](https://rdrr.io/r/base/nrow.html)`(``dat_count_season``)`\
`#> [1] 3518`\
[`table`](https://rdrr.io/r/base/table.html)`(``dat_count_season``$``Quarter``)`\
`#> `\
`#>   1   2   3   4 `\
`#> 892 844 906 876`

The split data have 3,518 rows and 24 distinct crossed period/quarter
cells. As checks on the restructuring, split durations sum to the
original duration, observed cell counts sum to the original observed
count, and the 83 withdrawn patients contribute 204 missing
positive-duration cells.

\
`season_check`` ``<-`` ``dat_count_season`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``patient``, ``period``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`summarise`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`        split_length ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``split_duration``)``,`\
`        split_count ``=`` ``if`` ``(`[`all`](https://rdrr.io/r/base/all.html)`(`[`is.na`](https://rdrr.io/r/base/NA.html)`(``split_outcome``)``)``)`` ``{`\
`            ``NA_integer_`\
`        ``}`` ``else`` ``{`\
`            `[`sum`](https://rdrr.io/r/base/sum.html)`(``split_outcome``)`\
`        ``}``,`\
`        original_length ``=`` `[`first`](https://dplyr.tidyverse.org/reference/nth.html)`(``Length``)``,`\
`        original_count ``=`` `[`first`](https://dplyr.tidyverse.org/reference/nth.html)`(``Observed_Count``)``,`\
`        .groups ``=`` ``"drop"`\
`    ``)`\
\
[`stopifnot`](https://rdrr.io/r/base/stopifnot.html)`(`\
`    `[`nrow`](https://rdrr.io/r/base/nrow.html)`(``dat_count_season``)`` ``==`` ``3518``,`\
`    `[`nlevels`](https://rdrr.io/r/base/nlevels.html)`(``dat_count_season``$``split_period``)`` ``==`` ``24``,`\
`    `[`sum`](https://rdrr.io/r/base/sum.html)`(`\
`        `[`is.na`](https://rdrr.io/r/base/NA.html)`(``dat_count_season``$``split_outcome``)`` ``&`\
`            ``dat_count_season``$``split_duration`` ``>`` ``0`\
`    ``)`` ``==`` ``204``,`\
`    `[`n_distinct`](https://dplyr.tidyverse.org/reference/n_distinct.html)`(`\
`        ``dat_count_season``$``patient``[`[`is.na`](https://rdrr.io/r/base/NA.html)`(``dat_count_season``$``split_outcome``)``]`\
`    ``)`` ``==`` ``83``,`\
`    `[`all`](https://rdrr.io/r/base/all.html)`(``season_check``$``split_length`` ``==`` ``season_check``$``original_length``)``,`\
`    `[`all`](https://rdrr.io/r/base/all.html)`(`\
`        ``season_check``$``split_count``[``season_check``$``period`` ``!=`` ``3``]`` ``==`\
`            ``season_check``$``original_count``[``season_check``$``period`` ``!=`` ``3``]`\
`    ``)``,`\
`    `[`all`](https://rdrr.io/r/base/all.html)`(`[`is.na`](https://rdrr.io/r/base/NA.html)`(``season_check``$``split_count``[``season_check``$``period`` ``==`` ``3``]``)``)`\
`)`

The count draw model uses a ragged negative-multinomial likelihood: it
accepts one row per observed positive-duration cell and accumulates the
cell means and counts by patient. There is no padding to a common set of
periods and no fixed upper limit on the number of periods.

We add `Quarter` to the imputation model. `split_period` uniquely
identifies the original period crossed with the absolute 91-day interval
and supplies the within-patient ordering used for sequential imputation.

\
`dat_ice_season`` ``<-`` ``dat_count_season`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(`[`is.na`](https://rdrr.io/r/base/NA.html)`(``split_outcome``)``, ``split_duration`` ``>`` ``0``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`distinct`](https://dplyr.tidyverse.org/reference/distinct.html)`(``patient``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``strategy ``=`` ``"MAR"``)`\
\
`vars_season`` ``<-`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`\
`    outcome ``=`` ``"split_outcome"``,`\
`    subjid ``=`` ``"patient"``,`\
`    period ``=`` ``"split_period"``,`\
`    duration ``=`` ``"split_duration"``,`\
`    group ``=`` ``"TreatLab"``,`\
`    covariates ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`\
`        ``"TreatLab:OnOff"``,`\
`        ``"BaseCount"``,`\
`        ``"Quarter"`\
`    ``)`\
`)`

\
`drawObj_season`` ``<-`` `[`draws`](https://openpharma.github.io/rbmi/reference/draws.md)`(`\
`    outcome ``=`` ``"count"``,`\
`    data ``=`` ``dat_count_season``,`\
`    data_ice ``=`` ``dat_ice_season``,`\
`    vars ``=`` ``vars_season``,`\
`    method ``=`` ``method``,`\
`    quiet ``=`` ``TRUE`\
`)`\
`#> recompiling to avoid crashing R session`\
`#> Trying to compile a simple C file`\
`#> Running /usr/local/lib/R/bin/R CMD SHLIB foo.c`\
`#> using C compiler: ‘gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0’`\
`#> gcc -std=gnu2x -I"/usr/local/lib/R/include" -DNDEBUG   -I"/usr/local/lib/R/site-library/Rcpp/include/"  -I"/usr/local/lib/R/site-library/RcppEigen/include/"  -I"/usr/local/lib/R/site-library/RcppEigen/include/unsupported"  -I"/usr/local/lib/R/site-library/BH/include" -I"/usr/local/lib/R/site-library/StanHeaders/include/src/"  -I"/usr/local/lib/R/site-library/StanHeaders/include/"  -I"/usr/local/lib/R/site-library/RcppParallel/include/" -DRCPP_PARALLEL_USE_TBB=1 -DTBB_INTERFACE_NEW -I/usr/local/lib/R/site-library/RcppParallel/include -I"/usr/local/lib/R/site-library/rstan/include" -DEIGEN_NO_DEBUG  -DBOOST_DISABLE_ASSERTS  -DBOOST_PENDING_INTEGER_LOG2_HPP  -DSTAN_THREADS  -DUSE_STANC3 -DSTRICT_R_HEADERS  -DBOOST_PHOENIX_NO_VARIADIC_EXPRESSION  -D_HAS_AUTO_PTR_ETC=0  -include '/usr/local/lib/R/site-library/StanHeaders/include/stan/math/prim/fun/Eigen.hpp'  -D_REENTRANT -DRCPP_PARALLEL_USE_TBB=1   -I/usr/local/include    -fpic  -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c foo.c -o foo.o`\
`#> In file included from <command-line>:`\
`#> /usr/local/lib/R/site-library/StanHeaders/include/stan/math/prim/fun/Eigen.hpp:3:10: fatal error: stdexcept: No such file or directory`\
`#>     3 | #include <stdexcept>`\
`#>       |          ^~~~~~~~~~~`\
`#> compilation terminated.`\
`#> make: *** [/usr/local/lib/R/etc/Makeconf:190: foo.o] Error 1`

During imputation, missing cells are visited in `split_period` order.
For each patient, a draw conditions first on all observed cells. After
each missing-cell draw, its sampled count and fitted mean are added to
the conditioning totals before drawing the next cell. With only one
missing cell, this reduces exactly to the conditional negative-binomial
calculation used by the original three-period implementation.

\
[`set.seed`](https://rdrr.io/r/base/Random.html)`(``123``)`\
`imputeObj_season`` ``<-`` `[`impute`](https://openpharma.github.io/rbmi/reference/impute.md)`(``drawObj_season``)`

\
`imputeObj_season`\
`#> `\
`#> Imputation Object`\
`#> -----------------`\
`#> Number of Imputed Datasets: 1000`\
`#> Endpoint Type: count`\
`#> Number of Patients with Positive Duration by Period:`\
`#>     1:0: 167`\
`#>     2:0: 2`\
`#>     1:1: 300`\
`#>     2:1: 11`\
`#>     1:2: 482`\
`#>     2:2: 26`\
`#>     3:2: 10`\
`#>     1:3: 636`\
`#>     2:3: 36`\
`#>     3:3: 21`\
`#>     1:4: 620`\
`#>     2:4: 50`\
`#>     3:4: 45`\
`#>     1:5: 446`\
`#>     2:5: 38`\
`#>     3:5: 49`\
`#>     1:6: 310`\
`#>     2:6: 27`\
`#>     3:6: 51`\
`#>     1:7: 144`\
`#>     2:7: 12`\
`#>     3:7: 27`\
`#>     1:8: 7`\
`#>     3:8: 1`\
`#> References:`\
`#>     Placebo -> Placebo`\
`#>     100mg   -> 100mg`\
`#>     300mg   -> 300mg`

Season is used only in the imputation model. The treatment-policy
analysis still aggregates all observed and imputed counts and exposure
within patient.

\
`ana_vars_season`` ``<-`` `[`set_vars`](https://openpharma.github.io/rbmi/reference/set_vars.md)`(`\
`    outcome ``=`` ``"split_outcome"``,`\
`    subjid ``=`` ``"patient"``,`\
`    period ``=`` ``"split_period"``,`\
`    duration ``=`` ``"split_duration"``,`\
`    group ``=`` ``"TreatLab"``,`\
`    covariates ``=`` ``"BaseCount"`\
`)`

\
`anaObj_season`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(`\
`    ``imputeObj_season``,`\
`    ``neg_bin_regression``,`\
`    vars ``=`` ``ana_vars_season`\
`)`

\
`poolObj_season`` ``<-`` `[`pool`](https://openpharma.github.io/rbmi/reference/pool.md)`(`\
`    ``anaObj_season``,`\
`    conf.level ``=`` ``0.95``,`\
`    alternative ``=`` ``"two.sided"`\
`)`

\
`poolObj_season`\
`#> `\
`#> Pool Object`\
`#> -----------`\
`#> Number of Results Combined: 1000`\
`#> Method: rubin`\
`#> Rubin df method: barnard-rubin`\
`#> Confidence Level: 0.95`\
`#> Alternative: two.sided`\
`#> `\
`` #> Results (transformed to the rate scale; original-scale results are in `$pars`): ``\
`#> `\
`#>   ===================================================`\
`#>      parameter     est    se     lci    uci    pval  `\
`#>   ---------------------------------------------------`\
`#>     (Intercept)   0.003    0    0.002  0.003  <0.001 `\
`#>    TreatLab100mg  0.765  0.086  0.614  0.953  0.017  `\
`#>    TreatLab300mg  0.837  0.09   0.678  1.033  0.098  `\
`#>      BaseCount    1.214  0.024  1.169  1.261  <0.001 `\
`#>   ---------------------------------------------------`

The corresponding SAS results are labelled
`4 Seasons: Treat*OnOff BaseCount`.

\
`rate_ratios_season`` ``<-`` `[`as.data.frame`](https://rdrr.io/r/base/as.data.frame.html)`(``poolObj_season``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``parameter`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"TreatLab100mg"``, ``"TreatLab300mg"``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`transmute`](https://dplyr.tidyverse.org/reference/transmute.html)`(`\
`        comparison ``=`` `[`recode`](https://dplyr.tidyverse.org/reference/recode.html)`(`\
`            ``parameter``,`\
`            TreatLab100mg ``=`` ``"100mg vs Placebo"``,`\
`            TreatLab300mg ``=`` ``"300mg vs Placebo"`\
`        ``)``,`\
`        rbmi_rate_ratio ``=`` ``est``,`\
`        rbmi_lower_95 ``=`` ``lci``,`\
`        rbmi_upper_95 ``=`` ``uci``,`\
`        rbmi_p_value ``=`` ``pval`\
`    ``)`\
`check_rate_ratio_results``(`\
`    ``rate_ratios_season``,`\
`    ``"4 Seasons: Treat*OnOff BaseCount"`\
`)`\
\
[`left_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html)`(`\
`    ``rate_ratios_season``,`\
`    `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``sas_results``, ``model`` ``==`` ``"4 Seasons: Treat*OnOff BaseCount"``)``,`\
`    by ``=`` ``"comparison"`\
`)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``-``model``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)` `\
`    ``dplyr``::`[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``dplyr``::`[`across`](https://dplyr.tidyverse.org/reference/across.html)`(``dplyr``::`[`where`](https://tidyselect.r-lib.org/reference/where.html)`(``is.numeric``)``, ``~`` `[`round`](https://rdrr.io/r/base/Round.html)`(``.x``, ``4``)``)``)`\
`#>         comparison rbmi_rate_ratio rbmi_lower_95 rbmi_upper_95 rbmi_p_value`\
`#> 1 100mg vs Placebo          0.7647        0.6139        0.9526       0.0167`\
`#> 2 300mg vs Placebo          0.8368        0.6776        1.0333       0.0978`\
`#>   sas_rate_ratio sas_lower_95 sas_upper_95 sas_p_value`\
`#> 1         0.7642       0.6131       0.9525      0.0167`\
`#> 2         0.8345       0.6756       1.0306      0.0929`

Runtime: draw 89.16 seconds, impute 52.40 seconds, analyse 87.42
seconds, and pool 0.15 seconds.

### 7.4 Fixed rate model for the active arms

The next controlled-imputation analysis retains the estimated
off-treatment rate for placebo, but replaces the model-based period-3
rate for both active arms with a fixed value.

There is an important parameterization detail.
[`count_strategy()`](https://openpharma.github.io/rbmi/reference/count_strategy.md)
offers two scales for `fixed_rate`:

- `fixed_rate_scale = "rate"` (the default): `fixed_rate` is an event
  rate per unit of duration, so the unconditional mean of the missing
  cell is \\(\mu\_{i3} = L\_{i3} \times \text{fixed\\\_rate}\\), the
  same for every posterior draw and treatment arm.
- `fixed_rate_scale = "lambda"`: reproduces the SAS macro
  `NM_Rand13.sas`, which fixes the value on its negative-multinomial
  lambda scale. If \\(r = \phi^{-1}\\) is the negative-multinomial shape
  parameter, the mean is \\(\mu\_{i3} = r L\_{i3} \times
  \text{fixed\\\_rate} = L\_{i3} \times \text{fixed\\\_rate} / \phi\\).
  The implied event rate therefore varies with each posterior draw of
  \\(\phi\\) and grows without bound when \\(\phi\\) is close to zero
  (nearly Poisson data);
  [`impute()`](https://openpharma.github.io/rbmi/reference/impute.md)
  warns when this implies rates more than 100 times the model-based
  rate.

To reproduce the SAS results, we select the SAS scale explicitly. For
new analyses, the default rate scale is recommended because the
specified value is then an interpretable event rate.

In the joint count model, \\(\mu\_{i3}\\) is the unconditional marginal
mean of \\(Y\_{i3}\\). The actual imputation distribution, however,
conditions on the observed counts \\(y\_{i1},y\_{i2}\\). Given these
counts and fitted observed-cell means \\(\hat\mu\_{i1},\hat\mu\_{i2}\\),
its conditional mean is

\\\[\mathbb{E}(Y\_{i3} \mid y\_{i1},y\_{i2}) = \frac{r + y\_{i1} +
y\_{i2}} {r + \hat\mu\_{i1} + \hat\mu\_{i2}}\\,\mu\_{i3}.\\\]

For a fixed-rate strategy based on JR or CR, \\(r\\) is calculated from
the mapped reference arm’s `phi`; under JR this is so even though the
fitted observed-cell means in the denominator use the subject’s
randomized-arm design.

Controlled count strategies are applied in
[`impute()`](https://openpharma.github.io/rbmi/reference/impute.md),
after the posterior parameters have been drawn. Each strategy has a base
trajectory (`MAR`, `JR`, or `CR`) and an optional transformation of the
missing-cell rate. Thus the original `drawObj` can be reused without
refitting the observed-data model.

First, we identify the period-3 withdrawals in the active arms and
update only their imputation strategy. Placebo patients retain MAR
imputation using the estimated placebo off-treatment rate.

\
`active_period3_strategy`` ``<-`` ``dat_count_filled`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(`\
`        ``period`` ``==`` ``"3"``,`\
`        ``Length`` ``>`` ``0``,`\
`        ``TreatLab`` ``!=`` ``"Placebo"`\
`    ``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`distinct`](https://dplyr.tidyverse.org/reference/distinct.html)`(``patient``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``strategy ``=`` ``"FIXED_LAMBDA"``)`\
\
`fixed_lambda_strategies`` ``<-`` `[`get_count_strategies`](https://openpharma.github.io/rbmi/reference/count_strategy.md)`(`\
`    FIXED_LAMBDA ``=`` `[`count_strategy`](https://openpharma.github.io/rbmi/reference/count_strategy.md)`(`\
`        base ``=`` ``"MAR"``,`\
`        fixed_rate ``=`` ``0.0021``,`\
`        fixed_rate_scale ``=`` ``"lambda"``,`\
`        period ``=`` ``"3"`\
`    ``)`\
`)`

\
[`set.seed`](https://rdrr.io/r/base/Random.html)`(``123``)`\
`imputeObj_fixed_lambda`` ``<-`` `[`impute`](https://openpharma.github.io/rbmi/reference/impute.md)`(`\
`    ``drawObj``,`\
`    update_strategy ``=`` ``active_period3_strategy``,`\
`    strategies ``=`` ``fixed_lambda_strategies`\
`)`

The treatment-policy analysis and pooling steps are unchanged.

\
`anaObj_fixed_lambda`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(`\
`    ``imputeObj_fixed_lambda``,`\
`    ``neg_bin_regression``,`\
`    vars ``=`` ``ana_vars`\
`)`

\
`poolObj_fixed_lambda`` ``<-`` `[`pool`](https://openpharma.github.io/rbmi/reference/pool.md)`(`\
`    ``anaObj_fixed_lambda``,`\
`    conf.level ``=`` ``0.95``,`\
`    alternative ``=`` ``"two.sided"`\
`)`

\
`rate_ratios_fixed_lambda`` ``<-`` `[`as.data.frame`](https://rdrr.io/r/base/as.data.frame.html)`(``poolObj_fixed_lambda``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``parameter`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"TreatLab100mg"``, ``"TreatLab300mg"``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`transmute`](https://dplyr.tidyverse.org/reference/transmute.html)`(`\
`        comparison ``=`` `[`recode`](https://dplyr.tidyverse.org/reference/recode.html)`(`\
`            ``parameter``,`\
`            TreatLab100mg ``=`` ``"100mg vs Placebo"``,`\
`            TreatLab300mg ``=`` ``"300mg vs Placebo"`\
`        ``)``,`\
`        rbmi_rate_ratio ``=`` ``est``,`\
`        rbmi_lower_95 ``=`` ``lci``,`\
`        rbmi_upper_95 ``=`` ``uci``,`\
`        rbmi_p_value ``=`` ``pval`\
`    ``)`\
`check_rate_ratio_results``(`\
`    ``rate_ratios_fixed_lambda``,`\
`    ``"Fixed 0.01 active imputed"`\
`)`\
\
[`left_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html)`(`\
`    ``rate_ratios_fixed_lambda``,`\
`    `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``sas_results``, ``model`` ``==`` ``"Fixed 0.01 active imputed"``)``,`\
`    by ``=`` ``"comparison"`\
`)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``-``model``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``dplyr``::`[`across`](https://dplyr.tidyverse.org/reference/across.html)`(``dplyr``::`[`where`](https://tidyselect.r-lib.org/reference/where.html)`(``is.numeric``)``, ``~`` `[`round`](https://rdrr.io/r/base/Round.html)`(``.x``, ``4``)``)``)`\
`#>         comparison rbmi_rate_ratio rbmi_lower_95 rbmi_upper_95 rbmi_p_value`\
`#> 1 100mg vs Placebo          0.7840        0.6286        0.9778       0.0309`\
`#> 2 300mg vs Placebo          0.8532        0.6909        1.0537       0.1404`\
`#>   sas_rate_ratio sas_lower_95 sas_upper_95 sas_p_value`\
`#> 1         0.7850       0.6291       0.9794      0.0320`\
`#> 2         0.8531       0.6906       1.0538      0.1405`

Runtime: draw 78.08 seconds (reusing the original draws), impute 20.71
seconds, analyse 87.22 seconds, and pool 0.15 seconds.

### 7.5 Off-treatment estimate is doubled for the active arms

The same controlled-imputation mechanism can multiply rather than
replace the model-based mean. Here the active-arm period-3 mean is twice
the corresponding estimated off-treatment mean, while placebo is
unchanged:

\\\[\mu\_{i3}^{\text{impute}} = 2\mu\_{i3}^{\text{model}}.\\\]

Only the strategy definition changes. Its base remains MAR, so each
active-arm patient retains their randomized arm’s modeled off-treatment
trajectory and dispersion parameter before the multiplier is applied.

\
`active_period3_double_strategy`` ``<-`` ``active_period3_strategy`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``strategy ``=`` ``"DOUBLE_RATE"``)`\
\
`double_rate_strategies`` ``<-`` `[`get_count_strategies`](https://openpharma.github.io/rbmi/reference/count_strategy.md)`(`\
`    DOUBLE_RATE ``=`` `[`count_strategy`](https://openpharma.github.io/rbmi/reference/count_strategy.md)`(`\
`        base ``=`` ``"MAR"``,`\
`        rate_multiplier ``=`` ``2``,`\
`        period ``=`` ``"3"`\
`    ``)`\
`)`

\
[`set.seed`](https://rdrr.io/r/base/Random.html)`(``123``)`\
`imputeObj_double_rate`` ``<-`` `[`impute`](https://openpharma.github.io/rbmi/reference/impute.md)`(`\
`    ``drawObj``,`\
`    update_strategy ``=`` ``active_period3_double_strategy``,`\
`    strategies ``=`` ``double_rate_strategies`\
`)`

\
`anaObj_double_rate`` ``<-`` `[`analyse`](https://openpharma.github.io/rbmi/reference/analyse.md)`(`\
`    ``imputeObj_double_rate``,`\
`    ``neg_bin_regression``,`\
`    vars ``=`` ``ana_vars`\
`)`

\
`poolObj_double_rate`` ``<-`` `[`pool`](https://openpharma.github.io/rbmi/reference/pool.md)`(`\
`    ``anaObj_double_rate``,`\
`    conf.level ``=`` ``0.95``,`\
`    alternative ``=`` ``"two.sided"`\
`)`

\
`rate_ratios_double_rate`` ``<-`` `[`as.data.frame`](https://rdrr.io/r/base/as.data.frame.html)`(``poolObj_double_rate``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``parameter`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"TreatLab100mg"``, ``"TreatLab300mg"``)``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`transmute`](https://dplyr.tidyverse.org/reference/transmute.html)`(`\
`        comparison ``=`` `[`recode`](https://dplyr.tidyverse.org/reference/recode.html)`(`\
`            ``parameter``,`\
`            TreatLab100mg ``=`` ``"100mg vs Placebo"``,`\
`            TreatLab300mg ``=`` ``"300mg vs Placebo"`\
`        ``)``,`\
`        rbmi_rate_ratio ``=`` ``est``,`\
`        rbmi_lower_95 ``=`` ``lci``,`\
`        rbmi_upper_95 ``=`` ``uci``,`\
`        rbmi_p_value ``=`` ``pval`\
`    ``)`\
`check_rate_ratio_results``(`\
`    ``rate_ratios_double_rate``,`\
`    ``"Delta Active double rate off"`\
`)`\
\
[`left_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html)`(`\
`    ``rate_ratios_double_rate``,`\
`    `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``sas_results``, ``model`` ``==`` ``"Delta Active double rate off"``)``,`\
`    by ``=`` ``"comparison"`\
`)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``-``model``)`` `[`%>%`](https://magrittr.tidyverse.org/reference/pipe.html)\
`    ``dplyr``::`[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``dplyr``::`[`across`](https://dplyr.tidyverse.org/reference/across.html)`(``dplyr``::`[`where`](https://tidyselect.r-lib.org/reference/where.html)`(``is.numeric``)``, ``~`` `[`round`](https://rdrr.io/r/base/Round.html)`(``.x``, ``4``)``)``)`\
`#>         comparison rbmi_rate_ratio rbmi_lower_95 rbmi_upper_95 rbmi_p_value`\
`#> 1 100mg vs Placebo          0.7924        0.6324        0.9929       0.0432`\
`#> 2 300mg vs Placebo          0.8619        0.6973        1.0655       0.1695`\
`#>   sas_rate_ratio sas_lower_95 sas_upper_95 sas_p_value`\
`#> 1         0.7931       0.6344       0.9915      0.0419`\
`#> 2         0.8606       0.6957       1.0647      0.1667`

Runtime: draw 78.08 seconds (reusing the original draws), impute 20.54
seconds, analyse 85.22 seconds, and pool 0.16 seconds.
