# Parse utility functions
# Column specifications, record extraction and type conversion

# --- Column specification ---------------------------------------------------

#' Declare one output column
#'
#' Every exported function declares its output as a list of `sen_col()`: where
#' the value lives in each API record, what the column is called and which
#' type it has. The type of a column never depends on the content of the
#' response.
#'
#' @param name Character. Final column name (`snake_case`).
#' @param path Character vector. Path to the value inside one record.
#' @param type Character. One of `"character"`, `"integer"`, `"double"`,
#'   `"logical"`, `"date"`, `"datetime"` or `"list"`.
#' @param format Character. `strptime()` format for `"date"` and `"datetime"`.
#'   Defaults to `"%Y-%m-%d"` and `"%Y-%m-%dT%H:%M:%OS"`.
#' @param spec For `"list"` columns: the column specification of the nested
#'   records. Each cell becomes a tibble. With `NULL` the cell keeps the raw
#'   parsed node.
#' @param trim Logical. Collapse runs of whitespace and line breaks in
#'   `"character"` columns.
#'
#' @return A list describing the column.
#' @noRd
sen_col <- function(name, path,
                    type = c(
                      "character", "integer", "double", "logical",
                      "date", "datetime", "list"
                    ),
                    format = NULL, spec = NULL, trim = FALSE) {
  type <- match.arg(type)

  if (is.null(format)) {
    format <- switch(type,
      date = "%Y-%m-%d",
      datetime = "%Y-%m-%dT%H:%M:%OS",
      NULL
    )
  }

  list(
    name = name, path = path, type = type,
    format = format, spec = spec, trim = trim
  )
}

# --- Main entry point -------------------------------------------------------

#' Convert API records into a tibble, following a column specification
#'
#' Selects, renames and converts: one column per entry of `spec`, in that
#' order. Fields missing from a record become `NA` of the declared type, and
#' an empty `records` yields a 0-row tibble with all columns and types.
#'
#' @param records A list of records, as returned by `sen_records()`.
#' @param spec A list of `sen_col()`.
#' @param .unnest Character vector or `NULL`. Path, inside each record, to a
#'   nested list that should yield one row per element (parent fields are
#'   repeated). Paths in `spec` that go through the nested list then address
#'   one element of it. A parent without elements keeps one row, with the
#'   nested fields as `NA`.
#'
#' @return A [tibble::tibble].
#' @noRd
sen_as_tibble <- function(records, spec, .unnest = NULL) {
  if (!is.null(.unnest)) {
    records <- sen_unnest_records(records, .unnest)
  }

  cols <- lapply(spec, function(col) sen_extract_col(records, col))
  names(cols) <- vapply(spec, function(col) col$name, character(1))

  ensure_utf8(tibble::new_tibble(cols, nrow = length(records)))
}

# --- Records ----------------------------------------------------------------

#' Safely walk a path inside a parsed response
#'
#' @param x A list.
#' @param path Character vector of names.
#' @return The node, or `NULL` if any step is missing.
#' @noRd
sen_pluck <- function(x, path) {
  for (step in path) {
    if (!is.list(x) || is.null(names(x))) {
      return(NULL)
    }
    x <- x[[step]]
    if (is.null(x)) {
      return(NULL)
    }
  }
  x
}

#' Normalise a repeatable node into a list of records
#'
#' The legacy services return the lone object, instead of a one-element array,
#' when a repeatable node has a single element. A missing or `null` node means
#' no records.
#'
#' @param node A parsed node.
#' @return An unnamed list of records (possibly empty).
#' @noRd
sen_as_records <- function(node) {
  if (is.null(node) || length(node) == 0L) {
    return(list())
  }
  if (!is.list(node)) {
    return(list(node))
  }
  if (!is.null(names(node))) {
    return(list(node))
  }
  node
}

#' Records found at a path of a parsed response
#'
#' @param x A parsed response.
#' @param path Character vector. Path to the records; `NULL` or empty when the
#'   records are the top-level array (v4 services).
#' @return An unnamed list of records (possibly empty).
#' @noRd
sen_records <- function(x, path = NULL) {
  if (length(path) == 0L) {
    return(sen_as_records(x))
  }
  sen_as_records(sen_pluck(x, path))
}

#' One record per element of a nested list
#' @noRd
sen_unnest_records <- function(records, path) {
  out <- list()

  for (record in records) {
    children <- sen_records(record, path)

    if (length(children) == 0L) {
      if (!is.null(sen_pluck(record, path))) {
        record[[path]] <- NULL
      }
      out[[length(out) + 1L]] <- record
      next
    }

    for (child in children) {
      row <- record
      row[[path]] <- child
      out[[length(out) + 1L]] <- row
    }
  }

  out
}

# --- Column extraction ------------------------------------------------------

#' Extract and convert one column from a list of records
#' @noRd
sen_extract_col <- function(records, col) {
  nodes <- lapply(records, sen_pluck, path = col$path)

  if (col$type == "list") {
    if (is.null(col$spec)) {
      return(nodes)
    }
    return(lapply(nodes, function(node) {
      sen_as_tibble(sen_as_records(node), col$spec)
    }))
  }

  # Scalars go through character so that the source type is irrelevant.
  # The literal string "NA" is a value (it is a vote code), never missing.
  values <- vapply(nodes, function(node) {
    if (is.null(node) || length(node) == 0L || is.list(node)) {
      return(NA_character_)
    }
    as.character(node[[1L]])
  }, character(1))

  switch(col$type,
    character = if (col$trim) squish(values) else values,
    integer = parse_integer(values, col$name),
    double = parse_double(values, col$name),
    logical = parse_logical(values),
    date = as.Date(values, format = col$format),
    datetime = as.POSIXct(values, format = col$format, tz = "America/Sao_Paulo")
  )
}

# --- Type parsers (called by the specification, column by column) -----------

#' Parse text into integer, warning when a value is not a whole number
#' @noRd
parse_integer <- function(x, name = "x") {
  out <- suppressWarnings(as.integer(x))
  warn_if_lost(x, out, name, "integer")
  out
}

#' Parse text into double (accepts comma as decimal separator)
#' @noRd
parse_double <- function(x, name = "x") {
  out <- suppressWarnings(as.numeric(gsub(",", ".", x, fixed = TRUE)))
  warn_if_lost(x, out, name, "double")
  out
}

#' @noRd
warn_if_lost <- function(x, out, name, type) {
  lost <- !is.na(x) & is.na(out)
  if (any(lost)) {
    cli::cli_warn(c(
      "Column {.field {name}}: {sum(lost)} value{?s} could not be read as {type} and became {.val {NA}}.",
      "i" = "First one: {.val {x[lost][1]}}. The API may have changed; please report it."
    ))
  }
}

#' Parse the three boolean encodings of the API into logical
#'
#' The API uses "Sim"/"Não", "S"/"N" and "true"/"false". Anything else is `NA`.
#' @noRd
parse_logical <- function(x) {
  x <- tolower(x)
  out <- rep(NA, length(x))
  out[x %in% c("sim", "s", "true")] <- TRUE
  out[x %in% c("n\u00e3o", "nao", "n", "false")] <- FALSE
  out
}

#' Collapse whitespace and line breaks
#' @noRd
squish <- function(x) {
  trimws(gsub("[[:space:]]+", " ", x))
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
