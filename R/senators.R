# Senators (Module 3.2)
# Lists, details, mandates, committee memberships and speeches

# --- Column specifications --------------------------------------------------
# Functions, not objects: R files are collated alphabetically and sen_col()
# is defined in utils-parse.R.

spec_mandate_summary <- function() list(
  sen_col("mandate_code", "CodigoMandato", "integer"),
  sen_col("state", "UfParlamentar"),
  sen_col("participation", "DescricaoParticipacao"),
  sen_col(
    "first_legislature",
    c("PrimeiraLegislaturaDoMandato", "NumeroLegislatura"), "integer"
  ),
  sen_col(
    "second_legislature",
    c("SegundaLegislaturaDoMandato", "NumeroLegislatura"), "integer"
  )
)

spec_senators <- function() {
  id <- "IdentificacaoParlamentar"
  list(
    sen_col("senator_code", c(id, "CodigoParlamentar"), "integer"),
    sen_col("name", c(id, "NomeParlamentar")),
    sen_col("full_name", c(id, "NomeCompletoParlamentar")),
    sen_col("sex", c(id, "SexoParlamentar")),
    sen_col("treatment", c(id, "FormaTratamento"), trim = TRUE),
    sen_col("party", c(id, "SiglaPartidoParlamentar")),
    sen_col("state", c("Mandato", "UfParlamentar")),
    sen_col("participation", c("Mandato", "DescricaoParticipacao")),
    sen_col("mandate_code", c("Mandato", "CodigoMandato"), "integer"),
    sen_col(
      "first_legislature",
      c("Mandato", "PrimeiraLegislaturaDoMandato", "NumeroLegislatura"),
      "integer"
    ),
    sen_col(
      "second_legislature",
      c("Mandato", "SegundaLegislaturaDoMandato", "NumeroLegislatura"),
      "integer"
    ),
    sen_col("bloc", c(id, "Bloco", "NomeBloco")),
    sen_col("board_member", c(id, "MembroMesa"), "logical"),
    sen_col("leadership_member", c(id, "MembroLideranca"), "logical"),
    sen_col("email", c(id, "EmailParlamentar")),
    sen_col("photo_url", c(id, "UrlFotoParlamentar")),
    sen_col("page_url", c(id, "UrlPaginaParlamentar")),
    sen_col(
      "mandates", c("Mandatos", "Mandato"), "list",
      spec = spec_mandate_summary()
    )
  )
}

spec_senator <- function() {
  id <- "IdentificacaoParlamentar"
  basic <- "DadosBasicosParlamentar"
  list(
    sen_col("senator_code", c(id, "CodigoParlamentar"), "integer"),
    sen_col("name", c(id, "NomeParlamentar")),
    sen_col("full_name", c(id, "NomeCompletoParlamentar")),
    sen_col("sex", c(id, "SexoParlamentar")),
    sen_col("party", c(id, "SiglaPartidoParlamentar")),
    sen_col("state", c(id, "UfParlamentar")),
    sen_col("birth_date", c(basic, "DataNascimento"), "date"),
    sen_col("birthplace", c(basic, "Naturalidade")),
    sen_col("birthplace_state", c(basic, "UfNaturalidade")),
    sen_col("office_address", c(basic, "EnderecoParlamentar"), trim = TRUE),
    sen_col("email", c(id, "EmailParlamentar")),
    sen_col("photo_url", c(id, "UrlFotoParlamentar")),
    sen_col("page_url", c(id, "UrlPaginaParlamentar")),
    sen_col("personal_url", c(id, "UrlPaginaParticular")),
    sen_col(
      "phones", c("Telefones", "Telefone"), "list",
      spec = list(
        sen_col("number", "NumeroTelefone"),
        sen_col("fax", "IndicadorFax", "logical")
      )
    )
  )
}

