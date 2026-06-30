#' Prepare input data to run the Stan model for count outcome
#'
#' @description
#' Prepare input data to run the Stan model for count outcome.
#'
#' @param ddat A design matrix
#' @param subjid A vector of subject IDs
#' @param period A vector of period values
#' @param duration A vector of duration values
#' @param outcome A vector of outcome values
#' @param group A vector of group values
#'
#' @return A `stan_data_count` object. A named list containing all the
#' required inputs as required by the `data{}` block of the Count Stan program:group
#'
#' - `N`: The number of observations
#' TODO complete
prepare_stan_data_count <- function(
    ddat,
    subjid,
    period,
    duration,
    outcome,
    group
) {
    assert_that(
        is.factor(group) | is.numeric(group),
        is.factor(period) | is.character(period),
        is.numeric(duration) & all(duration >= 0),
        is.character(subjid) | is.factor(subjid),
        is.numeric(outcome) & all(outcome >= 0),
        is.data.frame(ddat) | is.matrix(ddat),
        length(group) == length(period),
        length(period) == length(duration),
        length(duration) == length(outcome),
        length(outcome) == length(subjid),
        nrow(ddat) == length(subjid),
        length(unique(subjid)) * length(unique(period)) == nrow(ddat)
    )

    design_variables <- paste0("V", seq_len(ncol(ddat)))
    ddat <- as.data.frame(ddat)
    names(ddat) <- design_variables
    ddat$subjid <- as.character(subjid)
    ddat$period <- as.character(period)
    ddat$outcome <- outcome
    ddat$group <- group
    ddat$is_avail <- (!is.na(ddat$outcome)) * 1

    ddat <- remove_if_all_missing(ddat, timevar = "period")

    stan_dat <- list()

    class(stan_dat) <- c("list", "stan_data", "stan_data_count")
    validate(stan_dat)
    stan_dat
}


#' Validate a `stan_data_count` object
#'
#' @param x A `stan_data_count` object.
#' @param ... Not used.
validate.stan_data_count <- function(x, ...) {
    assert_that(,
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

    # TODO: Do we need a prepare_init_vals_count() function?

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
