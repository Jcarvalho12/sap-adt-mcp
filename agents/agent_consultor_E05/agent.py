#!/usr/bin/env python3
"""
agent_consultor_E05 — Senior SAP technical consultant pipeline.

Utiliza **exclusivamente** as ferramentas e parâmetros documentados em
``sap-adt-python/docs/MCP_COMMAND_REFERENCE.md`` (servidor MCP ``user-sap-adt``).

Ferramentas MCP disponíveis (21):
  §1 Conexão:       sap_save_password, sap_connect, sap_discovery,
                     sap_list_environments, sap_delete_password
  §2 Repositório:   sap_search, sap_browse_package, sap_object_metadata
  §3 Código-fonte:  sap_read_source, sap_write_source, sap_activate, sap_syntax_check
  §4 Transports:    sap_check_lock, sap_list_transports, sap_create_transport,
                     sap_release_transport, sap_transport_check
  §5 Objetos:       sap_create_program, sap_create_class, sap_create_interface,
                     sap_delete_object

Run from repo root or this directory; configure ``config.yaml`` and environment.
"""

from __future__ import annotations

import argparse
import getpass
import json
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any

_AGENT_ROOT = Path(__file__).resolve().parent
if str(_AGENT_ROOT) not in sys.path:
    sys.path.insert(0, str(_AGENT_ROOT))

from analyzer import (
    DependencyMap,
    analyze_abap,
    categorize_findings,
    extract_dependencies,
    suggest_improved_snippet,
)
from comparator import two_column_diff, unified_diff_text
from prompts import (
    SYSTEM_CONSULTANT,
    approval_prompt,
    clone_params_prompt,
    final_success_prompt,
    format_findings_markdown,
    user_input_prompt,
)
import integration as mcp_integration
from sap_mandatory_flow import mandatory_write_activate
from tools import SapMcpTools, read_source_text


def _agent_dir() -> Path:
    return _AGENT_ROOT


def load_config(path: Path | None = None) -> dict[str, Any]:
    cfg_path = path or _agent_dir() / "config.yaml"
    raw = cfg_path.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore

        data = yaml.safe_load(raw)
    except Exception:
        print(
            "Warning: PyYAML not installed or YAML parse failed; using minimal defaults.",
            file=sys.stderr,
        )
        data = {}
    if not isinstance(data, dict):
        return {}
    return data


def resolve_sap_adt_src(cfg: dict[str, Any]) -> Path:
    rel = (
        cfg.get("sap_adt_python", {}).get("src_path", "../../sap-adt-python/src")
        if cfg
        else "../../sap-adt-python/src"
    )
    p = (_agent_dir() / rel).resolve()
    if not p.is_dir():
        raise FileNotFoundError(f"sap_adt src path not found: {p}")
    return p


def resolve_temp_dir(cfg: dict[str, Any]) -> Path:
    """Resolve a pasta temporária para armazenar código-fonte lido do SAP."""
    configured = (cfg.get("temp_dir") or "").strip()
    if configured:
        p = Path(configured)
        if not p.is_absolute():
            p = (_agent_dir() / p).resolve()
    else:
        p = Path(tempfile.gettempdir()) / "agent_consultor_E05"
    p.mkdir(parents=True, exist_ok=True)
    return p


def _replace_report_name(source: str, old_name: str, new_name: str) -> str:
    """
    Substitui o nome do objeto na primeira linha REPORT/PROGRAM do código ABAP.
    Ex.: ``REPORT zold_name.`` → ``REPORT znew_name.``
    """
    pattern = re.compile(
        r"^(\s*(?:REPORT|PROGRAM)\s+)" + re.escape(old_name) + r"(\b)",
        re.IGNORECASE | re.MULTILINE,
    )
    return pattern.sub(r"\g<1>" + new_name + r"\2", source, count=1)


def prepare_improved_file(
    temp_dir: Path,
    improved_source: str,
    scope_name: str,
    new_name: str,
    effective_type: str,
) -> Path:
    """
    Grava o código melhorado num arquivo na pasta temporária, com o nome do
    novo objeto aplicado no código-fonte (REPORT/PROGRAM statement).
    Retorna o caminho do arquivo gravado.
    """
    final_source = improved_source
    if effective_type.upper() == "PROG":
        final_source = _replace_report_name(improved_source, scope_name, new_name)

    filename = new_name.lower() + ".abap"
    file_path = temp_dir / filename
    file_path.write_text(final_source, encoding="utf-8")
    return file_path


