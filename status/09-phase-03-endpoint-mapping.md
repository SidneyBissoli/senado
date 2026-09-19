# Mapeamento de endpoints da API — Fase 03 (v2, medido)

**Projeto:** Pacote R `senado`
**Documento:** `09-phase-03-endpoint-mapping.md`
**Versão:** 2.0 — 18 de setembro de 2026. Substitui integralmente a v1 (20 de março de 2026).
**Base URL:** `https://legis.senado.leg.br/dadosabertos`
**Spec de referência:** `GET /dadosabertos/v3/api-docs` — "Dados Abertos Legislativos do Senado Federal e Congresso Nacional", versão 4.1.3.97, 157 paths, 42 marcados `deprecated`.

## Por que existe uma v2

A v1 foi montada a partir da documentação e do Swagger UI, sem requisições. Conferida contra a API em 18/09/2026, ela apoiava 11 funções em endpoints que a spec marca como **deprecated** (todo o `/materia/*`, `/senador/{codigo}/votacoes`, `/senador/{codigo}/autorias`, `/plenario/lista/votacao/*`, `/plenario/votacao/nominal/{ano}`) e continha caminhos que não respondem (`/plenario/lista/votacao/{ano}` → 400, `/materia/{codigo}/votacoes` → 404, `/plenario/agenda/{data}` → 404, `/comissao/{sigla}` → 400). A API v4 substituiu esses serviços por `/processo` e `/votacao`. O conjunto de funções também mudou: de 29 funções core na v1 para 22.

## Método

Tudo o que está neste documento foi **medido em 18/09/2026**, por requisição real com `Accept: application/json`. Para cada endpoint: status e `Content-Type`; presença e estado (`deprecated` ou não) na spec; caminho até os registros; nomes e tipos dos campos como chegam no JSON; forma da resposta sem resultado; forma da resposta para identificador inexistente; comportamento com parâmetro inválido. Onde algo **não** foi medido, está dito na seção final. Os parâmetros listados vêm da spec; os marcados "medido" foram exercitados.

Os 27 endpoints usados pelas 22 funções constam da spec como **ativos** e responderam 200.

---

## Parte 1 — Comportamentos que valem para vários endpoints

### 1.1 Duas famílias de resposta

| | Família **legada** | Família **v4** |
|---|---|---|
| Endpoints | `/senador/*`, `/comissao/*`, `/composicao/*`, `/plenario/*` | `/processo`, `/processo/*`, `/votacao` |
| Raiz do JSON | objeto com uma chave-envelope: `{"ListaX": {"Metadados": {…}, …registros…}}` | array no topo (`[ {…}, {…} ]`) ou, em `/processo/{id}`, o objeto do registro |
| Números | **chegam como texto** (`"CodigoParlamentar": "5322"`) | chegam como número (`"codigoMateria": 163100`) |
| Nomes de campo | `PascalCase` (com exceções em `camelCase`: agenda de comissões, resultado do plenário) | `camelCase` |
| Sem resultado | envelope só com `Metadados`, ou nó de registros `null` | `[]` |
| Id inexistente | **200**, envelope só com `Metadados` | **404**, `application/problem+json` |
| Parâmetro inválido | varia (404 para formato de data errado no path) | **400**, `application/problem+json` com `detail` |

Consequência para o pacote: cada função declara o caminho até os registros e a família; a conversão de tipos não pode depender do conteúdo (códigos legados são texto numérico e devem virar `integer` por especificação).

### 1.2 "Não encontrado" tem duas formas

| Requisição | Status | Corpo |
|---|:-:|---|
| `/senador/99999999` | 200 | `{"DetalheParlamentar": {Metadados…}}` — sem o nó `Parlamentar` |
| `/senador/99999999/mandatos` | 200 | `{"MandatoParlamentar": {Metadados…}}` |
| `/senador/99999999/comissoes` | 200 | `{"MembroComissaoParlamentar": {Metadados…}}` |
| `/comissao/999999` | 200 | `{"ComissoesCongressoNacional": {Metadados…}}` |
| `/composicao/comissao/999999?ativas=S` | 200 | `{"ComposicaoAtivaComissaoSf": {Metadados…}}` |
| `/senador/lista/legislatura/999` | 200 | `{"ListaParlamentarLegislatura": {Metadados…}}` |
| `/processo/1` | **404** | `{"instance": "/dadosabertos/processo/1", "status": 404, "title": "Not Found"}` |
| `/processo/abc` | **404** | `{"detail": "No static resource …", "status": 404, …}` |

Na família legada, "não existe" e "existe mas está vazio" são indistinguíveis pela resposta. Para as funções de detalhe por id, a ausência do nó de registro é tratada como não encontrado (condição `senado_error_not_found`).

### 1.3 Sem resultado

| Requisição | Corpo |
|---|---|
| `/processo?sigla=PEC&ano=1900` | `[]` |
| `/votacao?dataInicio=2024-01-01&dataFim=2024-01-02` | `[]` |
| `/processo/documento?idProcesso=1` | `[]` |
| `/comissao/agenda/20240526` (domingo) | `{"AgendaReuniao": {"Metadados": …, "reunioes": {"reuniao": null}}}` |
| `/plenario/agenda/dia/20240526` | `{"AgendaPlenario": {Metadados…}}` — sem o nó `Sessoes` |
| `/plenario/resultado/20240526` | `{"ResultadoPlenario": {Metadados…}}` — sem o nó `Sessoes` |
| `/senador/5322/discursos` (sem discursos no período) | `…"Parlamentar": {"IdentificacaoParlamentar": {…}, "Pronunciamentos": null, …}` |
| `/plenario/legislatura/18000101` | `{"ListaLegislatura": {Metadados…}}` |
| `/comissao/lista/xyz` (tipo inválido) | 200, `{"ListaBasicaComissoes": {Metadados…}}` |

Correção de registro anterior: chegou a ser anotado que `/votacao` sem resultado devolvia `{}`. O corpo literal é `[]`.

### 1.4 Objeto-versus-array nos serviços legados

Quando um nó repetível tem **um** elemento, alguns serviços legados devolvem o objeto sozinho em vez de um array de um elemento.

