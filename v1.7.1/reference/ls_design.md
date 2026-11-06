# Calculate design vector for the lsmeans

Calculates the design vector as required to generate the lsmean and
standard error. `ls_design_equal` calculates it by applying an equal
weight per covariate combination whilst `ls_design_proportional` applies
weighting proportional to the frequency in which the covariate
combination occurred in the actual dataset.

## Usage

``` r
ls_design_equal(data, frm, fix)

ls_design_counterfactual(data, frm, fix)

ls_design_proportional(data, frm, fix)
```

## Arguments

- data:

  A data.frame

- frm:

  Formula used to fit the original model

- fix:

  A named list of variables with fixed values
