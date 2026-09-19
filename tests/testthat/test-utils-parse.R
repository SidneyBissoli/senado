# tests/testthat/test-utils-parse.R

read_fixture <- function(...) {
  jsonlite::fromJSON(test_path("fixtures", ...), simplifyVector = FALSE)
}

# --- sen_col ----------------------------------------------------------------

test_that("sen_col fills the default format of dates and datetimes", {
  expect_null(sen_col("a", "A")$format)
  expect_equal(sen_col("a", "A", "date")$format, "%Y-%m-%d")
  expect_equal(sen_col("a", "A", "datetime")$format, "%Y-%m-%dT%H:%M:%OS")
  expect_equal(sen_col("a", "A", "date", format = "%d/%m/%Y")$format, "%d/%m/%Y")
})

test_that("sen_col rejects an unknown type", {
  expect_error(sen_col("a", "A", "factor"))
})

# --- sen_pluck / sen_as_records / sen_records -------------------------------

test_that("sen_pluck walks a path and returns NULL when a step is missing", {
  x <- list(a = list(b = list(c = 1)))
  expect_equal(sen_pluck(x, c("a", "b", "c")), 1)
  expect_null(sen_pluck(x, c("a", "z", "c")))
  expect_null(sen_pluck(x, c("a", "b", "c", "d")))
  expect_null(sen_pluck(list(1, 2), "a"))
})

test_that("sen_as_records turns a lone object into a list of one record", {
  lone <- list(Sigla = "PT", Nome = "Partido dos Trabalhadores")
  many <- list(list(Sigla = "PT"), list(Sigla = "PL"))

  expect_equal(sen_as_records(lone), list(lone))
  expect_equal(sen_as_records(many), many)
  expect_equal(sen_as_records(NULL), list())
  expect_equal(sen_as_records(list()), list())
})

test_that("sen_records reads a path, or the top-level array", {
  legacy <- list(Lista = list(Metadados = list(), Itens = list(Item = list(A = "1"))))
  expect_length(sen_records(legacy, c("Lista", "Itens", "Item")), 1)
  expect_length(sen_records(legacy, c("Lista", "Nada", "Item")), 0)
  expect_length(sen_records(list(list(a = 1), list(a = 2))), 2)
})

# --- Type parsers -----------------------------------------------------------

test_that("parse_logical reads the three boolean encodings of the API", {
  expect_equal(parse_logical(c("Sim", "N\u00e3o", NA)), c(TRUE, FALSE, NA))
  expect_equal(parse_logical(c("S", "N")), c(TRUE, FALSE))
  expect_equal(parse_logical(c("true", "false")), c(TRUE, FALSE))
  expect_equal(parse_logical(c("Talvez", "1")), c(NA, NA))
})

test_that("parse_integer converts text and warns about what it cannot read", {
  expect_equal(parse_integer(c("5322", NA)), c(5322L, NA))
  expect_warning(out <- parse_integer(c("12", "abc"), "code"), "code")
  expect_equal(out, c(12L, NA))
})

test_that("parse_double accepts comma as decimal separator", {
  expect_equal(parse_double(c("1,5", "2.75", NA)), c(1.5, 2.75, NA))
})

test_that("squish collapses whitespace and line breaks", {
  expect_equal(squish(c("  a \n\n b  ", NA)), c("a b", NA))
})

# --- sen_as_tibble ----------------------------------------------------------

spec_basic <- list(
  sen_col("senator_code", c("Id", "Codigo"), "integer"),
  sen_col("name", c("Id", "Nome")),
  sen_col("board_member", "MembroMesa", "logical"),
  sen_col("birth_date", "DataNascimento", "date"),
  sen_col("start_date", "DataInicio", "date", format = "%d/%m/%Y"),
  sen_col("updated_at", "Atualizacao", "datetime")
)

