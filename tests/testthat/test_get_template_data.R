context("Check get_template_data() function")

source("helper_file.R")

test_that("Type of output",{
  template_data <- get_template_data(exp_name = explainer_titanic)
  expect_is(template_data, "list")
  expect_is(unlist(template_data), "character")
})

test_that("All parameters are included",{
  template_data <- get_template_data(exp_name = explainer_titanic)
  params_len <- sapply(strsplit(template_data$params, ","), length)
  params_amp_len <- sapply(strsplit(template_data$params_amp, ","), length)
  params_x_len <- sapply(strsplit(template_data$params_x, ","), length)
  expect_equal(params_len, params_amp_len)
  expect_equal(params_len, params_x_len)
})

test_that("Parameters were divided into numerical and factors correctly",{
  template_data <- get_template_data(exp_name = explainer_titanic)
  all_params <- sapply(strsplit(template_data$params, ","), length)
  factors_and_numeric <- sapply(strsplit(template_data$params_factor, ","), length) + sapply(strsplit(template_data$params_numeric, ","), length)
  expect_equal(factors_and_numeric, all_params)
})

file.remove("explainer_titanic.rda")


