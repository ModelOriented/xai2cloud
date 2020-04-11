#' Get Data From Template
#'
#' @param exp_name DALEX explainer object or an .rda filename in your working directory containing the explainer
#' @param model_package Package used to build the model, eg: "randomForest", "gbm"
#' @param title Title to be seen in Swagger
#' @return A list of parameters to fill the template
#' @export
get_template_data <- function(exp_name, model_package, title){
  UseMethod("get_template_data")
}

#' @export
get_template_data.default <- function(exp_name, model_package, title = "xai2cloud"){
  # Correct extension check
  # Template parameter: explain_name - explainer's .rda filename
  if(substr(exp_name, nchar(exp_name)-3, nchar(exp_name))!=".rda"){
    explain_name <- paste(exp_name, "rda", sep=".")
  }
  else{
    explain_name <- exp_name
  }

  # Loading the .rda file in
  (my_exp <- object_load(explain_name))
  model_name <- my_exp$label

  # Template parameter: params_x - parameters with default value X
  fact <- c()
  params_x <- c()
  for(colname in colnames(my_exp$data)){
    params_x <- paste(params_x, colname, " = 'X',", sep="")
    # Checking which columns are factors
    if(!is.null(levels(my_exp$data[,colname]))){
      fact <- c(fact, colname)
    }
  }
  params_x <- gsub(".$", "", params_x)

  # Template parameter: params_ok - factor parameters with their apropriate levels
  dat <- my_exp$data
  params_ok <- ""
  for(colname in fact){
    fact_check <- paste(colname,"_ok <- ", "c('",levels(dat[,colname])[1],"'", sep="")
    for(level in levels(dat[,colname])[2:length(levels(dat[,colname]))]){
      fact_check <- paste(fact_check,", '", level, "'", sep="")
    }
    fact_check <- paste(fact_check, ")", sep="")
    params_ok <- paste(params_ok, fact_check, "\n")
  }

  # Template parameter: par_check - checking whether inputed parameters are corect
  # Factors:
  # Template parameter: params_factor - factor parameters names as strings
  par_check <- ""
  params_factor <- ""
  for(colname in fact){
    params_factor <- paste(params_factor, "'", colname, "',", sep="")
    if_check <- paste("if(", colname, " != 'X' & ", colname, " %in% ", colname, "_ok) {", sep="")
    if_check <- paste(if_check, paste("   new_observation[,'",colname,"'] <- factor(", colname, ", levels = ", colname, "_ok)\n", sep=""))
    if_check <- paste(if_check, paste("   subtitle <- paste(subtitle, '  ", colname, ":', ", colname, ")}\n", sep=""))
    par_check <- paste(par_check, if_check)
  }
  params_factor <- gsub(".$", "", params_factor)

  # Numeric:
  # Template parameter: params_numeric - numeric parameters names as strings
  rest <- colnames(dat)[!colnames(dat) %in% fact]
  params_numeric <- ""
  for(colname in rest){
    params_numeric <- paste(params_numeric, "'", colname, "',", sep="")
    if_check <- paste("if(", colname, " != 'X') {", sep="")
    if_check <- paste(if_check, paste("   new_observation[,'",colname,"'] <- as.numeric(as.character(", colname, "))\n", sep=""), sep="")
    if_check <- paste(if_check, paste("   subtitle <- paste(subtitle, '  ", colname, ":', ", colname, ")}\n", sep=""), sep="")
    par_check <- paste(par_check, if_check)
  }
  params_numeric <- gsub(".$", "", params_numeric)

  # Template parameter: parameter_annotations - parameter annotations for predict function
  parameter_annotations <- ""
  for(colname in fact){
    pred_levels <- paste(levels(dat[,colname]), collapse = ", ", sep="")
    pred_param <- paste("#* @param ", colname, " X if missing. Factor, one of ", pred_levels, sep="")
    parameter_annotations <- paste(parameter_annotations, pred_param, "\n", sep="")
  }
  for(colname in rest){
    pred_param <- paste("#* @param ", colname, " X if missing. Numeric")
    parameter_annotations <- paste(parameter_annotations, pred_param, "\n", sep="")
  }

  # Template parameter: params - all parameter names
  params <- c()
  for(colname in colnames(dat)){
    params <- paste(params, colname, ",", sep="")
  }
  params <- gsub(".$", "", params)

  # Template parameter: params_amp - all parameter names as strings
  params_amp <- c()
  for(colname in colnames(dat)){
    params_amp <- paste(params_amp,"'", colname, "',", sep="")
  }
  params_amp <- gsub(".$", "", params_amp)

  # Template parameter: first_param - first parameter's name as string
  first_param <- paste("'", colnames(dat)[1], "'", sep="")

  # Constructing the list of template parameters
  data <- list( params_x = params_x
                , params_ok = params_ok
                , explain_name = explain_name
                , par_check = par_check
                , title = title
                , model_name = model_name
                , params = params
                , params_amp = params_amp
                , first_param = first_param
                , parameter_annotations = parameter_annotations
                , params_factor = params_factor
                , params_numeric = params_numeric
                , model_package = model_package
  )
  return(data)
}

