context("Check get_template() function")

test_that("Type of output",{
  template <- get_template()
  expect_is(template, "character")
})
