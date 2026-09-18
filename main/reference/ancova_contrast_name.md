# Name a default ANCOVA treatment-effect contrast

Determines the `parameter` name for a default contrast of a
non-reference level against the reference level: the second factor level
is `trt`, the third `trt_alt2`, the fourth `trt_alt3`, and so on. Only
used for the default (`group_contrasts = NULL`) set; user-supplied
contrasts are named explicitly by the caller.

## Usage

``` r
ancova_contrast_name(i, labels)
```

## Arguments

- i:

  Integer, 1-based index of the (non-reference) group level.

- labels:

  Character vector of level labels as returned by
  [`ancova_group_labels()`](https://openpharma.github.io/rbmi/reference/ancova_group_labels.md).

## Value

A length 1 character vector with the parameter name.
