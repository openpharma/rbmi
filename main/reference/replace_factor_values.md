# Replace the values of a factor while keeping its coding

Reference-based imputation evaluates the fitted model with the treatment
group replaced by the reference group. Constructing a new factor would
drop the original factor's `contrasts` attribute and `ordered` class, so
the design matrix would no longer be expressed in the basis in which the
coefficients were estimated. Replacing the values in place keeps both.

## Usage

``` r
replace_factor_values(x, values)
```

## Arguments

- x:

  A factor.

- values:

  Values to assign; must be levels of `x`. Recycled if of length 1.

## Value

`x` with its values replaced and all other attributes unchanged.
