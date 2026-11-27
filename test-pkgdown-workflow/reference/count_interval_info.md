# Normalize a count-data time interval specification

Normalize a count-data time interval specification

## Usage

``` r
count_interval_info(interval, origin, is_date)
```

## Arguments

- interval:

  A fixed interval width or supported calendar interval name, as
  accepted by
  [`split_time()`](https://openpharma.github.io/rbmi/reference/split_time.md).

- origin:

  The user-supplied interval origin, or `NULL`.

- is_date:

  Logical indicating whether the row start variable inherits from
  `Date`.

## Value

A list containing `origin` and either the fixed integer `width` or the
number of `calendar_months` in the requested interval.
