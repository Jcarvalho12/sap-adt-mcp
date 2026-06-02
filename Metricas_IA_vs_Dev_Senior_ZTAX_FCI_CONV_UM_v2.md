# Métricas: IA vs Desenvolvedor Sênior

## Report ZTAX_FCI_CONV_UM

### Pré-processamento FCI — Conversão de Unidade de Medida

| | |
|---|---|
| **Projeto** | FCI — Pré-processamento Conversão Unidade de Medida |
| **Sistema** | TDD (manaus.group.pirelli.com:8001, client 210) |
| **EF** | EF-TAX-TDF v1.0 — 07/04/2026 — Laura Prado (9 páginas) |
| **Data da análise** | 14/05/2026 (revisão v2) |
| **Ferramenta IA** | Cursor IDE + MCP SAP ADT (Claude) |
| **Request** | TDDK901617 |
| **Pacote** | ZTAX_FCI_CONV |

---

## 1. Inventário do Objeto

| Métrica | Valor |
|---|---|
| Tipo | Report ABAP (PROG) |
| LOC (linhas de código) | ~680 |
| FORMs (sub-rotinas) | 14 |
| Queries HANA nativas (cl_sql_statement) | 8 |
| Views HANA consumidas | 6 |
| Tabelas SAP acessadas | 1 (STPO) |
| Tabelas Z gravadas | 2 |
| CALL FUNCTION | 3 |
| IFs / CHECKs | ~25 |
| LOOPs | ~20 |
| TRY/CATCHs | 8 |
| Algoritmo recursivo (BOM) | 1 (até 20 níveis) |
| Saída ALV (cl_salv_table) | 1 |

**Complexidade geral: ALTA** — SQL HANA nativo, explosão recursiva de BOM multinível, lógica de conversão de unidades e gravação em múltiplas tabelas.

---

## 2. Análise de Complexidade por Sub-rotina

| # | FORM | LOC | SQL | IFs | LOOPs | TRY | Compl. | Detalhe |
|---|---|---|---|---|---|---|---|---|
| 1 | f_montar_periodo | ~25 | 0 | 2 | 0 | 0 | Baixa | Cálc. mês-2 |
| 2 | f_buscar_cfop_saida | ~25 | 1 | 0 | 0 | 1 | Baixa | Query HANA |
| 3 | f_buscar_cfop_entrada | ~25 | 1 | 0 | 0 | 1 | Baixa | Query HANA |
| 4 | f_buscar_produtos_saida | ~65 | 1 | 3 | 2 | 1 | Média | JOIN + filtros |
| 5 | f_buscar_produtos_entrada | ~55 | 1 | 2 | 1 | 1 | Média | JOIN + filtros |
| 6 | f_buscar_consumo_especif. | ~50 | 1 | 1 | 1 | 1 | Média | IN-list pares |
| 7 | f_explodir_bom | ~90 | 1 | 4 | 5 | 1 | **ALTA** | Recursivo 20n |
| 8 | f_filtrar_por_notas_entr. | ~30 | 0 | 2 | 2 | 0 | Baixa | Hash filter |
| 9 | f_filtrar_por_mtorg_imp. | ~60 | 1 | 2 | 3 | 1 | Média | MBEW import. |
| 10 | f_buscar_unid_item | ~45 | 1 | 1 | 2 | 1 | Média | Lookup ITEM |
| 11 | f_buscar_meins_stpo | ~50 | 1 | 1 | 2 | 1 | Média | Lookup STPO |
| 12 | f_processar_conversao | ~85 | 0 | 6 | 1 | 0 | **ALTA** | G/KG + FM |
| 13 | f_verificar_conv_ant. | ~40 | 0 | 2 | 2 | 0 | Média | ZENG_PRE_FCI |
| 14 | f_gravar_shadow | ~35 | 0 | 2 | 1 | 0 | Baixa | MODIFY shadow |
| 15 | f_gravar_controle | ~35 | 0 | 2 | 1 | 0 | Baixa | MODIFY ctrl |
| 16 | f_exibir_alv | ~60 | 0 | 0 | 0 | 1 | Média | cl_salv_table |

**Distribuição:** 2 Alta | 8 Média | 6 Baixa

---

## 3. Lacunas da EF — Procedimentos Não Previstos

