# Check whether a variable participates in a formula interaction

Check whether a variable participates in a formula interaction

## Usage

``` r
formula_has_interaction(formula, variable)
```

## Arguments

- formula:

  A model formula.

- variable:

  Character, the name of the variable to check.

## Value

A single logical value indicating whether an interaction term involves
`variable`, including through a transformation such as
`factor(variable)`.

## Details

Uses expanded model terms, so interactions removed with `-` do not
count. Arithmetic inside [`I()`](https://rdrr.io/r/base/AsIs.html) is
not treated as a formula interaction.
