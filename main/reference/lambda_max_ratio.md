# Largest ratio of lambda fixed means to model-based means

For missing cells using `fixed_rate_scale = "lambda"`, the fixed mean
`L * lambda / phi` is compared with the model-based mean of the same
cell under the base strategy, `L * exp(x * beta)`, for one posterior
draw.

## Usage

``` r
lambda_max_ratio(prepared, sample)
```

## Arguments

- prepared:

  The fixed imputation inputs returned by
  [`prepare_count_imputation_data()`](https://openpharma.github.io/rbmi/reference/prepare_count_imputation_data.md).

- sample:

  A `sample_single_count` posterior draw containing regression
  coefficients and dispersion parameters.

## Value

The largest ratio, or 0 if no cell uses the SAS lambda scale.