A EF (9 páginas) cobre apenas o núcleo da regra de conversão: comparar STPO.MEINS vs ITEM.UNID_INV, converter G/KG dividindo ou multiplicando por 1000, e gravar na shadow /TMF/D_CONS_ESPC. Porém, durante o desenvolvimento, o desenvolvedor sênior precisou debugar o fluxo FCI existente (/TAX/CL_CALCULO_FCI) e descobrir diversos procedimentos adicionais necessários para que o report funcionasse corretamente no cenário real. Esses procedimentos NÃO constam na EF e exigiram análise, engenharia reversa e decisões técnicas do desenvolvedor.

### Procedimentos descobertos durante o desenvolvimento

| # | Procedimento não previsto na EF | Impacto |
|---|---|---|
| 1 | Filtragem CFOP saída/entrada (CV_FCI_CES) | 2 queries + lógica DIRECT |
| 2 | Busca produtos c/ NF no período (JOINs NF_ITEM/DOC) | 2 queries complexas (~120 LOC) |
| 3 | Explosão BOM multinível (até 20 níveis) | Algoritmo recursivo (~90 LOC) |
| 4 | Proteção contra referências circulares na BOM | Tabela hash de visitados |
| 5 | Filtro MTORG importado (CV_MBEW IN 1,2,3,8) | Query + filtro hash (~60 LOC) |
| 6 | Filtro por notas de entrada no período | Query + filtro hash (~30 LOC) |
| 7 | Verificação conversão anterior (ZENG_PRE_FCI) | SELECT FAE + ícone vermelho |
| 8 | Tabela de controle ZENG_PRE_FCI | Gravação + lógica anti-regravação |
| 9 | Modo Simulação vs Execução c/ popup | Radio buttons + confirmação |
| 10 | Fallback UNIT_CONVERSION_SIMPLE (outras UMs) | CALL FUNCTION genérico |
| 11 | Filtros NF canceladas/tipos específicos NF | WHERE NOT IN (NFS,E2,J2...) |
| 12 | Select-Options COD_ITEM e COD_ITEM_COMP | Parâmetros de tela adicionais |

> **Estimativa:** ~50% do código final (aproximadamente 340 LOC de ~680 total) implementa procedimentos que não estavam previstos na EF original. O desenvolvedor sênior precisou debugar o fluxo FCI existente, entender a cadeia de dependências e propor as melhorias junto com a IA.

---

## 4. Estimativa — Desenvolvedor ABAP Sênior (Humano)

**Premissas:** Desenvolvedor ABAP sênior (5+ anos), experiência em HANA native SQL, familiaridade moderada com FCI/SmartTax. Produtividade: 30-40 LOC/hora. Inclui análise da EF, estudo do sistema, codificação, debugging de procedimentos não previstos, testes e transporte.

### Fase 1 — Entendimento da EF e sistema existente

| Atividade | Horas | Justificativa |
|---|---|---|
| Leitura e interpretação da EF (9 páginas) | 1,5h | Regras de negócio implícitas |
| Entendimento do problema (FCI > 100%) | 0,5h | Análise do cenário da EF |
| Estudo do fluxo FCI (/TAX/CL_CALCULO_FCI) | 3,0h | Replicar lógica de período/filtros |
| Estudo modelo de dados HANA (6 views) | 3,0h | Views HANA não-standard |
| Esclarecimentos com equipe funcional | 1,0h | Cenários G→KG, outras UMs |
| **Subtotal Fase 1** | **9,0h** | |

### Fase 2 — Design técnico

| Atividade | Horas | Justificativa |
|---|---|---|
| Design do pipeline (14 etapas) | 2,0h | Ordem: saída→consumo→BOM→entrada→conv. |
| Design queries HANA native SQL | 2,0h | 8 queries com JOINs e filtros dinâmicos |
| Design explosão BOM recursiva | 2,0h | 20 níveis, proteção circular |
| Design ALV + modos simulação/execução | 1,0h | Ícones, popup, gravação condicional |
| **Subtotal Fase 2** | **7,0h** | |

### Fase 3 — Codificação (~680 LOC)

