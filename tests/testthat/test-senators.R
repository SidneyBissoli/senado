# tests/testthat/test-senators.R
# Mocked tests read tests/testthat/api (see data-raw/record-fixtures.R).
# Lists in the fixtures are trimmed: row counts below are those of the fixture.

senator_cols <- c(
  senator_code = "integer", name = "character", full_name = "character",
  sex = "character", treatment = "character", party = "character",
  state = "character", participation = "character", mandate_code = "integer",
  first_legislature = "integer", second_legislature = "integer",
  bloc = "character", board_member = "logical", leadership_member = "logical",
  email = "character", photo_url = "character", page_url = "character",
  mandates = "list"
)

# --- sen_senators -----------------------------------------------------------

test_that("sen_senators lists the senators in office", {
  with_api_fixtures({
    result <- sen_senators()
  })

  expect_cols(result, senator_cols)
  expect_equal(nrow(result), 5L)
  expect_false(anyNA(result$senator_code))
  expect_false(anyNA(result$party))
  expect_false(anyNA(result$state))
  expect_type(result$board_member, "logical")
  expect_false(anyNA(result$board_member))
  # "Senador " arrives with a trailing space
  expect_true(all(result$treatment %in% c("Senador", "Senadora")))
  # the single `Mandato` of the current list also feeds the list-column
  expect_equal(vapply(result$mandates, nrow, integer(1)), rep(1L, 5))
  expect_equal(result$mandates[[1]]$mandate_code, result$mandate_code[1])
})

test_that("sen_senators filters by party on the client, ignoring case", {
  with_api_fixtures({
    result <- sen_senators(party = "pt")
  })

  expect_equal(nrow(result), 2L)
  expect_equal(unique(result$party), "PT")
})

test_that("sen_senators sends state and status to the API", {
  with_api_fixtures({
    by_state <- sen_senators(state = "sp")
    substitutes <- sen_senators(status = "substitute")
  })

  expect_equal(unique(by_state$state), "SP")
  expect_true(all(grepl("Suplente", substitutes$participation)))

  httptest2::with_mock_api({
    expect_error(sen_senators(state = "RJ", status = "holder"), "uf=RJ")
    expect_error(sen_senators(state = "RJ", status = "holder"), "participacao=T")
  })
})

test_that("sen_senators lists a legislature, with every mandate of each senator", {
  with_api_fixtures({
    result <- sen_senators(57)
  })

  expect_cols(result, senator_cols)
  expect_equal(nrow(result), 4L)
  expect_false(anyNA(result$state))
  # columns that exist only for current senators
  expect_true(all(is.na(result$bloc)))
  expect_true(all(is.na(result$board_member)))

  # Carlos Favaro held two mandates in the 57th legislature: one row, the
  # flat columns describe the most recent mandate
  favaro <- result[result$senator_code == 6295L, ]
  expect_equal(nrow(favaro), 1L)
  expect_equal(favaro$mandates[[1]]$mandate_code, c(582L, 592L))
  expect_equal(favaro$mandate_code, 592L)
})

test_that("sen_senators accepts a range of legislatures and in_office", {
  with_api_fixtures({
    range <- sen_senators(c(55, 57))
    in_office <- sen_senators(57, in_office = TRUE)
  })

  expect_cols(range, senator_cols)
  expect_gt(nrow(range), 0L)
  expect_gt(nrow(in_office), 0L)

  httptest2::with_mock_api({
    expect_error(sen_senators(56, in_office = FALSE), "exercicio=N")
    expect_error(sen_senators(c(50, 52)), "legislatura/50/52")
  })
})

test_that("sen_senators returns 0 rows with columns for an unknown legislature", {
  with_api_fixtures({
    result <- sen_senators(999)
  })

  expect_cols(result, senator_cols)
  expect_equal(nrow(result), 0L)
})

test_that("sen_senators validates its arguments before any request", {
  httptest2::without_internet({
    expect_error(sen_senators(state = "XX"), "not a valid")
    expect_error(sen_senators(status = "retired"), "must be one of")
    expect_error(sen_senators(57, party = "PT"), "currently in office")
    expect_error(sen_senators(in_office = TRUE), "together with")
    expect_error(sen_senators(57, in_office = "yes"), "TRUE")
    expect_error(sen_senators(c(57, 55)), "earlier to the later")
    expect_error(sen_senators(1:3), "one number or a pair")
    expect_error(sen_senators("57"), "numeric")
    expect_error(sen_senators(party = 13), "character")
  })
})

# --- sen_senator ------------------------------------------------------------

test_that("sen_senator returns one row with the details", {
  with_api_fixtures({
    result <- sen_senator(5322)
  })

  expect_cols(result, c(
    senator_code = "integer", name = "character", full_name = "character",
    sex = "character", party = "character", state = "character",
    birth_date = "Date", birthplace = "character",
    birthplace_state = "character", office_address = "character",
    email = "character", photo_url = "character", page_url = "character",
    personal_url = "character", phones = "list"
  ))
  expect_equal(nrow(result), 1L)
  expect_equal(result$senator_code, 5322L)
  expect_equal(result$birth_date, as.Date("1966-01-29"))
  expect_equal(result$state, "RJ")
  # runs of spaces in the address are collapsed
  expect_no_match(result$office_address, "  ", fixed = TRUE)

  expect_cols(result$phones[[1]], c(number = "character", fax = "logical"))
  expect_equal(nrow(result$phones[[1]]), 3L)
})

