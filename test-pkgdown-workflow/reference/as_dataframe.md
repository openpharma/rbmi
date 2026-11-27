# Convert object to dataframe

Convert object to dataframe

## Usage

``` r
as_dataframe(x)
```

## Arguments

- x:

  a data.frame like object

  Utility function to convert a "data.frame-like" object to an actual
  `data.frame` to avoid issues with inconsistency on methods (such as
  `[`() and `dplyr`'s grouped dataframes)
