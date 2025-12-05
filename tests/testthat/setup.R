# Run before any test
#
# Note:
#   - This file will be loaded by devtools::test()
#   - This file will NOT be loaded by devtools::load_all()
#
# https://testthat.r-lib.org/articles/special-files.html#setup-files
#

# Default cache to being disabled unless running a core or extended tests
if (is_core_test()) {
    options("rbmi.enable_cache" = TRUE)
}
