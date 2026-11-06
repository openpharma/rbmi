# Format method descriptions

This function formats method descriptions by combining method names and
their descriptions.

## Usage

``` r
format_method_descriptions(method)
```

## Arguments

- method:

  A named list of methods and their descriptions.

## Value

A character vector of formatted method descriptions.

## Details

If any non-atomic elements are present in the method list, they are
converted to a string representation using
[`dput()`](https://rdrr.io/r/base/dput.html).
