#' Title
#'
#' @param file
#'
#' @return
#'
#' @examples
object_load <- function(file) {
  env <- new.env()
  load(file = file, envir = env)
  env[[ls(env)[1]]]
}
