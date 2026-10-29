#' Student t distribution with location and scale
#'
#' Quantile and cumulative distribution functions for a location-scale Student
#' t distribution. These extend [stats::qt()] and [stats::pt()] with location
#' and scale parameters, rather than a noncentrality parameter.
#'
#' @param p A numeric vector of probabilities.
#' @param q A numeric vector of quantiles.
#' @param df Degrees of freedom, passed to [stats::qt()] or [stats::pt()].
#' @param mean The location parameter. This is the mean when `df > 1`.
#' @param scale A positive scale parameter. This differs from the standard
#' deviation, which is `scale * sqrt(df / (df - 2))` when `df > 2`.
#' @param ... Additional arguments passed to [stats::qt()] or [stats::pt()],
#' such as `lower.tail` and `log.p`.
#'
#' @return A numeric vector of quantiles (`qstudent`) or cumulative
#' probabilities (`pstudent`).
#' @name student_t
#' @keywords internal
#' @importFrom stats qt pt
qstudent <- function(p, df, mean = 0, scale = 1, ...) {
    mean + scale * qt(p, df = df, ...)
}


#' @rdname student_t
pstudent <- function(q, df, mean = 0, scale = 1, ...) {
    pt((q - mean) / scale, df = df, ...)
}
