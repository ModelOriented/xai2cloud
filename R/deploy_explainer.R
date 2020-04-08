#' Deploy An Explainer
#'
#' This function deploys an explainer as an REST API with an corresponding swagger.
#' Deployment can be done either locally or directly to the DigitalOcean's droplet.
#' A new folder will be created in your working directory containing a plumber R file and an .rda file of the explainer.
#'
#' @param exp_name DALEX explainer object or an .rda filename containing the explainer
#' @param title Title to be seen in Swagger
#' @param droplet If you want to deploy the API locally leave the value as \code{NA}. If you want to deploy to DigitalOcean, use the droplet's ID which can be checked by using \code{analogsea::droplets()}
#' @param port Port on which you want your API to be deployed
#' @export
#' @import plumber
#' @import DALEX
#' @importFrom whisker whisker.render
#' @examples
#' \dontrun{
#' # Using an explainer object, locally
#' # Load data
#' titanic <- na.omit(DALEX::titanic)
#' model_titanic_rf <- randomForest::randomForest(survived == "yes" ~ gender + age + class + embarked +
#' fare + sibsp + parch,  data = titanic)
#' explain_titanic_rf <- DALEX::explain(model_titanic_rf,
#' data = titanic[,-9],
#' y = titanic$survived == "yes",
#' label = "Random Forest v7",
#' colorize = FALSE)
#'
#' deploy_explainer(explain_titanic_rf, title = "Titanic", port = 8070)
#'
#' # Using an explainer object, to the cloud
#' deploy_explainer(explain_titanic_rf, title = "Titanic", droplet = 185232162, port = 8070)
#'
#' # Using an .rda explainer file, locally
#' deploy_explainer("explain_titanic_rf.rda", title = "Titanic", port = 8070)
#'
#' # Using an .rda explainer file, to the cloud
#' deploy_explainer("explain_titanic_rf.rda", title = "Titanic", droplet = 185232162, port = 8080)
#' }
deploy_explainer <- function(exp_name, title = "xai2cloud", droplet = NA, port = 8088){

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
