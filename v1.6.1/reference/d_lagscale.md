# Calculate delta from a lagged scale coefficient

Calculates a delta value based upon a baseline delta value and a post
ICE scaling coefficient.

## Usage

``` r
d_lagscale(delta, dlag, is_post_ice)
```

## Arguments

- delta:

  a numeric vector. Determines the baseline amount of delta to be
  applied to each visit.

- dlag:

  a numeric vector. Determines the scaling to be applied to `delta`
  based upon with visit the ICE occurred on. Must be the same length as
  delta.

- is_post_ice:

  logical vector. Indicates whether a visit is "post-ICE" or not.

## Details

See
[`delta_template()`](https://openpharma.github.io/rbmi/reference/delta_template.md)
for full details on how this calculation is performed.