def normalize_object_type_fixed(user_type: str, aliases: dict[str, str]) -> str:
    key = user_type.strip().upper().replace("-", " ")
    while "  " in key:
        key = key.replace("  ", " ")
    if key in aliases:
        return aliases[key]
    u = user_type.strip().upper()
    if u in aliases:
        return aliases[u]
    if u in ("PROG", "CLAS", "INTF", "FUGR", "TABL"):
        return u
    return "PROG"


def parse_search_objects(result: Any) -> list[dict[str, Any]]:
    if isinstance(result.data, dict) and "objects" in result.data:
        return list(result.data["objects"])
    try:
        j = json.loads(result.raw)
        return list(j.get("objects", []))
    except Exception:
        return []


def pick_object_uri(objects: list[dict[str, Any]], name: str) -> str:
    uname = name.upper()
    for o in objects:
        if (o.get("name") or "").upper() == uname:
            return str(o.get("uri", ""))
    if objects:
        return str(objects[0].get("uri", ""))
    return ""


def discover_object(
    tools: SapMcpTools,
    object_name: str,
    adt_type: str,
) -> tuple[list[dict[str, Any]], str]:
    """
    §2.1 sap_search — pesquisa objetos no repositório ABAP.
    Parâmetros: query (obrigatório), object_type, max_results.
    """
    q = object_name.strip().upper()
    res = tools.sap_search(query=q, object_type=adt_type, max_results=20)
    objs = parse_search_objects(res)
    uri = pick_object_uri(objs, object_name)
    return objs, uri


def metadata_dict(tools: SapMcpTools, uri: str) -> dict[str, Any]:
    """
    §2.3 sap_object_metadata — metadados detalhados pela URI ADT.
    Parâmetros: object_uri (obrigatório).
    """
    if not uri:
        return {}
    r = tools.sap_object_metadata(object_uri=uri)
    if isinstance(r.data, dict):
        return r.data
    try:
        return json.loads(r.raw)
    except Exception:
        return {"raw": r.raw[:2000]}


def _connect_failed(r: Any) -> bool:
    raw = getattr(r, "raw", str(r))
    if isinstance(r.data, str) and r.data.strip().upper().startswith("ERROR"):
        return True
    return "ERROR" in raw


def _password_required(r: Any) -> bool:
    raw = getattr(r, "raw", str(r))
    data = getattr(r, "data", "")
    blob = raw + (data if isinstance(data, str) else "")
    return "Password is required" in blob


def connect_from_config(
    tools: SapMcpTools,
    cfg: dict[str, Any],
    system_id_override: str | None = None,
    *,
    password_override: str | None = None,
    interactive: bool = True,
) -> str:
    """
    §1.2 sap_connect — conexão com o sistema SAP via ADT REST API.
    Parâmetros: system_id, host, port, client, user, password, language.
    """
    conn = cfg.get("connection", {})
    sid = (system_id_override or "").strip() or str(conn.get("system_id", "") or "")
    env_pwd = os.environ.get("SAP_PASSWORD", "").strip()
    kwargs: dict[str, Any] = {
        "system_id": sid,
        "host": str(conn.get("host", "") or ""),
        "port": int(conn.get("port") or 0),
        "client": str(conn.get("client", "") or ""),
        "user": str(conn.get("user", "") or ""),
        "password": (password_override or env_pwd).strip(),
        "language": str(conn.get("language", "") or ""),
    }
    r = tools.sap_connect(**kwargs)
    if _password_required(r) and interactive and sys.stdin.isatty():
        print(
            "Defina SAP_PASSWORD no ambiente, use sap_save_password no MCP, "
            "ou informe a senha abaixo.",
            file=sys.stderr,
        )
        pwd = getpass.getpass("Senha SAP: ").strip()
        if pwd:
            kwargs["password"] = pwd
            r = tools.sap_connect(**kwargs)
    elif _password_required(r) and not interactive:
        raise RuntimeError(
            "Senha SAP necessária: defina SAP_PASSWORD, use o campo de senha na UI web, "
            "ou sap_save_password / chaveiro do SO."
        )
    if _connect_failed(r):
        raise RuntimeError(r.raw)
    msg = r.raw
    print(msg)
    return msg


