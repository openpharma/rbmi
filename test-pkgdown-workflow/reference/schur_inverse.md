# Invert a symmetric block matrix using its scalar Schur complement

Computes the inverse of the block matrix with rows `(A, B)` and
`(t(B), C)`, where `C` is scalar. Positivity checks and any
model-specific fallback belong to the caller.

## Usage

``` r
schur_inverse(A, B, C)
```

## Arguments

- A:

  Leading square block, which must be invertible.

- B:

  Cross block, supplied as a vector.

- C:

  Scalar final block.

## Value

The inverse of the full block matrix, without dimension names, or `NULL`
if the Schur complement is zero or nonfinite.
