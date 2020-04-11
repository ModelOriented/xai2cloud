context("Check deploy_explainer() function")

source("helper_file.R")

test_that("All files are created",{
  deploy_explainer(exp_name = explainer_titanic, droplet = NA, deploy=FALSE)
  expect_true("exp_name" %in% list.files())
  expect_true("exp_name.rda" %in% list.files())
  expect_true("plumber.R" %in% list.files("exp_name"))
  expect_true("exp_name.rda" %in% list.files("exp_name"))
})

file.remove("exp_name.rda")
unlink("exp_name", recursive=TRUE)
