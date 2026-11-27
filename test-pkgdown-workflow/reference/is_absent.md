# Is value absent

Returns true if a value is either NULL, NA or "". In the case of a
vector all values must be NULL/NA/"" for x to be regarded as absent.

## Usage

``` r
is_absent(x, na = TRUE, blank = TRUE)
```

## Arguments

- x:

  a value to check if it is absent or not

- na:

  do NAs count as absent

- blank:

  do blanks i.e. "" count as absent
