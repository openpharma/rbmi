# Stack Per-Group Values into a Stan Array

Stack Per-Group Values into a Stan Array

## Usage

``` r
stack_by_group(x)
```

## Arguments

- x:

  A list with one numeric vector or one matrix per group.

## Value

A matrix (vectors) or 3-dimensional array (matrices) with the groups
along the first dimension, as expected by `rstan` for Stan variables
declared as `array[G] vector` or `array[G] matrix`.
