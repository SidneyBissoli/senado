# Changelog: Atualizações ao Roadmap (04-project-roadmap.md)

**Data:** 20 de março de 2026  
**Motivo:** Mapeamento de endpoints da API concluído — ajustes no escopo da Fase 03 e correção do Apêndice A  
**Documento de referência:** `09-phase03-endpoint-mapping.md`

---

## Edições a aplicar

### 1. Cabeçalho — Linha 7
**De:**
```
**Última atualização deste documento:** 20 de março de 2026 (Fase 02 concluída)
```
**Para:**
```
**Última atualização deste documento:** 20 de março de 2026 (Fase 03 em andamento — mapeamento de endpoints concluído)
```

### 2. Fase 03 — Status
**De:**
```
**Status:** 🔲 NÃO INICIADA
```
**Para:**
```
**Status:** 🔄 EM ANDAMENTO
```

### 3. Fase 03 — Módulo 3.1 — Remover `sen_proceeding_types()`
**Remover esta linha:**
```
- [ ] `sen_proceeding_types()` — Tipos de tramitação
```

### 4. Fase 03 — Módulo 3.2 — Adicionar `sen_senator_speeches()`
**Após:**
```
- [ ] `sen_senator_mandates()` — Histórico de mandatos
```
**Adicionar:**
```
- [ ] `sen_senator_speeches()` — Discursos/pronunciamentos de um senador
```

### 5. Fase 03 — Módulo 3.3 — Adicionar `sen_recent_bills()`
**Após:**
```
- [ ] `sen_bill_authors()` — Autores e coautores
```
**Adicionar:**
```
- [ ] `sen_recent_bills()` — Matérias atualizadas nos últimos N dias
```

### 6. Fase 03 — Tabela de distribuição — Adicionar coluna Status
**De:**
```
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
```
**Para:**
```
| Tarefa | Ator | Status |
|---|---|:-:|
| Mapear endpoints da API para cada função (Swagger UI) | `CN` + `CD` | ✅ |
| Implementar módulos 3.1–3.6 | `CC` | 🔲 |
| Capturar fixtures de resposta da API para cada endpoint | `CC` (via MCP) | 🔲 |
| Escrever testes unitários (mocks) | `CC` | 🔲 |
| Escrever testes de integração | `CC` | 🔲 |
| Testar interativamente cada função no RStudio | `HUM` | 🔲 |
| Validar que saída é tidy (snake_case, tipos corretos) | `HUM` | 🔲 |
| Revisão de código | `HUM` | 🔲 |
```

### 7. Fase 03 — Previsto vs. Realizado — Atualizar contagem
**De:**
```
| Funções exportadas (core) | ~26 funções | |
```
**Para:**
```
| Funções exportadas (core) | ~27 funções (26 originais − 1 removida + 2 adicionadas) | |
```

### 8. Fase 05 — Adicionar `sen_proceeding_types()` (movida da Fase 03)
**Após a linha (em Módulo 5.1):**
```
- [ ] `sen_attendance()` — Taxa de presença por senador/período
```
**Adicionar:**
```
- [ ] `sen_proceeding_types()` — Tipos de tramitação (derivado de `/materia/movimentacoes/{codigo}`)
```

### 9. Apêndice A — Substituir tabela completa de endpoints

**Adicionar nota após o título do Apêndice A:**
```
> **Nota (Fase 03 — atualizado 20/03/2026):** Endpoints corrigidos com base no mapeamento real da API (`09-phase03-endpoint-mapping.md`). Várias rotas previstas originalmente não existem; substituídas por endpoints reais ou derivações client-side.
```

**Substituir toda a tabela do Apêndice A por:**

