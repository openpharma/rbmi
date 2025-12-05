# Find Stan File

Finds a Stan file either in the local `inst/stan` directory or in the
system package directory.

## Usage

``` r
find_stan_file(file, subdir = "")
```

## Arguments

- file:

  The name of the Stan file to find.

- subdir:

  Optional subdirectory within `inst/stan` where the file might be
  located.

## Value

The full path to the Stan file if found, otherwise an error is raised.