| Componente | LOC | Horas | Justificativa |
|---|---|---|---|
| Tipos, dados globais, tela de seleção | ~75 | 2,0h | 7 tipos + selection-screen |
| START-OF-SELECTION + popup | ~30 | 1,0h | Pipeline + confirmação |
| f_montar_periodo | ~25 | 1,0h | Mês-2 com virada de ano |
| f_buscar_cfop_saida/entrada | ~50 | 1,5h | 2 queries HANA simples |
| f_buscar_produtos_saida/entrada | ~120 | 4,0h | Queries complexas com JOINs |
| f_buscar_consumo_especifico | ~50 | 2,0h | IN-list pares (COD_ITEM,CENTRO) |
| f_explodir_bom | ~90 | 5,0h | Recursivo 20 níveis + hash visitados |
| f_filtrar (entrada + MTORG) | ~90 | 2,5h | Filtros com tabela hash |
| f_buscar_unid_item/meins_stpo | ~95 | 2,0h | 2 queries de lookup |
| f_processar_conversao | ~85 | 3,0h | CASE G/KG + FM fallback |
| f_verificar_conversao_anterior | ~40 | 1,5h | SELECT FAE + BINARY SEARCH |
| f_gravar_shadow/controle | ~70 | 2,0h | MODIFY + COMMIT/ROLLBACK |
| f_exibir_alv | ~60 | 2,0h | cl_salv_table + 15 colunas |
| **Subtotal Fase 3** | **~680** | **29,5h** | |

### Fase 4 — Testes e depuração

| Atividade | Horas | Justificativa |
|---|---|---|
| Testes unitários (modo simulação) | 3,0h | Validar cada etapa do pipeline |
| Testes de integração (modo execução) | 4,0h | Gravar shadow + ZENG_PRE_FCI |
| Depuração e correção de bugs | 3,5h | Debug, ajuste queries, edge cases |
| Teste de re-execução | 1,0h | Ícone vermelho impede regravação |
| **Subtotal Fase 4** | **11,5h** | |

### Fase EXTRA — Debugging e melhorias não previstas na EF

Durante o desenvolvimento, o desenvolvedor sênior precisou debugar o fluxo FCI existente e realizar engenharia reversa para descobrir procedimentos que a EF não documentava. Após entender cada procedimento, precisou implementar as melhorias e testar os cenários adicionais.

| Atividade | Horas | Justificativa |
|---|---|---|
| Debug/engenharia reversa do FCI existente | 5,0h | Rastrear fluxo real no SAP via SE80/debug |
| Descobrir filtros não previstos na EF | 4,0h | CFOP, NF período, BOM, MTORG, ZENG_PRE_FCI |
| Implementar melhorias além da EF | 6,0h | Simulação/execução, popup, BOM circular, FM |
| Testes adicionais das melhorias | 3,0h | Testar cenários não cobertos pela EF |
| **Subtotal Fase Extra** | **18,0h** | |

### Fase 5 — Finalização

| Atividade | Horas | Justificativa |
|---|---|---|
| Transporte (TDDK901617) | 0,5h | Associar objetos e liberar |
| Code review / preparação | 1,0h | Auto-revisão |
| Documentação técnica | 0,5h | Complementar a EF |
| **Subtotal Fase 5** | **2,0h** | |

### Resumo — Desenvolvedor Sênior

| Fase | Horas | % |
|---|---|---|
| 1. Entendimento da EF e sistema | 9,0h | 12% |
| 2. Design técnico | 7,0h | 9% |
| 3. Codificação | 29,5h | 38% |
| 4. Testes e depuração | 11,5h | 15% |
| EXTRA. Debugging + melhorias não previstas | 18,0h | 23% |
| 5. Finalização | 2,0h | 3% |
| **Total Desenvolvedor Sênior** | **77,0h** | **100%** |

> **77 horas = 9,6 dias úteis = ~1,9 semanas** (8h/dia)

---

## 5. Estimativa — IA (Cursor + MCP SAP ADT) — Revisão v2

**Premissas:** IA recebe EF (PDF) como contexto. Deploy direto via MCP. IA lê código existente via sap_read_source. O desenvolvedor sênior é essencial para debugar procedimentos não previstos na EF, localizar pontos-chave no fluxo existente e realizar ajustes manuais no código gerado pela IA.

**Fatores de ajuste nesta revisão (v2):** Na prática, o código gerado pela IA exigiu mais iterações de ajustes manuais do que o estimado inicialmente. O desenvolvedor precisou investir tempo significativo depurando o programa para localizar pontos-chave antes de prosseguir com a evolução, e o ciclo de correção-redeploy-teste foi mais longo que o previsto.