| Nó | Medido |
|---|---|
| `/comissao/agenda/{data}` → `reuniao[].partes` | **objeto** em 10 reuniões, **array** (2 ou 3) em 3 — a armadilha existe |
| `/comissao/agenda/{data}` → `reuniao[].colegiados` | objeto nas 13 reuniões da amostra (nenhuma conjunta); tratar como o anterior |
| `/comissao/agenda/{data}` → `reuniao[].dataReuniao` | array em todas |
| `/senador/lista/legislatura/57` → `Mandatos.Mandato` | array em todos (244 com 1 elemento, 1 com 2) — sem armadilha |
| `/senador/{codigo}/mandatos` → `Mandato`, `Suplente` | array, inclusive com 1 elemento |
| `/plenario/agenda/dia/{data}` → `Sessao` | array com 1 elemento |
| `/plenario/legislatura/{data}` → `Legislatura` | array com 1 elemento |

Regra para o pacote: ao ler nó repetível de serviço legado, normalizar — objeto com nomes vira lista de um elemento. Com `jsonlite::fromJSON(simplifyVector = TRUE)` o mesmo nó vira ora `data.frame`, ora `list`; por isso o parse desses nós deve usar `simplifyVector = FALSE`.

### 1.5 Formatos de data

| Onde | Formato |
|---|---|
| Parâmetros de query em `/processo`, `/processo/documento`, `/votacao` | `AAAA-MM-DD`. `/votacao` rejeita `AAAAMMDD` (400 "Invalid request content") e, sem estar documentado, aceita `DD/MM/AAAA` |
| Parâmetros de path em `/plenario/*` e `/comissao/agenda/*` | `AAAAMMDD` (com hífen → 404). Mês em `/comissao/agenda/mes/` é `AAAAMM` (medido: `202405`); em `/plenario/agenda/mes/` e `/plenario/resultado/mes/` a spec pede `AAAAMMDD` (medido com o dia 01: `20240501`) |
| Parâmetros de query em `/senador/{codigo}/discursos` | `AAAAMMDD` |
| Campos de resposta v4 | `"2024-05-08"`, `"2024-04-16 13:59:53"`, `"2017-01-01T00:00:00"`, `"2026-07-01T10:27:23.914"` |
| Campos de resposta legados | `"2023-02-01"`; **mas** `/comissao/{codigo}` usa `"01/01/1900"` e `/plenario/resultado` usa `"22/05/2024"`; `Metadados.Versao` usa `"18/09/2026 14:19:54"` |

### 1.6 Limites e truncamentos

| Endpoint | Comportamento medido |
|---|---|
| `/processo` | **Não pagina.** Resposta inteira; `pagina`, `page`/`size`, `limit`/`offset` são ignorados em silêncio. Janela de datas > 1 ano sem outro filtro obrigatório → **400** "Limite o período a um ano ou informe um dos parâmetros obrigatórios." `numdias` > 30 → 400. Sem nenhum parâmetro → assume `tramitando=S` (10.780 registros) |
| `/votacao` | **Não pagina nem trunca.** Contagem anual conferida contra fonte independente (`/dados/ListaVotacoes{ano}.json`): 2012 = 82, 2013 = 180, 2014 = 85, 2017 = 146, 2018 = 112, 2019 = 133, 2021 = 225, 2024 = 95 — todas iguais. Janela > 1 ano → **400** "Limite o período a 1 ano…". Sem nenhum parâmetro → últimos 12 meses (93 registros) |
| `/senador/{codigo}/discursos` | **Trunca em silêncio.** A janela é reduzida a 1 ano antes de `dataFim`, sem erro nem aviso. Medido (senador 825): `20230101–20241231` devolve o mesmo que `20240101–20241231` (138); `20230101–20240630` devolve só de 2023-07-04 em diante. Não há teto de linhas (2019 tem 223). Sem datas → últimos 30 dias. **O pacote precisa fatiar por ano sempre que a janela passar de 1 ano** |
| Tempo de resposta | Maior medido: `/processo?tramitouLegislaturaAtual=S` — 45,7 s, 26.212 registros, 21 MB. `/processo?tramitando=S` — 19,7 s. `/comissao/agenda/mes/202405` — 1,1 s, 6,45 MB. Demais abaixo de 2 s |

### 1.7 Lacuna nos dados de origem: votações nominais de 2015 e 2016

`/votacao` devolve 17 votações em 2015 e 13 em 2016, contra 85 em 2014 e 146 em 2017. O arquivo anual do serviço antigo mostra a mesma queda (17 e 7). Não é paginação nem defeito de cliente: o registro publicado está incompleto nesses anos. A documentação de `sen_votes()` e `sen_vote_records()` deve avisar.

### 1.8 Parâmetro `v`

Quase todos os endpoints aceitam `v` (inteiro): "Versão do serviço. Exemplificada a última disponível." Sem `v`, vale a versão mais recente, que é a que foi medida (o número aparece em `Metadados.VersaoServico` nos serviços legados). O pacote não envia `v`.

### 1.9 Redirecionamentos

`/plenario/lista/legislaturas`, `/senador/partidos` e `/comissao/lista/colegiados` respondem **301** para arquivos estáticos em `/dados/*.json` (`ListaLegislatura.json`, `ListaPartidos.json`, `ListaColegiados.json`), atualizados uma vez por dia (`Metadados.Versao` com a hora da geração). O cliente HTTP precisa seguir redirecionamento; o httr2 segue por padrão.

---

## Parte 2 — Função por função

Convenção dos quadros: **Registros** é o caminho, dentro do JSON, até o array de registros. Tipos entre parênteses são os do JSON (`txt` = texto, `int` = número inteiro); "txt-num" marca texto que contém número e deve virar `integer` na especificação de colunas.

### Módulo 3.1 — Dados de referência

#### `sen_legislatures()`

| | |
|---|---|
| **Endpoint** | `GET /plenario/lista/legislaturas` (301 → `/dados/ListaLegislatura.json`) |
| **Família** | legada |
| **Parâmetros** | nenhum |
| **Registros** | `ListaLegislatura.Legislaturas.Legislatura[]` — 58 |
| **Campos** | `NumeroLegislatura` (txt-num), `DataInicio`, `DataFim`, `DataEleicao` (txt `AAAA-MM-DD`), `SessoesLegislativas.SessaoLegislativa[]` (aninhado) |
| **Observação** | Inclui a legislatura futura (58ª, 2027–2031). Ordem decrescente |

