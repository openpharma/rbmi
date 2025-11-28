
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
# https://cran.r-project.org/doc/manuals/r-release/R-ints.html#Tools
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

note_phrase="checking for new files in some other directories ... NOTE"
if grep -q "${note_phrase}" ${temp_dir}/*.Rcheck/00check.log; then
    echo "ERROR: Found NOTE about new files in other directories"
    exit 1
fi

# Check for status line
if ! grep -q "^Status" ${temp_dir}/*.Rcheck/00check.log; then
    echo "ERROR: No status line found in R CMD check log"
    exit 1
fi

# Check for errors
if grep -q "ERROR" ${temp_dir}/*.Rcheck/00check.log; then
    echo "ERROR: R CMD check has errors"
    exit 1
fi

# Check for warnings
if grep -q "WARNING" ${temp_dir}/*.Rcheck/00check.log; then
    echo "ERROR: R CMD check has warnings"
    exit 1
fi

exit 0
