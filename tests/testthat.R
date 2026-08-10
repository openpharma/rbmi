library(testthat)
library(rbmi)

# Disable cache by default during unit tests
options("rbmi.enable_cache" = FALSE)

test_check("rbmi")
