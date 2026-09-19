# Test helpers for senado package

skip_if_api_unavailable <- function() {
  withr::local_envvar(NOT_CRAN = "true")
  testthat::skip_if_not(sen_api_available(), "Senado API is unavailable")
}

# Mocked tests read the fixtures recorded by data-raw/record-fixtures.R.
# Dropping the base URL keeps the fixture paths short (R CMD check refuses
# paths longer than 100 bytes). httptest2 applies the redactor to the request
# URL too, so recorded and requested paths match.
if (requireNamespace("httptest2", quietly = TRUE)) {
  api_base <- "https://legis.senado.leg.br/dadosabertos/"
  httptest2::set_redactor(function(response) {
    httptest2::gsub_response(response, api_base, "", fixed = TRUE)
  })
}

with_api_fixtures <- function(code) {
  testthat::skip_if_not_installed("httptest2")
  withr::local_options(senado.use_cache = FALSE)
  httptest2::with_mock_dir("api", code)
}

# A tibble with exactly these columns, in this order, with these classes.
expect_cols <- function(tbl, types) {
  testthat::expect_s3_class(tbl, "tbl_df")
  testthat::expect_named(tbl, names(types))
  actual <- vapply(tbl, function(col) class(col)[1], character(1))
  testthat::expect_equal(unname(actual), unname(types))
}
