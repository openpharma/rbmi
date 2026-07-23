# Is package in development mode?

Returns `TRUE` if the package is being developed on i.e. you have a
local copy of the source code which you are actively editing Returns
`FALSE` otherwise

## Usage

``` r
is_in_rbmi_development()
```

## Details

Main use of this function is in parallel processing to indicate whether
the sub-processes need to load the current development version of the
code or whether they should load the main installed package on the
system
