# Landscape Analysis: R Package for Brazilian Federal Senate Data

**Conversations:**  
- [R Package – Brazilian Senate (feasibility and market analysis)](https://claude.ai/chat/80223d90-0322-4e21-9258-814825170196)  
- [R Package – Brazilian Senate (MCP connector exploration)](https://claude.ai/chat/80223d90-0322-4e21-9258-814825170196)  

**Date:** February 23, 2026  

---

## 1. Objective

Before designing a new R package for Brazilian Federal Senate data, a comprehensive landscape analysis was conducted across two fronts:

- **R packages** — Which packages already exist, what they cover, and whether contributing to one would be viable.
- **MCP connectors** — Which Model Context Protocol servers already wrap the Senate API, what architectural decisions they made, and what infrastructure patterns are worth adopting.
- **Data volume** — Whether the Senate data scenario would demand the same storage architecture being planned for `healthbR` (Parquet, R2, pre-computed aggregations).

---

## 2. Existing R Packages

Three packages were identified. None is currently maintained or suitable for contribution.

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

### Verdict

The issues are architectural — they cannot be solved with isolated PRs. Contributing would be equivalent to rewriting. **The recommendation is to create a new package from scratch.**

---

## 4. MCP Connector Landscape

An exhaustive search was conducted across GitHub, npm, Glama, Smithery, LobeHub, mcpservers.org, PulseMCP, mcp.so, and Apify. **Three dedicated MCP servers** exist for the Senate API. Two of the three are authored by Bissoli — one for Node.js/npm, the other for Cloudflare Workers.

### 4.1. `mcp-senado` (Cristiano Aredes)

- Repository: [github.com/cristianoaredes/mcp-senado](https://github.com/cristianoaredes/mcp-senado)
- npm: `@aredes.me/mcp-senado` (~568 total downloads). Listed on Smithery and Glama.
- **56 tools** across 7 categories (senators, legislative proposals, voting, committees, plenary, parties, reference data).
- Enterprise-grade infrastructure: circuit breaker, in-memory LRU cache, token bucket rate limiting, Pino structured logging, Prometheus-style metrics, LGPD compliance (PII masking).
- 211 tests, 73% coverage (Vitest).
- 4 deployment modes: stdio, HTTP/REST, Docker (Alpine), Cloudflare Workers (with Durable Objects).
- **Missing:** No e-Cidadania coverage.
- Companion project: [`mcp-dadosbr`](https://github.com/cristianoaredes/mcp-dadosbr) — a broader Brazilian OSINT toolkit (23 tools: CNPJ, CEP, courts, transparency, healthcare, finance).

### 4.2. `senado-br-mcp` (Sidney Bissoli)

- Repository: [github.com/SidneyBissoli/senado-br-mcp](https://github.com/SidneyBissoli/senado-br-mcp)
- npm: `senado-br-mcp` v1.1.5 (~45 downloads/week). Listed on Glama, mcpservers.org, LobeHub, MCP Gallery Japan.
- **33 tools** across 8 categories. Cloud-hosted at `https://senado-br-mcp.up.railway.app/mcp` (Railway).
- Standard architecture: Express, node-cache (15min–24h TTL), Pino, Cheerio (for scraping), esbuild.
- **Key differentiator: 11 tools dedicated to e-Cidadania** — the Senate's citizen participation platform (public consultations with voting data, legislative ideas, interactive events). Unique among all Senate MCPs and R packages. These endpoints are not part of the official REST API and require web scraping, rate-limited to 1 req/sec.
- **This is the MCP currently connected in this Claude project.**

### 4.3. `senado-br-mcp-cloudflare` (Sidney Bissoli)

- Repository: [github.com/SidneyBissoli/senado-br-mcp-cloudflare](https://github.com/SidneyBissoli/senado-br-mcp-cloudflare)
- Not published on npm — deployed via `wrangler deploy` to Cloudflare Workers.
- **37 tools** across 8 groups — same coverage as the Node.js version plus 4 extra tools (`senado_senador_detail`, `senado_search_votacoes`, `senado_search_processos`, `senado_votos_materia`).
- Ground-up rewrite for edge deployment: only 3 production deps (`@modelcontextprotocol/sdk`, `agents`, `zod`), multi-layer caching (L0 in-memory + L1 Cache API + L2 KV), token bucket rate limiting (global 8 req/s + per-client 2 req/s), concurrency limiter (max 6 upstream requests), stateless per-request architecture.

### MCP Comparative Summary

| Dimension | `mcp-senado` (Aredes) | `senado-br-mcp` (Bissoli) | `senado-br-mcp-cloudflare` (Bissoli) |
|---|---|---|---|
| **Tools** | 56 | 33 | 37 |
| **e-Cidadania** | No | Yes (11 tools) | Yes (11 tools) |
| **Runtime** | Node.js 18+ | Node.js 18+ | Cloudflare Workers |
| **Infrastructure** | Enterprise (circuit breaker, LRU, Prometheus) | Standard (node-cache) | Edge-native (multi-layer cache, concurrency limiter) |
| **Testing** | 211 tests, 73% coverage | Not specified | Not specified |
| **Deployment** | 4 modes (stdio, HTTP, Docker, CF Workers) | 2 modes (stdio, Railway) | 1 mode (Cloudflare Workers) |
| **Production deps** | Multiple | 8+ | 3 |

The three represent different philosophies: Aredes prioritized **infrastructure depth** (circuit breakers, observability, LGPD); Bissoli's Node.js version prioritized **coverage breadth** (e-Cidadania, broader ecosystem); and Bissoli's Cloudflare variant is an **edge-native evolution** trading npm portability for leaner dependencies and multi-layer caching. All three wrap the same underlying API at `https://legis.senado.leg.br/dadosabertos/`.

---

## 5. Adjacent Brazilian Government Data MCPs

Beyond the Senate, a broader ecosystem of Brazilian legislative and government MCPs was identified:

- **Câmara dos Deputados:** [`AgenteCidadaoMCP`](https://github.com/gvc2000/AgenteCidadaoMCP) (57 tools, production-grade), [`mcp-camara`](https://github.com/vrtornisiello/mcp-camara) (6 tools, minimal), and `mcp-camara-server` (LobeHub listing only).
- **Federal Transparency:** [`mcp-portal-transparencia`](https://github.com/dutradotdev/mcp-portal-transparencia) (142 stars — most popular Brazil gov MCP; dynamic tool generation from Swagger).
- **IBGE/BCB:** `ibge-br-mcp` (23 tools, Bissoli) and `bcb-br-mcp` (8 tools, Bissoli).
- **Other:** `mcp-dadosbr` (Aredes, OSINT), `brasil-api-mcp-server` (BrasilAPI), Brazilian Law Research MCP, MCP PJe Server.

---

## 6. Data Volume: Senate vs. DATASUS

A central question was whether the Senate package would face the same volume problem as `healthbR`. **The answer is no — the scenario is radically different.**

### Scale Comparison

| Dimension | DATASUS (healthbR) | Federal Senate |
|---|---|---|
| Unit of analysis | Individual (200M+ Brazilians) | Senator (81 in office) |
| Records/year (vaccination) | Tens/hundreds of millions | N/A |
| Votes/year | N/A | ~100 (95 in 2024) |
| Roll-call votes/year | N/A | ~8,000 (95 votes × ~81 senators) |
| Legislative matters | N/A | Thousands, but each is 1 row of metadata |
| Committees | N/A | ~30 permanent + temporary |

A real API call to the Senate API (`senado_listar_votacoes`, year=2024) returned **95 votes** — the entire year. Even the complete history since 1991 would fit in memory in a tibble.

### Architectural Implication

Parquet, R2, and pre-computed aggregations are **not needed**. The technical challenge here is different: API stability (endpoints that change), response format inconsistency (standard XML, optional JSON), variable field names, and undocumented rate limiting. The solution is a robust **access infrastructure layer** — retry, cache, normalization — which the planned `apigateway` shared infrastructure would address.

---

## 7. Implications for the R Package Design

### 7.1. API Coverage Target

Combining the coverage of all three MCPs and filling their gaps, the R package should target:

| Domain | Covered by MCPs? | R Package Target |
|---|---|---|
| Senators (list, search, details, mandates) | Yes | Yes |
| Legislative Matters (search, details, proceedings, texts) | Yes | Yes |
| Voting (plenary, nominal, by senator, by matter) | Yes | Yes |
| Committees (list, details, members, meetings) | Yes | Yes |
| Plenary Agenda | Yes | Yes |
| Reference Data (legislature, types, parties, UFs) | Yes | Yes |
| Processes (search, details) | Partial | Yes |
| e-Cidadania (consultations, ideas, events) | Yes (Bissoli only) | Yes |
| Parliamentary Blocs | No | Future |
| Legislation/Normas | No | Future |

### 7.2. Infrastructure Patterns to Adopt

From the MCP ecosystem analysis, three sets of patterns emerged:

**From Aredes' architecture:**  
- Retry with exponential backoff (the Senate API has undocumented rate limiting).  
- In-memory caching (`memoise` or `cachem` in R, equivalent to LRU cache).  
- User-agent header to identify the package.  
- Response normalization (clean column names in snake_case, consistent types).  

**From Bissoli's Node.js architecture:**  
- e-Cidadania as a separate web scraping module, with its own rate limiting.  
- Tiered cache TTL — short for agendas/recent votes (15min), long for historical data (24h).  

**From Bissoli's Cloudflare Workers architecture:**  
- Concurrency limiter — cap on simultaneous upstream requests to avoid overloading the Senate API.  
- Minimal dependency philosophy — avoid bloating the R package with unnecessary imports.  

### 7.3. What No Existing Tool Solved (R Package Differentiator)

All three MCPs return raw API responses with minimal transformation. The existing R packages either have broken APIs or architectural flaws. The new R package should differentiate by providing:

- **Tidy output** — all functions return tibbles with consistent snake_case column names.
- **Transparent pagination** — handled internally, invisible to the user.
- **Date parsing** — the API returns dates as strings in various formats.
- **Factor encoding** — party names, vote types, matter types as factors.
- **Cross-referencing** — e.g., join senator codes across voting and biographical data.

### 7.4. Naming Convention

All three MCPs use a `senado_*` prefix for all tools, validating the planned R package convention: `senado_senators()`, `senado_votes()`, `senado_matters()`, etc. (or a shorter `sen_*` prefix).

---

## 8. Decisions and Next Steps

1. **Create a new R package from scratch** — none of the existing packages is suitable for contribution.
2. **No storage architecture needed** — the Senate API returns everything in real time and fits in memory.
3. **Focus on access layer quality:** central `senado_get()` function with retry, cache, user-agent, and response normalization.
4. **Define initial scope** covering senators, votes, legislative matters, committees, e-Cidadania, and reference data.
5. **Consider `apigateway` as shared infrastructure** across the package suite (healthbR, educabR, welfarebR, and this Senate package).

---

## 9. Resources

### Official Senate API
- Documentation: `https://legis.senado.leg.br/dadosabertos/docs/index.html`
- Swagger UI: `https://legis.senado.leg.br/dadosabertos/api-docs/swagger-ui/index.html`

### MCP Servers
- Aredes: `https://github.com/cristianoaredes/mcp-senado`
- Bissoli (Node.js): `https://github.com/SidneyBissoli/senado-br-mcp`
- Bissoli (Cloudflare): `https://github.com/SidneyBissoli/senado-br-mcp-cloudflare`

### Adjacent Projects (Reference)
- AgenteCidadaoMCP (Câmara): `https://github.com/gvc2000/AgenteCidadaoMCP`
- Portal Transparência MCP: `https://github.com/dutradotdev/mcp-portal-transparencia`
- senatebR (R package, reference): `https://github.com/vsntos/senatebR`
