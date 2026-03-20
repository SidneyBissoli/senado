# Roadmap: Pacote R `senado`

**Projeto:** Pacote R para acesso a dados abertos do Senado Federal do Brasil  
**Repositório:** `github.com/SidneyBissoli/senado` *(a confirmar)*  
**Autor principal:** Sidney Bissoli  
**Início do projeto:** 23 de fevereiro de 2026  
**Última atualização deste documento:** 20 de março de 2026  

---

## Visão geral

Este documento é o **plano mestre** do pacote `senado`. Cada fase contém entregáveis obrigatórios, checklists acionáveis, distribuição de tarefas por ator e critérios de validação. A regra é simples: **a fase N+1 só começa quando 100% dos entregáveis da fase N estiverem concluídos**.

Ao final de cada fase, uma seção "Previsto vs. Realizado" será preenchida, comparando o que foi planejado com o que foi efetivamente implementado.

### Marcos do projeto

| Marco | Fase | Critério de conclusão |
|---|:-:|---|
| Decisão de construir o pacote | 00 | Landscape analysis concluída, decisão documentada |
| Primeiro `devtools::load_all()` funcional | 01 | Scaffolding completo, CI verde |
| Primeira função retornando dados reais | 02 | `senado_get()` operacional com retry/cache |
| Cobertura funcional completa (core) | 03 | Todas as funções core retornando tibbles |
| e-Cidadania operacional | 04 | Módulo de scraping com rate limiting |
| Features avançadas | 05 | Cross-referencing, modelo preditivo de aprovação |
| Cobertura de testes ≥ 90% | 06 | testthat + httptest2 + covr |
| Documentação publicação-ready | 07 | Vignettes + man pages + pkgdown |
| Repositório community-ready | 08 | CI/CD, README, CONTRIBUTING, CODE_OF_CONDUCT |
| 100+ estrelas no GitHub | 09 | Marketing executado |
| Aceito pelo rOpenSci | 10 | Revisão por pares concluída |
| Publicado no CRAN | 11 | `install.packages("senado")` funcional |
| Artigo publicado no The R Journal | 12 | Paper aceito e publicado |

### Atores e suas capacidades

| Ator | Sigla | Quando usar |
|---|:-:|---|
| **Sidney (humano)** | `HUM` | Decisões de design, revisão de código, validação de domínio, submissões oficiais (CRAN, rOpenSci), escrita acadêmica, networking |
| **Claude Code** | `CC` | Implementação de código R, testes, scaffolding, refactoring, debugging, geração de documentação roxygen2, scripts de automação |
| **Claude Desktop** | `CD` | Planejamento, análise de documentos, escrita de vignettes/artigos, revisão de texto, pesquisa de literatura |
| **Claude Cowork** | `CW` | Tarefas repetitivas de arquivo (batch rename, reorganização de pastas, geração de boilerplate), automação de workflows |
| **Claude Navegador** | `CN` | Pesquisa web (API docs, exemplos de outros pacotes, rOpenSci guidelines), testes de endpoints, verificação de links |

---

## Fase 00 — Exploração do cenário

**Status:** ✅ CONCLUÍDA  
**Período:** 23 de fevereiro de 2026  
**Objetivo:** Decidir se vale a pena construir um pacote R para dados do Senado Federal.

### Entregáveis

- [x] Mapeamento de pacotes R existentes (`congressbr`, `SenadoBR`, `senatebR`)
- [x] Análise detalhada do código-fonte do `senatebR` (clone + inspeção)
- [x] Mapeamento de MCP connectors existentes (`mcp-senado`, `senado-br-mcp`, `senado-br-mcp-cloudflare`)
- [x] Análise comparativa de arquitetura dos MCPs (infra, cobertura, deploy)
- [x] Teste empírico de volume de dados via API (95 votações em 2024)
- [x] Comparação de escala Senate vs. DATASUS
- [x] Documento consolidado: `03-landscape-analysis.md`
- [x] Decisão formal: **criar pacote novo do zero**

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Pesquisa de pacotes R existentes | `CD` + `CN` |
| Clone e análise do `senatebR` | `CC` |
| Pesquisa de MCPs no ecossistema | `CN` |
| Teste empírico da API | `CC` (via MCP senado-br-mcp) |
| Redação dos documentos de análise | `CD` |
| Decisão final | `HUM` |

### Validação

- [x] **Máquina (Claude):** Documentos revisados por consistência interna.
- [x] **Humano (Sidney):** Decisão de criar pacote novo aprovada.

### Previsto vs. Realizado

| Aspecto | Previsto | Realizado |
|---|---|---|
| Pacotes R existentes | 1–2 esperados | 3 encontrados (todos inviáveis) |
| MCPs existentes | Não esperávamos encontrar nenhum | 3 encontrados (rico em padrões de infra) |
| Volume de dados | Preocupação com escala semelhante ao healthbR | Escala radicalmente menor (~95 votações/ano) |
| Decisão | Criar novo ou contribuir | Criar novo (problemas dos existentes são arquiteturais) |
| Entregáveis extras | — | Mapa completo da API, padrões de infra a adotar |

### Lições aprendidas

1. Escala de dados determina a arquitetura — legislative data é ordens de grandeza menor que health data.
2. MCPs são fonte valiosa de padrões de infraestrutura (retry, cache, rate limiting) que o ecossistema R não implementou.
3. Contribuir com pacote existente pode custar mais do que criar do zero quando os problemas são arquiteturais.

---

## Fase 01 — Arquitetura e scaffolding do pacote

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 1 semana  
**Objetivo:** Criar a estrutura do pacote R com todas as convenções corretas, CI/CD básico e as decisões arquiteturais documentadas.

### Decisões arquiteturais a tomar

Antes de escrever código, as seguintes decisões devem ser formalizadas:

- [ ] **Nome do pacote:** `senado` (curto, limpo, memorizável — confirmar disponibilidade no CRAN)
- [ ] **Prefixo das funções:** `senado_` (ex: `senado_senators()`, `senado_votes()`) — consistente com convenção dos MCPs
- [ ] **Dependências core (mínimas):**
  - `httr2` (HTTP client moderno, substitui `httr` — retry, throttle, cache nativos)
  - `jsonlite` (parse JSON)
  - `xml2` (parse XML — a API do Senado retorna XML por padrão)
  - `rvest` (scraping e-Cidadania — apenas se módulo e-Cidadania for incluído)
  - `tibble` (saída tidy)
  - `cli` (mensagens e progress bars)
  - `rlang` (programação com tidyverse, tratamento de erros)
  - `memoise` ou `cachem` (cache em memória — avaliar qual é mais adequado)
