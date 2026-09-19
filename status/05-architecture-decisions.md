# Decisões arquiteturais — Pacote R `senado`

**Data:** 20 de março de 2026  
**Fase:** 01 (Arquitetura e scaffolding)  
**Status:** Aprovado  

---

## ADR-001: Criar pacote novo em vez de contribuir com existente

**Contexto:** Três pacotes R para dados do Senado já existiam (`congressbr`, `SenadoBR`, `senatebR`). O `senatebR` era o mais ativo (147 commits, 15 stars), mas apresentava problemas arquiteturais graves: dependências pesadas e inadequadas (spacyr, quanteda, stm), três métodos de acesso sem padronização, zero infraestrutura de robustez, sem testes, sem vignettes.

**Decisão:** Criar pacote novo do zero.

**Justificativa:** Os problemas do `senatebR` são fundacionais — não se resolvem com PRs pontuais. Contribuir seria equivalente a reescrever. A análise completa está em `status/01-explore-r-packages.md`.

---

## ADR-002: Nome do pacote — `senado`

**Contexto:** Alternativas consideradas: `senadoR`, `senador`, `legislabR`, `senado`.

**Decisão:** `senado`.

**Justificativa:** Curto, limpo, memorizável. Sem sufixo artificial (`bR`, `R`). Consistente com pacotes de referência no ecossistema (`dplyr`, `tibble`, `httr2`). Bilíngue naturalmente (PT *senado* / EN cognato *senate*). Disponibilidade no CRAN verificada.

---

## ADR-003: Prefixo de funções — `sen_`

**Contexto:** Alternativas: `senado_`, `sf_`, `sen_`, sem prefixo.

**Decisão:** `sen_`.

**Justificativa:** Curto (3 caracteres + underscore), facilita autocomplete no RStudio. Segue padrão consolidado do ecossistema: `str_` (stringr), `gs4_` (googlesheets4), `fct_` (forcats), `dv_` (dataverse). Evita conflito com `sf` (pacote de dados espaciais). Lição aprendida do `senatebR`, que misturava 7 prefixos diferentes (`obter_*`, `extrair_*`, `info_*`, `coletar_*`, `dados_*`, `processar_*`, `get_*`).

---

## ADR-004: HTTP client — `httr2` (não `httr`)

**Contexto:** O `senatebR` e o `congressbr` usavam `httr`. Alternativas: `httr`, `httr2`, `curl` direto.

**Decisão:** `httr2`.

**Justificativa:** `httr2` é o sucessor oficial do `httr`, mantido por Hadley Wickham. Oferece nativamente retry com backoff, throttle (rate limiting), pipeline de requisições, e tratamento de erros superior. Elimina a necessidade de implementar manualmente retry e rate limiting — funcionalidades que nenhum pacote existente para dados do Senado implementou. É o padrão recomendado pelo rOpenSci Dev Guide.

---

## ADR-005: Formato de resposta preferido — JSON com fallback para XML

**Contexto:** A API do Senado retorna XML por padrão. JSON está disponível via query param `?formato=json` ou header `Accept: application/json`, mas nem todos os endpoints suportam JSON.

**Decisão:** Solicitar JSON por padrão (via header `Accept: application/json`). Se o endpoint não retornar JSON válido, fazer fallback automático para XML.

**Justificativa:** JSON é mais leve e mais fácil de parsear em R (via `jsonlite`). O fallback garante cobertura total da API sem depender do formato. Os MCPs (`senado-br-mcp-cloudflare`) adotaram a mesma estratégia com sucesso.

---

## ADR-006: Saída — tibble com colunas em snake_case

**Contexto:** A API do Senado retorna nomes de campos em PascalCase (`CodigoParlamentar`, `NomeParlamentar`) e camelCase misturados. O `senatebR` herdava esses nomes sem padronização.

**Decisão:** Todas as funções retornam `tibble` com colunas em `snake_case`.

**Justificativa:** Consistência com o ecossistema tidyverse. Facilita o uso com `dplyr`, `ggplot2` e demais pacotes. O custo de normalização é trivial (feito uma vez no parser, transparente ao usuário). Padrão exigido pelo rOpenSci.

---

## ADR-007: Dependências mínimas — 7 Imports

**Contexto:** O `senatebR` importava 20+ pacotes, incluindo `spacyr` (requer Python), `quanteda`, `stm`, `ggridges`, `patchwork` — nenhum relacionado a acesso a dados.

**Decisão:** 7 pacotes em Imports: `httr2`, `jsonlite`, `xml2`, `tibble`, `cli`, `rlang`, `cachem`.

**Justificativa:** Filosofia de dependências mínimas. Cada pacote tem justificativa funcional direta:

| Pacote | Justificativa |
|---|---|
| `httr2` | HTTP client com retry, throttle, pipeline |
| `jsonlite` | Parse JSON (leve, sem dependências pesadas) |
| `xml2` | Parse XML (API retorna XML por padrão) |
| `tibble` | Saída tidy |
| `cli` | Mensagens, progress bars, erros informativos |
| `rlang` | Programação tidy, tratamento de erros |
| `cachem` | Cache em memória com TTL |

O `rvest` (scraping) foi movido para Suggests — só será necessário quando o módulo e-Cidadania for implementado (Fase 04). Isso permite que o pacote core funcione sem `rvest`.

**Atualização (18/09/2026):** O módulo e-Cidadania por web scraping (Fase 04) foi removido do escopo do pacote. Motivos: o portal não é uma API versionada e seu HTML muda sem aviso; corrigir um pacote no CRAN depois de uma quebra leva dias e depende de cada usuário atualizar; e o volume do acervo (mais de 100 mil ideias legislativas) não cabe numa chamada de função com rate limiting de 1 req/s. Os dados do e-Cidadania estão disponíveis como dataset no Zenodo (DOI `10.5281/zenodo.21183940`). Sem scraping, `rvest` não tem mais uso e saiu do `Suggests` do `DESCRIPTION`. A decisão dos 7 Imports não muda. O pacote passa a cobrir apenas a API oficial do Senado.

