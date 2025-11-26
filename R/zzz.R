.onLoad <- function(...) {
    set_options()
}

#' Clean up after examples
#' @name tidy-up-examples
#' @keywords internal
#' @examples
#' \dontshow{
#'   e <- environment()
#'   tidy_up_examples <- function(e) {
#'    clear_model_cache(keep = "")
#'    if (length(list.files(getOption('rbmi.cache_dir'))) == 0) {
#'        unlink(getOption('rbmi.cache_dir'))
#'    }
#'    rm(e)
#'   }
#'   reg.finalizer(e, f = tidy_up_examples, onexit = TRUE)
#' }
#' 
NULL