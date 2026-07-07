#' Adding Labels To Variables For Model
#'
#' @param vars (`list`)\cr variables to use.
#' @param data (`data.frame`)\cr data to use.
#' @param x (`character`)\cr an element in vars.
#'
#' @name labels
#' @keywords internal
NULL

#' @describeIn labels checks if element in `vars` is not `NULL` and not empty.
h_is_specified <- function(x, vars) {
  !is.null(vars[[x]]) && (length(vars[[x]]) > 0)
}

#' @describeIn labels checks if element in vars is not NULL and exists in dataset.
h_is_specified_and_in_data <- function(x, vars, data) {
  h_is_specified(x, vars) && all(vars[[x]] %in% names(data))
}

#' @describeIn labels gets label for each element in vars.
h_check_and_get_label <- function(x, vars, data) {
  checkmate::assert_true(h_is_specified_and_in_data(x, vars, data))
  res <- NULL
  for (v in vars[[x]]) {
    label <- attr(data[[v]], "label")
    string <- ifelse(!is.null(label), label, v)
    res <- c(res, stats::setNames(string, v))
  }
  res
}

#' Extraction of Covariate Parts from Character Vector
#'
#' @description
#' Extraction of Covariate Parts from Character Vector.
#'
#' @param covariates (`character`)\cr specification in the usual way, see examples.
#'
#' @return Character vector of the covariates involved in `covariates` specification.
#' @keywords internal
h_get_covariate_parts <- function(covariates) {
  checkmate::assert_character(covariates, null.ok = TRUE)
  if (is.null(covariates)) {
    NULL
  } else {
    unique(unlist(strsplit(covariates, split = "\\*|:")))
  }
}

#' @describeIn labels returns the list of variables with labels.
h_labels <- function(vars, data) {
  checkmate::assert_list(vars)
  checkmate::assert_data_frame(data)
  labels <- list()
  labels$response <- h_check_and_get_label("response", vars, data)
  labels$id <- h_check_and_get_label("id", vars, data)
  labels$visit <- h_check_and_get_label("visit", vars, data)
  if (h_is_specified("arm", vars)) {
    labels$arm <- h_check_and_get_label("arm", vars, data)
  }
  if (h_is_specified("covariates", vars)) {
    vars$parts <- h_get_covariate_parts(vars$covariates)
    labels$parts <- h_check_and_get_label("parts", vars, data)
  }
  if (h_is_specified("weights", vars)) {
    labels$weights <- h_check_and_get_label("weights", vars, data)
  }
  if (h_is_specified("subgroup", vars)) {
    labels$subgroup <- h_check_and_get_label("subgroup", vars, data)
  }
  return(labels)
}

#' Building Model Formula
#'
#' This builds the model formula which is used inside [fit_mmrm_j()] and provided
#' to [mmrm::mmrm()] internally. It can be instructive to look at the resulting
#' formula directly sometimes. In particular, if a `subgroup` variable is included
#' in `vars`, then the formula will include the interaction of `subgroup` with
#' `arm` and `visit`.
#'
#' @param vars (`list`)\cr variables to use in the model.
#' @param cor_struct (`string`)\cr specify the covariance structure to use.
#' @return Formula to use in [mmrm::mmrm()].
#' @export
#'
#' @examples
#' vars <- list(
#'   response = "AVAL",
#'   covariates = c("RACE", "SEX"),
#'   id = "USUBJID",
#'   arm = "ARMCD",
#'   visit = "AVISIT",
#'   subgroup = "REGION"
#' )
#' build_formula(vars, "auto-regressive")
#' build_formula(vars)
build_formula <- function(
  vars,
  cor_struct = c(
    "unstructured",
    "toeplitz",
    "heterogeneous toeplitz",
    "ante-dependence",
    "heterogeneous ante-dependence",
    "auto-regressive",
    "heterogeneous auto-regressive",
    "compound symmetry",
    "heterogeneous compound symmetry"
  )
) {
  checkmate::assert_list(vars)
  cor_struct <- match.arg(cor_struct)
  covariates_part <- paste(vars$covariates, collapse = " + ")
  arm_visit_part <- if (is.null(vars$arm)) {
    vars$visit
  } else {
    paste0(vars$arm, "*", vars$visit)
  }
  if (!is.null(vars$subgroup)) {
    arm_visit_part <- paste0(arm_visit_part, "*", vars$subgroup)
  }
  random_effects_fun <- switch(cor_struct,
    unstructured = "us",
    toeplitz = "toep",
    `heterogeneous toeplitz` = "toeph",
    `ante-dependence` = "ad",
    `heterogeneous ante-dependence` = "adh",
    `auto-regressive` = "ar1",
    `heterogeneous auto-regressive` = "ar1h",
    `compound symmetry` = "cs",
    `heterogeneous compound symmetry` = "csh"
  )
  random_effects_part <- paste0(random_effects_fun, "(", vars$visit, " | ", vars$id, ")")
  rhs_formula <- paste(arm_visit_part, "+", random_effects_part)
  if (covariates_part != "") {
    rhs_formula <- paste(covariates_part, "+", rhs_formula)
  }
  stats::as.formula(paste(vars$response, "~", rhs_formula))
}