- [ ] **Dependências sugeridas (Suggests):**
  - `testthat` (≥ 3.0.0)
  - `httptest2` (mock de requisições HTTP para testes)
  - `covr` (cobertura de testes)
  - `knitr`, `rmarkdown` (vignettes)
  - `withr` (gestão de estado em testes)
  - `dplyr` (exemplos nas vignettes)
  - `ggplot2` (exemplos nas vignettes)
- [ ] **Infraestrutura compartilhada:** decidir se `apigateway` será um pacote interno separado ou um módulo dentro de `senado` (recomendação: começar dentro de `senado` em `R/utils-api.R`, extrair depois se necessário)
- [ ] **Formato de saída:** todas as funções retornam `tibble` com colunas em `snake_case`
- [ ] **Licença:** MIT (consistente com ecossistema rOpenSci)
- [ ] **Versão mínima do R:** ≥ 4.1.0 (para suporte nativo ao pipe `|>`)

### Entregáveis

- [ ] Repositório GitHub criado e configurado (`senado`)
- [ ] `usethis::create_package("senado")` executado
- [ ] `DESCRIPTION` preenchido (Title, Description, Authors, License, Imports, Suggests, URL, BugReports, Roxygen, Config/testthat/edition)
- [ ] Estrutura de pastas criada:
  ```
  senado/
  ├── R/
  │   ├── senado-package.R        # Package-level documentation
  │   ├── utils-api.R             # senado_get(), retry, cache, user-agent
  │   ├── utils-parse.R           # Parsers XML/JSON, normalização de colunas
  │   ├── utils-validate.R        # Validação de inputs (anos, códigos, etc.)
  │   └── zzz.R                   # .onLoad, .onAttach
  ├── tests/
  │   └── testthat/
  │       ├── testthat.R
  │       └── helper.R            # Fixtures, skip_if_offline()
  ├── man/                        # Auto-gerado por roxygen2
  ├── vignettes/
  ├── inst/
  │   └── WORDLIST               # Para spell checking (rOpenSci)
  ├── .github/
  │   └── workflows/
  │       └── R-CMD-check.yaml   # GitHub Actions CI
  ├── .Rbuildignore
  ├── .gitignore
  ├── NAMESPACE
  ├── NEWS.md
  ├── README.md                  # Placeholder inicial
  ├── LICENSE.md
  └── senado.Rproj
  ```
- [ ] GitHub Actions configurado: R CMD check em ubuntu-latest, macOS-latest, windows-latest (R-release e R-devel)
- [ ] `.Rbuildignore` configurado (excluir `.github/`, `README.Rmd`, `data-raw/`, etc.)
- [ ] `usethis::use_testthat(3)` executado
- [ ] `usethis::use_roxygen_md()` ativado
- [ ] Primeiro `devtools::check()` passando com 0 errors, 0 warnings, 0 notes
- [ ] Documento de decisões arquiteturais salvo em `status/04-architecture-decisions.md`

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Verificar disponibilidade do nome `senado` no CRAN | `CN` |
| Criar repositório no GitHub | `HUM` |
| Executar scaffolding (`usethis::*`, `devtools::*`) | `CC` |
| Configurar GitHub Actions (R CMD check) | `CC` |
| Preencher DESCRIPTION | `CC` + `HUM` (revisão) |
| Criar estrutura de pastas e arquivos base | `CC` |
| Documentar decisões arquiteturais | `CD` |
| Primeiro `devtools::check()` | `CC` |
| Revisão e aprovação | `HUM` |

### Validação

- [ ] **Máquina (Claude):** `devtools::check()` com 0/0/0 (errors/warnings/notes).
- [ ] **Humano (Sidney):** Revisão das decisões arquiteturais e DESCRIPTION.

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Dependências core | 8 pacotes | |
| Tempo | 1 semana | |
| CI/CD | GitHub Actions R CMD check | |
| Decisões em aberto | Nenhuma | |

---

## Fase 02 — Camada de infraestrutura de acesso à API

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 1–2 semanas  
**Objetivo:** Implementar o `senado_get()` e toda a infraestrutura que garante robustez no acesso à API do Senado.

### Contexto técnico

A API do Senado (`legis.senado.leg.br/dadosabertos/`) possui características que exigem uma camada de infra robusta:

- Retorna **XML por padrão**, JSON apenas quando solicitado via query param `?formato=json` ou header `Accept: application/json`.
- **Rate limiting não documentado** — os MCPs implementaram token bucket e throttle por precaução.
- **Endpoints instáveis** — já quebraram o `congressbr` no passado.
- **Estrutura de resposta aninhada** — JSON com vários níveis de nesting, exigindo flatten.
- **Datas em formatos variados** — strings em múltiplos formatos.
- **Nomes de campos inconsistentes** — PascalCase, camelCase e snake_case misturados.

### Entregáveis

- [ ] **`R/utils-api.R`** — Função central `senado_get()`:
  - [ ] Construção de URL base + path + query params
  - [ ] Header `User-Agent: senado/{version} (https://github.com/SidneyBissoli/senado)`
  - [ ] Header `Accept: application/json` (preferir JSON quando disponível)
  - [ ] Retry com backoff exponencial (máx. 3 tentativas, backoff 1s → 2s → 4s)
  - [ ] Throttle: máx. 2 requisições/segundo (via `httr2::req_throttle()`)
  - [ ] Timeout: 30 segundos por requisição
  - [ ] Tratamento de erros HTTP (4xx, 5xx) com mensagens informativas via `cli`
  - [ ] Fallback automático XML → JSON (tentar JSON; se falhar, tentar XML)
  - [ ] Retorno: lista R parseada (JSON via `jsonlite`, XML via `xml2`)
- [ ] **`R/utils-cache.R`** — Sistema de cache:
  - [ ] Cache em memória via `cachem::cache_mem()` (ou `memoise`)
  - [ ] TTL configurável por tipo de dado:
    - Dados de referência (partidos, UFs, tipos de matéria): 24h
    - Dados semi-estáticos (lista de senadores da legislatura): 6h
    - Dados dinâmicos (votações recentes, agenda): 15min
  - [ ] Função `senado_cache_clear()` para limpar cache manualmente
  - [ ] Opção global `senado_use_cache` (TRUE/FALSE) via `options()`
- [ ] **`R/utils-parse.R`** — Normalização de respostas:
  - [ ] Flatten de JSON aninhado em tibble
  - [ ] Conversão de nomes de colunas para `snake_case` (via `snakecase::to_snake_case()` ou implementação própria)
  - [ ] Parse de datas (detecção automática de formato → `Date` ou `POSIXct`)
  - [ ] Conversão de tipos: character → numeric onde apropriado, campos lógicos (Sim/Não → TRUE/FALSE)
  - [ ] Tratamento de encoding (UTF-8)
