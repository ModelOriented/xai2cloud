context("Check deploy_explainer() function")

source("helper_file.R")

test_that("All files are created",{
  # From object
  install.packages("randomForest")
  deploy_explainer(exp_name = explainer_titanic, model_package = "randomForest", droplet = NA, deploy=FALSE)
  expect_true("exp_name" %in% list.files())
  expect_true("exp_name.rda" %in% list.files())
  expect_true("plumber.R" %in% list.files("exp_name"))
  expect_true("exp_name.rda" %in% list.files("exp_name"))
  # From file
  deploy_explainer(exp_name = "./../objects_for_tests/explain_titanic.rda", model_package = "randomForest", droplet = NA, deploy=FALSE)
  expect_true("explain_titanic" %in% list.files())
  expect_true("plumber.R" %in% list.files("explain_titanic"))
  expect_true("explain_titanic.rda" %in% list.files("explain_titanic"))
})


file.remove("exp_name.rda")
unlink("exp_name", recursive=TRUE)
unlink("explain_titanic", recursive=TRUE)
