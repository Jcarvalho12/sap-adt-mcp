"""MCP Server for SAP ADT — exposes ABAP development tools to Cursor IDE.

Run with:  python -m sap_adt.mcp_server
Or:        python scripts/run_mcp.py
"""

from __future__ import annotations

import json
import logging
import os
import sys
from dataclasses import asdict

from mcp.server.fastmcp import FastMCP

from .activation import ActivationService
from .client import AdtClient
from .credential_store import (
    SapEnvironment,
    delete_environment,
    get_environment,
    get_password as keyring_get_password,
    list_environments,
    save_environment,
)
from .exceptions import AdtError, AdtLockError
from .repository import RepositoryService
from .source import SourceService, resolve_object_uri
from .transport import TransportService

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger("sap_adt.mcp")

mcp = FastMCP("SAP ADT ABAP Workbench")

# Global client + services — initialised on sap_connect
_client: AdtClient | None = None
_repo: RepositoryService | None = None
_source: SourceService | None = None
_activation: ActivationService | None = None
_transport: TransportService | None = None


def _ensure_services() -> tuple[AdtClient, RepositoryService, SourceService, ActivationService, TransportService]:
    if _client is None or not _client.is_connected:
        raise AdtError("Not connected. Call sap_connect first.")
    assert _repo and _source and _activation and _transport
    return _client, _repo, _source, _activation, _transport


# ======================================================================
# Connection tools
# ======================================================================

@mcp.tool()
def sap_connect(
    system_id: str = "",
    host: str = "",
    port: int = 0,
    client: str = "",
    user: str = "",
    password: str = "",
    language: str = "",
) -> str:
    """Connect to an SAP system via ADT REST API.

    Resolution order for each parameter:
    1. Explicit argument passed to this tool
    2. Saved environment (if system_id is provided)
    3. Environment variables (SAP_HOST, SAP_PORT, …)
    4. Built-in defaults

    Password resolution:
    1. Explicit password argument
    2. SAP_PASSWORD environment variable
    3. OS credential manager (if system_id is provided or can be inferred)

    Use sap_save_password to store credentials securely in the OS credential
    manager so you never need to pass passwords in plain text.

    Args:
        system_id: Saved environment ID (e.g. 'ED2'). If provided, loads
                   host/port/client/user/language from stored config and
                   retrieves the password from the OS credential manager.
    """
    global _client, _repo, _source, _activation, _transport

    saved_env: SapEnvironment | None = None
    if system_id:
        saved_env = get_environment(system_id)

    host = host or (saved_env.host if saved_env else "") or os.environ.get("SAP_HOST", "awsntwpstx01.engdb.infra")
    port = port or (saved_env.port if saved_env else 0) or int(os.environ.get("SAP_PORT", "8000"))
    client = client or (saved_env.client if saved_env else "") or os.environ.get("SAP_CLIENT", "500")
    user = user or (saved_env.user if saved_env else "") or os.environ.get("SAP_USER", "egoetz")
    language = language or (saved_env.language if saved_env else "") or os.environ.get("SAP_LANGUAGE", "EN")
    use_https = (saved_env.use_https if saved_env else False) or os.environ.get("SAP_USE_HTTPS", "false").lower() == "true"

    if not password:
        password = os.environ.get("SAP_PASSWORD", "")
    if not password and system_id:
        password = keyring_get_password(system_id, user) or ""
    if not password and not system_id:
        for env in list_environments():
            if env.host == host and env.port == port and env.client == client and env.user == user:
                password = keyring_get_password(env.system_id, user) or ""
                break

    if not password:
        hint = " Use sap_save_password to store credentials securely." if not system_id else ""
        return f"ERROR: Password is required.{hint} Set SAP_PASSWORD env var, pass it directly, or use system_id with saved credentials."

    _client = AdtClient(
        host=host,
        port=port,
        client=client,
        user=user,
        password=password,
        language=language,
        use_https=use_https,
    )
    discovery_xml = _client.connect()

    _repo = RepositoryService(_client)
    _source = SourceService(_client)
    _activation = ActivationService(_client)
    _transport = TransportService(_client)

    source = f" (from saved environment '{system_id}')" if saved_env else ""
    return f"Connected to {host}:{port} (client {client}) as user {user}{source}. ADT services available."