#' Extract Least Square Means from `MMRM`
#'
#' Extracts the least square means from an `MMRM` fit.
#'
#' @inheritParams fit_mmrm_j
#' @param fit (`mmrm`)\cr result of [mmrm::mmrm()].
#' @param averages (`list`)\cr named list of visit levels which should be averaged
#'   and reported along side the single visits.
#' @param weights (`string`)\cr type of weights to be used for the least square means,
#'   see [emmeans::emmeans()] for details.
#' @param mult_adj (`string`)\cr multiplicity adjustment within visits for the contrasts.
#' @return A list with data frames `estimates` and `contrasts`.
#'   The attributes `averages`, `weights` and `mult_adj` save the settings used.
#'
#' @note This is modified from `tern.mmrm` and has the additional `mult_adj` argument.
#' @export
get_mmrm_lsmeans <- function(
  fit, vars, conf_level, weights, averages = list(),
  mult_adj = c("none", "dunnett", "step-down-dunnett")
) {
  checkmate::assert_class(fit, "mmrm")
  checkmate::assert_list(averages, types = "character")
  mult_adj <- match.arg(mult_adj)
  emmeans_res <- h_get_emmeans_res(fit, vars, weights)

  # Get least square means estimates for single visits, and possibly averaged visits.
  estimates <- h_get_single_visit_estimates(emmeans_res, conf_level)
  if (length(averages)) {
    average_specs <- h_get_average_visit_specs(emmeans_res, vars, averages, fit)
    average_estimates <- h_get_spec_visit_estimates(emmeans_res, average_specs, conf_level)
    estimates <- rbind(estimates, average_estimates)
  }
  has_arm_var <- !is.null(vars$arm)
  if (!has_arm_var) {
    return(list(estimates = estimates))
  }
  # Continue with contrasts when we have an arm variable.
  if (mult_adj != "none" && !identical(averages, list())) {
    stop("Multiplicity adjustment within visits cannot be combined with averages across visits")
  }

  contrast_specs <- h_single_visit_contrast_specs(emmeans_res, vars)
  contrast_estimates <- h_get_spec_visit_estimates(emmeans_res, contrast_specs, conf_level, tests = TRUE)

  if (length(averages)) {
    average_contrast_specs <- h_average_visit_contrast_specs(contrast_specs, averages, vars)
    average_contrasts <- h_get_spec_visit_estimates(emmeans_res, average_contrast_specs, conf_level, tests = TRUE)
    contrast_estimates <- rbind(contrast_estimates, average_contrasts)
  }

  if (mult_adj != "none") {
    # We just calculate the adjusted p-values and confidence intervals here and replace them
    # in the contrast_estimates data frame. The estimates and t-stats remain unchanged.
    mult_adj_df <- h_get_mult_adj_estimates(
      emmeans_res = emmeans_res,
      vars = vars,
      mult_adj = mult_adj,
      conf_level = conf_level,
      contrast_df = contrast_estimates$df
    )
    contrast_estimates$p_value <- mult_adj_df$p_value
    contrast_estimates$p_value_less <- mult_adj_df$p_value_less
    contrast_estimates$p_value_greater <- mult_adj_df$p_value_greater
    contrast_estimates$lower_cl <- mult_adj_df$lower_cl
    contrast_estimates$upper_cl <- mult_adj_df$upper_cl
  }

  relative_reduc_df <- h_get_relative_reduc_df(estimates, vars)
  contrast_estimates <- merge(
    contrast_estimates,
    relative_reduc_df,
    by = c(vars$subgroup, vars$arm, vars$visit),
    sort = FALSE
  )
  if (!is.null(vars$subgroup)) {
    contrast_estimates[[vars$subgroup]] <- factor(
      contrast_estimates[[vars$subgroup]],
      levels = intersect(levels(estimates[[vars$subgroup]]), contrast_estimates[[vars$subgroup]])
    )
  }
  contrast_estimates[[vars$arm]] <- factor(
    contrast_estimates[[vars$arm]],
    levels = intersect(levels(estimates[[vars$arm]]), contrast_estimates[[vars$arm]])
  )
  contrast_estimates[[vars$visit]] <- factor(
    contrast_estimates[[vars$visit]],
    levels = intersect(levels(estimates[[vars$visit]]), contrast_estimates[[vars$visit]])
  )
  structure(
    list(estimates = estimates, contrasts = contrast_estimates),
    averages = averages,
    weights = weights,
    mult_adj = mult_adj
  )
}