def run_analysis_phase(
    cfg: dict[str, Any],
    object_name: str,
    object_type: str,
    *,
    include_name: str | None = None,
    system_id: str | None = None,
    password: str | None = None,
) -> dict[str, Any]:
    """
    Fase de análise: descoberta, leitura, dependências, análise e diff.

    Ferramentas MCP utilizadas (conforme MCP_COMMAND_REFERENCE.md):
      - sap_connect (§1.2)
      - sap_search (§2.1)
      - sap_object_metadata (§2.3)
      - sap_read_source (§3.1) — parâmetros: object_name, object_type, version
    """
    aliases = cfg.get("object_type_aliases") or {}
    sap_src = resolve_sap_adt_src(cfg)
    tools = SapMcpTools(sap_src)

    sid = (system_id or "").strip() or str(
        (cfg.get("connection") or {}).get("system_id", "") or ""
    )
    connect_msg = connect_from_config(
        tools,
        cfg,
        system_id_override=system_id,
        password_override=password,
        interactive=False,
    )

    adt_type = normalize_object_type_fixed(object_type, aliases)
    objs, uri = discover_object(tools, object_name, adt_type)
    meta = metadata_dict(tools, uri)

    # Resolve pasta temporária para armazenar o código-fonte lido
    temp_dir = resolve_temp_dir(cfg)

    # §3.1 sap_read_source — parâmetros: object_name, object_type, version, save_to
    # Usa save_to para gravar o código original numa pasta temporária local
    read_res = tools.sap_read_source(
        object_name=object_name.upper(),
        object_type=adt_type,
        save_to=str(temp_dir),
    )
    source = read_source_text(read_res)
    if not source.strip():
        raise RuntimeError("Fonte vazia ou sap_read_source falhou.")

    # Determinar o caminho do arquivo salvo pelo sap_read_source
    saved_file = ""
    if isinstance(read_res.data, dict) and read_res.data.get("saved_to"):
        saved_file = str(read_res.data["saved_to"])
    else:
        candidate = temp_dir / (object_name.lower() + ".abap")
        if candidate.is_file():
            saved_file = str(candidate)

    dep_map: DependencyMap = extract_dependencies(source, object_name.upper(), adt_type)
    scope_name = object_name.upper()
    effective_type = adt_type

    chosen_include = (include_name or "").strip().upper()
    if chosen_include:
        scope_name = chosen_include
        effective_type = "PROG"
        read_res = tools.sap_read_source(
            object_name=scope_name,
            object_type=effective_type,
            save_to=str(temp_dir),
        )
        source = read_source_text(read_res)
        if not source.strip():
            raise RuntimeError(f"Fonte vazia para o objeto escopado {scope_name}.")
        dep_map = extract_dependencies(source, scope_name, effective_type)
        if isinstance(read_res.data, dict) and read_res.data.get("saved_to"):
            saved_file = str(read_res.data["saved_to"])
        else:
            candidate = temp_dir / (scope_name.lower() + ".abap")
            if candidate.is_file():
                saved_file = str(candidate)

    findings = analyze_abap(source, scope_name, effective_type)
    by_cat = categorize_findings(findings)
    findings_md = format_findings_markdown(by_cat)
    improved = suggest_improved_snippet(source, findings)

    col_preview = two_column_diff(source, improved)
    udiff = unified_diff_text(
        source,
        improved,
        from_name=scope_name,
        to_name=scope_name + "_improved",
    )
    udiff_out = udiff[:8000] if len(udiff) > 8000 else udiff

    return {
        "ok": True,
        "connect_message": connect_msg,
        "system_id_hint": sid,
        "resolved_adt_type": adt_type,
        "scope_name": scope_name,
        "effective_type": effective_type,
        "object_name": object_name.strip().upper(),
        "discovery": {
            "matches": len(objs),
            "metadata_uri": uri,
            "package_hint": meta.get("package_name", ""),
            "objects_preview": objs[:15],
        },
        "metadata": meta,
        "dependency_map": dep_map.to_dict(),
        "findings_markdown": findings_md,
        "findings_raw_count": len(findings),
        "source": source,
        "improved": improved,
        "two_column_preview": col_preview,
        "unified_diff": udiff_out,
        "unified_diff_truncated": len(udiff) > 8000,
        "temp_dir": str(temp_dir),
        "saved_source_file": saved_file,
    }


