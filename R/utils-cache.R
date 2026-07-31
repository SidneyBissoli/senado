# Cache utility functions
# In-memory cache system with configurable TTL per data category

# --- Internal cache store (package-level environment) ----------------------

#' Package-level cache environment
#' @noRd
sen_cache_env <- new.env(parent = emptyenv())

#' Initialise the cache store
#'
#' Called once on package load. Creates three `cachem::cache_mem()` stores with
#' different TTLs:
#'
#' * **reference** — parties, states, bill types (24 h)
#' * **semi_static** — senator lists per legislature (6 h)
#' * **dynamic** — recent votes, agenda (15 min)
#'
#' @noRd
sen_cache_init <- function() {
  sen_cache_env$reference <- cachem::cache_mem(
    max_age = 60 * 60 * 24   # 24 hours
  )
  sen_cache_env$semi_static <- cachem::cache_mem(
    max_age = 60 * 60 * 6    # 6 hours
  )
  sen_cache_env$dynamic <- cachem::cache_mem(
    max_age = 60 * 15        # 15 minutes
  )
}

# --- Cache category helper -------------------------------------------------

#' Resolve a cache category to its store
#'
#' @param category Character. One of `"reference"`, `"semi_static"`, or
#'   `"dynamic"`.
#' @return A `cachem::cache_mem` object.
#' @noRd
sen_cache_store <- function(category = c("dynamic", "semi_static", "reference")) {
  category <- match.arg(category)


  # Lazily initialise if stores do not exist yet
  if (is.null(sen_cache_env$reference)) {
    sen_cache_init()
  }

  sen_cache_env[[category]]
}

# --- Public-facing helpers (used by sen_get) --------------------------------

#' Retrieve a value from the cache
#'
#' @param key Character. Cache key (typically the full request URL).
#' @param category Character. Cache category — controls the TTL.
#' @return The cached value, or `NULL` (via `cachem`'s `key_missing()`
#'   sentinel) if not found.
#' @noRd
sen_cache_get <- function(key, category = "dynamic") {
  if (!isTRUE(getOption("senado.use_cache", TRUE))) {
    return(NULL)
  }

  store <- sen_cache_store(category)
  value <- store$get(key)

  if (cachem::is.key_missing(value)) {
    return(NULL)
  }
  value
}

#' Store a value in the cache
#'
#' @param key Character. Cache key.
#' @param value The value to cache.
#' @param category Character. Cache category.
#' @noRd
sen_cache_set <- function(key, value, category = "dynamic") {
  if (!isTRUE(getOption("senado.use_cache", TRUE))) {
    return(invisible(value))
  }

  store <- sen_cache_store(category)
  store$set(key, value)
  invisible(value)
}

# --- User-facing function ---------------------------------------------------

#' Clear the senado package cache
#'
#' Removes all cached API responses. Optionally targets a single cache
#' category.
#'
#' @param category Character or `NULL`. One of `"reference"`,
#'   `"semi_static"`, `"dynamic"`, or `NULL` (default) to clear all
#'   categories.
#'
#' @return Invisibly returns `NULL`.
#'
#' @examples
#' \dontrun{
#' # Clear everything
#' sen_cache_clear()
#'
#' # Clear only the dynamic cache (recent votes, agenda)
#' sen_cache_clear("dynamic")
#' }
#'
#' @export
sen_cache_clear <- function(category = NULL) {
  categories <- if (is.null(category)) {
    c("reference", "semi_static", "dynamic")
  } else {
    match.arg(category, c("reference", "semi_static", "dynamic"))
  }

  for (cat in categories) {
    store <- sen_cache_store(cat)
    store$reset()
  }

  cli::cli_alert_success("Cache cleared{if (!is.null(category)) paste0(' (', category, ')') else ''}.")
  invisible(NULL)
}
