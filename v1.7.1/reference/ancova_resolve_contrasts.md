# Resolve the set of ANCOVA contrasts to compute

Translates the optional `group_contrasts` specification into a list of
contrast records. Each record holds a weight vector over the group
levels (`weights`, in factor-level order, summing to zero), the output
`parameter` name, an optional user `label`, and the `level_1` /
`level_2` group labels for simple pairwise contrasts (`NA` for general
weight-vector contrasts).

## Usage

``` r
ancova_resolve_contrasts(group_contrasts, orig_levels, labels)
```

## Arguments

- group_contrasts:

  Either `NULL` or a fully named list of length-2 character vectors
  and/or numeric weight vectors. See
  [`set_vars()`](https://openpharma.github.io/rbmi/reference/set_vars.md).

- orig_levels:

  Character vector of the group factor levels (in order).

- labels:

  Character vector of `ref`/`alt`/... labels from
  [`ancova_group_labels()`](https://openpharma.github.io/rbmi/reference/ancova_group_labels.md).

## Value

A list of contrast records (see description).

## Details

When `group_contrasts` is `NULL` the default is each non-reference level
versus the reference level, using the backwards-compatible `trt` /
`trt_alt2` / ... naming. Otherwise the list must be fully named; each
element is either a length-2 character vector `c(minuend, subtrahend)`
(a pairwise contrast) or a numeric weight vector over the group levels,
and the list name is used as the `parameter` name.
