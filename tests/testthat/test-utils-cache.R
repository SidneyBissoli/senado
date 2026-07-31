# tests/testthat/test-utils-cache.R

# --- Cache init and stores --------------------------------------------------

test_that("sen_cache_init creates three stores", {
  sen_cache_init()
  expect_false(is.null(sen_cache_env$reference))
  expect_false(is.null(sen_cache_env$semi_static))
  expect_false(is.null(sen_cache_env$dynamic))
})

test_that("sen_cache_store returns a valid cache object", {
  store <- sen_cache_store("dynamic")
  expect_true(is.function(store$get))
  expect_true(is.function(store$set))
  expect_true(is.function(store$reset))
})

test_that("sen_cache_store rejects invalid category", {
  expect_error(sen_cache_store("invalid"), "should be one of")
})

# --- Cache get/set ----------------------------------------------------------

test_that("sen_cache_set and sen_cache_get round-trip a value", {
  sen_cache_init()
  sen_cache_set("test_key", list(a = 1), category = "dynamic")
  result <- sen_cache_get("test_key", category = "dynamic")
  expect_equal(result, list(a = 1))
})

test_that("sen_cache_get returns NULL for missing keys", {
  sen_cache_init()
  result <- sen_cache_get("nonexistent_key", category = "dynamic")
  expect_null(result)
})

test_that("cache is bypassed when senado.use_cache is FALSE", {
  sen_cache_init()
  withr::with_options(list(senado.use_cache = FALSE), {
    sen_cache_set("bypass_key", "value", category = "dynamic")
    result <- sen_cache_get("bypass_key", category = "dynamic")
    expect_null(result)
  })
})

test_that("cache works across categories independently", {
  sen_cache_init()
  sen_cache_set("shared_key", "ref_value", category = "reference")
  sen_cache_set("shared_key", "dyn_value", category = "dynamic")

  expect_equal(sen_cache_get("shared_key", category = "reference"), "ref_value")
  expect_equal(sen_cache_get("shared_key", category = "dynamic"), "dyn_value")
})

# --- sen_cache_clear --------------------------------------------------------

test_that("sen_cache_clear clears all categories", {
  sen_cache_init()
  sen_cache_set("k1", "v1", category = "reference")
  sen_cache_set("k2", "v2", category = "semi_static")
  sen_cache_set("k3", "v3", category = "dynamic")

  sen_cache_clear()

  expect_null(sen_cache_get("k1", category = "reference"))
  expect_null(sen_cache_get("k2", category = "semi_static"))
  expect_null(sen_cache_get("k3", category = "dynamic"))
})

test_that("sen_cache_clear clears only specified category", {
  sen_cache_init()
  sen_cache_set("k1", "v1", category = "reference")
  sen_cache_set("k2", "v2", category = "dynamic")

  sen_cache_clear("dynamic")

  expect_null(sen_cache_get("k2", category = "dynamic"))
  expect_equal(sen_cache_get("k1", category = "reference"), "v1")
})

# --- sen_cache_key ----------------------------------------------------------

test_that("sen_cache_key is deterministic", {
  key1 <- sen_cache_key("senador/lista/atual", NULL, "json")
  key2 <- sen_cache_key("senador/lista/atual", NULL, "json")
  expect_equal(key1, key2)
  expect_match(key1, "^[a-f0-9]+$")
})

test_that("sen_cache_key sorts query params", {
  k1 <- sen_cache_key("path", list(b = 2, a = 1), "json")
  k2 <- sen_cache_key("path", list(a = 1, b = 2), "json")
  expect_equal(k1, k2)
})

test_that("sen_cache_key differentiates by format", {
  key_json <- sen_cache_key("path", NULL, "json")
  key_xml <- sen_cache_key("path", NULL, "xml")
  expect_false(key_json == key_xml)
})