def run_clone_phase(
    cfg: dict[str, Any],
    *,
    scope_name: str,
    effective_type: str,
    improved: str,
    new_name: str,
    package: str,
    transport: str = "",
    transport_description: str | None = None,
    system_id: str | None = None,
    password: str | None = None,
) -> dict[str, Any]:
    """
    Fase de clone: cria transporte se necessário, cria objeto, grava fonte via
    arquivo temporário e ativa.

    Fluxo de arquivo:
      1. Escreve o código melhorado (com novo nome de objeto) num arquivo .abap
         na pasta temporária
      2. Chama sap_write_source(source_file=<caminho>) para enviar o arquivo ao SAP

    Ferramentas MCP utilizadas (conforme MCP_COMMAND_REFERENCE.md):
      - sap_connect (§1.2)
      - sap_list_transports (§4.2)
      - sap_create_transport (§4.3)
      - sap_check_lock (§4.1)
      - sap_create_program / sap_create_class / sap_create_interface (§5.1–§5.3)
      - sap_transport_check (§4.5)
      - sap_write_source (§3.2) com source_file — lock/write/activate/unlock automáticos
      - sap_syntax_check (§3.4)
      - sap_activate (§3.3)
      - sap_release_transport (§4.4) — opcional, conforme config
    """
    sap_src = resolve_sap_adt_src(cfg)
    tools = SapMcpTools(sap_src)
    connect_from_config(
        tools,
        cfg,
        system_id_override=system_id,
        password_override=password,
        interactive=False,
    )

    new_name = new_name.strip().upper()
    package = package.strip().upper()
    tr = transport.strip().upper()

    if not new_name or not package:
        raise ValueError("Nome do novo objeto e pacote são obrigatórios.")

    logs: list[str] = []
    logs.append(mcp_integration.workflow_7_1_setup_note(system_id or ""))

    # §4.2 sap_list_transports — listar transports abertos
    pre_logs, suggested_tr = mcp_integration.clone_phase_preflight(tools, cfg)
    logs.extend(pre_logs)
    if not tr and suggested_tr:
        tr = suggested_tr
        logs.append(f"[config] Reusing first open transport from list: {tr}")

    # §4.3 sap_create_transport — criar transport se necessário
    if not tr and package != "$TMP":
        desc = (transport_description or "").strip() or f"Consultant clone {new_name}"
        try:
            ctr = tools.sap_create_transport(description=desc, package=package)
        except Exception as exc:
            logs.append(str(exc))
            return {
                "ok": False,
                "error": "transport_create_failed",
                "message": str(exc),
                "hint": (
                    "Muitos sistemas SAP não permitem criar transporte só pela API ADT "
                    "(erro típico: «user action is not supported»). "
                    "Crie um pedido em SE09/SE10 e preencha o campo Transporte na UI, "
                    "ou use o pacote $TMP (objeto local, sem transporte)."
                ),
                "logs": logs,
            }
        logs.append(ctr.raw)
        if isinstance(ctr.data, dict) and ctr.data.get("number"):
            tr = str(ctr.data["number"])
        else:
            try:
                j = json.loads(ctr.raw)
                tr = str(j.get("number", ""))
            except Exception:
                tr = ""

    # §4.1 sap_check_lock — verificar lock prévio
    lock_info = tools.sap_check_lock(object_name=new_name, object_type=effective_type)
    logs.append(lock_info.raw)

    # §5.1–§5.3 — criar esqueleto do objeto
    sk_log = create_skeleton_object(
        tools,
        adt_type=effective_type,
        new_name=new_name,
        package=package,
        transport=tr,
        description=f"Improved copy of {scope_name}",
        silent=True,
    )
    logs.append("Create skeleton: " + sk_log)

    # §4.5 + §4.1 — diagnóstico após criação do esqueleto
    logs.extend(
        mcp_integration.after_skeleton_diagnostics(tools, new_name, effective_type, cfg)
    )

    # Preparar arquivo temporário com o código melhorado e novo nome do objeto
    temp_dir = resolve_temp_dir(cfg)
    improved_file = prepare_improved_file(
        temp_dir=temp_dir,
        improved_source=improved,
        scope_name=scope_name,
        new_name=new_name,
        effective_type=effective_type,
    )
    logs.append(f"[temp_file] Código melhorado gravado em: {improved_file}")

    # Fluxo obrigatório: sap_write_source(source_file=...) → sap_syntax_check → sap_activate
    mw = mandatory_write_activate(
        tools,
        object_name=new_name,
        object_type=effective_type,
        source_file=str(improved_file),
        package=package,
        forced_transport=tr,
    )
    logs.extend(mw.get("logs") or [])
    if not mw.get("ok"):
        return {
            "ok": False,
            "error": mw.get("error", "mandatory_write_failed"),
            "message": mw.get("message", ""),
            "logs": logs,
            "improved_file": str(improved_file),
        }

    activated_ok = bool(mw.get("activated"))
    last_syntax_raw = str(mw.get("syntax_raw", ""))

    # §4.4 sap_release_transport — opcional, conforme config
    rel = mcp_integration.optional_release_transport(tools, tr, cfg)
    if rel:
        logs.append(f"[sap_release_transport]\n{rel}")

    return {
        "ok": True,
        "new_name": new_name,
        "package": package,
        "transport": mw.get("transport_used") or tr or None,
        "activated": activated_ok,
        "logs": logs,
        "syntax_check_raw": last_syntax_raw,
        "improved_file": str(improved_file),
        "mcp_reference": str(mcp_integration.reference_doc_path(_agent_dir())),
    }


