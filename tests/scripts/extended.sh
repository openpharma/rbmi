#!/usr/bin/env bash
set -euo pipefail

export RBMI_CACHE_DIR="${RBMI_CACHE_DIR:-$(pwd)/local}"
export RBMI_TEST_EXTENDED=TRUE
export RBMI_TEST_CORE=TRUE

echo "
Debug:
-------
PWD                 = $(pwd)
RBMI_TEST_CORE      = ${RBMI_TEST_CORE}
RBMI_TEST_EXTENDED  = ${RBMI_TEST_EXTENDED}

"

Rscript -e "devtools::test(stop_on_failure=TRUE)"
