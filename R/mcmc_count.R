#' Prepare input data to run the Stan model for count outcome
#'
#' @description
#' Prepare input data to run the Stan model for count outcome.
#'
#' @param ddat A design matrix
#' @param subjid A vector of subject IDs
#' @param period A vector of period values
#' @param duration A vector of duration values
#' @param outcome A vector of integer outcome values (unscaled, i.e. raw counts)
#'
#' @return A `stan_data_count` object. A named list containing all the
#' required inputs as required by the `data{}` block of the Count Stan program:group
#'
#' - `N`: The number of patients
#' - `K`: The number of periods to analyze
#' - `P`: The number of design matrix columns in each period
#' - `y`: N x K matrix of outcome values for each period
#' - `X`: K x N x P array of design matrices for each period
#' - `log_offset`: N x K matrix of log offsets for each period
#' - `is_avail`: N x K matrix of 0/1 indicator whether
#'    the outcome is available for each patient for each period
prepare_stan_data_count <- function(
    ddat,
    subjid,
    period,
    duration,
    outcome
) {
    assert_that(
        is.factor(period) | is.character(period),
        is.numeric(duration) & all(duration >= 0),
        is.character(subjid) | is.factor(subjid),
        is.numeric(outcome) &
            all((outcome == trunc(outcome) & (outcome >= 0)) | is.na(outcome)),
        is.data.frame(ddat) | is.matrix(ddat),
        length(period) == length(duration),
        length(duration) == length(outcome),
        length(outcome) == length(subjid),
        nrow(ddat) == length(subjid),
        length(unique(subjid)) * length(unique(period)) == nrow(ddat)
    )

    design_variables <- paste0("V", seq_len(ncol(ddat)))
    ddat <- as.data.frame(ddat)
    names(ddat) <- design_variables

    # Omit period 3 because all data are missing there
    # so we cannot use it.
    is_period_3 <- period == "3"
    ddat <- ddat[!is_period_3, ]
    subjid <- subjid[!is_period_3]
    period <- period[!is_period_3]
    outcome <- outcome[!is_period_3]
    duration <- duration[!is_period_3]

    # Now we know that outcome is only missing if duration
    # is 0 for periods 1 and 2:
    assert_that(all(is.na(outcome) == (duration == 0)))

    N <- length(unique(subjid))
    K <- 2 # on-treatment and off-treatment periods
    P <- ncol(ddat)
    y <- matrix(NA, nrow = N, ncol = K)
    y[, 1] <- outcome[period == "1"]
    y[, 2] <- outcome[period == "2"]
    X <- array(NA, dim = c(K, N, P))
    X[1, , ] <- as.matrix(ddat[period == "1", ])
    X[2, , ] <- as.matrix(ddat[period == "2", ])
    log_offset <- matrix(NA, nrow = N, ncol = K)
    log_offset[, 1] <- log(duration[period == "1"])
    log_offset[, 2] <- log(duration[period == "2"])
    is_avail <- matrix(NA, nrow = N, ncol = K)
    is_avail[, 1] <- !is.na(outcome[period == "1"])
    is_avail[, 2] <- !is.na(outcome[period == "2"])

    # Stan does not allow NA.
    y[!is_avail] <- 999
    log_offset[!is_avail] <- 999

    stan_dat <- list(
        N = N,
        K = K,
        P = P,
        y = y,
        X = X,
        log_offset = log_offset,
        is_avail = is_avail
    )

    class(stan_dat) <- c("list", "stan_data", "stan_data_count")
    validate(stan_dat)
    stan_dat
}


#' Validate a `stan_data_count` object
#'
#' @param x A `stan_data_count` object.
#' @param ... Not used.
#' @export
validate.stan_data_count <- function(x, ...) {
    assert_that(
        x$N == nrow(x$y),
        x$N == nrow(x$log_offset),
        x$N == nrow(x$is_avail),
        x$N == dim(x$X)[2],
        x$K == ncol(x$y),
        x$K == ncol(x$log_offset),
        x$K == ncol(x$is_avail),
        x$K == dim(x$X)[1],
        x$P == dim(x$X)[3],
        !anyNA(x$y),
        all(is.finite(x$log_offset)),
        all(x$is_avail == 0 | x$is_avail == 1),
        msg = "Invalid Stan Data Object for Count Outcome"
    )
}


