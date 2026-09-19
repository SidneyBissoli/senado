# Record the httptest2 fixtures used by the mocked tests.
#
# Run from the package root, with the API reachable:
#   Rscript data-raw/record-fixtures.R
#
# Responses are recorded through the package functions, so the mock paths
# match what the tests request. Long lists are then trimmed: the tests need
# the shape of the records, not all of them, and the package tarball must
# stay small. Every test that counts rows counts the trimmed fixture.

pkgload::load_all(".", quiet = TRUE)
library(httptest2)

fixture_dir <- "tests/testthat/api"
source("tests/testthat/helper.R") # redactor: drops the base URL from the paths
options(senado.use_cache = FALSE)

unlink(fixture_dir, recursive = TRUE)

dir.create(fixture_dir, showWarnings = FALSE, recursive = TRUE)
.mockPaths(fixture_dir)

capture_requests({
  # Module 3.1
  sen_legislatures()
  sen_current_legislature(as.Date("2026-09-19"))
  sen_current_legislature(as.Date("1800-01-01")) |> try(silent = TRUE)
  sen_parties()
  sen_bill_types()
  sen_bill_statuses()

  # Module 3.2
  sen_senators()
  sen_senators(state = "SP")
  sen_senators(status = "substitute")
  sen_senators(57)
  sen_senators(57, in_office = TRUE)
  sen_senators(c(55, 57))
  sen_senators(999)

  sen_senator(5322)
  sen_senator(99999999) |> try(silent = TRUE)

  sen_senator_mandates(5322) # Partidos.Partido as array
  sen_senator_mandates(825) # Partidos.Partido as lone object
  sen_senator_mandates(6373) # substitute: has Titular
  sen_senator_mandates(99999999) |> try(silent = TRUE)

  sen_senator_committees(5322)
  sen_senator_committees(5322, active = TRUE)
  sen_senator_committees(825, committee = "CCJ")
  sen_senator_committees(6373) # known senator, no committee
  sen_senator_committees(99999999) |> try(silent = TRUE)

  sen_senator_speeches(825, "2024-05-01", "2024-05-31")
  sen_senator_speeches(825, "2023-11-01", "2024-02-29") # two yearly slices
  sen_senator_speeches(5322, "2024-01-01", "2024-01-05") # none
  sen_senator_speeches(99999999, "2024-01-01", "2024-01-05") |> try(silent = TRUE)
  invisible()
})

# --- Trim -------------------------------------------------------------------

trim <- function(file, path, keep) {
  file <- file.path(fixture_dir, file)
  x <- jsonlite::fromJSON(file, simplifyVector = FALSE)
  records <- if (length(path)) sen_pluck(x, path) else x
  if (is.null(records)) {
    return(invisible()) # envelope without records (unknown id): nothing to trim
  }
  records <- records[keep(records)]
  if (length(path)) x[[path]] <- records else x <- records
  json <- jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", pretty = TRUE, digits = NA)
  con <- file(file, open = "wb")
  writeLines(enc2utf8(json), con, useBytes = TRUE)
  close(con)
}

first <- function(n) function(records) seq_len(min(n, length(records)))

senators <- c("Parlamentares", "Parlamentar")
code_of <- function(record) record$IdentificacaoParlamentar$CodigoParlamentar

for (file in list.files(fixture_dir, recursive = TRUE)) {
  if (grepl("^plenario/lista/legislaturas", file)) {
    trim(file, c("ListaLegislatura", "Legislaturas", "Legislatura"), first(4))
  } else if (grepl("^senador/partidos", file)) {
    trim(file, c("ListaPartidos", "Partidos", "Partido"), first(6))
  } else if (grepl("^processo/", file)) {
    trim(file, character(), first(8))
  } else if (grepl("^senador/lista/atual\\.json$", file)) {
    # five senators, among them two from PT (Beto Faro and Camilo Santana)
    trim(file, c("ListaParlamentarEmExercicio", senators), function(records) {
      which(vapply(records, code_of, "") %in% c("5672", "5982", "4639", "6336", "5967"))
    })
  } else if (grepl("^senador/lista/atual-", file)) {
    trim(file, c("ListaParlamentarEmExercicio", senators), first(3))
  } else if (grepl("^senador/lista/legislatura/57\\.json$", file)) {
    # 6295 (Carlos Favaro) is the one senator with two mandates in the 57th
    trim(file, c("ListaParlamentarLegislatura", senators), function(records) {
      union(1:3, which(vapply(records, code_of, "") == "6295"))
    })
  } else if (grepl("^senador/lista/legislatura/", file)) {
    trim(file, c("ListaParlamentarLegislatura", senators), first(3))
  } else if (grepl("^senador/5322/comissoes\\.json$", file)) {
    trim(file, c("MembroComissaoParlamentar", "Parlamentar", "MembroComissoes", "Comissao"), first(6))
  } else if (grepl("^senador/825/comissoes", file)) {
    trim(file, c("MembroComissaoParlamentar", "Parlamentar", "MembroComissoes", "Comissao"), first(3))
  } else if (grepl("^senador/825/discursos", file)) {
    # keep the speech whose Aparteante arrives as a lone object (506264)
    trim(file, c("DiscursosParlamentar", "Parlamentar", "Pronunciamentos", "Pronunciamento"), function(records) {
      codes <- vapply(records, function(r) r$CodigoPronunciamento, "")
      union(1:3, which(codes == "506264"))
    })
  }
}

files <- list.files(fixture_dir, recursive = TRUE, full.names = TRUE)
print(data.frame(file = sub(fixture_dir, "", files, fixed = TRUE), kb = round(file.size(files) / 1024, 1)))
cat("total KB:", round(sum(file.size(files)) / 1024), "\n")