spec_senator_mandates <- function() {
  first <- "PrimeiraLegislaturaDoMandato"
  second <- "SegundaLegislaturaDoMandato"
  list(
    sen_col("mandate_code", "CodigoMandato", "integer"),
    sen_col("state", "UfParlamentar"),
    sen_col("participation", "DescricaoParticipacao"),
    sen_col("first_legislature", c(first, "NumeroLegislatura"), "integer"),
    sen_col("first_start_date", c(first, "DataInicio"), "date"),
    sen_col("first_end_date", c(first, "DataFim"), "date"),
    sen_col("second_legislature", c(second, "NumeroLegislatura"), "integer"),
    sen_col("second_start_date", c(second, "DataInicio"), "date"),
    sen_col("second_end_date", c(second, "DataFim"), "date"),
    sen_col("holder_code", c("Titular", "CodigoParlamentar"), "integer"),
    sen_col("holder_name", c("Titular", "NomeParlamentar")),
    sen_col(
      "substitutes", c("Suplentes", "Suplente"), "list",
      spec = list(
        sen_col("participation", "DescricaoParticipacao"),
        sen_col("senator_code", "CodigoParlamentar", "integer"),
        sen_col("name", "NomeParlamentar")
      )
    ),
    sen_col(
      "terms", c("Exercicios", "Exercicio"), "list",
      spec = list(
        sen_col("term_code", "CodigoExercicio", "integer"),
        sen_col("start_date", "DataInicio", "date"),
        sen_col("end_date", "DataFim", "date"),
        sen_col("leave_code", "SiglaCausaAfastamento"),
        sen_col("leave_description", "DescricaoCausaAfastamento"),
        sen_col("reading_date", "DataLeitura", "date")
      )
    ),
    sen_col(
      "parties", c("Partidos", "Partido"), "list",
      spec = list(
        sen_col("party_code", "CodigoPartido", "integer"),
        sen_col("party", "Sigla"),
        sen_col("party_name", "Nome"),
        sen_col("affiliation_date", "DataFiliacao", "date"),
        sen_col("disaffiliation_date", "DataDesfiliacao", "date")
      )
    )
  )
}

spec_senator_committees <- function() {
  id <- "IdentificacaoComissao"
  list(
    sen_col("committee_code", c(id, "CodigoComissao"), "integer"),
    sen_col("committee", c(id, "SiglaComissao")),
    sen_col("committee_name", c(id, "NomeComissao")),
    sen_col("house", c(id, "SiglaCasaComissao")),
    sen_col("participation", "DescricaoParticipacao"),
    sen_col("start_date", "DataInicio", "date"),
    sen_col("end_date", "DataFim", "date")
  )
}

spec_senator_speeches <- function() {
  session <- "SessaoPlenaria"
  list(
    sen_col("speech_code", "CodigoPronunciamento", "integer"),
    sen_col("date", "DataPronunciamento", "date"),
    sen_col("speech_type", c("TipoUsoPalavra", "Sigla")),
    sen_col("speech_type_description", c("TipoUsoPalavra", "Descricao")),
    sen_col("party", "SiglaPartidoParlamentarNaData"),
    sen_col("state", "UfParlamentarNaData"),
    sen_col("house", "SiglaCasaPronunciamento"),
    sen_col("summary", "TextoResumo", trim = TRUE),
    sen_col("keywords", "Indexacao", trim = TRUE),
    sen_col("text_url", "UrlTexto"),
    sen_col("file_url", "UrlTextoBinario"),
    sen_col("session_id", c(session, "CodigoSessao"), "integer"),
    sen_col("session_type", c(session, "SiglaTipoSessao")),
    sen_col("session_number", c(session, "NumeroSessao"), "integer"),
    sen_col("session_date", c(session, "DataSessao"), "date"),
    sen_col(
      "interjections", c("Aparteantes", "Aparteante"), "list",
      spec = list(
        sen_col("senator_code", "CodigoParlamentar", "integer"),
        sen_col("name", "NomeAparteante")
      )
    ),
    sen_col(
      "publications", c("Publicacoes", "Publicacao"), "list",
      spec = list(
        sen_col("source", "DescricaoVeiculoPublicacao"),
        sen_col("date", "DataPublicacao", "date"),
        sen_col("first_page", "NumeroPagInicioPublicacao", "integer"),
        sen_col("last_page", "NumeroPagFimPublicacao", "integer"),
        sen_col("republication", "IndicadorRepublicacao", "logical"),
        sen_col("url", "UrlDiario")
      )
    )
  )
}

