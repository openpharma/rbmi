# Invert and derive indexes

Takes a list of elements and creates a new list containing 1 entry per
unique element value containing the indexes of which original elements
it occurred in.

## Usage

``` r
invert_indexes(x)
```

## Arguments

- x:

  list of elements to invert and calculate index from (see details).

## Details

This functions purpose is best illustrated by an example:

input:

    list( c("A", "B", "C"), c("A", "A", "B"))}

becomes:

    list( "A" = c(1,2,2), "B" = c(1,2), "C" = 1 )