@mcp.tool()
def sap_discovery() -> str:
    """List available ADT services on the connected SAP system."""
    client, *_ = _ensure_services()
    resp = client.get("/sap/bc/adt/discovery", accept="application/atomsvc+xml")
    return resp.text[:5000]


# ======================================================================
# Credential management tools
# ======================================================================

@mcp.tool()
def sap_save_password(
    system_id: str,
    password: str,
    host: str = "",
    port: int = 8000,
    client: str = "500",
    user: str = "",
    language: str = "EN",
    use_https: bool = False,
) -> str:
    """Save SAP environment credentials securely in the OS credential manager.

    The password is stored in the OS keyring (Windows Credential Manager,
    macOS Keychain, or Linux Secret Service). Connection parameters are
    stored in ~/.sap-adt/environments.json (no secrets in that file).

    After saving, use sap_connect(system_id='...') to connect without
    needing to pass any password.

    Args:
        system_id: Short identifier for this environment (e.g. 'ED2', 'QA1', 'PRD').
        password: The SAP password to store securely.
        host: SAP hostname.
        port: SAP port number.
        client: SAP client number.
        user: SAP user name.
        language: Logon language.
        use_https: Whether to use HTTPS.
    """
    if not system_id:
        return json.dumps({"error": True, "message": "system_id is required."})
    if not password:
        return json.dumps({"error": True, "message": "password is required."})
    if not host:
        return json.dumps({"error": True, "message": "host is required."})
    if not user:
        return json.dumps({"error": True, "message": "user is required."})

    env = SapEnvironment(
        system_id=system_id.upper(),
        host=host,
        port=port,
        client=client,
        user=user,
        language=language,
        use_https=use_https,
    )
    try:
        save_environment(env, password)
    except Exception as exc:
        return json.dumps({"error": True, "message": f"Failed to save credentials: {exc}"})

    return json.dumps({
        "saved": True,
        "system_id": env.system_id,
        "host": host,
        "port": port,
        "client": client,
        "user": user,
        "message": f"Credentials for {env.system_id} stored securely. Use sap_connect(system_id='{env.system_id}') to connect.",
    }, indent=2)


@mcp.tool()
def sap_delete_password(system_id: str) -> str:
    """Remove saved credentials for an SAP environment.

    Deletes both the stored configuration and the password from the OS
    credential manager.

    Args:
        system_id: Environment identifier (e.g. 'ED2').
    """
    if not system_id:
        return json.dumps({"error": True, "message": "system_id is required."})

    deleted = delete_environment(system_id.upper())
    if not deleted:
        return json.dumps({"error": True, "message": f"No saved environment found with ID '{system_id.upper()}'."})

    return json.dumps({
        "deleted": True,
        "system_id": system_id.upper(),
        "message": f"Credentials for {system_id.upper()} removed from config and OS credential manager.",
    }, indent=2)


@mcp.tool()
def sap_list_environments() -> str:
    """List all saved SAP environments (passwords are never shown).

    Returns connection details for each stored environment. Use
    sap_connect(system_id='...') to connect to any of them.
    """
    envs = list_environments()
    if not envs:
        return json.dumps({
            "environments": [],
            "message": "No saved environments. Use sap_save_password to add one.",
        }, indent=2)

    return json.dumps({
        "environments": [
            {
                "system_id": e.system_id,
                "host": e.host,
                "port": e.port,
                "client": e.client,
                "user": e.user,
                "language": e.language,
                "use_https": e.use_https,
            }
            for e in envs
        ],
    }, indent=2)


# ======================================================================
# Repository tools
# ======================================================================

@mcp.tool()
def sap_search(
    query: str,
    object_type: str = "",
    max_results: int = 50,
) -> str:
    """Search the ABAP repository for objects.

    Args:
        query: Search pattern — use * as wildcard (e.g. 'Z*', 'ZCL_MY*').
        object_type: Optional filter: PROG, CLAS, INTF, FUGR, TABL.
        max_results: Maximum number of results to return.
    """
    _, repo, *_ = _ensure_services()
    result = repo.search(query, object_type=object_type, max_results=max_results)
    objects = [
        {"name": o.name, "type": o.type, "uri": o.uri, "package": o.package_name, "description": o.description}
        for o in result.objects
    ]
    return json.dumps({"count": result.total_count, "objects": objects}, indent=2)


