.onLoad <- function(...) {
    set_options()
}

#' Clean up after examples
#' @keywords internal
#' @examples
#' \dontshow{
#'   e <- environment(),  
#'   reg.finalizer(e, f = tidy_up_examples, onexit = TRUE)
#' }
#' 
tidy_up_examples <- function(e) {
    clear_model_cache(keep = "")
    rm(e)
}