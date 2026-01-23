# as_ascii_table

This function takes a data.frame and attempts to convert it into a
simple ascii format suitable for printing to the screen It is assumed
all variable values have a as.character() method in order to cast them
to character.

## Usage

``` r
as_ascii_table(dat, line_prefix = "  ", pcol = NULL)
```

## Arguments

- dat:

  Input dataset to convert into a ascii table

- line_prefix:

  Symbols to prefix infront of every line of the table

- pcol:

  name of column to be handled as a p-value. Sets the value to \<0.001
  if the value is 0 after rounding
