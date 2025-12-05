# rbmi settings

Define settings that modify the behaviour of the `rbmi` package

Each of the following are the name of options that can be set via:

    options(<option_name> = <value>)

### `rbmi.cache_dir`

Default = [`tempfile()`](https://rdrr.io/r/base/tempfile.html)

Directory to store compiled Stan models in to avoid having to
re-compile. If the environment variable `RBMI_CACHE_DIR` has been set
this will be used as the default value. Note that if you are running
rbmi in multiple R processes at the same time (that is say multiple
calls to `Rscript` at once) then there is a theoretical risk of the
processes breaking each other as they attempt to read/write to the same
cache folder at the same time. To avoid this potential issue it is
recommended to leave this value at the default which will result in a
unique cache for each process

### `rbmi.enable_cache`

Default = `TRUE`

If `TRUE` then the package will attempt to cache compiled Stan models to
the `rbmi.cache_dir` directory. If `FALSE` then the package will
re-compile the Stan model each time it is required. If the environment
variable `RBMI_ENABLE_CACHE` has been set this will be used as the
default value.

## Usage

``` r
set_options()
```

## Examples

``` r
if (FALSE) { # \dontrun{
options(rbmi.cache_dir = "some/directory/path")
options(rbmi.enable_cache = FALSE)
} # }
```