#### Legislatura vigente (função interna, default do argumento `legislature`)

| | |
|---|---|
| **Endpoint** | `GET /plenario/legislatura/{data}` — `data` em `AAAAMMDD` |
| **Registros** | `ListaLegislatura.Legislaturas.Legislatura[]` — 1 elemento (array) |
| **Campos** | os mesmos de `sen_legislatures()`; em 18/09/2026 → `NumeroLegislatura = "57"` |
| **Sem resultado** | data fora de qualquer legislatura → envelope sem `Legislaturas` |

#### `sen_parties()`

| | |
|---|---|
| **Endpoint** | `GET /senador/partidos` (301 → `/dados/ListaPartidos.json`) |
| **Parâmetros** | nenhum |
| **Registros** | `ListaPartidos.Partidos.Partido[]` — 108 (ativos e extintos) |
| **Campos** | `Codigo` (txt-num), `Sigla`, `Nome`, `DataCriacao`, `DataExtincao` (só nos extintos; conferido nos 108 registros) |

#### `sen_bill_types()`

| | |
|---|---|
| **Endpoint** | `GET /processo/siglas` |
| **Família** | v4 (array no topo) — 184 registros |
| **Campos** | `sigla`, `descricao`, `dataInicio`, `dataFim` (txt `AAAA-MM-DDTHH:MM:SS`; `dataFim` nulo nas vigentes) |
| **Uso** | valores aceitos por `sen_bills(type = )` |

#### `sen_bill_statuses()`

| | |
|---|---|
| **Endpoint** | `GET /processo/tipos-situacao` |
| **Família** | v4 — 175 registros |
| **Campos** | `id` (int), `sigla`, `descricao`, `dataInicio`, `dataFim` |
| **Uso** | valores aceitos por `sen_bills(status = )` → parâmetro `siglaSituacao` |

### Módulo 3.2 — Senadores

#### `sen_senators()`

| | |
|---|---|
| **Endpoints** | `GET /senador/lista/atual` · `GET /senador/lista/legislatura/{legislatura}` · `GET /senador/lista/legislatura/{legislaturaInicio}/{legislaturaFim}` |
| **Parâmetros (API → argumento)** | `uf` → `state` (**filtro no servidor**; medido: `uf=SP` → 3) · `participacao` = `T`/`S` → titular/suplente (medido: `S` → 9) · `exercicio` = `S`/`N` (só nas listas por legislatura) |
| **Registros** | `ListaParlamentarEmExercicio.Parlamentares.Parlamentar[]` (81) · `ListaParlamentarLegislatura.Parlamentares.Parlamentar[]` (245 na 57ª; 963 para 49–57 em 1 requisição, 0,7 s, 1 MB) |
| **Campos — lista atual** | `IdentificacaoParlamentar.{CodigoParlamentar (txt-num), CodigoPublicoNaLegAtual, NomeParlamentar, NomeCompletoParlamentar, SexoParlamentar, FormaTratamento, UrlFotoParlamentar, UrlPaginaParlamentar, EmailParlamentar, SiglaPartidoParlamentar, UfParlamentar, MembroMesa, MembroLideranca}`, `…Bloco.{CodigoBloco, NomeBloco, NomeApelido, DataCriacao}`, `…Telefones.Telefone[]`; `Mandato.{CodigoMandato, UfParlamentar, DescricaoParticipacao, PrimeiraLegislaturaDoMandato.*, SegundaLegislaturaDoMandato.*, Suplentes.Suplente[], Exercicios.Exercicio[]}` |
| **Campos — lista por legislatura** | `IdentificacaoParlamentar.{CodigoParlamentar, NomeParlamentar, NomeCompletoParlamentar, SexoParlamentar, FormaTratamento}`; `Mandatos.Mandato[].{CodigoMandato, UfParlamentar, DescricaoParticipacao, PrimeiraLegislaturaDoMandato.*, SegundaLegislaturaDoMandato.*, Titular.*, Suplentes.Suplente[]}` |
| **⚠️ Partido** | **A lista por legislatura não traz partido** — nem na identificação, nem no mandato. Partido só existe na lista atual. Consequência: o filtro `party` só vale para senadores em exercício; nas listas históricas a coluna `party` sai `NA`. O partido por período está em `/senador/{codigo}/mandatos` (`Partidos.Partido[]`) e o partido na data de cada voto, em `/votacao` |
| **Id inexistente** | legislatura 999 → 200, envelope sem `Parlamentares` → tibble de 0 linhas |

#### `sen_senator()`

| | |
|---|---|
| **Endpoint** | `GET /senador/{codigo}` |
| **Registros** | `DetalheParlamentar.Parlamentar` (objeto único) |
| **Campos** | `IdentificacaoParlamentar.*` (11, como na lista atual, mais `UrlPaginaParticular`); `DadosBasicosParlamentar.{DataNascimento, Naturalidade, UfNaturalidade, EnderecoParlamentar}`; `Telefones.Telefone[]`; `OutrasInformacoes.Servico[]` (links para outros serviços — descartar) |
| **Id inexistente** | 200, sem o nó `Parlamentar` → `senado_error_not_found` |
| **Fora da spec** | `/senador/{codigo}/historico` responde 200 mas **não consta da spec**; não usar |

#### `sen_senator_mandates()`

| | |
|---|---|
| **Endpoint** | `GET /senador/{codigo}/mandatos` |
| **Registros** | `MandatoParlamentar.Parlamentar.Mandatos.Mandato[]` |
| **Campos** | `CodigoMandato`, `UfParlamentar`, `DescricaoParticipacao`, `PrimeiraLegislaturaDoMandato.{NumeroLegislatura, DataInicio, DataFim}`, `SegundaLegislaturaDoMandato.*`; aninhados: `Suplentes.Suplente[]`, `Exercicios.Exercicio[]` (`CodigoExercicio`, `DataInicio`, e fim/causa quando houver), `Partidos.Partido[]` (`CodigoPartido`, `Sigla`, `Nome`, `DataFiliacao`, e desfiliação quando houver) |
| **Desenho** | uma linha por mandato; suplentes, exercícios e partidos como colunas-lista, ou argumento que escolhe qual desaninhar |

#### `sen_senator_committees()`

