# Simulate drop-out

Simulate drop-out

## Usage

``` r
simulate_dropout(prob_dropout, ids, subset = rep(1, length(ids)))
```

## Arguments

- prob_dropout:

  Numeric that specifies the probability that a post-baseline visit is
  affected by study drop-out.

- ids:

  Factor variable that specifies the id of each subject.

- subset:

  Binary variable that specifies the subset that could be affected by
  drop-out. I.e. `subset` is a binary vector of length equal to the
  length of `ids` that takes value `1` if the corresponding visit could
  be affected by drop-out and `0` otherwise.

## Value

A binary vector of length equal to the length of `ids` that takes value
`1` if the corresponding outcome is affected by study drop-out.

## Details

`subset` can be used to specify outcome values that cannot be affected
by the drop-out. By default `subset` will be set to `1` for all the
values except the values corresponding to the baseline outcome, since
baseline is supposed to not be affected by drop-out. Even if `subset` is
specified by the user, the values corresponding to the baseline outcome
are still hard-coded to be `0`.
