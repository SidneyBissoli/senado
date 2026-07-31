# tests/testthat/test-utils-validate.R

# --- validate_year ----------------------------------------------------------

test_that("validate_year accepts valid years", {
  expect_invisible(validate_year(2024))
  expect_equal(validate_year(1991), 1991L)
  expect_equal(validate_year(as.integer(format(Sys.Date(), "%Y"))),
               as.integer(format(Sys.Date(), "%Y")))
})

test_that("validate_year rejects years before 1991", {
  expect_error(validate_year(1990), "1991")
  expect_error(validate_year(1800), "1991")
})

test_that("validate_year rejects future years", {
  expect_error(validate_year(2099), "current year")
})

test_that("validate_year rejects non-integer input", {
  expect_error(validate_year(2024.5), "whole number")
  expect_error(validate_year("2024"), "numeric")
  expect_error(validate_year(NULL), "single")
  expect_error(validate_year(NA), "single")
  expect_error(validate_year(c(2020, 2021)), "single")
})

# --- validate_senator_code --------------------------------------------------

test_that("validate_senator_code accepts positive integers", {
  expect_invisible(validate_senator_code(123))
  expect_equal(validate_senator_code(1), 1L)
  expect_equal(validate_senator_code(5012), 5012L)
})

test_that("validate_senator_code rejects non-positive values", {
  expect_error(validate_senator_code(0), "positive")
  expect_error(validate_senator_code(-1), "positive")
})

test_that("validate_senator_code rejects bad types", {
  expect_error(validate_senator_code("abc"), "numeric")
  expect_error(validate_senator_code(NA), "single")
})

# --- validate_bill_code -----------------------------------------------------

test_that("validate_bill_code accepts positive integers", {
  expect_equal(validate_bill_code(999), 999L)
})

test_that("validate_bill_code rejects non-positive values", {
  expect_error(validate_bill_code(0), "positive")
  expect_error(validate_bill_code(-5), "positive")
})

# --- validate_party ---------------------------------------------------------

test_that("validate_party accepts valid abbreviations", {
  expect_equal(validate_party("PT"), "PT")
  expect_equal(validate_party("pl"), "PL")
  expect_equal(validate_party(" mdb "), "MDB")
})

test_that("validate_party rejects non-string input", {
  expect_error(validate_party(123), "character")
  expect_error(validate_party(c("PT", "PL")), "single")
})

test_that("validate_party rejects strings with non-letter characters", {
  expect_error(validate_party("PT1"), "only letters")
  expect_error(validate_party("P-T"), "only letters")
})

# --- validate_uf ------------------------------------------------------------

test_that("validate_uf accepts valid state codes", {
  expect_equal(validate_uf("SP"), "SP")
  expect_equal(validate_uf("rj"), "RJ")
  expect_equal(validate_uf(" df "), "DF")
})

test_that("validate_uf rejects invalid state codes", {
  expect_error(validate_uf("XX"), "not a valid")
  expect_error(validate_uf("ABC"), "not a valid")
})

test_that("validate_uf lists valid values in error", {
  expect_error(validate_uf("ZZ"), "Valid values")
})

test_that("validate_uf rejects non-string input", {
  expect_error(validate_uf(11), "character")
  expect_error(validate_uf(c("SP", "RJ")), "single")
})
