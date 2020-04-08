#' Load An File As Object
#'
#' @param file File name of an .rda file to be loaded as an object.
object_load <- function(file) {
  env <- new.env()
  load(file = file, envir = env)
  env[[ls(env)[1]]]
}
