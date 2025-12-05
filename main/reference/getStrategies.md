# Get imputation strategies

Returns a list defining the imputation strategies to be used to create
the multivariate normal distribution parameters by merging those of the
source group and reference group per patient.

## Usage

``` r
getStrategies(...)
```

## Arguments

- ...:

  User defined methods to be added to the return list. Input must be a
  function.

## Details

By default Jump to Reference (JR), Copy Reference (CR), Copy Increments
in Reference (CIR), Last Mean Carried Forward (LMCF) and Missing at
Random (MAR) are defined.

The user can define their own strategy functions (or overwrite the
pre-defined ones) by specifying a named input to the function i.e.
`NEW = function(...) ...`. Only exception is MAR which cannot be
overwritten.

All user defined functions must take 3 inputs: `pars_group`, `pars_ref`
and `index_mar`. `pars_group` and `pars_ref` are both lists with
elements `mu` and `sigma` representing the multivariate normal
distribution parameters for the subject's current group and reference
group respectively. `index_mar` will be a logical vector specifying
which visits the subject met the MAR assumption at. The function must
return a list with elements `mu` and `sigma`. See the implementation of
[`strategy_JR()`](https://insightsengineering.github.io/rbmi/reference/strategies.md)
for an example.

## Examples

``` r
if (FALSE) { # \dontrun{
getStrategies()
getStrategies(
    NEW = function(pars_group, pars_ref, index_mar) code ,
    JR = function(pars_group, pars_ref, index_mar)  more_code
)
} # }
```
