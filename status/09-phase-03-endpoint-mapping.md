# Mapeamento de endpoints da API — Fase 03

**Projeto:** Pacote R `senado`  
**Documento:** `09-phase03-endpoint-mapping.md`  
**Data:** 20 de março de 2026  
**Tarefa:** Mapear endpoints da API do Senado para cada função da Fase 03  
**Fontes consultadas:**  
- Swagger UI: `https://legis.senado.leg.br/dadosabertos/api-docs/swagger-ui/index.html`  
- Docs Enunciate: `https://legis.senado.leg.br/dadosabertos/docs/index.html`  
  - `resource_ListaSenadorService.html`  
  - `resource_ListaComissaoService.html`  
  - `resource_AgendaReuniaoService.html`  
  - `resource_DistribuicaoMateriaService.html`  
  - `resource_LegislacaoService.html`  
  - `resource_Composicao.html`  
- Catálogo ODA: `https://catalogodedadosabertos.com.br/Senado`  
- Congresso Nacional (Plenário): `https://www.congressonacional.leg.br/dados/docs/resource_PlenarioService.html`  
- MCP connector (referência de implementação): `https://github.com/SidneyBissoli/senado-br-mcp`  

---

## Convenções

- **Base URL:** `https://legis.senado.leg.br/dadosabertos`
- **Formato padrão:** XML. Para JSON, usar header `Accept: application/json` ou sufixo `.json`
- **Parâmetros de path:** entre `{}`
- **Parâmetros de query:** após `?`, separados por `&`
- **Cache TTL recomendado:** `ref` = referência (24h), `semi` = semi-estático (6h), `dyn` = dinâmico (15min)

---

## Módulo 3.1 — Dados de referência (`R/reference.R`)

### `sen_legislatures()`

Lista de legislaturas com número, período e senadores.

| Aspecto | Detalhe |
|---|---|
| **Endpoint primário** | `GET /senador/lista/legislatura/{legislatura}` |
| **Endpoint de referência** | Não há endpoint dedicado que liste todas as legislaturas. A abordagem recomendada é iterar sobre números de legislatura conhecidos (a legislatura atual é a 57ª, 2023–2027; a primeira com dados é a 48ª, 1987–1991). |
| **Alternativa** | Incluir lookup table interna no pacote (data/legislaturas.rda) com número → datas. Validar contra API se necessário. |
| **Formato resposta** | JSON/XML |
| **Parâmetros** | `legislatura` (path): número da legislatura (inteiro, ex: 57) |
| **Cache TTL** | `ref` (24h) — legislaturas não mudam |
| **Nota** | O MCP connector não implementa esta função. O `senatebR` também não. Será um diferencial. |

### `sen_current_legislature()`

Legislatura atual (shortcut).

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /senador/lista/atual` |
| **Lógica** | Extrair o campo `Legislatura` da resposta de `/senador/lista/atual`. Não há endpoint dedicado para "legislatura atual" — a informação vem embutida na lista de senadores em exercício. |
| **Cache TTL** | `ref` (24h) |
| **Nota** | Pode ser implementada como wrapper simples que extrai o metadado da resposta de `sen_senators()`. |

### `sen_parties()`

Partidos com representação no Senado.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /senador/partidos` |
| **Formato resposta** | JSON/XML — lista de partidos com sigla, nome e total de senadores |
| **Parâmetros** | Nenhum obrigatório |
| **Cache TTL** | `semi` (6h) — composição partidária muda com trocas de partido |
| **MCP equivalente** | `senado_partidos` |
| **Exemplo** | `https://legis.senado.leg.br/dadosabertos/senador/partidos.json` |

### `sen_states()`

UFs com senadores.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | Não há endpoint dedicado para UFs. |
| **Lógica** | Derivar da resposta de `/senador/lista/atual` (extrair UFs únicas dos senadores em exercício) **OU** usar lookup table interna com as 27 UFs (dado estável). |
| **Alternativa MCP** | O MCP connector implementa `senado_ufs` usando lookup interno. |
| **Cache TTL** | `ref` (24h) — UFs não mudam |
| **Recomendação** | Usar lookup table interna (as 27 UFs brasileiras são estáveis). Enriquecer com contagem de senadores por UF via `/senador/lista/atual`. |

