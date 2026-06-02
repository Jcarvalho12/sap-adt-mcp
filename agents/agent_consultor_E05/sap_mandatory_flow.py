"""
Fluxo obrigatório SAP ADT usando **somente** as ferramentas documentadas em
``sap-adt-python/docs/MCP_COMMAND_REFERENCE.md``.

O ``sap_write_source`` do MCP já executa internamente:
  1. Trava (lock) o objeto
  2. Verifica necessidade de transport request
  3. Escreve o código-fonte
  4. Opcionalmente ativa (compila)
  5. Destrava (unlock) o objeto

Portanto este módulo **não** chama ``sap_lock``/``sap_unlock`` (que não existem
no MCP). Em vez disso, orquestra:
  - ``sap_transport_check`` + ``sap_list_transports`` → fila de transports
  - ``sap_check_lock`` → verificação prévia
  - ``sap_write_source(activate=False)`` → escrita com lock automático
  - ``sap_syntax_check`` → verificação de sintaxe
  - ``sap_activate`` → ativação separada
"""

from __future__ import annotations

import json
import re
from typing import Any

from tools import SapMcpTools, SapToolResult

_MAX_WRITE_ATTEMPTS = 3


def _parse_json_result(r: SapToolResult) -> Any:
    if isinstance(r.data, (dict, list)):
        return r.data
    try:
        return json.loads(r.raw)
    except json.JSONDecodeError:
        return {"_raw": r.raw}


def _is_valid_tr(num: str) -> bool:
    s = (num or "").strip().upper()
    if not s or s == "X":
        return False
    return bool(re.match(r"^[A-Z0-9]{3,4}K\d{6}$", s))


def _build_transport_queue(
    tools: SapMcpTools,
    object_name: str,
    object_type: str,
    forced_first: str = "",
) -> list[str]:
    """
    Constrói fila de transports priorizando:
    1. ``forced_first`` (se válido)
    2. ``recording_transport`` de ``sap_transport_check``
    3. ``available_transports`` de ``sap_transport_check``
    4. Transports abertos via ``sap_list_transports``

    Parâmetros conforme MCP_COMMAND_REFERENCE.md §4.5 e §4.2.
    """
    tc = _parse_json_result(
        tools.sap_transport_check(object_name=object_name, object_type=object_type)
    )
    if not isinstance(tc, dict):
        tc = {}

    ordered: list[str] = []
    seen: set[str] = set()

    if _is_valid_tr(forced_first):
        ordered.append(forced_first.strip().upper())
        seen.add(ordered[-1])

    rec = tc.get("recording_transport") or ""
    if _is_valid_tr(str(rec)) and str(rec).strip().upper() not in seen:
        ordered.append(str(rec).strip().upper())
        seen.add(ordered[-1])

    for n in tc.get("available_transports") or []:
        ns = str(n).strip().upper()
        if _is_valid_tr(ns) and ns not in seen:
            ordered.append(ns)
            seen.add(ns)

    lt = _parse_json_result(tools.sap_list_transports())
    rows = lt if isinstance(lt, list) else []
    for tr in rows:
        if not isinstance(tr, dict):
            continue
        ns = str(tr.get("number", "")).strip().upper()
        if _is_valid_tr(ns) and ns not in seen:
            ordered.append(ns)
            seen.add(ns)

    return ordered


def _write_failed_transport(msg: str) -> bool:
    """Detecta se a falha de escrita é por problema de transport/lock recuperável."""
    m = (msg or "").lower()
    return (
        "423" in msg
        or "not locked" in m
        or "lock" in m and ("invalid" in m or "handle" in m)
        or "transport" in m and ("required" in m or "missing" in m)
    )


