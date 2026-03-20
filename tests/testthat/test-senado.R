test_that("package loads correctly", {
  expect_true("senado" %in% loadedNamespaces())
})

test_that("default options are set", {
  expect_true(getOption("senado.use_cache", default = FALSE))
})