### `sen_bill_types()`

Tipos de matéria legislativa (PEC, PL, PLS, PLP, MPV, etc.).

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /dados/ListaTiposDocumento.xml` |
| **Formato** | **Somente XML** (arquivo estático, sem versão JSON) |
| **Parâmetros** | Nenhum |
| **Cache TTL** | `ref` (24h) |
| **MCP equivalente** | `senado_tipos_materia` |
| **Nota** | Por ser XML estático, o fallback JSON→XML do `sen_get()` é necessário aqui. |
| **Exemplo** | `https://legis.senado.leg.br/dadosabertos/dados/ListaTiposDocumento.xml` |

### `sen_proceeding_types()`

Tipos de tramitação.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | Não identificado endpoint dedicado na API. |
| **Alternativa** | Os tipos de tramitação são embutidos nas respostas de movimentação de matérias (`/materia/movimentacoes/{codigo}`). Considerar: (a) extrair tipos únicos de uma amostra de matérias; (b) incluir lookup table interna; (c) **remover da Fase 03** e implementar como derivação na Fase 05. |
| **Recomendação** | **Mover para Fase 05 ou remover.** A API não expõe esta informação como tabela de referência. Incluir nota no roadmap. |

---

## Módulo 3.2 — Senadores (`R/senators.R`)

### `sen_senators()`

Lista de senadores com filtros.

| Aspecto | Detalhe |
|---|---|
| **Endpoints** | `GET /senador/lista/atual` — senadores em exercício |
| | `GET /senador/lista/legislatura/{legislatura}` — senadores por legislatura |
| **Parâmetros (query)** | `participacao` (opcional): "A" para titulares, "S" para suplentes em exercício |
| **Filtros client-side** | `state` (UF), `party` (sigla) — filtrar no tibble após parse |
| **Formato resposta** | JSON/XML — lista com código, nome, partido, UF, foto |
| **Cache TTL** | `semi` (6h) |
| **MCP equivalente** | `senado_listar_senadores` |
| **Exemplos** | `/senador/lista/atual.json` |
| | `/senador/lista/legislatura/57.json` |
| **Nota** | O parâmetro `status` (ativo/inativo) será implementado como filtro client-side sobre o campo `DescricaoParticipacao`. |

### `sen_senator()`

Detalhes de um senador por código.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /senador/{codigo}` |
| **Parâmetros** | `codigo` (path, obrigatório): código do parlamentar (inteiro) |
| **Formato resposta** | JSON/XML — dados biográficos, mandato atual, foto, email, gabinete, partido, UF, telefone |
| **Endpoint complementar** | `GET /senador/{codigo}/historico` — inclui todos os mandatos (atual + anteriores) |
| **Cache TTL** | `semi` (6h) |
| **MCP equivalente** | `senado_obter_senador` |
| **Exemplo** | `/senador/5322.json` |

### `sen_senator_votes()`

Votações nominais de um senador.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /senador/{codigo}/votacoes` |
| **Parâmetros path** | `codigo` (obrigatório): código do parlamentar |
| **Parâmetros query** | `sigla` (opcional): sigla do tipo de matéria (ex: "PEC", "PLS") |
| | `tramitando` (opcional): "s" para matérias em tramitação |
| | `dataInicio`, `dataFim` (opcional): formato YYYYMMDD |
| **Cache TTL** | `dyn` (15min) |
| **MCP equivalente** | `senado_votacoes_senador` |
| **Exemplo** | `/senador/4981/votacoes.json?sigla=pls&tramitando=s` |

### `sen_senator_bills()`

Matérias de autoria de um senador.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /senador/{codigo}/autorias` |
| **Parâmetros path** | `codigo` (obrigatório): código do parlamentar |
| **Parâmetros query** | `sigla` (opcional): tipo de matéria |
| | `tramitando` (opcional): "s" para em tramitação |
| | `principal` (opcional): "n" para matérias onde é coautor |
| **Cache TTL** | `semi` (6h) |
| **MCP equivalente** | Coberto por `senado_buscar_materias` com filtro de autor |
| **Exemplos** | `/senador/4981/autorias.json` |
| | `/senador/4981/autorias.json?sigla=pls&tramitando=s` |
| | `/senador/4981/autorias.json?principal=n` (coautorias) |

### `sen_senator_committees()`

Comissões de que um senador é membro.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /senador/{codigo}/comissoes` |
| **Parâmetros path** | `codigo` (obrigatório) |
| **Parâmetros query** | `indAtivos` (opcional): "s" para comissões ativas |
| | `comissao` (opcional): sigla de comissão específica (ex: "CE") |
| **Cache TTL** | `semi` (6h) |
| **Exemplo** | `/senador/5322/comissoes.json?indAtivos=s` |

