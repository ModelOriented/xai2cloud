context("Check get_template_data() function")

source("helper_file.R")

test_that("Type of output",{
  # From explainer object
  template_data <- get_template_data(exp_name = explainer_titanic, model_package = "randomForest")
  expect_is(template_data, "list")
  expect_is(unlist(template_data), "character")
  # From .rda file
  template_data_file <- get_template_data(exp_name = "./../objects_for_tests/explain_titanic.rda", model_package = "randomForest")
  expect_is(template_data_file, "list")
  expect_is(unlist(template_data_file), "character")
})

test_that("All parameters are included",{
  # From explainer object
  template_data <- get_template_data(exp_name = explainer_titanic, model_package = "randomForest")
  params_len <- sapply(strsplit(template_data$params, ","), length)
  params_amp_len <- sapply(strsplit(template_data$params_amp, ","), length)
  params_x_len <- sapply(strsplit(template_data$params_x, ","), length)
  expect_equal(params_len, params_amp_len)
  expect_equal(params_len, params_x_len)
  # From .rda file
  template_data_file <- get_template_data(exp_name = "./../objects_for_tests/explain_titanic.rda", model_package = "randomForest")
  params_len_file <- sapply(strsplit(template_data_file$params, ","), length)
  params_amp_len_file <- sapply(strsplit(template_data_file$params_amp, ","), length)
  params_x_len_file <- sapply(strsplit(template_data_file$params_x, ","), length)
  expect_equal(params_len_file, params_amp_len_file)
  expect_equal(params_len_file, params_x_len_file)
})

test_that("Parameters were divided into numerical and factors correctly",{
  # From explainer object
  template_data <- get_template_data(exp_name = explainer_titanic, model_package = "randomForest")
  all_params <- sapply(strsplit(template_data$params, ","), length)
  factors_and_numeric <- sapply(strsplit(template_data$params_factor, ","), length) + sapply(strsplit(template_data$params_numeric, ","), length)
  expect_equal(factors_and_numeric, all_params)
  # From .rda file
  template_data_file <- get_template_data(exp_name = explainer_titanic, model_package = "randomForest")
  all_params_file <- sapply(strsplit(template_data_file$params, ","), length)
  factors_and_numeric_file <- sapply(strsplit(template_data_file$params_factor, ","), length) + sapply(strsplit(template_data_file$params_numeric, ","), length)
  expect_equal(factors_and_numeric_file, all_params_file)
})


file.remove("explainer_titanic.rda")


