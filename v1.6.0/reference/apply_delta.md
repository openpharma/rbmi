# Applies delta adjustment

Takes a delta dataset and adjusts the outcome variable by adding the
corresponding delta.

## Usage

``` r
apply_delta(data, delta = NULL, group = NULL, outcome = NULL)
```

## Arguments

- data:

  `data.frame` which will have its `outcome` column adjusted.

- delta:

  `data.frame` (must contain a column called `delta`).

- group:

  character vector of variables in both `data` and `delta` that will be
  used to merge the 2 data.frames together by.

- outcome:

  character, name of the outcome variable in `data`.
