# Resolve a numeric contrast weight vector to full group-level order

Expands a (possibly level-named or level-length) numeric weight vector
into a full vector over all group levels in factor order, validating
that it references known levels, sums to zero and is not trivially zero.

## Usage

``` r
resolve_contrast_weights(x, orig_levels)
```

## Arguments

- x:

  Numeric weight vector, either named by group levels (missing levels
  are filled with `0`) or of length `length(orig_levels)` in factor
  order.

- orig_levels:

  Character vector of the group factor levels (in order).

## Value

A numeric vector of length `length(orig_levels)` summing to zero.
