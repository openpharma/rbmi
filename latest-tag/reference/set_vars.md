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
  strategy = "strategy",
  group_contrasts = NULL
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

- group_contrasts:

  Optional specification of the treatment-group contrasts to be
  estimated by
  [`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md).
  Either `NULL` (the default) or a fully named list whose elements are
  one of:

  - a length-2 character vector `c(minuend, subtrahend)` giving a
    pairwise contrast `minuend - subtrahend` between two levels of
    `group`; or

  - a numeric weight vector over the group levels (summing to zero),
    either named by the levels of `group` (unlisted levels default to
    `0`) or of the same length as the number of levels (in factor
    order).

  Each element must be named; the name is used as the output `parameter`
  name (and must not start with `lsm_`, which is reserved for the
  least-squares means). See details.

## Value

A `vars` object; a named list of class `ivars` recording the names of
the key variables (`subjid`, `visit`, `outcome`, `group`, `covariates`,
`strata` and `strategy`) used throughout `rbmi` by functions such as
[`draws()`](https://openpharma.github.io/rbmi/reference/draws.md),
[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md) and
[`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md).

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

The `group_contrasts` argument is only used by
[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md). If
`NULL` (default) a treatment effect is estimated for every non-reference
group versus the reference group (the first factor level of `group`).
Alternatively a bespoke set of contrasts can be requested. Pairwise
contrasts are given as length-2 character vectors, e.g.
`group_contrasts = list(c("A", "Placebo"), c("B", "Placebo"))` requests
the contrasts `A - Placebo` and `B - Placebo`. More general linear
contrasts are given as named numeric weight vectors over the group
levels, e.g.
`group_contrasts = list(pooled_vs_pbo = c(Placebo = -1, A = 0.5, B = 0.5))`
contrasts the average of `A` and `B` against `Placebo`. List names are
carried through to the `contrast_label` column of the
[`pool()`](https://openpharma.github.io/rbmi/reference/pool.md) output;
weight-vector contrasts must be named. See
[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md) for
the resulting `parameter` naming scheme.

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
