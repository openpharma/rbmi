# Least Square Means

Estimates the least square means from a linear model. The exact
implementation / interpretation depends on the weighting scheme; see the
weighting section for more information.

## Usage

``` r
lsmeans(
  model,
  ...,
  .weights = c("counterfactual", "equal", "proportional_em", "proportional")
)
```

## Arguments

- model:

  A model created by `lm`.

- ...:

  Fixes specific variables to specific values i.e. `trt = 1` or
  `age = 50`. The name of the argument must be the name of the variable
  within the dataset.

- .weights:

  Character, either `"counterfactual"` (default), `"equal"`,
  `"proportional_em"` or `"proportional"`. Specifies the weighting
  strategy to be used when calculating the lsmeans. See the weighting
  section for more details.

## Weighting

### Counterfactual

For `weights = "counterfactual"` (the default) the lsmeans are obtained
by taking the average of the predicted values for each patient after
assigning all patients to each arm in turn. This approach is equivalent
to standardization or g-computation. In comparison to `emmeans` this
approach is equivalent to:

    emmeans::emmeans(model, specs = "<treatment>", counterfactual = "<treatment>")

Note that to ensure backwards compatibility with previous versions of
`rbmi` `weights = "proportional"` is an alias for
`weights = "counterfactual"`. To get results consistent with `emmeans`'s
`weights = "proportional"` please use `weights = "proportional_em"`.

### Equal

For `weights = "equal"` the lsmeans are obtained by taking the model
fitted value of a hypothetical patient whose covariates are defined as
follows:

- Continuous covariates are set to `mean(X)`

- Dummy categorical variables are set to `1/N` where `N` is the number
  of levels

- Continuous \* continuous interactions are set to `mean(X) * mean(Y)`

- Continuous \* categorical interactions are set to `mean(X) * 1/N`

- Dummy categorical \* categorical interactions are set to `1/N * 1/M`

In comparison to `emmeans` this approach is equivalent to:

    emmeans::emmeans(model, specs = "<treatment>", weights = "equal")

### Proportional

For `weights = "proportional_em"` the lsmeans are obtained as per
`weights = "equal"` except instead of weighting each observation equally
they are weighted by the proportion in which the given combination of
categorical values occurred in the data. In comparison to `emmeans` this
approach is equivalent to:

    emmeans::emmeans(model, specs = "<treatment>", weights = "proportional")

Note that this is not to be confused with `weights = "proportional"`
which is an alias for `weights = "counterfactual"`.

## Fixing

Regardless of the weighting scheme any named arguments passed via `...`
will fix the value of the covariate to the specified value. For example,
`lsmeans(model, trt = "A")` will fix the dummy variable `trtA` to 1 for
all patients (real or hypothetical) when calculating the lsmeans.

See the references for similar implementations as done in SAS and in R
via the `emmeans` package.

## References

<https://CRAN.R-project.org/package=emmeans>

<https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.3/statug/statug_glm_details41.htm>

## Examples

``` r
if (FALSE) { # \dontrun{
mod <- lm(Sepal.Length ~ Species + Petal.Length, data = iris)
lsmeans(mod)
lsmeans(mod, Species = "virginica")
lsmeans(mod, Species = "versicolor")
lsmeans(mod, Species = "versicolor", Petal.Length = 1)
} # }
```
