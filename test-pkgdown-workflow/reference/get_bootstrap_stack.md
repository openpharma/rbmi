# Creates a stack object populated with bootstrapped samples

Function creates a
[`Stack()`](https://openpharma.github.io/rbmi/reference/Stack.md) object
and populated the stack with bootstrap samples based upon
`method$n_samples`

## Usage

``` r
get_bootstrap_stack(longdata, method, stack = Stack$new())
```

## Arguments

- longdata:

  A
  [`longDataConstructor()`](https://openpharma.github.io/rbmi/reference/longDataConstructor.md)
  object

- method:

  A `method` object

- stack:

  A [`Stack()`](https://openpharma.github.io/rbmi/reference/Stack.md)
  object (this is only exposed for unit testing purposes)
