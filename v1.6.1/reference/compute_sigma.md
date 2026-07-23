# Compute covariance matrix for some reference-based methods (JR, CIR)

Adapt covariance matrix in reference-based methods. Used for Copy
Increments in Reference (CIR) and Jump To Reference (JTR) methods, to
adapt the covariance matrix to different pre-deviation and post
deviation covariance structures. See Carpenter et al. (2013)

## Usage

``` r
compute_sigma(sigma_group, sigma_ref, index_mar)
```

## Arguments

- sigma_group:

  the covariance matrix with dimensions equal to `index_mar` for the
  subjects original group

- sigma_ref:

  the covariance matrix with dimensions equal to `index_mar` for the
  subjects reference group

- index_mar:

  A logical vector indicating which visits meet the MAR assumption for
  the subject. I.e. this identifies the observations that after a
  non-MAR intercurrent event (ICE).

## References

Carpenter, James R., James H. Roger, and Michael G. Kenward. "Analysis
of longitudinal trials with protocol deviation: a framework for
relevant, accessible assumptions, and inference via multiple
imputation." Journal of Biopharmaceutical statistics 23.6 (2013):
1352-1371.