test_that("sen_as_tibble selects, renames and converts by specification", {
  records <- list(
    list(
      Id = list(Codigo = "5322", Nome = "Rom\u00e1rio", Extra = "x"),
      MembroMesa = "N\u00e3o", DataNascimento = "1966-01-29",
      DataInicio = "01/02/2023", Atualizacao = "2026-07-01T10:27:23.914"
    ),
    list(Id = list(Codigo = "825", Nome = "Paulo Paim"), MembroMesa = "Sim")
  )
  result <- sen_as_tibble(records, spec_basic)

  expect_s3_class(result, "tbl_df")
  expect_named(result, c(
    "senator_code", "name", "board_member", "birth_date", "start_date",
    "updated_at"
  ))
  expect_equal(result$senator_code, c(5322L, 825L))
  expect_equal(result$board_member, c(FALSE, TRUE))
  expect_equal(result$birth_date, as.Date(c("1966-01-29", NA)))
  expect_equal(result$start_date, as.Date(c("2023-02-01", NA)))
  expect_s3_class(result$updated_at, "POSIXct")
  expect_equal(format(result$updated_at[1], "%Y-%m-%d %H:%M"), "2026-07-01 10:27")
})

test_that("sen_as_tibble returns 0 rows with typed columns for no records", {
  result <- sen_as_tibble(list(), spec_basic)

  expect_equal(dim(result), c(0L, 6L))
  expect_type(result$senator_code, "integer")
  expect_type(result$name, "character")
  expect_type(result$board_member, "logical")
  expect_s3_class(result$birth_date, "Date")
  expect_s3_class(result$updated_at, "POSIXct")
})

test_that("column types do not depend on the content", {
  spec <- list(sen_col("vote", "voto"), sen_col("text", "texto"))
  records <- list(
    list(voto = "Sim", texto = "2024"),
    list(voto = "N\u00e3o", texto = "2025")
  )
  result <- sen_as_tibble(records, spec)

  expect_type(result$vote, "character")
  expect_type(result$text, "character")
})

test_that("the literal string \"NA\" is kept as a value", {
  spec <- list(sen_col("vote", "voto"))
  result <- sen_as_tibble(list(list(voto = "NA"), list(voto = NULL)), spec)

  expect_equal(result$vote, c("NA", NA))
  expect_equal(is.na(result$vote), c(FALSE, TRUE))
})

test_that("trim = TRUE squishes text columns", {
  spec <- list(sen_col("result", "texto", trim = TRUE))
  result <- sen_as_tibble(list(list(texto = "  Aprovado.\n\n ")), spec)
  expect_equal(result$result, "Aprovado.")
})

test_that("list columns become tibbles, whether the node is object or array", {
  party_spec <- list(
    sen_col("party", "Sigla"),
    sen_col("joined", "DataFiliacao", "date")
  )
  spec <- list(
    sen_col("mandate_code", "CodigoMandato", "integer"),
    sen_col("parties", c("Partidos", "Partido"), "list", spec = party_spec)
  )
  records <- list(
    list(CodigoMandato = "1", Partidos = list(
      Partido = list(Sigla = "PT", DataFiliacao = "1985-01-01")
    )),
    list(CodigoMandato = "2", Partidos = list(Partido = list(
      list(Sigla = "PL", DataFiliacao = "2021-04-08"),
      list(Sigla = "S/Partido", DataFiliacao = "2026-09-10")
    ))),
    list(CodigoMandato = "3")
  )
  result <- sen_as_tibble(records, spec)

  expect_type(result$parties, "list")
  expect_equal(vapply(result$parties, nrow, integer(1)), c(1L, 2L, 0L))
  expect_named(result$parties[[3]], c("party", "joined"))
  expect_s3_class(result$parties[[2]]$joined, "Date")
})

test_that("a list column without spec keeps the raw node", {
  spec <- list(sen_col("raw", "x", "list"))
  result <- sen_as_tibble(list(list(x = list(1, 2))), spec)
  expect_equal(result$raw[[1]], list(1, 2))
})

test_that(".unnest yields one row per nested element and keeps empty parents", {
  spec <- list(
    sen_col("session_id", "codigo", "integer"),
    sen_col("item", c("itens", "nome"))
  )
  records <- list(
    list(codigo = 1, itens = list(list(nome = "a"), list(nome = "b"))),
    list(codigo = 2, itens = list(nome = "c")),
    list(codigo = 3, itens = NULL),
    list(codigo = 4)
  )
  result <- sen_as_tibble(records, spec, .unnest = "itens")

  expect_equal(result$session_id, c(1L, 1L, 2L, 3L, 4L))
  expect_equal(result$item, c("a", "b", "c", NA, NA))
})

