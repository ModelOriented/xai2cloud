library(DALEX)
library(iBreakDown)
library(ggplot2)
library(ingredients)
library(stats)
object_load <- function(file) {
env <- new.env()
load(file = file, envir = env)
env[[ls(env)[1]]]
}
get_observation <- function(gender = 'X',age = 'X',class = 'X',embarked = 'X',fare = 'X',sibsp = 'X',parch = 'X',survived = 'X') {
 gender_ok <- c('female', 'male') 
 class_ok <- c('1st', '2nd', '3rd', 'deck crew', 'engineering crew', 'restaurant staff', 'victualling crew') 
 embarked_ok <- c('Belfast', 'Cherbourg', 'Queenstown', 'Southampton') 

(my_exp <- object_load("exp_name.rda"))
new_observation <- my_exp$data[1,]
subtitle = ""
 if(gender != 'X' & gender %in% gender_ok) {    new_observation[,'gender'] <- factor(gender, levels = gender_ok)
    subtitle <- paste(subtitle, '  gender:', gender)}
 if(class != 'X' & class %in% class_ok) {    new_observation[,'class'] <- factor(class, levels = class_ok)
    subtitle <- paste(subtitle, '  class:', class)}
 if(embarked != 'X' & embarked %in% embarked_ok) {    new_observation[,'embarked'] <- factor(embarked, levels = embarked_ok)
    subtitle <- paste(subtitle, '  embarked:', embarked)}
 if(age != 'X') {   new_observation[,'age'] <- as.numeric(as.character(age))
   subtitle <- paste(subtitle, '  age:', age)}
 if(fare != 'X') {   new_observation[,'fare'] <- as.numeric(as.character(fare))
   subtitle <- paste(subtitle, '  fare:', fare)}
 if(sibsp != 'X') {   new_observation[,'sibsp'] <- as.numeric(as.character(sibsp))
   subtitle <- paste(subtitle, '  sibsp:', sibsp)}
 if(parch != 'X') {   new_observation[,'parch'] <- as.numeric(as.character(parch))
   subtitle <- paste(subtitle, '  parch:', parch)}
 if(survived != 'X') {   new_observation[,'survived'] <- as.numeric(as.character(survived))
   subtitle <- paste(subtitle, '  survived:', survived)}

list(new_observation = new_observation, subtitle = subtitle)
}

#* @apiTitle Titanic

#* Using a glm model

#* @param gender X if missing. Factor, one of female, male
#* @param class X if missing. Factor, one of 1st, 2nd, 3rd, deck crew, engineering crew, restaurant staff, victualling crew
#* @param embarked X if missing. Factor, one of Belfast, Cherbourg, Queenstown, Southampton
#* @param  age  X if missing. Numeric
#* @param  fare  X if missing. Numeric
#* @param  sibsp  X if missing. Numeric
#* @param  parch  X if missing. Numeric
#* @param  survived  X if missing. Numeric

#* @get /predict
#* @post /predict
function(req, gender = 'X',age = 'X',class = 'X',embarked = 'X',fare = 'X',sibsp = 'X',parch = 'X',survived = 'X') {
tmp <- get_observation(gender,age,class,embarked,fare,sibsp,parch,survived)
new_observation <- tmp$new_observation
(my_exp <- object_load("exp_name.rda"))
pr <- predict(my_exp, new_observation)
list(
result_text = paste("Predicted value", pr),
result = pr,
raw_body = req$postBody)
}

#* Plot break down

#* @param gender X if missing. Factor, one of female, male
#* @param class X if missing. Factor, one of 1st, 2nd, 3rd, deck crew, engineering crew, restaurant staff, victualling crew
#* @param embarked X if missing. Factor, one of Belfast, Cherbourg, Queenstown, Southampton
#* @param  age  X if missing. Numeric
#* @param  fare  X if missing. Numeric
#* @param  sibsp  X if missing. Numeric
#* @param  parch  X if missing. Numeric
#* @param  survived  X if missing. Numeric

#* @get /break_down
#* @post /break_down
#* @png (width = 420, height = 250)
function(req, gender = 'X',age = 'X',class = 'X',embarked = 'X',fare = 'X',sibsp = 'X',parch = 'X',survived = 'X') {

  tmp <- get_observation(gender,age,class,embarked,fare,sibsp,parch,survived)
  new_observation <- tmp$new_observation
  (my_exp <- object_load("exp_name.rda"))
  pr <- predict(my_exp, new_observation)
  bd_plot <- iBreakDown::break_down(my_exp, new_observation)
  print(plot(bd_plot))
}


#* Plot ceteris paribus

#* @param variable variable to be explained
#* @param gender X if missing. Factor, one of female, male
#* @param class X if missing. Factor, one of 1st, 2nd, 3rd, deck crew, engineering crew, restaurant staff, victualling crew
#* @param embarked X if missing. Factor, one of Belfast, Cherbourg, Queenstown, Southampton
#* @param  age  X if missing. Numeric
#* @param  fare  X if missing. Numeric
#* @param  sibsp  X if missing. Numeric
#* @param  parch  X if missing. Numeric
#* @param  survived  X if missing. Numeric

