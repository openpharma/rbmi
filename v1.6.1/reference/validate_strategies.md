# Validate user specified strategies

Compares the user provided strategies to those that are required (the
reference). Will throw an error if not all values of reference have been
defined.

## Usage

``` r
validate_strategies(strategies, reference)
```

## Arguments

- strategies:

  named list of strategies.

- reference:

  list or character vector of strategies that need to be defined.

## Value

Will throw an error if there is an issue otherwise will return `TRUE`.