@mcp.tool()
def sap_browse_package(package_name: str) -> str:
    """List the contents of an ABAP package (development class).

    Args:
        package_name: Package name (e.g. 'ZPACKAGE', '$TMP').
    """
    _, repo, *_ = _ensure_services()
    nodes = repo.browse_package(package_name)
    items = [
        {"name": n.name, "type": n.type, "uri": n.uri, "description": n.description}
        for n in nodes
    ]
    return json.dumps({"package": package_name.upper(), "objects": items}, indent=2)


@mcp.tool()
def sap_object_metadata(object_uri: str) -> str:
    """Get metadata for an ABAP object by its ADT URI.

    Args:
        object_uri: ADT URI (e.g. '/sap/bc/adt/programs/programs/ztest_report').
    """
    _, repo, *_ = _ensure_services()
    obj = repo.get_object_metadata(object_uri)
    return json.dumps(asdict(obj), indent=2)


# ======================================================================
# Source code tools
# ======================================================================

@mcp.tool()
def sap_read_source(
    object_name: str,
    object_type: str = "PROG",
    version: str = "active",
    save_to: str = "",
) -> str:
    """Read the source code of an ABAP object.

    Args:
        object_name: Object name (e.g. 'ZTEST_REPORT', 'ZCL_MY_CLASS').
        object_type: PROG (program), CLAS (class), INTF (interface), FUGR (function group).
        version: 'active' or 'inactive'.
        save_to: Optional directory or file path to save the source code locally.
                 If a directory is given, the file is saved as <object_name>.abap
                 inside that directory. If a full file path is given, it is used as-is.
                 The source code is always returned in addition to being saved.

    Returns the ABAP source code as plain text.
    """
    _, _, source_svc, *_ = _ensure_services()
    code = source_svc.read_source(object_name, object_type=object_type, version=version)

    if save_to:
        try:
            from pathlib import Path
            target = Path(save_to)
            if target.is_dir() or (not target.suffix and not target.exists()):
                target.mkdir(parents=True, exist_ok=True)
                target = target / f"{object_name.lower()}.abap"
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(code, encoding="utf-8")
            return json.dumps({
                "source": code,
                "saved_to": str(target.resolve()),
            })
        except Exception as exc:
            return json.dumps({
                "source": code,
                "save_error": f"Failed to save file: {exc}",
            })

    return code


