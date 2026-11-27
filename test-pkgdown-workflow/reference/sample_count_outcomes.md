# Sample missing counts for one posterior parameter draw

Sample missing counts for one posterior parameter draw

## Usage

``` r
sample_count_outcomes(prepared, sample)
```

## Arguments

- prepared:

  The fixed imputation inputs returned by
  [`prepare_count_imputation_data()`](https://openpharma.github.io/rbmi/reference/prepare_count_imputation_data.md).

- sample:

  A `sample_single_count` posterior draw containing regression
  coefficients and dispersion parameters.

## Value

A numeric vector aligned with the rows of `prepared`. Observed rows
contain zero, zero-duration missing rows contain zero, and
positive-duration missing rows contain the sampled counts.