- [ ] **`R/utils-validate.R`** — Validação de inputs:
  - [ ] Validação de ano (inteiro, ≥ 1991, ≤ ano atual)
  - [ ] Validação de código de senador (inteiro positivo)
  - [ ] Validação de sigla de partido (character, uppercase)
  - [ ] Validação de UF (character, 2 letras, uma das 27 UFs válidas)
  - [ ] Validação de código de matéria (inteiro positivo)
  - [ ] Mensagens de erro amigáveis via `cli::cli_abort()`
- [ ] **`R/zzz.R`** — Configuração on-load:
  - [ ] Variáveis de ambiente: `SENADO_API_BASE_URL`, `SENADO_CACHE_ENABLED`
  - [ ] Mensagem on-attach com versão e link para docs
- [ ] Testes unitários para toda a camada de infra:
  - [ ] `test-utils-api.R` — mock de requisições com `httptest2`
  - [ ] `test-utils-cache.R` — teste de TTL e limpeza
  - [ ] `test-utils-parse.R` — teste de normalização com fixtures JSON/XML reais
  - [ ] `test-utils-validate.R` — teste de validações
- [ ] `devtools::check()` passando com 0/0/0

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Implementar `senado_get()` | `CC` |
| Implementar sistema de cache | `CC` |
| Implementar parsers e normalização | `CC` |
| Implementar validações de input | `CC` |
| Capturar fixtures JSON/XML reais da API para testes | `CC` (via MCP) |
| Escrever testes unitários | `CC` |
| Testar manualmente contra API real | `HUM` + `CC` |
| Revisão de código | `HUM` |

### Validação

- [ ] **Máquina (Claude):** Todos os testes passando; `devtools::check()` 0/0/0; `senado_get("senador/lista/atual")` retorna tibble.
- [ ] **Humano (Sidney):** Testar `senado_get()` interativamente no RStudio contra 5+ endpoints diferentes; validar que retry funciona (ex: desconectar internet temporariamente).

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Funções de infra | 4 arquivos (api, cache, parse, validate) | |
| Tempo | 1–2 semanas | |
| Testes | 4 arquivos de teste | |
| Cobertura de testes (infra) | ≥ 80% | |

---

## Fase 03 — Funções de acesso a dados (módulos core)

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 2–3 semanas  
**Objetivo:** Implementar todas as funções de acesso aos endpoints core da API do Senado — senadores, matérias, votações, comissões, plenário e dados de referência.

### Princípios de design

1. **Uma função por ação semântica** (não por endpoint). Ex: `senado_senators()` agrega lista + filtro.
2. **Saída sempre em tibble** com colunas `snake_case`.
3. **Paginação transparente** — o usuário recebe todos os resultados sem saber que houve paginação.
4. **Parâmetros com nomes em inglês** (consistente com ecossistema R internacional).
5. **Valores default sensatos** — `year = current_year()`, `legislature = current_legislature()`.
6. **Progress bar** para operações que fazem múltiplas requisições (via `cli::cli_progress_bar()`).

### Módulo 3.1 — Dados de referência (`R/reference.R`)

- [ ] `senado_legislatures()` — Lista de legislaturas (número, datas, senadores)
- [ ] `senado_current_legislature()` — Legislatura atual (shortcut)
- [ ] `senado_parties()` — Partidos com representação no Senado
- [ ] `senado_states()` — UFs com senadores
- [ ] `senado_bill_types()` — Tipos de matéria legislativa (PEC, PL, PLS, etc.)
- [ ] `senado_proceeding_types()` — Tipos de tramitação

### Módulo 3.2 — Senadores (`R/senators.R`)

- [ ] `senado_senators()` — Lista de senadores (com filtros: legislature, state, party, status)
- [ ] `senado_senator()` — Detalhes de um senador por código
- [ ] `senado_senator_votes()` — Votações nominais de um senador
- [ ] `senado_senator_bills()` — Matérias de autoria de um senador
- [ ] `senado_senator_committees()` — Comissões de que um senador é membro
- [ ] `senado_senator_mandates()` — Histórico de mandatos

### Módulo 3.3 — Matérias legislativas (`R/bills.R`)

- [ ] `senado_bills()` — Busca de matérias (com filtros: year, type, author, keyword, status)
- [ ] `senado_bill()` — Detalhes de uma matéria por código
- [ ] `senado_bill_text()` — Texto(s) da matéria (inteiro teor, emendas, substitutivos)
- [ ] `senado_bill_proceedings()` — Tramitação detalhada (timeline)
- [ ] `senado_bill_votes()` — Votações relacionadas à matéria
- [ ] `senado_bill_authors()` — Autores e coautores

### Módulo 3.4 — Votações (`R/votes.R`)

- [ ] `senado_votes()` — Lista de votações (com filtros: year, date_range, bill_type)
- [ ] `senado_vote()` — Detalhes de uma votação por código
- [ ] `senado_vote_roll_call()` — Votos nominais (quem votou o quê)
- [ ] `senado_recent_votes()` — Votações dos últimos N dias

### Módulo 3.5 — Comissões (`R/committees.R`)

- [ ] `senado_committees()` — Lista de comissões (com filtro: type = permanent/temporary)
- [ ] `senado_committee()` — Detalhes de uma comissão
- [ ] `senado_committee_members()` — Membros de uma comissão
- [ ] `senado_committee_meetings()` — Reuniões agendadas/realizadas

### Módulo 3.6 — Plenário e agenda (`R/plenary.R`)

- [ ] `senado_agenda()` — Agenda do plenário (com filtros: date, date_range)
- [ ] `senado_sessions()` — Sessões plenárias realizadas

### Entregáveis consolidados

- [ ] 6 arquivos R implementados (reference, senators, bills, votes, committees, plenary)
- [ ] Todas as funções com documentação roxygen2 completa (@title, @description, @param, @return, @examples, @export, @family)
- [ ] Exemplos executáveis em `@examples` (com `\dontrun{}` para chamadas à API)
- [ ] Testes unitários com mocks (`httptest2`) para cada função
- [ ] Testes de integração (marcados com `skip_on_cran()`) contra API real
- [ ] `devtools::check()` passando com 0/0/0
- [ ] Cobertura de testes ≥ 80% (core functions)

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Mapear endpoints da API para cada função (Swagger UI) | `CN` + `CD` |
| Implementar módulos 3.1–3.6 | `CC` |
| Capturar fixtures de resposta da API para cada endpoint | `CC` (via MCP) |
| Escrever testes unitários (mocks) | `CC` |
| Escrever testes de integração | `CC` |
| Testar interativamente cada função no RStudio | `HUM` |
| Validar que saída é tidy (snake_case, tipos corretos) | `HUM` |
| Revisão de código | `HUM` |

### Validação