| | |
|---|---|
| **Endpoint** | `GET /senador/{codigo}/comissoes` |
| **Parâmetros** | `ativo` = `S` (só atuais) / `N` (só finalizadas) — medido: todas = 83, `ativo=S` = 11 · `comissao` = sigla. *(A v1 chamava o parâmetro de `indAtivos`; o nome correto é `ativo`.)* |
| **Registros** | `MembroComissaoParlamentar.Parlamentar.MembroComissoes.Comissao[]` |
| **Campos** | `IdentificacaoComissao.{CodigoComissao (txt-num), SiglaComissao, NomeComissao, SiglaCasaComissao}`, `DescricaoParticipacao`, `DataInicio`, `DataFim` |
| **Observação** | inclui colegiados do Congresso (`SiglaCasaComissao = "CN"`), grupos e frentes parlamentares |

#### `sen_senator_speeches()`

| | |
|---|---|
| **Endpoint** | `GET /senador/{codigo}/discursos` |
| **Parâmetros** | `dataInicio`, `dataFim` (`AAAAMMDD`) · `casa` · `numeroSessao` · `tipoSessao` |
| **⚠️ Janela** | sem datas → últimos 30 dias. Janela > 1 ano → **truncada em silêncio** a 1 ano antes de `dataFim` (ver 1.6). A função fatia por ano |
| **Registros** | `DiscursosParlamentar.Parlamentar.Pronunciamentos.Pronunciamento[]` |
| **Campos** | `CodigoPronunciamento` (txt-num), `DataPronunciamento`, `TipoUsoPalavra.{Codigo, Sigla, Descricao}`, `SiglaPartidoParlamentarNaData`, `UfParlamentarNaData`, `SiglaCasaPronunciamento`, `TextoResumo`, `Indexacao`, `UrlTexto`, `UrlTextoBinario`, `SessaoPlenaria.{CodigoSessao, SiglaTipoSessao, NumeroSessao, DataSessao, HoraInicioSessao, …}`, `Publicacoes.Publicacao[]` |
| **Sem resultado** | `Pronunciamentos: null` |
| **Observação** | o texto do discurso não vem; vem o resumo e as URLs. Texto integral: `/discurso/texto-integral/{codigoPronunciamento}` (fora do escopo) |

### Módulo 3.3 — Matérias legislativas

#### `sen_bills()`

| | |
|---|---|
| **Endpoint** | `GET /processo` |
| **Família** | v4 — array no topo |
| **Parâmetros (API → argumento)** | `sigla` → `type` · `numero` → `number` · `ano` → `year` · `termo` → `keyword` · `autor` → `author` · `codigoParlamentarAutor` → `author_code` · `siglaSituacao` → `status` · `tramitando` (`S`/`N`) → `in_progress` · `dataInicioApresentacao`/`dataFimApresentacao` (`AAAA-MM-DD`) → `start_date`/`end_date` · `numdias` (**máx. 30**) → `updated_days` · `codigoMateria`, `idProcesso` (usados internamente) |
| **Outros parâmetros da spec, não expostos** | `tramitouLegislaturaAtual`, `codigoColegiadoTramitando`, `situacao`, `siglaTipoDocumento`, `siglaTipoConteudo`, `codigoClasse`, `codAssuntoGeral`, `codAssuntoEspecifico`, `casa`, `siglaEnteIdentificador`, `dataInicioDeliberacao`/`dataFimDeliberacao`, `siglaTipoDeliberacao`, `tipoNorma`, `numeroNorma`, `anoNorma`, `alteracao` |
| **Regra da API** | é obrigatório ao menos um de: `numero`, `ano`, `idProcesso`, `codigoMateria`, `tramitando=S`, `tramitouLegislaturaAtual=S`, `codigoParlamentarAutor`, `codigoClasse`, `codAssuntoEspecifico`, `sigla` + `siglaEnteIdentificador`, datas de apresentação ou deliberação, `numeroNorma`, `anoNorma`, `numdias`. Sem nenhum, assume `tramitando=S`. Medido: `sigla` sozinha funciona e **não** aplica filtro implícito (`sigla=PL` → 8.124 = 5.122 tramitando + 3.002 encerrados) |
| **Campos** | `id` (int) → `process_id` · `codigoMateria` (int) → `bill_code` · `identificacao` ("PEC 1/2024") · `ementa` · `autoria` (texto único, autores separados por vírgula) · `tipoDocumento` · `tipoConteudo` · `objetivo` ("Iniciadora"/"Revisora") · `casaIdentificadora` · `enteIdentificador` · `dataApresentacao` · `situacaoAtual` · `dataSituacaoAtual` · `tramitando` ("Sim"/"Não") · `dataUltimaAtualizacao` · `ultimaInformacaoAtualizada` · `urlDocumento`; presentes só em parte dos registros: `dataDeliberacao`, `siglaTipoDeliberacao`, `normaGerada`, `apelido` |
| **Tamanhos medidos** | `ano=2023` → 5.428 (4,3 MB, 9,3 s) · `codigoParlamentarAutor=825` → 4.337 (3,8 MB, 7,2 s) · `termo=saude` → 845 |
| **Relação entre as chaves** | 1 para 1: nos 5.428 processos de 2023 todo registro tem `codigoMateria` e nenhum código se repete. `codigoMateria` é o número da URL do portal (`…/materias/-/materia/161942`) |

#### `sen_bill()`, `sen_bill_authors()`, `sen_bill_proceedings()`

As três leem **a mesma resposta**; com o cache, custam 1 requisição.

