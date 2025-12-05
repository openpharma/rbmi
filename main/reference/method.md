# Set the multiple imputation methodology

These functions determine what methods `rbmi` should use when creating
the imputation models, generating imputed values and pooling the
results.

## Usage

``` r
method_bayes(
  covariance = c("us", "ad", "adh", "ar1", "ar1h", "cs", "csh", "toep", "toeph"),
  same_cov = TRUE,
  n_samples = 20,
  prior_cov = c("default", "lkj"),
  control = control_bayes(),
  burn_in = NULL,
  burn_between = NULL
)

method_approxbayes(
  covariance = c("us", "ad", "adh", "ar1", "ar1h", "cs", "csh", "toep", "toeph"),
  threshold = 0.01,
  same_cov = TRUE,
  REML = TRUE,
  n_samples = 20
)

method_condmean(
  covariance = c("us", "ad", "adh", "ar1", "ar1h", "cs", "csh", "toep", "toeph"),
  threshold = 0.01,
  same_cov = TRUE,
  REML = TRUE,
  n_samples = NULL,
  type = c("bootstrap", "jackknife")
)

method_bmlmi(
  covariance = c("us", "ad", "adh", "ar1", "ar1h", "cs", "csh", "toep", "toeph"),
  threshold = 0.01,
  same_cov = TRUE,
  REML = TRUE,
  B = 20,
  D = 2
)
```

## Arguments

- covariance:

  a character string that specifies the structure of the covariance
  matrix to be used in the imputation model. Must be one of `"us"`
  (default), `"ad"`, `"adh"`, `"ar1"`, `"ar1h"`, `"cs"`, `"csh"`,
  `"toep"`, or `"toeph"`). See details.

- same_cov:

  a logical, if `TRUE` the imputation model will be fitted using a
  single shared covariance matrix for all observations. If `FALSE` a
  separate covariance matrix will be fit for each group as determined by
  the `group` argument of
  [`set_vars()`](https://insightsengineering.github.io/rbmi/reference/set_vars.md).

- n_samples:

  a numeric that determines how many imputed datasets are generated. In
  the case of `method_condmean(type = "jackknife")` this argument must
  be set to `NULL`. See details.

- prior_cov:

  a character string that specifies the prior used for the covariance
  model parameters. Must be one of `"default"` (default) or `"lkj"` (for
  the unstructured covariance model). See the Statistical Specifications
  vignette for details.

- control:

  a list which specifies further lower level details of the
  computations. Currently only used by `method_bayes()`, please see
  [`control_bayes()`](https://insightsengineering.github.io/rbmi/reference/control.md)
  for details and default settings.

- burn_in:

  deprecated. Please use the `warmup` argument in
  [`control_bayes()`](https://insightsengineering.github.io/rbmi/reference/control.md)
  instead.

- burn_between:

  deprecated. Please use the `thin` argument in
  [`control_bayes()`](https://insightsengineering.github.io/rbmi/reference/control.md)
  instead.

- threshold:

  a numeric between 0 and 1, specifies the proportion of bootstrap
  datasets that can fail to produce valid samples before an error is
  thrown. See details.

- REML:

  a logical indicating whether to use REML estimation rather than
  maximum likelihood.

- type:

  a character string that specifies the resampling method used to
  perform inference when a conditional mean imputation approach (set via
  `method_condmean()`) is used. Must be one of `"bootstrap"` or
  `"jackknife"`.

- B:

  a numeric that determines the number of bootstrap samples for
  `method_bmlmi`.

- D:

  a numeric that determines the number of random imputations for each
  bootstrap sample. Needed for `method_bmlmi()`.

## Details

In the case of `method_condmean(type = "bootstrap")` there will be
`n_samples + 1` imputation models and datasets generated as the first
sample will be based on the original dataset whilst the other
`n_samples` samples will be bootstrapped datasets. Likewise, for
`method_condmean(type = "jackknife")` there will be
`length(unique(data$subjid)) + 1` imputation models and datasets
generated. In both cases this is represented by `n + 1` being displayed
in the print message. In the case that `method_bayes()` is used, and
with the `control` argument the number of chains is set to more than 1,
then the `n_samples` samples will be distributed across the chains. The
total number of returned samples will still be `n_samples`.

The user is able to specify different covariance structures using the
the `covariance` argument. Currently supported structures include:

- Unstructured (`"us"`) (default)

- Ante-dependence (`"ad"`)

- Heterogeneous ante-dependence (`"adh"`)

- First-order auto-regressive (`"ar1"`)

- Heterogeneous first-order auto-regressive (`"ar1h"`)

- Compound symmetry (`"cs"`)

- Heterogeneous compound symmetry (`"csh"`)

- Toeplitz (`"toep"`)

- Heterogeneous Toeplitz (`"toeph"`)

For full details please see
[`mmrm::cov_types()`](https://openpharma.github.io/mmrm/latest-tag/reference/covariance_types.html).

In the case of `method_condmean(type = "bootstrap")`,
`method_approxbayes()` and `method_bmlmi()` repeated bootstrap samples
of the original dataset are taken with an MMRM fitted to each sample.
Due to the randomness of these sampled datasets, as well as limitations
in the optimisers used to fit the models, it is not uncommon that
estimates for a particular dataset can't be generated. In these
instances `rbmi` is designed to throw out that bootstrapped dataset and
try again with another. However to ensure that these errors are due to
chance and not due to some underlying misspecification in the data
and/or model a tolerance limit is set on how many samples can be
discarded. Once the tolerance limit has been reached an error will be
thrown and the process aborted. The tolerance limit is defined as
`ceiling(threshold * n_samples)`. Note that for the jackknife method
estimates need to be generated for all leave-one-out datasets and as
such an error will be thrown if any of them fail to fit.

Please note that at the time of writing (September 2021) Stan is unable
to produce reproducible samples across different operating systems even
when the same seed is used. As such care must be taken when using Stan
across different machines. For more information on this limitation
please consult the Stan documentation
<https://mc-stan.org/docs/2_27/reference-manual/reproducibility-chapter.html>
