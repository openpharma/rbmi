# Match PPM binaries to the container's OS release as the base image upgrades.
os_release <- readLines("/etc/os-release")
os_codename <- sub(
    "^VERSION_CODENAME=",
    "",
    grep("^VERSION_CODENAME=", os_release, value = TRUE)
)
os_codename <- gsub("^['\"]|['\"]$", "", os_codename)
if (length(os_codename) != 1L ||
    !grepl("^[a-z][a-z0-9-]*$", os_codename)) {
    stop("Expected a valid VERSION_CODENAME in /etc/os-release")
}

# Configure useragent to enable binary package installation from PPM
options(
    repos = c(
        CRAN = sprintf(
            "https://packagemanager.posit.co/cran/__linux__/%s/latest",
            os_codename
        )
    ),
    "HTTPUserAgent" = sprintf(
        "R/%s R (%s)",
        getRversion(),
        paste(
            getRversion(),
            R.version["platform"],
            R.version["arch"],
            R.version["os"]
        )
    )
)

# Throw errors if any warnings arise
options(warn = 2)

if (!requireNamespace("desc", quietly = TRUE)) {
    install.packages("desc")
}


# Get a list of all packages that we claim we depend on in the DESCRIPTION file
pkgs <- desc::desc("DESCRIPTION")$get_deps()$package |> unique()

# Add on additional packages that might be needed in the future
pkgs <- c(
    pkgs,
    "tidyverse",
    "devtools",
    "jinjar",
    "tidymodels",
    "languageserver",
    "fs",
    "assertthat",
    "lifecycle"
)


# R will error if you try to update the base packages so remove them
# if they are in any of the imports / suggests / depends list
base_pkgs <- c(
    "KernSmooth",
    "class",
    "foreign",
    "methods",
    "rpart",
    "survival",
    "MASS",
    "cluster",
    "grDevices",
    "mgcv",
    "spatial",
    "tcltk",
    "Matrix",
    "codetools",
    "graphics",
    "nlme",
    "splines",
    "tools",
    "base",
    "compiler",
    "grid",
    "nnet",
    "stats",
    "translations",
    "boot",
    "datasets",
    "lattice",
    "parallel",
    "stats4",
    "utils",
    "R"
)
pkgs <- pkgs[!pkgs %in% base_pkgs]

install.packages(pkgs, dependencies = TRUE)

# Install cmdstanr (not available from CRAN)
install.packages(
    "cmdstanr",
    repos = c("https://stan-dev.r-universe.dev", getOption("repos"))
)
