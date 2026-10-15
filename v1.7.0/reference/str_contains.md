# Does a string contain a substring

Returns a vector of `TRUE`/`FALSE` for each element of x if it contains
any element in `subs`

i.e.

    str_contains( c("ben", "tom", "harry"), c("e", "y"))
    [1] TRUE FALSE TRUE

## Usage

``` r
str_contains(x, subs)
```

## Arguments

- x:

  character vector

- subs:

  a character vector of substrings to look for
