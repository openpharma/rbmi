# Split one count-data row into time intervals

Split one count-data row into time intervals

## Usage

``` r
split_time_row(
  source_row,
  start,
  duration,
  outcome,
  event_times,
  period,
  interval_info,
  is_date
)
```

## Arguments

- source_row:

  A one-row data frame from the original count data.

- start:

  Name of the row start variable.

- duration:

  Name of the row duration variable.

- outcome:

  Name of the aggregate count variable.

- event_times:

  Optional names of the event-time offset columns.

- period:

  Optional name of the original period variable.

- interval_info:

  A normalized interval specification returned by
  [`count_interval_info()`](https://openpharma.github.io/rbmi/reference/count_interval_info.md).

- is_date:

  Logical indicating whether the row start variable inherits from
  `Date`.

## Value

A data frame containing one row per interval intersected by
`source_row`, with split timing, duration, period, and outcome columns.
