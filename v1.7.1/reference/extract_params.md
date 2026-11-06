# Extract parameters from a MMRM model

Extracts the beta and sigma coefficients from an MMRM model created by
[`mmrm::mmrm()`](https://openpharma.github.io/mmrm/latest-tag/reference/mmrm.html).

## Usage

``` r
extract_params(fit)
```

## Arguments

- fit:

  an object created by
  [`mmrm::mmrm()`](https://openpharma.github.io/mmrm/latest-tag/reference/mmrm.html)

## Details

For structured covariance models, additional parameter estimates will be
returned, based on the type of the covariance model.
