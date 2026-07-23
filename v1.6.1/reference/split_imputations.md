# Split a flat list of [`imputation_single()`](https://openpharma.github.io/rbmi/reference/imputation_single.md) into multiple [`imputation_df()`](https://openpharma.github.io/rbmi/reference/imputation_df.md)'s by ID

Split a flat list of
[`imputation_single()`](https://openpharma.github.io/rbmi/reference/imputation_single.md)
into multiple
[`imputation_df()`](https://openpharma.github.io/rbmi/reference/imputation_df.md)'s
by ID

## Usage

``` r
split_imputations(list_of_singles, split_ids)
```

## Arguments

- list_of_singles:

  A list of
  [`imputation_single()`](https://openpharma.github.io/rbmi/reference/imputation_single.md)'s

- split_ids:

  A list with 1 element per required split. Each element must contain a
  vector of "ID"'s which correspond to the
  [`imputation_single()`](https://openpharma.github.io/rbmi/reference/imputation_single.md)
  ID's that are required within that sample. The total number of ID's
  must by equal to the length of `list_of_singles`

## Details

This function converts a list of imputations from being structured per
patient to being structured per sample i.e. it converts

    obj <- list(
        imputation_single("Ben", numeric(0)),
        imputation_single("Ben", numeric(0)),
        imputation_single("Ben", numeric(0)),
        imputation_single("Harry", c(1, 2)),
        imputation_single("Phil", c(3, 4)),
        imputation_single("Phil", c(5, 6)),
        imputation_single("Tom", c(7, 8, 9))
    )

    index <- list(
        c("Ben", "Harry", "Phil", "Tom"),
        c("Ben", "Ben", "Phil")
    )

Into:

    output <- list(
        imputation_df(
            imputation_single(id = "Ben", values = numeric(0)),
            imputation_single(id = "Harry", values = c(1, 2)),
            imputation_single(id = "Phil", values = c(3, 4)),
            imputation_single(id = "Tom", values = c(7, 8, 9))
        ),
        imputation_df(
            imputation_single(id = "Ben", values = numeric(0)),
            imputation_single(id = "Ben", values = numeric(0)),
            imputation_single(id = "Phil", values = c(5, 6))
        )
    )