@mcp.tool()
def sap_write_source(
    object_name: str,
    source_code: str = "",
    source_file: str = "",
    object_type: str = "PROG",
    transport_request: str = "",
    activate: bool = True,
) -> str:
    """Write source code to an ABAP object, with automatic lock and optional activation.

    This tool performs the full workflow:
    1. Locks the object
    2. Checks if a transport request is needed
    3. Writes the source code
    4. Optionally activates (compiles) the object
    5. Unlocks the object

    Args:
        object_name: Object name (e.g. 'ZTEST_REPORT', 'ZCL_MY_CLASS').
        source_code: The ABAP source code to write. If empty, source_file is used.
        source_file: Path to a local file containing the ABAP source code.
                     Used when source_code is empty. Supports .abap, .txt, or any text file.
        object_type: PROG, CLAS, INTF, FUGR.
        transport_request: Transport request number (e.g. 'ED2K900001'). If empty and object
                          is not in $TMP, the tool will check for available transports.
        activate: Whether to activate (compile) after writing. Default True.
    """
    if not source_code and source_file:
        try:
            from pathlib import Path
            file_path = Path(source_file)
            if not file_path.exists():
                return json.dumps({"error": True, "message": f"File not found: {source_file}"})
            source_code = file_path.read_text(encoding="utf-8")
        except Exception as exc:
            return json.dumps({"error": True, "message": f"Failed to read file: {exc}"})

    if not source_code:
        return json.dumps({"error": True, "message": "Either source_code or source_file is required."})

    client, _, source_svc, activation_svc, transport_svc = _ensure_services()

    object_uri = resolve_object_uri(object_type, object_name)

    # Step 1: Check transport requirements
    if not transport_request:
        tr_check = transport_svc.check_transport(object_uri, object_name)
        if tr_check.locked and tr_check.locked_by_user != client.user:
            return json.dumps({
                "error": True,
                "message": f"Object is locked by user {tr_check.locked_by_user} in transport {tr_check.lock_transport}",
                "locked_by": tr_check.locked_by_user,
                "lock_transport": tr_check.lock_transport,
            })
        if tr_check.recording_transport:
            transport_request = tr_check.recording_transport
        elif tr_check.needs_transport and tr_check.available_transports:
            transport_request = tr_check.available_transports[0].number

    # Enable stateful session so the lock persists across HTTP requests
    client.begin_stateful()

    source_uri = f"{object_uri}/source/main"

    # Step 2: Lock — try source/main path first, fall back to object root.
    # Some SAP systems require the lock on the exact resource being written.
    lock_uri = object_uri
    try:
        lock_handle = client.lock(source_uri)
        lock_uri = source_uri
    except Exception:
        try:
            lock_handle = client.lock(object_uri)
            lock_uri = object_uri
        except AdtLockError as exc:
            client.end_stateful()
            return json.dumps({
                "error": True,
                "message": str(exc),
                "locked_by": exc.locked_by_user,
                "lock_transport": exc.lock_transport,
            })

    try:
        # Step 3: Write source
        params = {"lockHandle": lock_handle}
        if transport_request:
            params["corrNr"] = transport_request

        resp = client.put(
            source_uri, data=source_code,
            content_type="text/plain; charset=utf-8", accept="text/plain",
            params=params,
        )

        if resp.status_code >= 400:
            return json.dumps({
                "error": True,
                "message": f"Write failed ({resp.status_code}): {resp.text[:500]}",
            })

        result = {
            "written": True,
            "object": object_name,
            "transport": transport_request,
        }

        # Step 4: Activate
        if activate:
            act_result = activation_svc.activate(object_name, object_uri)
            result["activated"] = act_result.success
            result["messages"] = [
                {"severity": m.severity, "text": m.short_text, "line": m.line, "column": m.column}
                for m in act_result.messages
            ]
        return json.dumps(result, indent=2)
    finally:
        # Step 5: Unlock and end stateful session
        client.unlock(lock_uri, lock_handle)
        client.end_stateful()


@mcp.tool()
def sap_activate(
    object_name: str,
    object_type: str = "PROG",
    object_uri: str = "",
) -> str:
    """Activate (compile) an ABAP object.

    Args:
        object_name: Object name.
        object_type: PROG, CLAS, INTF, FUGR.
        object_uri: Optional explicit URI (overrides type/name resolution).
    """
    _, _, _, activation_svc, _ = _ensure_services()
    result = activation_svc.activate(object_name, object_uri=object_uri, object_type=object_type)
    return json.dumps({
        "success": result.success,
        "messages": [
            {"severity": m.severity, "text": m.short_text, "line": m.line, "column": m.column}
            for m in result.messages
        ],
    }, indent=2)


@mcp.tool()
def sap_syntax_check(
    object_name: str,
    object_type: str = "PROG",
) -> str:
    """Run syntax check on an ABAP object without activating.

    Args:
        object_name: Object name.
        object_type: PROG, CLAS, INTF, FUGR.
    """
    _, _, _, activation_svc, _ = _ensure_services()
    messages = activation_svc.syntax_check(object_name, object_type=object_type)
    return json.dumps([
        {"severity": m.severity, "text": m.short_text, "line": m.line, "column": m.column}
        for m in messages
    ], indent=2)


# ======================================================================
# Transport tools
# ======================================================================

@mcp.tool()
def sap_check_lock(
    object_name: str,
    object_type: str = "PROG",
) -> str:
    """Check if an ABAP object is locked, and by whom.

    Args:
        object_name: Object name.
        object_type: PROG, CLAS, INTF, FUGR.
    """
    _, _, _, _, transport_svc = _ensure_services()
    object_uri = resolve_object_uri(object_type, object_name)
    info = transport_svc.check_lock(object_uri)
    return json.dumps(info, indent=2)


