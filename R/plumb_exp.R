#' Plumb Explainer
#'
#' @param exp_name
#' @param title
#' @param droplet
#'
#' @return
#' @export
#' @import plumber
#' @import DALEX
#' @importFrom whisker whisker.render
#'
#' @examples
plumb_exp <- function(exp_name, title = "xai2cloud", droplet = NA, port = 8088){

  template_data <- get_template_data(exp_name, title)
  template <- get_template()

  text_to_file <- whisker.render(template, template_data)

  explain_name <- template_data$explain_name
  dir_name <- substr(explain_name, 1, nchar(explain_name)-4)
  dir.create(dir_name)
  old_wd <- getwd()
  new_wd <- paste(old_wd,"/",dir_name, sep="")

  from_copy <- paste(old_wd,"/",explain_name, sep="")
  to_copy <- paste(new_wd,"/",explain_name, sep="")
  file.copy(from_copy, to_copy)

  setwd(new_wd)
  file_name_ext <- "plumber.R"
  file.create(file_name_ext)
  fileConn<-file(file_name_ext)
  writeLines(text_to_file, fileConn)
  close(fileConn)
  if(is.na(droplet)){
    pmodel <- plumb("plumber.R")
    setwd(old_wd)
    pmodel$run(port=port)
  }
  setwd(old_wd)
  local_path <- paste0(getwd(),"/",dir_name)
  print(local_path)
  if(!is.na(droplet)){
    plumber::do_deploy_api(droplet = droplet, path = dir_name, localPath = local_path, swagger = TRUE, port = port)
  }
}
