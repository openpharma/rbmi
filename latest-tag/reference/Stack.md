# R6 Class for a FIFO stack

This is a simple stack object offering add / pop functionality

## Public fields

- `stack`:

  A list containing the current stack

## Methods

### Public methods

- [`Stack$add()`](#method-Stack-add)

- [`Stack$pop()`](#method-Stack-pop)

- [`Stack$clone()`](#method-Stack-clone)

------------------------------------------------------------------------

### Method `add()`

Adds content to the end of the stack (must be a list)

#### Usage

    Stack$add(x)

#### Arguments

- `x`:

  content to add to the stack

------------------------------------------------------------------------

### Method `pop()`

Retrieve content from the stack

#### Usage

    Stack$pop(i)

#### Arguments

- `i`:

  the number of items to retrieve from the stack. If there are less than
  `i` items left on the stack it will just return everything that is
  left.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Stack$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
