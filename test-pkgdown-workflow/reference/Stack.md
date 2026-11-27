# R6 Class for a FIFO stack

This is a simple stack object offering add / pop functionality

## Value

A `Stack` generator object (an
[R6::R6Class](https://r6.r-lib.org/reference/R6Class.html) generator).
Call `Stack$new()` to create an instance, which exposes `add()` and
`pop()` methods for storing and retrieving elements in
first-in-first-out order.

## Public fields

- `stack`:

  A list containing the current stack

## Methods

### Public methods

- [`Stack$add()`](#method-Stack-add)

- [`Stack$pop()`](#method-Stack-pop)

- [`Stack$clone()`](#method-Stack-clone)

------------------------------------------------------------------------

### `Stack$add()`

Adds content to the end of the stack (must be a list)

#### Usage

    Stack$add(x)

#### Arguments

- `x`:

  content to add to the stack

------------------------------------------------------------------------

### `Stack$pop()`

Retrieve content from the stack

#### Usage

    Stack$pop(i)

#### Arguments

- `i`:

  the number of items to retrieve from the stack. If there are less than
  `i` items left on the stack it will just return everything that is
  left.

------------------------------------------------------------------------

### `Stack$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Stack$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