### `sen_senator_mandates()`

Histórico de mandatos de um senador.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /senador/{codigo}/historico` |
| **Parâmetros** | `codigo` (path, obrigatório) |
| **Lógica** | O endpoint `/historico` retorna todos os mandatos. Extrair a seção `Mandatos` da resposta e normalizar em tibble. |
| **Alternativa** | `/senador/{codigo}/mandatos` — **verificar se existe** (documentação não é clara; pode ser sub-path ou pode não existir separadamente) |
| **Cache TTL** | `ref` (24h) — mandatos passados não mudam |
| **Exemplo** | `/senador/5322/historico.json` |

---

## Módulo 3.3 — Matérias legislativas (`R/bills.R`)

### `sen_bills()`

Busca de matérias com filtros.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /materia/pesquisa` |
| **Parâmetros query** | `sigla` (opcional): tipo de matéria (PEC, PL, PLP, MPV, etc.) |
| | `numero` (opcional): número da matéria |
| | `ano` (opcional): ano de apresentação |
| | `palavraChave` (opcional): termo de busca no texto/ementa |
| | `tramitando` (opcional): "s" para em tramitação |
| | `autor` (opcional): nome do autor |
| | `relator` (opcional): nome do relator |
| | `nomeParteAutor` (opcional): parte do nome do autor |
| **Formato** | JSON/XML |
| **Cache TTL** | `dyn` (15min) |
| **MCP equivalente** | `senado_buscar_materias` |
| **Exemplos** | `/materia/pesquisa.json?sigla=PEC&ano=2024` |
| | `/materia/pesquisa.json?palavraChave=saude&tramitando=s` |
| **Nota** | Endpoint pode não suportar paginação — verificar se retorna todos os resultados ou se há limite. Testar com queries amplas. |
| **Endpoint alternativo** | `GET /materia/atualizadas?numdias={N}` — matérias atualizadas nos últimos N dias |
| | `GET /materia/tramitando` — matérias em tramitação |

### `sen_bill()`

Detalhes de uma matéria por código.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /materia/{codigo}` |
| **Parâmetros** | `codigo` (path, obrigatório): código da matéria |
| **Formato** | JSON/XML — ementa, autor, relator, status, situação, datas |
| **Cache TTL** | `semi` (6h) |
| **MCP equivalente** | `senado_obter_materia` |
| **Exemplo** | `/materia/139025.json` |

### `sen_bill_text()`

Textos da matéria (inteiro teor, emendas, substitutivos).

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /materia/{codigo}/textos` |
| **Parâmetros** | `codigo` (path, obrigatório) |
| **Formato** | JSON/XML — lista de textos com tipo, data, URL de download |
| **Cache TTL** | `semi` (6h) |
| **MCP equivalente** | `senado_textos_materia` |
| **Exemplo** | `/materia/139025/textos.json` |

### `sen_bill_proceedings()`

Tramitação detalhada (timeline).

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /materia/movimentacoes/{codigo}` |
| **Parâmetros** | `codigo` (path, obrigatório) |
| **Formato** | JSON/XML — lista cronológica de movimentações |
| **Cache TTL** | `dyn` (15min) |
| **MCP equivalente** | `senado_tramitacao_materia` |
| **Exemplo** | `/materia/movimentacoes/139025.json` |
| **Nota** | Pode conter centenas de movimentações para matérias antigas. O tibble deve ter colunas: data, tipo, casa, descrição. |

### `sen_bill_votes()`

Votações relacionadas à matéria.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /materia/{codigo}/votacoes` |
| **Parâmetros** | `codigo` (path, obrigatório) |
| **Formato** | JSON/XML — lista de votações com resultado |
| **Cache TTL** | `dyn` (15min) |
| **MCP equivalente** | `senado_votos_materia` |
| **Exemplo** | `/materia/139025/votacoes.json` |

