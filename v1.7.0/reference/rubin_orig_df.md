# Original Rubin degrees of freedom approximation

Compute the degrees of freedom according to the original Rubin (1987)
approximation.

## Usage

``` r
rubin_orig_df(v_com, var_b, var_t, M)
```

## Arguments

- v_com:

  Ignored in this function.

- var_b:

  Between-imputation sample variance of the point estimates across
  multiply imputed datasets.

- var_t:

  Estimate (according to Rubin's rules) of the variance of the point
  estimates.

- M:

  Number of imputations (integer larger than 1).

## Value

Degrees of freedom according to the original Rubin approximation. If the
between-imputation variance is zero, returns `Inf`.

## Details

Let \\V_W = V_T - (1 + 1 / M) V_B\\ be the within-imputation variance
and \\r = (1 + 1 / M) V_B / V_W\\ be the relative increase in variance
due to nonresponse. The returned degrees of freedom are \\(M - 1) (1 + 1
/ r)^2\\. Note that the internal computation is algebraically simplified
to \\(M - 1) ((M V_T) / ((M + 1) V_B))^2\\.

## References

Rubin, D.B. (1987). Multiple Imputation for Nonresponse in Surveys. John
Wiley & Sons, New York. \[Section 3.3\]
