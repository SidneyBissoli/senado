# Reference data (Module 3.1)
# Legislatures, parties, bill types and bill statuses

# --- Column specifications --------------------------------------------------
# Functions, not objects: R files are collated alphabetically and sen_col()
# is defined in utils-parse.R.

spec_legislative_sessions <- function() list(
  sen_col("session_number", "NumeroSessaoLegislativa", "integer"),
  sen_col("session_type", "TipoSessaoLegislativa"),
  sen_col("start_date", "DataInicio", "date"),
  sen_col("end_date", "DataFim", "date")
)

spec_legislatures <- function() list(
  sen_col("legislature", "NumeroLegislatura", "integer"),
  sen_col("start_date", "DataInicio", "date"),
  sen_col("end_date", "DataFim", "date"),
  sen_col("election_date", "DataEleicao", "date"),
  sen_col(
    "sessions", c("SessoesLegislativas", "SessaoLegislativa"), "list",
    spec = spec_legislative_sessions()
  )
)

spec_parties <- function() list(
  sen_col("party_code", "Codigo", "integer"),
  sen_col("party", "Sigla"),
  sen_col("party_name", "Nome"),
  sen_col("creation_date", "DataCriacao", "date"),
  sen_col("extinction_date", "DataExtincao", "date")
)

spec_bill_types <- function() list(
  sen_col("type", "sigla"),
  sen_col("description", "descricao"),
  sen_col("start_date", "dataInicio", "date"),
  sen_col("end_date", "dataFim", "date")
)

spec_bill_statuses <- function() list(
  sen_col("status_id", "id", "integer"),
  sen_col("status", "sigla"),
  sen_col("description", "descricao"),
  sen_col("start_date", "dataInicio", "date"),
  sen_col("end_date", "dataFim", "date")
)

# --- Legislatures -----------------------------------------------------------

#' List the legislatures of the Federal Senate
#'
#' Returns every legislature known to the API, from the 1st (1826) to the
#' next one to be installed, with the legislative sessions of each.
#'
#' @return A [tibble::tibble] with one row per legislature, most recent
#'   first:
#'   \describe{
#'     \item{legislature}{Legislature number (integer).}
#'     \item{start_date, end_date}{First and last day of the legislature
#'       (Date).}
#'     \item{election_date}{Day of the election that formed it (Date).}
#'     \item{sessions}{List-column. For each legislature, a tibble of its
#'       legislative sessions: `session_number` (integer), `session_type`
#'       (character, e.g. "Ordinária"), `start_date` and `end_date`
#'       (Date).}
#'   }
#'
#' @details
#' The legislative sessions live in a list-column. To get one row per
#' session, use `tidyr::unnest(sen_legislatures(), sessions, names_sep = "_")`.
#'
#' @examplesIf senado:::sen_api_available()
#' legislatures <- sen_legislatures()
#' legislatures
#'
#' # Legislative sessions of the most recent legislature
#' legislatures$sessions[[1]]
#'
#' @family reference data
#' @export
sen_legislatures <- function() {
  data <- sen_get("plenario/lista/legislaturas", cache_category = "reference")
  records <- sen_records(
    data, c("ListaLegislatura", "Legislaturas", "Legislatura")
  )
  sen_as_tibble(records, spec_legislatures())
}

#' Number of the legislature in force on a given day
#'
#' Default of the `legislature` argument across the package.
#'
#' @param date A `Date`. Defaults to today.
#' @param call The calling environment for error context.
#' @return An integer.
#' @noRd
sen_current_legislature <- function(date = Sys.Date(),
                                    call = rlang::caller_env()) {
  path <- paste0("plenario/legislatura/", format(date, "%Y%m%d"))
  data <- sen_get(path, cache_category = "reference", call = call)
  records <- sen_records(
    data, c("ListaLegislatura", "Legislaturas", "Legislatura")
  )

  if (length(records) == 0L) {
    cli::cli_abort(
      "The Senado API reports no legislature in force on {format(date)}.",
      class = c("senado_error_not_found", "senado_error"),
      call = call
    )
  }

  sen_as_tibble(records, spec_legislatures())$legislature[[1]]
}

# --- Parties ----------------------------------------------------------------

#' List political parties
#'
#' Returns the parties registered by the Senate, both active and extinct.
#'
#' @return A [tibble::tibble] with one row per party:
#'   \describe{
#'     \item{party_code}{Party code in the Senate systems (integer).}
#'     \item{party}{Party abbreviation (character), as used in the `party`
#'       column and argument of the other functions.}
#'     \item{party_name}{Full name (character).}
#'     \item{creation_date}{Date the party was created (Date).}
#'     \item{extinction_date}{Date the party was dissolved (Date); `NA` for
#'       active parties.}
#'   }
#'
#' @examplesIf senado:::sen_api_available()
#' parties <- sen_parties()
#'
#' # Active parties only
#' parties[is.na(parties$extinction_date), ]
#'
#' @family reference data
#' @export
sen_parties <- function() {
  data <- sen_get("senador/partidos", cache_category = "reference")
  records <- sen_records(data, c("ListaPartidos", "Partidos", "Partido"))
  sen_as_tibble(records, spec_parties())
}

# --- Bill types and statuses ------------------------------------------------

#' List bill types
#'
#' Returns the types of legislative proposals (PEC, PL, PLP, MPV...). The
#' `type` column holds the values accepted by the `type` argument of
#' `sen_bills()`.
#'
#' @return A [tibble::tibble] with one row per type:
#'   \describe{
#'     \item{type}{Abbreviation (character), e.g. `"PEC"`.}
#'     \item{description}{What the abbreviation stands for (character).}
#'     \item{start_date}{First day the type was in use (Date).}
#'     \item{end_date}{Last day the type was in use (Date); `NA` for the
#'       types still in use.}
#'   }
#'
#' @examplesIf senado:::sen_api_available()
#' types <- sen_bill_types()
#'
#' # Types still in use
#' types[is.na(types$end_date), ]
#'
#' @family reference data
#' @export
sen_bill_types <- function() {
  data <- sen_get("processo/siglas", cache_category = "reference")
  sen_as_tibble(sen_records(data), spec_bill_types())
}

#' List bill statuses
#'
#' Returns the situations a legislative proposal can be in (e.g. "ready for
#' the floor agenda"). The `status` column holds the values accepted by the
#' `status` argument of `sen_bills()`.
#'
#' @return A [tibble::tibble] with one row per status:
#'   \describe{
#'     \item{status_id}{Status identifier (integer).}
#'     \item{status}{Abbreviation (character), e.g. `"AGDDO"`.}
#'     \item{description}{Description, in Portuguese (character).}
#'     \item{start_date}{First day the status was in use (Date).}
#'     \item{end_date}{Last day the status was in use (Date); `NA` for the
#'       statuses still in use.}
#'   }
#'
#' @examplesIf senado:::sen_api_available()
#' sen_bill_statuses()
#'
#' @family reference data
#' @export
sen_bill_statuses <- function() {
  data <- sen_get("processo/tipos-situacao", cache_category = "reference")
  sen_as_tibble(sen_records(data), spec_bill_statuses())
}
