# Set key variables

This function is used to define the names of key variables within the
`data.frame`'s that are provided as input arguments to
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md) and
[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md).

## Usage

``` r
set_vars(
  subjid = "subjid",
  visit = "visit",
  outcome = "outcome",
  group = "group",
  covariates = character(0),
  strata = group,
  strategy = "strategy"
)
```

## Arguments

- subjid:

  The name of the "Subject ID" variable. A length 1 character vector.

- visit:

  The name of the "Visit" variable. A length 1 character vector.

- outcome:

  The name of the "Outcome" variable. A length 1 character vector.

- group:

  The name of the "Group" variable. A length 1 character vector.

- covariates:

  The name of any covariates to be used in the context of modelling. See
  details.

- strata:

  The name of the any stratification variable to be used in the context
  of bootstrap sampling. See details.

- strategy:

  The name of the "strategy" variable. A length 1 character vector.

## Details

In both
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md) and
[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md) the
`covariates` argument can be specified to indicate which variables
should be included in the imputation and analysis models respectively.
If you wish to include interaction terms these need to be manually
specified i.e. `covariates = c("group*visit", "age*sex")`. Please note
that the use of the [`I()`](https://rdrr.io/r/base/AsIs.html) function
to inhibit the interpretation/conversion of objects is not supported.

Currently `strata` is only used by
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md) in
combination with `method_condmean(type = "bootstrap")` and
[`method_approxbayes()`](https://openpharma.github.io/rbmi/reference/method.md)
in order to allow for the specification of stratified bootstrap
sampling. By default `strata` is set equal to the value of `group` as it
is assumed most users will want to preserve the group size between
samples. See
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md) for
more details.

Likewise, currently the `strategy` argument is only used by
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md) to
specify the name of the strategy variable within the `data_ice`
data.frame. See
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md) for
more details.

## See also

[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md)

[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md)

## Examples

``` r
if (FALSE) { # \dontrun{

# Using CDISC variable names as an example
set_vars(
    subjid = "usubjid",
    visit = "avisit",
    outcome = "aval",
    group = "arm",
    covariates = c("bwt", "bht", "arm * avisit"),
    strategy = "strat"
)

} # }
```
