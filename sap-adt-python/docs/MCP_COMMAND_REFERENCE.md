# SAP ADT MCP — Referência Completa de Comandos

**Versão:** 1.0  
**Atualizado:** 2026-04-02  
**Servidor MCP:** `user-sap-adt` (chave `sap-adt` no `.cursor/mcp.json`)

---

## Índice

1. [Conexão e Credenciais](#1-conexão-e-credenciais)
2. [Repositório ABAP](#2-repositório-abap)
3. [Código-Fonte](#3-código-fonte)
4. [Gerenciamento de Transports](#4-gerenciamento-de-transports)
5. [Criação e Exclusão de Objetos](#5-criação-e-exclusão-de-objetos)
6. [Pré-requisitos SAP para ADT](#6-pré-requisitos-sap-para-adt)
7. [Fluxo Típico de Trabalho](#7-fluxo-típico-de-trabalho)

---

## 1. Conexão e Credenciais

### 1.1 `sap_save_password`

Salva credenciais de um ambiente SAP no gerenciador de credenciais do sistema operacional (Windows Credential Manager / macOS Keychain / Linux Secret Service). Os parâmetros de conexão são gravados em `~/.sap-adt/environments.json` (sem senhas nesse arquivo).

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `system_id` | string | Sim | — | Identificador curto do ambiente (ex: `ED2`, `QA1`, `PRD`) |
| `host` | string | Sim | — | Hostname do servidor SAP |
| `port` | int | Não | `8000` | Porta HTTP/HTTPS |
| `client` | string | Não | `500` | Mandante SAP |
| `user` | string | Sim | — | Usuário SAP |
| `password` | string | Sim | — | Senha do usuário |
| `language` | string | Não | `EN` | Idioma de logon |
| `use_https` | bool | Não | `false` | Usar HTTPS |

**Exemplo:**

```
sap_save_password(
    system_id="ED2",
    host="awsntwpstx01.engdb.infra",
    port=8000,
    client="500",
    user="egoetz",
    password="SuaSenhaAqui",
    language="EN"
)
```

**Retorno (sucesso):**

```json
{
  "saved": true,
  "system_id": "ED2",
  "host": "awsntwpstx01.engdb.infra",
  "port": 8000,
  "client": "500",
  "user": "egoetz",
  "message": "Credentials for ED2 stored securely. Use sap_connect(system_id='ED2') to connect."
}
```

---

### 1.2 `sap_connect`

Estabelece conexão com o sistema SAP via ADT REST API. Realiza autenticação HTTP Basic, obtém token CSRF e inicializa todos os serviços internos.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `system_id` | string | Não | `""` | ID do ambiente salvo (ex: `ED2`). Carrega host/port/client/user/language do config salvo e recupera a senha do keyring |
| `host` | string | Não | `""` | Hostname (sobrescreve o salvo) |
| `port` | int | Não | `0` | Porta (sobrescreve o salvo) |
| `client` | string | Não | `""` | Mandante (sobrescreve o salvo) |
| `user` | string | Não | `""` | Usuário (sobrescreve o salvo) |
| `password` | string | Não | `""` | Senha (sobrescreve o salvo e o keyring) |
| `language` | string | Não | `""` | Idioma (sobrescreve o salvo) |

**Ordem de resolução de cada parâmetro:**
1. Argumento explícito passado na chamada
2. Ambiente salvo (se `system_id` fornecido)
3. Variáveis de ambiente (`SAP_HOST`, `SAP_PORT`, etc.)
4. Defaults internos

**Ordem de resolução da senha:**
1. Argumento `password` explícito
2. Variável `SAP_PASSWORD`
3. Keyring do SO (se `system_id` fornecido)

**Exemplo 1 — usando ambiente salvo (recomendado):**

```
sap_connect(system_id="ED2")
```

**Exemplo 2 — parâmetros explícitos:**

```
sap_connect(
    host="awsntwpstx01.engdb.infra",
    port=8000,
    client="500",
    user="egoetz",
    password="SuaSenhaAqui"
)
```

**Retorno:**

```
Connected to awsntwpstx01.engdb.infra:8000 (client 500) as user egoetz (from saved environment 'ED2'). ADT services available.
```

> **Importante:** `sap_connect` deve ser chamado antes de qualquer outro comando. Todos os demais comandos dependem de uma conexão ativa.

---

### 1.3 `sap_discovery`

Lista os serviços ADT disponíveis no sistema conectado. Retorna o XML de descoberta (Atom Service Document).

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| *(nenhum)* | — | — | — | — |

**Exemplo:**

```
sap_discovery()
```

**Retorno:** XML com as coleções de serviços ADT disponíveis (limitado a 5000 caracteres).

---

### 1.4 `sap_list_environments`

Lista todos os ambientes SAP salvos (senhas nunca são exibidas).

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| *(nenhum)* | — | — | — | — |

**Exemplo:**

```
sap_list_environments()
```

**Retorno:**

```json
{
  "environments": [
    {
      "system_id": "ED2",
      "host": "awsntwpstx01.engdb.infra",
      "port": 8000,
      "client": "500",
      "user": "egoetz",
      "language": "EN",
      "use_https": false
    },
    {
      "system_id": "EQ2",
      "host": "awsntwpstx01.engdb.infra",
      "port": 8008,
      "client": "500",
      "user": "egoetz",
      "language": "EN",
      "use_https": false
    }
  ]
}
```

---

### 1.5 `sap_delete_password`

Remove as credenciais salvas de um ambiente (configuração + keyring).

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `system_id` | string | Sim | — | ID do ambiente (ex: `ED2`) |

**Exemplo:**

```
sap_delete_password(system_id="EQ2")
```

**Retorno:**

```json
{
  "deleted": true,
  "system_id": "EQ2",
  "message": "Credentials for EQ2 removed from config and OS credential manager."
}
```

---

## 2. Repositório ABAP

### 2.1 `sap_search`

Pesquisa objetos no repositório ABAP. Suporta curingas (`*`).

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `query` | string | Sim | — | Padrão de busca (ex: `Z*`, `ZCL_MY*`, `/TAX/*`) |
| `object_type` | string | Não | `""` | Filtro: `PROG`, `CLAS`, `INTF`, `FUGR`, `TABL` |
| `max_results` | int | Não | `50` | Número máximo de resultados |

**Exemplo 1 — busca genérica:**

```
sap_search(query="ZREPORT*")
```

**Exemplo 2 — filtrar por tipo:**

```
sap_search(query="ZCL_*", object_type="CLAS", max_results=10)
```

**Exemplo 3 — buscar por nome exato:**

```
sap_search(query="ZREPORT_PROD")
```

**Retorno:**

```json
{
  "count": 1,
  "objects": [
    {
      "name": "ZREPORT_PROD",
      "type": "PROG/P",
      "uri": "/sap/bc/adt/programs/programs/zreport_prod",
      "package": "ZGOETZ",
      "description": "Production report"
    }
  ]
}
```

---

### 2.2 `sap_browse_package`

Lista o conteúdo de um pacote ABAP (classe de desenvolvimento).

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `package_name` | string | Sim | — | Nome do pacote (ex: `ZGOETZ`, `$TMP`, `/TAX/SPED_MONITOR`) |

**Exemplo 1 — pacote simples:**

```
sap_browse_package(package_name="ZGOETZ")
```

**Exemplo 2 — pacote com namespace:**

```
sap_browse_package(package_name="/TAX/SPED_MONITOR")
```

**Retorno:**

```json
{
  "package": "ZGOETZ",
  "objects": [
    {
      "name": "ZREPORT_PROD",
      "type": "PROG/P",
      "uri": "/sap/bc/adt/programs/programs/zreport_prod",
      "description": "Production report"
    },
    {
      "name": "ZCL_MY_CLASS",
      "type": "CLAS/OC",
      "uri": "/sap/bc/adt/oo/classes/zcl_my_class",
      "description": "My custom class"
    }
  ]
}
```

---

### 2.3 `sap_object_metadata`

Retorna metadados detalhados de um objeto ABAP pela sua URI ADT.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `object_uri` | string | Sim | — | URI ADT do objeto |

**Padrões de URI por tipo:**

| Tipo | Template de URI |
|------|-----------------|
| Programa | `/sap/bc/adt/programs/programs/{nome_em_minúsculo}` |
| Classe | `/sap/bc/adt/oo/classes/{nome_em_minúsculo}` |
| Interface | `/sap/bc/adt/oo/interfaces/{nome_em_minúsculo}` |
| Grupo de Funções | `/sap/bc/adt/functions/groups/{nome_em_minúsculo}` |

**Exemplo:**

```
sap_object_metadata(object_uri="/sap/bc/adt/programs/programs/zreport_prod")
```

**Retorno:**

```json
{
  "name": "ZREPORT_PROD",
  "uri": "/sap/bc/adt/programs/programs/zreport_prod",
  "type": "PROG/P",
  "package_name": "ZGOETZ",
  "description": "Production report",
  "responsible_user": "EGOETZ",
  "source_uri": "/sap/bc/adt/programs/programs/zreport_prod/source/main"
}
```

---

## 3. Código-Fonte

### 3.1 `sap_read_source`

Lê o código-fonte de um objeto ABAP. Opcionalmente salva em arquivo local.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `object_name` | string | Sim | — | Nome do objeto (ex: `ZREPORT_PROD`) |
| `object_type` | string | Não | `PROG` | Tipo: `PROG`, `CLAS`, `INTF`, `FUGR` |
| `version` | string | Não | `active` | `active` ou `inactive` |
| `save_to` | string | Não | `""` | Diretório ou caminho completo para salvar localmente |

**Exemplo 1 — ler código:**

```
sap_read_source(object_name="ZREPORT_PROD")
```

**Retorno:** Código ABAP em texto plano.

```abap
REPORT zreport_prod.

WRITE: / 'Hello, SAP!'.
```

**Exemplo 2 — ler e salvar em diretório:**

```
sap_read_source(
    object_name="ZREPORT_PROD",
    save_to="e:\\ENGDB\\codigo"
)
```

**Retorno:**

```json
{
  "source": "REPORT zreport_prod.\n\nWRITE: / 'Hello, SAP!'.\n",
  "saved_to": "e:\\ENGDB\\codigo\\zreport_prod.abap"
}
```

**Exemplo 3 — ler classe:**

```
sap_read_source(object_name="ZCL_MY_CLASS", object_type="CLAS")
```

**Exemplo 4 — ler versão inativa:**

```
sap_read_source(object_name="ZREPORT_PROD", version="inactive")
```

---

### 3.2 `sap_write_source`

Escreve código-fonte em um objeto ABAP com workflow completo automatizado:
1. Verifica necessidade de transport request
2. Trava (lock) o objeto
3. Escreve o código-fonte
4. Ativa (compila) o objeto (opcional)
5. Destrava (unlock) o objeto

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `object_name` | string | Sim | — | Nome do objeto |
| `source_code` | string | Não* | `""` | Código ABAP (texto). Se vazio, usa `source_file` |
| `source_file` | string | Não* | `""` | Caminho de arquivo local com o código |
| `object_type` | string | Não | `PROG` | `PROG`, `CLAS`, `INTF`, `FUGR` |
| `transport_request` | string | Não | `""` | Número do transport (ex: `ED2K971420`). Auto-detectado se vazio |
| `activate` | bool | Não | `true` | Ativar após gravar |

> *Pelo menos um entre `source_code` e `source_file` é obrigatório.

**Exemplo 1 — código inline:**

```
sap_write_source(
    object_name="ZREPORT_PROD",
    source_code="REPORT zreport_prod.\n\nWRITE: / 'Updated via MCP!'.\n",
    transport_request="ED2K971420"
)
```

**Exemplo 2 — código de arquivo local:**

```
sap_write_source(
    object_name="ZREPORT_PROD",
    source_file="e:\\ENGDB\\codigo\\zreport_prod.abap",
    transport_request="ED2K971420"
)
```

**Exemplo 3 — sem ativação (apenas gravar):**

```
sap_write_source(
    object_name="ZREPORT_PROD",
    source_code="REPORT zreport_prod.\n\nWRITE: / 'Draft'.\n",
    transport_request="ED2K971420",
    activate=false
)
```

**Retorno (sucesso):**

```json
{
  "written": true,
  "object": "ZREPORT_PROD",
  "transport": "ED2K971420",
  "activated": true,
  "messages": []
}
```

**Retorno (erro de ativação):**

```json
{
  "written": true,
  "object": "ZREPORT_PROD",
  "transport": "ED2K971420",
  "activated": false,
  "messages": [
    {
      "severity": "E",
      "text": "Statement \"WRTE\" is unknown.",
      "line": 3,
      "column": 1
    }
  ]
}
```

---

### 3.3 `sap_activate`

Ativa (compila) um objeto ABAP sem alterar o código-fonte.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `object_name` | string | Sim | — | Nome do objeto |
| `object_type` | string | Não | `PROG` | `PROG`, `CLAS`, `INTF`, `FUGR` |
| `object_uri` | string | Não | `""` | URI ADT explícita (sobrescreve type/name) |

**Exemplo:**

```
sap_activate(object_name="ZREPORT_PROD")
```

**Retorno:**

```json
{
  "success": true,
  "messages": []
}
```

---

### 3.4 `sap_syntax_check`

Executa verificação de sintaxe sem ativar o objeto.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `object_name` | string | Sim | — | Nome do objeto |
| `object_type` | string | Não | `PROG` | `PROG`, `CLAS`, `INTF`, `FUGR` |

**Exemplo:**

```
sap_syntax_check(object_name="ZREPORT_PROD")
```

**Retorno (sem erros):**

```json
[]
```

**Retorno (com erros):**

```json
[
  {
    "severity": "E",
    "text": "Field \"LV_UNDEFINED\" is unknown.",
    "line": 15,
    "column": 10
  }
]
```

---

## 4. Gerenciamento de Transports

### 4.1 `sap_check_lock`

Verifica se um objeto está travado e por qual usuário.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `object_name` | string | Sim | — | Nome do objeto |
| `object_type` | string | Não | `PROG` | `PROG`, `CLAS`, `INTF`, `FUGR` |

**Exemplo:**

```
sap_check_lock(object_name="ZREPORT_PROD")
```

**Retorno (não travado):**

```json
{
  "locked": false,
  "locked_by_user": "",
  "lock_transport": ""
}
```

**Retorno (travado):**

```json
{
  "locked": true,
  "locked_by_user": "DEVELOPER2",
  "lock_transport": "ED2K971500"
}
```

---

### 4.2 `sap_list_transports`

Lista transport requests abertos (modificáveis) de um usuário.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `user` | string | Não | `""` | Usuário SAP. Se vazio, usa o usuário conectado |

**Exemplo 1 — transports do usuário conectado:**

```
sap_list_transports()
```

**Exemplo 2 — transports de outro usuário:**

```
sap_list_transports(user="DEVELOPER2")
```

**Retorno:**

```json
[
  {
    "number": "ED2K971420",
    "description": "ABAP development - egoetz",
    "owner": "EGOETZ",
    "status": "modifiable",
    "target_system": "EQ2",
    "tasks": [
      {
        "number": "ED2K971421",
        "description": "Development task",
        "owner": "EGOETZ"
      }
    ]
  }
]
```

---

### 4.3 `sap_create_transport`

Cria um novo transport request (workbench).

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `description` | string | Sim | — | Descrição curta da alteração |
| `package` | string | Não | `""` | Pacote ABAP alvo |
| `target_system` | string | Não | `""` | Sistema destino do transporte |

**Exemplo:**

```
sap_create_transport(
    description="Correção de report de produção",
    target_system="EQ2"
)
```

**Retorno:**

```json
{
  "number": "ED2K971530",
  "description": "Correção de report de produção",
  "owner": "EGOETZ"
}
```

---

### 4.4 `sap_release_transport`

Libera um transport request. **Use com cuidado** — após a liberação o transport entra na fila de importação.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `transport_number` | string | Sim | — | Número do transport (ex: `ED2K971420`) |

**Exemplo:**

```
sap_release_transport(transport_number="ED2K971530")
```

**Retorno:**

```json
{
  "released": true,
  "transport": "ED2K971530"
}
```

---

### 4.5 `sap_transport_check`

Verifica se um objeto necessita de transport request e quais estão disponíveis.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `object_name` | string | Sim | — | Nome do objeto |
| `object_type` | string | Não | `PROG` | `PROG`, `CLAS`, `INTF`, `FUGR` |

**Exemplo:**

```
sap_transport_check(object_name="ZREPORT_PROD")
```

**Retorno:**

```json
{
  "needs_transport": true,
  "locked": false,
  "locked_by_user": "",
  "lock_transport": "",
  "recording_transport": "ED2K971420",
  "available_transports": ["ED2K971420", "ED2K971500"]
}
```

> Objetos no pacote `$TMP` não necessitam de transport request (`needs_transport: false`).

---

## 5. Criação e Exclusão de Objetos

### 5.1 `sap_create_program`

Cria um novo programa ABAP (report executável).

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `name` | string | Sim | — | Nome do programa (ex: `ZTEST_NEW_REPORT`) |
| `description` | string | Não | `""` | Descrição curta |
| `package` | string | Não | `$TMP` | Pacote destino |
| `transport_request` | string | Não | `""` | Número do transport (obrigatório se pacote ≠ `$TMP`) |

**Exemplo 1 — programa temporário ($TMP):**

```
sap_create_program(
    name="ZTEST_TEMP",
    description="Teste temporário"
)
```

**Exemplo 2 — programa em pacote real:**

```
sap_create_program(
    name="ZREPORT_PROD",
    description="Production report",
    package="ZGOETZ",
    transport_request="ED2K971420"
)
```

**Retorno:**

```json
{
  "created": true,
  "name": "ZREPORT_PROD",
  "package": "ZGOETZ"
}
```

---

### 5.2 `sap_create_class`

Cria uma nova classe ABAP global.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `name` | string | Sim | — | Nome da classe (ex: `ZCL_MY_CLASS`) |
| `description` | string | Não | `""` | Descrição curta |
| `package` | string | Não | `$TMP` | Pacote destino |
| `transport_request` | string | Não | `""` | Número do transport |

**Exemplo:**

```
sap_create_class(
    name="ZCL_UTILS",
    description="Utility class",
    package="ZGOETZ",
    transport_request="ED2K971420"
)
```

**Retorno:**

```json
{
  "created": true,
  "name": "ZCL_UTILS",
  "package": "ZGOETZ"
}
```

---

### 5.3 `sap_create_interface`

Cria uma nova interface ABAP.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `name` | string | Sim | — | Nome da interface (ex: `ZIF_MY_INTF`) |
| `description` | string | Não | `""` | Descrição curta |
| `package` | string | Não | `$TMP` | Pacote destino |
| `transport_request` | string | Não | `""` | Número do transport |

**Exemplo:**

```
sap_create_interface(
    name="ZIF_EXPORTABLE",
    description="Interface for exportable objects",
    package="ZGOETZ",
    transport_request="ED2K971420"
)
```

**Retorno:**

```json
{
  "created": true,
  "name": "ZIF_EXPORTABLE",
  "package": "ZGOETZ"
}
```

---

### 5.4 `sap_delete_object`

Exclui um objeto ABAP. Requer confirmação explícita com `confirm="DELETE"`.

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|:-----------:|---------|-----------|
| `object_name` | string | Sim | — | Nome do objeto |
| `object_type` | string | Não | `PROG` | `PROG`, `CLAS`, `INTF`, `FUGR` |
| `transport_request` | string | Não | `""` | Número do transport (pode ser obrigatório) |
| `confirm` | string | Sim | `""` | Deve ser `DELETE` para confirmar |

**Exemplo:**

```
sap_delete_object(
    object_name="ZTEST_TEMP",
    object_type="PROG",
    confirm="DELETE"
)
```

**Retorno:**

```json
{
  "deleted": true,
  "object": "ZTEST_TEMP",
  "type": "PROG"
}
```

> **Atenção:** A exclusão é irreversível. Sem `confirm="DELETE"`, o comando retorna erro pedindo confirmação.

---

## 6. Pré-requisitos SAP para ADT

Para que os comandos ADT funcionem corretamente, o sistema SAP precisa estar configurado conforme descrito abaixo. Essas configurações são responsabilidade do administrador de sistema (Basis).

### 6.1 Versão Mínima do SAP

| Versão | Suporte |
|--------|---------|
| SAP NetWeaver 7.31 EHP1 SP04 | Mínimo (funcionalidades básicas) |
| SAP NetWeaver 7.40 SP02+ | Recomendado (syntax check, data preview, etc.) |
| SAP NetWeaver 7.50+ | Completo (ABAP Unit, ATC, source search) |
| SAP S/4HANA 1809+ | Completo |
| SAP S/4HANA 2023+ | Completo + Server Events via WebSocket |

### 6.2 Ativação de Serviços ICF (transação SICF)

Os serviços ICF são instalados **inativos** por segurança. O administrador deve ativá-los:

1. Abrir transação **SICF**
2. Campo "Virtual Host" → `DEFAULT_HOST` → Executar (F8)
3. Expandir: `default_host` → `sap` → `bc`
4. Clicar com botão direito em **`adt`** → **Activate Service**

**Serviço principal obrigatório:**

| Caminho SICF | Descrição |
|--------------|-----------|
| `/default_host/sap/bc/adt` | Ponto de entrada ADT (obrigatório) |

**Serviços adicionais (recomendados):**

| Caminho SICF | Necessário para |
|--------------|-----------------|
| `/default_host/sap/bc/abap/docu` | Documentação ABAP |
| `/default_host/sap/bc/abap/toolsdocu` | ABAP Element Info |
| `/default_host/sap/public/bc/abap/docu` | Documentação pública |
| `/default_host/sap/bc/apc/sap/adt` | Server Events (WebSocket, S/4HANA 2023+) |

### 6.3 Roles Padrão SAP

Atribuir uma das roles abaixo ao usuário que fará a conexão ADT:

| Role | Descrição | Permissão |
|------|-----------|-----------|
| `SAP_BC_DWB_ABAPDEVELOPER` | Desenvolvedor ABAP completo (Workbench + ADT) | Leitura + Escrita |
| `SAP_BC_ABAP_DEVELOPER_5` | Desenvolvedor ADT focado em código cloud-ready | Leitura + Escrita |
| `SAP_BC_DWB_WBDISPLAY` | Somente visualização (browse/display) | Somente Leitura |

> **Recomendação SAP:** Atribuir apenas uma dessas roles ao usuário (não combinar `SAP_BC_DWB_ABAPDEVELOPER` com `SAP_BC_ABAP_DEVELOPER_5`).

### 6.4 Objetos de Autorização Necessários

#### 6.4.1 `S_ADT_RES` — Acesso a Recursos ADT

Controla o acesso a URIs específicas do ADT. O campo de autorização é `URI`.

**URIs mínimas necessárias para este MCP:**

| URI Prefix | Funcionalidade |
|------------|----------------|
| `/sap/bc/adt/discovery` | Conexão / Discovery |
| `/sap/bc/adt/repository/*` | Busca e navegação no repositório |
| `/sap/bc/adt/programs/*` | Programas ABAP (leitura, escrita, criação) |
| `/sap/bc/adt/oo/*` | Classes e interfaces (leitura, escrita, criação) |
| `/sap/bc/adt/functions/*` | Grupos de funções |
| `/sap/bc/adt/packages/*` | Pacotes ABAP |
| `/sap/bc/adt/activation` | Ativação de objetos |
| `/sap/bc/adt/activation/*` | Ativação de objetos |
| `/sap/bc/adt/checkruns` | Syntax check |
| `/sap/bc/adt/checkruns/*` | Syntax check |
| `/sap/bc/adt/cts/*` | Change and Transport System |
| `/sap/bc/adt/abapsource/*` | Source code (formatter, ABAP Doc) |
| `/sap/bc/adt/compatibility/*` | Compatibilidade ADT |

#### 6.4.2 `S_DEVELOP` — ABAP Workbench

Controla criação e modificação de objetos de desenvolvimento.

| Campo | Valores Necessários | Descrição |
|-------|---------------------|-----------|
| `ACTVT` | `01` (Criar), `02` (Modificar), `03` (Exibir) | Atividades permitidas |
| `OBJTYPE` | `PROG`, `CLAS`, `INTF`, `FUGR`, `TABL`, `DEVC` | Tipos de objeto |
| `OBJNAME` | `*` ou nomes específicos | Nomes de objetos |
| `DEVCLASS` | `*` ou pacotes específicos (ex: `ZGOETZ`, `$TMP`) | Pacotes permitidos |
| `P_GROUP` | `*` | Grupo de autorização |

> Para somente leitura, `ACTVT = 03` é suficiente.

#### 6.4.3 `S_TRANSPRT` — Change and Transport System

| Campo | Valores Necessários | Descrição |
|-------|---------------------|-----------|
| `ACTVT` | `01` (Criar), `02` (Modificar), `03` (Exibir), `43` (Liberar) | Atividades |
| `TTYPE` | `DTRA` (Workbench), `TASK` (Tarefa) | Tipos de request |

> `ACTVT = 43` (Liberar) só é necessário se o usuário for liberar transports via MCP (`sap_release_transport`).

#### 6.4.4 `S_RFC` — Acesso RFC Remoto

| Campo | Valor | Tipo |
|-------|-------|------|
| `ACTVT` | `16` (Executar) | Atividade |
| `RFC_NAME` | `DDIF_FIELDINFO_GET` | Function Module |
| `RFC_NAME` | `RFCPING` | Function Module |
| `RFC_NAME` | `RFC_GET_FUNCTION_INTERFACE` | Function Module |
| `RFC_NAME` | `SADT_REST_RFC_ENDPOINT` | Function Module |
| `RFC_TYPE` | `FUNC` | Tipo do objeto RFC |

#### 6.4.5 `S_TCODE` — Transações para Integração SAP GUI

| Campo | Valor |
|-------|-------|
| `TCD` | `SADT_START_TCODE` |
| `TCD` | `SADT_START_WB_URI` |

### 6.5 Parâmetros de Perfil (transação RZ11)

Para uso de assertion tickets (segurança máxima na integração SAP GUI):

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| `login/create_sso2_ticket` | `3` | Emitir apenas assertion tickets |
| `login/accept_sso2_ticket` | `1` | Aceitar assertion tickets |

### 6.6 Checklist Rápido para o Administrador Basis

```
[ ] 1. Versão SAP >= NetWeaver 7.31 SP04 (preferencialmente 7.50+)
[ ] 2. Serviço ICF /sap/bc/adt ativado (transação SICF)
[ ] 3. Role SAP_BC_DWB_ABAPDEVELOPER atribuída ao usuário
[ ] 4. Objeto S_ADT_RES com URIs /sap/bc/adt/* liberadas
[ ] 5. Objeto S_DEVELOP com ACTVT 01+02+03, OBJTYPE PROG/CLAS/INTF/FUGR
[ ] 6. Objeto S_TRANSPRT com ACTVT 01+02+03 e TTYPE DTRA+TASK
[ ] 7. Objeto S_RFC com ACTVT 16 para function modules ADT
[ ] 8. Acesso de rede liberado para host:porta do SAP (sem firewall bloqueando)
[ ] 9. Usuário ABAP criado e com senha válida (não expirada)
```

---

## 7. Fluxo Típico de Trabalho

### 7.1 Setup Inicial (uma vez)

```
1. sap_save_password(system_id="ED2", host="awsntwpstx01.engdb.infra",
                     port=8000, client="500", user="egoetz", password="***")

2. sap_connect(system_id="ED2")
```

### 7.2 Explorar o Repositório

```
1. sap_search(query="Z*", object_type="PROG", max_results=20)
2. sap_browse_package(package_name="ZGOETZ")
3. sap_object_metadata(object_uri="/sap/bc/adt/programs/programs/zreport_prod")
```

### 7.3 Ler e Modificar Código

```
1. sap_read_source(object_name="ZREPORT_PROD")
   → Analisa o código atual

2. sap_read_source(object_name="ZREPORT_PROD", save_to="e:\\ENGDB\\codigo")
   → Salva localmente para edição no IDE

3. sap_write_source(
       object_name="ZREPORT_PROD",
       source_file="e:\\ENGDB\\codigo\\zreport_prod.abap",
       transport_request="ED2K971420"
   )
   → Grava, ativa e destrava automaticamente
```

### 7.4 Criar Novo Objeto

```
1. sap_list_transports()
   → Verifica transports disponíveis

2. sap_create_transport(description="Nova funcionalidade X")
   → Cria transport se necessário

3. sap_create_program(
       name="ZNEW_REPORT",
       description="Relatório de vendas",
       package="ZGOETZ",
       transport_request="ED2K971530"
   )

4. sap_write_source(
       object_name="ZNEW_REPORT",
       source_code="REPORT znew_report.\n\nSELECT * FROM vbak INTO TABLE @DATA(lt_orders) UP TO 100 ROWS.\nCL_DEMO_OUTPUT=>DISPLAY( lt_orders ).\n",
       transport_request="ED2K971530"
   )
```

### 7.5 Verificar e Diagnosticar

```
1. sap_syntax_check(object_name="ZREPORT_PROD")
   → Verifica sintaxe sem ativar

2. sap_check_lock(object_name="ZREPORT_PROD")
   → Verifica se está travado

3. sap_transport_check(object_name="ZREPORT_PROD")
   → Verifica necessidade de transport
```

---

> **Fonte oficial SAP:** [Configuring the ABAP Back-end for ABAP Development Tools for Eclipse](https://help.sap.com/doc/2e65ad9a26c84878b1413009f8ac07c3/202310.000/en-US/config_guide_system_backend_abap_development_tools.pdf)