---

## ADR-008: Cache — `cachem` com TTL por tipo de dado

**Contexto:** Nenhum pacote R existente para dados do Senado implementa cache. Cada chamada de função resulta em requisição HTTP, mesmo para dados que mudam raramente.

**Decisão:** Cache em memória via `cachem::cache_mem()` com TTL diferenciado:

| Tipo de dado | TTL | Exemplo |
|---|---|---|
| Referência (estático) | 24h | Partidos, UFs, tipos de matéria |
| Semi-estático | 6h | Lista de senadores da legislatura |
| Dinâmico | 15min | Votações recentes, agenda |

**Justificativa:** Reduz chamadas redundantes à API, melhora performance percebida e diminui risco de rate limiting. O TTL diferenciado evita stale data para informações que mudam com frequência. O usuário pode desabilitar globalmente via `options(senado.use_cache = FALSE)` ou limpar manualmente via `sen_cache_clear()`. `cachem` foi escolhido sobre `memoise` por ser mais leve e oferecer controle explícito de TTL.

---

## ADR-009: Rate limiting — máx. 2 req/seg via `httr2::req_throttle()`

**Contexto:** A API do Senado não documenta limites de taxa. Os MCPs implementaram limites conservadores (token bucket, 1-2 req/seg). O `senatebR` não implementava nenhum rate limiting (apenas 1 arquivo com `Sys.sleep` isolado).

**Decisão:** Throttle global de 2 requisições por segundo, via `httr2::req_throttle()`.

**Justificativa:** Conservador o suficiente para não sobrecarregar a API, mas rápido o suficiente para não frustrar o usuário. O `httr2::req_throttle()` implementa isso nativamente, sem necessidade de código custom. O valor de 2 req/seg é consistente com o que os MCPs testaram empiricamente sem receber bloqueios.

---

## ADR-010: Retry — backoff exponencial, máx. 3 tentativas

**Contexto:** A API do Senado pode retornar erros temporários (5xx, timeout). Nenhum pacote R existente implementa retry.

**Decisão:** Retry automático com backoff exponencial: 3 tentativas, intervalos de 1s → 2s → 4s. Aplicado apenas a erros 429 e 5xx (não a 4xx, que indicam erro do cliente).

**Justificativa:** Padrão de robustez para APIs governamentais, que frequentemente têm instabilidade temporária. O `httr2` oferece `req_retry()` nativamente. Os MCPs implementaram lógica similar com sucesso.

---

## ADR-011: Versão mínima do R — 4.1.0

**Contexto:** O pipe nativo `|>` foi introduzido no R 4.1.0 (maio de 2021).

**Decisão:** `Depends: R (>= 4.1.0)`.

**Justificativa:** Permite usar `|>` internamente e nos exemplos, sem depender de `magrittr`. R 4.1.0 tem quase 5 anos — é razoável como piso mínimo. Pacotes modernos do tidyverse (como `httr2`) também exigem R ≥ 4.0.

---

## ADR-012: Infraestrutura compartilhada — começar embutida, extrair depois

**Contexto:** O plano original previa um pacote `apigateway` compartilhado entre `senado`, `healthbR`, `educabR` e `welfarebR`.

**Decisão:** Implementar a infraestrutura de acesso (`sen_get()`, cache, parse, validate) dentro de `R/utils-*.R` no pacote `senado`. Extrair para pacote separado somente quando outro pacote da suíte precisar.

**Justificativa:** Evita abstração prematura. O pacote `senado` funciona de forma independente, sem dependência de infraestrutura externa que ainda não existe. Quando `healthbR` ou `educabR` precisarem da mesma camada, o código já estará maduro e testado, facilitando a extração. Este é o padrão recomendado: "make it work, make it right, make it reusable".

---

## ADR-013: Licença — MIT

**Contexto:** Alternativas: MIT, GPL-3, Apache-2.0.

**Decisão:** MIT.

**Justificativa:** Consistente com ecossistema rOpenSci e tidyverse. Permissiva, facilita adoção acadêmica e comercial. O `senatebR` também usava MIT.

---

## ADR-014: Idioma das funções e documentação — inglês (com suporte PT)

**Contexto:** Pacote sobre dados brasileiros, mas ecossistema R é internacional. O `senatebR` usava nomes de funções em português (`obter_*`, `extrair_*`), limitando alcance.

**Decisão:** Nomes de funções, parâmetros e documentação primária em inglês. Vignettes podem incluir exemplos contextualizados em português quando relevante.

**Justificativa:** Alcance internacional. Submissão ao CRAN e rOpenSci exige documentação em inglês. Pesquisadores internacionais interessados em dados legislativos brasileiros podem usar o pacote. A barreira de idioma é a API (que retorna dados em português), não o pacote.

---

## Resumo das dependências

### Imports (7 pacotes)

```
httr2, jsonlite, xml2, tibble, cli, rlang, cachem
```

### Suggests (9 pacotes)

```
testthat (>= 3.0.0), httptest2, covr, knitr, rmarkdown, withr, 
spelling, dplyr, ggplot2
```

`rvest` saiu em 18/09/2026, com a remoção da Fase 04 (ver ADR-007).

---

## Registro de alterações

| Data | ADR | Alteração |
|---|---|---|
| 2026-03-20 | Todos | Documento criado com 14 decisões arquiteturais |
| 2026-09-18 | ADR-007 | `rvest` retirado de Suggests: Fase 04 (e-Cidadania por scraping) removida do escopo |
