#' Get Templates
#'
#' @return A whisker template for the plumber R file
#'
#' @importFrom readr read_file
get_template <- function(){
  path_to_template <- system.file("templates", "default_template.txt", package="xai2cloud")
  template <- read_file(path_to_template)
  return(template)
}