#* @get /ceteris_paribus
#* @post /ceteris_paribus
#* @png (width = 420, height = 250)
function(req, variable, gender = 'X',age = 'X',class = 'X',embarked = 'X',fare = 'X',sibsp = 'X',parch = 'X',survived = 'X') {

  tmp <- get_observation(gender,age,class,embarked,fare,sibsp,parch,survived)
  new_observation <- tmp$new_observation
  (my_exp <- object_load("exp_name.rda"))

  if (!(variable %in% c('gender','age','class','embarked','fare','sibsp','parch','survived'))) {
    variable = 'gender'
  }

  pr <- predict(my_exp, new_observation)
  title = paste0("Prediction for ", variable, " = ", new_observation[[variable]], " is ", round(pr, 3))
  subtitle = paste0("Prediction for different values of ", variable, ":")
  grids = list()
  grids[[variable]] = sort(unique(my_exp$data[,variable]))
  cp_my_exp <- ceteris_paribus(my_exp, new_observation,
                                   variables = variable, variable_splits = grids)

  if (variable %in% c('age','fare','sibsp','parch','survived')) {
    pl <- plot(cp_my_exp) +
            show_observations(cp_my_exp, variables = variable, size = 5) +
            ylab(paste0("Prediction after change in ", variable)) + facet_null() +
            xlab(variable) +
            ggtitle(title, subtitle) +
            theme(plot.title = element_text(size = 12), plot.subtitle = element_text(size = 12))
  }
  if (variable %in% c('gender','class','embarked')){
    pl <- plot(cp_my_exp, only_numerical = FALSE) +
            ylab(paste0("Prediction after change in ", variable)) + facet_null() +
            xlab(variable) +
            ggtitle(title, subtitle) +
            theme(plot.title = element_text(size = 12), plot.subtitle = element_text(size = 12))
  }
  print(pl)
}

#* Break down description

#* @param gender X if missing. Factor, one of female, male
#* @param class X if missing. Factor, one of 1st, 2nd, 3rd, deck crew, engineering crew, restaurant staff, victualling crew
#* @param embarked X if missing. Factor, one of Belfast, Cherbourg, Queenstown, Southampton
#* @param  age  X if missing. Numeric
#* @param  fare  X if missing. Numeric
#* @param  sibsp  X if missing. Numeric
#* @param  parch  X if missing. Numeric
#* @param  survived  X if missing. Numeric

#* @get /break_down_desc
#* @post /break_down_desc
function(req, gender = 'X',age = 'X',class = 'X',embarked = 'X',fare = 'X',sibsp = 'X',parch = 'X',survived = 'X') {
  tmp <- get_observation(gender,age,class,embarked,fare,sibsp,parch,survived)
  new_observation <- tmp$new_observation
  (my_exp <- object_load("exp_name.rda"))
  pr <- predict(my_exp, new_observation)
  bd_explain <- iBreakDown::break_down(my_exp, new_observation)
  iBreakDown::describe(bd_explain,
                       label = "the prediction value is",
                       short_description = FALSE,
                       display_values =  TRUE,
                       display_numbers = TRUE,
                       display_distribution_details = FALSE)
}


#* Ceteris paribus description

#* @param variable variable to be explained
#* @param gender X if missing. Factor, one of female, male
#* @param class X if missing. Factor, one of 1st, 2nd, 3rd, deck crew, engineering crew, restaurant staff, victualling crew
#* @param embarked X if missing. Factor, one of Belfast, Cherbourg, Queenstown, Southampton
#* @param  age  X if missing. Numeric
#* @param  fare  X if missing. Numeric
#* @param  sibsp  X if missing. Numeric
#* @param  parch  X if missing. Numeric
#* @param  survived  X if missing. Numeric

#* @get /ceteris_paribus_desc
#* @post /ceteris_paribus_desc
function(req, variable, gender = 'X',age = 'X',class = 'X',embarked = 'X',fare = 'X',sibsp = 'X',parch = 'X',survived = 'X') {

  tmp <- get_observation(gender,age,class,embarked,fare,sibsp,parch,survived)
  new_observation <- tmp$new_observation
  (my_exp <- object_load("exp_name.rda"))

  if (!(variable %in% c('gender','age','class','embarked','fare','sibsp','parch','survived'))) {
    variable = 'gender'
  }

  pr <- predict(my_exp, new_observation)
  grids = list()
  grids[[variable]] = sort(unique(my_exp$data[,variable]))
  cp_my_exp <- ceteris_paribus(my_exp, new_observation,
                                   variables = variable, variable_splits = grids)
  ingredients::describe(cp_my_exp, label = "the predicted result")
}

