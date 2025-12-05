# Evaluate a call to mmrm

This is a utility function that attempts to evaluate a call to mmrm
managing any warnings or errors that are thrown.

## Usage

``` r
eval_mmrm(expr)
```

## Arguments

- expr:

  An expression to be evaluated. Should be a call to
  [`mmrm::mmrm()`](https://openpharma.github.io/mmrm/latest-tag/reference/mmrm.html).

## Details

This function was originally developed for use with `glmmTMB` which
needed more hand-holding and dropping of false-positive warnings. It is
not as important now but is kept around encase we need to catch
false-positive warnings again in the future.

## See also

[`record()`](https://insightsengineering.github.io/rbmi/reference/record.md)

## Examples

``` r
if (FALSE) { # \dontrun{
eval_mmrm({
    mmrm::mmrm(formula, data)
})
} # }
```
