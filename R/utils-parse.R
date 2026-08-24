# Parse utility functions
# XML/JSON parsers, column normalization, type conversion

# --- Main entry point -------------------------------------------------------

#' Convert a parsed API response (list) into a tidy tibble
#'
#' Flattens nested structures, normalises column names to `snake_case`,
#' converts types (dates, numerics, logicals) and ensures UTF-8 encoding.
#'
#' @param data A list (or data.frame) returned by [sen_get()].
#' @param .unnest Character vector of column names to unnest one level, or
#'   `NULL` (default) to skip.
#'
#' @return A [tibble::tibble].
#' @noRd
sen_as_tibble <- function(data, .unnest = NULL) {
  if (is.data.frame(data)) {
    tbl <- tibble::as_tibble(data)
  } else if (is.list(data)) {
    tbl <- tibble::as_tibble(flatten_list(data))
  } else {
    cli::cli_abort("Cannot coerce object of class {.cls {class(data)}} to tibble.")
  }

  names(tbl) <- to_snake_case(names(tbl))
  tbl <- convert_types(tbl)
  tbl <- ensure_utf8(tbl)
  tbl
}

# --- Flatten ----------------------------------------------------------------

#' Flatten a nested list into a single-depth named list
#'
#' Recursively concatenates names with `"_"` as separator.
#' Vectors of length > 1 are kept as-is (they become list-columns later).
#'
#' @param x A list.
#' @param prefix Character prefix for recursive calls.
#' @return A flat named list.
#' @noRd
flatten_list <- function(x, prefix = "") {

  out <- list()

  for (nm in names(x)) {
    key <- if (nzchar(prefix)) paste0(prefix, "_", nm) else nm
    val <- x[[nm]]

    if (is.list(val) && !is.data.frame(val) && length(val) > 0 &&
        !is.null(names(val))) {
      out <- c(out, flatten_list(val, prefix = key))
    } else {
      out[[key]] <- val
    }
  }

  out
}

# --- snake_case conversion --------------------------------------------------

#' Convert a character vector to snake_case
#'
#' Handles PascalCase, camelCase and mixed separators (`.`, `-`, ` `) commonly
#' found in the Senado API responses.
#'
#' @param x Character vector.
#' @return Character vector in `snake_case`.
#' @noRd
to_snake_case <- function(x) {
  # Insert underscore before uppercase letters preceded by a lowercase letter
  # or digit (camelCase / PascalCase boundaries)
  out <- gsub("([a-z0-9])([A-Z])", "\\1_\\2", x)
  # Insert underscore between consecutive uppercase + lowercase (e.g., "XMLParser" → "XML_Parser")
  out <- gsub("([A-Z]+)([A-Z][a-z])", "\\1_\\2", out)
  # Replace common separators with underscore
  out <- gsub("[. -]+", "_", out)
  # Collapse multiple underscores
  out <- gsub("_+", "_", out)
  # Strip leading/trailing underscores
  out <- gsub("^_|_$", "", out)
  tolower(out)
}

# --- Type conversion --------------------------------------------------------

#' Auto-convert column types in a tibble
#'
#' * Character columns that look numeric → `numeric`
#' * Character columns with "Sim"/"Não" → `logical`
#' * Character columns matching common date patterns → `Date` or `POSIXct`
#'
#' @param tbl A tibble.
#' @return The tibble with converted columns.
#' @noRd
convert_types <- function(tbl) {
  for (col in names(tbl)) {
    vals <- tbl[[col]]
    if (!is.character(vals)) next

    # Skip columns that are entirely NA
    non_na <- vals[!is.na(vals)]
    if (length(non_na) == 0L) next

    # Try logical (Sim/Não)
    if (is_logical_field(non_na)) {
      tbl[[col]] <- parse_logical(vals)
      next
    }

    # Try date / datetime
    parsed_date <- try_parse_date(non_na)
    if (!is.null(parsed_date)) {
      tbl[[col]] <- try_parse_date(vals)
      next
    }

    # Try numeric
    if (is_numeric_field(non_na)) {
      tbl[[col]] <- parse_numeric(vals)
      next
    }
  }

  tbl
}

# --- Logical helpers --------------------------------------------------------

#' Check if a character vector represents a logical field
#' @noRd
is_logical_field <- function(x) {
  all(tolower(x) %in% c("sim", "n\u00e3o", "s", "n", "true", "false"))
}

#' Parse a character vector of Sim/Não into logical
#' @noRd
parse_logical <- function(x) {
  ifelse(is.na(x), NA,
    tolower(x) %in% c("sim", "s", "true")
  )
}

# --- Numeric helpers --------------------------------------------------------

#' Check if a character vector looks like numbers
#' @noRd
is_numeric_field <- function(x) {
  # Allow digits, optional decimal point/comma, optional leading minus
  all(grepl("^-?[0-9]+([.,][0-9]+)?$", x))
}

#' Parse a character vector to numeric (handles comma as decimal separator)
#' @noRd
parse_numeric <- function(x) {
  as.numeric(gsub(",", ".", x))
}

# --- Date helpers -----------------------------------------------------------

#' Common date/datetime formats found in the Senado API
#' @noRd
sen_date_formats <- c(
  # datetime formats
  "%Y-%m-%dT%H:%M:%S",
  "%Y-%m-%d %H:%M:%S",
  "%d/%m/%Y %H:%M:%S",
  # date-only formats
  "%Y-%m-%d",
  "%d/%m/%Y"
)

#' Try to parse a character vector as Date or POSIXct
#'
#' Tests each format in [sen_date_formats] against the non-NA values.
#' Returns a `POSIXct` if the matching format includes a time component,
#' otherwise a `Date`. Returns `NULL` if no format matches.
#'
#' @param x Character vector.
#' @return `Date`, `POSIXct`, or `NULL`.
#' @noRd
try_parse_date <- function(x) {
  non_na <- x[!is.na(x)]
  if (length(non_na) == 0L) return(NULL)

  for (fmt in sen_date_formats) {
    parsed <- as.POSIXct(non_na, format = fmt, tz = "America/Sao_Paulo")
    if (!any(is.na(parsed))) {
      # Apply to full vector (preserving NAs)
      full_parsed <- as.POSIXct(x, format = fmt, tz = "America/Sao_Paulo")
      # If format has no time component, return Date
      if (!grepl("%H", fmt, fixed = TRUE)) {
        return(as.Date(full_parsed))
      }
      return(full_parsed)
    }
  }

  NULL
}

# --- Encoding ---------------------------------------------------------------

#' Ensure all character columns are UTF-8 encoded
#' @noRd
ensure_utf8 <- function(tbl) {
  for (col in names(tbl)) {
    if (is.character(tbl[[col]])) {
      Encoding(tbl[[col]]) <- "UTF-8"
    }
  }
  tbl
}
