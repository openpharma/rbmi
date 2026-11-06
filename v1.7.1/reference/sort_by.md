# Sort `data.frame`

Sorts a `data.frame` (ascending by default) based upon variables within
the dataset

## Usage

``` r
sort_by(df, vars = NULL, decreasing = FALSE)
```

## Arguments

- df:

  data.frame

- vars:

  character vector of variables

- decreasing:

  logical whether sort order should be in descending or ascending
  (default) order. Can be either a single logical value (in which case
  it is applied to all variables) or a vector which is the same length
  as `vars`

## Examples

``` r
if (FALSE) { # \dontrun{
sort_by(iris, c("Sepal.Length", "Sepal.Width"), decreasing = c(TRUE, FALSE))
} # }
```
