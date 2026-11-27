# Transpose results object

Transposes a Results object (as created by
[`analyse()`](https://openpharma.github.io/rbmi/reference/analyse.md))
in order to group the same estimates together into vectors.

## Usage

``` r
transpose_results(results, components)
```

## Arguments

- results:

  A list of results.

- components:

  a character vector of components to extract (i.e. `"est", "se"`).

## Details

Essentially this function takes an object of the format:

    x <- list(
        list(
            "trt1" = list(
                est = 1,
                se  = 2
            ),
            "trt2" = list(
                est = 3,
                se  = 4
            )
        ),
        list(
            "trt1" = list(
                est = 5,
                se  = 6
            ),
            "trt2" = list(
                est = 7,
                se  = 8
            )
        )
    )

and produces:

    list(
        trt1 = list(
            est = c(1,5),
            se = c(2,6)
        ),
        trt2 = list(
            est = c(3,7),
            se = c(4,8)
        )
    )