| | |
|---|---|
| **Endpoint** | `GET /processo/{id}` — `id` é o `idProcesso`. **Não aceita `codigoMateria`** (`/processo/161942` → 404) |
| **Resolução de `code`** | `GET /processo?codigoMateria={code}` → campo `id` (1 requisição, cacheável) |
| **Raiz** | o próprio objeto do processo (sem envelope, sem array) |
| **`sen_bill()` — campos escalares** | `id`, `codigoMateria`, `identificacao`, `sigla`, `descricaoSigla`, `numero` (txt), `ano` (int), `objetivo`, `casaIdentificadora`, `siglaEnteIdentificador`, `tramitando`, `dataInicioEfetivo`, `situacaoAtual`, `siglaSituacaoAtual`, `dataSituacaoAtual`, `idProcessoCasaInicial`, `identificacaoProcessoInicial`, `siglaCasaIniciadora`; objetos: `conteudo.{id, siglaTipo, tipo, ementa, tipoNormaIndicada}`, `documento.{id, siglaTipo, tipo, dataApresentacao, indexacao, url, resumoAutoria}`, `deliberacao.{data, siglaTipo, tipoDeliberacao, siglaDestino, destino}`, `normaGerada.{codigo, siglaTipo, tipo, numero, anoAssinatura, dataAssinatura, descricao, dataPublicacao, …}` |
| **Arrays não usados na v0.1** | `classificacoes[]`, `outrosNumeros[]`, `processosRelacionados[]`, `despachos[]`, `autuacoes[].situacoes[]` (histórico de situações), `autuacoes[].movimentacoes[]` (remessas entre órgãos) |
| **`sen_bill_authors()`** | `autoriaIniciativa[]`: `autor`, `siglaTipo`, `descricaoTipo`, `ordem`, `outrosAutoresNaoInformados`, `codigoParlamentar`, `sexo`, `uf`, `siglaPartido`, `partido`, `siglaCargo`, `cargo`, `idEnte`, `siglaEnte`, `casaEnte`, `ente` (campos de parlamentar vêm nulos quando o autor é um ente) |
| **⚠️ Duas autorias** | `autoriaIniciativa[]` é quem teve a iniciativa; `documento.autoria[]` é o autor do documento que chegou ao Senado. **Podem diferir**: no PLP 233/2023 a iniciativa é "Presidência da República" e o documento é da "Câmara dos Deputados". `sen_bill_authors()` usa `autoriaIniciativa` |
| **`sen_bill_proceedings()`** | `autuacoes[].informesLegislativos[]`: `id` (int), `data` (`AAAA-MM-DD HH:MM:SS`), `descricao` (texto livre, chega a 1.388+ caracteres), `colegiado.{codigo, casa, sigla, nome}`, `enteAdministrativo.{id, casa, sigla, nome}`, `idSituacaoIniciada`, `siglaSituacaoIniciada`, `documentosAssociados[]` (`id`, `tipo`, `siglaTipo`, `identificacao`, `data`, `autoria`, `url`). Medido: 57 informes no PLP 233/2023; os do Plenário narram cada votação com resultado e placar |
| **Id inexistente** | 404 → `senado_error_not_found` |

#### `sen_bill_documents()`

| | |
|---|---|
| **Endpoint** | `GET /processo/documento?idProcesso={id}` (a spec lista também `codigoMateria`; não exercitado) |
| **Família** | v4 — array no topo; PLP 233/2023 → 60 documentos |
| **Outros parâmetros** | `idDocumento`, `dataInicio`/`dataFim`, `codigoParlamentarAutor`, `idEnteAutor`, `codigoColegiado`, `siglaColegiado`, `sigla`, `siglaTipo` |
| **Campos** | `id` (int), `identificacao`, `descricao`, `siglaTipo`, `descricaoTipo`, `dataDocumento`, `dataRecebimento`, `autoria` (texto), `urlDocumento`, `siglaEnteRecebedor`, `nomeEnteRecebedor`, `siglaColegiadoRecebedor`, `nomeColegiadoRecebedor`, `casaRecebedora`; aninhados: `autores[]` (mesma forma de `autoriaIniciativa`), `apresentadoNosProcessos[]` (`id`, `identificacao`, `papelNoProcesso`, `tramitando`) |
| **Observação** | devolve metadados e URL de cada documento, não o texto |

### Módulo 3.4 — Votações

#### `sen_votes()` e `sen_vote_records()`

| | |
|---|---|
| **Endpoint** | `GET /votacao` — as duas funções leem a mesma resposta |
| **Família** | v4 — array no topo, uma votação por elemento, com os votos aninhados em `votos[]` |
| **Parâmetros (API → argumento)** | `dataInicio`/`dataFim` (`AAAA-MM-DD`) → `start_date`/`end_date` e `year` · `codigoMateria` → `bill` · `codigoParlamentar` → `senator` · `codigoSessao` → `session_id` (medido: 399276 → 4 votações) · `idProcesso` · `sigla`, `numero`, `ano` (da proposição; medido: `ano=2024&sigla=PEC`) · `nomeParlamentar`, `siglaVotoParlamentar` (não expostos) |
| **⚠️ Não existe** | filtro por id de votação: `codigoSessaoVotacao=…` é ignorado em silêncio e devolve o default de 12 meses |
| **Campos da votação** | `codigoSessaoVotacao` (int) → `vote_id` · `codigoSessao` (int) → `session_id` · `dataSessao` · `numeroSessao`, `siglaTipoSessao`, `casaSessao`, `codigoSessaoLegislativa`, `sequencialSessao`, `sequencialVotacao` · `codigoMateria` → `bill_code` · `idProcesso` → `process_id` · `identificacao`, `sigla`, `numero` (txt), `ano` (int), `ementa`, `dataApresentacao` · `descricaoVotacao` · `resultadoVotacao` ("A", "R", …) · `votacaoSecreta` ("S"/"N") · `totalVotosSim`, `totalVotosNao`, `totalVotosAbstencao` · `informeLegislativo.*` (13 campos; `texto` chega a 1.505 caracteres) |
| **Campos de `votos[]`** | `codigoParlamentar` (int) → `senator_code` · `nomeParlamentar` · `sexoParlamentar` · `siglaPartidoParlamentar` · `siglaUFParlamentar` · `siglaVotoParlamentar` → `vote` · `descricaoVotoParlamentar` |
| **⚠️ Totais** | `totalVotos*` **nem sempre vêm preenchidos**: nas 4 votações do PLP 233/2023 vieram nulos, com os 81 votos presentes. `sen_votes()` calcula os totais a partir de `votos[]`; em votação secreta, usa os campos da API |
| **Votação secreta** | `votacaoSecreta = "S"`; `votos[]` traz os 81 senadores com `siglaVotoParlamentar = "Votou"` |
| **Partido** | é o **da data do voto**: votos de 2019 trazem "DEM"; 28 de 55 senadores presentes em 2019 e em 2024 têm partido diferente nos dois períodos |
| **Valores de voto observados (2023 inteiro, 11.421 votos)** | "Votou" (5.072 — votações secretas), "Sim" (2.431), "P-NRV" (1.710), "Não" (894), "AP" (643), "LS" (346), "MIS" (213), "Presidente (art. 51 RISF)" (53), "NCom" (24), "LP" (18), "Abstenção" (9) e **"NA"** (8). Tabela de significados: `GET /plenario/lista/tiposComparecimento`. `descricaoVotoParlamentar` vem preenchida em cerca de um quarto dos votos |
| **⚠️ O voto "NA"** | "NA" é uma sigla de voto **literal**, não um valor ausente. Qualquer conversão que trate a string "NA" como faltante (o default de `readr` e de `type.convert()`) apaga esses votos. A coluna `vote` é `character` por especificação e não passa por conversão automática |
| **Resultados observados (2023)** | `resultadoVotacao`: "A" (131), "R" (10) |
| **Cobertura** | desde 1991 (23 votações; 0 em 1988). Volume: 2024 → 95 votações, 7.695 votos, 1 requisição; 2021 → 225 votações, 18.220 votos. Lacuna de origem em 2015–2016 (ver 1.7) |
| **Sem resultado** | `[]` |

