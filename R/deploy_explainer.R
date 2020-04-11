#' Deploy An Explainer
#'
#' This function deploys an explainer as an REST API with an corresponding swagger.
#' A new folder will be created in your working directory containing a plumber R file and an .rda file of the explainer.
#' Deployment can be done either locally or directly to the DigitalOcean's droplet.
#' Full guide on setting up DigitalOcean's droplet and deploying to the cloud can be found on package's GitHub page.
#'
#' @param exp_name DALEX explainer object or an .rda filename in your working directory containing the explainer
#' @param model_package Name of package used to build the model, eg: "randomForest", "gbm".
#' @param droplet If you want to deploy the API locally leave the value as \code{NA}. If you want to deploy to DigitalOcean, use the droplet's ID which can be checked by using \code{analogsea::droplets()}
#' @param port Port on which you want your API to be deployed
#' @param deploy Boolean telling whether the plumber file is run on set port
#' @param title Title to be seen in Swagger
#' @export
#' @import plumber
#' @import DALEX
#' @importFrom whisker whisker.render
#' @examples
#' # Using an explainer object, locally
#' # Load data and create model
#' model_data <- DALEX::titanic_imputed
#' titanic_glm <- glm(survived ~ gender + age + fare,
#'                        data = model_data, family = "binomial")
#' # Create DALEX explainer
#' explain_titanic_glm <- explain(titanic_glm,
#'                            data = model_data,
#'                            y = model_data$survived,
#'                            label = "glm")
#' # Deploy the API
#' # If you want the API to deploy automatically, set deploy parameter to TRUE
#'
#' # Locally
#' deploy_explainer(explain_titanic_glm, model_package = "stats",
#'   title = "Titanic", port = 8070, deploy=FALSE)
#'
#' # To the cloud
#'\dontrun{
#' analogsea::droplets()
#' deploy_explainer(explain_titanic_glm, model_package = "stats",
#'   title = "Titanic", droplet = 136232162,
#'   port = 8080)
#'}
deploy_explainer <- function(exp_name, model_package, droplet = NA,
                             port = 8088, deploy = TRUE, title = "xai2cloud"){

  # Get data to fill the template
  template_data <- get_template_data(exp_name, model_package, title)
  # Get whisker template
  template <- get_template()
  # Rendering the template with provided data
  text_to_file <- whisker.render(template, template_data)
  # Creating a new directory with the explainer's name
  explain_path <- template_data$explain_name
  explain_name <- gsub(".*/","",template_data$explain_name)
  dir_name <- substr(explain_name, 1, nchar(explain_name)-4)
  dir.create(dir_name)
  old_wd <- getwd()
  new_wd <- paste(old_wd,"/",dir_name, sep="")

  # Copying the .rda file to the new directory
  from_copy <- explain_path
  to_copy <- paste(new_wd,"/",explain_name, sep="")
  file.copy(from_copy, to_copy)

  setwd(new_wd)
  # Creating the R file to be plumbed
  file_name_ext <- "plumber.R"
  file.create(file_name_ext)
  fileConn<-file(file_name_ext)
  writeLines(text_to_file, fileConn)
  close(fileConn)
  # Deploying the API locally
  if(is.na(droplet)){
    pmodel <- plumb("plumber.R")
    setwd(old_wd)
    if(deploy==TRUE){
      pmodel$run(port=port)
    }
  }
  setwd(old_wd)
  local_path <- paste0(getwd(),"/",dir_name)
  # Deploying the API to DigitalOcean
  if(!is.na(droplet)){
    if(deploy==TRUE){
      plumber::do_deploy_api(droplet = droplet, path = dir_name, localPath = local_path, swagger = TRUE, port = port)
    }
  }
}
