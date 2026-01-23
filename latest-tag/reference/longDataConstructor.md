# R6 Class for Storing / Accessing & Sampling Longitudinal Data

A `longdata` object allows for efficient storage and recall of
longitudinal datasets for use in bootstrap sampling. The object works by
de-constructing the data into lists based upon subject id thus enabling
efficient lookup.

## Details

The object also handles multiple other operations specific to `rbmi`
such as defining whether an outcome value is MAR / Missing or not as
well as tracking which imputation strategy is assigned to each subject.

It is recognised that this objects functionality is fairly overloaded
and is hoped that this can be split out into more area specific objects
/ functions in the future. Further additions of functionality to this
object should be avoided if possible.

## Public fields

- `data`:

  The original dataset passed to the constructor (sorted by id and
  visit)

- `vars`:

  The vars object (list of key variables) passed to the constructor

- `visits`:

  A character vector containing the distinct visit levels

- `ids`:

  A character vector containing the unique ids of each subject in
  `self$data`

- `formula`:

  A formula expressing how the design matrix for the data should be
  constructed

- `strata`:

  A numeric vector indicating which strata each corresponding value of
  `self$ids` belongs to. If no stratification variable is defined this
  will default to 1 for all subjects (i.e. same group). This field is
  only used as part of the `self$sample_ids()` function to enable
  stratified bootstrap sampling

- `ice_visit_index`:

  A list indexed by subject storing the index number of the first visit
  affected by the ICE. If there is no ICE then it is set equal to the
  number of visits plus 1.

- `values`:

  A list indexed by subject storing a numeric vector of the original
  (unimputed) outcome values

- `group`:

  A list indexed by subject storing a single character indicating which
  imputation group the subject belongs to as defined by
  `self$data[id, self$ivars$group]` It is used to determine what
  reference group should be used when imputing the subjects data.

- `is_mar`:

  A list indexed by subject storing logical values indicating if the
  subjects outcome values are MAR or not. This list is defaulted to TRUE
  for all subjects & outcomes and is then modified by calls to
  `self$set_strategies()`. Note that this does not indicate which values
  are missing, this variable is True for outcome values that either
  occurred before the ICE visit or are post the ICE visit and have an
  imputation strategy of MAR

- `strategies`:

  A list indexed by subject storing a single character value indicating
  the imputation strategy assigned to that subject. This list is
  defaulted to "MAR" for all subjects and is then modified by calls to
  either `self$set_strategies()` or `self$update_strategies()`

- `strategy_lock`:

  A list indexed by subject storing a single logical value indicating
  whether a patients imputation strategy is locked or not. If a strategy
  is locked it means that it can't change from MAR to non-MAR.
  Strategies can be changed from non-MAR to MAR though this will trigger
  a warning. Strategies are locked if the patient is assigned a MAR
  strategy and has non-missing after their ICE date. This list is
  populated by a call to `self$set_strategies()`.

- `indexes`:

  A list indexed by subject storing a numeric vector of indexes which
  specify which rows in the original dataset belong to this subject i.e.
  to recover the full data for subject "pt3" you can use
  `self$data[self$indexes[["pt3"]],]`. This may seem redundant over
  filtering the data directly however it enables efficient bootstrap
  sampling of the data i.e.

      indexes <- unlist(self$indexes[c("pt3", "pt3")])
      self$data[indexes,]

  This list is populated during the object initialisation.

- `is_missing`:

  A list indexed by subject storing a logical vector indicating whether
  the corresponding outcome of a subject is missing. This list is
  populated during the object initialisation.

- `is_post_ice`:

  A list indexed by subject storing a logical vector indicating whether
  the corresponding outcome of a subject is post the date of their ICE.
  If no ICE data has been provided this defaults to False for all
  observations. This list is populated by a call to
  `self$set_strategies()`.

## Methods

### Public methods