- [ ] **Máquina (Claude):** Todos os testes passando; `devtools::check()` 0/0/0; cobertura ≥ 80%.
- [ ] **Humano (Sidney):** Testar cada função interativamente com dados reais; validar que os tibbles de saída são corretos, completos e tidy.

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Funções exportadas (core) | ~26 funções | |
| Arquivos R | 6 módulos | |
| Tempo | 2–3 semanas | |
| Cobertura de testes | ≥ 80% | |

---

## Fase 04 — Módulo e-Cidadania

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 1–2 semanas  
**Objetivo:** Implementar acesso à plataforma e-Cidadania do Senado (consultas públicas, ideias legislativas, eventos interativos) — funcionalidade que **nenhum pacote R existente oferece**.

### Contexto técnico

Os endpoints de e-Cidadania **não fazem parte da API REST oficial** do Senado. Requerem web scraping do portal `https://www12.senado.leg.br/ecidadania/`. Isso implica:

- Rate limiting rigoroso (máx. 1 req/seg — padrão adotado pelos MCPs de Bissoli).
- Parsing de HTML via `rvest`.
- Maior fragilidade (HTML pode mudar sem aviso — diferente de API versionada).
- Necessidade de testes mais robustos e monitoramento.

### Entregáveis

- [ ] **`R/ecidadania.R`** — Funções de acesso:
  - [ ] `senado_consultations()` — Consultas públicas (com filtros: status, theme, date_range)
  - [ ] `senado_consultation()` — Detalhes de uma consulta (votos sim/não, total)
  - [ ] `senado_ideas()` — Ideias legislativas (com filtros: status, keyword, sort_by)
  - [ ] `senado_idea()` — Detalhes de uma ideia (apoios, status)
  - [ ] `senado_events()` — Eventos interativos (audiências públicas, sabatinas, lives)
  - [ ] `senado_event()` — Detalhes de um evento
- [ ] **`R/utils-scrape.R`** — Infraestrutura de scraping:
  - [ ] Rate limiter dedicado (1 req/seg, separado do throttle da API REST)
  - [ ] User-agent e headers adequados
  - [ ] Retry com backoff para erros de scraping
  - [ ] Validação de estrutura HTML (detectar mudanças no layout)
- [ ] Testes com fixtures HTML salvas (snapshots do portal)
- [ ] Documentação roxygen2 com aviso de que estes dados vêm de scraping (menor estabilidade)
- [ ] `devtools::check()` passando com 0/0/0

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Mapear estrutura HTML do portal e-Cidadania | `CN` |
| Implementar funções de scraping | `CC` |
| Implementar infra de scraping (rate limit, retry) | `CC` |
| Capturar fixtures HTML para testes | `CN` + `CC` |
| Escrever testes | `CC` |
| Testar interativamente | `HUM` |

### Validação

- [ ] **Máquina (Claude):** Testes passando; `devtools::check()` 0/0/0.
- [ ] **Humano (Sidney):** Validar dados de e-Cidadania contra portal web manualmente (amostra de 10 consultas/ideias).

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Funções exportadas (e-Cidadania) | ~6–8 funções | |
| Tempo | 1–2 semanas | |
| Rate limit | 1 req/seg | |

---

## Fase 05 — Features avançadas

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 2–3 semanas  
**Objetivo:** Implementar funcionalidades que **nenhum produto existente oferece** — cross-referencing de dados, datasets pré-construídos e modelo preditivo de aprovação de matérias.

### Módulo 5.1 — Cross-referencing e data augmentation (`R/augment.R`)

- [ ] `senado_senator_profile()` — Perfil consolidado de um senador: dados biográficos + comissões + votações + matérias de autoria, tudo em uma lista nomeada de tibbles
- [ ] `senado_bill_timeline()` — Timeline completa de uma matéria: autoria → tramitação → votações → resultado, em tibble com coluna `event_type`
- [ ] `senado_party_cohesion()` — Índice de coesão partidária por votação ou período (% de votos alinhados com a maioria do partido)
- [ ] `senado_vote_matrix()` — Matriz de votação (senadores × votações) em formato wide, pronta para análise (NOMINATE, ideal points)
- [ ] `senado_attendance()` — Taxa de presença por senador/período

### Módulo 5.2 — Dados pré-construídos (`data-raw/` e `data/`)

- [ ] `senado_historical_senators` — Dataset com todos os senadores desde 1991 (tibble no pacote)
- [ ] `senado_historical_votes` — Dataset com todas as votações nominais desde 1991
- [ ] Scripts de geração em `data-raw/` (reprodutíveis, documentados)
- [ ] Documentação de cada dataset em `R/data.R`

### Módulo 5.3 — Modelo preditivo de aprovação (`R/predict.R`)

**Nota:** Este módulo é experimental e ambicioso. Pode ser movido para um pacote-satélite se a complexidade for excessiva.

- [ ] `senado_predict_approval()` — Estima a probabilidade de aprovação de uma matéria com base em:
  - Tipo de matéria (PEC, PL, PLS — PECs têm quórum qualificado)
  - Partido do autor vs. composição atual do Senado
  - Histórico de aprovação por tipo/tema
  - Número de coautores
  - Tempo em tramitação
  - Relator designado (se houver)
  - Resultado em comissões (se aplicável)
- [ ] Modelo: regressão logística ou random forest (dependências em Suggests: `stats` para glm ou `ranger` para RF)
- [ ] Função retorna tibble com colunas: `bill_code`, `probability`, `confidence_interval_lower`, `confidence_interval_upper`, `features_used`
- [ ] Vignette dedicada explicando a metodologia e limitações

### Módulo 5.4 — Limpeza e manipulação (`R/clean.R`)

- [ ] `senado_clean_names()` — Wrapper para normalizar nomes de colunas de qualquer output (já feito internamente, mas exposto para usuário avançado)
- [ ] `senado_merge_votes()` — Merge entre votações e dados biográficos dos senadores (join por código)
- [ ] `senado_pivot_votes()` — Pivota votos nominais de long → wide (matriz senador × votação)

### Entregáveis consolidados

- [ ] 4 arquivos R implementados (augment, data, predict, clean)
- [ ] Datasets pré-construídos em `data/` com documentação
- [ ] Scripts reprodutíveis em `data-raw/`
- [ ] Testes para todas as funções
- [ ] `devtools::check()` passando com 0/0/0

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Implementar cross-referencing | `CC` |
| Gerar datasets históricos | `CC` (via API) |
| Modelagem do preditor de aprovação | `CD` (design) + `CC` (implementação) |
| Validação estatística do modelo preditivo | `HUM` |
| Testes | `CC` |
| Revisão de código e metodologia | `HUM` |

### Validação

