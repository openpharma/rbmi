# Apply strategy updates locally to count imputation data

Apply strategy updates locally to count imputation data

## Usage

``` r
update_count_strategies(data, update_strategy)
```

## Arguments

- data:

  A cloned `longdata` object for a count endpoint.

- update_strategy:

  A data frame accepted by the `update_strategy` argument of
  [`impute()`](https://openpharma.github.io/rbmi/reference/impute.md).

## Value

The modified `longdata` object.
