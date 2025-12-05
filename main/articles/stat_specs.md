# rbmi: Statistical Specifications

## 1 Scope of this document

This document describes the statistical methods implemented in the
`rbmi` R package for standard and reference-based multiple imputation of
continuous longitudinal outcomes. The package implements three classes
of multiple imputation (MI) approaches:

1.  Conventional MI methods based on Bayesian (or approximate Bayesian)
    posterior draws of model parameters combined with Rubin’s rules to
    make inferences as described in Carpenter, Roger, and Kenward
    ([2013](#ref-CarpenterEtAl2013)) and Cro et al.
    ([2020](#ref-CroEtAlTutorial2020)).

2.  Conditional mean imputation methods combined with re-sampling
    techniques as described in Wolbers et al.
    ([2022](#ref-Wolbers2021)).

3.  Bootstrapped MI methods as described in von Hippel and Bartlett
    ([2021](#ref-vonHippelBartlett2021)).

The document is structured as follows: we first provide an informal
introduction to estimands and corresponding treatment effect estimation
based on MI (section [2](#sec:intro)). The core of this document
consists of section [3](#sec:statsMethods) which describes the
statistical methodology in detail and also contains a comparison of the
implemented approaches (section [3.10](#sec:methodsComparison)). The
link between theory and the functions included in package `rbmi` is
described in section [4](#sec:rbmiFunctions). We conclude with a
comparison of our package to some alternative software implementations
of reference-based imputation methods (section [5](#sec:otherSoftware)).

## 2 Introduction to estimands and estimation methods

### 2.1 Estimands

The ICH E9(R1) addendum on estimands and sensitivity analyses describes
a systematic approach to ensure alignment among clinical trial
objectives, trial execution/conduct, statistical analyses, and
interpretation of results (ICH E9 working group ([2019](#ref-iche9r1))).
As per the addendum, an estimand is a precise description of the
treatment effect reflecting the clinical question posed by the trial
objective which summarizes at a population-level what the outcomes would
be in the same patients under different treatment conditions being
compared. One important attribute of an estimand is a list of possible
intercurrent events (ICEs), i.e. of events occurring after treatment
initiation that affect either the interpretation or the existence of the
measurements associated with the clinical question of interest, and the
definition of appropriate strategies to deal with ICEs. The three most
relevant strategies for the purpose of this document are the
hypothetical strategy, the treatment policy strategy, and the composite
strategy. For the hypothetical strategy, a scenario is envisaged in
which the ICE would not occur. Under this scenario, endpoint values
after the ICE are not directly observable and treated using models for
missing data. For the treatment policy strategy, the treatment effect in
the presence of the ICEs is targeted and analyses are based on the
observed outcomes regardless whether the subject had an ICE or not. For
the composite strategy, the ICE itself is included as a component of the
endpoint.

### 2.2 Alignment between the estimand and the estimation method

The ICH E9(R1) addendum distinguishes between ICEs and missing data (ICH
E9 working group ([2019](#ref-iche9r1))). Whereas ICEs such as treatment
discontinuations reflect clinical practice, the amount of missing data
can be minimized in the conduct of a clinical trial. However, there are
many connections between missing data and ICEs. For example, it is often
difficult to retain subjects in a clinical trial after treatment
discontinuation and a subject’s dropout from the trial leads to missing
data. As another example, outcome values after ICEs addressed using a
hypothetical strateg are not directly observable under the hypothetical
scenario. Consequently, any observed outcome values after such ICEs are
typically discarded and treated as missing data.

The addendum proposes that estimation methods to address the problem
presented by missing data should be selected to align with the estimand.
A recent overview of methods to align the estimator with the estimand is
Mallinckrodt et al. ([2020](#ref-Mallinckrodt2020)). A short
introduction on estimation methods for studies with longitudinal
endpoints can also be found in Wolbers et al.
([2022](#ref-Wolbers2021)). One prominent statistical method for this
purpose is multiple imputation (MI), which is the target of the `rbmi`
package.

#### 2.2.1 Missing data prior to ICEs

Missing data may occur in subjects without an ICE or prior to the
occurrence of an ICE. As such missing outcomes are not associated with
an ICE, it is often plausible to impute them under a missing-at-random
(MAR) assumption using a standard MMRM imputation model of the
longitudinal outcomes. Informally, MAR occurs if the missing data can be
fully accounted for by the baseline variables included in the model and
the observed longitudinal outcomes, and if the model is correctly
specified.

#### 2.2.2 Implementation of the hypothetical strategy

The MAR imputation model described above is often also a good starting
point for imputing data after an ICE handled using a hypothetical
strategy (Mallinckrodt et al. ([2020](#ref-Mallinckrodt2020))).
Informally, this assumes that unobserved values after the ICE would have
been similar to the observed data from subjects who did not have the ICE
and remained under follow-up. However, in some situations, it may be
more reasonable to assume that missingness is “informative” and
indicates a systematically better or worse outcome than in observed
subjects. In such situations, MNAR imputation with a
\\\delta\\-adjustment could be explored as a sensitivity analysis.
\\\delta\\-adjustments add a fixed or random quantity to the imputations
in order to make the imputed outcomes systematically worse or better
than those observed as described in Cro et al.
([2020](#ref-CroEtAlTutorial2020)). In `rbmi` only fixed
\\\delta\\-adjustments are implemented.

#### 2.2.3 Implementation of the treatment policy strategy

Ideally, data collection continues after an ICE handled with a treatment
policy strategy and no missing data arises. Indeed, such post-ICE data
are increasingly systematically collected in RCTs. However, despite best
efforts, missing data after an ICE such as study treatment
discontinuation may still occur because the subject drops out from the
study after discontinuation. It is difficult to give definite
recommendations regarding the implementation of the treatment policy
strategy in the presence of missing data at this stage because the
optimal method is highly context dependent and a topic of ongoing
statistical research.

For ICEs which are thought to have a negligible effect on efficacy
outcomes, standard MAR-based imputation which ignores whether an outcome
is observed pre- or post-ICE may be appropriate. In contrast, an ICE
such as treatment discontinuation may be expected to have a more
substantial impact on efficacy outcomes. In such settings, the MAR
assumption may still be plausible after conditioning on the subject’s
time-varying treatment status (Guizzaro et al.
([2021](#ref-Guizzaro2021))). In this case, one option is to impute
missing post-discontinuation data based on subjects who also
discontinued treatment but continued to be followed up. Another option
which may require somewhat less post-discontinuation data is to include
all subjects in the imputation procedure but to model
post-discontinuation data by using time-varying treatment status
indicators (Guizzaro et al. ([2021](#ref-Guizzaro2021)), Polverejan and
Dragalin ([2020](#ref-PolverejanDragalin2020)), Noci et al.
([2023](#ref-Noci2021)), Drury et al. ([2024](#ref-Drury2024)), Bell et
al. ([2025](#ref-Bell2024))). In this approach, post-ICE outcomes are
included in every step of the analysis, including in the fitting of the
imputation model. It assumes that ICEs may impact post-ICE outcomes but
that otherwise missingness is non-informative. The approach also assumes
that the time-varying covariates do not contain missing values,
deviations in outcomes after the ICE are correctly modeled by these
time-varying covariates, and that sufficient post-ICE data are available
to inform the regression coefficients of the time-varying covariates.
The resulting imputation models are called “retrieved dropout models” in
the statistical literature. These models tend to have less bias than
alternative analysis approaches based on imputation under a basic MAR
assumption or a reference-based missing data assumption. However,
retrieved dropout models have been associated with inflated standard
errors of associated treatment effect estimators which has a detrimental
effect on study power. In particular, it has been observed that once the
post-ICE observation percentages falls below 50%, the power loss can be
quite dramatic ([Bell et al. 2025](#ref-Bell2024)). We illustrate the
implementation of retrieved dropout models in the vignette
“Implementation of retrieved-dropout models using rbmi”
([`vignette(topic = "retrieved_dropout", package = "rbmi")`](https://insightsengineering.github.io/rbmi/articles/retrieved_dropout.md)).

In some trial settings, only few subjects discontinue the randomized
treatment. In other settings, treatment discontinuation rates are higher
but it is difficult to retain subjects in the trial after treatment
discontinuation leading to sparse data collection after treatment
discontinuation. In both settings, the amount of available data after
treatment discontinuation may be insufficient to inform an imputation
model which explicitly models post-discontinuation data. Depending on
the disease area and the anticipated mechanism of action of the
intervention, it may be plausible to assume that subjects in the
intervention group behave similarly to subjects in the control group
after the ICE treatment discontinuation. In this case, reference-based
imputation methods are an option (Mallinckrodt et al.
([2020](#ref-Mallinckrodt2020))). Reference-based imputation methods
formalize the idea to impute missing data in the intervention group
based on data from a control or reference group. For a general
description and review of reference-based imputation methods, we refer
to Carpenter, Roger, and Kenward ([2013](#ref-CarpenterEtAl2013)), Cro
et al. ([2020](#ref-CroEtAlTutorial2020)), I. White, Royes, and Best
([2020](#ref-White2020causal)) and Wolbers et al.
([2022](#ref-Wolbers2021)). For a technical description of the
implemented statistical methodology for reference-based imputation, we
refer to section [3](#sec:statsMethods) (in particular section
[3.4](#sec:imputationStep)).

#### 2.2.4 Implementation of the composite strategy

The composite strategy is typically applied to binary or time-to-event
outcomes but it can also be used for continuous outcomes by ascribing a
suitably unfavorable value to patients who experience ICEs for which a
composite strategy has been defined. One possibility to implement this
is to use MI with a \\\delta\\-adjustment for post-ICE data as described
in Darken et al. ([2020](#ref-Darken2020)).

## 3 Statistical methodology

### 3.1 Overview of the imputation procedure

Analyses of datasets with missing data always rely on missing data
assumptions. The methods described here can be used to produce valid
imputations under a MAR assumption or under reference-based imputation
assumptions. MNAR imputation based on fixed \\\delta\\-adjustments as
typically used in sensitivity analyses such as tipping-point analyses
are also supported.

Three general imputation approaches are implemented in `rbmi`:

1.  **Conventional MI** based on Bayesian (or approximate Bayesian)
    posterior draws from the imputation model combined with Rubin’s
    rules for inference as described in Carpenter, Roger, and Kenward
    ([2013](#ref-CarpenterEtAl2013)) and Cro et al.
    ([2020](#ref-CroEtAlTutorial2020)).

2.  **Conditional mean imputation** based on the REML estimate of the
    imputation model combined with resampling techniques (the jackknife
    or the bootstrap) for inference as described in Wolbers et al.
    ([2022](#ref-Wolbers2021)).

3.  **Bootstrapped MI** methods based on REML estimates of the
    imputation model as described in von Hippel and Bartlett
    ([2021](#ref-vonHippelBartlett2021)).

#### 3.1.1 Conventional MI

Conventional MI approaches include the following steps:

1.  **Base imputation model fitting step** (Section
    [3.3](#sec:imputationModel))

- Fit a Bayesian multivariate normal mixed model for repeated measures
  (MMRM) to the observed longitudinal outcomes after exclusion of data
  after ICEs for which reference-based missing data imputation is
  desired (Section [3.3.3](#sec:imputationModelBayes)). Draw \\M\\
  posterior samples of the estimated parameters (regression coefficients
  and covariance matrices) from this model.

- Alternatively, \\M\\ approximate posterior draws from the posterior
  distribution can be sampled by repeatedly applying conventional
  restricted maximum-likelihood (REML) parameter estimation of the MMRM
  model to nonparametric bootstrap samples from the original dataset
  (Section [3.3.4](#sec:imputationModelBoot)).

2.  **Imputation step** (Section [3.4](#sec:imputationStep))

- Take a single sample \\m\\ (\\m\in 1,\ldots, M)\\ from the posterior
  distribution of the imputation model parameters.

- For each subject, use the sampled parameters and the defined
  imputation strategy to determine the mean and covariance matrix
  describing the subject’s marginal outcome distribution for all
  longitudinal outcome assessments (i.e. observed and missing outcomes).

- For each subjects, construct the conditional multivariate normal
  distribution of their missing outcomes given their observed outcomes
  (including observed outcomes after ICEs for which a reference-based
  assumption is desired).

- For each subject, draw a single sample from this conditional
  distribution to impute their missing outcomes leading to a complete
  imputed dataset.

- For sensitivity analyses, a pre-defined \\\delta\\-adjustment may be
  applied to the imputed data prior to the analysis step. (Section
  [3.5](#sec:deltaAdjustment)).

3.  **Analysis step** (Section [3.6](#sec:analysis))

- Analyze the imputed dataset using an analysis model (e.g. ANCOVA)
  resulting in a point estimate and a standard error (with corresponding
  degrees of freedom) of the treatment effect.

4.  **Pooling step for inference** (Section [3.7](#sec:pooling))

- Repeat steps 2. and 3. for each posterior sample \\m\\, resulting in
  \\M\\ complete datasets, \\M\\ point estimates of the treatment
  effect, and \\M\\ standard errors (with corresponding degrees of
  freedom). Pool the \\M\\ treatment effect estimates, standard errors,
  and degrees of freedom using the rules by Barnard and Rubin to obtain
  the final pooled treatment effect estimator, standard error, and
  degrees of freedom.

#### 3.1.2 Conditional mean imputation

The conditional mean imputation approach includes the following steps:

1.  **Base imputation model fitting step** (Section
    [3.3](#sec:imputationModel))

- Fit a conventional multivariate normal/MMRM model using restricted
  maximum likelihood (REML) to the observed longitudinal outcomes after
  exclusion of data after ICEs for which reference-based missing data
  imputation is desired (Section [3.3.2](#sec:imputationModelREML)).

2.  **Imputation step** (Section [3.4](#sec:imputationStep))

- For each subject, use the fitted parameters from step 1. to construct
  the conditional distribution of missing outcomes given observed
  outcomes (including observed outcomes after ICEs for which
  reference-based missing data imputation is desired) as described
  above.

- For each subject, impute their missing data deterministically by the
  mean of this conditional distribution leading to a complete imputed
  dataset.

- For sensitivity analyses, a pre-defined \\\delta\\-adjustment may be
  applied to the imputed data prior to the analysis step. (Section
  [3.5](#sec:deltaAdjustment)).

3.  **Analysis step** (Section [3.6](#sec:analysis))

- Apply an analysis model (e.g. ANCOVA) to the completed dataset
  resulting in a point estimate of the treatment effect.

4.  **Jackknife or bootstrap inference step** (Section
    [3.8](#sec:bootInference))

- Inference for the treatment effect estimate from 3. is based on
  re-sampling techniques. Both the jackknife and the bootstrap are
  supported. Importantly, these methods require repeating all steps of
  the imputation procedure (i.e. imputation, conditional mean
  imputation, and analysis steps) on each of the resampled datasets.

#### 3.1.3 Bootstrapped MI

The bootstrapped MI approach includes the following steps:

1.  **Base imputation model fitting step** (Section
    [3.3](#sec:imputationModel))

- Apply conventional restricted maximum-likelihood (REML) parameter
  estimation of the MMRM model to \\B\\ nonparametric bootstrap samples
  from the original dataset using the observed longitudinal outcomes
  after exclusion of data after ICEs for which reference-based missing
  data imputation is desired.

2.  **Imputation step** (Section [3.4](#sec:imputationStep))

- Take a bootstrapped dataset \\b\\ (\\b\in 1,\ldots, B)\\ and its
  corresponding imputation model parameter estimates.

- For each subject (from the bootstrapped dataset), use the parameter
  estimates and the defined strategy for dealing with their ICEs to
  determine the mean and covariance matrix describing the subject’s
  marginal outcome distribution for all longitudinal outcome assessments
  (i.e. observed and missing outcomes).

- For each subjects (from the bootstrapped dataset), construct the
  conditional multivariate normal distribution of their missing outcomes
  given their observed outcomes (including observed outcomes after ICEs
  for which reference-based missing data imputation is desired).

- For each subject (from the bootstrapped dataset), draw \\D\\ samples
  from this conditional distributions to impute their missing outcomes
  leading to \\D\\ complete imputed dataset for bootstrap sample \\b\\.

- For sensitivity analyses, a pre-defined \\\delta\\-adjustment may be
  applied to the imputed data prior to the analysis step. (Section
  [3.5](#sec:deltaAdjustment)).

3.  **Analysis step** (Section [3.6](#sec:analysis))

- Analyze each of the \\B\times D\\ imputed datasets using an analysis
  model (e.g. ANCOVA) resulting in \\B\times D\\ point estimates of the
  treatment effect.

4.  **Pooling step for inference** (Section [3.9](#sec:poolbmlmi))

- Pool the \\B\times D\\ treatment effect estimates as described in von
  Hippel and Bartlett ([2021](#ref-vonHippelBartlett2021)) to obtain the
  final pooled treatment effect estimate, standard error, and degrees of
  freedom.

### 3.2 Setting, notation, and missing data assumptions

Assume that the data are from a study with \\n\\ subjects in total and
that each subject \\i\\ (\\i=1,\ldots,n\\) has \\J\\ scheduled follow-up
visits at which the outcome of interest is assessed. In most
applications, the data will be from a randomized trial of an
intervention vs a control group and the treatment effect of interest is
a comparison in outcomes at a specific visit between these randomized
groups. However, single-arm trials or multi-arm trials are in principle
also supported by the `rbmi` implementation.

Denote the observed outcome vector of length \\J\\ for subject \\i\\ by
\\Y_i\\ (with missing assessments coded as NA (not available)) and its
non-missing and missing components by \\Y\_{i!}\\ and \\Y\_{i?}\\,
respectively. By default, imputation of missing outcomes in \\Y\_{i}\\
is performed under a MAR assumption in `rbmi`. Therefore, if missing
data following an ICE are to be handled using MAR imputation, this is
compatible with the default assumption. As discussed in Section
[2](#sec:intro), the MAR assumption is often a good starting point for
implementing a hypothetical strategy. But also note that observed
outcome data after an ICE handled using a hypothetical strategy is not
compatible with this strategy. Therefore, we assume that all post-ICE
data after ICEs handled using a hypothetical strategy are already set to
NA in \\Y_i\\ prior calling any `rbmi` functions. However, any observed
outcomes after ICEs handled using a treatment policy strategy should be
included in \\Y_i\\ as they are compatible with this strategy.

Subjects may also experience up to one ICE after which missing data
imputation according to a reference-based imputation method is foreseen.
For a subject \\i\\ with such an ICE, denote their first visit which is
affected by the ICE by \\\tilde{t}\_i \in \\1,\ldots,J\\\\. For all
other subjects, set \\\tilde{t}\_i=\infty\\. A subject’s outcome vector
after setting observed outcomes from visit \\\tilde{t}\_i\\ onwards to
missing (i.e. NA) is denoted as \\Y'\_i\\ and the corresponding data
vector after removal of NA elements as \\Y'\_{i!}\\.

MNAR \\\delta\\-adjustments are added to the imputed datasets after the
formal imputation steps. This is covered in a separate section (Section
[3.5](#sec:deltaAdjustment)).

### 3.3 The base imputation model

#### 3.3.1 Included data and model specification

The purpose of the imputation model is to estimate (covariate-dependent)
mean trajectories and covariance matrices for each group in the absence
of ICEs handled using reference-based imputation methods.
Conventionally, publications on reference-based imputation methods have
implicitly assumed that the corresponding post-ICE data is missing for
all subjects (Carpenter, Roger, and Kenward
([2013](#ref-CarpenterEtAl2013))). We also allow the situation where
post-ICE data is available for some subjects but needs to be imputed
using reference-based methods for others. However, any observed data
after ICEs for which reference-based imputation methods are specified is
not compatible with the imputation model described below and they are
therefore removed and considered as missing for the purpose of
estimating the imputation model, and for this purpose only. For example,
if a patient has an ICE addressed with a reference-based method but
outcomes after the ICE are collected, these post-ICE outcomes will be
excluded when fitting the base imputation model (but they will be
included again in the following steps). That is, the base imputation
model is fitted to \\Y'\_{i!}\\ and not to \\Y\_{i!}\\. If we did not
exclude these data, then the imputation model would mistakenly estimate
mean trajectories based on a mixture of observed pre- and post-ICE data
which are not relevant for reference-based imputations.

Observed post-ICE outcomes in the control or reference group are also
excluded from the base imputation model if the user specifies a
reference-based imputation strategy for such ICEs. This ensures that an
ICE has the same impact on the data included in the imputation model
regardless whether the ICE occurred in the control or the intervention
group. On the other hand, imputation in the reference group is based on
a MAR assumption even for reference-based imputation methods and it may
be preferable in some settings to include post-ICE data from the control
group in the base imputation model. This can be implemented by
specifying a `MAR` strategy for the ICE in the control group and a
reference-based strategy for the same ICE in the intervention group.

The base imputation model of the longitudinal outcomes \\Y'\_i\\ assumes
that the mean structure is a linear function of covariates. Full
flexibility for the specification of the linear predictor of the model
is supported. At a minimum the covariates should include the treatment
group, the (categorical) visit, and treatment-by-visit interactions.
Typically, other covariates including the baseline outcome are also
included. External time-varying covariates (e.g. calendar time of the
visit) as well as internal time-varying (e.g. time-varying indicators of
treatment discontinuation or initiation of rescue treatment) may in
principle also be included if indicated (Guizzaro et al.
([2021](#ref-Guizzaro2021))). Missing covariate values are not allowed.
This means that the values of time-varying covariates must be
non-missing at every visit regardless of whether the outcome is measured
or missing.

Denote the \\J\times p\\ design matrix for subject \\i\\ corresponding
to the mean structure model by \\X_i\\ and the same matrix after removal
of rows corresponding to missing outcomes in \\Y'\_{i!}\\ by
\\X'\_{i!}\\. Here \\p\\ is the number of parameters in the mean
structure of the model for the elements of \\Y'\_{i!}\\. The base
imputation model for the observed outcomes is defined as: \\ Y'\_{i!} =
X'\_{i!}\beta + \epsilon\_{i!} \mbox{ with } \epsilon\_{i!}\sim
N(0,\Sigma\_{i!!})\\ where \\\beta\\ is the vector of regression
coefficients and \\\Sigma\_{i!!}\\ is a covariance matrix which is
obtained from the complete-data \\J\times J\\-covariance matrix
\\\Sigma\\ by omitting rows and columns corresponding to missing outcome
assessments for subject \\i\\.

Typically, a common unstructured covariance matrix for all subjects is
assumed for \\\Sigma\\ but separate covariate matrices per treatment
group are also supported. Indeed, the implementation also supports the
specification of separate covariate matrices according to an arbitrarily
defined categorical variable which groups the subjects into disjoint
subset. For example, this could be useful if different covariance
matrices are suspected in different subject strata. Finally, for all
imputation methods described below, there is further flexibility in the
choice of the covariance structure, i.e. unstructured (default),
(heterogeneous) Toeplitz, (heterogeneous) compound symmetry, and
(heterogeneous) AR(1) covariance structures are supported.

#### 3.3.2 Restricted maximum likelihood estimation (REML)

Frequentist parameter estimation for the base imputation is based on
REML. The use of REML as an improved alternative to maximum likelihood
(ML) for covariance parameter estimation was originally proposed by
Patterson and Thompson ([1971](#ref-Patterson1971)). Since then, it has
become the default method for parameter estimation in linear mixed
effects models. `rbmi` allows to choose between ML and REML methods to
estimate the model parameters, with REML being the default option.

#### 3.3.3 Bayesian model fitting

The Bayesian imputation model is fitted with the R package `rstan` (Stan
Development Team ([2020](#ref-Rstan))). `rstan` is the R interface of
Stan. Stan is a powerful and flexible statistical software developed by
a dedicated team and implements Bayesian inference with state-of-the-art
MCMC sampling procedures. The multivariate normal model with missing
data specified in section [3.3.1](#sec:imputationModelSpecs) can be
considered a generalization of the models described in the Stan user’s
guide (see Stan Development Team ([2020, sec. 3.5](#ref-Rstan))).

As in the “five macros”, the MCMC algorithm is initialized at the
parameters from a frequentist REML fit (see section
[3.3.2](#sec:imputationModelREML)). As described below, we are using
only weakly informative priors for the parameters. Therefore, the Markov
chain is essentially starting from the targeted stationary posterior
distribution and only a minimal amount of burn-in of the chain is
required.

We now describe the available combinations of covariance models and
prior specifications.

##### 3.3.3.1 Inverse Wishart prior for unstructured covariance matrix

By default, the same prior distributions as in the SAS implementation of
the “five macros” are used (Roger ([2021](#ref-FiveMacros))), i.e. an
improper flat priors for the regression coefficients and a weakly
informative inverse Wishart prior for the covariance matrix (or
matrices). Specifically, let \\S \in \mathbb{R}^{J \times J}\\ be a
symmetric positive definite matrix and \\\nu \in (J-1, \infty)\\. Then
the symmetric positive definite matrix \\x \in \mathbb{R}^{J \times J}\\
has density: \\ \text{InvWish}(x \vert \nu, S) = \frac{1}{2^{\nu J/2}}
\frac{1}{\Gamma_J(\frac{\nu}{2})} \vert S \vert^{\nu/2} \vert x \vert
^{-(\nu + J + 1)/2} \text{exp}\left(-\frac{1}{2}
\text{tr}(Sx^{-1})\right). \\ For \\\nu \> J+1\\ the mean is given by:
\\ E\[x\] = \frac{S}{\nu - J - 1}. \\ We choose \\S\\ equal to the
estimated covariance matrix from the frequentist REML fit and \\\nu =
J+2\\ as these are the lowest degrees of freedom that guarantee a finite
mean. Setting the degrees of freedom with such a low \\\nu\\ ensures
that the prior has little impact on the posterior. Moreover, this choice
allows to interpret the parameter \\S\\ as the mean of the prior
distribution.

##### 3.3.3.2 LKJ and scaled inverse chi-squared priors for unstructured covariance matrix

Alternatively, the user can specify to use an LKJ prior for the
unstructured correlation matrix, combined with independent scaled
inverse chi-squared priors for the variances. The LKJ prior has density
proportional to 1, i.e. it is a uniform prior on the space of
correlation matrices.

For a single variance \\y\\, we use a scaled inverse chi-square prior
with density given by:

\\ \text{ScaledInvChiSquare}(y \vert \nu,\sigma) = \frac{(\nu /
2)^{1\nu/2}}{\Gamma(\nu / 2)} \\ \sigma^\nu \\ y^{-(\nu/2 + 1)} \\ \exp
\\ \left( \\ - \\ \frac{1}{2} \\ \nu\\ \sigma^2 \\ \frac{1}{y} \right)
\\

This distribution is a special case of the inverse-Wishart distribution
for a univariate random variable. Similarly as above, also here we use
\\\nu = 3\\ degrees of freedom to guarantee a finite mean. The scale
parameter \\\sigma\\ is set to the estimated standard deviation from the
frequentist REML fit, which leads to the prior mean for the variance
\\y\\ to be equal to the estimated variance from the frequentist REML
fit.

##### 3.3.3.3 Autoregressive order 1 covariance structure

For the time-homogeneous version of the AR(1) covariance structure (see
[here](https://openpharma.github.io/mmrm/latest-tag/articles/covariance.html#homogeneous-ar1-and-heterogeneous-ar1h-autoregressive)),
we use a uniform prior on the correlation parameter \\\rho\\ and a
scaled inverse chi-square prior for the variance parameter \\\sigma^2\\,
as described above. For the time-heterogeneous version, we simply use
independent scaled inverse chi-square priors for the time-point specific
variances, which are centered around the respective estimated variances
from the frequentist REML fit.

##### 3.3.3.4 Compound symmetry covariance structure

For the compound symmetry covariance structure (see
[here](https://openpharma.github.io/mmrm/latest-tag/articles/covariance.html#homogeneous-cs-and-heterogeneous-csh-compound-symmetry)),
we use a uniform prior on the correlation parameter \\\rho\\ in the
allowed range \\(-1/(J-1), 1)\\. This is because for \\\rho\\ smaller
than the lower boundary, the correlation matrix would not be positive
definite any longer. For the variance parameter(s), we use again scaled
inverse chi-square priors as described above.

##### 3.3.3.5 Antedependence covariance structure

For the antedependence covariance structure (see
[here](https://openpharma.github.io/mmrm/latest-tag/articles/covariance.html#homogeneous-ad-and-heterogeneous-ante-dependence-adh)),
we use uniform priors on the \\J-1\\ correlation parameters \\\rho\_{1},
\dotsc, \rho\_{J-1}\\ in the full range \\(-1, 1)\\. For the variance
parameter(s), we use again scaled inverse chi-square priors as described
above.

##### 3.3.3.6 Toeplitz covariance structure

For the Toeplitz covariance structure (see
[here](https://openpharma.github.io/mmrm/latest-tag/articles/covariance.html#homogeneous-toep-and-heterogeneous-toeplitz-toeph)),
we use a uniform prior on the correlation parameters \\\rho\_{1},
\dotsc, \rho\_{J-1}\\ in the full range \\(-1, 1)\\. For the variance
parameter(s), we use again scaled inverse chi-square priors as described
above.

##### 3.3.3.7 Further options

The initial values and other expert options for the MCMC sampling can be
defined via the `control` argument to `method_bayes`, which is
simplified with the corresponding
[`control_bayes()`](https://insightsengineering.github.io/rbmi/reference/control.md)
function call. With the default initial values, i.e. when using
`init = "mmrm"` in the `control` list, then for obtaining reproducible
results an external [`set.seed()`](https://rdrr.io/r/base/Random.html)
call is required before running
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).
In particular, please note that it is not sufficient to just set the
`seed` option in the `control` list. If more than one chain is being
run, the chains are currently initialized at `"random"` values as per
`rstan` default. Note that for consistency with `rstan`, the burn-in can
be customized via the `warmup` argument, and the burn-between can be
customized via the `thin` argument. Independent of the number of chains
used, the total number of returned samples is always `n_samples`. In the
case that more than one chain is used, these samples are distributed
across the multiple chains appropriately.

#### 3.3.4 Approximate Bayesian posterior draws via the bootstrap

Several authors have suggested that a stabler way to get Bayesian
posterior draws from the imputation model is to bootstrap the incomplete
data and to calculate REML estimates for each bootstrap sample (Little
and Rubin ([2002](#ref-LittleRubin1992)), Efron
([1994](#ref-Efron1994)), Honaker and King ([2010](#ref-Honaker2010)),
von Hippel and Bartlett ([2021](#ref-vonHippelBartlett2021))). This
method is proper in that the REML estimates from the bootstrap samples
are asymptotically equivalent to a sample from the posterior
distribution and may provide additional robustness to model
misspecification (Little and Rubin ([2002, sec.
10.2.3](#ref-LittleRubin1992), part 6), Honaker and King
([2010](#ref-Honaker2010))). In order to retain balance between
treatment groups and stratification factors across bootstrap samples,
the user is able to provide stratification variables for the bootstrap
in the `rbmi` implementation.

### 3.4 Imputation step

#### 3.4.1 Marginal imputation distribution for a subject - MAR case

For each subject \\i\\, the marginal distribution of the complete
\\J\\-dimensional outcome vector from all assessment visits according to
the imputation model is a multivariate normal distribution. Its mean
\\\tilde{\mu}\_i\\ is given by the predicted mean from the imputation
model conditional on the subject’s baseline characteristics, group, and,
optionally, time-varying covariates. Its covariance matrix
\\\tilde{\Sigma}\_i\\ is given by the overall estimated covariance
matrix or, if different covariance matrices are assumed for different
groups, the covariance matrix corresponding to subject \\i\\’s group.

#### 3.4.2 Marginal imputation distribution for a subject - reference-based imputation methods

For each subject \\i\\, we calculate the mean and covariance matrix of
the complete \\J\\-dimensional outcome vector from all assessment visits
as for the MAR case and denote them by \\\mu_i\\ and \\\Sigma_i\\. For
reference-based imputation methods, a corresponding reference group is
also required for each group. Typically, the reference group for the
intervention group will be the control group. The reference mean
\\\mu\_{ref,i}\\ is defined as the predicted mean from the imputation
model conditional on the reference group (rather than the actual group
subject \\i\\ belongs to) and the subject’s baseline characteristics.
The reference covariance matrix \\\Sigma\_{ref,i}\\ is the overall
estimated covariance matrix or, if different covariance matrices are
assumed for different groups, the estimated covariance matrix
corresponding to the reference group. In principle, time-varying
covariates could also be included in reference-based imputation methods.
However, this is only sensible for external time-varying covariates
(e.g. calendar time of the visit) and not for internal time-varying
covariates (e.g. treatment discontinuation) because the latter likely
depend on the actual treatment group and it is typically not sensible to
assume the same trajectory of the time-varying covariate for the
reference group.

Based on these means and covariance matrices, the subject’s marginal
imputation distribution for the reference-based imputation methods is
then calculated as detailed in Carpenter, Roger, and Kenward ([2013,
sec. 4.3](#ref-CarpenterEtAl2013)). Denote the mean and covariance
matrix of this marginal imputation distribution by \\\tilde{\mu}\_i\\
and \\\tilde{\Sigma}\_i\\. Recall that the subject’s first visit which
is affected by the ICE is denoted by \\\tilde{t}\_i \in \\1,\ldots,J\\\\
(and visit \\\tilde{t}\_i-1\\ is the last visit unaffected by the ICE).
The marginal distribution for the patient \\i\\ is then built according
to the specific assumption for the data up to and post the ICE as
follows:

1.  Jump to reference (JR): the patient’s outcome distribution is
    normally distributed with the following mean: \\\tilde{\mu}\_i =
    (\mu_i\[1\], \dots, \mu_i\[\tilde{t}\_i-1\],
    \mu\_{ref,i}\[\tilde{t}\_i\], \dots, \mu\_{ref,i}\[J\])^T.\\ The
    covariance matrix is constructed as follows. First, we partition the
    covariance matrices \\\Sigma_i\\ and \\\Sigma\_{ref,i}\\ in blocks
    according to the time of the ICE \\\tilde{t}\_i\\: \\ \Sigma\_{i} =
    \begin{bmatrix} \Sigma\_{i, 11} & \Sigma\_{i, 12} \\ \Sigma\_{i, 21}
    & \Sigma\_{i,22} \\ \end{bmatrix} \\ \\ \Sigma\_{ref,i} =
    \begin{bmatrix} \Sigma\_{ref, i, 11} & \Sigma\_{ref, i, 12} \\
    \Sigma\_{ref, i, 21} & \Sigma\_{ref, i,22} \\ \end{bmatrix}. \\ We
    want the covariance matrix \\\tilde{\Sigma}\_i\\ to match
    \\\Sigma_i\\ for the pre-deviation measurements, and
    \\\Sigma\_{ref,i}\\ for the conditional components for the
    post-deviation given the pre-deviation measurements. The solution is
    derived in Carpenter, Roger, and Kenward ([2013, sec.
    4.3](#ref-CarpenterEtAl2013)) and is given by: \\ \begin{matrix}
    \tilde{\Sigma}\_{i,11} = \Sigma\_{i, 11} \\ \tilde{\Sigma}\_{i, 21}
    = \Sigma\_{ref,i, 21} \Sigma^{-1}\_{ref,i, 11} \Sigma\_{i, 11} \\
    \tilde{\Sigma}\_{i, 22} = \Sigma\_{ref, i, 22} - \Sigma\_{ref,i, 21}
    \Sigma^{-1}\_{ref,i, 11} (\Sigma\_{ref,i, 11} - \Sigma\_{i,11})
    \Sigma^{-1}\_{ref,i, 11} \Sigma\_{ref,i, 12}. \end{matrix} \\

2.  Copy increments in reference (CIR): the patient’s outcome
    distribution is normally distributed with the following mean: \\
    \begin{split} \tilde{\mu}\_i =& (\mu_i\[1\], \dots,
    \mu_i\[\tilde{t}\_i-1\], \mu_i\[\tilde{t}\_i-1\] +
    (\mu\_{ref,i}\[\tilde{t}\_i\] - \mu\_{ref,i}\[\tilde{t}\_i-1\]),
    \dots,\\ & \mu_i\[\tilde{t}\_i-1\]+(\mu\_{ref,i}\[J\] -
    \mu\_{ref,i}\[\tilde{t}\_i-1\]))^T. \end{split} \\ The covariance
    matrix is derived as for the JR method.

3.  Copy reference (CR): the patient’s outcome distribution is normally
    distributed with mean and covariance matrix taken from the reference
    group: \\ \tilde{\mu}\_i = \mu\_{ref,i} \\ \\ \tilde{\Sigma}\_i =
    \Sigma\_{ref,i}. \\

4.  Last mean carried forward (LMCF): the patient’s outcome distribution
    is normally distributed with the following mean: \\ \tilde{\mu}\_i =
    (\mu_i\[1\], \dots, \mu_i\[\tilde{t}\_i-1\],
    \mu_i\[\tilde{t}\_i-1\], \dots, \mu_i\[\tilde{t}\_i-1\])'\\ and
    covariance matrix: \\ \tilde{\Sigma}\_i = \Sigma_i.\\

#### 3.4.3 Imputation of missing outcome data

The joint marginal multivariate normal imputation distribution of
subject \\i\\’s observed and missing outcome data has mean
\\\tilde{\mu}\_i\\ and covariance matrix \\\tilde{\Sigma}\_i\\ as
defined above. The actual imputation of the missing outcome data is
obtained by conditioning this marginal distribution on the subject’s
observed outcome data. Of note, this approach is valid regardless
whether the subject has intermittent or terminal missing data.

The conditional distribution used for the imputation is again a
multivariate normal distribution and explicit formulas for the
conditional mean and covariance are readily available. For completeness,
we report them here with the notation and terminology of our setting.
The marginal distribution for the outcome of patient \\i\\ is \\Y_i \sim
N(\tilde{\mu}\_i, \tilde{\Sigma}\_i)\\ and the outcome \\Y_i\\ can be
decomposed in the observed (\\Y\_{i,!}\\) and the unobserved
(\\Y\_{i,?}\\) components. Analogously the mean \\\tilde{\mu}\_i\\ can
be decomposed as \\(\tilde{\mu}\_{i,!},\tilde{\mu}\_{i,?})\\ and the
covariance \\\tilde{\Sigma}\_i\\ as: \\ \tilde{\Sigma}\_i =
\begin{bmatrix} \tilde{\Sigma}\_{i, !!} & \tilde{\Sigma}\_{i,!?} \\
\tilde{\Sigma}\_{i, ?!} & \tilde{\Sigma}\_{i, ??} \end{bmatrix}. \\ The
conditional distribution of \\Y\_{i,?}\\ conditional on \\Y\_{i,!}\\ is
then a multivariate normal distribution with expectation \\ E(Y\_{i,?}
\vert Y\_{i,!})= \tilde{\mu}\_{i,?} + \tilde{\Sigma}\_{i, ?!}
\tilde{\Sigma}\_{i,!!}^{-1} (Y\_{i,!} - \tilde{\mu}\_{i,!}) \\ and
covariance matrix \\ Cov(Y\_{i,?} \vert Y\_{i,!}) =
\tilde{\Sigma}\_{i,??} - \tilde{\Sigma}\_{i,?!}
\tilde{\Sigma}\_{i,!!}^{-1} \tilde{\Sigma}\_{i,!?}. \\

Conventional random imputation consists in sampling from this
conditional multivariate normal distribution. Conditional mean
imputation imputes missing values with the deterministic conditional
expectation \\E(Y\_{i,?} \vert Y\_{i,!})\\.

### 3.5 \\\delta\\-adjustment

A *marginal* \\\delta\\-adjustment approach similar to the “five macros”
in SAS is implemented (Roger ([2021](#ref-FiveMacros))), i.e. fixed
non-stochastic values are added after the multivariate normal imputation
step and prior to the analysis. This is relevant for sensitivity
analyses in order to make imputed data systematically worse or better,
respectively, than observed data. In addition, some authors have
suggested \\\delta\\-type adjustments to implement a composite strategy
for continuous outcomes (Darken et al. ([2020](#ref-Darken2020))).

The implementation provides full flexibility regarding the specific
implementation of the \\\delta\\-adjustment, i.e. the value that is
added may depend on the randomized treatment group, the timing of the
subject’s ICE, and other factors. For suggestions and case studies
regarding this topic, we refer to Cro et al.
([2020](#ref-CroEtAlTutorial2020)).

### 3.6 Analysis step

After data imputation, a standard analysis model can be applied to the
completed data resulting in a treatment effect estimate. As the imputed
data no longer contains missing values, the analysis model is often
simple. For example, it can be an analysis of covariance (ANCOVA) model
with the outcome (or the change in the outcome from baseline) at a
specific visit j as the dependent variable, the randomized treatment
group as the primary covariate and, typically, adjustment for the same
baseline covariates as for the imputation model.

### 3.7 Pooling step for inference of (approximate) Bayesian MI and Rubin’s rules

Assume that the analysis model has been applied to \\M\\ multiple
imputed random datasets which resulted in \\m\\ treatment effect
estimates \\\hat{\theta}\_m\\ (\\m=1,\ldots,M\\) with corresponding
standard error \\SE_m\\ and (if available) degrees of freedom
\\\nu\_{com}\\. If degrees of freedom are not available for an analysis
model, set \\\nu\_{com}=\infty\\ for inference based on the normal
distribution.

Rubin’s rules are used for pooling the treatment effect estimates and
corresponding variances estimates from the analysis steps across the
\\M\\ multiple imputed datasets. According to Rubin’s rules, the final
estimate of the treatment effect is calculated as the sample mean over
the \\M\\ treatment effect estimates: \\ \hat{\theta} = \frac{1}{M}
\sum\_{m = 1}^M \hat{\theta}\_m. \\ The pooled variance is based on two
components that reflect the within and the between variance of the
treatment effects across the multiple imputed datasets: \\
V(\hat{\theta}) = V_W(\hat{\theta}) + (1 + \frac{1}{M})
V_B(\hat{\theta}) \\ where \\V_W(\hat{\theta}) = \frac{1}{M}\sum\_{m =
1}^M SE^2_m\\ is the within-variance and \\V_B(\hat{\theta}) =
\frac{1}{M-1} \sum\_{m = 1}^M (\hat{\theta}\_m - \hat{\theta})^2\\ is
the between-variance.

Confidence intervals and tests of the null hypothesis \\H_0:
\theta=\theta_0\\ are based on the \\t\\-statistics \\T\\:

\\ T= (\hat{\theta}-\theta_0)/\sqrt{V(\hat{\theta})}. \\ Under the null
hypothesis, \\T\\ has an approximate \\t\\-distribution with \\\nu\\
degrees of freedom. \\\nu\\ is calculated according to the Barnard and
Rubin approximation, see Barnard and Rubin ([1999](#ref-Barnard1999))
(formula 3) or Little and Rubin ([2002](#ref-LittleRubin1992)) (formula
(5.24), page 87):

\\ \nu = \frac{\nu\_{old}\* \nu\_{obs}}{\nu\_{old} + \nu\_{obs}} \\ with
\\ \nu\_{old} = \frac{M-1}{\lambda^2} \quad\mbox{and}\quad \nu\_{obs} =
\frac{\nu\_{com} + 1}{\nu\_{com} + 3} \nu\_{com} (1 - \lambda) \\ where
\\\lambda = \frac{(1 + \frac{1}{M})V_B(\hat{\theta})}{V(\hat{\theta})}\\
is the fraction of missing information.

#### 3.7.1 Monte Carlo standard error

The Bayesian approach to multiple imputation yields probabilistic
results. The precision of the MC algorithm can be quantified through the
MC standard error (MCSE). Such quantification is important for judging
the scientific reproducibility of the results, e.g., when computational
parameters such as the seed are changed. For the treatment effect
estimates \\\hat{\theta}\\ obtained through Rubin’s rule as described
above, a closed-form expression for the MCSE exists ([Royston, Carlin,
and White 2009](#ref-Royston2009)):

\\ \text{MCSE}(\hat{\theta}) = \sqrt{V_B(\hat{\theta}) / M} \\

However, since decisions are generally based not just on the treatment
effect estimate but also on the p-value, it is important to calculate
the corresponding MCSE. No closed-form expression exists for the MCSE of
the p-value, but as argued by Royston, Carlin, and White
([2009](#ref-Royston2009)), the jackknife method could be used to
estimate the MCSE ([Efron and Gong 1983](#ref-EfronGong1983)). Let
\\\theta\\ be the parameter of interest (e.g. the p-value) and let
\\\hat{\theta}\_{(-m)}\\ be the jackknife parameter estimate, obtained
from the \\M-1\\ imputed datasets after removing the \\m\\-th imputed
dataset. Also let \\\overline{\theta}\_{(\cdot)} = \sum\_{m = 1}^{M}
\hat{\theta}\_{(-m)} / M\\ be the average of the jackknife parameter
estimates. The MCSE of the overall estimate \\\hat{\theta}\\ is then
given by:

\\ \text{MCSE}(\hat{\theta}) = \sqrt{\frac{M - 1}{M} \sum\_{m=1}^{M}
\left(\hat{\theta}\_{(-m)} - \overline{\theta}\_{(\cdot)}\right)^2} \\

For simplicity, only the latter MCSE formula is implemented for all
parameters.

### 3.8 Bootstrap and jackknife inference for conditional mean imputation

#### 3.8.1 Point estimate of the treatment effect

The point estimator is obtained by applying the analysis model (Section
[3.6](#sec:analysis)) to a single conditional mean imputation of the
missing data (see Section [3.4.3](#sec:imputationRandomConditionalMean))
based on the REML estimator of the parameters of the imputation model
(see Section [3.3.2](#sec:imputationModelREML)). We denote this
treatment effect estimator by \\\hat{\theta}\\.

As demonstrated in Wolbers et al. ([2022](#ref-Wolbers2021)) (Section
2.4), this treatment effect estimator is valid if the analysis model is
an ANCOVA model or, more generally, if the treatment effect estimator is
a linear function of the imputed outcome vector. Indeed, if this is the
case, then the estimator is identical to the pooled treatment effect
across multiple random REML imputation with an infinite number of
imputations and corresponds to a computationally efficient
implementation of a proposal by von Hippel and Bartlett
([2021](#ref-vonHippelBartlett2021)). We expect that the conditional
mean imputation method is also applicable to some other analysis models
(e.g. for general MMRM analysis models) but this has not been formally
justified.

#### 3.8.2 Jackknife standard errors, confidence intervals (CI) and tests for the treatment effect

For a dataset containing \\n\\ subjects, the jackknife standard error
depends on treatment effect estimates \\\hat{\theta}\_{(-b)}\\
(\\b=1,\ldots,n\\) from samples of the original dataset which leave out
the observation from subject \\b\\. As described previously, to obtain
treatment effect estimates for leave-one-subject-out datasets, all steps
of the imputation procedure (i.e. imputation, conditional mean
imputation, and analysis steps) need to be repeated on this new dataset.

Then, the *jackknife standard error* is defined as
\\\hat{se}\_{jack}=\[\frac{(n-1)}{n}\cdot\sum\_{b=1}^{n}
(\hat{\theta}\_{(-b)}-\bar{\theta}\_{(.)})^2\]^{1/2}\\ where
\\\bar{\theta}\_{(.)}\\ denotes the mean of all jackknife estimates
(Efron and Tibshirani ([1994](#ref-EfronTibs1994)), chapter 10). (Note
that this is the same formula as it is used for the MCSE above.) The
corresponding two-sided normal approximation \\1-\alpha\\ CI is defined
as \\\hat{\theta}\pm z^{1-\alpha/2}\cdot \hat{se}\_{jack}\\ where
\\\hat{\theta}\\ is the treatment effect estimate from the original
dataset. Tests of the null hypothesis \\H_0: \theta=\theta_0\\ are then
based on the \\Z\\-score \\Z=(\hat{\theta}-\theta_0)/\hat{se}\_{jack}\\
using a standard normal approximation.

A simulation study reported in Wolbers et al. ([2022](#ref-Wolbers2021))
demonstrated exact protection of the type I error for jackknife-based
inference with a relatively low sample size (n = 100 per group) and a
substantial amount of missing data (\>25% of subjects with an ICE).

#### 3.8.3 Bootstrap standard errors, confidence intervals (CI) and tests for the treatment effect

As an alternative to the jackknife, the bootstrap has also been
implemented in `rbmi` (Efron and Tibshirani
([1994](#ref-EfronTibs1994)), Davison and Hinkley
([1997](#ref-DavisonHinkley1997))).

Two different bootstrap methods are implemented in `rbmi`: Methods based
on the *bootstrap standard error and the normal approximation* and
*percentile bootstrap methods*. Denote the treatment effect estimates
from \\B\\ bootstrap samples by \\\hat{\theta}^\*\_b\\
(\\b=1,\ldots,B\\). The *bootstrap standard error* \\\hat{se}\_{boot}\\
is defined as the empirical standard deviation of the bootstrapped
treatment effect estimates. Confidence intervals and tests based on the
bootstrap standard error can then be constructed in the same way as for
the jackknife. Confidence intervals using the *percentile bootstrap* are
based on empirical quantiles of the bootstrap distribution and
corresponding statistical tests are implemented in `rbmi` via inversion
of the confidence interval. Explicit formulas for bootstrap inference as
implemented in the `rbmi` package and some considerations regarding the
required number of bootstrap samples are included in the Appendix of
Wolbers et al. ([2022](#ref-Wolbers2021)).

A simulation study reported in Wolbers et al. ([2022](#ref-Wolbers2021))
demonstrated a small inflation of the type I error rate for inference
based on the bootstrap standard error (up to \\5.3\\\\ for a nominal
type I error rate of \\5\\\\) for a sample size of n = 100 per group and
a substantial amount of missing data (\>25% of subjects with an ICE).
Based on this simulations, we recommend the jackknife over the bootstrap
for inference because it performed better in our simulation study and is
typically much faster to compute than the bootstrap.

### 3.9 Pooling step for inference of the bootstrapped MI methods

Assume that the analysis model has been applied to \\B\times D\\
multiple imputed random datasets which resulted in \\B\times D\\
treatment effect estimates \\\hat{\theta}\_{bd}\\ (\\b=1,\ldots,B\\;
\\d=1,\ldots,D\\).

The final estimate of the treatment effect is calculated as the sample
mean over the \\B\*D\\ treatment effect estimates: \\ \hat{\theta} =
\frac{1}{BD} \sum\_{b = 1}^B \sum\_{d = 1}^D \hat{\theta}\_{bd}. \\ The
pooled variance is based on two components that reflect the variability
within and between imputed bootstrap samples (von Hippel and Bartlett
([2021](#ref-vonHippelBartlett2021)), formula 8.4): \\ V(\hat{\theta}) =
(1 + \frac{1}{B})\frac{MSB - MSW}{D} + \frac{MSW}{BD} \\

where \\MSB\\ is the mean square between the bootstrapped datasets, and
\\MSW\\ is the mean square within the bootstrapped datasets and between
the imputed datasets:

\\ \begin{align\*} MSB &= \frac{D}{B-1} \sum\_{b = 1}^B
(\bar{\theta\_{b}} - \hat{\theta})^2 \\ MSW &= \frac{1}{B(D-1)} \sum\_{b
= 1}^B \sum\_{d = 1}^D (\theta\_{bd} - \bar{\theta_b})^2 \end{align\*}
\\ where \\\bar{\theta\_{b}}\\ is the mean across the \\D\\ estimates
obtained from random imputation of the \\b\\-th bootstrap sample.

The degrees of freedom are estimated with the following formula (von
Hippel and Bartlett ([2021](#ref-vonHippelBartlett2021)), formula 8.6):

\\ \nu = \frac{(MSB\cdot (B+1) - MSW\cdot B)^2}{\frac{MSB^2\cdot
(B+1)^2}{B-1} + \frac{MSW^2\cdot B}{D-1}} \\

Confidence intervals and tests of the null hypothesis \\H_0:
\theta=\theta_0\\ are based on the \\t\\-statistics \\T\\:

\\ T= (\hat{\theta}-\theta_0)/\sqrt{V(\hat{\theta})}. \\ Under the null
hypothesis, \\T\\ has an approximate \\t\\-distribution with \\\nu\\
degrees of freedom.

### 3.10 Comparison between the implemented approaches

#### 3.10.1 Treatment effect estimation

All approaches provide consistent treatment effect estimates for
standard and reference-based imputation methods in case the analysis
model of the completed datasets is a general linear model such as
ANCOVA. Methods other than conditional mean imputation should also be
valid for other analysis models. The validity of conditional mean
imputation has only been formally demonstrated for analyses using the
general linear model (Wolbers et al. ([2022, sec.
2.4](#ref-Wolbers2021))) though it may also be applicable more widely
(e.g. for general MMRM analysis models).

Treatment effects based on conditional mean imputation are
deterministic. All other methods are affected by Monte Carlo sampling
error and the precision of estimates depends on the number of
imputations or bootstrap samples, respectively.

#### 3.10.2 Standard errors of the treatment effect

All approaches for imputation under a MAR assumption provide consistent
estimates of the frequentist standard error.

For reference-based imputation methods, the situation is more
complicated and two different types of variance estimators have been
proposed in the statistical literature (Bartlett
([2023](#ref-Bartlett2021))). The first is the frequentist variance
which describes the actual repeated sampling variability of the
estimator. If the reference-based missing data assumption is correctly
specified, then the resulting inference based on this variance is
correct in the frequentist sense, i.e. hypothesis tests have
asymptotically correct type I error control and confidence intervals
have correct coverage probabilities under repeated sampling (Bartlett
([2023](#ref-Bartlett2021)), Wolbers et al. ([2022](#ref-Wolbers2021))).
Reference-based missing data assumptions are strong and borrow
information from the reference arm for imputation in the active arm. As
a consequence, the size of frequentist standard errors for treatment
effects may decrease with increasing amounts of missing data. The second
proposal is the so-called “information-anchored” variance which was
originally proposed in the context of sensitivity analyses (Cro,
Carpenter, and Kenward ([2019](#ref-CroEtAl2019))). This variance
estimator is based on disentangling point estimation and variance
estimation altogether. The information-anchoring principle described in
Cro, Carpenter, and Kenward ([2019](#ref-CroEtAl2019)) states that the
relative increase in the variance of the treatment effect estimator
under MAR imputation with increasing amounts of missing data should be
preserved for reference-based imputation methods. The resulting
information-anchored variance is typically very similar to the variance
under MAR imputation and typically increases with increasing amounts of
missing data. However, the information-anchored variance does not
reflect the actual variability of the reference-based estimator under
repeated sampling and the resulting inference is highly conservative
resulting in a substantial power loss (Wolbers et al.
([2022](#ref-Wolbers2021))). Moreover, to date, no Bayesian or
frequentist framework has been developed under which the
information-anchored variance provides correct inference for
reference-based missingness assumptions, nor is it clear whether such a
framework can even be developed.

Reference-based conditional mean imputation
([`method_condmean()`](https://insightsengineering.github.io/rbmi/reference/method.md))
and bootstrapped likelihood-based multiple methods
(`method = method_bmlmi()`) obtain standard errors via resampling and
hence target the frequentist variance (Wolbers et al.
([2022](#ref-Wolbers2021)), von Hippel and Bartlett
([2021](#ref-vonHippelBartlett2021))). For finite samples, simulations
for a sample size of \\n=100\\ per group reported in Wolbers et al.
([2022](#ref-Wolbers2021)) demonstrated that conditional mean imputation
combined with the jackknife (`method_condmean(type = "jackknife")`)
provided exact protection of the type one error rate whereas the
bootstrap (`method_condmean(type = "bootstrap")`) was associated with a
small type I error inflation (between 5.1% to 5.3% for a nominal level
of 5%). For reference-based conditional mean imputation, an alternative
information-anchored variance can be obtained by following a proposal by
Lu ([2021](#ref-Lu2021)). The basic idea of Lu ([2021](#ref-Lu2021)) is
to obtain the information-anchored variance via a MAR imputation
combined with a delta-adjustment where delta is selected in a
data-driven way to match the reference-based estimator. For conditional
mean imputation, the proposal by Lu ([2021](#ref-Lu2021)) can be
implemented by choosing the delta-adjustment as the difference between
the conditional mean imputation under the chosen reference-based
assumption and MAR on the original dataset. An illustration of how the
different variances can be obtained for conditional mean imputation in
`rbmi` is provided in the vignette “Frequentist and information-anchored
inference for reference-based conditional mean imputation”
([`vignette(topic = "CondMean_Inference", package = "rbmi")`](https://insightsengineering.github.io/rbmi/articles/CondMean_Inference.md)).

Reference-based Bayesian (or approximate Bayesian) multiple imputation
methods combined with Rubin’s rules
([`method_bayes()`](https://insightsengineering.github.io/rbmi/reference/method.md)
and
[`method_approxbayes()`](https://insightsengineering.github.io/rbmi/reference/method.md))
target the information-anchored variance (Cro, Carpenter, and Kenward
([2019](#ref-CroEtAl2019))). A frequentist variance for these methods
could in principle be obtained via bootstrap or jackknife re-sampling of
the treatment effect estimates but this would be very computationally
intensive and is not directly supported by `rbmi`.

Our view is that for primary analyses, accurate type I error control
(which can be obtained by using the frequentist variance) is more
important than adherence to the information anchoring principle which,
to us, is not fully compatible with the strong reference-based
assumptions. In any case, if reference-based imputation is used for the
primary analysis, it is critical that the chosen reference-based
assumption can be clinically justified, and that suitable sensitivity
analyses are conducted to stress-test these assumptions.

Conditional mean imputation combined with the jackknife is the only
method which leads to deterministic standard error estimates and,
consequently, confidence intervals and \\p\\-values are also
deterministic. This is particularly important in a regulatory setting
where it is important to ascertain whether a calculated \\p\\-value
which is close to the critical boundary of 5% is truly below or above
that threshold rather than being uncertain about this because of Monte
Carlo error.

#### 3.10.3 Computational complexity

Bayesian MI methods rely on the specification of prior distributions and
the usage of Markov chain Monte Carlo (MCMC) methods. All other methods
based on multiple imputation or bootstrapping require no other tuning
parameters than the specification of the number of imputations \\M\\ or
bootstrap samples \\B\\ and rely on numerical optimization for fitting
the MMRM imputation models via REML. Conditional mean imputation
combined with the jackknife has no tuning parameters.

In our `rbmi` implementation, the fitting of the MMRM imputation model
via REML is computationally most expensive. MCMC sampling using `rstan`
(Stan Development Team ([2020](#ref-Rstan))) is typically relatively
fast in our setting and requires only a small warmup phase and thinning
of the chains. In addition, the number of random imputations for
reliable inference using Rubin’s rules is often smaller than the number
of resamples required for the jackknife or the bootstrap (see e.g. the
discussions in I. R. White, Royston, and Wood ([2011, sec.
7](#ref-White2011multiple)) for Bayesian MI and the Appendix of Wolbers
et al. ([2022](#ref-Wolbers2021)) for the bootstrap). Thus, for many
applications, we expect that conventional MI based on Bayesian posterior
draws will be fastest, followed by conventional MI using approximate
Bayesian posterior draws and conditional mean imputation combined with
the jackknife. Conditional mean imputation combined with the bootstrap
and bootstrapped MI methods will typically be most computationally
demanding. Of note, all implemented methods are conceptually
straightforward to parallelise and some parallelisation support is
provided by `rbmi`.

## 4 Mapping of statistical methods to `rbmi` functions

For a full documentation of the `rbmi` package functionality we refer to
the help pages of all functions and to the other package vignettes. Here
we only give a brief overview of how the different steps of the
imputation procedure are mapped to `rbmi` functions:

- The base imputation model fitting step is implemented in the function
  [`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).
  The chosen MI approach can be set using the argument `method` and
  should be one of the following:
  - Bayesian posterior parameter draws from the imputation model are
    obtained via the argument `method = method_bayes()`.
  - Approximate Bayesian posterior parameter draws from the imputation
    model are obtained via argument `method = method_approxbayes()`.
  - ML or REML parameter estimates of the imputation model parameters
    for the original dataset and all leave-one-subject-out datasets (as
    required for the jackknife) are obtained via argument
    `method = method_condmean(type = "jackknife")`.
  - ML or REML parameter estimates of the imputation model parameters
    for the original dataset and bootstrapped datasets are obtained via
    argument `method = method_condmean(type = "bootstrap")`.
  - Bootstrapped MI methods are obtained via argument
    `method = method_bmlmi(B=B, D=D)` where \\B\\ refers to the number
    of bootstrap samples and \\D\\ to the number of random imputations
    for each bootstrap sample.
- The imputation step using random imputation or deterministic
  conditional mean imputation, respectively, is implemented in function
  [`impute()`](https://insightsengineering.github.io/rbmi/reference/impute.md).
  Imputation can be performed assuming the already implemented
  imputation strategies as presented in section
  [3.4](#sec:imputationStep). Additionally, user-defined imputation
  strategies are also supported.
- The analysis step is implemented in function
  [`analyse()`](https://insightsengineering.github.io/rbmi/reference/analyse.md)
  and applies the analysis model to all imputed datasets. By default,
  the analysis model (argument `fun`) is the
  [`ancova()`](https://insightsengineering.github.io/rbmi/reference/ancova.md)
  function but alternative analysis functions can also be provided by
  the user. The
  [`analyse()`](https://insightsengineering.github.io/rbmi/reference/analyse.md)
  function also allows for \\\delta\\-adjustments to the imputed
  datasets prior to the analysis via argument `delta`.
- The inference step is implemented in function
  [`pool()`](https://insightsengineering.github.io/rbmi/reference/pool.md)
  which pools the results across imputed datasets. The Rubin and Bernard
  rule is applied in case of (approximate) Bayesian MI, with
  [`mcse()`](https://insightsengineering.github.io/rbmi/reference/pool.md)
  implementing the MCSE. For conditional mean imputation, jackknife and
  bootstrap (normal approximation or percentile) inference is supported.
  For BMLMI, the pooling and inference steps are performed via
  [`pool()`](https://insightsengineering.github.io/rbmi/reference/pool.md)
  which in this case implements the method described in Section
  [3.9](#sec:poolbmlmi).

## 5 Comparison to other software implementations

An established software implementation of reference-based imputation in
SAS are the so-called “five macros” by James Roger (Roger
([2021](#ref-FiveMacros))). An alternative `R` implementation which is
also currently under development is the R package `RefBasedMI` (McGrath
and White ([2021](#ref-RefbasedMIpackage))).

`rbmi` has several features which are not supported by the other
implementations:

1.  In addition to the Bayesian MI approach implemented also in the
    other packages, our implementation provides three alternative MI
    approaches: approximate Bayesian MI, conditional mean imputation
    combined with resampling, and bootstrapped MI.

2.  `rbmi` allows for the usage of data collected after an ICE. For
    example, suppose that we want to adopt a treatment policy strategy
    for the ICE “treatment discontinuation”. A possible implementation
    of this strategy is to use the observed outcome data for subjects
    who remain in the study after the ICE and to use reference-based
    imputation in case the subject drops out. In our implementation,
    this is implemented by excluding observed post ICE data from the
    imputation model which assumes MAR missingness but including them in
    the analysis model. To our knowledge, this is not directly supported
    by the other implementations.

3.  `RefBasedMI` fits the imputation model to data from each treatment
    group separately which implies covariate-treatment group
    interactions for all covariates for the pooled data from both
    treatment groups. In contrast, Roger’s five macros assume a joint
    model including data from all the randomized groups and
    covariate-treatment interactions covariates are not allowed. We also
    chose to implement a joint model but use a flexible model for the
    linear predictor which may or may not include an interaction term
    between any covariate and the treatment group. In addition, our
    imputation model also allows for the inclusion of time-varying
    covariates.

4.  In our implementation, the grouping of the subjects for the purpose
    of the imputation model (and the definition of the reference group)
    does not need to correspond to the assigned treatment groups. This
    provides additional flexibility for the imputation procedure. It is
    not clear to us whether this feature is supported by Roger’s five
    macros or `RefBasedMI`.

5.  We believe that our R-based implementation is more modular than
    `RefBasedMI` which should facilitate further package enhancements.

In contrast, the more general causal model introduced by I. White,
Royes, and Best ([2020](#ref-White2020causal)) is available in the other
implementations but is currently not supported by ours.

## References

Barnard, John, and Donald B Rubin. 1999. “Miscellanea. Small-Sample
Degrees of Freedom with Multiple Imputation.” *Biometrika* 86 (4):
948–55.

Bartlett, Jonathan W. 2023. “Reference-Based Multiple Imputation - What
Is the Right Variance and How to Estimate It.” *Statistics in
Biopharmaceutical Research* 15 (1): 178–86.

Bell, James, Thomas Drury, Tobias Mütze, Christian Bressen Pipper,
Lorenzo Guizzaro, Marian Mitroiu, Khadija Rerhou Rantell, Marcel
Wolbers, and David Wright. 2025. “Estimation Methods for Estimands Using
the Treatment Policy Strategy; a Simulation Study Based on the PIONEER 1
Trial.” *Pharmaceutical Statistics* 24 (2): e2472.
https://doi.org/<https://doi.org/10.1002/pst.2472>.

Carpenter, James R, James H Roger, and Michael G Kenward. 2013.
“Analysis of Longitudinal Trials with Protocol Deviation: A Framework
for Relevant, Accessible Assumptions, and Inference via Multiple
Imputation.” *Journal of Biopharmaceutical Statistics* 23 (6): 1352–71.

Cro, Suzie, James R Carpenter, and Michael G Kenward. 2019.
“Information-Anchored Sensitivity Analysis: Theory and Application.”
*Journal of the Royal Statistical Society: Series A (Statistics in
Society)* 182 (2): 623–45.

Cro, Suzie, Tim P Morris, Michael G Kenward, and James R Carpenter.
2020. “Sensitivity Analysis for Clinical Trials with Missing Continuous
Outcome Data Using Controlled Multiple Imputation: A Practical Guide.”
*Statistics in Medicine* 39 (21): 2815–42.

Darken, Patrick, Jack Nyberg, Shaila Ballal, and David Wright. 2020.
“The Attributable Estimand: A New Approach to Account for Intercurrent
Events.” *Pharmaceutical Statistics* 19 (5): 626–35.

Davison, Anthony C, and David V Hinkley. 1997. *Bootstrap Methods and
Their Application*. Cambridge University Press.

Drury, Thomas, Juan J Abellan, Nicky Best, and Ian R White. 2024.
“Estimation of Treatment Policy Estimands for Continuous Outcomes Using
Off-Treatment Sequential Multiple Imputation.” *Pharmaceutical
Statistics*.

Efron, Bradley. 1994. “Missing Data, Imputation, and the Bootstrap.”
*Journal of the American Statistical Association* 89 (426): 463–75.

Efron, Bradley, and Gail Gong. 1983. “A Leisurely Look at the Bootstrap,
the Jackknife, and Cross-Validation.” *The American Statistician* 37
(1): 36–48.
<https://www.tandfonline.com/doi/abs/10.1080/00031305.1983.10483087>.

Efron, Bradley, and Robert J Tibshirani. 1994. *An Introduction to the
Bootstrap*. CRC press.

Guizzaro, Lorenzo, Frank Pétavy, Robin Ristl, and Ciro Gallo. 2021. “The
Use of a Variable Representing Compliance Improves Accuracy of
Estimation of the Effect of Treatment Allocation Regardless of
Discontinuation in Trials with Incomplete Follow-up.” *Statistics in
Biopharmaceutical Research* 13 (1): 119–27.

Honaker, James, and Gary King. 2010. “What to Do about Missing Values in
Time-Series Cross-Section Data.” *American Journal of Political Science*
54 (2): 561–81.

ICH E9 working group. 2019. “ICH E9 (R1): Addendum on estimands and
sensitivity analysis in clinical trials to the guideline on statistical
principles for clinical trials.” International Council for Harmonisation
of Technical Requirements for Pharmaceuticals for Human Use. 2019.
<https://database.ich.org/sites/default/files/E9-R1_Step4_Guideline_2019_1203.pdf>.

Little, Roderick JA, and Donald B Rubin. 2002. *Statistical Analysis
with Missing Data, Second Edition*. John Wiley & Sons.

Lu, Kaifeng. 2021. “An Alternative Implementation of Reference-Based
Controlled Imputation Procedures.” *Statistics in Biopharmaceutical
Research* 13 (4): 483–91.

Mallinckrodt, CH, J Bell, G Liu, B Ratitch, M O’Kelly, I Lipkovich, P
Singh, L Xu, and G Molenberghs. 2020. “Aligning Estimators with
Estimands in Clinical Trials: Putting the ICH E9 (R1) Guidelines into
Practice.” *Therapeutic Innovation & Regulatory Science* 54 (2): 353–64.

McGrath, Kevin, and Ian White. 2021. “RefBasedMI: Reference-Based
Imputation for Longitudinal Clinical Trials with Protocol Deviation.”
<https://github.com/UCL/RefbasedMI>.

Noci, Alessandro, Marcel Wolbers, Markus Abt, Corine Baayen, Hans Ulrich
Burger, Man Jin, and Weining Zhao Robieson. 2023. “A Comparison of
Estimand and Estimation Strategies for Clinical Trials in Early
Parkinson’s Disease.” *Statistics in Biopharmaceutical Research* 15 (3):
491–501.

Patterson, H Desmond, and Robin Thompson. 1971. “Recovery of Inter-Block
Information When Block Sizes Are Unequal.” *Biometrika* 58 (3): 545–54.

Polverejan, Elena, and Vladimir Dragalin. 2020. “Aligning Treatment
Policy Estimands and Estimators—a Simulation Study in Alzheimer’s
Disease.” *Statistics in Biopharmaceutical Research* 12 (2): 142–54.

Roger, James. 2021. “Reference-Based MI via Multivariate Normal RM (the
‘Five Macros’ and MIWithD).”
<https://www.lshtm.ac.uk/research/centres-projects-groups/missing-data#dia-missing-data>.

Royston, Patrick, John B. Carlin, and Ian R. White. 2009. “Multiple
Imputation of Missing Values: New Features for Mim.” *The Stata Journal*
9 (2): 252–64.
<https://journals.sagepub.com/doi/pdf/10.1177/1536867X0900900205>.

Stan Development Team. 2020. “RStan: The R Interface to Stan.”
<https://mc-stan.org/>.

von Hippel, Paul T, and Jonathan W Bartlett. 2021. “Maximum Likelihood
Multiple Imputation: Faster Imputations and Consistent Standard Errors
Without Posterior Draws.” *Statistical Science* 36 (3): 400–420.

White, Ian R, Patrick Royston, and Angela M Wood. 2011. “Multiple
Imputation Using Chained Equations: Issues and Guidance for Practice.”
*Statistics in Medicine* 30 (4): 377–99.

White, Ian, Joseph Royes, and Nicky Best. 2020. “A Causal Modelling
Framework for Reference-Based Imputation and Tipping Point Analysis in
Clinical Trials with Quantitative Outcome.” *Journal of
Biopharmaceutical Statistics* 30 (2): 334–50.

Wolbers, Marcel, Alessandro Noci, Paul Delmar, Craig Gower-Page, Sean
Yiu, and Jonathan W Bartlett. 2022. “Standard and Reference-Based
Conditional Mean Imputation.” *Pharmaceutical Statistics* 21 (6):
1246–57.