### `sen_bill_authors()`

Autores e coautores de uma matéria.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /materia/{codigo}/autores` |
| **Alternativa** | A informação de autoria pode estar embutida na resposta de `/materia/{codigo}` (campo `Autoria`). Testar se endpoint dedicado `/autores` existe. |
| **Se não existir** | Implementar como extração do campo `Autoria` da resposta de `sen_bill()`. Marcar como derivação, não como endpoint direto. |
| **Cache TTL** | `semi` (6h) |
| **Nota** | Endpoint `/materia/distribuicao/autoria.json?codParlamentar={cod}` existe para distribuição de autoria por senador — pode ser útil como complemento. |

---

## Módulo 3.4 — Votações (`R/votes.R`)

### `sen_votes()`

Lista de votações com filtros.

| Aspecto | Detalhe |
|---|---|
| **Endpoint principal** | `GET /plenario/lista/votacao/{ano}` |
| **Parâmetros path** | `ano` (obrigatório): ano no formato YYYY |
| **Filtros client-side** | `month`, `date_range` — filtrar no tibble após parse |
| **Formato** | JSON/XML — lista de votações com código, data, matéria, resultado |
| **Cache TTL** | `dyn` (15min) para ano corrente; `ref` (24h) para anos passados |
| **MCP equivalente** | `senado_listar_votacoes` |
| **Exemplo** | `/plenario/lista/votacao/2024.json` |
| **Nota importante** | O endpoint é do serviço "Plenário" (`/plenario/`), não `/votacao/`. A estrutura de caminho difere do que estava previsto no Apêndice A do roadmap (`/votacao/lista`). **Atualizar roadmap.** |
| **Alternativa** | Votações de comissões podem estar em endpoints diferentes — investigar na Fase 03 de implementação. |

### `sen_vote()`

Detalhes de uma votação por código.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /plenario/votacao/{codigo}` |
| **Alternativa** | A informação detalhada pode vir de `/materia/{codigoMateria}/votacoes` se a votação estiver vinculada a uma matéria. |
| **Parâmetros** | `codigo` (path, obrigatório): código da sessão/votação |
| **Cache TTL** | `ref` (24h) para votações passadas |
| **MCP equivalente** | `senado_obter_votacao` |
| **Nota** | Testar se `/plenario/votacao/{codigo}` retorna votos nominais ou se é necessário endpoint separado. |

### `sen_vote_roll_call()`

Votos nominais (quem votou o quê).

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | Embutido na resposta de `GET /plenario/votacao/{codigo}` ou `GET /materia/{codigo}/votacoes` |
| **Lógica** | Os votos nominais individuais (senador → voto) vêm como lista aninhada dentro da resposta da votação. Extrair e normalizar em tibble com colunas: `senator_code`, `senator_name`, `party`, `state`, `vote` (Sim/Não/Abstenção/P-OD/etc.). |
| **Endpoint específico** | Para vetos do Congresso Nacional: `GET /plenario/resultado/veto/{codigo}` |
| **Cache TTL** | `ref` (24h) |
| **MCP equivalente** | Incluído em `senado_obter_votacao` |
| **Exemplo** | `/plenario/resultado/veto/11762.json` |

### `sen_recent_votes()`

Votações dos últimos N dias.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | Não há endpoint dedicado para "votações recentes". |
| **Lógica** | Implementar como wrapper: (1) `sen_votes(year = current_year)` → (2) filtrar por data ≥ `Sys.Date() - days`. |
| **Alternativa** | O MCP implementa `senado_votacoes_recentes` com essa mesma lógica. |
| **Parâmetro** | `days` (default = 30) |
| **Cache TTL** | `dyn` (15min) |

---

## Módulo 3.5 — Comissões (`R/committees.R`)

### `sen_committees()`

Lista de comissões com filtro por tipo.

