
unset RBMI_CACHE_DIR
export R_TEST_FULL=FALSE
export R_TEST_LOCAL=FALSE

echo "
Debug:
-------
PWD          = $(pwd)
R_TEST_FULL  = ${R_TEST_FULL}
R_TEST_LOCAL = ${R_TEST_LOCAL}

"

PKGDIR=$(pwd)
temp_dir=$(mktemp -d)
cd ${temp_dir}

# R CMD CHECK args
export R_KEEP_PKG_SOURCE=yes
export _R_CHECK_DONTTEST_EXAMPLES_=true
export _R_CHECK_THINGS_IN_OTHER_DIRS_=true

R CMD build --no-manual "${PKGDIR}"
R CMD check \
    --run-donttest \
    --no-manual \
    --output=$temp_dir $temp_dir/*.tar.gz

if [ $? -ne 0 ]; then
    exit 1
fi

if grep -q "checking for new files in some other directories ... NOTE" ${temp_dir}/*.Rcheck/00check.log; then
    echo "ERROR: Found NOTE about new files in other directories"
    exit 1
fi

exit 0