def create_skeleton_object(
    tools: SapMcpTools,
    adt_type: str,
    new_name: str,
    package: str,
    transport: str,
    description: str,
    *,
    silent: bool = False,
) -> str:
    """
    §5.1–§5.3 — Cria esqueleto do objeto usando as ferramentas MCP:
      - sap_create_program: parâmetros name, description, package, transport_request
      - sap_create_class: parâmetros name, description, package, transport_request
      - sap_create_interface: parâmetros name, description, package, transport_request
    """
    if adt_type == "PROG":
        r = tools.sap_create_program(
            name=new_name,
            description=description or "Consultant clone",
            package=package,
            transport_request=transport,
        )
    elif adt_type == "CLAS":
        r = tools.sap_create_class(
            name=new_name,
            description=description or "Consultant clone",
            package=package,
            transport_request=transport,
        )
    elif adt_type == "INTF":
        r = tools.sap_create_interface(
            name=new_name,
            description=description or "Consultant clone",
            package=package,
            transport_request=transport,
        )
    else:
        raise ValueError(
            f"Object type {adt_type} is not supported for automatic creation. "
            "Use PROG, CLAS, or INTF (conforme MCP §5)."
        )
    if not silent:
        print(r.raw)
    if isinstance(r.data, dict) and r.data.get("error"):
        raise RuntimeError(str(r.data.get("message", r.raw)))
    return r.raw


