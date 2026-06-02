# agent_consultor_E05

Agente consultor SAP sênior: descobre objetos ABAP via SAP ADT, analisa o código-fonte em busca de sinais de desempenho e Clean Core, exibe um diff em duas colunas, pede aprovação e, em seguida, cria um objeto **novo** e aplica melhorias usando **exclusivamente** as ferramentas e parâmetros documentados no servidor MCP **sap-adt-python** (`user-sap-adt`).

## Conformidade MCP

Este agente utiliza **somente** as 21 ferramentas documentadas em [`sap-adt-python/docs/MCP_COMMAND_REFERENCE.md`](../../sap-adt-python/docs/MCP_COMMAND_REFERENCE.md), com **somente** os parâmetros descritos nessa documentação:

| Seção | Ferramentas MCP |
|-------|----------------|
| §1 Conexão | `sap_save_password`, `sap_connect`, `sap_discovery`, `sap_list_environments`, `sap_delete_password` |
| §2 Repositório | `sap_search`, `sap_browse_package`, `sap_object_metadata` |
| §3 Código-fonte | `sap_read_source`, `sap_write_source`, `sap_activate`, `sap_syntax_check` |
| §4 Transports | `sap_check_lock`, `sap_list_transports`, `sap_create_transport`, `sap_release_transport`, `sap_transport_check` |
| §5 Objetos | `sap_create_program`, `sap_create_class`, `sap_create_interface`, `sap_delete_object` |

**Nenhuma** ferramenta ou parâmetro fora desta documentação é utilizado. Em particular:
- O `sap_write_source` do MCP já executa internamente: lock → check transport → write → optionally activate → unlock
- Não há chamadas a ferramentas não documentadas como `sap_lock` ou `sap_unlock`
- Os parâmetros de cada ferramenta seguem estritamente a referência MCP

## Pré-requisitos

- Python 3.10+
- O projeto **sap-adt-python** neste repositório (padrão: `../../sap-adt-python/src` a partir desta pasta)
- O pacote **`mcp`** (importado por `sap_adt.mcp_server`)

### Recomendado (Windows)

Use o mesmo interpretador do projeto **sap-adt-python** (venv já com `mcp`):

```powershell
cd agents\agent_consultor_E05
.\run_agent.ps1
```

Ou chame o Python do venv explicitamente:

```powershell
..\..\sap-adt-python\.venv\Scripts\python.exe agent.py
```

### Alternativa

No ambiente onde você roda `python agent.py`:

```bash
pip install mcp PyYAML
```

- Credenciais SAP resolvidas conforme MCP §1.2 (`sap_connect`):
  - `SAP_HOST`, `SAP_PORT`, `SAP_CLIENT`, `SAP_USER`, `SAP_PASSWORD`, `SAP_LANGUAGE`, **ou**
  - ambiente salvo (`system_id`, ex.: `E05`) via `sap_save_password` (§1.1) + chaveiro do SO
  - Se `system_id` estiver no `config.yaml` mas **não** houver senha no chaveiro nem `SAP_PASSWORD`, o agente (em terminal interativo) **pede a senha uma vez** com prompt oculto.
- `PyYAML` para carregar `config.yaml`

## Configuração

Edite `config.yaml`:

- `sap_adt_python.src_path`: caminho para **sap-adt-python/src** (contém o pacote `sap_adt`).
- `connection.system_id`: ex.: `E05` — equivale a chamar `sap_connect(system_id="E05")`.
- `object_type_aliases`: mapeia rótulos legíveis (PROGRAM, INCLUDE, …) para códigos ADT (`PROG`, `CLAS`, …).

## Como executar

Neste diretório:

```bash
pip install PyYAML
set SAP_PASSWORD=sua_senha
python agent.py
```

Descoberta semi-automática:

```bash
python agent.py --object ZMY_REPORT --type PROGRAM --include ZMY_INC
```

Aprovação e etapas de clone usam stdin; execute em um terminal real.

### Interface web (navegador)

```powershell
pip install -r requirements-web.txt
python web_server.py
```

Ou: `.\run_web.ps1`. Abra **http://127.0.0.1:8765**. Use apenas em rede local.

## Pipeline de execução (resumo)

