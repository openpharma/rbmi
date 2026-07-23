# Prepare input data to run the Stan model

Prepare input data to run the Stan model. Creates / calculates all the
required inputs as required by the `data{}` block of the MMRM Stan
program.

## Usage

``` r
prepare_stan_data(ddat, subjid, visit, outcome, group)
```

## Arguments

- ddat:

  A design matrix

- subjid:

  Character vector containing the subjects IDs.

- visit:

  Vector containing the visits.

- outcome:

  Numeric vector containing the outcome variable.

- group:

  Vector containing the group variable.

## Value

A `stan_data` object. A named list as per `data{}` block of the related
Stan file. In particular it returns:

- N - The number of rows in the design matrix

- P - The number of columns in the design matrix

- G - The number of distinct covariance matrix groups (i.e.
  `length(unique(group))`)

- n_visit - The number of unique outcome visits

- n_pat - The total number of pattern groups (as defined by missingness
  patterns & covariance group)

- pat_G - Index for which Sigma each pattern group should use

- pat_n_pt - number of patients within each pattern group

- pat_n_visit - number of non-missing visits in each pattern group

- pat_sigma_index - rows/cols from Sigma to subset on for the pattern
  group (padded by 0's)

- y - The outcome variable

- Q - design matrix (after QR decomposition)

- R - R matrix from the QR decomposition of the design matrix

## Details

- The `group` argument determines which covariance matrix group the
  subject belongs to. If you want all subjects to use a shared
  covariance matrix then set group to "1" for everyone.