#' @export
get_template_data.explainer <- function(exp_name, model_package, title = "xai2cloud"){

  # Creating a .rda file name
  explain_name <- paste(deparse(substitute(exp_name)), ".rda", sep="")

  # Loading the explainer
  my_exp <- exp_name
  model_name <- my_exp$label

  # Saving the explainer to .rda file
  save(my_exp, file = explain_name)

  # Template parameter: params_x - parameters with default value X
  fact <- c()
  params_x <- c()
  for(colname in colnames(my_exp$data)){
    params_x <- paste(params_x, colname, " = 'X',", sep="")
    # Checking which columns are factors
    if(!is.null(levels(my_exp$data[,colname]))){
      fact <- c(fact, colname)
    }
  }
  params_x <- gsub(".$", "", params_x)

  # Template parameter: params_ok - factor parameters with their apropriate levels
  dat <- my_exp$data
  params_ok <- ""
  for(colname in fact){
    fact_check <- paste(colname,"_ok <- ", "c('",levels(dat[,colname])[1],"'", sep="")
    for(level in levels(dat[,colname])[2:length(levels(dat[,colname]))]){
      fact_check <- paste(fact_check,", '", level, "'", sep="")
    }
    fact_check <- paste(fact_check, ")", sep="")
    params_ok <- paste(params_ok, fact_check, "\n")
  }


  # Template parameter: par_check - checking whether inputed parameters are corect
  # Factors:
  # Template parameter: params_factor - factor parameters names as strings
  par_check <- ""
  params_factor <- ""
  for(colname in fact){
    params_factor <- paste(params_factor, "'", colname, "',", sep="")
    if_check <- paste("if(", colname, " != 'X' & ", colname, " %in% ", colname, "_ok) {", sep="")
    if_check <- paste(if_check, paste("   new_observation[,'",colname,"'] <- factor(", colname, ", levels = ", colname, "_ok)\n", sep=""))
    if_check <- paste(if_check, paste("   subtitle <- paste(subtitle, '  ", colname, ":', ", colname, ")}\n", sep=""))
    par_check <- paste(par_check, if_check)
  }
  params_factor <- gsub(".$", "", params_factor)

  # Numeric:
  # Template parameter: params_numeric - numeric parameters names as strings
  rest <- colnames(dat)[!colnames(dat) %in% fact]
  params_numeric <- ""
  for(colname in rest){
    params_numeric <- paste(params_numeric, "'", colname, "',", sep="")
    if_check <- paste("if(", colname, " != 'X') {", sep="")
    if_check <- paste(if_check, paste("   new_observation[,'",colname,"'] <- as.numeric(as.character(", colname, "))\n", sep=""), sep="")
    if_check <- paste(if_check, paste("   subtitle <- paste(subtitle, '  ", colname, ":', ", colname, ")}\n", sep=""), sep="")
    par_check <- paste(par_check, if_check)
  }
  params_numeric <- gsub(".$", "", params_numeric)


  # Template parameter: parameter_annotations - parameter annotations for predict function
  parameter_annotations <- ""
  for(colname in fact){
    pred_levels <- paste(levels(dat[,colname]), collapse = ", ", sep="")
    pred_param <- paste("#* @param ", colname, " X if missing. Factor, one of ", pred_levels, sep="")
    parameter_annotations <- paste(parameter_annotations, pred_param, "\n", sep="")
  }
  for(colname in rest){
    pred_param <- paste("#* @param ", colname, " X if missing. Numeric")
    parameter_annotations <- paste(parameter_annotations, pred_param, "\n", sep="")
  }

  # Template parameter: params - all parameter names
  params <- c()
  for(colname in colnames(dat)){
    params <- paste(params, colname, ",", sep="")
  }
  params <- gsub(".$", "", params)

  # Template parameter: params_amp - all parameter names as strings
  params_amp <- c()
  for(colname in colnames(dat)){
    params_amp <- paste(params_amp,"'", colname, "',", sep="")
  }
  params_amp <- gsub(".$", "", params_amp)

  # Template parameter: first_param - first parameter's name as string
  first_param <- paste("'", colnames(dat)[1], "'", sep="")

  # Constructing the list of template parameters
  data <- list( params_x = params_x
                , params_ok = params_ok
                , explain_name = explain_name
                , par_check = par_check
                , title = title
                , model_name = model_name
                , params = params
                , params_amp = params_amp
                , first_param = first_param
                , parameter_annotations = parameter_annotations
                , params_factor = params_factor
                , params_numeric = params_numeric
                , model_package = model_package
  )
  return(data)
}


