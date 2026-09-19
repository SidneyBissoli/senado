# API utility functions
# Core infrastructure for accessing the Senado Federal Open Data API

#' Base URL for the Senado Federal Open Data API
#' @noRd
sen_base_url <- function() {
  Sys.getenv("SENADO_API_BASE_URL", "https://legis.senado.leg.br/dadosabertos")
}

#' Build user-agent string for the package
#' @noRd
sen_user_agent <- function() {
  version <- as.character(utils::packageVersion("senado"))
  paste0("senado/", version, " (https://github.com/SidneyBissoli/senado)")
}

#' Make a GET request to the Senado Federal Open Data API
#'
#' Central function for all API access. Handles URL construction, headers,
#' retry with exponential backoff, throttle, timeout, caching and error
#' handling.
#'
#' HTTP errors are never swallowed: they are re-signalled as classed
#' conditions (`senado_error_not_found`, `senado_error_bad_request`,
#' `senado_error_unavailable`, all inheriting from `senado_error`) carrying the
#' message sent by the API. The other format (JSON <-> XML) is tried only when
#' the response cannot be parsed or the API answers 406 -- never on 4xx, 5xx
#' or timeout.
#'
#' @param path Character. API endpoint path (e.g., `"senador/lista/atual"`).
#' @param query Named list. Query parameters to append to the URL. `NULL`
#'   elements are dropped. Default `NULL`.
#' @param format Character. Response format: `"json"` (default) or `"xml"`.
#' @param cache_category Character. Cache TTL tier: `"reference"` (24 h),
#'   `"semi_static"` (6 h), or `"dynamic"` (15 min, default). See
#'   [sen_cache_clear()] for details.
#' @param call The calling environment for error context.
#'
#' @return A parsed R list from the API response. JSON is parsed without
#'   simplification: arrays are unnamed lists, objects are named lists.
#'
#' @noRd
sen_get <- function(path, query = NULL, format = c("json", "xml"),
                    cache_category = "dynamic", call = rlang::caller_env()) {
  format <- match.arg(format)
  query <- query[!vapply(query, is.null, logical(1))]

  cache_key <- sen_cache_key(path, query, format)
  cached <- sen_cache_get(cache_key, category = cache_category)
  if (!is.null(cached)) {
    return(cached)
  }

  result <- tryCatch(
    sen_request(path, query = query, format = format, call = call),
    senado_error_format = function(e) {
      other <- setdiff(c("json", "xml"), format)
      sen_request(path, query = query, format = other, call = call)
    }
  )

  sen_cache_set(cache_key, result, category = cache_category)

  result
}

#' Execute a single API request with retry and throttle
#'
#' @param path Character. API endpoint path.
#' @param query Named list. Query parameters.
#' @param format Character. `"json"` or `"xml"`.
#' @param call The calling environment for error context.
#'
#' @return A parsed R list. Failures are signalled as `senado_error`
#'   conditions.
#' @noRd
sen_request <- function(path, query = NULL, format = "json",
                        call = rlang::caller_env()) {
  url <- paste0(sen_base_url(), "/", path)

  if (format == "json") {
    accept_header <- "application/json"
  } else {
    accept_header <- "application/xml"
  }

  req <- httr2::request(url) |>
    httr2::req_headers(
      `User-Agent` = sen_user_agent(),
      Accept = accept_header
    ) |>
    httr2::req_url_query(!!!query) |>
    httr2::req_retry(
      max_tries = getOption("senado.max_tries", 3L),
      is_transient = sen_is_transient,
      backoff = ~ 2^.x
    ) |>
    httr2::req_throttle(rate = 2 / 1) |>
    httr2::req_timeout(getOption("senado.timeout", 120)) |>
    httr2::req_error(body = sen_error_body)

  resp <- tryCatch(
    httr2::req_perform(req),
    httr2_http = function(e) sen_abort_http(e, url = url, call = call),
    httr2_failure = function(e) {
      cli::cli_abort(
        c(
          "Could not reach the Senado API.",
          "i" = "Endpoint: {.url {url}}"
        ),
        class = c("senado_error_unavailable", "senado_error"),
        parent = e,
        call = call
      )
    }
  )

  sen_parse_response(resp, format = format, call = call)
}

#' Statuses worth retrying (ADR-010)
#' @noRd
sen_is_transient <- function(resp) {
  httr2::resp_status(resp) %in% c(429L, 500L, 502L, 503L, 504L)
}