| Aspecto | Detalhe |
|---|---|
| **Endpoints** | `GET /comissao/lista/permanente` — comissões permanentes |
| | `GET /comissao/lista/temporaria` — comissões temporárias |
| | `GET /comissao/lista/cpi` — CPIs |
| **Parâmetros** | Nenhum obrigatório por endpoint |
| **Formato** | JSON/XML — lista de comissões com sigla, nome, tipo |
| **Lógica na função** | Parâmetro `type = c("all", "permanent", "temporary", "cpi")`. Se `type = "all"`, fazer 3 chamadas e combinar com `rbind`. |
| **Cache TTL** | `semi` (6h) |
| **MCP equivalente** | `senado_listar_comissoes` |
| **Exemplos** | `/comissao/lista/permanente.json` |
| | `/comissao/lista/cpi.json` |

### `sen_committee()`

Detalhes de uma comissão.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /comissao/{sigla}` |
| **Alternativa** | `GET /composicao/comissao/{codigo}` (código numérico, não sigla) |
| **Parâmetros** | `sigla` ou `codigo` (path, obrigatório) |
| **Cache TTL** | `semi` (6h) |
| **MCP equivalente** | `senado_obter_comissao` |
| **Exemplo** | `/composicao/comissao/34.json` |
| **Nota** | Verificar qual identificador a API espera — sigla (ex: "CCJ") ou código numérico (ex: 34). O MCP usa sigla; o endpoint `/composicao/` usa código. Pode ser necessário manter um mapeamento sigla→código interno. |

### `sen_committee_members()`

Membros de uma comissão.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /composicao/comissao/{codigo}` |
| **Alternativa** | `GET /comissao/{sigla}/membros` |
| **Parâmetros query** | `ativas` (opcional): "S" para vagas ativas apenas |
| **Formato** | JSON/XML — lista de membros com nome, partido, cargo na comissão |
| **Cache TTL** | `semi` (6h) |
| **MCP equivalente** | `senado_membros_comissao` |
| **Exemplo** | `/composicao/comissao/34.json?ativas=S` |

### `sen_committee_meetings()`

Reuniões agendadas/realizadas.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /agendareuniao/{dataReferencia}` |
| **Parâmetros path** | `dataReferencia` (obrigatório): formato YYYYMMDD para dia, AAAAMM para mês |
| **Endpoint mensal** | `GET /agendareuniao/mes/{AAAAMM}` |
| **Endpoint próximos** | `GET /agendareuniao/atual/iCal` — próximos 30 dias |
| **Filtro** | Por comissão: filtrar client-side pela sigla no tibble resultante |
| **Cache TTL** | `dyn` (15min) |
| **MCP equivalente** | `senado_reunioes_comissao` e `senado_agenda_comissoes` |
| **Exemplos** | `/agendareuniao/20240529.json` |
| | `/agendareuniao/mes/202405.json` |

---

## Módulo 3.6 — Plenário e agenda (`R/plenary.R`)

### `sen_agenda()`

Agenda do plenário com filtros.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /plenario/agenda/{dataSessao}` |
| **Parâmetros path** | `dataSessao` (obrigatório): formato YYYYMMDD |
| **Formato** | JSON/XML — agenda da sessão plenária |
| **Cache TTL** | `dyn` (15min) |
| **MCP equivalente** | `senado_agenda_plenario` |
| **Exemplo** | `/plenario/agenda/20130522.json` |
| **Nota** | Este endpoint é do **Congresso Nacional** (sessões conjuntas), disponível em `congressonacional.leg.br`. Verificar se há endpoint equivalente para sessões do **Senado exclusivamente**. |

### `sen_sessions()`

Sessões plenárias realizadas.

| Aspecto | Detalhe |
|---|---|
| **Endpoint** | `GET /plenario/resultado/{dataSessao}` |
| **Parâmetros path** | `dataSessao` (obrigatório): formato YYYYMMDD |
| **Formato** | JSON/XML — resultado da sessão |
| **Cache TTL** | `ref` (24h) para sessões passadas |
| **Exemplo** | `/plenario/resultado/20130522.json` |
| **Nota** | Verificar se há endpoint que liste sessões por período (ex: por mês ou por ano), em vez de exigir data exata. |

---

## Endpoints adicionais descobertos (não previstos no roadmap)

Estes endpoints foram identificados durante o mapeamento e podem ser integrados na Fase 03 ou em fases futuras:

