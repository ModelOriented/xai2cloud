context("Check object_load() function")

test_that("Type of output",{
  explainer <- object_load("./../objects_for_tests/explain_titanic.rda")
  expect_is(explainer, "explainer")
})
