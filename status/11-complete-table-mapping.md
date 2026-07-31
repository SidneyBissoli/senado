# Mapeamento completo de tabelas — APIs do Senado Federal (v2 — corrigido)

**Data:** 21 de março de 2026  
**Versão:** 2.0 (corrige 44 erros da v1)  
**Objetivo:** Identificar as tabelas de dados reais que as duas APIs retornam, para definir funções no pacote `senado`.  
**Método de verificação:** Todos os endpoints listados abaixo foram extraídos diretamente da spec OpenAPI via JavaScript no Swagger UI. Nenhum endpoint foi inferido ou inventado.

---

## Panorama geral

| API | Base URL | Endpoints totais | Ativos | Deprecated |
|---|---|:-:|:-:|:-:|
| **Legislativa** | `legis.senado.leg.br/dadosabertos/` | 157 | 115 | 42 |
| **Administrativa** | `adm.senado.gov.br/adm-dadosabertos/` | 81 | 42 (JSON) + 39 (CSV) | 0 |

**Nota sobre deprecated:** A API Legislativa tem 42 endpoints deprecated, concentrados no grupo Processo (34 da API v3 de matérias `/materia/*`, substituída pela v4 `/processo/*`). O pacote deve usar apenas os endpoints ativos.

---

## API LEGISLATIVA

### 1. Parlamentar (13 endpoints ativos, 1 deprecated)

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/senador/{codigo}` | Informações de um Senador | `codigo*`, `v` |
| 2 | `/senador/{codigo}/profissao` | Profissões de um Senador | `codigo*`, `v` |
| 3 | `/senador/{codigo}/mandatos` | Mandatos Parlamentares de um Senador | `codigo*`, `v` |
| 4 | `/senador/{codigo}/licencas` | Licenças oficiais de um Senador | `codigo*`, `dataInicio`, `dataFim`, `v` |
| 5 | `/senador/{codigo}/historicoAcademico` | Histórico Acadêmico de um Senador | `codigo*`, `v` |
| 6 | `/senador/{codigo}/filiacoes` | Filiações Partidárias de um Senador | `codigo*`, `v` |
| 7 | `/senador/{codigo}/comissoes` | Comissões de que um Senador é membro | `codigo*`, `ativo`, `comissao`, `v` |
| 8 | `/senador/{codigo}/cargos` | Cargos ocupados por um Senador | `codigo*`, `ativo`, `comissao`, `v` |
| 9 | `/senador/partidos` | Partidos Políticos em atividade e/ou extintos | — |
| 10 | `/senador/lista/legislatura/{legislaturaInicio}/{legislaturaFim}` | Senadores por intervalo de legislaturas | `legislaturaInicio*`, `legislaturaFim*` |
| 11 | `/senador/lista/legislatura/{legislatura}` | Senadores por legislatura | `legislatura*` |
| 12 | `/senador/lista/atual` | Senadores em exercício | — |
| 13 | `/senador/afastados` | Senadores afastados | — |

Deprecated: `/senador/{codigo}/liderancas`

---

### 2. Votação (4 endpoints ativos, 1 deprecated)

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/votacao` | Votos Nominais de Parlamentares em Processos Legislativos | `codigoSessao`, `dataInicio`, `dataFim`, `idProcesso`, `codigoMateria`, `sigla`, `numero`, `ano`, `codigoParlamentar`, `nomeParlamentar`, `siglaVotoParlamentar`, `v` |
| 2 | `/votacaoComissao/comissao/{siglaComissao}` | Votações de Matérias nas Comissões | `siglaComissao*`, `dataInicio`, `dataFim`, `v` |
| 3 | `/votacaoComissao/parlamentar/{codigo}` | Votações nas Comissões por Parlamentar | `codigo*`, `comissao`, `dataInicio`, `dataFim`, `v` |
| 4 | `/votacaoComissao/materia/{sigla}/{numero}/{ano}` | Votações de Matérias nas Comissões por Identificação | `sigla*`, `numero*`, `ano*`, `comissao`, `dataInicio`, `dataFim`, `v` |

