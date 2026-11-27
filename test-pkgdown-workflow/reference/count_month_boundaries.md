# Calculate calendar interval boundaries

Calculate calendar interval boundaries

## Usage

``` r
count_month_boundaries(index, interval_info)
```

## Arguments

- index:

  An integer vector of interval indices.

- interval_info:

  A normalized calendar interval specification returned by
  [`count_interval_info()`](https://openpharma.github.io/rbmi/reference/count_interval_info.md).

## Value

A `Date` vector containing the first day of each requested calendar
interval.
