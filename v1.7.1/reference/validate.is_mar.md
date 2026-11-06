# Validate `is_mar` for a given subject

Checks that the longitudinal data for a patient is divided in MAR
followed by non-MAR data; a non-MAR observation followed by a MAR
observation is not allowed.

## Usage

``` r
# S3 method for class 'is_mar'
validate(x, ...)
```

## Arguments

- x:

  Object of class `is_mar`. Logical vector indicating whether
  observations are MAR.

- ...:

  Not used.

## Value

Will error if there is an issue otherwise will return `TRUE`.
