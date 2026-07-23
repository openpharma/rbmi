# Von Hippel and Bartlett pooling of BMLMI method

Compute pooled point estimates, standard error and degrees of freedom
according to the Von Hippel and Bartlett formula for Bootstrapped
Maximum Likelihood Multiple Imputation (BMLMI).

## Usage

``` r
get_ests_bmlmi(ests, D)
```

## Arguments

- ests:

  numeric vector containing estimates from the analysis of the imputed
  datasets.

- D:

  numeric representing the number of imputations between each bootstrap
  sample in the BMLMI method.

## Value

a list containing point estimate, standard error and degrees of freedom.

## Details

`ests` must be provided in the following order: the firsts D elements
are related to analyses from random imputation of one bootstrap sample.
The second set of D elements (i.e. from D+1 to 2\*D) are related to the
second bootstrap sample and so on.

## References

Von Hippel, Paul T and Bartlett, Jonathan W8. Maximum likelihood
multiple imputation: Faster imputations and consistent standard errors
without posterior draws. 2021
