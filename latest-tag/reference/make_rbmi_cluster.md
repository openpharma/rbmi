# Create a `rbmi` ready cluster

Create a `rbmi` ready cluster

## Usage

``` r
make_rbmi_cluster(ncores = 1, objects = NULL, packages = NULL)
```

## Arguments

- ncores:

  Number of parallel processes to use or an existing cluster to make use
  of

- objects:

  a named list of objects to export into the sub-processes

- packages:

  a character vector of libraries to load in the sub-processes

  This function is a wrapper around
  [`parallel::makePSOCKcluster()`](https://rdrr.io/r/parallel/makeCluster.html)
  but takes care of configuring `rbmi` to be used in the sub-processes
  as well as loading user defined objects and libraries and setting the
  seed for reproducibility.

  If `ncores` is `1` this function will return `NULL`.

  If `ncores` is a cluster created via
  [`parallel::makeCluster()`](https://rdrr.io/r/parallel/makeCluster.html)
  then this function just takes care of inserting the relevant `rbmi`
  objects into the existing cluster.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage
make_rbmi_cluster(5)

# User objects + libraries
VALUE <- 5
myfun <- function(x) {
    x + day(VALUE) # From lubridate::day()
}
make_rbmi_cluster(5, list(VALUE = VALUE, myfun = myfun), c("lubridate"))

# Using a already created cluster
cl <- parallel::makeCluster(5)
make_rbmi_cluster(cl)
} # }
```