#' Extract the error message sent by the API
#'
#' The v4 services answer errors with `application/problem+json`, whose
#' `detail` field explains what was wrong with the request.
#'
#' @param resp An `httr2_response` object.
#' @return A character string, or `NULL` when the body has no message.
#' @noRd
sen_error_body <- function(resp) {
  if (!grepl("json", httr2::resp_content_type(resp), fixed = TRUE)) {
    return(NULL)
  }
  body <- tryCatch(
    httr2::resp_body_json(resp, check_type = FALSE),
    error = function(e) NULL
  )
  if (is.character(body$detail)) {
    return(body$detail)
  }
  if (is.character(body$title)) {
    return(body$title)
  }
  NULL
}

#' Re-signal an HTTP error as a classed senado condition
#' @noRd
sen_abort_http <- function(e, url, call = rlang::caller_env()) {
  status <- e$status

  if (status == 404L) {
    class <- "senado_error_not_found"
    msg <- "The Senado API found nothing at this address (HTTP 404)."
  } else if (status == 400L) {
    class <- "senado_error_bad_request"
    msg <- "The Senado API rejected the request (HTTP 400)."
  } else if (status == 406L) {
    class <- "senado_error_format"
    msg <- "The Senado API cannot answer in the requested format (HTTP 406)."
  } else if (status == 429L || status >= 500L) {
    class <- "senado_error_unavailable"
    msg <- "The Senado API is unavailable (HTTP {status})."
  } else {
    class <- "senado_error_http"
    msg <- "The Senado API answered with an error (HTTP {status})."
  }

  cli::cli_abort(
    c(msg, "i" = "Endpoint: {.url {url}}"),
    class = c(class, "senado_error"),
    parent = e,
    call = call
  )
}

#' Parse an API response
#'
#' JSON is parsed with `simplifyVector = FALSE`. The legacy services return a
#' lone object instead of a one-element array when a repeatable node has a
#' single element, so automatic simplification would hand back a `data.frame`
#' in one call and a `list` in the next. See `sen_records()`.
#'
#' @param resp An `httr2_response` object.
#' @param format Character. Expected format (`"json"` or `"xml"`).
#' @param call The calling environment for error context.
#'
#' @return A parsed R list. A body that cannot be parsed signals
#'   `senado_error_format`.
#' @noRd
sen_parse_response <- function(resp, format = "json",
                               call = rlang::caller_env()) {
  content_type <- httr2::resp_content_type(resp)
  body <- httr2::resp_body_string(resp)

  tryCatch(
    {
      if (grepl("json", content_type, fixed = TRUE) || format == "json") {
        jsonlite::fromJSON(body, simplifyVector = FALSE)
      } else {
        xml2::as_list(xml2::read_xml(body))
      }
    },
    error = function(e) {
      cli::cli_abort(
        "Failed to parse the {format} response from the Senado API.",
        class = c("senado_error_format", "senado_error"),
        parent = e,
        call = call
      )
    }
  )
}

#' Build a deterministic cache key from request parameters
#'
#' @param path Character. API endpoint path.
#' @param query Named list or `NULL`. Query parameters.
#' @param format Character. `"json"` or `"xml"`.
#'
#' @return A character string suitable as a cache key.
#' @noRd
sen_cache_key <- function(path, query = NULL, format = "json") {
  # Build a human-readable representation, then hash it.
  # cachem keys must contain only lowercase letters and numbers;
  # rlang::hash() returns a 32-char hex string that satisfies this.
  parts <- paste0(format, ":", path)
  if (!is.null(query) && length(query) > 0) {
    query <- query[order(names(query))]
    params <- paste(names(query), query, sep = "=", collapse = "&")
    parts <- paste0(parts, "?", params)
  }
  rlang::hash(parts)
}

#' Is the Senado API reachable right now?
#'
#' Condition used by `@examplesIf` in every function that calls the API, and
#' by the integration tests. It is `FALSE` on CRAN (`NOT_CRAN` unset), when
#' offline, and when the API does not answer within 5 seconds.
#'
#' @return `TRUE` or `FALSE`.
#' @keywords internal
#' @noRd
sen_api_available <- function() {
  if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
    return(FALSE)
  }
  if (!httr2::is_online()) {
    return(FALSE)
  }
  tryCatch(
    {
      resp <- httr2::request(sen_base_url()) |>
        httr2::req_timeout(5) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()
      httr2::resp_status(resp) < 400L
    },
    error = function(e) FALSE
  )
}
