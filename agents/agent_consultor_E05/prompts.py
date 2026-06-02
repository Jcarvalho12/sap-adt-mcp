"""
Structured prompts for the senior SAP consultant persona (LLM or human-in-loop).

These strings are used by ``agent.py`` for section headers and optional
integration with external LLMs; SAP connectivity remains exclusively via
sap-adt-python MCP-backed tools.
"""

from __future__ import annotations

from typing import Any


SYSTEM_CONSULTANT = """You are a senior SAP technical consultant and architect with deep expertise in:
ABAP (procedural and OO), SAP UI5/Fiori, SAP HANA (SQLScript, procedures),
CDS views, calculation views, OData, RFC, enhancements, Clean Core, performance,
and SAP naming/modularization best practices.

You analyze repository objects retrieved via SAP ADT, explain findings clearly,
and propose improvements that preserve structure and reuse dependencies.
You never recommend overwriting customer objects in place without an explicit
new object name and transport discipline."""


def user_input_prompt() -> str:
    return (
        "Please provide the SAP object name and type "
        "(Program, Class, Function Module, Include, Method, Table, CDS View, OData, UI5 App, etc.)."
    )


def discovery_summary_prompt(
    object_name: str,
    object_type: str,
    metadata: dict[str, Any],
    search_snippet: str,
) -> str:
    return f"""## Object discovery

- **Name**: {object_name}
- **Type (requested)**: {object_type}
- **Metadata (ADT)**: {metadata}
- **Search context (excerpt)**: {search_snippet[:4000]}
"""


def analysis_sections_prompt() -> str:
    return """## Analysis sections (required)

### Performance
- Nested loops, SELECT in loops, missing indexes, inefficient joins, redundant DB calls.

### Clean Core
- Modifications vs extensions, reuse, hardcoding, separation of concerns.

### Code quality
- Naming, modularization, dead code, redundancy, exception handling.

### Best practices
- Modern ABAP (inline declarations, expressions), CDS vs SELECT, push-down to HANA.
"""


def approval_prompt() -> str:
    return "Do you approve these improvements? (yes/no)"


def clone_params_prompt() -> str:
    return (
        "Provide the new object name (mandatory), package (mandatory), "
        "and transport request (optional, press Enter to skip)."
    )


def final_success_prompt(
    new_name: str,
    transport: str,
    activated: bool,
) -> str:
    return f"""## Result

- Object created: **{new_name}**
- Improvements applied to the new object only (dependencies unchanged)
- Transport: **{transport or '(none / $TMP)'}**
- Activated: **{activated}**
"""


def format_findings_markdown(findings_by_category: dict[str, list[Any]]) -> str:
    """Render categorized findings as markdown."""
    parts: list[str] = ["## Improvements (categorized)\n"]
    for cat, items in findings_by_category.items():
        parts.append(f"### {cat}\n")
        for f in items:
            title = getattr(f, "title", str(f))
            detail = getattr(f, "detail", "")
            parts.append(f"- **{title}**: {detail}\n")
    return "".join(parts)