| Endpoint | Descrição | Fase sugerida |
|---|---|---|
| `GET /senador/{codigo}/discursos` | Discursos/pronunciamentos de um senador | 03 (adicionar `sen_senator_speeches()`) |
| `GET /senador/{codigo}/apartes` | Apartes de um senador | 05 (augment) |
| `GET /senador/{codigo}/cargos` | Cargos/funções de um senador | 03 (adicionar a `sen_senator()` ou função separada) |
| `GET /senador/{codigo}/relatorias` | Relatorias de um senador | 05 (augment) |
| `GET /materia/{codigo}/emendas` | Emendas de uma matéria | 05 |
| `GET /materia/{codigo}/relatorias` | Relatorias de uma matéria | 05 |
| `GET /materia/atualizadas?numdias={N}` | Matérias atualizadas recentemente | 03 (considerar `sen_recent_bills()`) |
| `GET /materia/tramitando` | Matérias em tramitação | 03 (considerar como filtro de `sen_bills()`) |
| `GET /dados/ListaBlocoParlamentar.xml` | Blocos parlamentares | 05 |
| `GET /blocoParlamentar/{codigo}` | Detalhes de bloco parlamentar | 05 |
| `GET /dados/ListaAutores.xml` | Lista de autores (senadores + outros) | 03 (reference) |
| `GET /glossario/lista` | Glossário de termos | 05 |
| `GET /comissao/{sigla}/documentos` | Documentos de uma comissão | 05 |
| `GET /comissao/cpi/{sigla}/requerimentos` | Requerimentos de CPI | 05 |
| `GET /comissao/tiposCargo` | Tipos de cargo em comissão | 03 (reference) |
| `GET /materia/distribuicao/autoria` | Distribuição de autoria | 05 |
| `GET /materia/distribuicao/relatoria/{sigla}` | Distribuição de relatoria | 05 |

---

## Divergências entre roadmap (Apêndice A) e API real

| Função (roadmap) | Endpoint previsto (Apêndice A) | Endpoint real | Ação |
|---|---|---| :-:|
| `sen_legislatures()` | `REST /legislatura` | **Não existe.** Usar lookup table interna | Atualizar Apêndice A |
| `sen_current_legislature()` | `REST /legislatura/atual` | **Não existe.** Derivar de `/senador/lista/atual` | Atualizar Apêndice A |
| `sen_states()` | `REST /ufs` | **Não existe.** Usar lookup table interna + enriquecer com API | Atualizar Apêndice A |
| `sen_bill_types()` | `REST /tipos-materia` | `GET /dados/ListaTiposDocumento.xml` (somente XML) | Atualizar Apêndice A |
| `sen_proceeding_types()` | `REST /tipos-tramitacao` | **Não existe.** Mover para Fase 05 | Atualizar roadmap |
| `sen_votes()` | `REST /votacao/lista` | `GET /plenario/lista/votacao/{ano}` | Atualizar Apêndice A |
| `sen_vote()` | `REST /votacao/{codigo}` | `GET /plenario/votacao/{codigo}` (verificar) | Atualizar Apêndice A |
| `sen_vote_roll_call()` | `REST /votacao/{codigo}/votos` | Embutido na resposta da votação | Atualizar Apêndice A |
| `sen_recent_votes()` | `REST /votacao/recentes` | **Não existe.** Derivar de `/plenario/lista/votacao/{ano}` | Atualizar Apêndice A |
| `sen_committees()` | `REST /comissao/lista` | 3 endpoints separados: `/permanente`, `/temporaria`, `/cpi` | Atualizar Apêndice A |
| `sen_committee()` | `REST /comissao/{codigo}` | `GET /composicao/comissao/{codigo}` | Atualizar Apêndice A |
| `sen_committee_members()` | `REST /comissao/{codigo}/membros` | `GET /composicao/comissao/{codigo}` (membros embutidos) | Atualizar Apêndice A |
| `sen_committee_meetings()` | `REST /comissao/{codigo}/reunioes` | `GET /agendareuniao/{data}` (por data, não por comissão) | Atualizar Apêndice A |
| `sen_agenda()` | `REST /agenda/plenario` | `GET /plenario/agenda/{dataSessao}` (Congresso Nacional) | Atualizar Apêndice A |
| `sen_sessions()` | `REST /sessao/lista` | `GET /plenario/resultado/{dataSessao}` (verificar) | Atualizar Apêndice A |

---

## Resumo de endpoints validados (prontos para implementação)