# --- Helpers ----------------------------------------------------------------

#' Fetch a per-senator service and return its `Parlamentar` node
#'
#' The legacy services answer 200 to an unknown code, with an envelope that
#' lacks the `Parlamentar` node. A known senator with nothing to show (no
#' committees, no speeches) still has the node, so its absence means the
#' senator does not exist.
#'
#' @param code Senator code (validated integer).
#' @param service Character. `""`, `"mandatos"`, `"comissoes"` or
#'   `"discursos"`.
#' @param envelope Character. Name of the root key of the response.
#' @param required Character or `NULL`. Child of `Parlamentar` that must be
#'   present: the speeches service answers an unknown code with a
#'   `Parlamentar` node that lacks `IdentificacaoParlamentar`.
#' @param query Named list of query parameters.
#' @param cache_category Cache TTL tier.
#' @param call The calling environment for error context.
#' @return The parsed `Parlamentar` node.
#' @noRd
sen_senator_node <- function(code, service, envelope, query = NULL,
                             required = NULL, cache_category = "semi_static",
                             call = rlang::caller_env()) {
  path <- paste0("senador/", code)
  if (nzchar(service)) {
    path <- paste0(path, "/", service)
  }

  data <- sen_get(path, query = query, cache_category = cache_category, call = call)
  node <- sen_pluck(data, c(envelope, "Parlamentar"))

  if (is.null(node) || (!is.null(required) && is.null(node[[required]]))) {
    cli::cli_abort(
      c(
        "No senator found with code {.val {code}}.",
        "i" = "Senator codes are in the {.field senator_code} column of {.fn sen_senators}."
      ),
      class = c("senado_error_not_found", "senado_error"),
      call = call
    )
  }

  node
}

#' Put the senator code in front of a per-senator table
#' @noRd
sen_with_senator_code <- function(tbl, code) {
  tibble::add_column(
    tbl,
    senator_code = rep(as.integer(code), nrow(tbl)),
    .before = 1L
  )
}

#' Split a date window into calendar-year slices
#'
#' @param start,end `Date` values, `start <= end`.
#' @return A list of `c(start, end)` pairs, none crossing a year boundary.
#' @noRd
sen_year_slices <- function(start, end) {
  years <- seq(
    as.integer(format(start, "%Y")),
    as.integer(format(end, "%Y"))
  )
  lapply(years, function(year) {
    c(
      max(start, as.Date(sprintf("%d-01-01", year))),
      min(end, as.Date(sprintf("%d-12-31", year)))
    )
  })
}

# --- sen_senators -----------------------------------------------------------

