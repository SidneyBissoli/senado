# tests/testthat/test-api-spec.R
#
# Design principle 7: no function relies on an endpoint the API marks as
# deprecated. This is the alarm against what killed `congressbr`.
# Every endpoint used by the package is listed here, as written in the
# OpenAPI spec. Add to the list when a function starts using a new one.

endpoints_used <- c(
  # Module 3.1 - reference data
  "/dadosabertos/plenario/lista/legislaturas",
  "/dadosabertos/plenario/legislatura/{data}",
  "/dadosabertos/senador/partidos",
  "/dadosabertos/processo/siglas",
  "/dadosabertos/processo/tipos-situacao",
  # Module 3.2 - senators
  "/dadosabertos/senador/lista/atual",
  "/dadosabertos/senador/lista/legislatura/{legislatura}",
  "/dadosabertos/senador/lista/legislatura/{legislaturaInicio}/{legislaturaFim}",
  "/dadosabertos/senador/{codigo}",
  "/dadosabertos/senador/{codigo}/mandatos",
  "/dadosabertos/senador/{codigo}/comissoes",
  "/dadosabertos/senador/{codigo}/discursos"
)

test_that("every endpoint used by the package is active in the OpenAPI spec", {
  skip_on_cran()
  skip_if_api_unavailable()

  spec <- sen_get("v3/api-docs", cache_category = "reference")
  paths <- spec$paths

  missing <- setdiff(endpoints_used, names(paths))
  expect_equal(missing, character())

  deprecated <- Filter(
    function(endpoint) isTRUE(paths[[endpoint]]$get$deprecated),
    intersect(endpoints_used, names(paths))
  )
  expect_equal(deprecated, character())
})