@mcp.tool()
def sap_list_transports(user: str = "") -> str:
    """List open (modifiable) transport requests for a user.

    Args:
        user: SAP user name. Defaults to the connected user.
    """
    _, _, _, _, transport_svc = _ensure_services()
    transports = transport_svc.list_open_transports(user=user)
    return json.dumps([
        {
            "number": t.number,
            "description": t.description,
            "owner": t.owner,
            "status": t.status,
            "target_system": t.target_system,
            "tasks": [{"number": tk.number, "description": tk.description, "owner": tk.owner} for tk in t.tasks],
        }
        for t in transports
    ], indent=2)


@mcp.tool()
def sap_create_transport(
    description: str,
    package: str = "",
    target_system: str = "",
) -> str:
    """Create a new workbench transport request.

    Args:
        description: Short text describing the change.
        package: Target ABAP package (optional).
        target_system: Target system for transport (optional).
    """
    _, _, _, _, transport_svc = _ensure_services()
    tr = transport_svc.create_transport_request(description, package=package, target_system=target_system)
    return json.dumps({
        "number": tr.number,
        "description": tr.description,
        "owner": tr.owner,
    }, indent=2)


@mcp.tool()
def sap_release_transport(transport_number: str) -> str:
    """Release a transport request.

    Args:
        transport_number: Transport number (e.g. 'ED2K900001').
    """
    _, _, _, _, transport_svc = _ensure_services()
    transport_svc.release_transport(transport_number)
    return json.dumps({"released": True, "transport": transport_number})


@mcp.tool()
def sap_transport_check(
    object_name: str,
    object_type: str = "PROG",
) -> str:
    """Check if an object needs a transport request and which transports are available.

    Args:
        object_name: Object name.
        object_type: PROG, CLAS, INTF, FUGR.
    """
    _, _, _, _, transport_svc = _ensure_services()
    object_uri = resolve_object_uri(object_type, object_name)
    result = transport_svc.check_transport(object_uri, object_name)
    return json.dumps({
        "needs_transport": result.needs_transport,
        "locked": result.locked,
        "locked_by_user": result.locked_by_user,
        "lock_transport": result.lock_transport,
        "recording_transport": result.recording_transport,
        "available_transports": [t.number for t in result.available_transports],
    }, indent=2)


# ======================================================================
# Object creation tools
# ======================================================================

@mcp.tool()
def sap_create_program(
    name: str,
    description: str = "",
    package: str = "$TMP",
    transport_request: str = "",
) -> str:
    """Create a new ABAP program (report).

    Args:
        name: Program name (e.g. 'ZTEST_NEW_REPORT').
        description: Short description.
        package: Target package. Use '$TMP' for local/temporary.
        transport_request: Transport request number (required if package is not $TMP).
    """
    client, *_ = _ensure_services()

    body = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<program:abapProgram xmlns:program="http://www.sap.com/adt/programs/programs" '
        'xmlns:adtcore="http://www.sap.com/adt/core" '
        f'adtcore:description="{description}" '
        f'adtcore:name="{name.upper()}" '
        f'adtcore:type="PROG/P" '
        f'adtcore:language="EN">'
        f'<adtcore:packageRef adtcore:name="{package.upper()}"/>'
        "</program:abapProgram>"
    )

    headers = {}
    if transport_request:
        headers["sap-transportrequest"] = transport_request

    resp = client.post(
        "/sap/bc/adt/programs/programs",
        data=body,
        content_type="application/vnd.sap.adt.programs.programs.v2+xml",
        accept="application/xml",
        headers=headers or None,
    )

    if resp.status_code >= 400:
        return json.dumps({"error": True, "message": f"Create failed ({resp.status_code}): {resp.text[:500]}"})

    return json.dumps({"created": True, "name": name.upper(), "package": package.upper()})