### Fase 1 — Entendimento da EF e sistema

| Atividade | Horas | Justificativa |
|---|---|---|
| IA lê e interpreta a EF (PDF) | 0,1h | 9 páginas em segundos |
| IA lê código FCI existente via MCP | 0,3h | Leitura automatizada |
| IA analisa modelo de dados HANA | 0,3h | Pesquisa automatizada |
| Humano valida entendimento da IA | 1,3h | Revisão, alinhamento e correções de interpretação |
| **Subtotal Fase 1** | **2,0h** | |

### Fase 2 — Design técnico

| Atividade | Horas | Justificativa |
|---|---|---|
| IA propõe pipeline completo | 0,2h | Geração instantânea |
| Humano revisa, ajusta e corrige design | 0,8h | Validação de decisões e correção de premissas |
| **Subtotal Fase 2** | **1,0h** | |

### Fase 3 — Codificação (~680 LOC)

| Componente | Horas | Justificativa |
|---|---|---|
| Geração completa do report (1ª iteração) | 1,5h | Report inteiro a partir da EF |
| Revisão humana + identificação de ajustes | 1,5h | Leitura detalhada e marcação de correções |
| IA aplica correções (2ª-4ª iteração) | 1,5h | Mais iterações necessárias que o previsto |
| Ajustes manuais no código-fonte pelo dev | 2,5h | Correções finas que a IA não acertou |
| Deploy via MCP (write + activate) | 0,5h | Múltiplos ciclos de deploy/reativação |
| **Subtotal Fase 3** | **7,5h** | |

### Fase 4 — Testes e depuração

| Atividade | Horas | Justificativa |
|---|---|---|
| Teste modo simulação (humano) | 3,0h | Execução real no SAP com análise de resultados |
| Depuração e localização de pontos-chave | 2,0h | Identificar trechos críticos para evolução |
| IA corrige bugs encontrados | 1,0h | Lê log, ajusta, redeploy via MCP |
| Teste integração (modo execução) | 2,0h | Shadow + ZENG_PRE_FCI + validação dados |
| Teste re-execução | 0,5h | Proteção contra regravação |
| **Subtotal Fase 4** | **8,5h** | |

### Fase EXTRA — Debugging e melhorias não previstas na EF

O desenvolvedor sênior precisa debugar o fluxo FCI existente no SAP e realizar engenharia reversa — esta é uma atividade humana insubstituível. Nesta revisão, ficou evidente que o tempo de depuração para localizar pontos-chave no fluxo existente foi maior que o estimado inicialmente. Além disso, as melhorias implementadas pela IA exigiram ajustes manuais adicionais após cada ciclo de geração.

| Atividade | Horas | Justificativa |
|---|---|---|
| Dev sênior debugar fluxo FCI no SAP | 5,0h | Trabalho humano puro (SE80/debugger) |
| Dev localizar pontos-chave para evolução | 3,0h | Identificar onde intervir no fluxo existente |
| Dev comunicar requisitos descobertos à IA | 1,5h | Descrever filtros, BOM, MTORG etc. |
| IA implementar melhorias c/ supervisão | 2,0h | IA gera código, dev valida lógica |
| Ajustes manuais pós-geração IA | 1,5h | Correções finas no código gerado |
| Testes adicionais (humano + IA) | 2,0h | Dev testa cenários, IA corrige via MCP |
| **Subtotal Fase Extra** | **15,0h** | |

### Fase 5 — Finalização

| Atividade | Horas | Justificativa |
|---|---|---|
| Transporte + documentação (IA-assistida) | 0,5h | Via MCP + revisão humana |
| **Subtotal Fase 5** | **0,5h** | |

### Resumo — IA + Revisão Humana (v2)

| Fase | Horas | % |
|---|---|---|
| 1. Entendimento da EF e sistema | 2,0h | 6% |
| 2. Design técnico | 1,0h | 3% |
| 3. Codificação | 7,5h | 22% |
| 4. Testes e depuração | 8,5h | 24% |
| EXTRA. Debugging + melhorias não previstas | 15,0h | 43% |
| 5. Finalização | 0,5h | 1% |
| **Total IA + Revisão Humana** | **34,5h** | **100%** |

> **34,5 horas = 4,3 dias úteis** (8h/dia)

---

## 6. Comparativo Consolidado

### 6.1 Comparativo por Fase

