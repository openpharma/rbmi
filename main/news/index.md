# Changelog

## rbmi 1.5.2

CRAN release: 2025-10-28

### Bug Fixes

- Disable caching in tests on CRAN and reduce tests run on CRAN to
  conform to 10-minute limit

## rbmi 1.5.1

CRAN release: 2025-10-14

### Bug Fixes

- Modify caching in tests to speed up testing on CRAN.

## rbmi 1.5.0

### New Features

- All covariance structures are now also supported for Bayesian multiple
  imputation:
  [`method_bayes()`](https://insightsengineering.github.io/rbmi/reference/method.md)
  gained additional `covariance` and `prior_cov` arguments to allow
  users to specify the covariance structure and prior for the Bayesian
  imputation model. Please see the updated statistical specifications
  vignette for details.
  ([\#501](https://github.com/insightsengineering/rbmi/issues/501),
  [\#518](https://github.com/insightsengineering/rbmi/issues/518))
- New function
  [`mcse()`](https://insightsengineering.github.io/rbmi/reference/pool.md)
  to calculate the Monte Carlo standard error for pooled estimates from
  (approximate) Bayesian imputation.
  ([\#493](https://github.com/insightsengineering/rbmi/issues/493))

### Bug Fixes

- Fixed cluster used in parallel test and make sure tests clean up Stan
  files properly.
  ([\#523](https://github.com/insightsengineering/rbmi/issues/523))
- Small updates and fixes to documentation.
  ([\#504](https://github.com/insightsengineering/rbmi/issues/504),
  [\#506](https://github.com/insightsengineering/rbmi/issues/506),
  [\#498](https://github.com/insightsengineering/rbmi/issues/498))

## rbmi 1.4.1

CRAN release: 2025-03-03

### Bug Fixes

- Fixed Stan related bug that caused unit tests to fail on machines
  compiling with the C23 standard
  ([\#481](https://github.com/insightsengineering/rbmi/issues/481))
- Fixed bug in unit test that caused false-positive reproducibility
  errors
  ([\#483](https://github.com/insightsengineering/rbmi/issues/483))

## rbmi 1.4.0

CRAN release: 2025-02-07

### Breaking Changes

- Deprecated the `burn_in` and `burn_between` arguments in
  [`method_bayes()`](https://insightsengineering.github.io/rbmi/reference/method.md)
  in favour of using the `warmup` and `thin` arguments, respectively, in
  the new `control` list produced by `control_bayes`. This is to align
  with the `rstan` package.
  ([\#477](https://github.com/insightsengineering/rbmi/issues/477))

### New Features

- Added
  [`control_bayes()`](https://insightsengineering.github.io/rbmi/reference/control.md)
  function to allow expert users to specify additional control arguments
  for the MCMC computations using `rstan`.
  ([\#477](https://github.com/insightsengineering/rbmi/issues/477))

### Bug Fixes

- Fixed bug where `lsmeans(.weights = "proportional_em")` would error if
  there was only a single categorical variable in the dataset.
  ([\#412](https://github.com/insightsengineering/rbmi/issues/412))
- Removed native pipes `|>` and lambda functions `\(x)` from code base
  to ensure package is backwards compatible with older versions of R.
  ([\#474](https://github.com/insightsengineering/rbmi/issues/474))

## rbmi 1.3.1

CRAN release: 2024-12-11

- Fixed bug where stale caches of the `rstan` model were not being
  correctly cleared
  ([\#459](https://github.com/insightsengineering/rbmi/issues/459))

## rbmi 1.3.0

CRAN release: 2024-10-16

### Breaking Changes

- Convert `rstan` to be a suggested package to simplify the installation
  process. This means that the Bayesian imputation functionality will
  not be available by default. To use this feature, you will need to
  install `rstan` separately
  ([\#441](https://github.com/insightsengineering/rbmi/issues/441))
- Deprecated the `seed` argument to
  [`method_bayes()`](https://insightsengineering.github.io/rbmi/reference/method.md)
  in favour of using the base
  [`set.seed()`](https://rdrr.io/r/base/Random.html) function
  ([\#431](https://github.com/insightsengineering/rbmi/issues/431))

### New Features

- Added vignette on how to implement retrieved dropout models with
  time-varying intercurrent event (ICE) indicators
  ([\#414](https://github.com/insightsengineering/rbmi/issues/414))
- Added vignette on how to obtain frequentist and information-anchored
  inference with conditional mean imputation using `rbmi`
  ([\#406](https://github.com/insightsengineering/rbmi/issues/406))
- Added FAQ vignette including a statement on validation
  ([\#407](https://github.com/insightsengineering/rbmi/issues/407)
  [\#440](https://github.com/insightsengineering/rbmi/issues/440))
- Updates to
  [`lsmeans()`](https://insightsengineering.github.io/rbmi/reference/lsmeans.md)
  for better consistency with the `emmeans` package
  ([\#412](https://github.com/insightsengineering/rbmi/issues/412))
  - Renamed `lsmeans(..., weights = "proportional")` to
    `lsmeans(..., weights = "counterfactual")`to more accurately reflect
    the weights used in the calculation.
  - Added `lsmeans(..., weights = "proportional_em")` which provides
    consistent results with `emmeans(..., weights = "proportional")`
  - `lsmeans(..., weights = "proportional")` has been left in the
    package for backwards compatibility and is an alias for
    `lsmeans(..., weights = "counterfactual")` but now gives a message
    prompting users to use either “proptional_em” or “counterfactual”
    instead.
- Added support for parallel processing in the
  [`analyse()`](https://insightsengineering.github.io/rbmi/reference/analyse.md)
  function
  ([\#370](https://github.com/insightsengineering/rbmi/issues/370))
- Added documentation clarifying potential false-positive warnings from
  rstan
  ([\#288](https://github.com/insightsengineering/rbmi/issues/288))
- Added support for all covariance structures supported by the `mmrm`
  package
  ([\#437](https://github.com/insightsengineering/rbmi/issues/437))
- Updated `rbmi` citation detail
  ([\#423](https://github.com/insightsengineering/rbmi/issues/423)
  [\#425](https://github.com/insightsengineering/rbmi/issues/425))

### Miscellaneous Bug Fixes

- Stopped warning messages being accidentally supressed when changing
  the ICE type in
  [`impute()`](https://insightsengineering.github.io/rbmi/reference/impute.md)
  ([\#408](https://github.com/insightsengineering/rbmi/issues/408))
- Fixed equations not rendering properly in the `pkgdown` website
  ([\#433](https://github.com/insightsengineering/rbmi/issues/433))

## rbmi 1.2.6

CRAN release: 2023-11-24

- Updated unit tests to fix false-positive error on CRAN’s testing
  servers

## rbmi 1.2.5

CRAN release: 2023-09-20

- Updated internal Stan code to ensure future compatibility
  ([@andrjohns](https://github.com/andrjohns),
  [\#390](https://github.com/insightsengineering/rbmi/issues/390))
- Updated package description to include relevant references
  ([\#393](https://github.com/insightsengineering/rbmi/issues/393))
- Fixed documentation typos
  ([\#393](https://github.com/insightsengineering/rbmi/issues/393))

## rbmi 1.2.3

CRAN release: 2022-11-14

- Minor internal tweaks to ensure compatibility with the packages `rbmi`
  depends on

## rbmi 1.2.1

CRAN release: 2022-10-25

- Removed native pipes `|>` in testing code so package is backwards
  compatible with older servers
- Replaced our `glmmTMB` dependency with the `mmrm` package. This has
  resulted in the package being more stable (less model fitting
  convergence issues) as well as speeding up run times 3-fold.

## rbmi 1.1.4

CRAN release: 2022-05-18

- Updated urls for references in vignettes
- Fixed a bug where visit factor levels were re-constructed incorrectly
  in
  [`delta_template()`](https://insightsengineering.github.io/rbmi/reference/delta_template.md)
- Fixed a bug where the wrong visit was displayed in the error message
  for when a specific visit doesn’t have any data in
  [`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md)
- Fixed a bug where the wrong input parameter was displayed in an error
  message in
  [`simulate_data()`](https://insightsengineering.github.io/rbmi/reference/simulate_data.md)

## rbmi 1.1.1 & 1.1.3

CRAN release: 2022-03-08

- No change in functionality from 1.1.0
- Various minor tweaks to address CRAN checks messages

## rbmi 1.1.0

CRAN release: 2022-03-02

- Initial public release
