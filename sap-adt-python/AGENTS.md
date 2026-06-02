# SAP ADT Python — Agent Instructions

This project provides MCP tools that let Cursor function as an ABAP development workbench.

## Available MCP Tools

Use the **sap-adt** MCP server for all SAP/ABAP interactions. In Cursor this server is listed as **user-sap-adt** (Cursor adds the `user-` prefix to user-defined MCP servers).

| Tool | Purpose |
|------|---------|
| `sap_connect` | Authenticate to SAP system (supports saved environments via system_id) |
| `sap_discovery` | List available ADT services |
| `sap_save_password` | Store credentials securely in OS credential manager |
| `sap_delete_password` | Remove saved credentials for an environment |
| `sap_list_environments` | List all saved SAP environments |
| `sap_search` | Search ABAP objects (supports wildcards: `Z*`, `ZCL_*`) |
| `sap_browse_package` | List contents of a package |
| `sap_object_metadata` | Get object details (type, package, author) |
| `sap_read_source` | Read ABAP source code |
| `sap_write_source` | Write source + auto-lock + transport check + activate |
| `sap_activate` | Compile/activate an ABAP object |
| `sap_syntax_check` | Check syntax without activating |
| `sap_check_lock` | Check if object is locked and by whom |
| `sap_list_transports` | List open transport requests |
| `sap_create_transport` | Create a new transport request |
| `sap_release_transport` | Release a transport request |
| `sap_transport_check` | Check if object needs a transport |
| `sap_create_program` | Create a new ABAP program |
| `sap_create_class` | Create a new ABAP class |
| `sap_create_interface` | Create a new ABAP interface |
| `sap_delete_object` | Delete an ABAP object (requires confirm='DELETE') |

## ABAP Development Workflow

### First-time setup (once per environment):
1. Call `sap_save_password` with system_id, host, port, client, user, and password
2. The password is stored in the OS credential manager (never in plain text files)

### Before editing any ABAP object:
1. Call `sap_connect(system_id='ED2')` to authenticate (if not already connected)
2. Use `sap_search` to find the object
3. Use `sap_read_source` to get the current source code
4. Use `sap_check_lock` to verify the object is not locked by another user

### To modify an ABAP object:
1. Use `sap_write_source` — it handles lock, transport, write, activate, and unlock automatically
2. If no transport request is available and the object is not in `$TMP`, use `sap_create_transport` first
3. Always check the activation result for errors

### Transport request rules:
- Objects in package `$TMP` do NOT require transport requests
- All other packages require a transport request for any modification
- Use `sap_transport_check` to determine if a transport is needed
- Use `sap_list_transports` to find existing open transports
- Use `sap_create_transport` if no suitable transport exists

## Target System

- Environment: **ED2**
- Host: `awsntwpstx01.engdb.infra:8000`
- Client: `500`
- User: `egoetz`
- Language: `EN`
