# Get delta utility variables

This function creates the default delta template (1 row per subject per
visit) and extracts all the utility information that users need to
define their own logic for defining delta. See
[`delta_template()`](https://insightsengineering.github.io/rbmi/reference/delta_template.md)
for full details.

## Usage

``` r
get_delta_template(imputations)
```

## Arguments

- imputations:

  an imputations object created by
  [`impute()`](https://insightsengineering.github.io/rbmi/reference/impute.md).
