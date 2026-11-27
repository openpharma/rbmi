# Split count-data rows into time intervals

`split_time()` divides each count-data row into fixed-width or calendar
intervals. Event-time columns are used to allocate an observed aggregate
count to the resulting cells. Missing aggregate counts remain missing in
every resulting positive-duration cell.

## Usage

``` r
split_time(
  data,
  start,
  duration,
  outcome,
  event_times = NULL,
  interval,
  origin = NULL,
  period = NULL
)
```

## Arguments

- data:

  A data frame with one row per original count period.

- start:

  Name of the row start variable. It must be a `Date` or a whole-number
  numeric time (time is measured in whole days or units).

- duration:

  Name of the non-negative duration variable, measured in days for
  `Date` starts and in the same units as a numeric `start`.

- outcome:

  Name of the aggregate count variable.

- event_times:

  Optional character vector naming columns that contain one-based,
  whole-number event-time offsets from `start`. These are required to
  allocate a positive observed count when a row intersects more than one
  interval.

- interval:

  A positive whole number giving a fixed interval width, or one of
  `"day"`, `"week"`, `"month"`, `"quarter"`, or `"year"`. Calendar
  months, quarters, and years require `Date` starts.

- origin:

  Optional whole-number interval origin. For fixed intervals this is the
  boundary immediately before interval zero. For calendar intervals it
  must be the first day of a month. Defaults to `0` for numeric starts
  and `1970-01-01` for `Date` starts. (Note that `interval = "week"`
  with the default numeric origin 0 / `1970-01-01` (a Thursday) produces
  Thursday-based weeks.)

- period:

  Optional name of the original period variable. When supplied,
  `split_period` combines this value with `split_interval`, which allows
  two original periods intersecting the same interval to remain
  distinct.

## Value

A data frame with the original columns and six additional columns:
`split_start`, `split_end`, `split_interval`, `split_period`,
`split_duration`, and `split_outcome`. `split_period` is an ordered
factor suitable for `set_vars(period = "split_period")`.

## Examples

``` r
dat <- data.frame(
    id = 1,
    period = "observed",
    start = 10,
    duration = 10,
    count = 2,
    event1 = 2,
    event2 = 9
)
split_time(
    dat,
    start = "start",
    duration = "duration",
    outcome = "count",
    event_times = c("event1", "event2"),
    interval = 7,
    origin = 0,
    period = "period"
)
#>   id   period start duration count event1 event2 split_start split_end
#> 1  1 observed    10       10     2      2      9          10        13
#> 2  1 observed    10       10     2      2      9          14        19
#>   split_interval split_period split_duration split_outcome
#> 1              1   observed:1              4             1
#> 2              2   observed:2              6             1
```
