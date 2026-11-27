# Render a Stan model template

Parses and renders a Stan file using the whitespace handling shared by
the package's top-level model templates.

## Usage

``` r
render_stan_model(file, data = list())
```

## Arguments

- file:

  Path to a Stan template file.

- data:

  Named list of values made available to the template.

## Value

The rendered Stan model code as a character string.