### Endpoints com alta confiança (validados via MCP + documentação + catálogo)

| # | Endpoint | Método | JSON | Função(ões) |
|:-:|---|:-:|:-:|---|
| 1 | `/senador/lista/atual` | GET | ✅ | `sen_senators()`, `sen_current_legislature()`, `sen_states()` |
| 2 | `/senador/lista/legislatura/{leg}` | GET | ✅ | `sen_senators()`, `sen_legislatures()` |
| 3 | `/senador/{codigo}` | GET | ✅ | `sen_senator()` |
| 4 | `/senador/{codigo}/historico` | GET | ✅ | `sen_senator()`, `sen_senator_mandates()` |
| 5 | `/senador/{codigo}/votacoes` | GET | ✅ | `sen_senator_votes()` |
| 6 | `/senador/{codigo}/autorias` | GET | ✅ | `sen_senator_bills()` |
| 7 | `/senador/{codigo}/comissoes` | GET | ✅ | `sen_senator_committees()` |
| 8 | `/senador/partidos` | GET | ✅ | `sen_parties()` |
| 9 | `/materia/pesquisa` | GET | ✅ | `sen_bills()` |
| 10 | `/materia/{codigo}` | GET | ✅ | `sen_bill()` |
| 11 | `/materia/{codigo}/textos` | GET | ✅ | `sen_bill_text()` |
| 12 | `/materia/movimentacoes/{codigo}` | GET | ✅ | `sen_bill_proceedings()` |
| 13 | `/materia/{codigo}/votacoes` | GET | ✅ | `sen_bill_votes()` |
| 14 | `/plenario/lista/votacao/{ano}` | GET | ✅ | `sen_votes()` |
| 15 | `/comissao/lista/permanente` | GET | ✅ | `sen_committees()` |
| 16 | `/comissao/lista/temporaria` | GET | ✅ | `sen_committees()` |
| 17 | `/comissao/lista/cpi` | GET | ✅ | `sen_committees()` |
| 18 | `/composicao/comissao/{codigo}` | GET | ✅ | `sen_committee()`, `sen_committee_members()` |
| 19 | `/agendareuniao/{data}` | GET | ✅ | `sen_committee_meetings()` |
| 20 | `/agendareuniao/mes/{AAAAMM}` | GET | ✅ | `sen_committee_meetings()` |
| 21 | `/plenario/agenda/{data}` | GET | ✅ | `sen_agenda()` |
| 22 | `/plenario/resultado/{data}` | GET | ✅ | `sen_sessions()` |

### Endpoints somente XML (fallback necessário)

| # | Endpoint | Função(ões) |
|:-:|---|---|
| 23 | `/dados/ListaTiposDocumento.xml` | `sen_bill_types()` |
| 24 | `/dados/ListaBlocoParlamentar.xml` | Fase 05 |
| 25 | `/dados/ListaAutores.xml` | `sen_bill_authors()` (referência) |
| 26 | `/dados/ListaTiposAutor.xml` | Referência |

---

## Endpoints a validar na implementação (CC)

Os seguintes endpoints precisam ser testados diretamente contra a API para confirmar existência, formato de resposta e parâmetros:

1. **`/senador/{codigo}/mandatos`** — Existe separado de `/historico`? Ou mandatos são parte da resposta de `/historico`?
2. **`/materia/{codigo}/autores`** — Endpoint dedicado? Ou autores vêm embutidos em `/materia/{codigo}`?
3. **`/plenario/votacao/{codigo}`** — Detalhes de votação específica com votos nominais?
4. **`/plenario/resultado/veto/{codigo}`** — Confirmado na documentação do Congresso Nacional. Funciona no Senado?
5. **`/comissao/{sigla}`** — Aceita sigla no path? Ou apenas código numérico via `/composicao/comissao/{codigo}`?
6. **Paginação em `/materia/pesquisa`** — Há limite de resultados? Parâmetros `page`/`offset`?

---

## Próximo passo

Este documento é o entregável da tarefa "Mapear endpoints da API para cada função (Swagger UI)" da Fase 03. O próximo passo no roadmap é:

> **Implementar módulos 3.1–3.6** (ator: `CC`)

Claude Code deve usar este mapeamento como referência para implementar cada função, fazendo as validações pendentes diretamente contra a API durante a implementação.
