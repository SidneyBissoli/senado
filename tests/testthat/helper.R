# Test helpers for senado package

skip_if_offline <- function() {
  testthat::skip_if_offline()
}

skip_if_api_unavailable <- function() {
  skip_if_offline()
  tryCatch(
    {
      resp <- httr2::request("https://legis.senado.leg.br/dadosabertos") |>
        httr2::req_timeout(5) |>
        httr2::req_perform()
      if (httr2::resp_status(resp) >= 400) {
        testthat::skip("Senado API is unavailable")
      }
    },
    error = function(e) {
      testthat::skip("Senado API is unavailable")
    }
  )
}
