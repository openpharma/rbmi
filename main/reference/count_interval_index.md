# Find the interval index for a time value

Find the interval index for a time value

## Usage

``` r
count_interval_index(value, interval_info, is_date)
```

## Arguments

- value:

  A numeric or `Date` time value.

- interval_info:

  A normalized interval specification returned by
  [`count_interval_info()`](https://openpharma.github.io/rbmi/reference/count_interval_info.md).

- is_date:

  Logical indicating whether `value` inherits from `Date`.

## Value

A single integer interval index relative to the normalized origin.
