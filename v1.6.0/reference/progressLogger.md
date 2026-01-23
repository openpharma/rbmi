# R6 Class for printing current sampling progress

Object is initalised with total number of iterations that are expected
to occur. User can then update the object with the `add` method to
indicate how many more iterations have just occurred. Every time `step`
\* 100 % of iterations have occurred a message is printed to the
console. Use the `quiet` argument to prevent the object from printing
anything at all

## Public fields

- `step`:

  real, percentage of iterations to allow before printing the progress
  to the console

- `step_current`:

  integer, the total number of iterations completed since progress was
  last printed to the console

- `n`:

  integer, the current number of completed iterations

- `n_max`:

  integer, total number of expected iterations to be completed acts as
  the denominator for calculating progress percentages

- `quiet`:

  logical holds whether or not to print anything

## Methods

### Public methods

- [`progressLogger$new()`](#method-progressLogger-new)

- [`progressLogger$add()`](#method-progressLogger-add)

- [`progressLogger$print_progress()`](#method-progressLogger-print_progress)

- [`progressLogger$clone()`](#method-progressLogger-clone)

------------------------------------------------------------------------

### Method `new()`

Create progressLogger object

#### Usage

    progressLogger$new(n_max, quiet = FALSE, step = 0.1)

#### Arguments

- `n_max`:

  integer, sets field `n_max`

- `quiet`:

  logical, sets field `quiet`

- `step`:

  real, sets field `step`

------------------------------------------------------------------------

### Method `add()`

Records that `n` more iterations have been completed this will add that
number to the current step count (`step_current`) and will print a
progress message to the log if the step limit (`step`) has been reached.
This function will do nothing if `quiet` has been set to `TRUE`

#### Usage

    progressLogger$add(n)

#### Arguments

- `n`:

  the number of successfully complete iterations since `add()` was last
  called

------------------------------------------------------------------------

### Method `print_progress()`

method to print the current state of progress

#### Usage

    progressLogger$print_progress()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    progressLogger$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