#' List senators
#'
#' Returns the senators currently in office or, with `legislature`, everyone
#' who held a mandate in one legislature or in a range of legislatures --
#' holders and substitutes, whether or not they ever took office.
#'
#' @param legislature `NULL` (default) for the senators currently in office;
#'   a legislature number (e.g. `57`) for everyone with a mandate in that
#'   legislature; or two numbers (e.g. `c(55, 57)`) for a range. See
#'   [sen_legislatures()].
#' @param state Two-letter state abbreviation (e.g. `"SP"`). Filtered by the
#'   API.
#' @param party Party abbreviation (e.g. `"PT"`). **Only for the senators
#'   currently in office** (`legislature = NULL`); see the section on party
#'   below.
#' @param status `"all"` (default), `"holder"` for elected holders of the
#'   seat or `"substitute"` for substitutes (*suplentes*). Filtered by the
#'   API.
#' @param in_office Only with `legislature`: `TRUE` for those who actually
#'   took office during the legislature, `FALSE` for those who did not,
#'   `NULL` (default) for both.
#'
#' @return A [tibble::tibble] with one row per senator:
#'   \describe{
#'     \item{senator_code}{Senator code (integer). The join key across the
#'       package.}
#'     \item{name, full_name}{Parliamentary name and full civil name.}
#'     \item{sex}{`"Masculino"` or `"Feminino"`.}
#'     \item{treatment}{Form of address (`"Senador"`, `"Senadora"`).}
#'     \item{party}{Party abbreviation. See the section on party below.}
#'     \item{state}{State of the mandate.}
#'     \item{participation}{`"Titular"`, `"1º Suplente"` or
#'       `"2º Suplente"`.}
#'     \item{mandate_code}{Mandate code (integer).}
#'     \item{first_legislature, second_legislature}{The two legislatures an
#'       eight-year mandate spans (integer).}
#'     \item{bloc}{Parliamentary bloc. Current senators only.}
#'     \item{board_member, leadership_member}{Whether the senator sits on the
#'       Senate board or holds a leadership post (logical). Current senators
#'       only.}
#'     \item{email, photo_url, page_url}{Contact and web addresses.}
#'     \item{mandates}{List-column: a tibble with every mandate the senator
#'       held in the requested legislatures (`mandate_code`, `state`,
#'       `participation`, `first_legislature`, `second_legislature`). The
#'       flat mandate columns above describe the most recent one.}
#'   }
#'   With no match, a tibble with zero rows and the same columns.
#'
#' @section Party in historical lists:
#' Only the list of current senators carries a reliable party. In the lists
#' by legislature the API fills `party` for some senators only (153 of the
#' 245 in the 57th legislature), and with the party on record today, not
#' the party at the time. That is why the `party` argument is refused
#' together with `legislature`. For the party in each period use
#' [sen_senator_mandates()].
#'
#' @examplesIf senado:::sen_api_available()
#' # Senators currently in office
#' sen_senators()
#'
#' # From one state, from one party
#' sen_senators(state = "SP")
#' sen_senators(party = "PT")
#'
#' # Seats in office by state
#' table(sen_senators()$state)
#'
#' # Everyone who took office during the 56th legislature
#' sen_senators(legislature = 56, in_office = TRUE)
#'
#' @family senators
#' @export
sen_senators <- function(legislature = NULL, state = NULL, party = NULL,
                         status = c("all", "holder", "substitute"),
                         in_office = NULL) {
  status <- rlang::arg_match(status)
  if (!is.null(party)) {
    party <- validate_party(party)
  }
  query <- list(
    uf = if (!is.null(state)) validate_uf(state),
    participacao = switch(status, holder = "T", substitute = "S")
  )

  if (is.null(legislature)) {
    if (!is.null(in_office)) {
      cli::cli_abort(c(
        "{.arg in_office} can only be used together with {.arg legislature}.",
        "i" = "Without {.arg legislature}, every senator returned is in office."
      ))
    }
    path <- "senador/lista/atual"
    envelope <- "ListaParlamentarEmExercicio"
  } else {
    if (!is.null(party)) {
      cli::cli_abort(c(
        "{.arg party} can only be used for the senators currently in office.",
        "i" = "The API has no reliable party in the lists by legislature.",
        "i" = "For the party in each period, see {.fn sen_senator_mandates}."
      ))
    }
    if (!is.null(in_office)) {
      if (!rlang::is_bool(in_office)) {
        cli::cli_abort("{.arg in_office} must be `TRUE`, `FALSE` or `NULL`.")
      }
      query$exercicio <- if (in_office) "S" else "N"
    }
    path <- paste0(
      "senador/lista/legislatura/",
      paste(validate_legislature_range(legislature), collapse = "/")
    )
    envelope <- "ListaParlamentarLegislatura"
  }

  data <- sen_get(path, query = query, cache_category = "semi_static")
  records <- sen_records(data, c(envelope, "Parlamentares", "Parlamentar"))

  # The current list has one `Mandato`; the lists by legislature have
  # `Mandatos.Mandato[]`. Give every record both shapes.
  records <- lapply(records, function(record) {
    mandates <- sen_records(record, c("Mandatos", "Mandato"))
    if (length(mandates) == 0L) {
      mandates <- sen_records(record, "Mandato")
    }
    record$Mandatos <- list(Mandato = mandates)
    record$Mandato <- if (length(mandates) > 0L) mandates[[length(mandates)]]
    record
  })

  result <- sen_as_tibble(records, spec_senators())

  if (!is.null(party)) {
    result <- result[!is.na(result$party) & toupper(result$party) == party, ]
  }

  result
}

