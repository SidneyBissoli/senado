# tests/testthat/test-utils-parse.R

# --- to_snake_case ----------------------------------------------------------

test_that("to_snake_case converts PascalCase", {
  expect_equal(to_snake_case("CodigoParlamentar"), "codigo_parlamentar")
  expect_equal(to_snake_case("NomeParlamentar"), "nome_parlamentar")
})

test_that("to_snake_case converts camelCase", {
  expect_equal(to_snake_case("codigoParlamentar"), "codigo_parlamentar")
  expect_equal(to_snake_case("siglaPartido"), "sigla_partido")
})

test_that("to_snake_case handles consecutive uppercase (acronyms)", {
  expect_equal(to_snake_case("XMLParser"), "xml_parser")
  expect_equal(to_snake_case("getHTTPResponse"), "get_http_response")
})

test_that("to_snake_case handles dots, hyphens, and spaces", {
  expect_equal(to_snake_case("some.name"), "some_name")
  expect_equal(to_snake_case("some-name"), "some_name")
  expect_equal(to_snake_case("some name"), "some_name")
})

test_that("to_snake_case collapses multiple separators", {
  expect_equal(to_snake_case("a__b"), "a_b")
  expect_equal(to_snake_case("a..b"), "a_b")
})

test_that("to_snake_case strips leading/trailing underscores", {
  expect_equal(to_snake_case("_foo_"), "foo")
})

test_that("to_snake_case is idempotent on snake_case input", {
  expect_equal(to_snake_case("already_snake"), "already_snake")
})

# --- flatten_list -----------------------------------------------------------

test_that("flatten_list flattens a simple nested list", {
  input <- list(a = list(b = 1, c = 2), d = 3)
  result <- flatten_list(input)
  expect_equal(result, list(a_b = 1, a_c = 2, d = 3))
})

test_that("flatten_list handles deeply nested lists", {
  input <- list(x = list(y = list(z = "deep")))
  result <- flatten_list(input)
  expect_equal(result, list(x_y_z = "deep"))
})

test_that("flatten_list preserves vectors as-is", {
  input <- list(a = c(1, 2, 3), b = "text")
  result <- flatten_list(input)
  expect_equal(result$a, c(1, 2, 3))
  expect_equal(result$b, "text")
})

# --- is_logical_field / parse_logical ---------------------------------------

test_that("is_logical_field detects Sim/Não", {

  expect_true(is_logical_field(c("Sim", "N\u00e3o", "Sim")))
  expect_true(is_logical_field(c("S", "N")))
  expect_true(is_logical_field(c("true", "false")))
})

test_that("is_logical_field rejects mixed content", {
  expect_false(is_logical_field(c("Sim", "Maybe")))
  expect_false(is_logical_field(c("1", "0")))
})

test_that("parse_logical converts correctly", {
  expect_equal(parse_logical(c("Sim", "N\u00e3o", NA)), c(TRUE, FALSE, NA))
  expect_equal(parse_logical(c("S", "N")), c(TRUE, FALSE))
  expect_equal(parse_logical(c("true", "false")), c(TRUE, FALSE))
})

# --- is_numeric_field / parse_numeric ---------------------------------------

test_that("is_numeric_field detects numeric strings", {
  expect_true(is_numeric_field(c("123", "456")))
  expect_true(is_numeric_field(c("12.5", "3.14")))
  expect_true(is_numeric_field(c("12,5", "3,14")))
  expect_true(is_numeric_field(c("-10", "20")))
})

test_that("is_numeric_field rejects non-numeric strings", {
  expect_false(is_numeric_field(c("abc", "123")))
  expect_false(is_numeric_field(c("12.5.6")))
  expect_false(is_numeric_field(c("")))
})

test_that("parse_numeric handles comma as decimal separator", {
  expect_equal(parse_numeric(c("1,5", "2,75")), c(1.5, 2.75))
  expect_equal(parse_numeric(c("10", NA)), c(10, NA))
})

# --- try_parse_date ---------------------------------------------------------

test_that("try_parse_date parses ISO dates", {
  result <- try_parse_date(c("2024-01-15", "2024-06-30"))
  expect_s3_class(result, "Date")
  expect_equal(result, as.Date(c("2024-01-15", "2024-06-30")))
})

test_that("try_parse_date parses BR dates (dd/mm/yyyy)", {
  result <- try_parse_date(c("15/01/2024", "30/06/2024"))
  expect_s3_class(result, "Date")
  expect_equal(as.character(result), c("2024-01-15", "2024-06-30"))
})

test_that("try_parse_date parses ISO datetimes", {
  result <- try_parse_date(c("2024-01-15T10:30:00", "2024-06-30T14:00:00"))
  expect_s3_class(result, "POSIXct")
})

test_that("try_parse_date returns NULL for non-date strings", {
  expect_null(try_parse_date(c("hello", "world")))
  expect_null(try_parse_date(c("123", "456")))
})

# --- sen_as_tibble ----------------------------------------------------------

test_that("sen_as_tibble converts a nested list to a tidy tibble", {
  input <- list(
    CodigoParlamentar = c("123", "456"),
    NomeParlamentar = c("Fulano", "Beltrano"),
    Ativo = c("Sim", "N\u00e3o"),
    DataNascimento = c("1970-05-20", "1980-11-03")
  )
  result <- sen_as_tibble(as.data.frame(input, stringsAsFactors = FALSE))

  expect_s3_class(result, "tbl_df")
  expect_equal(names(result), c("codigo_parlamentar", "nome_parlamentar",
                                "ativo", "data_nascimento"))
  expect_type(result$codigo_parlamentar, "double")
  expect_type(result$ativo, "logical")
  expect_s3_class(result$data_nascimento, "Date")
})

test_that("sen_as_tibble handles a data.frame input", {
  df <- data.frame(SomeCol = c("a", "b"), stringsAsFactors = FALSE)
  result <- sen_as_tibble(df)
  expect_s3_class(result, "tbl_df")
  expect_equal(names(result), "some_col")
})

# --- ensure_utf8 ------------------------------------------------------------

test_that("ensure_utf8 marks character columns as UTF-8", {
  tbl <- tibble::tibble(x = "caf\u00e9", y = 1)
  result <- ensure_utf8(tbl)
  expect_equal(Encoding(result$x), "UTF-8")
})
