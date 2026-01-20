# Combine estimates using Rubin's rules

Pool together the results from `M` complete-data analyses according to
Rubin's rules. See details.

## Usage

``` r
rubin_rules(ests, ses, v_com)
```

## Arguments

- ests:

  Numeric vector containing the point estimates from the complete-data
  analyses.

- ses:

  Numeric vector containing the standard errors from the complete-data
  analyses.

- v_com:

  Positive number representing the degrees of freedom in the
  complete-data analysis.

## Value

A list containing:

- `est_point`: the pooled point estimate according to Little-Rubin
  (2002).

- `var_t`: total variance according to Little-Rubin (2002).

- `df`: degrees of freedom according to Barnard-Rubin (1999).

## Details

`rubin_rules` applies Rubin's rules (Rubin, 1987) for pooling together
the results from a multiple imputation procedure. The pooled point
estimate `est_point` is is the average across the point estimates from
the complete-data analyses (given by the input argument `ests`). The
total variance `var_t` is the sum of two terms representing the
within-variance and the between-variance (see Little-Rubin (2002)). The
function also returns `df`, the estimated pooled degrees of freedom
according to Barnard-Rubin (1999) that can be used for inference based
on the t-distribution.

## References

Barnard, J. and Rubin, D.B. (1999). Small sample degrees of freedom with
multiple imputation. Biometrika, 86, 948-955

Roderick J. A. Little and Donald B. Rubin. Statistical Analysis with
Missing Data, Second Edition. John Wiley & Sons, Hoboken, New Jersey,
2002. \[Section 5.4\]

## See also

[`rubin_df()`](https://openpharma.github.io/rbmi/reference/rubin_df.md)
for the degrees of freedom estimation.