#' Validate `legislature`: one number, or an increasing pair
#' @noRd
validate_legislature_range <- function(legislature,
                                       call = rlang::caller_env()) {
  if (!length(legislature) %in% c(1L, 2L)) {
    cli::cli_abort(
      "{.arg legislature} must be one number or a pair (first, last), not {length(legislature)} values.",
      call = call
    )
  }

  out <- vapply(
    legislature,
    function(x) validate_positive_integer(x, arg = "legislature", call = call),
    integer(1)
  )

  if (length(out) == 2L && out[1] > out[2]) {
    cli::cli_abort(
      "{.arg legislature} must go from the earlier to the later legislature, not {out[1]} to {out[2]}.",
      call = call
    )
  }

  out
}

# --- sen_senator ------------------------------------------------------------

#' Details of one senator
#'
#' Returns the record of a senator: identification, party and state, birth
#' data, contact and web addresses.
#'
#' @param code Senator code, as in the `senator_code` column of
#'   [sen_senators()].
#'
#' @return A [tibble::tibble] with one row:
#'   \describe{
#'     \item{senator_code}{Senator code (integer).}
#'     \item{name, full_name}{Parliamentary name and full civil name.}
#'     \item{sex}{`"Masculino"` or `"Feminino"`.}
#'     \item{party, state}{Current (or last) party and state.}
#'     \item{birth_date}{Date of birth (Date).}
#'     \item{birthplace, birthplace_state}{City and state of birth.}
#'     \item{office_address}{Address of the office in the Senate.}
#'     \item{email, photo_url, page_url, personal_url}{Contact and web
#'       addresses.}
#'     \item{phones}{List-column: a tibble with `number` (character) and
#'       `fax` (logical).}
#'   }
#'   An unknown `code` raises an error of class `senado_error_not_found`.
#'
#' @section Related data:
#' The votes and the bills of a senator come from the general functions,
#' filtered by senator:
#'
#' ```r
#' # How the senator voted in 2024
#' sen_vote_records(senator = 5322, year = 2024)
#'
#' # Bills authored by the senator
#' sen_bills(author_code = 5322)
#' ```
#'
#' Mandates (with the party in each period), committee memberships and
#' speeches have their own functions: [sen_senator_mandates()],
#' [sen_senator_committees()] and [sen_senator_speeches()].
#'
#' @examplesIf senado:::sen_api_available()
#' senator <- sen_senator(5322)
#' senator
#'
#' senator$phones[[1]]
#'
#' @family senators
#' @export
sen_senator <- function(code) {
  code <- validate_senator_code(code)
  node <- sen_senator_node(code, "", "DetalheParlamentar")
  sen_as_tibble(list(node), spec_senator())
}

# --- sen_senator_mandates ---------------------------------------------------