### Módulo 3.5 — Comissões

#### `sen_committees()`

| | |
|---|---|
| **Endpoints** | `GET /comissao/lista/colegiados` (301 → `/dados/ListaColegiados.json`) · `GET /comissao/lista/{tipo}`, `tipo` ∈ `permanente`, `temporaria`, `cpi`, `orgaos` |
| **Registros** | `ListaColegiados.Colegiados.Colegiado[]` — 218 · `ListaBasicaComissoes.colegiado.colegiados[].colegiado[]` — 16 permanentes, 3 temporárias, 2 CPIs |
| **Campos — colegiados** | `Codigo` (txt-num), `Sigla`, `Nome`, `DataInicio`, `Publica`, `CodigoTipoColegiado`, `SiglaTipoColegiado`, `DescricaoTipoColegiado`, `SiglaCasa`, `Finalidade` |
| **Campos — lista por tipo** | `CodigoColegiado`, `SiglaColegiado`, `NomeColegiado`, `DataInicio`, `IndicadorDistrPartidaria`, `tipocolegiado.{CodigoTipoColegiado, DescricaoTipoColegiado, SiglaTipoColegiado, SiglaCasa, …}`; nas temporárias e CPIs também `DescricaoSubtitulo`, `TextoFinalidade` |
| **Recomendação** | usar `/comissao/lista/colegiados` como fonte única (já traz o tipo em `SiglaTipoColegiado` e a casa) e filtrar `type` no cliente; evita três requisições e três formatos |
| **⚠️ Só ativos** | as listas não trazem colegiados extintos (não há campo de data de fim) |
| **Siglas repetidas** | entre os 218, só `PLEN` (Plenário do SF, 1998; Plenário do CN, 1999). Nas três listas por tipo, nenhuma |
| **Tipo inválido** | `/comissao/lista/xyz` → 200, envelope vazio |

#### `sen_committee()`

| | |
|---|---|
| **Endpoint** | `GET /comissao/{codigo}` — **código numérico**; sigla → 400 "Type mismatch." |
| **Registros** | `ComissoesCongressoNacional.Colegiados.Colegiado[]` — 1 elemento |
| **Campos** | `CodigoColegiado`, `SiglaColegiado`, `NomeColegiado`, `DataInicio` (**`DD/MM/AAAA`**), `TipoColegiado.{TipoColegiado, SiglaCasa, CodigoTipo}`, `QuantidadesMembros.Distribuicao.{Senadores, SenadoresTitulares, SenadoresSuplentes}`, `InformacoesSecretaria.{Secretario, TelefoneSecretaria, eMail, NumeroFax, AgendaReuniao}`; aninhados: `Cargos.Cargo[]` (`TipoCargo`, `CodigoCargo`, `NomeParlamentar`, `CodigoParlamentar`, `Bancada`), `MembrosBlocoSF.PartidoBloco[]`, `EventosProrrogacao`, `ObservacoesVaga`, `ObservacoesComissao` |
| **Id inexistente** | 200, envelope sem `Colegiados` → `senado_error_not_found` |
| **⚠️ Comissão extinta** | **`/comissao/{codigo}` não devolve colegiado extinto**: responde 200 com o envelope vazio, igual a um código inexistente. Medido em quatro colegiados do Senado já encerrados e fora da lista de ativos (códigos obtidos em `/senador/5322/comissoes?ativo=N`): CPIDPRO (1900, encerrada em 2015), CPIDFDQ (1928, 2016), CDHINT (2170, 2018) e CPIMJAE (2659, 2025). `sen_committee()` só descreve colegiados em atividade, e a mensagem de erro deve dizer isso |
| **Resolução de sigla** | pela lista de colegiados (cache): 1 ocorrência → resolve; mais de uma → erro com os códigos candidatos; nenhuma → erro explicando que a sigla só resolve colegiados em atividade |

#### `sen_committee_members()`

| | |
|---|---|
| **Endpoint** | `GET /composicao/comissao/{codigo}?ativas=S\|N` |
| **⚠️ `ativas` é obrigatório** | sem ele → 400 "Required query parameter 'ativas' is not present." (a spec diz "para todas, não informe", o que não corresponde ao comportamento) |
| **⚠️ Envelope muda** | `ativas=S` → `ComposicaoAtivaComissaoSf`; `ativas=N` → `UltimaComposicaoComissaoSf` |
| **Registros** | `{envelope}.ComposicaoComissao.Membros.Membro[]` — 52 na CCJ com `ativas=S` |
| **Campos** | `CodigoMembro` (txt-num) → `senator_code`, `NomeMembro`, `TipoVaga` ("Titular"/"Suplente"), `IndicadorVagaAtiva`, `DataInicioMembroVaga`; identificação em `…IdentificacaoComissao[]` |
| **Comissão extinta** | **funciona**: para os mesmos quatro colegiados encerrados, `ativas=N` devolveu a última composição (10, 17, 6 e 16 membros). Com `ativas=S`, três devolveram os mesmos membros e a CPIMJAE devolveu zero — `ativas=N` é o valor que sempre traz a composição |
| **Limitação** | **não traz partido nem UF do membro.** `/comissao/{codigo}` traz, em `MembrosBlocoSF.PartidoBloco[].MembrosSF.Membro[]`: `NomeParlamentar`, `CodigoParlamentar`, `SiglaUf`, `Partido`, `TipoVaga`, `ProprietarioVaga`, `NumeroOrdem` — agrupados por bloco. Como `sen_committee()` e esta função podem ler a mesma resposta de `/comissao/{codigo}`, vale decidir na implementação qual das duas fontes usar |

