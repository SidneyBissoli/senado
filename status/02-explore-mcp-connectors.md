# Summary: MCP Connector Landscape for Brazilian Senate Data

**Conversation:** "R Package – Brazilian Senate (MCP connector exploration)"  
**Link:** https://claude.ai/chat/80223d90-0322-4e21-9258-814825170196  
**Date:** February 23, 2026  

---

## 1. Objective

Before designing the R package for Brazilian Senate data, we explored the **MCP (Model Context Protocol) ecosystem** to understand:

- Which MCP servers already wrap the Senate API, and what architectural decisions they made.
- What API endpoints they cover — to map the full surface area available.
- What infrastructure patterns (caching, retry, rate limiting) they implemented — to inform the R package's own `senado_get()` layer.
- What adjacent Brazilian government data MCPs exist — for ecosystem context.

---

## 2. Senate MCP Servers Found

**Three dedicated MCP servers exist** for the Brazilian Federal Senate API. An exhaustive search was conducted across GitHub, npm, Glama, Smithery, LobeHub, mcpservers.org, PulseMCP, mcp.so, and Apify. No others were found. Two of the three are authored by Bissoli — one for Node.js/npm, the other for Cloudflare Workers.

### 2.1. `mcp-senado` (Cristiano Aredes)

- Author: Cristiano Aredes (`@cristianoaredes`), software engineer.
- Repository: [github.com/cristianoaredes/mcp-senado](https://github.com/cristianoaredes/mcp-senado)
- npm: `@aredes.me/mcp-senado` (install via `npx @aredes.me/mcp-senado`)
- License: Not confirmed (README references Smithery listing).
- Stats: 1 star, 0 forks, 45 commits. ~568 total npm downloads (spike of ~540 in Nov 2025, then ~15/month).

### 2.2. `senado-br-mcp` (Sidney Bissoli)

- Author: Sidney Bissoli (`@SidneyBissoli`), psychologist and data analyst.
- Repository: [github.com/SidneyBissoli/senado-br-mcp](https://github.com/SidneyBissoli/senado-br-mcp)
- npm: `senado-br-mcp` v1.1.5 (install via `npx senado-br-mcp`)
- License: MIT.
- Stats: 0 stars, 0 forks, 11 commits. ~45 npm downloads/week.
- Glama quality scores: Security A, License A, Quality A.
- **This is the MCP currently connected in this Claude Code environment.**

### 2.3. `senado-br-mcp-cloudflare` (Sidney Bissoli)

- Author: Sidney Bissoli (`@SidneyBissoli`).
- Repository: [github.com/SidneyBissoli/senado-br-mcp-cloudflare](https://github.com/SidneyBissoli/senado-br-mcp-cloudflare)
- npm: **Not published** (deployed via `wrangler deploy`, not npm).
- License: Not specified.
- Stats: 0 stars, 0 forks, 3 commits. Created February 19, 2026.
- **Development conversation:** [claude.ai/chat/d8a275f2-62d1-4da2-8507-e75640ff5328](https://claude.ai/chat/d8a275f2-62d1-4da2-8507-e75640ff5328)
- **This is the Cloudflare Workers variant of Bissoli’s Senate MCP, designed for edge deployment.**

---

## 3. Detailed Analysis: `mcp-senado` (Aredes)

### Architecture

The most architecturally sophisticated of the two. Built with enterprise-grade infrastructure:

- **Language/Runtime:** TypeScript 5.7+ (strict mode), Node.js 18+.
- **Testing:** Vitest — 211 tests, 73% coverage.
- **Schema validation:** Zod (all inputs validated before dispatch).
- **Circuit breaker:** API failure protection with automatic recovery.
- **In-memory LRU cache:** Reduces load on the Senate API.
- **Token bucket rate limiting:** Prevents API abuse.
- **Structured logging + metrics:** Full observability (Pino + Prometheus-style).
- **LGPD compliance:** PII masking, input sanitization.
- **Containerization:** Docker (multi-stage Alpine Linux, ~150MB image).

### Deployment Modes (4 options)

1. `stdio` — standard MCP protocol for Claude Desktop, Cursor, Windsurf, Continue.dev.
2. `HTTP/REST` — standalone server with multiple endpoints.
3. **Docker** — multi-stage Alpine image.
4. **Cloudflare Workers** — edge computing across 300+ global data centers, using 4 Durable Objects for cache, rate limiting, circuit breaking, and metrics.

### Tool Coverage: 56 tools across 7 categories

| Category | Tools | Coverage |
|---|---|---|
| Reference Data | 10 | Legislature types, bill types, processing statuses |
| Senators | 13 | List, search, biographical details, mandates, committees |
| Legislative Proposals | 12 | Search by keyword/author/type, full details, texts, proceedings |
| Voting Records | 5 | Plenary votes by date, recent votes, nominal records per senator |
| Committees | 5 | List, details, members, meeting schedules |
| Political Parties | 5 | Parties with representation, UF breakdown |
| Plenary Sessions | 6 | Agendas, session details |

### What's Missing

- **No e-Cidadania coverage.** Public consultations, legislative ideas, and interactive events are not included.

### Registry Listings

- Smithery: listed.
- Glama: listed at `glama.ai/mcp/servers/@cristianoaredes/mcp-senado`.

### Companion Project

Aredes also maintains [`mcp-dadosbr`](https://github.com/cristianoaredes/mcp-dadosbr) (`@aredes.me/mcp-dadosbr`), a broader Brazilian OSINT toolkit with 23 tools covering CNPJ, CEP, court proceedings, government transparency, healthcare facilities, and financial indicators. 1 star, 2 forks, 96 commits.

---

## 4. Detailed Analysis: `senado-br-mcp` (Bissoli)

### Architecture

Standard but functional, with a focus on breadth of coverage rather than infrastructure sophistication:

- **Language/Runtime:** TypeScript (strict), Node.js 18+.
- **HTTP framework:** Express 4.18.
- **MCP SDK:** `@modelcontextprotocol/sdk` ^1.0.0.
- **Schema validation:** Zod.
- **Caching:** `node-cache` (15min–24h TTL depending on data volatility).
- **Logging:** Pino.
- **HTML parsing:** Cheerio (for e-Cidadania scraping).
- **Build:** esbuild.

### Deployment Modes (2 options)

1. `stdio/npm` — local via `npx senado-br-mcp`.
2. **HTTP Remote** — cloud-hosted at `https://senado-br-mcp.up.railway.app/mcp` (Railway), with monthly request cap of 10,000.

### Tool Coverage: 33 tools across 8 categories

| Category | Tools | Notes |
|---|---|---|
| Legislature/Lookup | 4 | Current legislature, bill types, parties, UFs |
| Senators | 4 | List, search by name, details, enriched detail |
| Legislative Matters | 5 | Search, details, proceedings history, texts, processes |
| Voting | 6 | List by year, recent, details, senator votes, matter votes, advanced search |
| Committees | 4 | List, details, members, meetings |
| Agenda | 2 | Plenary sessions, committee calendar |
| e-Cidadania: Consultations | 4 | List, details, consensus analysis, polarization analysis |
| e-Cidadania: Ideas | 3 | List, details, popular ideas |
| e-Cidadania: Events | 3 | List, details, popular events |
| e-Cidadania: Analysis | 1 | Poll theme suggestions |

### Key Differentiator: e-Cidadania

**11 tools dedicated to e-Cidadania** — the Senate's citizen participation platform. This is unique among all Senate MCPs and R packages analyzed. It covers:

- **Public consultations** with citizen voting data (including consensus and polarization analysis).
- **Legislative ideas** proposed by citizens (including popularity rankings).
- **Interactive events** (public hearings, confirmation hearings, live streams).
- **Poll theme suggestions** based on configurable criteria.

These endpoints are not part of the official Senate REST API — they require web scraping (Cheerio), rate-limited to 1 req/sec.

### Version History

- v1.0.0: 22 tools (core Senate data).
- v1.1.0: +11 tools (e-Cidadania integration).
- v1.1.5: current.

### Registry Listings

- [Awesome MCP Servers (mcpservers.org)](https://mcpservers.org/servers/sidneybissoli/senado-br-mcp)
- [Glama.ai](https://glama.ai/mcp/servers/@SidneyBissoli/senado-br-mcp)
- [LobeHub](https://lobehub.com/mcp/sidneybissoli-senado-br-mcp)
- [MCP Gallery Japan](https://www.mcp-gallery.jp/mcp/github/sidneybissoli/senado-br-mcp)

### Broader Ecosystem

Bissoli maintains a coherent suite of four complementary MCPs:

| Package | Tools | Runtime | Data Source |
|---|---|---|---|
| `senado-br-mcp` | 33 | Node.js | Senate API + e-Cidadania |
| `senado-br-mcp-cloudflare` | 37 | Cloudflare Workers | Senate API + e-Cidadania |
| `ibge-br-mcp` | 23 | Node.js | IBGE (geography, census, statistics) + BCB + DataSUS |
| `bcb-br-mcp` | 8 | Node.js | Banco Central do Brasil SGS (150+ economic series) |

All four use TypeScript/Zod/MCP-SDK. The first three were created in January 2026; the Cloudflare Workers variant was created in February 2026.

---

## 4b. Detailed Analysis: `senado-br-mcp-cloudflare` (Bissoli)

### Architecture

A ground-up rewrite of Bissoli’s Senate MCP, purpose-built for Cloudflare Workers instead of Node.js:

- **Runtime:** Cloudflare Workers (ESM), not Node.js.
- **Transport:** Streamable HTTP (MCP spec 2025-03-26) via `createMcpHandler` from `agents/mcp`.
- **SDK:** `@modelcontextprotocol/sdk` 1.26.0+ (per-request McpServer instances — stateless).
- **Schema validation:** Zod.
- **Caching:** 2-layer: L0 (in-memory per-isolate) + L1 (Cloudflare Cache API), keyed by SHA-256 hash. Tiered TTLs: static (5min/10min), semi-static (2min/5min), dynamic (30s/60s), on-demand (30s/2min).
- **Rate limiting:** Token bucket — global (8 req/s) + per-client (2 req/s).
- **Upstream throttle:** Max 6 concurrent requests, 10s timeout, retry with exponential backoff + jitter on 429/503.
- **Dependencies:** Only 3 production deps (`@modelcontextprotocol/sdk`, `agents`, `zod`) — no Express, no Cheerio, no Pino.
- **Code:** ~2,458 lines of TypeScript across 14 source files.

### Deployment

1. **Cloudflare Workers** via `wrangler deploy` — edge computing across 300+ global data centers.
2. Uses **KV namespace** for optional L2 cache (rare, low-write items).
3. Health check at `/health`.
4. Not published on npm — this is a Workers-native project, not an npm package.

### Tool Coverage: 37 tools across 8 groups

| Category | Tools | Count |
|---|---|---|
| Reference Data | `senado_legislatura_atual`, `senado_tipos_materia`, `senado_partidos`, `senado_ufs` | 4 |
| Senators | `senado_listar_senadores`, `senado_buscar_senador_por_nome`, `senado_obter_senador`, `senado_senador_detail`, `senado_votacoes_senador` | 5 |
| Legislative Matters | `senado_buscar_materias`, `senado_obter_materia`, `senado_textos_materia`, `senado_tramitacao_materia` | 4 |
| Voting Records | `senado_listar_votacoes`, `senado_votacoes_recentes`, `senado_obter_votacao`, `senado_search_votacoes`, `senado_votos_materia` | 5 |
| Committees | `senado_listar_comissoes`, `senado_obter_comissao`, `senado_membros_comissao`, `senado_reunioes_comissao`, `senado_agenda_comissoes` | 5 |
| Plenary Sessions | `senado_agenda_plenario` | 1 |
| Processes | `senado_search_processos`, `senado_obter_processo` | 2 |
| e-Cidadania | 11 tools (consultations, ideas, events, analysis) | 11 |

### Key Differentiators vs. `senado-br-mcp`

- **Edge-native:** Runs on Cloudflare Workers, not Node.js. Responses served from the nearest data center globally.
- **Stateless per-request:** Each request creates a fresh McpServer instance (SDK 1.26.0+ requirement). No in-process state leaks between requests.
- **Leaner dependencies:** 3 production deps vs. 8+ in the Node.js version. No Express, Cheerio, or Pino.
- **More tools:** 37 vs. 33 — adds `senado_senador_detail`, `senado_search_votacoes`, `senado_search_processos`, `senado_votos_materia`.
- **Sophisticated caching:** Multi-layer (memory → Cache API → KV) vs. single-layer `node-cache`.
- **No npm distribution:** Deployed via `wrangler deploy`, not installable via `npx`.

---

## 5. Comparative Analysis

| Dimension | `mcp-senado` (Aredes) | `senado-br-mcp` (Bissoli) | `senado-br-mcp-cloudflare` (Bissoli) |
|---|---|---|---|
| **Tools** | 56 | 33 | 37 |
| **e-Cidadania** | No | Yes (11 tools, web scraping) | Yes (11 tools, direct fetch) |
| **Runtime** | Node.js 18+ | Node.js 18+ | Cloudflare Workers (ESM) |
| **Infrastructure** | Enterprise-grade (circuit breaker, LRU cache, token bucket, Prometheus metrics) | Standard (node-cache, basic rate limiting) | Multi-layer cache (L0 memory + L1 Cache API + L2 KV), token bucket, concurrency limiter |
| **Testing** | 211 tests, 73% coverage | Not specified | Not specified |
| **Deployment options** | 4 (stdio, HTTP, Docker, Cloudflare Workers) | 2 (stdio, HTTP via Railway) | 1 (Cloudflare Workers via `wrangler deploy`) |
| **Edge deployment** | Yes (Cloudflare Workers + Durable Objects) | No | Yes (Cloudflare Workers, stateless) |
| **LGPD compliance** | Explicit (PII masking) | Not mentioned | Not mentioned |
| **npm published** | Yes (`@aredes.me/mcp-senado`, ~568 downloads) | Yes (`senado-br-mcp`, ~45/week) | No (Workers-native) |
| **Cloud-hosted endpoint** | Not confirmed | Yes (Railway) | Yes (Cloudflare Workers) |
| **Registries** | Smithery, Glama | Glama, mcpservers.org, LobeHub, MCP Gallery JP | None yet |
| **Production deps** | Multiple (Pino, etc.) | 8+ (Express, Cheerio, Pino, node-cache, esbuild) | 3 (`@modelcontextprotocol/sdk`, `agents`, `zod`) |
| **Companion MCPs** | `mcp-dadosbr` (OSINT, 23 tools) | `ibge-br-mcp` (23 tools), `bcb-br-mcp` (8 tools) | Same ecosystem as `senado-br-mcp` |
| **Active in this environment** | No | Yes | No |

### Key Takeaway

The three MCPs represent different philosophies:

- **Aredes (`mcp-senado`)** prioritized **depth of infrastructure** — circuit breakers, edge deployment, observability, LGPD. Most tools (56), but no e-Cidadania. Built like a production backend service.
- **Bissoli (`senado-br-mcp`)** prioritized **breadth of coverage** — e-Cidadania (unique at the time), broader ecosystem (IBGE, BCB), and practical deployment (Railway cloud endpoint). Built like a data access layer.
- **Bissoli (`senado-br-mcp-cloudflare`)** is an **edge-native evolution** — same tool coverage as the Node.js version plus 4 extra tools, but rebuilt from scratch for Cloudflare Workers with a leaner dependency footprint (3 deps), multi-layer caching, and stateless per-request architecture. Trades npm portability for edge performance.

All three wrap the same underlying API: `https://legis.senado.leg.br/dadosabertos/`.

---

## 6. Adjacent MCP Ecosystem: Brazilian Legislative and Government Data

### 6.1. Camara dos Deputados (House of Representatives) — 3 MCPs found

| Project | Author | Language | Tools | Notes |
|---|---|---|---|---|
| [`AgenteCidadaoMCP`](https://github.com/gvc2000/AgenteCidadaoMCP) | gvc2000 | TypeScript | 57 | Production-grade: Zod, LRU cache, circuit breaker, Prometheus, Docker, Railway |
| [`mcp-camara`](https://github.com/vrtornisiello/mcp-camara) | vrtornisiello | Python | 6 | Minimal: uses `uv` package manager, generic endpoint caller |
| `mcp-camara-server` | thomaschi78 | TypeScript | ~10+ | LobeHub listing only; GitHub possibly private |

### 6.2. Federal Government Transparency

| Project | Author | Stars | Notes |
|---|---|---|---|
| [`mcp-portal-transparencia`](https://github.com/dutradotdev/mcp-portal-transparencia) | dutradotdev | **142** | Most popular Brazil gov MCP. Dynamic tool generation from Swagger/OpenAPI. Requires API key. |

### 6.3. Other Brazilian Data MCPs

| Project | Author | Scope |
|---|---|---|
| [`mcp-dadosbr`](https://github.com/cristianoaredes/mcp-dadosbr) | Aredes | CNPJ, CEP, courts, transparency, healthcare, finance (23 tools) |
| `ibge-br-mcp` | Bissoli | IBGE: geography, census, indicators (23 tools) |
| `bcb-br-mcp` | Bissoli | Central Bank: SELIC, IPCA, exchange rates (8 tools) |
| `brasil-api-mcp-server` | mauricio-cantu | BrasilAPI: CEP, banks, CNPJ, taxes |
| Brazilian Law Research MCP | pdmtt | Official law sources |
| MCP PJe Server | KlrCe | Electronic Judicial Process (PJe) |

### 6.4. Apify (Commercial)

- **Senado Noticias API** by `brasil-scrapers`: An Apify-hosted scraper for Senate news/videos/audio, exposed as an MCP endpoint. Requires Apify account. Not an open-source project.

---

## 7. Implications for the R Package

### 7.1. API Coverage Map

Combining what both MCPs cover, the full surface area of the Senate API that the R package should target is:

| Domain | Aredes | Bissoli (Node) | Bissoli (CF Workers) | R Package Target |
|---|---|---|---|---|
| Senators (list, search, details) | Yes (13 tools) | Yes (4 tools) | Yes (5 tools) | Yes |
| Legislative Matters (search, details, proceedings, texts) | Yes (12 tools) | Yes (5 tools) | Yes (4 tools) | Yes |
| Voting (plenary, nominal, by senator, by matter) | Yes (5 tools) | Yes (6 tools) | Yes (5 tools) | Yes |
| Committees (list, details, members, meetings) | Yes (5 tools) | Yes (4 tools) | Yes (5 tools) | Yes |
| Plenary Agenda | Yes (6 tools) | Yes (2 tools) | Yes (1 tool) | Yes |
| Reference Data (legislature, types, parties, UFs) | Yes (10 tools) | Yes (4 tools) | Yes (4 tools) | Yes |
| Processes (search, details) | No | Yes (2 tools) | Yes (2 tools) | Yes |
| e-Cidadania (consultations, ideas, events) | No | Yes (11 tools) | Yes (11 tools) | Yes |
| Parliamentary Blocs | No | No | No | Future |
| Legislation/Normas | No | No | No | Future |

### 7.2. Infrastructure Patterns to Adopt

From Aredes' architecture, the R package should implement:

- **Retry with exponential backoff** — the Senate API has undocumented rate limiting.
- **In-memory caching** — using `memoise` or `cachem` in R, equivalent to LRU cache.
- **User-agent header** — identify the package to the API.
- **Response normalization** — clean column names (snake_case), consistent types.

From Bissoli's Node.js architecture, the R package should consider:

- **e-Cidadania as a web scraping module** — separate from the REST API layer, with its own rate limiting.
- **Tiered cache TTL** — short for agendas/recent votes (15min), long for historical data (24h).

From Bissoli's Cloudflare Workers architecture, the R package should consider:

- **Multi-layer caching strategy** — L0 (fast, in-process) + L1 (shared/persistent) with SHA-256 keying.
- **Concurrency limiter** — cap on simultaneous upstream requests (max 6) to avoid overloading the Senate API.
- **Minimal dependency philosophy** — only 3 production deps; avoid bloating the R package with unnecessary imports.

### 7.3. What No MCP Solved (and the R Package Should)

All three MCPs return raw API responses with minimal transformation. The R package should add:

- **Tidy output** — all functions return tibbles with consistent snake_case column names.
- **Pagination handling** — transparent to the user.
- **Date parsing** — API returns dates as strings in various formats.
- **Factor encoding** — party names, vote types, matter types as factors.
- **Cross-referencing** — e.g., join senator codes across voting and biographical data.

### 7.4. Naming Convention Insight

All three MCPs use a `senado_*` prefix for all tools. This validates the R package's planned convention:

- `senado_senators()`, `senado_votes()`, `senado_matters()`, etc.
- Or shorter: `sen_senators()`, `sen_votes()`, `sen_matters()`.

---

## 8. Useful Resources

- **Official Senate API docs:** `https://legis.senado.leg.br/dadosabertos/docs/index.html`
- **Swagger UI:** `https://legis.senado.leg.br/dadosabertos/api-docs/swagger-ui/index.html`
- **Aredes MCP repo:** `https://github.com/cristianoaredes/mcp-senado`
- **Bissoli MCP repo (Node.js):** `https://github.com/SidneyBissoli/senado-br-mcp`
- **Bissoli MCP repo (Cloudflare Workers):** `https://github.com/SidneyBissoli/senado-br-mcp-cloudflare`
- **AgenteCidadaoMCP (Camara, reference):** `https://github.com/gvc2000/AgenteCidadaoMCP`
- **Portal Transparencia MCP (reference):** `https://github.com/dutradotdev/mcp-portal-transparencia`
