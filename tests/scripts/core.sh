
export RBMI_CACHE_DIR="${RBMI_CACHE_DIR:-$(pwd)/local}"
export RBMI_TEST_EXTENDED=FALSE
export RBMI_TEST_CORE=TRUE

echo "
Debug:
-------
PWD                 = $(pwd)
RBMI_TEST_CORE      = ${RBMI_TEST_CORE}
RBMI_TEST_EXTENDED  = ${RBMI_TEST_EXTENDED}

"

Rscript -e "devtools::test()"
