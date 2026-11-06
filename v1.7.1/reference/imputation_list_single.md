# A collection of `imputation_singles()` grouped by a single `subjid` ID

A collection of `imputation_singles()` grouped by a single `subjid` ID

## Usage

``` r
imputation_list_single(imputations, D = 1)
```

## Arguments

- imputations:

  a list of
  [`imputation_single()`](https://openpharma.github.io/rbmi/reference/imputation_single.md)
  objects ordered so that repetitions are grouped sequentially

- D:

  the number of repetitions that were performed which determines how
  many columns the imputation matrix should have

  This is a constructor function to create a `imputation_list_single`
  object which contains a matrix of
  [`imputation_single()`](https://openpharma.github.io/rbmi/reference/imputation_single.md)
  objects grouped by a single `id`. The matrix is split so that it has D
  columns (i.e. for non-BMLMI methods this will always be 1)

  The `id` attribute is determined by extracting the `id` attribute from
  the contributing
  [`imputation_single()`](https://openpharma.github.io/rbmi/reference/imputation_single.md)
  objects. An error is throw if multiple `id` are detected
