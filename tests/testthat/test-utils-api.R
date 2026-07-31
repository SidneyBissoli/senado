# tests/testthat/test-utils-api.R

# --- sen_base_url -----------------------------------------------------------

test_that("sen_base_url returns default URL", {
  withr::with_envvar(c(SENADO_API_BASE_URL = NA), {
    expect_equal(sen_base_url(), "https://legis.senado.leg.br/dadosabertos")
  })
})

test_that("sen_base_url respects environment variable", {
  withr::with_envvar(c(SENADO_API_BASE_URL = "https://mock.api"), {
    expect_equal(sen_base_url(), "https://mock.api")
  })
})

# --- sen_user_agent ---------------------------------------------------------

test_that("sen_user_agent includes package name and version", {
  ua <- sen_user_agent()
  expect_match(ua, "^senado/")
  expect_match(ua, "github\\.com/SidneyBissoli/senado")
})

# --- sen_cache_key (defined in utils-api.R) ---------------------------------

test_that("sen_cache_key returns a deterministic hash string", {
  key1 <- sen_cache_key("test/path", NULL, "json")
  key2 <- sen_cache_key("test/path", NULL, "json")
  expect_equal(key1, key2)
  expect_match(key1, "^[a-f0-9]+$")
})

test_that("sen_cache_key differs by query params and format", {
  k1 <- sen_cache_key("ep", list(a = 1, z = 3), "json")
  k2 <- sen_cache_key("ep", list(z = 3, a = 1), "json")
  k3 <- sen_cache_key("ep", list(a = 1, z = 3), "xml")
  # Same params in different order → same key
  expect_equal(k1, k2)
  # Different format → different key
  expect_false(k1 == k3)
})

# --- sen_parse_response -----------------------------------------------------

test_that("sen_parse_response parses JSON response", {
  # Build a minimal mock response
  resp <- httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"key": "value", "num": 42}')
  )

  result <- sen_parse_response(resp, format = "json")
  expect_type(result, "list")
  expect_equal(result$key, "value")
  expect_equal(result$num, 42)
})

test_that("sen_parse_response parses XML response", {
  xml_body <- "<root><item>hello</item></root>"
  resp <- httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "application/xml"),
    body = charToRaw(xml_body)
  )

  result <- sen_parse_response(resp, format = "xml")
  expect_type(result, "list")
})

test_that("sen_parse_response returns NULL on malformed body", {
  resp <- httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw("not json {{{")
  )

  suppressMessages({
    result <- sen_parse_response(resp, format = "json")
  })
  expect_null(result)
})

# --- sen_request (offline) --------------------------------------------------

test_that("sen_request returns NULL when API is unreachable", {
  withr::with_envvar(c(SENADO_API_BASE_URL = "https://localhost:1"), {
    result <- suppressMessages(sen_request("fake/path", format = "json"))
    expect_null(result)
  })
})

# --- sen_get (offline) ------------------------------------------------------

test_that("sen_get aborts when both formats fail", {
  withr::with_envvar(c(SENADO_API_BASE_URL = "https://localhost:1"), {
    expect_error(
      suppressMessages(sen_get("fake/path")),
      "Failed to retrieve data"
    )
  })
})

# --- Integration tests (skip if offline) ------------------------------------

test_that("sen_get retrieves data from the real API", {
  skip_if_offline()
  skip_on_cran()

  # Use a lightweight endpoint
  result <- sen_get("senador/lista/atual", cache_category = "semi_static")
  expect_type(result, "list")
  expect_true(length(result) > 0)
})