1. Solicita nome e tipo do objeto (ou passe `--object` / `--type`).
2. **Descoberta**: `sap_search` (§2.1), `sap_object_metadata` (§2.3).
3. **Fonte**: `sap_read_source` (§3.1) — parâmetros: `object_name`, `object_type`, `version`, `save_to`.
4. **Mapa de dependências**: obtido do código-fonte (INCLUDE, CALL FUNCTION, classes, tabelas, …).
5. **Escopo opcional**: analisar/clonar um único include (`--include` ou prompt).
6. **Análise**: heurísticas em `analyzer.py` (loops aninhados, SELECT em loop, Clean Core, …).
7. **Melhorias**: sugestão conservadora em `suggest_improved_snippet`.
8. **Diff**: duas colunas + unified diff em `comparator.py`.
9. **Aprovação**: é obrigatório confirmar para continuar.
10. **Dados do clone**: novo nome, pacote, transporte opcional.
11. **Transporte**: `sap_create_transport` (§4.3) se não houver e o pacote não for `$TMP`.
12. **Verificação de lock**: `sap_check_lock` (§4.1).
13. **Criação**: `sap_create_program` / `sap_create_class` / `sap_create_interface` (§5.1–§5.3).
14. **Gravação**: `sap_write_source` (§3.2) com `activate=False` — o MCP faz lock/write/unlock automaticamente.
15. **Sintaxe / ativação**: `sap_syntax_check` (§3.4), depois `sap_activate` (§3.3).

## Parâmetros MCP utilizados por ferramenta

| Ferramenta | Parâmetros utilizados |
|------------|----------------------|
| `sap_connect` | `system_id`, `host`, `port`, `client`, `user`, `password`, `language` |
| `sap_discovery` | *(nenhum)* |
| `sap_search` | `query`, `object_type`, `max_results` |
| `sap_browse_package` | `package_name` |
| `sap_object_metadata` | `object_uri` |
| `sap_read_source` | `object_name`, `object_type`, `version`, `save_to` |
| `sap_write_source` | `object_name`, `source_code`, `source_file`, `object_type`, `transport_request`, `activate` |
| `sap_activate` | `object_name`, `object_type`, `object_uri` |
| `sap_syntax_check` | `object_name`, `object_type` |
| `sap_check_lock` | `object_name`, `object_type` |
| `sap_list_transports` | `user` |
| `sap_create_transport` | `description`, `package`, `target_system` |
| `sap_release_transport` | `transport_number` |
| `sap_transport_check` | `object_name`, `object_type` |
| `sap_create_program` | `name`, `description`, `package`, `transport_request` |
| `sap_create_class` | `name`, `description`, `package`, `transport_request` |
| `sap_create_interface` | `name`, `description`, `package`, `transport_request` |
| `sap_delete_object` | `object_name`, `object_type`, `transport_request`, `confirm` |

## Tipos de objeto suportados (ADT)

| Área | Tipos ADT | Observações |
|------|-----------|-------------|
| Programas | `PROG` | Includes são programas; escopo com `--include`. |
| Classes | `CLAS` | |
| Interfaces | `INTF` | |
| Grupos de funções | `FUGR` | Grupo inteiro, não um único FM. |

## Arquivos

| Arquivo | Função |
|---------|--------|
| `agent.py` | CLI e pipeline ponta a ponta |
| `tools.py` | Camada fina sobre `sap_adt.mcp_server` (somente 21 ferramentas MCP) |
| `sap_mandatory_flow.py` | Fluxo: sap_write_source → sap_syntax_check → sap_activate |
| `integration.py` | Orquestração alinhada a §7 da referência MCP |
| `analyzer.py` | Extração de dependências + análise heurística |
| `comparator.py` | Diff em duas colunas e unified diff |
| `prompts.py` | Persona do consultor e fragmentos de prompt |
| `config.yaml` | Caminhos, aliases e configuração MCP |
| `web_server.py` | Servidor FastAPI + API `/api/analyze` e `/api/clone` |
| `static/` | HTML/CSS/JS da interface web |
| `requirements-web.txt` | Dependências opcionais da UI (FastAPI, uvicorn) |

## Transporte (CTS)

Se a criação automática de transporte falhar com **«user action is not supported»** (HTTP 400), o sistema costuma **não permitir** criar o pedido só pela API ADT — o mesmo pedido tem de ser criado em **SE09/SE10**. Depois disso, informe o número do transporte no prompt do agente ou no campo **Transporte** da interface web (ou use o pacote **`$TMP`** para desenvolvimento local sem transporte).

## Segurança

Não faça commit de senhas. Use variáveis de ambiente ou o chaveiro do SO via `sap_save_password` (MCP §1.1).
