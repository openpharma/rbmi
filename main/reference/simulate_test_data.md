# Create simulated datasets

Creates a longitudinal dataset in the format that `rbmi` was designed to
analyse.

## Usage

``` r
simulate_test_data(
  n = 200,
  sd = c(3, 5, 7),
  cor = c(0.1, 0.7, 0.4),
  mu = list(int = 10, age = 3, sex = 2, trt = c(0, 4, 8), visit = c(0, 1, 2))
)

as_vcov(sd, cor)
```

## Arguments

- n:

  the number of subjects to sample. Total number of observations
  returned is thus `n * length(sd)`

- sd:

  the standard deviations for the outcome at each visit. i.e. the square
  root of the diagonal of the covariance matrix for the outcome

- cor:

  the correlation coefficients between the outcome values at each visit.
  See details.

- mu:

  the coefficients to use to construct the mean outcome value at each
  visit. Must be a named list with elements `int`, `age`, `sex`, `trt` &
  `visit`. See details.

## Details

The number of visits is determined by the size of the variance
covariance matrix. i.e. if 3 standard deviation values are provided then
3 visits per patient will be created.

The covariates in the simulated dataset are produced as follows:

- Patients age is sampled at random from a N(0,1) distribution

- Patients sex is sampled at random with a 50/50 split

- Patients group is sampled at random but fixed so that each group has
  `n/2` patients

- The outcome variable is sampled from a multivariate normal
  distribution, see below for details

The mean for the outcome variable is derived as:

    outcome = Intercept + age + sex + visit + treatment

The coefficients for the intercept, age and sex are taken from `mu$int`,
`mu$age` and `mu$sex` respectively, all of which must be a length 1
numeric.

Treatment and visit coefficients are taken from `mu$trt` and `mu$visit`
respectively and must either be of length 1 (i.e. a constant affect
across all visits) or equal to the number of visits (as determined by
the length of `sd`). I.e. if you wanted a treatment slope of 5 and a
visit slope of 1 you could specify:

    mu = list(..., "trt" = c(0,5,10), "visit" = c(0,1,2))

The correlation matrix is constructed from `cor` as follows. Let
`cor = c(a, b, c, d, e, f)` then the correlation matrix would be:

    1  a  b  d
    a  1  c  e
    b  c  1  f
    d  e  f  1
