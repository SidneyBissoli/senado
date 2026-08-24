# Package load/attach hooks

.onLoad <- function(libname, pkgname) {
  # Set default options if not already set by the user

  op <- options()
  op_senado <- list(
    senado.use_cache = TRUE,
    senado.verbose = TRUE
  )
  toset <- !(names(op_senado) %in% names(op))
  if (any(toset)) options(op_senado[toset])

  # Honour SENADO_CACHE_ENABLED env var (overrides option)
  cache_env <- Sys.getenv("SENADO_CACHE_ENABLED", unset = "")
  if (nzchar(cache_env)) {
    options(senado.use_cache = tolower(cache_env) %in% c("true", "1", "yes"))
  }

  # Initialise in-memory cache stores
  sen_cache_init()

  invisible()
}

.onAttach <- function(libname, pkgname) {
  version <- as.character(utils::packageVersion(pkgname))
  packageStartupMessage(
    "senado ", version, " - Access data from the Brazilian Federal Senate\n",
    "Docs: https://github.com/SidneyBissoli/senado"
  )
}
