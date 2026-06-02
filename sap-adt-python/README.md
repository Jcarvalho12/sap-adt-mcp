# SAP ADT Python - ABAP Development Workbench

Cliente Python para a API REST do SAP ADT com servidor MCP, permitindo que o Cursor IDE funcione como um workbench completo de desenvolvimento ABAP — pesquisar, editar, ativar e gerenciar transports, assim como o Eclipse ADT.

---

## Pré-requisitos


| Requisito  | Versão mínima | Verificação                                              |
| ---------- | ------------- | -------------------------------------------------------- |
| Python     | 3.10+         | `python --version`                                       |
| pip        | 23+           | `pip --version`                                          |
| Git        | 2.x           | `git --version`                                          |
| Cursor IDE | —             | Instalado com suporte a MCP                              |
| Rede       | —             | Acesso ao host SAP (ex: `host_icm.empresa.com.br:8000`) |


---

## Instalação Passo a Passo

### 1. Clonar o repositório

```bash
git clone https://gitlab.engdb.com.br/tax-solution/sap-adt-python.git
cd sap-adt-python
```

### 2. Criar ambiente virtual Python

**Windows (PowerShell):**

```powershell
python -m venv .venv
.venv\Scripts\activate
```

**Linux / macOS:**

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Instalar dependências

```bash
pip install -r requirements.txt
```

### 4. Instalar o pacote em modo desenvolvimento

```bash
pip install -e .
```

Isso registra o pacote `sap_adt` no Python e cria o comando `sap-adt-mcp` no PATH do ambiente virtual.

### 5. Verificar a instalação

```bash
python -c "from sap_adt.client import AdtClient; print('OK')"
```

---

## Configuração do MCP no Cursor

O servidor MCP permite que o Cursor IDE se comunique com o SAP. Há duas formas de configurá-lo:

### Opção A — Configuração automática (recomendada)

O repositório já inclui o arquivo `.cursor/mcp.json`. Basta **abrir a pasta do projeto no Cursor** e o servidor será registrado automaticamente com a chave `sap-adt`.

No painel de MCP do Cursor, ele aparece como `**user-sap-adt`** (o Cursor adiciona o prefixo `user-`).

> Se o servidor MCP não iniciar, substitua `${workspaceFolder}` em `args` pelo caminho absoluto do repositório (ex: `D:\\ENGDB\\sap-adt-python`).

### Opção B — Configuração global

Para disponibilizar o MCP em **qualquer workspace** do Cursor, adicione o bloco abaixo no arquivo `~/.cursor/mcp.json`:

**Windows:** `C:\Users\<seu-usuario>\.cursor\mcp.json`
**Linux/macOS:** `~/.cursor/mcp.json`

```json
{
  "mcpServers": {
    "sap-adt": {
      "command": "python",
      "args": ["\\caminho\\absoluto\\para\\sap-adt-python\\scripts\\run_mcp.py"],
      "env": {
        "SAP_HOST": "host_icm.empresa.com.br",
        "SAP_PORT": "8000",
        "SAP_CLIENT":"100",
        "SAP_USER": "username",
        "SAP_LANGUAGE": "EN"
      }
    }
  }
}
```

> Ajuste o caminho em `args` para o local onde você clonou o repositório. No Linux/macOS use barras normais.

### Verificar se o MCP está ativo no Cursor

1. Abra o Cursor IDE
2. Abra a pasta do projeto (`sap-adt-python`)
3. Acesse **Settings > MCP** (ou Ctrl+Shift+P → "MCP")
4. O servidor `**user-sap-adt`** deve aparecer com status verde (ativo)
5. Teste no chat do Cursor: digite `sap_list_environments()` — deve retornar a lista de ambientes salvos

### Solução de problemas


| Problema                           | Solução                                                                |
| ---------------------------------- | ---------------------------------------------------------------------- |
| Servidor não aparece               | Verifique se `.cursor/mcp.json` existe na raiz do projeto              |
| Servidor aparece em vermelho       | Verifique o caminho do Python e do `run_mcp.py`; veja logs no terminal |
| `ModuleNotFoundError: sap_adt`     | Execute `pip install -e .` no ambiente virtual correto                 |
| Servidor antigo `user-sap-adt-DEV` | Remova a entrada antiga de `~/.cursor/mcp.json`                        |
| `ERROR: Password is required`      | Execute `sap_save_password(...)` primeiro (veja seção abaixo)          |


---

## Configuração Inicial de Credenciais

Antes de conectar ao SAP, salve as credenciais uma única vez. A senha é armazenada no **gerenciador de credenciais do sistema operacional** (Windows Credential Manager / macOS Keychain / Linux Secret Service).

### Salvar credenciais (executar no chat do Cursor)

```
sap_save_password(
    system_id="DEV",
    host="host_icm.empresa.com.br",
    port=8000,
    client="100",
    user="username",
    password="SuaSenhaAqui"
)
```

### Conectar ao SAP

```
sap_connect(system_id="DEV")
```

A senha é recuperada automaticamente do keyring do SO — nunca precisa ser passada novamente.

> Os parâmetros de conexão ficam em `~/.sap-adt/environments.json` (sem senhas). Para remover um ambiente: `sap_delete_password(system_id="DEV")`.

---

## Teste Rápido de Conexão

Para testar a conectividade fora do Cursor:

```bash
python scripts/test_connection.py
```

---

## Sistemas SAP Configurados


| Parâmetro | DEV (Desenvolvimento)      | EQ2 (Qualidade)            |
| --------- | -------------------------- | -------------------------- |
| Host      | `host_icm.empresa.com.br`  | `host_icm.empresa.com.br`  |
| Porta     | `8000`                     | `8008`                     |
| Mandante  | `100`                      | `200`                      |
| Usuário   | `username`                 | `username`                 |
| Idioma    | `EN`                       | `EN`                       |


---

## Ferramentas MCP Disponíveis (21 ferramentas)

### Conexão e Credenciais


| Ferramenta              | Descrição                                                 |
| ----------------------- | --------------------------------------------------------- |
| `sap_connect`           | Autenticar no sistema SAP (suporta ambientes salvos)      |
| `sap_discovery`         | Listar serviços ADT disponíveis                           |
| `sap_save_password`     | Armazenar credenciais no gerenciador de credenciais do SO |
| `sap_delete_password`   | Remover credenciais salvas                                |
| `sap_list_environments` | Listar ambientes SAP salvos                               |


### Repositório


| Ferramenta            | Descrição                                                     |
| --------------------- | ------------------------------------------------------------- |
| `sap_search`          | Pesquisar objetos ABAP (CLAS, PROG, INTF, FUGR, TABL)         |
| `sap_browse_package`  | Listar conteúdo de pacotes (suporta namespaces)               |
| `sap_object_metadata` | Obter detalhes de um objeto (nome, tipo, pacote, responsável) |


### Código-Fonte


| Ferramenta         | Descrição                                                  |
| ------------------ | ---------------------------------------------------------- |
| `sap_read_source`  | Ler código-fonte ABAP (opcional: salvar em arquivo local)  |
| `sap_write_source` | Gravar fonte com bloqueio automático, transport e ativação |
| `sap_activate`     | Compilar/ativar objetos                                    |
| `sap_syntax_check` | Verificação de sintaxe sem ativar                          |


### Gerenciamento de Transports


| Ferramenta              | Descrição                                  |
| ----------------------- | ------------------------------------------ |
| `sap_check_lock`        | Verificar status de bloqueio do objeto     |
| `sap_list_transports`   | Listar transport requests abertos          |
| `sap_create_transport`  | Criar novo transport request               |
| `sap_release_transport` | Liberar um transport request               |
| `sap_transport_check`   | Verificar se objeto necessita de transport |


### Criação e Exclusão de Objetos


| Ferramenta             | Descrição                                     |
| ---------------------- | --------------------------------------------- |
| `sap_create_program`   | Criar novo programa ABAP                      |
| `sap_create_class`     | Criar nova classe ABAP                        |
| `sap_create_interface` | Criar nova interface ABAP                     |
| `sap_delete_object`    | Excluir objeto ABAP (requer confirm='DELETE') |


> Referência completa com parâmetros, exemplos e retornos: [docs/MCP_COMMAND_REFERENCE.md](docs/MCP_COMMAND_REFERENCE.md)

---

## Arquitetura

```
Cursor IDE  →  Servidor MCP (stdio/JSON-RPC)  →  Cliente REST ADT  →  SAP /sap/bc/adt/*
```

O projeto utiliza os mesmos endpoints HTTP que o Eclipse ADT. Todas as operações passam por `/sap/bc/adt/` no sistema SAP.

```
src/sap_adt/
├── client.py            # Cliente HTTP ADT (autenticação, CSRF, sessões stateful)
├── credential_store.py  # Armazenamento seguro de senhas via keyring do SO
├── models.py            # Modelos de dados (AbapObject, TransportRequest, etc.)
├── exceptions.py        # Hierarquia de exceções
├── repository.py        # Pesquisa e navegação no repositório ABAP
├── source.py            # Leitura/escrita de código-fonte com gerenciamento de bloqueio
├── activation.py        # Ativação de objetos, verificação de sintaxe
├── transport.py         # Gerenciamento de transport requests
└── mcp_server.py        # Servidor MCP expondo 21 ferramentas
```

---

## Dependências


| Pacote   | Versão | Finalidade                                           |
| -------- | ------ | ---------------------------------------------------- |
| requests | >=2.31 | Cliente HTTP para a API REST ADT                     |
| mcp      | >=1.0  | SDK do Model Context Protocol (FastMCP)              |
| lxml     | >=5.0  | Parsing de XML para respostas ADT                    |
| keyring  | >=25.0 | Armazenamento seguro de credenciais no keyring do SO |


---

## Documentação

| Documento                                                                  | Descrição                                                    |
| -------------------------------------------------------------------------- | ------------------------------------------------------------ |
| [docs/PROJECT_DOCUMENTATION.md](docs/PROJECT_DOCUMENTATION.md)             | Documentação técnica completa (inglês)                       |
| [docs/PROJECT_DOCUMENTATION_PT-BR.md](docs/PROJECT_DOCUMENTATION_PT-BR.md) | Documentação técnica completa (português)                    |
| [docs/MCP_COMMAND_REFERENCE.md](docs/MCP_COMMAND_REFERENCE.md)             | Referência de comandos MCP com exemplos e pré-requisitos SAP |
| [AGENTS.md](AGENTS.md)                                                     | Instruções para agentes Cursor                               |

