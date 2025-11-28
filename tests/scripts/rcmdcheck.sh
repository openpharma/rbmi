
unset RBMI_CACHE_DIR
export RBMI_TEST_FULL=FALSE
export RBMI_TEST_LOCAL=FALSE

echo "
Debug:
-------
PWD             = $(pwd)
RBMI_TEST_FULL  = ${RBMI_TEST_FULL}
RBMI_TEST_LOCAL = ${RBMI_TEST_LOCAL}

"

PKGDIR=$(pwd)
temp_dir=$(mktemp -d)
cd ${temp_dir}

R CMD build ${PKGDIR}
R CMD check --as-cran --output=$temp_dir $temp_dir/*.tar.gz
