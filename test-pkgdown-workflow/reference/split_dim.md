# Transform array into list of arrays

Transform an array into list of arrays where the listing is performed on
a given dimension.

## Usage

``` r
split_dim(a, n)
```

## Arguments

- a:

  Array with number of dimensions at least 2.

- n:

  Positive integer. Dimension of `a` to be listed.

## Value

A list of length `n` of arrays with number of dimensions equal to the
number of dimensions of `a` minus 1.

## Details

For example, if `a` is a 3 dimensional array and `n = 1`,
`split_dim(a,n)` returns a list of 2 dimensional arrays (i.e. a list of
matrices) where each element of the list is `a[i, , ]`, where `i` takes
values from 1 to the length of the first dimension of the array.

Example:

inputs: `a <- array( c(1,2,3,4,5,6,7,8,9,10,11,12), dim = c(3,2,2))`,
which means that:

    a[1,,]     a[2,,]     a[3,,]

    [,1] [,2]  [,1] [,2]  [,1] [,2]
    ---------  ---------  ---------
     1    7     2    8     3    9
     4    10    5    11    6    12

`n <- 1`

output of `res <- split_dim(a,n)` is a list of 3 elements:

    res[[1]]   res[[2]]   res[[3]]

    [,1] [,2]  [,1] [,2]  [,1] [,2]
    ---------  ---------  ---------
     1    7     2    8     3    9
     4    10    5    11    6    12