#' Mandates of a senator
#'
#' Returns every mandate a senator has held, with the substitutes, the
#' periods actually in office and the party affiliations of each mandate.
#'
#' @inheritParams sen_senator
#'
#' @return A [tibble::tibble] with one row per mandate:
#'   \describe{
#'     \item{senator_code}{Senator code (integer).}
#'     \item{mandate_code}{Mandate code (integer).}
#'     \item{state}{State of the mandate.}
#'     \item{participation}{`"Titular"`, `"1º Suplente"` or
#'       `"2º Suplente"`.}
#'     \item{first_legislature, first_start_date, first_end_date}{First
#'       legislature of the mandate and its dates.}
#'     \item{second_legislature, second_start_date, second_end_date}{Second
#'       legislature of the mandate and its dates.}
#'     \item{holder_code, holder_name}{When the senator is a substitute: the
#'       holder of the seat. `NA` otherwise.}
#'     \item{substitutes}{List-column: `participation`, `senator_code`,
#'       `name`.}
#'     \item{terms}{List-column, one row per period in office: `term_code`,
#'       `start_date`, `end_date`, `leave_code`, `leave_description`,
#'       `reading_date`. The last four are `NA` while the term is ongoing.}
#'     \item{parties}{List-column, one row per party affiliation during the
#'       mandate: `party_code`, `party`, `party_name`, `affiliation_date`,
#'       `disaffiliation_date`.}
#'   }
#'   An unknown `code` raises an error of class `senado_error_not_found`.
#'
#' @details
#' Each mandate carries three lists of different things, so they are kept as
#' list-columns rather than multiplied into rows. Open one at a time:
#'
#' ```r
#' mandates <- sen_senator_mandates(5322)
#' tidyr::unnest(
#'   mandates[c("mandate_code", "parties")], parties
#' )
#' ```
#'
#' A party that changed its name appears under the current abbreviation.
#'
#' @examplesIf senado:::sen_api_available()
#' mandates <- sen_senator_mandates(5322)
#' mandates
#'
#' # Party affiliations during the most recent mandate
#' mandates$parties[[1]]
#'
#' @family senators
#' @export
sen_senator_mandates <- function(code) {
  code <- validate_senator_code(code)
  node <- sen_senator_node(code, "mandatos", "MandatoParlamentar")
  records <- sen_records(node, c("Mandatos", "Mandato"))
  sen_with_senator_code(sen_as_tibble(records, spec_senator_mandates()), code)
}

# --- sen_senator_committees -------------------------------------------------

#' Committee memberships of a senator
#'
#' Returns the committees a senator sits or has sat on. Besides Senate
#' committees, the list includes joint committees of the National Congress,
#' parliamentary groups and fronts.
#'
#' @inheritParams sen_senator
#' @param active `TRUE` for current memberships only, `FALSE` for past
#'   memberships only, `NULL` (default) for both. Filtered by the API.
#' @param committee Committee abbreviation (e.g. `"CCJ"`) to keep only the
#'   memberships in that committee. Filtered by the API.
#'
#' @return A [tibble::tibble] with one row per membership:
#'   \describe{
#'     \item{senator_code}{Senator code (integer).}
#'     \item{committee_code}{Committee code (integer).}
#'     \item{committee, committee_name}{Abbreviation and name.}
#'     \item{house}{`"SF"` (Senate) or `"CN"` (National Congress).}
#'     \item{participation}{`"Titular"` or `"Suplente"`.}
#'     \item{start_date, end_date}{Membership period (Date); `end_date` is
#'       `NA` for current memberships.}
#'   }
#'   A senator with no membership yields zero rows; an unknown `code` raises
#'   an error of class `senado_error_not_found`.
#'
#' @examplesIf senado:::sen_api_available()
#' sen_senator_committees(5322)
#'
#' # Current memberships only
#' sen_senator_committees(5322, active = TRUE)
#'
#' @family senators
#' @export
sen_senator_committees <- function(code, active = NULL, committee = NULL) {
  code <- validate_senator_code(code)

  if (!is.null(active) && !rlang::is_bool(active)) {
    cli::cli_abort("{.arg active} must be `TRUE`, `FALSE` or `NULL`.")
  }
  if (!is.null(committee) && !rlang::is_string(committee)) {
    cli::cli_abort("{.arg committee} must be a single character string.")
  }

  query <- list(
    ativo = if (!is.null(active)) if (active) "S" else "N",
    comissao = if (!is.null(committee)) toupper(trimws(committee))
  )

  node <- sen_senator_node(
    code, "comissoes", "MembroComissaoParlamentar",
    query = query
  )
  records <- sen_records(node, c("MembroComissoes", "Comissao"))
  sen_with_senator_code(sen_as_tibble(records, spec_senator_committees()), code)
}