test_that("sen_senator signals senado_error_not_found for an unknown code", {
  with_api_fixtures({
    expect_error(sen_senator(99999999), class = "senado_error_not_found")
  })
})

test_that("sen_senator validates the code", {
  httptest2::without_internet({
    expect_error(sen_senator("abc"), "numeric")
    expect_error(sen_senator(-1), "positive")
    expect_error(sen_senator(c(1, 2)), "single")
  })
})

# --- sen_senator_mandates ---------------------------------------------------

mandate_cols <- c(
  senator_code = "integer", mandate_code = "integer", state = "character",
  participation = "character", first_legislature = "integer",
  first_start_date = "Date", first_end_date = "Date",
  second_legislature = "integer", second_start_date = "Date",
  second_end_date = "Date", holder_code = "integer",
  holder_name = "character", substitutes = "list", terms = "list",
  parties = "list"
)

test_that("sen_senator_mandates returns one row per mandate", {
  with_api_fixtures({
    result <- sen_senator_mandates(5322)
  })

  expect_cols(result, mandate_cols)
  expect_equal(nrow(result), 2L)
  expect_equal(unique(result$senator_code), 5322L)
  expect_equal(result$first_legislature, c(57L, 55L))
  expect_true(all(is.na(result$holder_code)))

  expect_cols(result$substitutes[[1]], c(
    participation = "character", senator_code = "integer", name = "character"
  ))
  expect_equal(nrow(result$substitutes[[1]]), 2L)

  terms <- result$terms[[1]]
  expect_cols(terms, c(
    term_code = "integer", start_date = "Date", end_date = "Date",
    leave_code = "character", leave_description = "character",
    reading_date = "Date"
  ))
  # an ongoing term has no end and no cause of leave
  expect_true(is.na(terms$end_date[1]))
  expect_true(is.na(terms$leave_code[1]))
  expect_false(is.na(terms$leave_code[2]))
})

test_that("parties is a tibble whether the API sends an object or an array", {
  with_api_fixtures({
    several <- sen_senator_mandates(5322) # Partido is an array
    single <- sen_senator_mandates(825) # Partido is a lone object
  })
  party_cols <- c(
    party_code = "integer", party = "character", party_name = "character",
    affiliation_date = "Date", disaffiliation_date = "Date"
  )

  expect_cols(several$parties[[1]], party_cols)
  expect_gt(nrow(several$parties[[1]]), 1L)

  for (parties in single$parties) {
    expect_cols(parties, party_cols)
    expect_equal(nrow(parties), 1L)
    expect_equal(parties$party, "PT")
  }
})

test_that("sen_senator_mandates names the holder in a substitute's mandate", {
  with_api_fixtures({
    result <- sen_senator_mandates(6373)
  })

  expect_match(result$participation, "Suplente")
  expect_equal(result$holder_code, 5322L)
  expect_false(is.na(result$holder_name))
})

test_that("sen_senator_mandates signals not found for an unknown code", {
  with_api_fixtures({
    expect_error(sen_senator_mandates(99999999), class = "senado_error_not_found")
  })
})

# --- sen_senator_committees -------------------------------------------------

committee_cols <- c(
  senator_code = "integer", committee_code = "integer",
  committee = "character", committee_name = "character", house = "character",
  participation = "character", start_date = "Date", end_date = "Date"
)

test_that("sen_senator_committees returns one row per membership", {
  with_api_fixtures({
    result <- sen_senator_committees(5322)
  })

  expect_cols(result, committee_cols)
  expect_equal(nrow(result), 6L)
  expect_false(anyNA(result$committee_code))
  expect_true(all(result$house %in% c("SF", "CN")))
})

test_that("sen_senator_committees filters on the server", {
  with_api_fixtures({
    active <- sen_senator_committees(5322, active = TRUE)
    ccj <- sen_senator_committees(825, committee = "ccj")
  })

  expect_gt(nrow(active), 0L)
  expect_true(all(is.na(active$end_date)))
  expect_equal(unique(ccj$committee), "CCJ")

  httptest2::with_mock_api({
    expect_error(sen_senator_committees(1, active = FALSE), "ativo=N")
  })
})

test_that("a known senator without committees yields 0 rows, not an error", {
  with_api_fixtures({
    result <- sen_senator_committees(6373)
  })

  expect_cols(result, committee_cols)
  expect_equal(nrow(result), 0L)
})

test_that("sen_senator_committees signals not found and validates arguments", {
  with_api_fixtures({
    expect_error(sen_senator_committees(99999999), class = "senado_error_not_found")
  })
  httptest2::without_internet({
    expect_error(sen_senator_committees(5322, active = "S"), "TRUE")
    expect_error(sen_senator_committees(5322, committee = 34), "character")
  })
})

