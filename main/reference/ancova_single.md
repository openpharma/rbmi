# Implements an Analysis of Covariance (ANCOVA)

Performance analysis of covariance. See
[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md) for
full details.

## Usage

``` r
ancova_single(
  data,
  outcome,
  group,
  covariates,
  weights = c("counterfactual", "equal", "proportional_em", "proportional")
)
```

## Arguments

- data:

  A `data.frame` containing the data to be used in the model.

- outcome:

  Character, the name of the outcome variable in `data`.

- group:

  Character, the name of the group variable in `data`.

- covariates:

  Character vector containing the name of any additional covariates to
  be included in the model as well as any interaction terms.

- weights:

  Character, either `"counterfactual"` (default), `"equal"`,
  `"proportional_em"` or `"proportional"`. Specifies the weighting
  strategy to be used when calculating the lsmeans. See the weighting
  section for more details.

## Details

- `group` must be a factor variable with only 2 levels.

- `outcome` must be a continuous numeric variable.

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

## See also

[`ancova()`](https://openpharma.github.io/rbmi/reference/ancova.md)

## Examples

``` r
if (FALSE) { # \dontrun{
iris2 <- iris[ iris$Species %in% c("versicolor", "virginica"), ]
iris2$Species <- factor(iris2$Species)
ancova_single(iris2, "Sepal.Length", "Species", c("Petal.Length * Petal.Width"))
} # }
```
