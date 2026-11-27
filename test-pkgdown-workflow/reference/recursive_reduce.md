# recursive_reduce

Utility function used to replicate
[`purrr::reduce`](https://purrr.tidyverse.org/reference/reduce.html).
Recursively applies a function to a list of elements until only 1
element remains

## Usage

``` r
recursive_reduce(.l, .f)
```

## Arguments

- .l:

  list of values to apply a function to

- .f:

  function to apply to each each element of the list in turn i.e.
  `.l[[1]] <- .f( .l[[1]] , .l[[2]]) ; .l[[1]] <- .f( .l[[1]] , .l[[3]])`