#### `sen_committee_meetings()`

| | |
|---|---|
| **Endpoints** | `GET /comissao/agenda/{dataReferencia}` · `GET /comissao/agenda/{dataInicio}/{dataFim}` · `GET /comissao/agenda/mes/{mesReferencia}` — datas `AAAAMMDD`, mês `AAAAMM` |
| **Fora da spec** | `/agendareuniao/{data}` responde o mesmo conteúdo (medido: 459.818 bytes idênticos) mas **não consta da spec**; não usar |
| **Registros** | `AgendaReuniao.reunioes.reuniao[]` — 13 em 22/05/2024 (1,2 MB); semana 20–24/05/2024 → 1,96 MB; mês 05/2024 → 6,45 MB, 1,1 s |
| **Campos (camelCase, todos texto)** | `codigo`, `titulo`, `descricao`, `dataInicio` (`AAAA-MM-DDTHH:MM:SS.mmm`), `situacao`, `codigoSituacao`, `realizada`, `confirmada`, `secreta` ("true"/"false" como **texto**), `local`, `tipoPresenca`, `tipo.{codigo, descricao, sigla}`, `colegiadoCriador.{codigo, sigla, nome, siglaCasa, codigoTipo, descricaoTipo}`, `sessaoLegislativa.*`, `presidente.*`, URLs de pauta, resultado e ata; aninhados: `partes` (⚠️ objeto **ou** array — ver 1.4) com `evento.{finalidade, resultadoTexto, convidados[], participantes[]}`, `colegiados`, `dataReuniao[]` |
| **Filtro por comissão** | não há no servidor; filtrar no cliente por `colegiadoCriador.sigla`/`codigo` |
| **Sem resultado** | `reuniao: null` |
| **Observação** | inclui colegiados do Congresso e frentes parlamentares (`siglaCasa = "CN"`) |

### Módulo 3.6 — Plenário

#### `sen_agenda()`

| | |
|---|---|
| **Endpoints** | `GET /plenario/agenda/dia/{data}` · `GET /plenario/agenda/mes/{data}` — `AAAAMMDD` |
| **Registros** | `AgendaPlenario.Sessoes.Sessao[]` — 1 em 22/05/2024; mês 05/2024 → 0,23 MB |
| **Campos** | `CodigoSessao` (txt-num) → `session_id`, `Data`, `Hora`, `DiaSemana`, `NumeroSessao`, `TipoSessao`, `LocalSessao`, `Casa`, `Legislatura`, `SessaoLegislativa`, `SituacaoSessao`, `CodigoSituacaoSessao`, `Realizada.Status`, `PautaConfirmada`, `DescricaoTipoPresenca`; aninhados: `Materias.Materia[]` (`CodigoMateria` → `bill_code`, `DescricaoIdentificacaoMateria`, `SiglaMateria`, `NumeroMateria`, `AnoMateria`, `Ementa`, `Parecer`, `Apreciacao`, `NomeAutor`, `DescricaoTipoPauta`, `SequenciaOrdem`), `Oradores.TipoOrador[].OradorSessao.Orador[]` |
| **Observação** | cobre os plenários do Senado **e** do Congresso (campo `Casa`). Textos com espaços e quebras de linha sobrando (`"64ª SESSÃO "`, `Identificacao` com `\n`) — aparar na conversão |
| **Sem resultado** | envelope sem `Sessoes` |
| **Desenho** | uma linha por sessão, com `Materias` como coluna-lista, **ou** uma linha por item de pauta; decidir na especificação de colunas |

#### `sen_sessions()`

| | |
|---|---|
| **Endpoints** | `GET /plenario/resultado/{data}` · `GET /plenario/resultado/mes/{data}` — `AAAAMMDD` |
| **Registros** | `ResultadoPlenario.Sessoes.Sessao[]`; mês 05/2024 → 0,22 MB |
| **Campos (camelCase)** | `codigoSessao` (txt-num) → `session_id`, `numeroSessao`, `dataSessao` (**`DD/MM/AAAA`**), `horaSessao`, `tipoSessao` (sigla), `descricaoTipoSessao`, `siglaCasa`; aninhado `Itens.Item[]`: `codigoItem`, `codigoMateria` → `bill_code`, `idIdentificacao`, `siglaMateria`, `numeroMateria`, `anoMateria`, `DescricaoIdentificacaoMateria`, `textoResultado`, `descricaoDeliberacao`, `descricaoTipoApreciacao`, `autorMateria`, `sequencialItem`, `descricaoTipoPauta` |
| **Ligação com votos** | `codigoSessao` é o mesmo `codigoSessao` de `/votacao` (`session_id`) |
| **Sem resultado** | envelope sem `Sessoes` |

### Fase 05 — `sen_vote_matrix()`

Não tem endpoint: recebe a saída de `sen_vote_records()`. Dados de apoio: `GET /plenario/lista/tiposComparecimento` ("tipos de comparecimento em Votação" — `Sigla`, `Descricao`: AFO, AP, AUS, CAS, DIS, DJ, EP, EPR, FAL, GR, IL, IMP, L1, L2, …) para documentar a codificação dos votos.

---

## Parte 3 — Quadro-resumo

