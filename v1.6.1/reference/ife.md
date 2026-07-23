# if else

A wrapper around `if() else()` to prevent unexpected interactions
between [`ifelse()`](https://rdrr.io/r/base/ifelse.html) and factor
variables

## Usage

``` r
ife(x, a, b)
```

## Arguments

- x:

  True / False

- a:

  value to return if True

- b:

  value to return if False

## Details

By default [`ifelse()`](https://rdrr.io/r/base/ifelse.html) will convert
factor variables to their numeric values which is often undesirable.
This connivance function avoids that problem
