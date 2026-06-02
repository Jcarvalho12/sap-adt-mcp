"""
Integração com o SAP ADT seguindo **estritamente** os fluxos de
``sap-adt-python/docs/MCP_COMMAND_REFERENCE.md`` (especialmente a secção 7).

Não duplica lógica HTTP: apenas orquestra chamadas a ``SapMcpTools``.
Utiliza somente as 21 ferramentas e parâmetros documentados no MCP.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from tools import SapMcpTools

MCP_COMMAND_REFERENCE_RELATIVE = "../../sap-adt-python/docs/MCP_COMMAND_REFERENCE.md"


def reference_doc_path(agent_root: Path) -> Path:
    """Resolve o ficheiro MCP_COMMAND_REFERENCE.md a partir da pasta do agente."""
    return (agent_root / MCP_COMMAND_REFERENCE_RELATIVE).resolve()


def workflow_7_1_setup_note(system_id: str) -> str:
    """Texto alinhado a §7.1 — setup inicial (sap_save_password + sap_connect)."""
    return (
        "Fluxo §7.1 (Setup): 1) sap_save_password(...) uma vez; 2) sap_connect(system_id=...). "
        f"Detalhes: {MCP_COMMAND_REFERENCE_RELATIVE}"
    )


def workflow_7_2_explore(
    tools: SapMcpTools,
    query: str,
    *,
    object_type: str = "",
    package_name: str = "",
    metadata_uri: str = "",
) -> dict[str, Any]:
    """
    §7.2 Explorar repositório:
      - sap_search(query, object_type, max_results) — §2.1
      - sap_browse_package(package_name) — §2.2
      - sap_object_metadata(object_uri) — §2.3
    """
    out: dict[str, Any] = {"steps": []}
    r_search = tools.sap_search(query=query, object_type=object_type, max_results=30)
    out["steps"].append({"tool": "sap_search", "result": r_search.raw[:4000]})
    if package_name:
        r_pkg = tools.sap_browse_package(package_name=package_name)
        out["steps"].append({"tool": "sap_browse_package", "result": r_pkg.raw[:4000]})
    if metadata_uri:
        r_meta = tools.sap_object_metadata(object_uri=metadata_uri)
        out["steps"].append({"tool": "sap_object_metadata", "result": r_meta.raw[:4000]})
    return out


def clone_phase_preflight(
    tools: SapMcpTools,
    cfg: dict[str, Any],
) -> tuple[list[str], str | None]:
    """
    §7.4 — Antes de criar objeto: listar transports abertos.
    Usa sap_list_transports() — §4.2 (parâmetro opcional: user).

    Retorna (logs, primeiro número de transporte válido se existir e a config permitir reuso).
    """
    logs: list[str] = []
    wf = (cfg.get("mcp") or {}).get("clone_workflow") or {}
    if not wf.get("list_transports_before_create", True):
        return logs, None

    r = tools.sap_list_transports()
    logs.append(f"[sap_list_transports]\n{r.raw}")

    suggested: str | None = None
    rows: list[Any] = []
    if isinstance(r.data, list):
        rows = r.data
    else:
        try:
            rows = json.loads(r.raw)
        except Exception:
            rows = []
    if wf.get("reuse_first_open_transport", False) and rows:
        first = rows[0]
        if isinstance(first, dict) and first.get("number"):
            suggested = str(first["number"]).strip().upper()
    return logs, suggested


def after_skeleton_diagnostics(
    tools: SapMcpTools,
    object_name: str,
    object_type: str,
    cfg: dict[str, Any],
) -> list[str]:
    """
    §7.5 — Após criar o esqueleto do objeto:
      - sap_transport_check(object_name, object_type) — §4.5
      - sap_check_lock(object_name, object_type) — §4.1

    Somente parâmetros documentados no MCP.
    """
    wf = (cfg.get("mcp") or {}).get("clone_workflow") or {}
    if not wf.get("transport_check_after_create", True):
        return []

    logs: list[str] = []
    tc = tools.sap_transport_check(object_name=object_name, object_type=object_type)
    logs.append(f"[sap_transport_check]\n{tc.raw}")

    lk = tools.sap_check_lock(object_name=object_name, object_type=object_type)
    logs.append(f"[sap_check_lock]\n{lk.raw}")
    return logs


def optional_release_transport(
    tools: SapMcpTools,
    transport_number: str,
    cfg: dict[str, Any],
) -> str | None:
    """
    §4.4 sap_release_transport — só se configurado (por defeito desligado).
    Parâmetro: transport_number (obrigatório).
    """
    wf = (cfg.get("mcp") or {}).get("clone_workflow") or {}
    if not wf.get("release_transport_after_activate", False):
        return None
    if not transport_number or transport_number == "$TMP":
        return None
    r = tools.sap_release_transport(transport_number=transport_number)
    return r.raw
