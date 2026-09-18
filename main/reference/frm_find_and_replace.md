# Recursively find and replace symbols in a language object

This function traverses a language object (such as an expression or
call) and recursively replaces all occurrences of a specified symbol
with another symbol.

## Usage

``` r
frm_find_and_replace(expr, find_sym, replace_sym)
```

## Arguments

- find_sym:

  A symbol (as a name) to find within `frm`.

- replace_sym:

  A symbol (as a name) to replace `find_sym` with.

- frm:

  A language object (e.g., call, expression, or list of calls) to search
  and modify.

## Value

The modified language object with all instances of `find_sym` replaced
by `replace_sym`.

## Details

Replacement happens for symbols found within calls (recursively). A
`frm` that is itself a bare symbol equal to `find_sym` is returned
unchanged; this is not reachable from the
[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md) call
site because the input is always a formula (a call).

## Examples

``` r
if (FALSE) { # \dontrun{
expr <- quote(a + b * c)
frm_find_and_replace(expr, as.name("b"), as.name("x"))
# Returns: a + x * c
} # }
```
