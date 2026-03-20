# Package load/attach hooks

.onLoad <- function(libname, pkgname) {
  # Set default options if not already set
  op <- options()
  op_senado <- list(
    senado.use_cache = TRUE,
    senado.verbose = TRUE
  )
  toset <- !(names(op_senado) %in% names(op))
  if (any(toset)) options(op_senado[toset])

  invisible()
}
