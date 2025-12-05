# Convert indicator to index

Converts a string of 0's and 1's into index positions of the 1's padding
the results by 0's so they are all the same length

## Usage

``` r
as_indices(x)
```

## Arguments

- x:

  a character vector whose values are all either "0" or "1". All
  elements of the vector must be the same length

## Details

i.e.

    patmap(c("1101", "0001"))  ->   list(c(1,2,4,999), c(4,999, 999, 999))
