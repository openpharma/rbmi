# Extract Variables from string vector

Takes a string including potentially model terms like `*` and `:` and
extracts out the individual variables

## Usage

``` r
extract_covariates(x)
```

## Arguments

- x:

  string of variable names potentially including interaction terms

## Details

i.e. `c("v1", "v2", "v2*v3", "v1:v2")` becomes `c("v1", "v2", "v3")`