Deprecated: `/senador/{codigo}/votacoes` (use `/votacao` com `codigoParlamentar`)

**Nota:** O endpoint `/votacao` é o principal para votos nominais — aceita `nomeParlamentar` como filtro (busca por nome do senador).

---

### 3. Discurso (9 endpoints ativos, 0 deprecated)

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/senador/{codigo}/discursos` | Discursos de um Senador | `codigo*`, `casa`, `dataInicio`, `dataFim`, `numeroSessao`, `tipoSessao`, `v` |
| 2 | `/senador/{codigo}/apartes` | Apartes feitos por um Senador | `codigo*`, `casa`, `dataInicio`, `dataFim`, `numeroSessao`, `tipoSessao`, `v` |
| 3 | `/discurso/texto-integral/{codigoPronunciamento}` | Texto Integral de um Pronunciamento | `codigoPronunciamento*`, `v` |
| 4 | `/discurso/texto-binario/{codigoPronunciamento}` | Texto Binário de um Pronunciamento (PDF/DOC) | `codigoPronunciamento*`, `v` |
| 5 | `/taquigrafia/notas/sessao/{idSessao}` | Notas Taquigráficas de Sessões Plenárias | `idSessao*`, `v` |
| 6 | `/taquigrafia/notas/reuniao/{idReuniao}` | Notas Taquigráficas de Reuniões de Comissão | `idReuniao*`, `v` |
| 7 | `/taquigrafia/videos/sessao/{idSessao}` | Vídeos de Sessões Plenárias | `idSessao*`, `v` |
| 8 | `/taquigrafia/videos/reuniao/{idReuniao}` | Vídeos de Reuniões de Comissão | `idReuniao*`, `v` |
| 9 | `/senador/lista/tiposUsoPalavra` | Tipos de Uso da Palavra — referência | — |

---

### 4. Processo (27 endpoints ativos, 34 deprecated)

**API v4 — Processos Legislativos (substitui a v3 `/materia/*`)**

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/processo` | Pesquisa de Processos Legislativos | `sigla`, `numero`, `ano`, `palavraChave`, `tramitando`, `codigoParlamentarAutor`, e outros |
| 2 | `/processo/{id}` | Detalhes de um Processo Legislativo | `id*`, `v` |
| 3 | `/processo/relatoria` | Relatorias de Processos Legislativos | `idProcesso`, `codigoMateria`, `dataReferencia`, `dataInicio`, `dataFim`, `codigoParlamentar`, `codigoColegiado`, `v` |
| 4 | `/processo/emenda` | Emendas a Processos Legislativos | `idEmenda`, `idDocumento`, `idProcesso`, `codigoMateria`, `dataInicio`, `dataFim`, `codigoParlamentarAutor`, `codigoColegiado`, `v` |
| 5 | `/processo/documento` | Documentos de Processos Legislativos | `idDocumento`, `idProcesso`, `codigoMateria`, `dataInicio`, `dataFim`, `codigoParlamentarAutor`, `idEnteAutor`, `codigoColegiado`, `v` |
| 6 | `/processo/prazo` | Prazos de Processos Legislativos | `idProcesso`, `codigoMateria`, `idTipoPrazo`, `dataReferencia`, `dataInicio`, `dataFim`, `codigoColegiado`, `sigla`, `v` |
| 7 | `/processo/siglas` | Tipos e Siglas de Processos — referência | — |
| 8 | `/processo/tipos-situacao` | Tipos de Situações — referência | — |
| 9 | `/processo/tipos-decisao` | Tipos de Decisões — referência | — |
| 10 | `/processo/tipos-autor` | Tipos de Autores — referência | — |
| 11 | `/processo/tipos-atualizacao` | Tipos de Atualização — referência | — |
| 12 | `/processo/prazo/tipos` | Tipos de Prazos — referência | — |
| 13 | `/processo/documento/tipos` | Tipos de Documentos — referência | — |
| 14 | `/processo/documento/tipos-conteudo` | Tipos de Conteúdo de Documentos — referência | — |
| 15 | `/processo/entes` | Entes (autores não-parlamentares) — referência | — |
| 16 | `/processo/destinos` | Destinos possíveis de processos — referência | — |
| 17 | `/processo/classes` | Classes de processos — referência | — |
| 18 | `/processo/assuntos` | Assuntos de processos — referência | — |

**Endpoints ativos que ainda usam path `/materia/*` (não deprecated)**

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 19 | `/materia/vetos/{ano}` | Vetos presidenciais por ano | `ano*` |
| 20 | `/materia/vetos/encerrados` | Vetos encerrados | — |
| 21 | `/materia/vetos/aposrcn` | Vetos após RCN | — |
| 22 | `/materia/vetos/antesrcn` | Vetos antes de RCN | — |
| 23 | `/materia/lista/tramitacao` | Matérias em tramitação | — |
| 24 | `/materia/distribuicao/autoria` | Distribuição de autoria de matérias | filtros variados |
| 25 | `/materia/distribuicao/autoria/{siglaComissao}` | Distribuição de autoria por comissão | `siglaComissao*` |
| 26 | `/materia/distribuicao/relatoria/{sigla}` | Distribuição de relatoria por comissão | `sigla*` |
| 27 | `/autor/lista/atual` | Lista de autores atuais | — |

---

### 5. Plenário (22 endpoints ativos, 3 deprecated)

**Agenda do Plenário**

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/plenario/agenda/dia/{data}` | Agenda do plenário no dia | `data*` |
| 2 | `/plenario/agenda/mes/{data}` | Agenda do plenário no mês | `data*` |
| 3 | `/plenario/agenda/atual/iCal` | Agenda dos próximos 30 dias (formato iCal) | — |
| 4 | `/plenario/agenda/cn/{data}` | Agenda do Congresso Nacional no dia | `data*` |
| 5 | `/plenario/agenda/cn/{inicio}/{fim}` | Agenda do Congresso Nacional no período | `inicio*`, `fim*` |

**Sessões/Encontros**

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 6 | `/plenario/encontro/{codigo}` | Detalhes de uma Sessão Plenária | `codigo*` |
| 7 | `/plenario/encontro/{codigo}/pauta` | Pauta da Sessão | `codigo*` |
| 8 | `/plenario/encontro/{codigo}/resultado` | Resultado da Sessão | `codigo*` |
| 9 | `/plenario/encontro/{codigo}/resumo` | Resumo da Sessão | `codigo*` |

**Resultados e Votações**

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 10 | `/plenario/resultado/{data}` | Resultado da Sessão Plenária no dia | `data*`, `v` |
| 11 | `/plenario/resultado/mes/{data}` | Resultado das Sessões no mês | `data*` |
| 12 | `/plenario/resultado/cn/{data}` | Resultado de Sessão do Congresso Nacional | `data*` |
| 13 | `/plenario/resultado/veto/{codigo}` | Resultado de Votação de Veto | `codigo*`, `v` |
| 14 | `/plenario/resultado/veto/materia/{codigo}` | Resultado de Votação de Veto a Projeto de Lei | `codigo*`, `v` |
| 15 | `/plenario/resultado/veto/dispositivo/{codigo}` | Resultado de Votação de Dispositivo de Veto Parcial | `codigo*`, `v` |
| 16 | `/plenario/votacao/orientacaoBancada/{dataSessao}` | Orientação de Bancada por data | `dataSessao*`, `v` |
| 17 | `/plenario/votacao/orientacaoBancada/{dataInicio}/{dataFim}` | Orientação de Bancada por período | `dataInicio*`, `dataFim*`, `v` |

**Referência e Consulta**

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 18 | `/plenario/lista/legislaturas` | Lista de Legislaturas | — |
| 19 | `/plenario/lista/tiposComparecimento` | Tipos de Comparecimento — referência | — |
| 20 | `/plenario/lista/discursos/{dataInicio}/{dataFim}` | Discursos em Sessões Plenárias por período | `dataInicio*`, `dataFim*` |
| 21 | `/plenario/legislatura/{data}` | Legislatura vigente na data | `data*` |
| 22 | `/plenario/tiposSessao` | Tipos de Sessão Plenária — referência | — |

Deprecated: `/plenario/votacao/nominal/{ano}`, `/plenario/agenda/{data}`, `/plenario/presencas/{data}`

**Nota:** `/plenario/lista/legislaturas` é o endpoint que lista legislaturas — era o que "não existia" na Fase 03 original.

---

### 6. Comissão (13 endpoints ativos, 1 deprecated)

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/comissao/{codigo}` | Detalhes de um Colegiado | `codigo*`, `v` |
| 2 | `/comissao/lista/{tipo}` | Lista de Colegiados por tipo | `tipo*`, `v` |
| 3 | `/comissao/lista/colegiados` | Lista geral de Colegiados em atividade | — |
| 4 | `/comissao/lista/mistas` | Comissões Mistas do Congresso Nacional | — |
| 5 | `/comissao/lista/tiposColegiado` | Tipos de Colegiado — referência | — |
| 6 | `/comissao/agenda/{dataReferencia}` | Agenda de Reuniões na data | `dataReferencia*` |
| 7 | `/comissao/agenda/{dataInicio}/{dataFim}` | Agenda de Reuniões no período | `dataInicio*`, `dataFim*` |
| 8 | `/comissao/agenda/mes/{mesReferencia}` | Agenda de Reuniões no mês | `mesReferencia*` |
| 9 | `/comissao/agenda/atual/iCal` | Agenda dos próximos 30 dias (iCal) | — |
| 10 | `/comissao/reuniao/{codigoReuniao}` | Detalhes de uma Reunião de Comissão | `codigoReuniao*`, `v` |
| 11 | `/comissao/reuniao/notas/{codigoReuniao}` | Notas Taquigráficas de Reunião | `codigoReuniao*`, `v` |
| 12 | `/comissao/reuniao/{sigla}/documento/{tipoDocumento}` | Documento da última Reunião de uma Comissão | `sigla*`, `tipoDocumento*` |
| 13 | `/comissao/cpi/{comissao}/requerimentos` | Requerimentos de CPI | `comissao*` |

Deprecated: `/comissao/{comissao}/documentos`

---

### 7. Composição (14 endpoints ativos, 2 deprecated)

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/composicao/mesaSF` | Mesa Diretora do Senado Federal | — |
| 2 | `/composicao/mesaCN` | Mesa Diretora do Congresso Nacional | — |
| 3 | `/composicao/lista/{tipo}` | Composição das Comissões do SF por tipo | `tipo*` |
| 4 | `/composicao/lista/cn/{tipo}` | Composição das Comissões do CN por tipo | `tipo*` |
| 5 | `/composicao/lista/partidos` | Partidos Políticos (ativos e extintos) | — |
| 6 | `/composicao/lista/blocos` | Blocos Parlamentares | — |
| 7 | `/composicao/lista/tiposCargo` | Tipos de Cargo em Comissões — referência | — |
| 8 | `/composicao/lideranca` | Lideranças em atividade | — |
| 9 | `/composicao/lideranca/tipos` | Tipos de Liderança — referência | — |
| 10 | `/composicao/lideranca/tipos-unidade` | Tipos de Unidade de Liderança — referência | — |
| 11 | `/composicao/comissao/{codigo}` | Composição de uma Comissão (membros) | `codigo*` |
| 12 | `/composicao/comissao/atual/mista/{codigo}` | Composição atual de Comissão Mista | `codigo*` |
| 13 | `/composicao/comissao/resumida/mista/{codigo}/{dataInicio}/{dataFim}` | Composição resumida de Comissão Mista por período | `codigo*`, `dataInicio*`, `dataFim*` |
| 14 | `/composicao/bloco/{codigo}` | Detalhes de um Bloco Parlamentar | `codigo*` |

Deprecated: `/composicao/lista/liderancaSF`, `/composicao/lista/liderancaCN`

---

### 8. Legislação (10 endpoints ativos, 0 deprecated)

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/legislacao/{codigo}` | Detalhes de Norma Jurídica por código | `codigo*`, `v` |
| 2 | `/legislacao/{tipo}/{numdata}/{anoseq}` | Detalhes de Norma Jurídica por identificação | `tipo*`, `numdata*`, `anoseq*`, `v` |
| 3 | `/legislacao/urn` | Detalhes de Norma Jurídica por URN | `urn*`, `v` |
| 4 | `/legislacao/lista` | Pesquisa de Normas Jurídicas | `tipo`, `numero`, `ano`, `versao`, e outros |
| 5 | `/legislacao/termos` | Termos do catálogo de legislação | — |
| 6 | `/legislacao/classes` | Classes de legislação | — |
| 7 | `/legislacao/tiposNorma` | Tipos de Norma — referência | — |
| 8 | `/legislacao/tiposPublicacao` | Tipos de Publicação — referência | — |
| 9 | `/legislacao/tiposVide` | Tipos de Vide — referência | — |
| 10 | `/legislacao/tiposdeclaracao/detalhe` | Detalhes de Declaração — referência | — |

---

### 9. Orçamento (3 endpoints ativos, 0 deprecated)

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/orcamento/lista` | Lotes de Emendas ao Orçamento | — |
| 2 | `/orcamento/oficios` | Ofícios de apoio às Emendas de Orçamento | `v` |
| 3 | `/orcamento/oficios/{numeroSedol}` | Detalhes de um Ofício | `numeroSedol*`, `v` |

---

## API ADMINISTRATIVA

**Base URL:** `adm.senado.gov.br/adm-dadosabertos/`  
**Nota:** Todos os endpoints abaixo possuem versão JSON e CSV (sufixo `/csv`), exceto 3 indicados.

### 10. Senadores — Financeiro (5 endpoints)

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/api/v1/senadores/despesas_ceaps/{ano}` | Despesas CEAPS (cota parlamentar) por ano | `ano*` |
| 2 | `/api/v1/senadores/auxilio-moradia` | Auxílio-moradia e imóvel funcional | — |
| 3 | `/api/v1/senadores/escritorios` | Escritórios de apoio dos senadores | — |
| 4 | `/api/v1/senadores/aposentados` | Senadores aposentados | — |
| 5 | `/api/v1/senadores/quantitativos/senadores` | Quantitativos por grupo | — |

---

### 11. Servidores (15 endpoints)

| # | Endpoint | Descrição | Parâmetros | CSV |
|:-:|---|---|---|:-:|
| 1 | `/api/v1/servidores/servidores` | Lista de servidores | `tipoVinculoEquals`, `situacaoEquals`, `lotacaoEquals`, `cargoEquals` | ✅ |
| 2 | `/api/v1/servidores/servidores/ativos` | Servidores ativos | — | ✅ |
| 3 | `/api/v1/servidores/servidores/inativos` | Servidores inativos | — | ✅ |
| 4 | `/api/v1/servidores/servidores/efetivos` | Servidores efetivos | — | ✅ |
| 5 | `/api/v1/servidores/servidores/comissionados` | Servidores comissionados | — | ✅ |
| 6 | `/api/v1/servidores/remuneracoes/{ano}/{mes}` | Remunerações mensais | `ano*`, `mes*` | ✅ |
| 7 | `/api/v1/servidores/pensionistas` | Pensionistas | — | ✅ |
| 8 | `/api/v1/servidores/pensionistas/remuneracoes/{ano}/{mes}` | Remunerações de pensionistas | `ano*`, `mes*` | ✅ |
| 9 | `/api/v1/servidores/horas-extras/{ano}/{mes}` | Horas extras | `ano*`, `mes*` | ✅ |
| 10 | `/api/v1/servidores/estagiarios` | Estagiários | — | ✅ |
| 11 | `/api/v1/servidores/previsao-aposentadoria` | Previsão de aposentadoria | — | ✅ |
| 12 | `/api/v1/servidores/quantitativos/pessoal` | Quantitativos de pessoal | — | ✅ |
| 13 | `/api/v1/servidores/quantitativos/cargos-funcoes` | Quantitativos de cargos e funções | — | ✅ |
| 14 | `/api/v1/servidores/cargos` | Lista de cargos | — | ❌ |
| 15 | `/api/v1/servidores/lotacoes` | Lista de lotações | — | ❌ |

---

### 12. Contratações (17 endpoints)

| # | Endpoint | Descrição | Parâmetros | CSV |
|:-:|---|---|---|:-:|
| 1 | `/api/v1/contratacoes/contratos` | Lista de contratos | `statusContratoParam`, `maoDeObraEquals`, `nomeFornecedorContains`, `cnpjCpfEquals`, `numeroContains`, `anoEquals`, `subEspecieSiglaEquals`, `objetoDescricaoContains`, `obraEngenhariaEquals` | ✅ |
| 2 | `/api/v1/contratacoes/contratos/{id}/aditivos` | Aditivos de um contrato | `id*` | ✅ |
| 3 | `/api/v1/contratacoes/contratos/terceirizados/{id}` | Terceirizados de um contrato | `id*`, `situacaoTerceirizadoParam` | ✅ |
| 4 | `/api/v1/contratacoes/licitacoes` | Lista de licitações | `statusLicitacaoParam`, `nomeFornecedorContains`, `cnpjCpfEquals`, `numProcessoContains`, `anoEquals`, `subEspecieSiglaEquals`, `objetoDescricaoContains`, `obraEngenhariaEquals` | ✅ |
| 5 | `/api/v1/contratacoes/licitacoes/{id}/detalhamentos` | Detalhamentos de uma licitação | `id*` | ✅ |
| 6 | `/api/v1/contratacoes/licitacoes/{id}/detalhamentos/{id_detalhamento}` | Detalhamento específico | `id*`, `id_detalhamento*` | ❌ |
| 7 | `/api/v1/contratacoes/empresas` | Empresas contratadas | `status`, `maoDeObraEquals`, `nomeContains`, `cnpjCpfEquals`, `pagina` | ✅ |
| 8 | `/api/v1/contratacoes/notas_empenho` | Notas de empenho | — | ✅ |
| 9 | `/api/v1/contratacoes/terceirizados` | Terceirizados ativos | — | ✅ |
| 10 | `/api/v1/contratacoes/menores_aprendizes` | Menores aprendizes | — | ✅ |
| 11 | `/api/v1/contratacoes/atas_registro_preco` | Atas de registro de preço | `status`, `nomeFornecedorContains`, `cnpjCpfEquals`, `numeroEquals`, `anoEquals`, `objetoDescricaoContains`, `obraEngenhariaEquals` | ✅ |
| 12 | `/api/v1/contratacoes/atas_registro_preco/{id}/acionamentos` | Acionamentos de ARP | `id*` | ✅ |
| 13 | `/api/v1/contratacoes/{tipoContratacao}/{id}/pagamentos` | Pagamentos por contratação | `tipoContratacao*`, `id*` | ✅ |
| 14 | `/api/v1/contratacoes/{tipoContratacao}/{id}/pagamentos/{id_pagamento}/empenhos` | Empenhos de pagamento | `tipoContratacao*`, `id*`, `id_pagamento*` | ✅ |
| 15 | `/api/v1/contratacoes/{tipoContratacao}/{id}/pagamentos/{id_pagamento}/documentos_fiscais` | Documentos fiscais | `tipoContratacao*`, `id*`, `id_pagamento*` | ✅ |
| 16 | `/api/v1/contratacoes/{tipoContratacao}/{id}/itens` | Itens de contratação | `tipoContratacao*`, `id*` | ✅ |
| 17 | `/api/v1/contratacoes/{tipoContratacao}/{id}/garantias` | Garantias | `tipoContratacao*`, `id*` | ✅ |

---

### 13. Supridos (5 endpoints)

| # | Endpoint | Descrição | Parâmetros |
|:-:|---|---|---|
| 1 | `/api/v1/supridos/{ano}` | Pessoas supridas (portadores de cartão corporativo) | `ano*` |
| 2 | `/api/v1/supridos/transacoes/{ano}` | Transações do cartão corporativo | `ano*` |
| 3 | `/api/v1/supridos/movimentacoes/{ano}` | Movimentações financeiras | `ano*` |
| 4 | `/api/v1/supridos/empenhos/{ano}` | Empenhos vinculados | `ano*` |
| 5 | `/api/v1/supridos/atosConcessao/{ano}` | Atos de concessão | `ano*` |

---

## Resumo quantitativo

### API Legislativa — endpoints ativos por grupo

| Grupo | Dados | Referência | Total |
|---|:-:|:-:|:-:|
| Parlamentar | 13 | 0 | 13 |
| Votação | 4 | 0 | 4 |
| Discurso | 8 | 1 | 9 |
| Processo | 15 | 12 | 27 |
| Plenário | 19 | 3 | 22 |
| Comissão | 12 | 1 | 13 |
| Composição | 11 | 3 | 14 |
| Legislação | 4 | 6 | 10 |
| Orçamento | 3 | 0 | 3 |
| **Subtotal** | **89** | **26** | **115** |

### API Administrativa — endpoints por grupo

| Grupo | Dados | JSON+CSV | Só JSON | Total |
|---|:-:|:-:|:-:|:-:|
| Senadores | 5 | 5 | 0 | 5 |
| Servidores | 15 | 13 | 2 | 15 |
| Contratações | 17 | 16 | 1 | 17 |
| Supridos | 5 | 5 | 0 | 5 |
| **Subtotal** | **42** | **39** | **3** | **42** |

### Total geral

| | Dados | Referência | Total |
|---|:-:|:-:|:-:|
| API Legislativa | 89 | 26 | 115 |
| API Administrativa | 42 | 0 | 42 |
| **Total** | **131** | **26** | **157** |

---

## Notas para decisões de design

1. **Dois endpoints de partidos:** `/senador/partidos` (grupo Parlamentar) e `/composicao/lista/partidos` (grupo Composição) — verificar se retornam dados idênticos ou complementares.

2. **Legislaturas:** `/plenario/lista/legislaturas` retorna a lista de legislaturas. `/plenario/legislatura/{data}` retorna a legislatura vigente numa data. Eram os endpoints "que não existiam" na Fase 03.

3. **Endpoints de referência (26):** São lookup tables estáticas. Candidatos a serem incluídos como `data/` no pacote em vez de funções.

4. **Endpoints de voto:** O principal é `/votacao` (aceita `nomeParlamentar`). O deprecated `/senador/{codigo}/votacoes` pode ainda funcionar, mas o pacote deve usar o novo.

5. **Processo vs. Matéria:** A API v4 usa `/processo/*` como caminho principal, mas 9 endpoints ativos ainda usam `/materia/*` (vetos, distribuição, tramitação). Não são deprecated — coexistem.

6. **Sessões Plenárias:** O conceito de "encontro" (`/plenario/encontro/{codigo}`) é a unidade básica — cada encontro tem pauta, resultado e resumo como sub-recursos.

7. **API Administrativa — filtros ricos:** Os endpoints de Contratações aceitam filtros como `nomeFornecedorContains`, `cnpjCpfEquals` — busca textual e por CNPJ diretamente na API.
