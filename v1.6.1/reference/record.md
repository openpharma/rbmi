# Capture all Output

This function silences all warnings, errors & messages and instead
returns a list containing the results (if it didn't error) + the warning
and error messages as character vectors.

## Usage

``` r
record(expr)
```

## Arguments

- expr:

  An expression to be executed

## Value

A list containing

- **results** - The object returned by `expr` or
  [`list()`](https://rdrr.io/r/base/list.html) if an error was thrown

- **warnings** - NULL or a character vector if warnings were thrown

- **errors** - NULL or a string if an error was thrown

- **messages** - NULL or a character vector if messages were produced

## Examples

``` r
if (FALSE) { # \dontrun{
record({
  x <- 1
  y <- 2
  warning("something went wrong")
  message("O nearly done")
  x + y
})
} # }
```