@mcp.tool()
def sap_create_class(
    name: str,
    description: str = "",
    package: str = "$TMP",
    transport_request: str = "",
) -> str:
    """Create a new ABAP class.

    Args:
        name: Class name (e.g. 'ZCL_MY_NEW_CLASS').
        description: Short description.
        package: Target package.
        transport_request: Transport request number.
    """
    client, *_ = _ensure_services()

    body = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<class:abapClass xmlns:class="http://www.sap.com/adt/oo/classes" '
        'xmlns:adtcore="http://www.sap.com/adt/core" '
        f'adtcore:description="{description}" '
        f'adtcore:name="{name.upper()}" '
        f'adtcore:type="CLAS/OC" '
        f'adtcore:language="EN">'
        f'<adtcore:packageRef adtcore:name="{package.upper()}"/>'
        "</class:abapClass>"
    )

    headers = {}
    if transport_request:
        headers["sap-transportrequest"] = transport_request

    resp = client.post(
        "/sap/bc/adt/oo/classes",
        data=body,
        content_type="application/vnd.sap.adt.oo.classes.v2+xml",
        accept="application/xml",
        headers=headers or None,
    )

    if resp.status_code >= 400:
        return json.dumps({"error": True, "message": f"Create failed ({resp.status_code}): {resp.text[:500]}"})

    return json.dumps({"created": True, "name": name.upper(), "package": package.upper()})


@mcp.tool()
def sap_create_interface(
    name: str,
    description: str = "",
    package: str = "$TMP",
    transport_request: str = "",
) -> str:
    """Create a new ABAP interface.

    Args:
        name: Interface name (e.g. 'ZIF_MY_INTERFACE').
        description: Short description.
        package: Target package.
        transport_request: Transport request number.
    """
    client, *_ = _ensure_services()

    body = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<intf:abapInterface xmlns:intf="http://www.sap.com/adt/oo/interfaces" '
        'xmlns:adtcore="http://www.sap.com/adt/core" '
        f'adtcore:description="{description}" '
        f'adtcore:name="{name.upper()}" '
        f'adtcore:type="INTF/OI" '
        f'adtcore:language="EN">'
        f'<adtcore:packageRef adtcore:name="{package.upper()}"/>'
        "</intf:abapInterface>"
    )

    headers = {}
    if transport_request:
        headers["sap-transportrequest"] = transport_request

    resp = client.post(
        "/sap/bc/adt/oo/interfaces",
        data=body,
        content_type="application/vnd.sap.adt.oo.interfaces.v2+xml",
        accept="application/xml",
        headers=headers or None,
    )

    if resp.status_code >= 400:
        return json.dumps({"error": True, "message": f"Create failed ({resp.status_code}): {resp.text[:500]}"})

    return json.dumps({"created": True, "name": name.upper(), "package": package.upper()})


@mcp.tool()
def sap_delete_object(
    object_name: str,
    object_type: str = "PROG",
    transport_request: str = "",
    confirm: str = "",
) -> str:
    """Delete an ABAP object. Requires explicit confirmation.

    Args:
        object_name: Object name.
        object_type: PROG, CLAS, INTF, FUGR.
        transport_request: Transport request number (may be required).
        confirm: Must be 'DELETE' to confirm deletion.
    """
    if confirm != "DELETE":
        return json.dumps({
            "error": True,
            "message": "Deletion requires explicit confirmation. Set confirm='DELETE' to proceed.",
        })

    client, *_ = _ensure_services()
    object_uri = resolve_object_uri(object_type, object_name)

    client.begin_stateful()
    lock_handle = client.lock(object_uri)
    try:
        params = {}
        if transport_request:
            params["sap-transportrequest"] = transport_request

        headers = {"If-Match": lock_handle}
        if transport_request:
            headers["sap-transportrequest"] = transport_request

        resp = client.delete(object_uri, headers=headers, params=params or None)
        if resp.status_code >= 400:
            return json.dumps({"error": True, "message": f"Delete failed ({resp.status_code}): {resp.text[:500]}"})
        return json.dumps({"deleted": True, "object": object_name, "type": object_type})
    finally:
        try:
            client.unlock(object_uri, lock_handle)
        except Exception:
            pass
        client.end_stateful()


# ======================================================================
# Entry point
# ======================================================================

def main():
    """Run the MCP server on stdio."""
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
