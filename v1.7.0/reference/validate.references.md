# Validate user supplied references

Checks to ensure that the user specified references are expect values
(i.e. those found within the source data).

## Usage

``` r
# S3 method for class 'references'
validate(x, control, ...)
```

## Arguments

- x:

  named character vector.

- control:

  factor variable (should be the `group` variable from the source
  dataset).

- ...:

  Not used.

## Value

Will error if there is an issue otherwise will return `TRUE`.
