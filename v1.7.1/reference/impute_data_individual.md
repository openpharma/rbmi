# Impute data for a single subject

This function performs the imputation for a single subject at a time
implementing the process as detailed in
[`impute()`](https://openpharma.github.io/rbmi/reference/impute.md).

## Usage

``` r
impute_data_individual(
  id,
  index,
  beta,
  sigma,
  data,
  references,
  strategies,
  condmean,
  n_imputations = 1
)
```

## Arguments

- id:

  Character string identifying the subject.

- index:

  The sample indexes which the subject belongs to e.g `c(1,1,1,2,2,4)`.

- beta:

  A list of beta coefficients for each sample, i.e. `beta[[1]]` is the
  set of beta coefficients for the first sample.

- sigma:

  A list of the sigma coefficients for each sample split by group i.e.
  `sigma[[1]][["A"]]` would give the sigma coefficients for group A for
  the first sample.

- data:

  A `longdata` object created by
  [`longDataConstructor()`](https://openpharma.github.io/rbmi/reference/longDataConstructor.md)

- references:

  A named vector. Identifies the references to be used when generating
  the imputed values. Should be of the form
  `c("Group" = "Reference", "Group" = "Reference")`.

- strategies:

  A named list of functions. Defines the imputation functions to be
  used. The names of the list should mirror the values specified in
  `method` column of `data_ice`. Default =
  [`getStrategies()`](https://openpharma.github.io/rbmi/reference/getStrategies.md).
  See
  [`getStrategies()`](https://openpharma.github.io/rbmi/reference/getStrategies.md)
  for more details.

- condmean:

  Logical. If `TRUE` will impute using the conditional mean values, if
  `FALSE` will impute by taking a random draw from the multivariate
  normal distribution.

- n_imputations:

  When `condmean = FALSE` numeric representing the number of random
  imputations to be performed for each sample. Default is `1` (one
  random imputation per sample).

## Details

Note that this function performs all of the required imputations for a
subject at the same time. I.e. if a subject is included in samples
1,3,5,9 then all imputations (using sample-dependent imputation model
parameters) are performed in one step in order to avoid having to look
up a subjects' covariates and expanding them to a design matrix multiple
times (which would be more computationally expensive). The function also
supports subject belonging to the same sample multiple times, i.e.
1,1,2,3,5,5, as will typically occur for bootstrapped datasets.