| Fase | Dev Sênior | IA + Revisão | Economia (h) | Economia % |
|---|---|---|---|---|
| Entendimento da EF | 9,0h | 2,0h | 7,0h | 78% |
| Design técnico | 7,0h | 1,0h | 6,0h | 86% |
| Codificação | 29,5h | 7,5h | 22,0h | 75% |
| Testes e depuração | 11,5h | 8,5h | 3,0h | 26% |
| EXTRA: Debug + melhorias | 18,0h | 15,0h | 3,0h | 17% |
| Finalização | 2,0h | 0,5h | 1,5h | 75% |
| **TOTAL** | **77,0h** | **34,5h** | **42,5h** | **55%** |

### 6.2 Impacto da Fase Extra nos Totais

| Cenário | Dev Sênior | IA + Revisão | Economia % |
|---|---|---|---|
| Sem fase extra (só EF) | 59,0h | 19,5h | 67% |
| Com fase extra (cenário real) | 77,0h | 34,5h | 55% |
| Diferença adicionada | +18,0h | +15,0h | -12 p.p. |

> A fase extra reduz a economia de 67% para 55%, pois o debugging, engenharia reversa e ajustes manuais no SAP são trabalhos essencialmente humanos. A IA não substitui o desenvolvedor na depuração interativa, e o código gerado frequentemente exige ajustes manuais finos que consomem tempo adicional. A economia na fase extra vem da geração inicial de código: a IA produz o esqueleto das melhorias mais rápido, mas o dev precisa investir tempo significativo em refinamento.

---

## 7. Análise da Fase Extra — Debug, Ajustes Manuais e Melhorias

### 7.1 O que muda com a fase extra

A inclusão da fase extra reflete o cenário real de desenvolvimento: a EF raramente cobre 100% dos requisitos. O desenvolvedor sênior precisou atuar em **quatro** frentes durante esta fase:

- **Debugging:** rastrear o fluxo FCI existente via SE80/debugger para entender lógicas não documentadas
- **Localização de pontos-chave:** identificar exatamente onde no fluxo existente as intervenções deveriam ocorrer antes de prosseguir com a evolução
- **Ajustes manuais:** corrigir e refinar o código gerado pela IA, que nem sempre acertou detalhes específicos do contexto SAP
- **Implementação conjunta com IA:** após entender os requisitos, orientar a IA para codificar as melhorias

### 7.2 Onde a IA NÃO economiza (ou economiza pouco)

| Atividade | Dev sozinho | Dev + IA | Economia |
|---|---|---|---|
| Debugging no SAP (SE80/debugger) | 5,0h | 5,0h | 0% (humano puro) |
| Localização de pontos-chave para evolução | 4,0h | 3,0h | 25% (IA lê código, mas dev decide) |
| Ajustes manuais no código-fonte | — | 4,0h | 0% (trabalho humano sobre código IA) |

> O debugging no SAP e os ajustes manuais são os gargalos principais: a IA não tem acesso ao debugger interativo (breakpoints, variáveis em runtime), e o código gerado frequentemente precisa de correções finas que exigem conhecimento contextual do sistema. A localização de pontos-chave no fluxo existente também é predominantemente humana — a IA pode ler o código via MCP, mas o dev precisa executar e entender o fluxo real.

### 7.3 Onde a IA ECONOMIZA na fase extra

| Atividade | Dev sozinho | Dev + IA | Economia |
|---|---|---|---|
| Implementar melhorias (código inicial) | 6,0h | 2,0h | 67% (IA gera esqueleto) |
| Testes das melhorias | 3,0h | 2,0h | 33% (IA corrige e redeploy rápido) |

> Após o desenvolvedor entender o que precisa ser feito, a IA gera o esqueleto do código rapidamente. Porém, o ciclo completo (IA gera → dev revisa → dev ajusta manualmente → redeploy → teste) é mais longo que o estimado na v1 da métrica.

---

## 8. Onde a IA Mais Economizou