#' `MMRM` Analysis
#'
#' Does the `MMRM` analysis. Multiple other functions can be called on the result to produce
#' tables and graphs.
#'
#' @param vars (named `list` of `string` or `character`)\cr specifying the variables in the `MMRM`.
#'   The following elements need to be included as character vectors and match corresponding columns
#'   in `data`:
#'
#'   - `response`: the response variable.
#'   - `covariates`: the additional covariate terms (might also include interactions).
#'   - `id`: the subject ID variable.
#'   - `arm`: the treatment group variable (factor).
#'   - `visit`: the visit variable (factor).
#'   - `weights`: optional weights variable (if `NULL` or omitted then no weights will be used).
#'
#'   Note that the main effects and interaction of `arm` and `visit` are by default
#'   included in the model.
#' @param data (`data.frame`)\cr with all the variables specified in
#'   `vars`. Records with missing values in any independent variables
#'   will be excluded.
#' @param conf_level (`proportion`)\cr confidence level of the interval.
#' @param cor_struct (`string`)\cr specifying the covariance structure, defaults to
#'   `'unstructured'`. See the details.
#' @param averages_emmeans (`list`)\cr optional named list of visit levels which should be averaged
#'   and reported along side the single visits.
#' @param weights_emmeans (`string`)\cr argument from [emmeans::emmeans()], `'counterfactual'` by default.
#' @param mult_adj_emmeans (`string`)\cr whether to multiplicity adjust LS means contrast p-values and
#'   confidence intervals within visits when there are more than 2 treatment arms. Note that this cannot
#'   be combined with `averages_emmeans`. Either "none", "dunnett" or "step-down-dunnett".
#' @param ... additional arguments for [mmrm::mmrm()], in particular `reml` and options listed in
#'   [mmrm::mmrm_control()].
#'
#' @details Multiple different degree of freedom adjustments are available via the `method` argument
#'   for [mmrm::mmrm()]. In addition, covariance matrix adjustments are available via `vcov`.
#'   Please see [mmrm::mmrm_control()] for details and additional useful options.
#'
#'   For the covariance structure (`cor_struct`), the user can choose among the following options.
#'
#'   - `unstructured`: Unstructured covariance matrix. This is the most flexible choice and default.
#'        If there are `T` visits, then `T * (T+1) / 2` variance parameters are used.
#'   - `toeplitz`: Homogeneous Toeplitz covariance matrix, which uses `T` variance parameters.
#'   - `heterogeneous toeplitz`: Heterogeneous Toeplitz covariance matrix,
#'        which uses `2 * T - 1` variance parameters.
#'   - `ante-dependence`: Homogeneous Ante-Dependence covariance matrix, which uses `T` variance parameters.
#'   - `heterogeneous ante-dependence`: Heterogeneous Ante-Dependence covariance matrix,
#'        which uses `2 * T - 1` variance parameters.
#'   - `auto-regressive`: Homogeneous Auto-Regressive (order 1) covariance matrix,
#'        which uses 2 variance parameters.
#'   - `heterogeneous auto-regressive`: Heterogeneous Auto-Regressive (order 1) covariance matrix,
#'        which uses `T + 1` variance parameters.
#'   - `compound symmetry`: Homogeneous Compound Symmetry covariance matrix, which uses 2
#'        variance parameters.
#'   - `heterogeneous compound symmetry`: Heterogeneous Compound Symmetry covariance matrix, which uses
#'        `T + 1` variance parameters.
#'
#' @return A `tern_model` object which is a list with model results:
#'
#'   - `fit`: The `mmrm` object which was fitted to the data. Note that via `mmrm::component(fit, 'optimizer')`
#'       the finally used optimization algorithm can be obtained, which can be useful for refitting the model
#'       later on.
#'   - `cov_estimate`: The matrix with the covariance matrix estimate.
#'   - `diagnostics`: A list with model diagnostic statistics (REML criterion, AIC, corrected AIC, BIC).
#'   - `lsmeans`: This is a list with data frames `estimates` and `contrasts`.
#'        The attributes `averages`, `weights` and `mult_adj` save the settings used
#'        (`averages_emmeans`, `weights_emmeans` and `mult_adj_emmeans`).
#'   - `vars`: The variable list.
#'   - `labels`: Corresponding list with variable labels extracted from `data`.
#'   - `cor_struct`: input.
#'   - `ref_level`: The reference level for the arm variable, which is always the first level.
#'   - `treatment_levels`: The treatment levels for the arm variable.
#'   - `conf_level`: The confidence level which was used to construct the `lsmeans` confidence intervals.
#'   - `additional`: List with any additional inputs passed via `...`
#'
#' @export
#'
#' @note This function has the `_j` suffix to distinguish it from [mmrm::fit_mmrm()].
#'   It is modified from the `tern.mmrm` package.
#'   The new features are:
#'
#'   - the `mult_adj_emmeans` argument and its functionality
#'   - the `subgroup` variable in `vars` and its functionality
#'
#'   These could later be contributed upstream in `tern.mmrm`.
#'
#' @examples
#' mmrm_results <- fit_mmrm_j(
#'   vars = list(
#'     response = "FEV1",
#'     covariates = c("RACE", "SEX"),
#'     id = "USUBJID",
#'     arm = "ARMCD",
#'     visit = "AVISIT"
#'   ),
#'   data = mmrm::fev_data,
#'   cor_struct = "unstructured",
#'   weights_emmeans = "equal",
#'   averages_emmeans = list(
#'     "VIS1+2" = c("VIS1", "VIS2")
#'   )
#' )
fit_mmrm_j <- function(
  vars = list(
    response = "AVAL",
    covariates = c(),
    id = "USUBJID",
    arm = "ARM",
    visit = "AVISIT",
    subgroup = NULL
  ),
  data,
  conf_level = 0.95,
  cor_struct = "unstructured",
  weights_emmeans = "counterfactual",
  averages_emmeans = list(),
  mult_adj_emmeans = c("none", "dunnett", "step-down-dunnett"),
  ...
) {
  labels <- h_labels(vars, data)
  formula <- build_formula(vars, cor_struct)
  weights <- if (!is.null(vars$weights)) data[[vars$weights]] else NULL

  fit <- mmrm::mmrm(formula = formula, data = data, weights = weights, reml = TRUE, ...)
  lsmeans <- get_mmrm_lsmeans(
    fit = fit,
    vars = vars,
    conf_level = conf_level,
    averages = averages_emmeans,
    weights = weights_emmeans,
    mult_adj = mult_adj_emmeans
  )
  cov_estimate <- mmrm::VarCorr(fit)
  visit_levels <- rownames(cov_estimate)
  contrasts_from_visits <- match(visit_levels, lsmeans$contrasts[[vars$visit]])
  df <- stats::setNames(lsmeans$contrasts$df[contrasts_from_visits], visit_levels)
  results <- list(
    fit = fit,
    cov_estimate = cov_estimate,
    lsmeans = lsmeans,
    vars = vars,
    labels = labels,
    mse = diag(cov_estimate),
    df = df,
    cor_struct = cor_struct,
    ref_level = if (is.null(vars$arm)) NULL else levels(data[[vars$arm]])[1],
    treatment_levels = if (is.null(vars$arm)) NULL else levels(data[[vars$arm]])[-1],
    conf_level = conf_level,
    additional = list(...)
  )
  class(results) <- "tern_model"
  return(results)
}