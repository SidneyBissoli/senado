# Summary: Feasibility of an R Package for Brazilian Senate Data

**Conversation:** "R Package – Brazilian Senate (feasibility and market analysis)"  
**Link:** https://claude.ai/chat/80223d90-0322-4e21-9258-814825170196  
**Date:** February 23, 2026  

---

## 1. Conversation Objective

Assess whether R packages already exist for accessing data from the Brazilian Federal Senate and, if so, whether it is worth creating a new package or contributing to an existing one. Also evaluate whether the data volume scenario would require a storage architecture like the one being planned for the `healthbR` redesign.

---

## 2. Existing R Packages for Senate Data

Three packages were identified:

### 2.1. `congressbr` (McDonnell, Duarte & Freire, 2017)

- Covered both the House and Senate (`sen_*` and `cham_*` functions).
- Academic publication in the *Latin American Research Review* (2019).
- **Status: dead.** Removed from CRAN. GitHub repository with no updates since 2020. Several functions broken due to API changes.

### 2.2. `SenadoBR` (Daniel Marcelino)

- Focused exclusively on the Senate: roll-call votes, senator lists, bloc leaders.
- 26 commits, 2 stars, experimental status.
- **Never reached CRAN.** No recent activity. Example data outdated.

### 2.3. `senatebR` (Vinicius Santos, 2024)

- The most recent and ambitious. Author: PhD candidate in political science, UFMG.
- 147 commits, 15 stars, MIT license, pkgdown site.
- **Detailed source code analysis** (repository cloned and inspected).

---

## 3. Detailed Analysis of `senatebR`

### Structure

- 36 R files, 36 exported functions, ~2,600 lines of code.
- Commits: April 2024 to May 2025 (most concentrated in April 2024).
- Includes an academic paper in the `Texto/` folder.

### Strengths

- Broad thematic coverage (5 dimensions: senators, legislative matters, committees, plenary, votes).
- roxygen2 documentation present in all functions.
- `tryCatch` in most functions.

### Serious Issues Identified

1. **Heavy and inappropriate dependencies:** imports `spacyr` (requires spaCy/Python), `quanteda`, `stm`, `tidytext`, `ggrepel`, `ggridges`, `patchwork` — none of these relate to data access. Would be rejected by CRAN.

2. **Three access methods without standardization:**
   - REST API with JSON (8 files) — `httr::GET` + `jsonlite`
   - Static XML (18 files) — `xml2::read_xml`
   - HTML web scraping (11 files) — `rvest::read_html`
   - No unified abstraction layer (no central `senado_get()`).

3. **Zero robustness infrastructure:** no rate limiting (only 1 file with `Sys.sleep`), no cache, no user-agent, no retry, no encoding handling.

4. **No tests and no vignettes.** `testthat` listed in Suggests, but no tests written. No vignettes. `NEWS.md` contains only "Release".

5. **Inconsistent code style:** `%>%` (not `|>`), `data.frame()` (not `tibble()`), extensive `for` loops, and mixed function prefixes (`obter_*`, `extrair_*`, `info_*`, `coletar_*`, `dados_*`, `processar_*`, `get_*`).

6. **Inconsistent column names:** PascalCase and snake_case mixed, inheriting API format without standardization.

7. **Partial API coverage:** does not include legislative matter search by criteria, detailed proceedings, e-Cidadania, parliamentary blocs, or legislation.

### Conclusion on `senatebR`

The issues are architectural — they cannot be solved with isolated PRs. Contributing would be equivalent to rewriting. **The recommendation is to create a new package.**

---

## 4. Data Volume: Senate vs. DATASUS

Central question: will the Senate package face the same volume problem as `healthbR`?

**Answer: no. The scenario is radically different.**

### Scale Comparison

| Dimension | DATASUS (healthbR) | Federal Senate |
|---|---|---|
| Unit of analysis | Individual (200M+ Brazilians) | Senator (81 in office) |
| Records/year (vaccination) | Tens/hundreds of millions | N/A |
| Votes/year | N/A | ~100 (95 in 2024) |
| Roll-call votes/year | N/A | ~8,000 (95 votes × ~81 senators) |
| Legislative matters | N/A | Thousands, but each is 1 row of metadata |
| Committees | N/A | ~30 permanent + temporary |

### Empirical Evidence

A real API call was made to the Senate API (`senado_listar_votacoes`, year=2024), which returned **95 votes** — the entire year. Even the complete history of all votes since 1991 would fit in memory in a tibble.

### Architectural Implication

- **Not needed:** Parquet, R2, pre-computed aggregations, or any storage infrastructure.
- **The technical challenge is different:** API stability (endpoints that change), response format inconsistency (standard XML, optional JSON), variable field names, undocumented rate limiting.
- **The solution is an access infrastructure layer:** retry, cache, normalization — which the `apigateway` concept from the prioritization matrix would address.

---

## 5. Decisions and Suggested Next Steps

1. **Create a new R package** (do not contribute to `senatebR`).
2. **Do not worry about storage architecture** — the Senate API returns everything in real time and fits in memory.
3. **Focus on access layer quality:** central `senado_get()` function with retry, cache, user-agent, response normalization.
4. **Define initial scope** covering the most demanded endpoints: senators, votes, legislative matters, committees, e-Cidadania.
5. **Consider `apigateway` as shared infrastructure** between this package and others (healthbR, educabR, welfarebR).

---

## 6. Useful Resources Identified

- **Official Senate API:** `https://legis.senado.leg.br/dadosabertos/docs/index.html`
- **Swagger UI:** `https://legis.senado.leg.br/dadosabertos/api-docs/swagger-ui/index.html`
- **Senate MCP server** available in this Claude project (direct access via tools).
- **senatebR repository (reference):** `https://github.com/vsntos/senatebR`
