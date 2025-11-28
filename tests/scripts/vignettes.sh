
export RBMI_CACHE_DIR="$(pwd)/local"
export RBMI_TEST_FULL=FALSE
export RBMI_TEST_LOCAL=TRUE

echo "
Debug:
-------
PWD             = $(pwd)
RBMI_TEST_FULL  = ${RBMI_TEST_FULL}
RBMI_TEST_LOCAL = ${RBMI_TEST_LOCAL}

"

Rscript vignettes/build.R