def mandatory_write_activate(
    tools: SapMcpTools,
    *,
    object_name: str,
    object_type: str,
    source_code: str = "",
    source_file: str = "",
    package: str,
    forced_transport: str = "",
) -> dict[str, Any]:
    """
    Fluxo completo de escrita usando somente ferramentas MCP documentadas:

    1. ``sap_transport_check`` + ``sap_list_transports`` → monta fila de TRs
    2. ``sap_check_lock`` → verifica lock prévio
    3. ``sap_write_source(activate=False)`` → lock + escrita automáticos (MCP §3.2)
       Usa ``source_file`` quando fornecido (lê do arquivo local),
       ou ``source_code`` quando fornecido em texto.
    4. ``sap_syntax_check`` → verificação de sintaxe (MCP §3.4)
    5. ``sap_activate`` → ativação (MCP §3.3)

    Parâmetros usados são **estritamente** os documentados no MCP_COMMAND_REFERENCE.md.
    """
    if not source_code and not source_file:
        return {
            "ok": False,
            "error": "no_source",
            "message": "É necessário fornecer source_code ou source_file.",
            "logs": [],
        }

    name_u = object_name.strip().upper()
    otype = object_type.strip().upper() or "PROG"
    logs: list[str] = []

    transport_queue = _build_transport_queue(
        tools, name_u, otype, forced_first=forced_transport
    )
    if not transport_queue and package.strip().upper() != "$TMP":
        logs.append(
            "[warn] Nenhum transporte CTS válido encontrado; sap_write_source pode falhar."
        )

    ck = _parse_json_result(
        tools.sap_check_lock(object_name=name_u, object_type=otype)
    )
    logs.append(
        f"[sap_check_lock] {json.dumps(ck) if isinstance(ck, dict) else ck}"
    )

    last_err = ""
    write_ok = False
    used_tr = ""

    write_kwargs_base: dict[str, Any] = {
        "object_name": name_u,
        "object_type": otype,
        "activate": False,
    }
    if source_file:
        write_kwargs_base["source_file"] = source_file
        logs.append(f"[info] Usando source_file: {source_file}")
    else:
        write_kwargs_base["source_code"] = source_code

    for attempt in range(1, _MAX_WRITE_ATTEMPTS + 1):
        tr = ""
        if transport_queue:
            idx = min(attempt - 1, len(transport_queue) - 1)
            tr = transport_queue[idx]
        elif _is_valid_tr(forced_transport):
            tr = forced_transport.strip().upper()

        write_kwargs = {**write_kwargs_base, "transport_request": tr}
        wr = tools.sap_write_source(**write_kwargs)
        wdata = _parse_json_result(wr)
        logs.append(f"[sap_write_source attempt={attempt}] {wr.raw[:2500]}")

        if isinstance(wdata, dict) and wdata.get("written"):
            write_ok = True
            used_tr = tr
            break

        err_msg = str(
            wdata.get("message", wr.raw) if isinstance(wdata, dict) else wr.raw
        )
        last_err = err_msg

        if _write_failed_transport(err_msg) and attempt < _MAX_WRITE_ATTEMPTS:
            continue

        if attempt == _MAX_WRITE_ATTEMPTS:
            break

        return {
            "ok": False,
            "error": "write_failed",
            "message": err_msg,
            "logs": logs,
        }

    if not write_ok:
        return {
            "ok": False,
            "error": "write_failed_after_retries",
            "message": last_err or "Falha após tentativas de escrita",
            "logs": logs,
        }

    syn = tools.sap_syntax_check(object_name=name_u, object_type=otype)
    logs.append(f"[sap_syntax_check] {syn.raw[:2000]}")

    act = tools.sap_activate(object_name=name_u, object_type=otype)
    logs.append(f"[sap_activate] {act.raw[:2000]}")
    act_ok = False
    ad = _parse_json_result(act)
    if isinstance(ad, dict):
        act_ok = bool(ad.get("success"))

    return {
        "ok": True,
        "transport_used": used_tr,
        "activated": act_ok,
        "logs": logs,
        "syntax_raw": syn.raw,
        "activate_raw": act.raw,
    }
