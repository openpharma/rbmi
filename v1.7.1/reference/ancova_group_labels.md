# ANCOVA group level labels

Maps the ordered factor levels of the group variable to the fixed `rbmi`
label scheme: the first level is `ref`, the second `alt`, and any
further levels `alt2`, `alt3`, etc.

## Usage

``` r
ancova_group_labels(n)
```

## Arguments

- n:

  Integer, the number of group levels.

## Value

A character vector of labels of length `n`.