# --- sen_senator_speeches ---------------------------------------------------

speech_cols <- c(
  senator_code = "integer", speech_code = "integer", date = "Date",
  speech_type = "character", speech_type_description = "character",
  party = "character", state = "character", house = "character",
  summary = "character", keywords = "character", text_url = "character",
  file_url = "character", session_id = "integer", session_type = "character",
  session_number = "integer", session_date = "Date", interjections = "list",
  publications = "list"
)

test_that("sen_senator_speeches returns one row per speech", {
  with_api_fixtures({
    result <- sen_senator_speeches(825, "2024-05-01", as.Date("2024-05-31"))
  })

  expect_cols(result, speech_cols)
  expect_equal(nrow(result), 3L)
  expect_equal(unique(result$senator_code), 825L)
  expect_equal(unique(result$party), "PT")
  expect_false(is.unsorted(result$date))
  expect_false(anyNA(result$session_id))

  # `Aparteante` arrives as a lone object in speech 506264
  interjections <- result$interjections[[which(result$speech_code == 506264L)]]
  expect_cols(interjections, c(senator_code = "integer", name = "character"))
  expect_equal(nrow(interjections), 1L)

  expect_cols(result$publications[[1]], c(
    source = "character", date = "Date", first_page = "integer",
    last_page = "integer", republication = "logical", url = "character"
  ))
})

test_that("sen_senator_speeches slices a window that crosses years", {
  with_api_fixtures({
    result <- suppressMessages(
      sen_senator_speeches(825, "2023-11-01", "2024-02-29")
    )
  })

  expect_cols(result, speech_cols)
  expect_setequal(format(result$date, "%Y"), c("2023", "2024"))
  expect_equal(anyDuplicated(result$speech_code), 0L)
})

test_that("sen_year_slices never crosses a year boundary", {
  slices <- sen_year_slices(as.Date("2022-06-15"), as.Date("2024-02-10"))

  expect_equal(slices, list(
    as.Date(c("2022-06-15", "2022-12-31")),
    as.Date(c("2023-01-01", "2023-12-31")),
    as.Date(c("2024-01-01", "2024-02-10"))
  ))
  expect_equal(
    sen_year_slices(as.Date("2024-05-01"), as.Date("2024-05-31")),
    list(as.Date(c("2024-05-01", "2024-05-31")))
  )
})

test_that("sen_senator_speeches sends dates as YYYYMMDD, or none at all", {
  httptest2::with_mock_api({
    expect_error(
      sen_senator_speeches(1, "2024-05-01", "2024-05-31"),
      "dataInicio=20240501&dataFim=20240531"
    )
    err <- expect_error(sen_senator_speeches(1))
    expect_no_match(conditionMessage(err), "dataInicio", fixed = TRUE)
  })
})

test_that("a period without speeches yields 0 rows with the columns", {
  with_api_fixtures({
    result <- sen_senator_speeches(5322, "2024-01-01", "2024-01-05")
  })

  expect_cols(result, speech_cols)
  expect_equal(nrow(result), 0L)
})

test_that("sen_senator_speeches signals not found and validates arguments", {
  with_api_fixtures({
    expect_error(
      sen_senator_speeches(99999999, "2024-01-01", "2024-01-05"),
      class = "senado_error_not_found"
    )
  })
  httptest2::without_internet({
    expect_error(sen_senator_speeches(825, end_date = "2024-01-05"), "start_date")
    expect_error(sen_senator_speeches(825, "01/05/2024"), "YYYY-MM-DD")
    expect_error(sen_senator_speeches(825, "2024-05-31", "2024-05-01"), "must not be after")
  })
})

# --- Integration ------------------------------------------------------------

test_that("real API: senators", {
  skip_on_cran()
  skip_if_api_unavailable()

  current <- sen_senators()
  expect_cols(current, senator_cols)
  expect_gte(nrow(current), 78L)
  expect_lte(nrow(current), 81L)
  expect_false(anyNA(current$state))

  expect_lte(nrow(sen_senators(state = "SP")), 3L)

  code <- current$senator_code[1]
  expect_equal(sen_senator(code)$senator_code, code)
  expect_gte(nrow(sen_senator_mandates(code)), 1L)
  expect_cols(sen_senator_committees(code, active = TRUE), committee_cols)
  expect_cols(sen_senator_speeches(code), speech_cols)

  expect_error(sen_senator(99999999), class = "senado_error_not_found")
})

test_that("real API: a two-year window of speeches is not truncated", {
  skip_on_cran()
  skip_if_api_unavailable()

  result <- suppressMessages(
    sen_senator_speeches(825, "2023-01-01", "2024-12-31")
  )
  per_year <- table(format(result$date, "%Y"))
  expect_setequal(names(per_year), c("2023", "2024"))
  # measured on 2026-09-18: 168 in 2023 (lost to silent truncation without
  # slicing) and 138 in 2024
  expect_gt(per_year[["2023"]], 100L)
})
