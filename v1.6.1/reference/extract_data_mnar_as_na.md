# Set to NA outcome values that would be MNAR if they were missing (i.e. which occur after an ICE handled using a reference-based imputation strategy)

Set to NA outcome values that would be MNAR if they were missing (i.e.
which occur after an ICE handled using a reference-based imputation
strategy)

## Usage

``` r
extract_data_mnar_as_na(longdata)
```

## Arguments

- longdata:

  R6 `longdata` object containing all relevant input data information.

## Value

A `data.frame` containing `longdata$get_data(longdata$ids)`, but MNAR
outcome values are set to `NA`.
