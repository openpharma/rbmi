# Expand and fill in missing `data.frame` rows

These functions are essentially wrappers around
[`base::expand.grid()`](https://rdrr.io/r/base/expand.grid.html) to
ensure that missing combinations of data are inserted into a
`data.frame` with imputation/fill methods for updating covariate values
of newly created rows.

## Usage

``` r
expand(data, ...)

fill_locf(data, vars, group = NULL, order = NULL)

expand_locf(data, ..., vars, group, order)
```

## Arguments

- data:

  dataset to expand or fill in.

- ...:

  variables and the levels that should be expanded out (note that
  duplicate entries of levels will result in multiple rows for that
  level).

- vars:

  character vector containing the names of variables that need to be
  filled in.

- group:

  character vector containing the names of variables to group by when
  performing LOCF imputation of `var`.

- order:

  character vector containing the names of additional variables to sort
  the `data.frame` by before performing LOCF.

## Details

The [`draws()`](https://openpharma.github.io/rbmi/reference/draws.md)
function makes the assumption that all subjects and visits are present
in the `data.frame` and that all covariate values are non missing;
`expand()`, `fill_locf()` and `expand_locf()` are utility functions to
support users in ensuring that their `data.frame`'s conform to these
assumptions.

`expand()` takes vectors for expected levels in a `data.frame` and
expands out all combinations inserting any missing rows into the
`data.frame`. Note that all "expanded" variables are cast as factors.

`fill_locf()` applies LOCF imputation to named covariates to fill in any
NAs created by the insertion of new rows by `expand()` (though do note
that no distinction is made between existing NAs and newly created NAs).
Note that the `data.frame` is sorted by `c(group, order)` before
performing the LOCF imputation; the `data.frame` will be returned in the
original sort order however.

`expand_locf()` a simple composition function of `fill_locf()` and
`expand()` i.e. `fill_locf(expand(...))`.

### Missing First Values

The `fill_locf()` function performs last observation carried forward
imputation. A natural consequence of this is that it is unable to impute
missing observations if the observation is the first value for a given
subject / grouping. These values are deliberately not imputed as doing
so risks silent errors in the case of time varying covariates. One
solution is to first use `expand_locf()` on just the visit variable and
time varying covariates and then merge on the baseline covariates
afterwards i.e.

    library(dplyr)

    dat_expanded <- expand(
        data = dat,
        subject = c("pt1", "pt2", "pt3", "pt4"),
        visit = c("vis1", "vis2", "vis3")
    )

    dat_filled <- dat_expanded %>%
        left_join(baseline_covariates, by = "subject")

## Examples

``` r
if (FALSE) { # \dontrun{
dat_expanded <- expand(
    data = dat,
    subject = c("pt1", "pt2", "pt3", "pt4"),
    visit = c("vis1", "vis2", "vis3")
)

dat_filled <- fill_loc(
    data = dat_expanded,
    vars = c("Sex", "Age"),
    group = "subject",
    order = "visit"
)

## Or

dat_filled <- expand_locf(
    data = dat,
    subject = c("pt1", "pt2", "pt3", "pt4"),
    visit = c("vis1", "vis2", "vis3"),
    vars = c("Sex", "Age"),
    group = "subject",
    order = "visit"
)
} # }
```
