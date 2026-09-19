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

test_that("sen_parse_response parses JSON without simplification", {
  resp <- httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"key": "value", "items": [{"a": 1}, {"a": 2}]}')
  )

  result <- sen_parse_response(resp, format = "json")
  expect_type(result, "list")
  expect_equal(result$key, "value")
  # arrays stay lists of records, never data.frames
  expect_false(is.data.frame(result$items))
  expect_equal(result$items[[2]]$a, 2)
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

test_that("sen_parse_response signals senado_error_format on malformed body", {
  resp <- httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw("not json {{{")
  )

  expect_error(
    sen_parse_response(resp, format = "json"),
    class = "senado_error_format"
  )
})

# --- sen_error_body ---------------------------------------------------------

problem_json <- function(status, body) {
  httr2::response(
    status_code = status,
    headers = list(`Content-Type` = "application/problem+json"),
    body = charToRaw(body)
  )
}

json_ok <- function(body = "[]") {
  httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(body)
  )
}

test_that("sen_error_body reads detail, then title, from problem+json", {
  expect_equal(
    sen_error_body(problem_json(400, '{"detail": "Limite o periodo.", "title": "Bad Request"}')),
    "Limite o periodo."
  )
  expect_equal(
    sen_error_body(problem_json(404, '{"status": 404, "title": "Not Found"}')),
    "Not Found"
  )
  html <- httr2::response(
    status_code = 500,
    headers = list(`Content-Type` = "text/html"),
    body = charToRaw("<html></html>")
  )
  expect_null(sen_error_body(html))
})

# --- sen_is_transient -------------------------------------------------------

test_that("sen_is_transient covers 429 and the 5xx of ADR-010", {
  transient <- vapply(
    c(429, 500, 502, 503, 504, 400, 404, 200),
    function(status) sen_is_transient(httr2::response(status_code = status)),
    logical(1)
  )
  expect_equal(transient, c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE))
})

# --- sen_get: errors carry a class and the API message ----------------------

test_that("HTTP 404 becomes senado_error_not_found, in a single request", {
  withr::local_options(senado.use_cache = FALSE, senado.max_tries = 1L)
  n <- 0
  httr2::local_mocked_responses(function(req) {
    n <<- n + 1
    problem_json(404, '{"instance": "/dadosabertos/processo/1", "status": 404, "title": "Not Found"}')
  })

  expect_error(sen_get("processo/1"), class = "senado_error_not_found")
  # a 404 must not trigger the XML fallback
  expect_equal(n, 1)
})

test_that("HTTP 400 becomes senado_error_bad_request with the API detail", {
  withr::local_options(senado.use_cache = FALSE, senado.max_tries = 1L)
  httr2::local_mocked_responses(function(req) {
    problem_json(400, '{"detail": "Limite o periodo a um ano.", "status": 400, "title": "Bad Request"}')
  })

  err <- expect_error(sen_get("processo"), class = "senado_error_bad_request")
  expect_s3_class(err, "senado_error")
  expect_match(conditionMessage(err$parent), "Limite o periodo a um ano.", fixed = TRUE)
})

test_that("HTTP 5xx becomes senado_error_unavailable", {
  withr::local_options(senado.use_cache = FALSE, senado.max_tries = 1L)
  httr2::local_mocked_responses(function(req) httr2::response(status_code = 503))

  expect_error(sen_get("votacao"), class = "senado_error_unavailable")
})

test_that("other HTTP errors become senado_error_http", {
  withr::local_options(senado.use_cache = FALSE, senado.max_tries = 1L)
  httr2::local_mocked_responses(function(req) httr2::response(status_code = 403))

  expect_error(sen_get("votacao"), class = "senado_error_http")
})

test_that("an unreachable host becomes senado_error_unavailable", {
  withr::local_options(senado.use_cache = FALSE)
  withr::with_envvar(c(SENADO_API_BASE_URL = "https://localhost:1"), {
    expect_error(sen_get("fake/path"), class = "senado_error_unavailable")
  })
})

# --- sen_get: fallback only on 406 or parse failure -------------------------

test_that("HTTP 406 falls back to the other format", {
  withr::local_options(senado.use_cache = FALSE, senado.max_tries = 1L)
  accepts <- character()
  httr2::local_mocked_responses(function(req) {
    accepts <<- c(accepts, req$headers$Accept)
    if (length(accepts) == 1) {
      return(httr2::response(status_code = 406))
    }
    httr2::response(
      status_code = 200,
      headers = list(`Content-Type` = "application/xml"),
      body = charToRaw("<root><item>hello</item></root>")
    )
  })

  result <- sen_get("dados/ListaAlgo.xml")
  expect_type(result, "list")
  expect_equal(accepts, c("application/json", "application/xml"))
})

# --- sen_get: query, cache and options --------------------------------------

test_that("sen_get drops NULL query parameters", {
  withr::local_options(senado.use_cache = FALSE)
  url <- NULL
  httr2::local_mocked_responses(function(req) {
    url <<- req$url
    json_ok()
  })

  sen_get("senador/lista/atual", query = list(uf = "SP", participacao = NULL))
  expect_match(url, "uf=SP", fixed = TRUE)
  expect_no_match(url, "participacao", fixed = TRUE)
})

test_that("sen_get answers a repeated request from the cache", {
  withr::local_options(senado.use_cache = TRUE)
  withr::defer(suppressMessages(sen_cache_clear()))
  n <- 0
  httr2::local_mocked_responses(function(req) {
    n <<- n + 1
    json_ok('[{"a": 1}]')
  })

  first <- sen_get("teste/cache-unico")
  second <- sen_get("teste/cache-unico")
  expect_equal(first, second)
  expect_equal(n, 1)
})

test_that("the timeout comes from the senado.timeout option (default 120 s)", {
  withr::local_options(senado.use_cache = FALSE, senado.timeout = NULL)
  seen <- numeric()
  httr2::local_mocked_responses(function(req) {
    seen <<- c(seen, req$options$timeout_ms)
    json_ok()
  })

  sen_get("a")
  withr::with_options(list(senado.timeout = 5), sen_get("b"))
  expect_equal(seen, c(120000, 5000))
})

# --- sen_api_available ------------------------------------------------------

test_that("sen_api_available is FALSE on CRAN", {
  withr::with_envvar(c(NOT_CRAN = NA), expect_false(sen_api_available()))
})

# --- Integration tests (skip if offline) ------------------------------------

test_that("sen_get retrieves data from the real API", {
  skip_on_cran()
  # Skip (never fail) when the portal is unreachable from this network:
  # legis.senado.leg.br times out for cloud-runner IPs, and a live-API
  # test must not fail R CMD check for an upstream outage -- it did on
  # 2026-08-24 (ubuntu-release).
  skip_if_api_unavailable()

  result <- sen_get("senador/lista/atual", cache_category = "semi_static")
  expect_type(result, "list")
  expect_true(length(result) > 0)
})

test_that("real API: a 404 from a v4 service is senado_error_not_found", {
  skip_on_cran()
  skip_if_api_unavailable()

  expect_error(sen_get("processo/1"), class = "senado_error_not_found")
})
