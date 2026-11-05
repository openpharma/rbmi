# Install dependencies from the checked-out DESCRIPTION, retaining existing versions.
options(warn = 2)
remotes::install_deps(dependencies = TRUE, upgrade = "never")

# Older CI images contain noble binaries on a newer Ubuntu release. These
# packages appear installed to remotes, but cannot load their shared libraries.
# Rebuild only packages with unresolved system libraries until the corrected
# Docker image is published. Source builds use the current system's libraries.
if (identical(Sys.info()[["sysname"]], "Linux")) {
    installed <- installed.packages()
    broken <- vapply(seq_len(nrow(installed)), function(i) {
        libs <- list.files(
            file.path(installed[i, "LibPath"], installed[i, "Package"], "libs"),
            pattern = "\\.so$", recursive = TRUE, full.names = TRUE
        )
        any(vapply(libs, function(lib) {
            links <- suppressWarnings(system2(
                "ldd", shQuote(lib), stdout = TRUE, stderr = TRUE
            ))
            any(grepl("=> not found", links, fixed = TRUE))
        }, logical(1)))
    }, logical(1))
    packages <- unique(installed[broken, "Package"])
    if (length(packages)) {
        message("Rebuilding packages with missing system libraries: ",
                paste(packages, collapse = ", "))
        install.packages(packages, repos = "https://cloud.r-project.org",
                         type = "source")
    }
}

# Check in a fresh process: installation metadata alone does not establish that
# a package can load, and the installer may already have loaded old namespaces.
check <- paste(
    'deps <- desc::desc("DESCRIPTION")$get_deps()$package;',
    'deps <- unique(c(setdiff(deps, "R"), "devtools", "roxygen2", "xml2"));',
    'for (pkg in deps) {',
    '  message("Checking namespace: ", pkg);',
    '  loadNamespace(pkg);',
    '};',
    'message("Checking MMRM fit");',
    'mmrm::mmrm(FEV1 ~ RACE + ARMCD * AVISIT + us(AVISIT | USUBJID),',
    '           data = mmrm::fev_data, n_cores = 1, accept_singular = FALSE)'
)
status <- system2(file.path(R.home("bin"), "Rscript"), c("-e", shQuote(check)))
if (status != 0L) {
    stop("Dependency namespace checks failed; see the loader error above.")
}
