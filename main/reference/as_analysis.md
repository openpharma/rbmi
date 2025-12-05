# Construct an `analysis` object

Creates an analysis object ensuring that all components are correctly
defined.

## Usage

``` r
as_analysis(results, method, delta = NULL, fun = NULL, fun_name = NULL)
```

## Arguments

- results:

  A list of lists contain the analysis results for each imputation See
  [`analyse()`](https://insightsengineering.github.io/rbmi/reference/analyse.md)
  for details on what this object should look like.

- method:

  The method object as specified in
  [`draws()`](https://insightsengineering.github.io/rbmi/reference/draws.md).

- delta:

  The delta dataset used. See
  [`analyse()`](https://insightsengineering.github.io/rbmi/reference/analyse.md)
  for details on how this should be specified.

- fun:

  The analysis function that was used.

- fun_name:

  The character name of the analysis function (used for printing)
  purposes.