| Função | Endpoint | Família | Registros | Vazio | Id inexistente |
|---|---|:-:|---|---|---|
| `sen_legislatures()` | `/plenario/lista/legislaturas` | leg. | `ListaLegislatura.Legislaturas.Legislatura[]` | — | — |
| *(interna)* | `/plenario/legislatura/{data}` | leg. | idem | sem `Legislaturas` | — |
| `sen_parties()` | `/senador/partidos` | leg. | `ListaPartidos.Partidos.Partido[]` | — | — |
| `sen_bill_types()` | `/processo/siglas` | v4 | topo | — | — |
| `sen_bill_statuses()` | `/processo/tipos-situacao` | v4 | topo | — | — |
| `sen_senators()` | `/senador/lista/atual`, `/senador/lista/legislatura/…` | leg. | `….Parlamentares.Parlamentar[]` | sem `Parlamentares` | 200 vazio |
| `sen_senator()` | `/senador/{codigo}` | leg. | `DetalheParlamentar.Parlamentar` | — | 200 vazio |
| `sen_senator_mandates()` | `/senador/{codigo}/mandatos` | leg. | `….Parlamentar.Mandatos.Mandato[]` | — | 200 vazio |
| `sen_senator_committees()` | `/senador/{codigo}/comissoes` | leg. | `….MembroComissoes.Comissao[]` | — | 200 vazio |
| `sen_senator_speeches()` | `/senador/{codigo}/discursos` | leg. | `….Pronunciamentos.Pronunciamento[]` | `Pronunciamentos: null` | 200 vazio |
| `sen_bills()` | `/processo` | v4 | topo | `[]` | — |
| `sen_bill()` | `/processo/{id}` | v4 | raiz | — | 404 |
| `sen_bill_authors()` | `/processo/{id}` | v4 | `autoriaIniciativa[]` | — | 404 |
| `sen_bill_proceedings()` | `/processo/{id}` | v4 | `autuacoes[].informesLegislativos[]` | — | 404 |
| `sen_bill_documents()` | `/processo/documento` | v4 | topo | `[]` | `[]` |
| `sen_votes()` | `/votacao` | v4 | topo | `[]` | — |
| `sen_vote_records()` | `/votacao` | v4 | topo → `votos[]` | `[]` | — |
| `sen_committees()` | `/comissao/lista/colegiados` | leg. | `ListaColegiados.Colegiados.Colegiado[]` | — | — |
| `sen_committee()` | `/comissao/{codigo}` | leg. | `….Colegiados.Colegiado[]` | — | 200 vazio |
| `sen_committee_members()` | `/composicao/comissao/{codigo}?ativas=` | leg. | `{envelope}.ComposicaoComissao.Membros.Membro[]` | — | 200 vazio |
| `sen_committee_meetings()` | `/comissao/agenda/…` | leg. | `AgendaReuniao.reunioes.reuniao[]` | `reuniao: null` | — |
| `sen_agenda()` | `/plenario/agenda/dia\|mes/{data}` | leg. | `AgendaPlenario.Sessoes.Sessao[]` | sem `Sessoes` | — |
| `sen_sessions()` | `/plenario/resultado/{data}`, `/plenario/resultado/mes/{data}` | leg. | `ResultadoPlenario.Sessoes.Sessao[]` | sem `Sessoes` | — |

---

## Parte 4 — O que este mapeamento exige do pacote

1. **Parse com `simplifyVector = FALSE` nos serviços legados**, com normalização objeto→lista nos nós repetíveis (1.4).
2. **Especificação de colunas por função**, com tipo declarado: códigos legados chegam como texto; datas chegam em quatro formatos; booleanos chegam como "Sim"/"Não", "S"/"N" e "true"/"false".
3. **Detecção de "não encontrado" por ausência de nó** na família legada, por 404 na v4 (1.2).
4. **Fatiamento por ano no cliente** em `/processo`, `/votacao` (a API recusa com 400) e `/senador/{codigo}/discursos` (a API trunca em silêncio).
5. **Seguir redirecionamento 301** (1.9).
6. **Totais de votação calculados** a partir dos votos individuais.
7. **Aparar espaços e quebras de linha** nos textos do plenário.
8. **Teste de integração contra a spec**: ler `/dadosabertos/v3/api-docs` e falhar se algum endpoint usado estiver `deprecated` ou ausente.

---

## Parte 5 — O que não foi medido

- `reuniao[].colegiados` com mais de um colegiado (reunião conjunta): a amostra de 22/05/2024 não tinha nenhuma; presume-se o mesmo comportamento objeto-ou-array de `partes`.
- Campos de fim de período em `Exercicios.Exercicio[]` e `Partidos.Partido[]` de `/senador/{codigo}/mandatos`: a amostra só tinha registros em aberto.
- `/plenario/agenda/mes` e `/plenario/resultado/mes` foram medidos quanto a status e tamanho, não campo a campo; presume-se a mesma forma dos endpoints diários.
- Limite de janela em `/processo/documento` com `dataInicio`/`dataFim` sem `idProcesso`.
- Variação de tempo de resposta ao longo do dia: cada tempo citado é uma medição única.
- A data de desligamento dos 42 endpoints `deprecated`: a spec não informa.
- Nenhum endpoint foi medido em XML; o pacote pede JSON, e todos os 27 responderam JSON.

---

## Anexo — Endpoints da v1 e seu destino

| Endpoint na v1 | Situação em 18/09/2026 | Substituto |
|---|---|---|
| `/materia/pesquisa/lista`, `/materia/{codigo}`, `/materia/textos/{codigo}`, `/materia/movimentacoes/{codigo}`, `/materia/votacoes/{codigo}`, `/materia/autoria/{codigo}`, `/materia/atualizadas` | deprecated (ainda respondem 200) | `/processo`, `/processo/{id}`, `/processo/documento`, `/votacao` |
| `/senador/{codigo}/votacoes` | deprecated | `/votacao?codigoParlamentar=` |
| `/senador/{codigo}/autorias` | deprecated | `/processo?codigoParlamentarAutor=` |
| `/plenario/lista/votacao/{dataInicio}/{dataFim}`, `/plenario/votacao/nominal/{ano}` | deprecated | `/votacao` |
| `/plenario/lista/votacao/{ano}` | nunca existiu com ano (400) | `/votacao` |
| `/plenario/agenda/{data}` | 404 | `/plenario/agenda/dia/{data}` |
| `/plenario/votacao/{codigo}` | não existe | — (a API não filtra por id de votação) |
| `/comissao/{sigla}` | 400 | `/comissao/{codigo}` |
| `/senador/{codigo}/historico`, `/agendareuniao/*` | respondem, mas fora da spec | `/senador/{codigo}` + `/mandatos`; `/comissao/agenda/*` |
| `/dados/ListaTiposDocumento.xml` (só XML) | ativo | `/processo/siglas` (JSON) |
| "Não existe endpoint de legislaturas" | incorreto | `/plenario/lista/legislaturas`, `/plenario/legislatura/{data}` |
