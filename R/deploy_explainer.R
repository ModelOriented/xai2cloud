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
#' @importFrom utils askYesNo
#' @examples
#' # Create a model
#' library("ranger")
#' library("DALEX")
#' model <- ranger(survived~., data = titanic_imputed)
#'
#' # Create DALEX explainer
#' explainer <- explain(model,
#'                      data = titanic_imputed[,-8],
#'                      y = titanic_imputed$survived)
#'
#' # Deploy the API
#' # If you want the API to deploy automatically, set deploy parameter to TRUE
#'
#' # Locally
#' deploy_explainer(explainer, model_package = "ranger",
#'   port = 8070, deploy=FALSE, title = "Local Example")
#'
#' # To the cloud
#'\dontrun{
#' my_droplets <- analogsea::droplets()
#'
#' # Choose the correct droplets name - xai2cloudExamples in this case
#' specific_droplet <- my_droplets$xai2cloudExamples
#' droplet_id <- specific_droplet$id
#'
#' deploy_explainer(explainer, model_package = "ranger",
#'                  droplet = droplet_id, port = 8070,
#'                  title = "Titanic Example")
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
      if(!is.numeric(droplet)){
        stop("`droplet` has to be numeric.\nCheck your droplets ID by running anaglosea::droplets(). \n")
      }
      chech_droplet_id <- try(dr <- analogsea::droplet(droplet))
      if (class(chech_droplet_id)[1] == "try-error") {
        stop("`droplet` with such ID does not exist.\nCheck your droplets ID by running anaglosea::droplets(). \n")
      }
      # Install model's package on the droplet, if needed.
      question_for_user <- paste0("Do you want to install ", model_package, " package on the droplet?\nIf you didn't install it using `do_setup` function, press 'Yes'.")
      install_do_package <- askYesNo(question_for_user)
      if(install_do_package){
        analogsea::install_r_package(dr, model_package)
      }
      # Deploy application to the droplet.
      tryCatch(plumber::do_deploy_api(droplet = droplet, path = dir_name, localPath = local_path, swagger = TRUE, port = port),
               error = function(e){
                 message("An connection error occurred")
                 message("Please make sure you are using github's development version of `plumber`.")
                 message("If you are having problems with already used address try chaning the `port` parameter.")
                 message("If you are encounter 'ssh failed' error, remove previous version of this explainer by running:")
                 message("plumber::do_remove_api(",droplet,",'",dir_name,"',TRUE)")
                 stop(e)
               },
               warning = function(w){
                 message("A warning occured:\n", w)
                 message("In case you want to remove old version of the explainer, use `plumber::do_remove_api`` function.")
               },
               finally = {
                 ip_addr <- dr$networks$v4[[1]]$ip_address
               })
      message("You have succesfully deployed an explainer to your DigitalOcean's droplet.")
      message("Your explainer's swagger is now available at: ", ip_addr, "/", dir_name, "/__swagger__/")
    }
  }
}
