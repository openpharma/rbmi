
unset RBMI_CACHE_DIR
export RBMI_TEST_EXTENDED=FALSE
export RBMI_TEST_CORE=FALSE

echo "
Debug:
-------
PWD                 = $(pwd)
RBMI_TEST_CORE      = ${RBMI_TEST_CORE}
RBMI_TEST_EXTENDED  = ${RBMI_TEST_EXTENDED}

"

PKGDIR=$(pwd)
temp_dir=$(mktemp -d)
cd ${temp_dir}

# R CMD CHECK args
# https://cran.r-project.org/doc/manuals/r-release/R-ints.html#Tools

# Arguments to implement --as-cran
# Manually specified to allow for tweaking as needed
export _R_CHECK_CRAN_INCOMING_=TRUE
export _R_CHECK_CRAN_INCOMING_REMOTE_=TRUE
export _R_CHECK_VC_DIRS_=TRUE
export _R_CHECK_TIMINGS_=10
export _R_CHECK_INSTALL_DEPENDS_=TRUE
export _R_CHECK_SUGGESTS_ONLY_=TRUE
export _R_CHECK_NO_RECOMMENDED_=TRUE
export _R_CHECK_EXECUTABLES_EXCLUSIONS_=FALSE
export _R_CHECK_DOC_SIZES2_=TRUE
export _R_CHECK_CODE_ASSIGN_TO_GLOBALENV_=TRUE
export _R_CHECK_CODE_ATTACH_=TRUE
export _R_CHECK_CODE_DATA_INTO_GLOBALENV_=TRUE
export _R_CHECK_CODE_USAGE_VIA_NAMESPACES_=TRUE
export _R_CHECK_DOT_FIRSTLIB_=TRUE
export _R_CHECK_DEPRECATED_DEFUNCT_=TRUE
export _R_CHECK_REPLACING_IMPORTS_=TRUE
export _R_CHECK_SCREEN_DEVICE_=stop
export _R_CHECK_TOPLEVEL_FILES_=TRUE
export _R_CHECK_OVERWRITE_REGISTERED_S3_METHODS_=TRUE
export _R_CHECK_PRAGMAS_=TRUE
export _R_CHECK_COMPILATION_FLAGS_=TRUE
export _R_CHECK_R_DEPENDS_=warn
export _R_CHECK_SERIALIZATION_=TRUE
export _R_CHECK_R_ON_PATH_=TRUE
export _R_CHECK_PACKAGES_USED_IN_TESTS_USE_SUBDIRS_=TRUE
export _R_CHECK_SHLIB_OPENMP_FLAGS_=TRUE
export _R_CHECK_CONNECTIONS_LEFT_OPEN_=TRUE
export _R_CHECK_FUTURE_FILE_TIMESTAMPS_=TRUE
export _R_CHECK_AUTOCONF_=true
export _R_CHECK_DATALIST_=true
export _R_CHECK_THINGS_IN_CHECK_DIR_=true
export _R_CHECK_THINGS_IN_TEMP_DIR_=true
export _R_CHECK_BASHISMS_=true
export _R_CHECK_ORPHANED_=true
export _R_CHECK_BOGUS_RETURN_=true
export _R_CHECK_MATRIX_DATA_=TRUE
export _R_CHECK_CODE_CLASS_IS_STRING_=true
export _R_CHECK_RD_VALIDATE_RD2HTML_=true
export _R_CHECK_RD_MATH_RENDERING_=true
export _R_CHECK_NEWS_IN_PLAIN_TEXT_=true
export _R_CHECK_BROWSER_NONINTERACTIVE_=true
export _R_CHECK_URLS_SHOW_301_STATUS_=true
export _R_CHECK_UNDOC_USE_ALL_NAMES_=true
export _R_CHECK_S3_METHODS_SHOW_POSSIBLE_ISSUES_=true
export _R_CHECK_RD_NOTE_LOST_BRACES_=true
export _R_CHECK_XREFS_NOTE_MISSING_PACKAGE_ANCHORS_=true
export _R_CHECK_PACKAGES_USED_IN_DEMO_=true

# Additional arguments to replicate donttest error
# https://github.com/openpharma/rbmi/issues/537
export R_KEEP_PKG_SOURCE=yes
export _R_CHECK_DONTTEST_EXAMPLES_=true
export _R_CHECK_THINGS_IN_OTHER_DIRS_=true


R CMD build "${PKGDIR}"
R CMD check \
    --run-donttest \
    --output=${temp_dir} \
    ${temp_dir}/*.tar.gz

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