- [ ] **Máquina (Claude):** Testes passando; datasets reprodutíveis; modelo preditivo com AUC > 0.65 em validação cruzada.
- [ ] **Humano (Sidney):** Validar cross-referencing manualmente (amostra); revisar metodologia do modelo preditivo.

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Funções exportadas (avançadas) | ~12 funções | |
| Datasets pré-construídos | 2 | |
| Modelo preditivo | AUC > 0.65 | |
| Tempo | 2–3 semanas | |

---

## Fase 06 — Testes e quality assurance

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 1–2 semanas  
**Objetivo:** Atingir cobertura de testes ≥ 90%, implementar CI completo e garantir qualidade de código.

### Entregáveis

- [ ] **Cobertura de testes ≥ 90%** (via `covr::package_coverage()`)
- [ ] **Testes unitários** para todas as funções exportadas (com mocks via `httptest2`)
- [ ] **Testes de integração** (marcados com `skip_on_cran()`, `skip_if_offline()`)
- [ ] **Testes de snapshot** para outputs tidy (detectar mudanças na API)
- [ ] **Lint** com `lintr` — 0 warnings
- [ ] **Spell check** com `spelling::spell_check_package()` — 0 erros (WORDLIST atualizado)
- [ ] **GitHub Actions expandido:**
  - [ ] R CMD check (3 OS × 2 R versions)
  - [ ] Cobertura de testes com upload para Codecov
  - [ ] Lint check
  - [ ] Spell check
- [ ] **Badges** no README: R CMD check, codecov, CRAN status, lifecycle
- [ ] `devtools::check()` passando com 0/0/0 em todos os OS

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Completar testes para cobertura ≥ 90% | `CC` |
| Configurar GitHub Actions expandido | `CC` |
| Configurar Codecov | `HUM` (conta) + `CC` (workflow) |
| Executar `lintr` e corrigir | `CC` |
| Spell check e WORDLIST | `CC` + `HUM` (revisão) |
| Teste cross-platform (Windows) | `HUM` (RStudio local) |

### Validação

- [ ] **Máquina (Claude):** `covr::package_coverage()` ≥ 90%; `lintr` 0 warnings; `spelling` 0 erros; CI verde em todos os OS.
- [ ] **Humano (Sidney):** Executar `devtools::check()` localmente no Windows.

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Cobertura de testes | ≥ 90% | |
| CI/CD | 3 OS × 2 R versions + codecov + lint + spell | |
| Tempo | 1–2 semanas | |

---

## Fase 07 — Documentação e vignettes

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 2 semanas  
**Objetivo:** Produzir documentação de qualidade publicação — man pages completas, vignettes pedagógicas e site pkgdown profissional.

### Entregáveis

- [ ] **Man pages** (roxygen2) completas para todas as funções exportadas, com:
  - @title, @description, @param, @return, @examples, @seealso, @family
  - Exemplos que rodam (`\dontrun{}` apenas para chamadas à API)
- [ ] **Vignette 1:** "Getting started with senado" — instalação, autenticação (não requer), primeira query, estrutura de outputs
- [ ] **Vignette 2:** "Analyzing Senate votes" — votações nominais, coesão partidária, matrizes de votação, visualizações com ggplot2
- [ ] **Vignette 3:** "Tracking legislation" — busca de matérias, tramitação, timeline, modelo preditivo
- [ ] **Vignette 4:** "Citizen participation: e-Cidadania" — consultas públicas, ideias legislativas, eventos
- [ ] **Vignette 5:** "API infrastructure" — cache, retry, rate limiting, como o pacote funciona por dentro (para desenvolvedores)
- [ ] **README.Rmd** completo com:
  - Badge de CI, codecov, CRAN, lifecycle
  - Descrição curta e motivação
  - Instalação (GitHub e CRAN)
  - Exemplo mínimo funcional (copy-paste-run)
  - Tabela de funções por categoria
  - Link para pkgdown
- [ ] **NEWS.md** com changelog por versão
- [ ] **pkgdown site** configurado e deployado via GitHub Pages
- [ ] **`CONTRIBUTING.md`** com guidelines de contribuição
- [ ] **`CODE_OF_CONDUCT.md`** (Contributor Covenant)

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Completar man pages (roxygen2) | `CC` |
| Escrever vignettes 1–5 | `CD` (rascunho) + `HUM` (revisão) |
| Criar README.Rmd | `CC` (estrutura) + `CD` (texto) |
| Configurar pkgdown | `CC` |
| Deploy pkgdown no GitHub Pages | `CC` |
| CONTRIBUTING.md e CODE_OF_CONDUCT.md | `CD` |
| Revisão final de toda a documentação | `HUM` |

### Validação

- [ ] **Máquina (Claude):** Todas as vignettes renderizam sem erros; pkgdown build sem erros; links válidos.
- [ ] **Humano (Sidney):** Leitura completa de todas as vignettes como se fosse um usuário novato.

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Vignettes | 5 | |
| pkgdown site | Sim | |
| Tempo | 2 semanas | |

---

## Fase 08 — Repositório community-ready

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 1 semana  
**Objetivo:** Preparar o repositório para receber contribuições externas e ser avaliado por revisores (rOpenSci, CRAN).

### Entregáveis

- [ ] **Issue templates** no GitHub (bug report, feature request)
- [ ] **PR template** no GitHub
- [ ] **Labels** configuradas (bug, enhancement, documentation, good first issue, help wanted)
- [ ] **GitHub Discussions** habilitado
- [ ] **Branch protection** em `main` (require PR review, require CI pass)
- [ ] **Semantic versioning** implementado (v0.1.0 como primeira release)
- [ ] **GitHub Release** criada com release notes
- [ ] **`cran-comments.md`** preparado (rascunho para submissão futura ao CRAN)
- [ ] **Revisão final da DESCRIPTION** (todos os campos preenchidos corretamente para rOpenSci e CRAN)
- [ ] **`codemeta.json`** gerado via `codemetar::write_codemeta()`
- [ ] Verificação: `goodpractice::gp()` com 0 issues críticos

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Configurar templates de issue/PR | `CC` |
| Configurar labels e Discussions | `HUM` (GitHub UI) |
| Branch protection | `HUM` (GitHub UI) |
| Criar release v0.1.0 | `HUM` + `CC` |
| Gerar codemeta.json | `CC` |
| Executar goodpractice::gp() e corrigir | `CC` |
| Revisão final | `HUM` |

### Validação

- [ ] **Máquina (Claude):** `goodpractice::gp()` sem issues críticos; `codemetar::write_codemeta()` gerado.
- [ ] **Humano (Sidney):** Navegar no repositório como se fosse um visitante externo — tudo claro e convidativo?

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Versão release | v0.1.0 | |
| goodpractice issues | 0 críticos | |
| Tempo | 1 semana | |

---

