# Prepare input data to run the Stan model for count outcome

Prepare input data to run the Stan model for count outcome.

## Usage

``` r
prepare_stan_data_count(
  ddat,
  subjid,
  duration,
  outcome,
  group,
  same_cov,
  term_names = colnames(ddat)
)
```

## Arguments

- ddat:

  A design matrix

- subjid:

  A vector of subject IDs

- duration:

  A vector of duration values

- outcome:

  A vector of integer outcome values (unscaled, i.e. raw counts)

- group:

  A factor containing the treatment group for each row.

- same_cov:

  Logical. If `TRUE`, use one shared dispersion parameter. If `FALSE`,
  estimate a separate dispersion parameter for each treatment group.

- term_names:

  `NULL` or the model-matrix column names of `ddat`, used to name
  unidentified terms in error messages.

## Value

A `stan_data_count` object. A named list containing all the required
inputs as required by the `data{}` block of the count Stan program:

- `N`: The number of patients

- `R`: The number of observed positive-duration cells

- `P`: The number of design matrix columns in each period

- `G`: The number of dispersion parameter groups

- `group`: The dispersion parameter group index for each patient

- `subject`: The patient index for each observed cell

- `y`: The observed cell counts

- `X`: The cell-level design matrix

- `log_offset`: The log exposure for each observed cell