def run_pipeline_interactive(
    cfg: dict[str, Any],
    object_name: str | None,
    object_type: str | None,
    include_name: str | None = None,
    system_id: str | None = None,
) -> None:
    """Pipeline interativo (CLI) usando somente ferramentas MCP documentadas."""
    aliases = cfg.get("object_type_aliases") or {}
    sap_src = resolve_sap_adt_src(cfg)
    tools = SapMcpTools(sap_src)

    print(SYSTEM_CONSULTANT[:400] + "...\n")
    sid = (system_id or "").strip() or str(
        (cfg.get("connection") or {}).get("system_id", "") or ""
    )
    print(
        "Connecting via sap_connect (MCP §1.2)... "
        f'equivalent: sap_connect(system_id="{sid or "?"}")',
    )
    connect_from_config(tools, cfg, system_id_override=system_id)

    # §1.3 sap_discovery (opcional)
    if (cfg.get("mcp") or {}).get("discovery_after_connect"):
        disc = tools.sap_discovery()
        print("\n--- sap_discovery (excerpt) ---\n", disc.raw[:2500])

    if not object_name or not object_type:
        print("\n" + user_input_prompt())
        object_name = input("Object name: ").strip()
        object_type = input("Object type: ").strip()

    adt_type = normalize_object_type_fixed(object_type, aliases)
    print(f"\nResolved ADT type: {adt_type}  (from '{object_type}')")

    # §2.1 sap_search + §2.3 sap_object_metadata
    objs, uri = discover_object(tools, object_name, adt_type)
    if not objs:
        print(
            f"Warning: sap_search returned no hits for {object_name!r} / {adt_type}. "
            "Continuing with read by name.",
            file=sys.stderr,
        )
    meta = metadata_dict(tools, uri)
    print("\n--- Discovery (summary) ---")
    print(json.dumps({
        "matches": len(objs),
        "metadata_uri": uri,
        "package_hint": meta.get("package_name", ""),
    }, indent=2))

    # Resolve pasta temporária para armazenar o código-fonte lido
    temp_dir = resolve_temp_dir(cfg)

    # §3.1 sap_read_source — parâmetros: object_name, object_type, version, save_to
    # Usa save_to para gravar o código original na pasta temporária
    read_res = tools.sap_read_source(
        object_name=object_name.upper(),
        object_type=adt_type,
        save_to=str(temp_dir),
    )
    source = read_source_text(read_res)
    if not source.strip():
        raise RuntimeError("Empty source or sap_read_source failed.")
    print(f"Código-fonte salvo em: {temp_dir}")

    dep_map: DependencyMap = extract_dependencies(source, object_name.upper(), adt_type)

    scope_name = object_name.upper()
    effective_type = adt_type
    chosen_include = (include_name or "").strip().upper()
    if chosen_include:
        scope_name = chosen_include
        effective_type = "PROG"
        read_res = tools.sap_read_source(
            object_name=scope_name,
            object_type=effective_type,
            save_to=str(temp_dir),
        )
        source = read_source_text(read_res)
        if not source.strip():
            raise RuntimeError(f"Empty source for scoped object {scope_name}.")
        dep_map = extract_dependencies(source, scope_name, effective_type)
    elif dep_map.includes and sys.stdin.isatty():
        print(
            "\nThis object references includes:",
            ", ".join(dep_map.includes),
        )
        inc = input(
            "Enter the **single** include/program name to analyze and clone "
            "(blank = keep main object only): "
        ).strip()
        if inc:
            scope_name = inc.upper()
            effective_type = "PROG"
            read_res = tools.sap_read_source(
                object_name=scope_name,
                object_type=effective_type,
                save_to=str(temp_dir),
            )
            source = read_source_text(read_res)
            if not source.strip():
                raise RuntimeError(f"Empty source for scoped object {scope_name}.")
            dep_map = extract_dependencies(source, scope_name, effective_type)

    print("\n--- Dependency map ---")
    print(json.dumps(dep_map.to_dict(), indent=2))

    findings = analyze_abap(source, scope_name, effective_type)
    by_cat = categorize_findings(findings)
    print("\n" + format_findings_markdown(by_cat))

    improved = suggest_improved_snippet(source, findings)

    print("\n--- Two-column preview (truncated lines) ---")
    print(two_column_diff(source, improved))
    print("\n--- Unified diff (excerpt) ---")
    udiff = unified_diff_text(
        source,
        improved,
        from_name=scope_name,
        to_name=scope_name + "_improved",
    )
    print(udiff[:8000] if len(udiff) > 8000 else udiff)

    print("\n" + approval_prompt())
    ans = input().strip().lower()
    if ans not in ("y", "yes", "sim", "s"):
        print("Aborted by user (no approval).")
        return

    print("\n" + clone_params_prompt())
    new_name = input("New object name: ").strip().upper()
    package = input("Package: ").strip().upper()
    tr = input("Transport (optional): ").strip().upper()

    if not new_name or not package:
        print("New name and package are mandatory. Abort.")
        return

    # §4.3 sap_create_transport (se necessário)
    if not tr and package != "$TMP":
        desc = (
            input("Transport description (for new request): ").strip()
            or f"Consultant clone {new_name}"
        )
        try:
            ctr = tools.sap_create_transport(description=desc, package=package)
        except Exception as exc:
            print(f"\nCriação automática de transporte falhou:\n{exc}\n", file=sys.stderr)
            print(
                "Alguns sistemas não permitem criar transporte pela API ADT. "
                "Crie um pedido em SE09/SE10 e informe o número abaixo, "
                "ou cancele (Ctrl+C) e execute de novo usando o pacote $TMP.\n",
                file=sys.stderr,
            )
            tr = input("Número do transporte (obrigatório para este pacote): ").strip().upper()
            if not tr:
                print("Abort: é necessário um transporte ou use o pacote $TMP.", file=sys.stderr)
                return
        else:
            print(ctr.raw)
            if isinstance(ctr.data, dict) and ctr.data.get("number"):
                tr = str(ctr.data["number"])
            else:
                try:
                    j = json.loads(ctr.raw)
                    tr = str(j.get("number", ""))
                except Exception:
                    tr = ""

    # §4.1 sap_check_lock
    lock_info = tools.sap_check_lock(object_name=new_name, object_type=effective_type)
    print(lock_info.raw)

    # §5.1–§5.3 criar esqueleto
    print("\nCreating new object skeleton...")
    create_skeleton_object(
        tools,
        adt_type=effective_type,
        new_name=new_name,
        package=package,
        transport=tr,
        description=f"Improved copy of {scope_name}",
    )

    # Preparar arquivo temporário com o código melhorado e novo nome do objeto
    improved_file = prepare_improved_file(
        temp_dir=temp_dir,
        improved_source=improved,
        scope_name=scope_name,
        new_name=new_name,
        effective_type=effective_type,
    )
    print(f"\nCódigo melhorado gravado em: {improved_file}")

    # §3.2 sap_write_source com source_file (lock + write + unlock automáticos pelo MCP)
    # §3.4 sap_syntax_check
    # §3.3 sap_activate
    syntax_retries = int(cfg.get("analysis", {}).get("syntax_check_retries", 2))
    attempt = 0
    activated_ok = False
    while attempt <= syntax_retries:
        attempt += 1
        wr = tools.sap_write_source(
            object_name=new_name,
            source_file=str(improved_file),
            object_type=effective_type,
            transport_request=tr,
            activate=False,
        )
        print(wr.raw)
        if isinstance(wr.data, dict) and wr.data.get("error"):
            print("Write failed:", wr.data, file=sys.stderr)
            return

        syn = tools.sap_syntax_check(object_name=new_name, object_type=effective_type)
        print("Syntax check:", syn.raw)
        messages: list[Any] = []
        if isinstance(syn.data, list):
            messages = syn.data
        err_like = [
            m for m in messages
            if str(m.get("severity", "")).lower() in ("error", "e", "abort")
        ]
        if err_like:
            print("Syntax issues remain; auto-fix not applied (review messages).", file=sys.stderr)
            if attempt > syntax_retries:
                break
            continue

        act = tools.sap_activate(object_name=new_name, object_type=effective_type)
        print(act.raw)
        if isinstance(act.data, dict):
            activated_ok = bool(act.data.get("success"))
        break

    print(
        "\n"
        + final_success_prompt(
            new_name=new_name,
            transport=tr,
            activated=activated_ok,
        )
    )
    print("Object successfully created (when creation API succeeded)")
    print("Improvements applied to the new object")
    print(f"Source file used: {improved_file}")
    print(f"Transport assigned: {tr or 'n/a'}")
    print(f"Activation: {'done' if activated_ok else 'pending / failed — check messages above'}")


def main() -> None:
    parser = argparse.ArgumentParser(description="agent_consultor_E05 SAP consultant agent")
    parser.add_argument("--config", type=Path, default=None, help="Path to config.yaml")
    parser.add_argument("--object", "-o", dest="object_name", default=None)
    parser.add_argument("--type", "-t", dest="object_type", default=None)
    parser.add_argument(
        "--include",
        dest="include_name",
        default=None,
        help="Optional include/program name to scope analysis and clone.",
    )
    parser.add_argument(
        "--system-id",
        dest="system_id",
        default=None,
        metavar="ID",
        help=(
            'SAP saved environment id for sap_connect, e.g. E05 '
            '(same as sap_connect(system_id="E05")). '
            "Overrides config.yaml connection.system_id."
        ),
    )
    args = parser.parse_args()

    cfg = load_config(args.config)
    try:
        run_pipeline_interactive(
            cfg,
            args.object_name,
            args.object_type,
            include_name=args.include_name,
            system_id=args.system_id,
        )
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
