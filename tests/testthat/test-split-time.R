suppressPackageStartupMessages({
    library(testthat)
})


test_that("split_time reproduces the 91-day seasonal prototype", {
    data <- utils::read.csv(
        system.file(
            "extdata",
            "sim_rogeretal.csv",
            package = "rbmi"
        )
    )
    data$MyStart <- data$StartDate + data$Lengthsofar

    actual <- split_time(
        data = data,
        start = "MyStart",
        duration = "Length",
        outcome = "Observed_Count",
        event_times = paste0("Times", 1:20),
        interval = 91,
        origin = 0,
        period = "period"
    )
    totals <- stats::aggregate(
        cbind(split_duration, split_outcome) ~ patient + period,
        data = actual,
        FUN = sum,
        na.action = na.pass
    )
    expected <- data[, c("patient", "period", "Length", "Observed_Count")]
    totals <- merge(totals, expected, by = c("patient", "period"), sort = FALSE)

    expect_equal(nrow(actual), 3518)
    expect_equal(nlevels(actual$split_period), 24)
    expect_equal(
        sum(is.na(actual$split_outcome) & actual$split_duration > 0),
        204
    )
    expect_equal(
        length(unique(actual$patient[is.na(actual$split_outcome)])),
        83
    )
    expect_equal(totals$split_duration, totals$Length)
    observed <- totals$period != 3
    expect_equal(
        totals$split_outcome[observed],
        totals$Observed_Count[observed]
    )
    expect_true(all(is.na(totals$split_outcome[!observed])))
})


test_that("split_time supports calendar months and weeks", {
    monthly <- data.frame(
        start = as.Date("2024-01-30"),
        duration = 5,
        count = 2,
        event1 = 1,
        event2 = 4
    )
    actual_month <- split_time(
        monthly,
        start = "start",
        duration = "duration",
        outcome = "count",
        event_times = c("event1", "event2"),
        interval = "month"
    )

    expect_equal(actual_month$split_duration, c(2, 3))
    expect_equal(actual_month$split_outcome, c(1L, 1L))

    weekly <- monthly
    weekly$start <- 10
    actual_week <- split_time(
        weekly,
        start = "start",
        duration = "duration",
        outcome = "count",
        event_times = c("event1", "event2"),
        interval = "week",
        origin = 0
    )
    expect_equal(sum(actual_week$split_duration), weekly$duration)
    expect_equal(sum(actual_week$split_outcome), weekly$count)
})


test_that("split_time assigns fixed-width boundary days to the next interval", {
    data <- data.frame(
        start = 0,
        duration = 8,
        count = 2,
        event1 = 1,
        event2 = 8
    )

    actual <- split_time(
        data,
        start = "start",
        duration = "duration",
        outcome = "count",
        event_times = c("event1", "event2"),
        interval = 7,
        origin = 0
    )

    expect_equal(actual$split_interval, c(0L, 1L))
    expect_equal(actual$split_start, c(0, 7))
    expect_equal(actual$split_end, c(6, 7))
    expect_equal(actual$split_duration, c(7, 1))
    expect_equal(actual$split_outcome, c(1L, 1L))
})


test_that("split_time requires event times to allocate positive counts", {
    data <- data.frame(start = 1, duration = 10, count = 1)
    expect_error(
        split_time(data, "start", "duration", "count", interval = 5),
        "event_times"
    )
})


test_that("split_time rejects times between whole days instead of dropping events", {
    # Cells use inclusive whole-day endpoints (e.g. 0-6 and 7-13). An event at
    # time 6.5 belongs to neither cell, so such inputs must be rejected.
    split <- function(start, event, origin = NULL) {
        split_time(
            data.frame(start = start, duration = 14, count = 1, event = event),
            "start",
            "duration",
            "count",
            event_times = "event",
            interval = 7,
            origin = origin
        )
    }
    expect_error(split(0, 7.5), "whole numbers")
    expect_error(split(0.5, 7), "whole-number")
    expect_error(split(0, 7, origin = 0.5), "whole-number")

    # Whole-number inputs conserve the count
    expect_identical(sum(split(0, 7)$split_outcome), 1L)
})