# --- sen_senator_speeches ---------------------------------------------------

#' Speeches of a senator
#'
#' Returns the floor speeches of a senator in a period, with a summary,
#' keywords and links to the text. The text itself is not part of the
#' response.
#'
#' @inheritParams sen_senator
#' @param start_date,end_date Period, as `Date` or `"YYYY-MM-DD"`. With
#'   neither, the API returns the last 30 days. With only `start_date`, the
#'   period runs until today.
#'
#' @return A [tibble::tibble] with one row per speech:
#'   \describe{
#'     \item{senator_code}{Senator code (integer).}
#'     \item{speech_code}{Speech code (integer).}
#'     \item{date}{Date of the speech (Date).}
#'     \item{speech_type, speech_type_description}{Kind of floor use (e.g.
#'       `"DIS"`, "Discurso").}
#'     \item{party, state}{Party and state of the senator **on the date of
#'       the speech**.}
#'     \item{house}{`"SF"` (Senate) or `"CN"` (National Congress).}
#'     \item{summary}{Summary of the speech, in Portuguese.}
#'     \item{keywords}{Indexing terms, comma-separated.}
#'     \item{text_url, file_url}{Links to the full text (web page and file).}
#'     \item{session_id, session_type, session_number, session_date}{The
#'       plenary session in which the speech was given. `session_id` is the
#'       same key used by `sen_votes()` and `sen_sessions()`.}
#'     \item{interjections}{List-column: senators who interjected
#'       (`senator_code`, `name`).}
#'     \item{publications}{List-column: where the speech was published
#'       (`source`, `date`, `first_page`, `last_page`, `republication`,
#'       `url`).}
#'   }
#'   A period without speeches yields zero rows; an unknown `code` raises an
#'   error of class `senado_error_not_found`.
#'
#' @details
#' The API silently truncates any window longer than one year, keeping only
#' the year before `end_date`. To return what was asked for, the function
#' splits longer periods into calendar years, makes one request per year
#' (with a progress bar) and stacks the results.
#'
#' @examplesIf senado:::sen_api_available()
#' # Last 30 days
#' sen_senator_speeches(825)
#'
#' # One month
#' sen_senator_speeches(825, start_date = "2024-05-01", end_date = "2024-05-31")
#'
#' @family senators
#' @export
sen_senator_speeches <- function(code, start_date = NULL, end_date = NULL) {
  code <- validate_senator_code(code)

  if (is.null(start_date) && is.null(end_date)) {
    slices <- list(NULL)
  } else {
    if (is.null(start_date)) {
      cli::cli_abort(c(
        "{.arg end_date} needs a {.arg start_date}.",
        "i" = "With neither, the API returns the last 30 days."
      ))
    }
    start_date <- validate_date(start_date, arg = "start_date")
    end_date <- if (is.null(end_date)) {
      Sys.Date()
    } else {
      validate_date(end_date, arg = "end_date")
    }
    if (start_date > end_date) {
      cli::cli_abort(
        "{.arg start_date} ({start_date}) must not be after {.arg end_date} ({end_date})."
      )
    }
    slices <- sen_year_slices(start_date, end_date)
  }

  if (length(slices) > 1L) {
    cli::cli_progress_bar("Fetching speeches, year by year", total = length(slices))
  }

  records <- list()
  for (slice in slices) {
    query <- if (!is.null(slice)) {
      list(
        dataInicio = format(slice[1], "%Y%m%d"),
        dataFim = format(slice[2], "%Y%m%d")
      )
    }
    node <- sen_senator_node(
      code, "discursos", "DiscursosParlamentar",
      query = query, required = "IdentificacaoParlamentar",
      cache_category = "dynamic"
    )
    records <- c(records, sen_records(node, c("Pronunciamentos", "Pronunciamento")))
    if (length(slices) > 1L) {
      cli::cli_progress_update()
    }
  }

  result <- sen_as_tibble(records, spec_senator_speeches())
  result <- result[order(result$date, result$speech_code), ]
  sen_with_senator_code(result, code)
}
