library(testthat)
library(rbmi)

Sys.setenv(RBMI_ENABLE_CACHE = "false")
options("rbmi.enable_cache" = FALSE)

test_check("rbmi")
