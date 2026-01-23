# Calculate parametric confidence intervals

Calculates confidence intervals based upon a parametric distribution.

## Usage

``` r
parametric_ci(point, se, alpha, alternative, qfun, pfun, ...)
```

## Arguments

- point:

  The point estimate.

- se:

  The standard error of the point estimate. If using a non-"normal"
  distribution this should be set to 1.

- alpha:

  The type 1 error rate, should be a value between 0 and 1.

- alternative:

  a character string specifying the alternative hypothesis, must be one
  of "two.sided" (default), "greater" or "less".

- qfun:

  The quantile function for the assumed distribution i.e. `qnorm`.

- pfun:

  The CDF function for the assumed distribution i.e. `pnorm`.

- ...:

  additional arguments passed on `qfun` and `pfun` i.e. `df = 102`.