#' Completion of the Control Options for Count Outcome
#' TODO: complete docs
complete_control_bayes_count <- function(
    control,
    n_samples,
    quiet,
    stan_data
) {
    # TODO: This general stuff we should move into general function
    # for all outcome types.
    assertthat::assert_that(is.list(control))
    control_pars <- names(control)
    if ("iter" %in% control_pars) {
        stop(
            "`method$control$iter` must not be specified directly, please use `method$n_samples`"
        )
    }
    assertthat::assert_that(
        assertthat::is.number(control$warmup),
        assertthat::is.number(control$thin),
        assertthat::is.number(control$chains),
        assertthat::is.number(n_samples)
    )
    n_samples_per_chain <- ceiling(n_samples / control$chains)
    control$iter <- control$warmup + control$thin * n_samples_per_chain
    if ("refresh" %in% control_pars) {
        stop(
            "`method$control$refresh` must not be specified directly, please use `quiet`"
        )
    }
    control$refresh <- ife(
        quiet,
        0,
        ceiling(control$iter / 10)
    )

    # MMRM initial values are only defined for continuous outcomes. Preserve the
    # user-facing default of control_bayes() by falling back to Stan's random
    # initialisation for the count model.
    if (identical(control$init, "mmrm")) {
        control$init <- "random"
    }

    if (any(c("object", "data", "pars") %in% control_pars)) {
        stop(
            "The `object`, `data` and `pars` arguments must not be specified",
            " in `method$control`"
        )
    }
    control
}

#' Get the Stan model for count outcome
#' TODO complete docs
get_stan_model_count <- function() {
    # TODO: This should all go in general function

    # Compiling Stan models updates the current seed state. This can lead to
    # non-reproducibility as compiling is conditional on wether there is a cached
    # model available or not. Thus we save the current seed state and restore it
    # at the end of this function so that it is in the same state regardless of
    # whether the model was compiled or not.
    # See https://github.com/openpharma/rbmi/issues/469
    # Note that .Random.seed is only set if the seed has been set or if a random number
    # has been generated.
    current_seed_state <- globalenv()$.Random.seed
    on.exit({
        if (
            is.null(current_seed_state) &&
                exists(".Random.seed", envir = globalenv())
        ) {
            rm(".Random.seed", envir = globalenv(), inherits = FALSE)
        } else {
            assign(
                ".Random.seed",
                value = current_seed_state,
                envir = globalenv(),
                inherits = FALSE
            )
        }
    })

    ensure_rstan()

    # Find the correct Stan file for count outcome.
    file_loc_count_model <- find_stan_file(
        "count_model.stan"
    )
    model_template <- jinjar::parse_template(
        fs::path(file_loc_count_model),
        .config = jinjar::jinjar_config(
            trim_blocks = TRUE,
            lstrip_blocks = TRUE
        )
    )
    model_string <- jinjar::render(model_template)

    model_name <- "rbmi_count_model"

    # TODO: Enable caching but we need some general function for that

    model <- rstan::stan_model(
        model_code = model_string,
        model_name = model_name,
        auto_write = FALSE,
        save_dso = FALSE
    )

    model
}


#' Extract draws from a Stan fit object for count outcome
#'
#' TODO complete docs
extract_draws_count <- function(stan_fit, n_samples) {
    assertthat::assert_that(assertthat::is.number(n_samples))

    pars <- rstan::extract(stan_fit, pars = c("beta", "phi"))
    names(pars) <- c("beta", "phi")

    pars$beta <- split_dim(pars$beta, 1)
    pars$beta <- lapply(pars$beta, as.vector)
    assertthat::assert_that(length(pars$beta) >= n_samples)
    pars$beta <- pars$beta[seq_len(n_samples)]

    pars$phi <- as.list(pars$phi)
    assertthat::assert_that(length(pars$phi) >= n_samples)
    pars$phi <- pars$phi[seq_len(n_samples)]

    return(pars)
}
