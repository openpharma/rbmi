# Determine patients missingness group

Takes a design matrix with multiple rows per subject and returns a
dataset with 1 row per subject with a new column `pgroup` indicating
which group the patient belongs to (based upon their missingness pattern
and treatment group)

## Usage

``` r
get_pattern_groups(ddat)
```

## Arguments

- ddat:

  a `data.frame` with columns `subjid`, `visit`, `group`, `is_avail`

## Details

- The column `is_avail` must be a character or numeric `0` or `1`
