# Create a sample for a count-outcome imputation model

Create a sample for a count-outcome imputation model

## Usage

``` r
sample_single_count(ids, beta, phi)
```

## Arguments

- ids:

  Vector of subject identifiers.

- beta:

  Numeric vector of regression coefficients.

- phi:

  Positive numeric dispersion parameter(s) in the parameterisation
  `Var(Y) = mu + phi * mu^2`. A vector is named by treatment group when
  group-specific dispersion parameters are used.
