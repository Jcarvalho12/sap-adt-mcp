# SAP ADT MCP - ABAP Development Workbench for Cursor

Repositório com servidores MCP (Model Context Protocol) para integração do Cursor IDE com sistemas SAP, permitindo desenvolvimento ABAP diretamente no Cursor — incluindo via Cursor Web.

---

## Servidores MCP Incluídos

| Servidor | Descrição | Tecnologia |
|----------|-----------|------------|
| **sap-adt** | Cliente REST para SAP ADT — pesquisar, ler, escrever, ativar objetos ABAP e gerenciar transports | Python |
| **sap-hana** | Acesso a SAP HANA via MCP | Node.js |

---

## Uso via Cursor Web

1. Acesse [cursor.sh](https://cursor.sh) e abra este repositório
2. O Cursor detecta automaticamente o `.cursor/mcp.json` e registra os servidores MCP
3. O servidor **sap-adt** aparece como `user-sap-adt` no painel de MCP

### Pré-requisitos no ambiente

- **Python 3.10+** (para o servidor SAP ADT)
- **Node.js** (para o servidor SAP HANA)

### Setup inicial (uma vez)

```bash
cd sap-adt-python
pip install -e .
```

### Configurar credenciais SAP (no chat do Cursor)

```
sap_save_password(
    system_id="DEV",
    host="host_icm.empresa.com.br",
    port=8000,
    client="100",
    user="seu_usuario",
    password="sua_senha"
)
```

### Conectar

```
sap_connect(system_id="DEV")
```

---

## Estrutura do Repositório

```
├── .cursor/mcp.json          # Configuração MCP (detectado automaticamente pelo Cursor)
├── sap-adt-python/            # Servidor MCP SAP ADT (Python)
│   ├── src/sap_adt/           # Código-fonte do cliente ADT e servidor MCP
│   ├── scripts/run_mcp.py     # Entry point do servidor MCP
│   ├── docs/                  # Documentação detalhada
│   └── pyproject.toml         # Dependências Python
├── sap-hana-server/           # Servidor MCP SAP HANA (Node.js)
├── agents/                    # Agentes auxiliares (Jira, Consultor SAP)
└── temp/                      # Arquivos ABAP temporários
```

---

## Ferramentas MCP SAP ADT Disponíveis (21 ferramentas)

| Categoria | Ferramentas |
|-----------|------------|
| **Conexão** | `sap_connect`, `sap_discovery`, `sap_save_password`, `sap_delete_password`, `sap_list_environments` |
| **Repositório** | `sap_search`, `sap_browse_package`, `sap_object_metadata` |
| **Código-fonte** | `sap_read_source`, `sap_write_source`, `sap_activate`, `sap_syntax_check` |
| **Transports** | `sap_check_lock`, `sap_list_transports`, `sap_create_transport`, `sap_release_transport`, `sap_transport_check` |
| **Criação** | `sap_create_program`, `sap_create_class`, `sap_create_interface`, `sap_delete_object` |

Para documentação detalhada, veja [sap-adt-python/docs/](sap-adt-python/docs/)