# --- sen_as_tibble against real v4 fixtures ---------------------------------

vote_spec <- list(
  sen_col("vote_id", "codigoSessaoVotacao", "integer"),
  sen_col("session_date", "dataSessao", "datetime"),
  sen_col("bill_code", "codigoMateria", "integer"),
  sen_col("process_id", "idProcesso", "integer"),
  sen_col("description", "descricaoVotacao"),
  sen_col("secret", "votacaoSecreta", "logical"),
  sen_col("total_yes", "totalVotosSim", "integer")
)

record_spec <- c(vote_spec[c(1, 6)], list(
  sen_col("senator_code", c("votos", "codigoParlamentar"), "integer"),
  sen_col("vote", c("votos", "siglaVotoParlamentar"))
))

test_that("v4 fixture: /processo list", {
  spec <- list(
    sen_col("process_id", "id", "integer"),
    sen_col("bill_code", "codigoMateria", "integer"),
    sen_col("presented_on", "dataApresentacao", "date"),
    sen_col("updated_at", "dataUltimaAtualizacao", "datetime"),
    sen_col("summary", "ementa")
  )
  result <- sen_as_tibble(sen_records(read_fixture("v4", "processo-lista.json")), spec)

  expect_equal(nrow(result), 1L)
  expect_equal(result$process_id, 8617172L)
  expect_equal(result$bill_code, 161942L)
  expect_equal(result$presented_on, as.Date("2024-02-06"))
  expect_s3_class(result$updated_at, "POSIXct")
  expect_false(is.na(result$updated_at))
})

test_that("v4 fixture: /processo/{id} is a single object", {
  spec <- list(
    sen_col("process_id", "id", "integer"),
    sen_col("bill_code", "codigoMateria", "integer")
  )
  result <- sen_as_tibble(sen_records(read_fixture("v4", "processo-id.json")), spec)

  expect_equal(nrow(result), 1L)
  expect_equal(result$process_id, 8617172L)
})

test_that("v4 fixture: nominal vote, one row per vote and per senator", {
  votes <- sen_records(read_fixture("v4", "votacao-nominal.json"))

  by_vote <- sen_as_tibble(votes, vote_spec)
  expect_equal(nrow(by_vote), 1L)
  expect_false(by_vote$secret)
  # the API leaves the totals empty in this vote; the column is still integer
  expect_identical(by_vote$total_yes, NA_integer_)
  # a 1,500-character description must not trip any date parser
  expect_type(by_vote$description, "character")

  by_senator <- sen_as_tibble(votes, record_spec, .unnest = "votos")
  expect_equal(nrow(by_senator), 81L)
  expect_type(by_senator$vote, "character")
  expect_true(all(c("Sim", "N\u00e3o") %in% by_senator$vote))
  expect_false(anyNA(by_senator$senator_code))
})

test_that("v4 fixture: secret vote keeps \"Votou\" and the API totals", {
  votes <- sen_records(read_fixture("v4", "votacao-secreta.json"))

  by_vote <- sen_as_tibble(votes, vote_spec)
  expect_true(by_vote$secret)
  expect_equal(by_vote$total_yes, 48L)

  by_senator <- sen_as_tibble(votes, record_spec, .unnest = "votos")
  expect_true("Votou" %in% by_senator$vote)
})

test_that("v4 fixture: empty /votacao gives 0 rows with the spec columns", {
  votes <- sen_records(read_fixture("v4", "votacao-vazio.json"))
  result <- sen_as_tibble(votes, record_spec, .unnest = "votos")

  expect_equal(nrow(result), 0L)
  expect_named(result, c("vote_id", "secret", "senator_code", "vote"))
  expect_type(result$vote_id, "integer")
})

# --- ensure_utf8 ------------------------------------------------------------

test_that("ensure_utf8 marks character columns as UTF-8", {
  tbl <- tibble::tibble(x = "caf\u00e9", y = 1)
  result <- ensure_utf8(tbl)
  expect_equal(Encoding(result$x), "UTF-8")
})