- [`longDataConstructor$get_data()`](#method-longdata-get_data)

- [`longDataConstructor$add_subject()`](#method-longdata-add_subject)

- [`longDataConstructor$validate_ids()`](#method-longdata-validate_ids)

- [`longDataConstructor$sample_ids()`](#method-longdata-sample_ids)

- [`longDataConstructor$extract_by_id()`](#method-longdata-extract_by_id)

- [`longDataConstructor$update_strategies()`](#method-longdata-update_strategies)

- [`longDataConstructor$set_strategies()`](#method-longdata-set_strategies)

- [`longDataConstructor$check_has_data_at_each_visit()`](#method-longdata-check_has_data_at_each_visit)

- [`longDataConstructor$set_strata()`](#method-longdata-set_strata)

- [`longDataConstructor$new()`](#method-longdata-new)

- [`longDataConstructor$clone()`](#method-longdata-clone)

------------------------------------------------------------------------

### Method `get_data()`

Returns a `data.frame` based upon required subject IDs. Replaces missing
values with new ones if provided.

#### Usage

    longDataConstructor$get_data(
      obj = NULL,
      nmar.rm = FALSE,
      na.rm = FALSE,
      idmap = FALSE
    )

#### Arguments

- `obj`:

  Either `NULL`, a character vector of subjects IDs or a imputation list
  object. See details.

- `nmar.rm`:

  Logical value. If `TRUE` will remove observations that are not
  regarded as MAR (as determined from `self$is_mar`).

- `na.rm`:

  Logical value. If `TRUE` will remove outcome values that are missing
  (as determined from `self$is_missing`).

- `idmap`:

  Logical value. If `TRUE` will add an attribute `idmap` which contains
  a mapping from the new subject ids to the old subject ids. See
  details.

#### Details

If `obj` is `NULL` then the full original dataset is returned.

If `obj` is a character vector then a new dataset consisting of just
those subjects is returned; if the character vector contains duplicate
entries then that subject will be returned multiple times.

If `obj` is an `imputation_df` object (as created by
[`imputation_df()`](https://openpharma.github.io/rbmi/reference/imputation_df.md))
then the subject ids specified in the object will be returned and
missing values will be filled in by those specified in the imputation
list object. i.e.

    obj <- imputation_df(
      imputation_single( id = "pt1", values = c(1,2,3)),
      imputation_single( id = "pt1", values = c(4,5,6)),
      imputation_single( id = "pt3", values = c(7,8))
    )
    longdata$get_data(obj)

Will return a `data.frame` consisting of all observations for `pt1`
twice and all of the observations for `pt3` once. The first set of
observations for `pt1` will have missing values filled in with
`c(1,2,3)` and the second set will be filled in by `c(4,5,6)`. The
length of the values must be equal to `sum(self$is_missing[[id]])`.

If `obj` is not `NULL` then all subject IDs will be scrambled in order
to ensure that they are unique i.e. If the `pt2` is requested twice then
this process guarantees that each set of observations be have a unique
subject ID number. The `idmap` attribute (if requested) can be used to
map from the new ids back to the old ids.

#### Returns

A `data.frame`.

------------------------------------------------------------------------

### Method `add_subject()`

This function decomposes a patient data from `self$data` and populates
all the corresponding lists i.e. `self$is_missing`, `self$values`,
`self$group`, etc. This function is only called upon the objects
initialization.

#### Usage

    longDataConstructor$add_subject(id)

#### Arguments

- `id`:

  Character subject id that exists within `self$data`.

------------------------------------------------------------------------

### Method `validate_ids()`

Throws an error if any element of `ids` is not within the source data
`self$data`.

#### Usage

    longDataConstructor$validate_ids(ids)

#### Arguments

- `ids`:

  A character vector of ids.

#### Returns

TRUE

------------------------------------------------------------------------

### Method [`sample_ids()`](https://openpharma.github.io/rbmi/reference/sample_ids.md)

Performs random stratified sampling of patient ids (with replacement)
Each patient has an equal weight of being picked within their strata
(i.e is not dependent on how many non-missing visits they had).

#### Usage

    longDataConstructor$sample_ids()

#### Returns

Character vector of ids.

------------------------------------------------------------------------

### Method `extract_by_id()`

Returns a list of key information for a given subject. Is a convenience
wrapper to save having to manually grab each element.

#### Usage

    longDataConstructor$extract_by_id(id)

#### Arguments

- `id`:

  Character subject id that exists within `self$data`.

------------------------------------------------------------------------

### Method `update_strategies()`

Convenience function to run self\$set_strategies(dat_ice, update=TRUE)
kept for legacy reasons.

#### Usage

    longDataConstructor$update_strategies(dat_ice)

#### Arguments

- `dat_ice`:

  A `data.frame` containing ICE information see
  [`impute()`](https://openpharma.github.io/rbmi/reference/impute.md)
  for the format of this dataframe.

------------------------------------------------------------------------

### Method `set_strategies()`

Updates the `self$strategies`, `self$is_mar`, `self$is_post_ice`
variables based upon the provided ICE information.

#### Usage

    longDataConstructor$set_strategies(dat_ice = NULL, update = FALSE)

#### Arguments

- `dat_ice`:

  a `data.frame` containing ICE information. See details.

- `update`:

  Logical, indicates that the ICE data should be used as an update. See
  details.

#### Details

See [`draws()`](https://openpharma.github.io/rbmi/reference/draws.md)
for the specification of `dat_ice` if `update=FALSE`. See
[`impute()`](https://openpharma.github.io/rbmi/reference/impute.md) for
the format of `dat_ice` if `update=TRUE`. If `update=TRUE` this function
ensures that MAR strategies cannot be changed to non-MAR in the presence
of post-ICE observations.

------------------------------------------------------------------------

### Method `check_has_data_at_each_visit()`

Ensures that all visits have at least 1 observed "MAR" observation.
Throws an error if this criteria is not met. This is to ensure that the
initial MMRM can be resolved.

#### Usage

    longDataConstructor$check_has_data_at_each_visit()

------------------------------------------------------------------------

### Method `set_strata()`

Populates the `self$strata` variable. If the user has specified
stratification variables The first visit is used to determine the value
of those variables. If no stratification variables have been specified
then everyone is defined as being in strata 1.

#### Usage

    longDataConstructor$set_strata()

------------------------------------------------------------------------

### Method `new()`

Constructor function.

#### Usage

    longDataConstructor$new(data, vars)

#### Arguments

- `data`:

  longitudinal dataset.

- `vars`:

  an `ivars` object created by
  [`set_vars()`](https://openpharma.github.io/rbmi/reference/set_vars.md).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    longDataConstructor$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
