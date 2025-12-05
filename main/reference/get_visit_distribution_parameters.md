# Derive visit distribution parameters

Takes patient level data and beta coefficients and expands them to get a
patient specific estimate for the visit distribution parameters `mu` and
`sigma`. Returns the values in a specific format which is expected by
downstream functions in the imputation process (namely
`list(list(mu = ..., sigma = ...), list(mu = ..., sigma = ...))`).

## Usage

``` r
get_visit_distribution_parameters(dat, beta, sigma)
```

## Arguments

- dat:

  Patient level dataset, must be 1 row per visit. Column order must be
  in the same order as beta. The number of columns must match the length
  of beta

- beta:

  List of model beta coefficients. There should be 1 element for each
  sample e.g. if there were 3 samples and the models each had 4 beta
  coefficients then this argument should be of the form
  `list( c(1,2,3,4) , c(5,6,7,8), c(9,10,11,12))`. All elements of beta
  must be the same length and must be the same length and order as
  `dat`.

- sigma:

  List of sigma. Must have the same number of entries as `beta`.
