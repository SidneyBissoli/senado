# tests/testthat/test-reference.R
# Mocked tests read tests/testthat/api (see data-raw/record-fixtures.R).

# --- sen_legislatures -------------------------------------------------------

test_that("sen_legislatures returns one row per legislature", {
  with_api_fixtures({
    result <- sen_legislatures()
  })

  expect_cols(result, c(
    legislature = "integer", start_date = "Date", end_date = "Date",
    election_date = "Date", sessions = "list"
  ))
  expect_equal(result$legislature, 58:55)
  expect_equal(result$start_date[2], as.Date("2023-02-01"))
})

test_that("sen_legislatures keeps the legislative sessions in a list-column", {
  with_api_fixtures({
    result <- sen_legislatures()
  })
  sessions <- result$sessions[[which(result$legislature == 57L)]]

  expect_cols(sessions, c(
    session_number = "integer", session_type = "character",
    start_date = "Date", end_date = "Date"
  ))
  expect_equal(nrow(sessions), 6L)
  # the legislature yet to begin has no session, but has the columns
  future <- result$sessions[[which(result$legislature == 58L)]]
  expect_equal(nrow(future), 0L)
  expect_named(future, names(sessions))
})

# --- sen_current_legislature (internal) -------------------------------------

test_that("sen_current_legislature returns the legislature in force on a date", {
  with_api_fixtures({
    result <- sen_current_legislature(as.Date("2026-09-19"))
  })
  expect_identical(result, 57L)
})

test_that("sen_current_legislature aborts when no legislature covers the date", {
  with_api_fixtures({
    expect_error(
      sen_current_legislature(as.Date("1800-01-01")),
      class = "senado_error_not_found"
    )
  })
})

# --- sen_parties ------------------------------------------------------------

test_that("sen_parties returns active and extinct parties", {
  with_api_fixtures({
    result <- sen_parties()
  })

  expect_cols(result, c(
    party_code = "integer", party = "character", party_name = "character",
    creation_date = "Date", extinction_date = "Date"
  ))
  expect_equal(nrow(result), 6L)
  expect_equal(result$party[1], "AGIR")
  # DataExtincao exists only in extinct parties
  expect_true(is.na(result$extinction_date[result$party == "AGIR"]))
  expect_equal(
    result$extinction_date[result$party == "ANL"],
    as.Date("1937-12-02")
  )
})

# --- sen_bill_types ---------------------------------------------------------

test_that("sen_bill_types reads the top-level array of a v4 service", {
  with_api_fixtures({
    result <- sen_bill_types()
  })

  expect_cols(result, c(
    type = "character", description = "character",
    start_date = "Date", end_date = "Date"
  ))
  expect_equal(nrow(result), 8L)
  expect_equal(result$type[1], "ACE")
  # "2017-01-01T00:00:00" is read as a date
  expect_equal(result$start_date[1], as.Date("2017-01-01"))
  expect_true(anyNA(result$end_date))
})

# --- sen_bill_statuses ------------------------------------------------------

test_that("sen_bill_statuses returns typed columns", {
  with_api_fixtures({
    result <- sen_bill_statuses()
  })

  expect_cols(result, c(
    status_id = "integer", status = "character", description = "character",
    start_date = "Date", end_date = "Date"
  ))
  expect_equal(nrow(result), 8L)
  expect_equal(result$status[1], "AGDDO")
  expect_equal(result$status_id[1], 86L)
})

# --- Integration ------------------------------------------------------------

test_that("real API: reference data", {
  skip_on_cran()
  skip_if_api_unavailable()

  legislatures <- sen_legislatures()
  expect_gte(nrow(legislatures), 58L)
  expect_false(anyNA(legislatures$legislature))
  expect_false(anyNA(legislatures$start_date))

  expect_gte(sen_current_legislature(), 57L)

  parties <- sen_parties()
  expect_gt(nrow(parties), 50L)
  expect_true(all(c("PT", "PL", "MDB") %in% parties$party))

  types <- sen_bill_types()
  expect_true(all(c("PEC", "PL", "PLP") %in% types$type))

  statuses <- sen_bill_statuses()
  expect_gt(nrow(statuses), 50L)
  expect_false(anyNA(statuses$status_id))
})
