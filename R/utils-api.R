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
#' retry with exponential backoff, throttle, timeout, error handling, and
#' automatic JSON/XML fallback.
#'
#' @param path Character. API endpoint path (e.g., `"senador/lista/atual"`).
#' @param query Named list. Query parameters to append to the URL.
#'   Default `NULL`.
#' @param format Character. Preferred response format: `"json"` (default) or
#'   `"xml"`. If JSON fails, XML is attempted automatically.
#' @param cache_category Character. Cache TTL tier: `"reference"` (24 h),
#'   `"semi_static"` (6 h), or `"dynamic"` (15 min, default). See
#'   [sen_cache_clear()] for details.
#'
#' @return A parsed R list from the API response.
#'
#' @examples
#' \dontrun{
#' # List current senators
#' result <- sen_get("senador/lista/atual")
#'
#' # With query parameters
#' result <- sen_get("senador/lista/legislatura", query = list(legislatura = 57))
#' }
#'
#' @noRd
sen_get <- function(path, query = NULL, format = c("json", "xml"),
                    cache_category = "dynamic") {
  format <- match.arg(format)

  # Build a cache key from the full URL + query
  cache_key <- sen_cache_key(path, query, format)
  cached <- sen_cache_get(cache_key, category = cache_category)
  if (!is.null(cached)) {
    return(cached)
  }

  # Try preferred format first; fallback to the other
  result <- sen_request(path, query = query, format = format)

  if (is.null(result) && format == "json") {
    cli::cli_alert_info("JSON request failed. Falling back to XML.")
    result <- sen_request(path, query = query, format = "xml")
  } else if (is.null(result) && format == "xml") {
    cli::cli_alert_info("XML request failed. Falling back to JSON.")
    result <- sen_request(path, query = query, format = "json")
  }

  if (is.null(result)) {
    cli::cli_abort(c(
      "Failed to retrieve data from the Senado API.",
      "i" = "Endpoint: {.url {sen_base_url()}/{path}}",
      "i" = "Both JSON and XML formats failed after retries."
    ))
  }

  # Store in cache before returning
  sen_cache_set(cache_key, result, category = cache_category)

  result
}

#' Execute a single API request with retry and throttle
#'
#' @param path Character. API endpoint path.
#' @param query Named list. Query parameters.
#' @param format Character. `"json"` or `"xml"`.
#'
#' @return A parsed R list on success, or `NULL` on failure.
#' @noRd
sen_request <- function(path, query = NULL, format = "json") {
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
      max_tries = 3,
      backoff = ~ 2^.x
    ) |>
    httr2::req_throttle(rate = 2 / 1) |>
    httr2::req_timeout(30)

  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      cli::cli_alert_warning(
        "Request to {.url {url}} failed: {conditionMessage(e)}"
      )
      NULL
    }
  )

  if (is.null(resp)) {
    return(NULL)
  }

  sen_parse_response(resp, format = format)
}

#' Parse an API response based on content type
#'
#' @param resp An `httr2_response` object.
#' @param format Character. Expected format (`"json"` or `"xml"`).
#'
#' @return A parsed R list, or `NULL` on parse failure.
#' @noRd
sen_parse_response <- function(resp, format = "json") {
  content_type <- httr2::resp_content_type(resp)

  tryCatch(
    {
      if (grepl("json", content_type, fixed = TRUE) || format == "json") {
        body <- httr2::resp_body_string(resp)
        jsonlite::fromJSON(body, simplifyVector = TRUE, flatten = TRUE)
      } else {
        body <- httr2::resp_body_string(resp)
        xml_doc <- xml2::read_xml(body)
        xml2::as_list(xml_doc)
      }
    },
    error = function(e) {
      cli::cli_alert_warning("Failed to parse {format} response: {conditionMessage(e)}")
      NULL
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