| Tipo de tarefa | Economia | Justificativa |
|---|---|---|
| Leitura/interpretação da EF (PDF) | 93% | IA processa 9 páginas em segundos |
| Estudo do código existente (FCI) | 80% | IA lê via MCP, mas interpretação exige validação |
| Queries HANA native SQL | 70% | Padrão cl_sql_statement conhecido, mas ajustes manuais necessários |
| Explosão BOM recursiva | 65% | Algoritmo recursivo gerado pela IA exigiu refinamento |
| Lógica de conversão G/KG | 75% | Regra explícita na EF, mas edge cases exigiram ajustes |
| ALV com cl_salv_table | 80% | Padrão repetitivo, pouco ajuste manual |
| Deploy no SAP | 80% | MCP elimina Eclipse/SAP GUI, mas múltiplos ciclos |
| Implementar melhorias (pós-debug) | 50% | IA codifica rápido, mas dev ajusta manualmente depois |
| Ajustes manuais no código-fonte | 0% | Trabalho humano puro — correções finas |
| Debugging no SAP (SE80/debugger) | 0% | Trabalho humano puro — IA não substitui |
| Testes com dados reais | 30% | Humano executa, valida e frequentemente requer retrabalho |

---

## 9. Onde o Humano é Insubstituível

| Dimensão | Justificativa |
|---|---|
| Debugging no SAP (SE80/debugger) | Breakpoints, variáveis em runtime, fluxo real |
| Localização de pontos-chave no fluxo | Identificar onde intervir exige execução real e análise contextual |
| Ajustes manuais no código gerado pela IA | Correções finas que exigem conhecimento do contexto SAP |
| Engenharia reversa de fluxos complexos | Entender dependências não documentadas |
| Validação funcional com dados reais | Executar no SAP e confirmar FCI correto |
| Domínio fiscal (FCI, CFOP, MTORG) | IA implementa a regra, humano valida cenário |
| Decisões de escopo (G/KG vs todas UMs) | Humano decide se fallback era necessário |
| Testes de regressão | Garantir que conversão não quebra o FCI existente |

---

## 10. Conclusão

| Indicador | Valor |
|---|---|
| Ganho de produtividade com IA | **55%** (42,5 horas economizadas) |
| Fator de aceleração | **2,2x** mais rápido |
| Maior ganho (fases previstas na EF) | Entendimento + design (78-86%) |
| Codificação (ganho real) | 75% (reduzido por ajustes manuais) |
| Fase extra (não prevista na EF) | +18h dev / +15h IA (17% economia) |
| Gargalos principais | Debugging no SAP (0%) + ajustes manuais (0%) |

Com a inclusão da fase extra de debugging e melhorias não previstas na EF, **somada ao tempo adicional de ajustes manuais e depuração para localizar pontos-chave**, a economia real foi de **55%** (42,5 horas / ~5,3 dias úteis por projeto).

Os principais fatores que reduziram a economia em relação à estimativa teórica:

1. **Ajustes manuais no código-fonte:** O código gerado pela IA, embora funcional na estrutura, exigiu correções finas em detalhes específicos do contexto SAP (queries HANA, tratamento de exceções, edge cases de conversão). Foram ~4h adicionais de trabalho manual distribuídas entre as fases 3 e EXTRA.

2. **Depuração para localizar pontos-chave:** Antes de prosseguir com a evolução do programa, o desenvolvedor precisou investir ~5h adicionais (entre fases 4 e EXTRA) depurando o fluxo existente e o código gerado para identificar exatamente onde e como intervir.

3. **Ciclo de iteração mais longo:** O fluxo "IA gera → dev revisa → dev ajusta → redeploy → teste" exigiu mais iterações que o previsto, com múltiplos ciclos de deploy/reativação via MCP.

Mesmo assim, **a economia de 55% permanece significativa**. O modelo de trabalho "humano debugar e localizar pontos-chave + IA gera código + humano ajusta manualmente" demonstra que a IA é uma ferramenta de aceleração poderosa, mas que **o desenvolvedor sênior permanece essencial** em todas as fases — não apenas no debugging, mas também no refinamento do código gerado.

> **Nota metodológica:** As estimativas do desenvolvedor sênior baseiam-se em produtividade de 30-40 LOC/h para ABAP com HANA native SQL (benchmark ISBSG/SAP Community). A fase extra foi estimada com base na experiência real do desenvolvimento deste report, onde o desenvolvedor precisou debugar o fluxo /TAX/CL_CALCULO_FCI para descobrir 12 procedimentos não documentados na EF. As estimativas da IA baseiam-se na experiência prática via Cursor IDE + MCP SAP ADT, **revisadas com base no tempo real gasto** incluindo ajustes manuais e depuração adicional.
