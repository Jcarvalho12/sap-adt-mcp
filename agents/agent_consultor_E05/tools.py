"""
MCP integration abstraction for agent_consultor_E05.

Imports the same ``sap_adt.mcp_server`` module as ``sap-adt-python/scripts/run_mcp.py``.
Todas as ferramentas expostas pelo servidor MCP estão registadas aqui, alinhadas
**estritamente** com ``sap-adt-python/docs/MCP_COMMAND_REFERENCE.md``.

Somente as 21 ferramentas documentadas no MCP são expostas; nenhum parâmetro
extra (não documentado) é utilizado.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from types import ModuleType
from typing import Any, Callable

# Ordem lógica (grupos como na referência MCP):
#   §1 Conexão e credenciais
#   §2 Repositório ABAP
#   §3 Código-fonte
#   §4 Gerenciamento de transports
#   §5 Criação e exclusão de objetos
ALL_MCP_TOOL_NAMES: tuple[str, ...] = (
    # §1 Conexão e credenciais
    "sap_save_password",
    "sap_connect",
    "sap_discovery",
    "sap_list_environments",
    "sap_delete_password",
    # §2 Repositório ABAP
    "sap_search",
    "sap_browse_package",
    "sap_object_metadata",
    # §3 Código-fonte
    "sap_read_source",
    "sap_write_source",
    "sap_activate",
    "sap_syntax_check",
    # §4 Gerenciamento de transports
    "sap_check_lock",
    "sap_list_transports",
    "sap_create_transport",
    "sap_release_transport",
    "sap_transport_check",
    # §5 Criação e exclusão
    "sap_create_program",
    "sap_create_class",
    "sap_create_interface",
    "sap_delete_object",
)


def _load_sap_mcp_server(src_root: Path) -> ModuleType:
    """Load ``sap_adt.mcp_server`` from *src_root* (sap-adt-python/src)."""
    src_root = src_root.resolve()
    if str(src_root) not in sys.path:
        sys.path.insert(0, str(src_root))

    try:
        import sap_adt.mcp_server as mod
    except ImportError as exc:
        hint = (
            "Instale as dependências do sap-adt-python (mcp, requests, keyring, lxml) ou use: "
            "..\\..\\sap-adt-python\\.venv\\Scripts\\python.exe agent.py"
        )
        raise ImportError(
            f"Cannot import sap_adt.mcp_server from {src_root}. "
            f"Underlying error: {exc!s}. {hint}"
        ) from exc
    return mod


def _maybe_parse_json(value: str) -> Any:
    s = value.strip()
    if s.startswith("{") or s.startswith("["):
        try:
            return json.loads(s)
        except json.JSONDecodeError:
            pass
    return value


@dataclass
class SapToolResult:
    """Normalized result from a tool that may return plain text or JSON."""

    raw: str
    data: Any

    @property
    def as_str(self) -> str:
        if isinstance(self.data, str):
            return self.data
        if isinstance(self.data, dict) and "source" in self.data:
            return str(self.data["source"])
        return self.raw


class SapMcpTools:
    """
    Fachada sobre as funções ``@mcp.tool()`` de ``sap_adt.mcp_server``.

    Expõe **somente** as 21 ferramentas documentadas em
    ``sap-adt-python/docs/MCP_COMMAND_REFERENCE.md``, com **somente** os
    parâmetros documentados.

    Cada ``sap_*`` está disponível como atributo chamável,
    por exemplo ``tools.sap_search(query="Z*", object_type="PROG")``.
    Use também :meth:`call` com o nome da ferramenta em string.
    """

    def __init__(self, sap_adt_src: Path):
        self._src = Path(sap_adt_src)
        self._mcp: ModuleType = _load_sap_mcp_server(self._src)
        self._fns: dict[str, Callable[..., str]] = {}
        for name in ALL_MCP_TOOL_NAMES:
            fn = getattr(self._mcp, name, None)
            if callable(fn):
                self._fns[name] = fn

    @property
    def registered_tools(self) -> frozenset[str]:
        return frozenset(self._fns.keys())

    def call(self, tool_name: str, **kwargs: Any) -> SapToolResult:
        """Invoca uma ferramenta MCP pelo nome (deve existir em ``registered_tools``)."""
        if tool_name not in self._fns:
            raise ValueError(
                f"Unknown or unavailable tool: {tool_name}. "
                f"Registered: {sorted(self._fns.keys())}"
            )
        raw = self._fns[tool_name](**kwargs)
        parsed = _maybe_parse_json(raw)
        return SapToolResult(raw=raw, data=parsed)

    def __getattr__(self, name: str) -> Any:
        if name in self._fns:

            def bound(**kwargs: Any) -> SapToolResult:
                return self.call(name, **kwargs)

            bound.__doc__ = (
                f"MCP tool `{name}` — see sap-adt-python/docs/MCP_COMMAND_REFERENCE.md"
            )
            return bound
        raise AttributeError(f"{type(self).__name__!s} has no MCP tool {name!r}")


def read_source_text(result: SapToolResult) -> str:
    """Extract ABAP source text from ``sap_read_source`` output."""
    if isinstance(result.data, dict) and "source" in result.data:
        return str(result.data["source"])
    if isinstance(result.data, str):
        return result.data
    return result.raw
