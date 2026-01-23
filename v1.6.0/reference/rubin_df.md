# Barnard and Rubin degrees of freedom adjustment

Compute degrees of freedom according to the Barnard-Rubin formula.

## Usage

``` r
rubin_df(v_com, var_b, var_t, M)
```

## Arguments

- v_com:

  Positive number representing the degrees of freedom in the
  complete-data analysis.

- var_b:

  Between-variance of point estimate across multiply imputed datasets.

- var_t:

  Total-variance of point estimate according to Rubin's rules.

- M:

  Number of imputations.

## Value

Degrees of freedom according to Barnard-Rubin formula. See Barnard-Rubin
(1999).

## Details

The computation takes into account limit cases where there is no missing
data (i.e. the between-variance `var_b` is zero) or where the
complete-data degrees of freedom is set to `Inf`. Moreover, if `v_com`
is given as `NA`, the function returns `Inf`.

## References

Barnard, J. and Rubin, D.B. (1999). Small sample degrees of freedom with
multiple imputation. Biometrika, 86, 948-955.
