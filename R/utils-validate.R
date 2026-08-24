# Validation utility functions
# Input validation with friendly error messages via cli::cli_abort()

# --- Year -------------------------------------------------------------------

#' Validate a year value
#'
#' Must be an integer (or coercible), >= 1991 (year the Senado API data begins),
#' and <= current year.
#'
#' @param year A single numeric or integer value.
#' @param arg Character. Argument name for error messages.
#' @param call The calling environment for error context.
#' @return The year as an integer, invisibly.
#' @noRd
validate_year <- function(year, arg = "year", call = rlang::caller_env()) {
  validate_scalar_integer(year, arg = arg, call = call)

  year <- as.integer(year)
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  if (year < 1991L) {
    cli::cli_abort(
      "{.arg {arg}} must be >= 1991 (start of available data), not {year}.",
      call = call
    )
  }
  if (year > current_year) {
    cli::cli_abort(
      "{.arg {arg}} must be <= {current_year} (current year), not {year}.",
      call = call
    )
  }

  invisible(year)
}

# --- Senator code -----------------------------------------------------------

#' Validate a senator code
#'
#' Must be a positive integer.
#'
#' @param code A single numeric or integer value.
#' @param arg Character. Argument name for error messages.
#' @param call The calling environment for error context.
#' @return The code as an integer, invisibly.
#' @noRd
validate_senator_code <- function(code, arg = "code", call = rlang::caller_env()) {
  validate_positive_integer(code, arg = arg, call = call)
}

# --- Bill code --------------------------------------------------------------

#' Validate a bill (materia) code
#'
#' Must be a positive integer.
#'
#' @param code A single numeric or integer value.
#' @param arg Character. Argument name for error messages.
#' @param call The calling environment for error context.
#' @return The code as an integer, invisibly.
#' @noRd
validate_bill_code <- function(code, arg = "code", call = rlang::caller_env()) {
  validate_positive_integer(code, arg = arg, call = call)
}

# --- Party ------------------------------------------------------------------

#' Validate a party abbreviation
#'
#' Must be a single character string in uppercase.
#'
#' @param party A single character string (e.g., `"PL"`, `"PT"`).
#' @param arg Character. Argument name for error messages.
#' @param call The calling environment for error context.
#' @return The party abbreviation (uppercased), invisibly.
#' @noRd
validate_party <- function(party, arg = "party", call = rlang::caller_env()) {
  if (!rlang::is_string(party)) {
    cli::cli_abort(
      "{.arg {arg}} must be a single character string, not {.cls {class(party)}}.",
      call = call
    )
  }

  party <- toupper(trimws(party))

  if (!grepl("^[A-Z]+$", party)) {
    cli::cli_abort(
      "{.arg {arg}} must contain only letters, not {.val {party}}.",
      call = call
    )
  }

  invisible(party)
}

# --- UF (state) -------------------------------------------------------------

#' Valid Brazilian state codes (UFs)
#' @noRd
valid_ufs <- c(
  "AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", "MA",
  "MG", "MS", "MT", "PA", "PB", "PE", "PI", "PR", "RJ", "RN",
  "RO", "RR", "RS", "SC", "SE", "SP", "TO"
)

#' Validate a Brazilian state abbreviation (UF)
#'
#' Must be a 2-letter code matching one of the 27 valid UFs.
#'
#' @param uf A single character string (e.g., `"SP"`, `"RJ"`).
#' @param arg Character. Argument name for error messages.
#' @param call The calling environment for error context.
#' @return The UF (uppercased), invisibly.
#' @noRd
validate_uf <- function(uf, arg = "state", call = rlang::caller_env()) {
  if (!rlang::is_string(uf)) {
    cli::cli_abort(
      "{.arg {arg}} must be a single character string, not {.cls {class(uf)}}.",
      call = call
    )
  }

  uf <- toupper(trimws(uf))

  if (!uf %in% valid_ufs) {
    cli::cli_abort(c(
      "{.val {uf}} is not a valid Brazilian state abbreviation.",
      "i" = "Valid values: {.val {valid_ufs}}."
    ), call = call)
  }

  invisible(uf)
}

# --- Generic helpers --------------------------------------------------------

#' Validate that a value is a single integer (or coercible to one)
#' @noRd
validate_scalar_integer <- function(x, arg = "x", call = rlang::caller_env()) {
  if (length(x) != 1L || is.na(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a single non-NA value, not {.obj_type_friendly {x}}.",
      call = call
    )
  }

  if (!is.numeric(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be numeric, not {.cls {class(x)}}.",
      call = call
    )
  }

  if (x != as.integer(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a whole number, not {.val {x}}.",
      call = call
    )
  }

  invisible(as.integer(x))
}

#' Validate that a value is a positive integer
#' @noRd
validate_positive_integer <- function(x, arg = "x", call = rlang::caller_env()) {
  validate_scalar_integer(x, arg = arg, call = call)

  if (as.integer(x) < 1L) {
    cli::cli_abort(
      "{.arg {arg}} must be a positive integer, not {.val {x}}.",
      call = call
    )
  }

  invisible(as.integer(x))
}
