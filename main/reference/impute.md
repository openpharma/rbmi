# Create imputed datasets

`impute()` creates imputed datasets based upon the data and options
specified in the call to
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).
One imputed dataset is created per each "sample" created by
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).

## Usage

``` r
impute(
  draws,
  references = NULL,
  update_strategy = NULL,
  strategies = getStrategies()
)

# S3 method for class 'random'
impute(
  draws,
  references = NULL,
  update_strategy = NULL,
  strategies = getStrategies()
)

# S3 method for class 'condmean'
impute(
  draws,
  references = NULL,
  update_strategy = NULL,
  strategies = getStrategies()
)
```

## Arguments

- draws:

  A `draws` object created by
  [`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).

- references:

  A named vector. Identifies the references to be used for
  reference-based imputation methods. Should be of the form
  `c("Group1" = "Reference1", "Group2" = "Reference2")`. If `NULL`
  (default), the references are assumed to be of the form
  `c("Group1" = "Group1", "Group2" = "Group2")`. This argument cannot be
  `NULL` if an imputation strategy (as defined by
  `data_ice[[vars$strategy]]` in the call to
  [draws](https://insightsengineering.github.io/rbmi/reference/draws.md))
  other than `MAR` is set.

- update_strategy:

  An optional `data.frame`. Updates the imputation method that was
  originally set via the `data_ice` option in
  [`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).
  See the details section for more information.

- strategies:

  A named list of functions. Defines the imputation functions to be
  used. The names of the list should mirror the values specified in
  `strategy` column of `data_ice`. Default =
  [`getStrategies()`](https://insightsengineering.github.io/rbmi/reference/getStrategies.md).
  See
  [`getStrategies()`](https://insightsengineering.github.io/rbmi/reference/getStrategies.md)
  for more details.

## Details

`impute()` uses the imputation model parameter estimates, as generated
by
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md),
to first calculate the marginal (multivariate normal) distribution of a
subject's longitudinal outcome variable depending on their covariate
values. For subjects with intercurrent events (ICEs) handled using
non-MAR methods, this marginal distribution is then updated depending on
the time of the first visit affected by the ICE, the chosen imputation
strategy and the chosen reference group as described in Carpenter,
Roger, and Kenward (2013) . The subject's imputation distribution used
for imputing missing values is then defined as their marginal
distribution conditional on their observed outcome values. One dataset
is being generated per set of parameter estimates provided by
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).

The exact manner in how missing values are imputed from this conditional
imputation distribution depends on the `method` object that was provided
to
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md),
in particular:

- Bayes & Approximate Bayes: each imputed dataset contains 1 row per
  subject & visit from the original dataset with missing values imputed
  by taking a single random sample from the conditional imputation
  distribution.

- Conditional Mean: each imputed dataset contains 1 row per subject &
  visit from the bootstrapped or jackknife dataset that was used to
  generate the corresponding parameter estimates in
  [`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).
  Missing values are imputed by using the mean of the conditional
  imputation distribution. Please note that the first imputed dataset
  refers to the conditional mean imputation on the original dataset
  whereas all subsequent imputed datasets refer to conditional mean
  imputations for bootstrap or jackknife samples, respectively, of the
  original data.

- Bootstrapped Maximum Likelihood MI (BMLMI): it performs `D` random
  imputations of each bootstrapped dataset that was used to generate the
  corresponding parameter estimates in
  [`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).
  A total number of `B*D` imputed datasets is provided, where `B` is the
  number of bootstrapped datasets. Missing values are imputed by taking
  a random sample from the conditional imputation distribution.

The `update_strategy` argument can be used to update the imputation
strategy that was originally set via the `data_ice` option in
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).
This avoids having to re-run the
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md)
function when changing the imputation strategy in certain circumstances
(as detailed below). The `data.frame` provided to `update_strategy`
argument must contain two columns, one for the subject ID and another
for the imputation strategy, whose names are the same as those defined
in the `vars` argument as specified in the call to
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).
Please note that this argument only allows you to update the imputation
strategy and not other arguments such as the time of the first visit
affected by the ICE. A key limitation of this functionality is that one
can only switch between a MAR and a non-MAR strategy (or vice versa) for
subjects without observed post-ICE data. The reason for this is that
such a change would affect whether the post-ICE data is included in the
base imputation model or not (as explained in the help to
[`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md)).
As an example, if a subject had their ICE on "Visit 2" but had
observed/known values for "Visit 3" then the function will throw an
error if one tries to switch the strategy from MAR to a non-MAR
strategy. In contrast, switching from a non-MAR to a MAR strategy,
whilst valid, will raise a warning as not all usable data will have been
utilised in the imputation model.

## References

James R Carpenter, James H Roger, and Michael G Kenward. Analysis of
longitudinal trials with protocol deviation: a framework for relevant,
accessible assumptions, and inference via multiple imputation. Journal
of Biopharmaceutical Statistics, 23(6):1352–1371, 2013. \[Section 4.2
and 4.3\]

## Examples

``` r
if (FALSE) { # \dontrun{

impute(
    draws = drawobj,
    references = c("Trt" = "Placebo", "Placebo" = "Placebo")
)

new_strategy <- data.frame(
  subjid = c("Pt1", "Pt2"),
  strategy = c("MAR", "JR")
)

impute(
    draws = drawobj,
    references = c("Trt" = "Placebo", "Placebo" = "Placebo"),
    update_strategy = new_strategy
)
} # }
```