| Módulo | Função | Fase | Endpoint API / Fonte |
|---|---|---|---|
| **Reference** | `sen_legislatures()` | 03 | Lookup table interna + `GET /senador/lista/legislatura/{leg}` |
| | `sen_current_legislature()` | 03 | Derivado de `GET /senador/lista/atual` (metadado Legislatura) |
| | `sen_parties()` | 03 | `GET /senador/partidos` |
| | `sen_states()` | 03 | Lookup table interna (27 UFs) + contagem via `/senador/lista/atual` |
| | `sen_bill_types()` | 03 | `GET /dados/ListaTiposDocumento.xml` (somente XML) |
| **Senators** | `sen_senators()` | 03 | `GET /senador/lista/atual` + `GET /senador/lista/legislatura/{leg}` |
| | `sen_senator()` | 03 | `GET /senador/{codigo}` + `GET /senador/{codigo}/historico` |
| | `sen_senator_votes()` | 03 | `GET /senador/{codigo}/votacoes` |
| | `sen_senator_bills()` | 03 | `GET /senador/{codigo}/autorias` |
| | `sen_senator_committees()` | 03 | `GET /senador/{codigo}/comissoes` |
| | `sen_senator_mandates()` | 03 | `GET /senador/{codigo}/historico` (seção Mandatos) |
| | `sen_senator_speeches()` | 03 | `GET /senador/{codigo}/discursos` |
| **Bills** | `sen_bills()` | 03 | `GET /materia/pesquisa` |
| | `sen_bill()` | 03 | `GET /materia/{codigo}` |
| | `sen_bill_text()` | 03 | `GET /materia/{codigo}/textos` |
| | `sen_bill_proceedings()` | 03 | `GET /materia/movimentacoes/{codigo}` |
| | `sen_bill_votes()` | 03 | `GET /materia/{codigo}/votacoes` |
| | `sen_bill_authors()` | 03 | `GET /materia/{codigo}/autores` ou derivado de `/materia/{codigo}` |
| | `sen_recent_bills()` | 03 | `GET /materia/atualizadas?numdias={N}` |
| **Votes** | `sen_votes()` | 03 | `GET /plenario/lista/votacao/{ano}` |
| | `sen_vote()` | 03 | `GET /plenario/votacao/{codigo}` (a validar) |
| | `sen_vote_roll_call()` | 03 | Embutido na resposta de votação (normalizar lista aninhada) |
| | `sen_recent_votes()` | 03 | Derivado: `sen_votes(year)` + filtro por data |
| **Committees** | `sen_committees()` | 03 | `GET /comissao/lista/permanente` + `/temporaria` + `/cpi` |
| | `sen_committee()` | 03 | `GET /composicao/comissao/{codigo}` |
| | `sen_committee_members()` | 03 | `GET /composicao/comissao/{codigo}` (membros embutidos) |
| | `sen_committee_meetings()` | 03 | `GET /agendareuniao/{data}` + `GET /agendareuniao/mes/{AAAAMM}` |
| **Plenary** | `sen_agenda()` | 03 | `GET /plenario/agenda/{dataSessao}` |
| | `sen_sessions()` | 03 | `GET /plenario/resultado/{dataSessao}` |
| **e-Cidadania** | `sen_consultations()` | 04 | Scraping e-Cidadania |
| | `sen_consultation()` | 04 | Scraping e-Cidadania |
| | `sen_ideas()` | 04 | Scraping e-Cidadania |
| | `sen_idea()` | 04 | Scraping e-Cidadania |
| | `sen_events()` | 04 | Scraping e-Cidadania |
| | `sen_event()` | 04 | Scraping e-Cidadania |
| **Augment** | `sen_senator_profile()` | 05 | Composição (múltiplos endpoints) |
| | `sen_bill_timeline()` | 05 | Composição (múltiplos endpoints) |
| | `sen_party_cohesion()` | 05 | Cálculo (votos + senadores) |
| | `sen_vote_matrix()` | 05 | Pivot (votos nominais) |
| | `sen_attendance()` | 05 | Cálculo (sessões + presenças) |
| | `sen_proceeding_types()` | 05 | Derivado de `/materia/movimentacoes/{codigo}` (extrair tipos únicos) |
| **Clean** | `sen_clean_names()` | 05 | Interno |
| | `sen_merge_votes()` | 05 | Join (votos + senadores) |
| | `sen_pivot_votes()` | 05 | Pivot (long → wide) |
| **Predict** | `sen_predict_approval()` | 05 | Modelo estatístico |
| **Data** | `sen_historical_senators` | 05 | Dataset estático |
| | `sen_historical_votes` | 05 | Dataset estático |

**Total: ~44 funções exportadas + 2 datasets** (27 na Fase 03, 6 na Fase 04, ~13 na Fase 05)

### 10. Apêndice C — Adicionar documentos novos
**Após:**
```
- `06-appendix-e-contributions.md` — Registro de contribuições por ator (Apêndice E)
```
**Adicionar:**
```
- `08-phase02-test-results.md` — Resultados de testes manuais da Fase 02
- `09-phase03-endpoint-mapping.md` — Mapeamento de endpoints da API para a Fase 03
- `10-phase03-roadmap-changelog.md` — Este changelog de edições ao roadmap
```

---

## Resumo das mudanças

| Mudança | Razão |
|---|---|
| `sen_proceeding_types()` movida para Fase 05 | API não expõe tipos de tramitação como tabela de referência; será derivada |
| `sen_senator_speeches()` adicionada à Fase 03 | Endpoint `GET /senador/{codigo}/discursos` descoberto no mapeamento |
| `sen_recent_bills()` adicionada à Fase 03 | Endpoint `GET /materia/atualizadas?numdias={N}` descoberto no mapeamento |
| Todos os endpoints do Apêndice A corrigidos | 16 divergências entre endpoints previstos e reais identificadas no mapeamento |
| Total de funções: 43 → 44 | −1 (proceeding_types sai da Fase 03) +2 (speeches, recent_bills) = +1 líquido |