## Fase 09 — Divulgação e marketing

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 2–4 semanas (contínuo, em paralelo com fase 10)  
**Objetivo:** Atingir 100+ estrelas no GitHub e maximizar visibilidade na comunidade R e ciência política brasileira.

### Estratégia de divulgação

A divulgação segue uma lógica de **ondas concêntricas**: primeiro círculos técnicos pequenos, depois comunidades maiores, depois mídia acadêmica.

### Entregáveis — Onda 1: Comunidade R (semana 1)

- [ ] Post no **R-bloggers** (via blog pessoal com RSS feed)
- [ ] Post no **r/rstats** (Reddit)
- [ ] Post no **Mastodon** (hashtags #rstats, #OpenData, #BrazilianPolitics)
- [ ] Post no **Twitter/X** (hashtags #rstats, #DadosAbertos, #SenadoFederal)
- [ ] Toot na **Fosstodon** (instância Mastodon focada em open source)
- [ ] Post no **LinkedIn** (perfil pessoal)
- [ ] Menção no **R Weekly** (submeter link via GitHub issue no repo do R Weekly)
- [ ] Menção no **R4DS Slack** (canal #general ou #packages)

### Entregáveis — Onda 2: Ciência política e dados abertos (semana 2)

- [ ] Email para **lista de discussão da ABCP** (Associação Brasileira de Ciência Política)
- [ ] Post na **comunidade de dados abertos do Brasil** (Dados Abertos BR)
- [ ] Email para autores dos pacotes anteriores (`congressbr`, `senatebR`) informando sobre o novo pacote e convidando para contribuir
- [ ] Contato com **Laboratório de Análise Política** (UFMG, UnB, USP) que usam dados legislativos
- [ ] Post no **DataSenado** (canal interno — Sidney tem acesso)
- [ ] Post em grupos de **R no Telegram** (R Brasil, R para Ciência de Dados)

### Entregáveis — Onda 3: Apresentações e workshops (semana 3–4)

- [ ] Proposta de **lightning talk** para o próximo **R Day** ou **SER (Seminário de Estatística com R)**
- [ ] **Tutorial/workshop** gravado (vídeo de 15–20 min) demonstrando o pacote — publicar no YouTube
- [ ] **Gist/notebook** demonstrativo no GitHub com análise real usando o pacote (ex: "Coesão partidária no Senado em 2025")
- [ ] Submissão de proposta para **useR!** ou **LatinR** (se timing coincidir)

### Métricas de sucesso

| Métrica | Meta |
|---|---|
| Estrelas no GitHub | ≥ 100 |
| Downloads mensais (após CRAN) | ≥ 200 |
| Forks | ≥ 10 |
| Issues abertas por terceiros | ≥ 5 |
| Citações em blogs/artigos | ≥ 3 |

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Redigir posts para redes sociais e blogs | `CD` (rascunho) + `HUM` (publicação) |
| Submeter ao R-bloggers e R Weekly | `HUM` |
| Emails para comunidades acadêmicas | `HUM` |
| Gravar vídeo tutorial | `HUM` |
| Criar notebook demonstrativo | `CC` + `CD` |
| Submissões para conferências | `HUM` |

### Validação

- [ ] **Humano (Sidney):** Monitorar métricas semanalmente; ajustar estratégia conforme resposta.

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Estrelas GitHub | ≥ 100 | |
| Posts publicados | ~10 | |
| Workshops/talks | ≥ 1 | |
| Tempo | 2–4 semanas | |

---

## Fase 10 — Submissão ao rOpenSci

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 4–8 semanas (inclui tempo de revisão por pares)  
**Objetivo:** Ter o pacote aceito pela comunidade rOpenSci, passando pela revisão por pares e atendendo a todos os critérios de qualidade.

### Pré-requisitos (verificar antes de submeter)

- [ ] Pacote se encaixa no escopo do rOpenSci (dados governamentais abertos — sim, é escopo)
- [ ] `goodpractice::gp()` sem issues críticos
- [ ] `devtools::check()` 0/0/0
- [ ] Cobertura de testes ≥ 90%
- [ ] Pelo menos 2 vignettes
- [ ] pkgdown site funcional
- [ ] README completo
- [ ] CONTRIBUTING.md e CODE_OF_CONDUCT.md presentes
- [ ] `codemeta.json` presente
- [ ] Todas as funções documentadas
- [ ] Nenhuma dependência pesada ou desnecessária
- [ ] Licença compatível (MIT — ok)

### Entregáveis

- [ ] **Pre-submission inquiry** no repositório `ropensci/software-review` (issue com template)
- [ ] **Resposta positiva** do editor do rOpenSci (pacote está no escopo)
- [ ] **Submissão formal** (issue com template completo)
- [ ] **Endereçar revisão do Reviewer 1** — commits com respostas ponto a ponto
- [ ] **Endereçar revisão do Reviewer 2** — commits com respostas ponto a ponto
- [ ] **Aprovação do editor**
- [ ] **Transfer do repositório** para organização rOpenSci (se aplicável) ou badge no README
- [ ] Atualização do DESCRIPTION com `rOpenSci` badge e agradecimento

### Preparação para rOpenSci — Checklist adicional (baseado em rOpenSci Dev Guide)

- [ ] Funções têm nomes intuitivos e documentação clara
- [ ] Pacote não duplica funcionalidade existente no rOpenSci (não há pacote rOpenSci para Senado)
- [ ] Mensagens de erro são informativas (via `cli`)
- [ ] Pacote tem failsafe para quando API está offline (`try`/`tryCatch` + mensagens)
- [ ] `httr2` usado corretamente (não `httr`)
- [ ] Outputs são tibbles (não data.frames genéricos)
- [ ] Testes usam `httptest2` para mocks (não dependem de internet)
- [ ] Vignettes podem ser pre-built (não dependem de internet para build no CRAN)

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Preencher template de pre-submission inquiry | `CD` + `HUM` |
| Submeter pre-submission | `HUM` (GitHub issue) |
| Preencher template de submissão formal | `CD` + `HUM` |
| Submeter formalmente | `HUM` (GitHub issue) |
| Endereçar revisões (código) | `CC` |
| Endereçar revisões (documentação) | `CD` |
| Responder reviewers (texto) | `HUM` |
| Transfer/badge | `HUM` |

### Validação

- [ ] **Máquina (Claude):** Todos os pontos do dev guide checados automaticamente.
- [ ] **Humano (Sidney):** Leitura do dev guide; resposta pessoal aos reviewers.

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Tempo até aprovação | 4–8 semanas | |
| Rodadas de revisão | 2 | |
| Mudanças substanciais requeridas | Espera-se poucas | |

---

## Fase 11 — Publicação no CRAN

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 1–2 semanas (após aprovação rOpenSci)  
**Objetivo:** Publicar o pacote no CRAN, tornando-o instalável via `install.packages("senado")`.

### Pré-requisitos (rOpenSci já garante a maioria)

- [ ] `devtools::check()` 0/0/0 (inclusive em `--as-cran`)
- [ ] `R CMD check` passando em R-devel
- [ ] Todos os exemplos rodando (ou protegidos com `\dontrun{}` / `\donttest{}`)
- [ ] Vignettes pre-built (não dependem de internet)
- [ ] `cran-comments.md` atualizado com resultados dos checks
- [ ] `NEWS.md` atualizado
- [ ] Versão no DESCRIPTION: `0.1.0` (primeira submissão)
- [ ] URLs no DESCRIPTION testadas (nenhuma quebrada)
- [ ] `urlchecker::url_check()` passando

### Entregáveis

- [ ] **`devtools::submit_cran()`** executado
- [ ] **Resposta ao email do CRAN** (se houver solicitação de alteração)
- [ ] **Pacote aceito e disponível no CRAN**
- [ ] **Atualizar README** com badge do CRAN e instruções de instalação via `install.packages()`
- [ ] **Atualizar pkgdown** com versão CRAN

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Final `devtools::check(args = "--as-cran")` | `CC` + `HUM` |
| Preparar `cran-comments.md` | `CC` |
| Executar `devtools::submit_cran()` | `HUM` |
| Responder ao CRAN (se necessário) | `HUM` |
| Atualizar README e pkgdown | `CC` |

### Validação

- [ ] **Máquina (Claude):** `install.packages("senado")` funcional em R limpo.
- [ ] **Humano (Sidney):** Testar instalação do CRAN em máquina limpa (ou Docker).

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Tempo até publicação | 1–2 semanas | |
| Rodadas de revisão CRAN | 1–2 | |
| Versão publicada | 0.1.0 | |

---

## Fase 12 — Artigo no The R Journal

**Status:** 🔲 NÃO INICIADA  
**Período previsto:** 6–10 semanas  
**Objetivo:** Publicar um artigo descritivo do pacote no The R Journal, consolidando a contribuição acadêmica.

### Estrutura do artigo (baseada no template do The R Journal)

1. **Introduction** — Contexto: dados legislativos abertos no Brasil, lacuna nos pacotes R existentes, motivação.
2. **Background** — Breve revisão do ecossistema: `congressbr` (morto), `senatebR` (problemas arquiteturais), MCPs (inspiração de infra).
3. **Package design** — Decisões arquiteturais: `senado_get()`, camada de cache, parsing tidy, minimal dependencies.
4. **Usage examples** — Demonstrações com dados reais:
   - Listar senadores e votações.
   - Construir matriz de votação nominal.
   - Calcular coesão partidária.
   - Consultar e-Cidadania.
   - Modelo preditivo de aprovação (se implementado).
5. **Comparison with existing tools** — Tabela comparativa com `congressbr`, `senatebR`, e MCPs.
6. **Infrastructure details** — Cache, retry, rate limiting, scraping e-Cidadania.
7. **Conclusion and future work** — Blocos parlamentares, legislação, integração com Câmara, `apigateway`.

### Entregáveis

- [ ] **Rascunho completo** do artigo em formato R Journal (LaTeX ou Quarto)
- [ ] **Figuras e tabelas** reprodutíveis (código no artigo)
- [ ] **Revisão interna** por Sidney
- [ ] **Revisão por pelo menos 1 colega** (co-autor ou revisor informal)
- [ ] **Submissão ao The R Journal** via sistema de submissão oficial
- [ ] **Endereçar revisões** dos revisores do R Journal
- [ ] **Artigo aceito e publicado**

### Distribuição de tarefas

| Tarefa | Ator |
|---|---|
| Estruturar artigo (outline detalhado) | `CD` |
| Redigir seções 1–3 (introdução, background, design) | `CD` + `HUM` |
| Redigir seção 4 (usage examples — código) | `CC` (código) + `CD` (texto) |
| Redigir seções 5–7 (comparação, infra, conclusão) | `CD` + `HUM` |
| Gerar figuras e tabelas | `CC` |
| Formatar em template R Journal | `CC` + `CD` |
| Revisão interna | `HUM` |
| Solicitar revisão a colega | `HUM` |
| Submeter ao R Journal | `HUM` |
| Endereçar revisões | `HUM` + `CD` |

### Validação

- [ ] **Máquina (Claude):** Todo código no artigo é reprodutível; LaTeX/Quarto compila sem erros.
- [ ] **Humano (Sidney):** Leitura crítica completa; revisão por colega externo.

### Previsto vs. Realizado

*A ser preenchido ao final da fase.*

| Aspecto | Previsto | Realizado |
|---|---|---|
| Tempo até submissão | 6–10 semanas | |
| Rodadas de revisão | 1–2 | |
| Co-autores | A definir | |

---

## Apêndice A — Mapa completo de funções planejadas

| Módulo | Função | Fase | Endpoint API / Fonte |
|---|---|---|---|
| **Reference** | `senado_legislatures()` | 03 | REST `/legislatura` |
| | `senado_current_legislature()` | 03 | REST `/legislatura/atual` |
| | `senado_parties()` | 03 | REST `/partidos` |
| | `senado_states()` | 03 | REST `/ufs` |
| | `senado_bill_types()` | 03 | REST `/tipos-materia` |
| | `senado_proceeding_types()` | 03 | REST `/tipos-tramitacao` |
| **Senators** | `senado_senators()` | 03 | REST `/senador/lista` |
| | `senado_senator()` | 03 | REST `/senador/{codigo}` |
| | `senado_senator_votes()` | 03 | REST `/senador/{codigo}/votacoes` |
| | `senado_senator_bills()` | 03 | REST `/senador/{codigo}/materias` |
| | `senado_senator_committees()` | 03 | REST `/senador/{codigo}/comissoes` |
| | `senado_senator_mandates()` | 03 | REST `/senador/{codigo}/mandatos` |
| **Bills** | `senado_bills()` | 03 | REST `/materia/pesquisa` |
| | `senado_bill()` | 03 | REST `/materia/{codigo}` |
| | `senado_bill_text()` | 03 | REST `/materia/{codigo}/textos` |
| | `senado_bill_proceedings()` | 03 | REST `/materia/{codigo}/tramitacao` |
| | `senado_bill_votes()` | 03 | REST `/materia/{codigo}/votacoes` |
| | `senado_bill_authors()` | 03 | REST `/materia/{codigo}/autores` |
| **Votes** | `senado_votes()` | 03 | REST `/votacao/lista` |
| | `senado_vote()` | 03 | REST `/votacao/{codigo}` |
| | `senado_vote_roll_call()` | 03 | REST `/votacao/{codigo}/votos` |
| | `senado_recent_votes()` | 03 | REST `/votacao/recentes` |
| **Committees** | `senado_committees()` | 03 | REST `/comissao/lista` |
| | `senado_committee()` | 03 | REST `/comissao/{codigo}` |
| | `senado_committee_members()` | 03 | REST `/comissao/{codigo}/membros` |
| | `senado_committee_meetings()` | 03 | REST `/comissao/{codigo}/reunioes` |
| **Plenary** | `senado_agenda()` | 03 | REST `/agenda/plenario` |
| | `senado_sessions()` | 03 | REST `/sessao/lista` |
| **e-Cidadania** | `senado_consultations()` | 04 | Scraping e-Cidadania |
| | `senado_consultation()` | 04 | Scraping e-Cidadania |
| | `senado_ideas()` | 04 | Scraping e-Cidadania |
| | `senado_idea()` | 04 | Scraping e-Cidadania |
| | `senado_events()` | 04 | Scraping e-Cidadania |
| | `senado_event()` | 04 | Scraping e-Cidadania |
| **Augment** | `senado_senator_profile()` | 05 | Composição (múltiplos endpoints) |
| | `senado_bill_timeline()` | 05 | Composição (múltiplos endpoints) |
| | `senado_party_cohesion()` | 05 | Cálculo (votos + senadores) |
| | `senado_vote_matrix()` | 05 | Pivot (votos nominais) |
| | `senado_attendance()` | 05 | Cálculo (sessões + presenças) |
| **Clean** | `senado_clean_names()` | 05 | Interno |
| | `senado_merge_votes()` | 05 | Join (votos + senadores) |
| | `senado_pivot_votes()` | 05 | Pivot (long → wide) |
| **Predict** | `senado_predict_approval()` | 05 | Modelo estatístico |
| **Data** | `senado_historical_senators` | 05 | Dataset estático |
| | `senado_historical_votes` | 05 | Dataset estático |

**Total: ~43 funções exportadas + 2 datasets**

---

## Apêndice B — Dependências finais planejadas

### Imports (instaladas automaticamente)

| Pacote | Uso | Justificativa |
|---|---|---|
| `httr2` | HTTP client | Retry, throttle, cache nativos; substituto moderno do `httr` |
| `jsonlite` | Parse JSON | Standard, leve, sem dependências pesadas |
| `xml2` | Parse XML | API do Senado retorna XML por padrão |
| `rvest` | Scraping HTML | e-Cidadania (não faz parte da API REST) |
| `tibble` | Saída tidy | Consistência com ecossistema tidyverse |
| `cli` | Mensagens e progress | UX profissional, padrão rOpenSci |
| `rlang` | Programação tidy | Tratamento de erros, NSE |
| `cachem` | Cache em memória | LRU cache com TTL; usado pelo `memoise` |

### Suggests (instaladas apenas para dev/teste/docs)

| Pacote | Uso |
|---|---|
| `testthat` (≥ 3.0.0) | Framework de testes |
| `httptest2` | Mock de requisições HTTP |
| `covr` | Cobertura de testes |
| `knitr` | Vignettes |
| `rmarkdown` | Vignettes |
| `withr` | Gestão de estado em testes |
| `spelling` | Spell check |
| `dplyr` | Exemplos nas vignettes |
| `ggplot2` | Exemplos nas vignettes |
| `ranger` | Modelo preditivo (se implementado via RF) |

**Filosofia: minimal dependencies.** O pacote core terá ~8 imports — comparado com as dezenas de dependências do `senatebR` (que importava `spacyr`, `quanteda`, `stm`, etc.).

---

## Apêndice C — Referências e recursos

### API do Senado
- Documentação oficial: `https://legis.senado.leg.br/dadosabertos/docs/index.html`
- Swagger UI: `https://legis.senado.leg.br/dadosabertos/api-docs/swagger-ui/index.html`

### Pacotes R existentes (referência)
- `congressbr`: `https://github.com/RobertMyles/congressbr` (morto)
- `SenadoBR`: `https://github.com/danielmarcelino/SenadoBR` (experimental, inativo)
- `senatebR`: `https://github.com/vsntos/senatebR` (referência de cobertura, não de qualidade)

### MCP connectors (referência de infraestrutura)
- `mcp-senado` (Aredes): `https://github.com/cristianoaredes/mcp-senado`
- `senado-br-mcp` (Bissoli): `https://github.com/SidneyBissoli/senado-br-mcp`
- `senado-br-mcp-cloudflare` (Bissoli): `https://github.com/SidneyBissoli/senado-br-mcp-cloudflare`

### rOpenSci
- Dev Guide: `https://devguide.ropensci.org/`
- Software Review: `https://github.com/ropensci/software-review`
- Package Guide: `https://devguide.ropensci.org/building.html`

### CRAN
- Submission guidelines: `https://cran.r-project.org/web/packages/submission_checklist.html`
- Policies: `https://cran.r-project.org/web/packages/policies.html`

### The R Journal
- Author guidelines: `https://journal.r-project.org/share/author-guide.pdf`
- Submission: `https://journal.r-project.org/`

### Documentos do projeto
- `01-explore-r-packages.md` — Análise de pacotes R existentes
- `02-explore-mcp-connectors.md` — Análise de MCP connectors
- `03-landscape-analysis.md` — Landscape analysis consolidada
- `04-project-roadmap.md` — Este documento (roadmap do projeto)

---

## Apêndice D — Como usar este documento

### Para Sidney (humano)

Este roadmap é o plano mestre. Para executar qualquer fase, basta dar o seguinte comando ao Claude:

> **"Implemente a Fase XX."**

Claude lerá as instruções da fase correspondente e executará os entregáveis na ordem prevista, usando o ator adequado (Claude Code para implementação, Claude Desktop para escrita, etc.).

Ao final de cada fase, Sidney deve:

1. Validar os entregáveis (conforme seção "Validação").
2. Preencher a tabela "Previsto vs. Realizado".
3. Marcar os checkboxes como concluídos.
4. Dar o comando para iniciar a próxima fase.

### Para Claude (máquina)

Ao receber o comando "Implemente a Fase XX":

1. Ler a seção completa da fase solicitada neste documento.
2. Verificar que a fase anterior tem 100% dos entregáveis concluídos.
3. Executar cada entregável na ordem listada.
4. Ao final, executar a validação de máquina.
5. Reportar o status e solicitar validação humana.

### Princípios de execução

- **Sequencialidade rigorosa:** Fase N+1 só começa com fase N 100% concluída.
- **Validação dupla:** Toda fase é validada por máquina e por humano.
- **Documentação contínua:** A tabela "Previsto vs. Realizado" é preenchida ao final de cada fase.
- **Transparência:** Se algo divergir do plano, documentar o porquê na tabela.
- **Minimalismo:** Preferir soluções simples. Dependências extras só com justificativa.
