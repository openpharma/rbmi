# Conversion of Character Vector into Stan Code Block List

Conversion of Character Vector into Stan Code Block List

## Usage

``` r
as_stan_fragments(x, stan_blocks = STAN_BLOCKS)
```

## Arguments

- x:

  the single Stan code vector.

- stan_blocks:

  reference list of Stan blocks.

## Value

A list with the Stan code blocks.

## Details

Function only works if code is in format

    data {
        <code>
    }
    model {
        <code>
    }

That is to say we do not support code in inline format i.e.

    data { <code> }
    model { <code> }

## Author

Craig Gower-Page (from `jmpost` R package)
