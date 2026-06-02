"""
Code analysis engine for ABAP (and generic SAP artifact hints).

Uses deterministic heuristics (regex + line scanning) suitable for CI-style
checks. Pair with ``prompts.py`` for LLM narrative; this module returns
structured findings the agent can render and categorize.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum
from typing import Iterable


class FindingCategory(str, Enum):
    PERFORMANCE = "Performance"
    CLEAN_CORE = "Clean Core"
    READABILITY = "Readability"
    MAINTAINABILITY = "Maintainability"
    BEST_PRACTICE = "Best Practice"


@dataclass
class Finding:
    category: FindingCategory
    title: str
    detail: str
    line_hint: int = 0
    severity: str = "warning"  # info | warning | error


@dataclass
class DependencyMap:
    main_object: str
    type: str
    includes: list[str] = field(default_factory=list)
    classes: list[str] = field(default_factory=list)
    methods: list[str] = field(default_factory=list)
    function_modules: list[str] = field(default_factory=list)
    tables: list[str] = field(default_factory=list)
    external_dependencies: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "main_object": self.main_object,
            "type": self.type,
            "includes": sorted(set(self.includes)),
            "classes": sorted(set(self.classes)),
            "methods": sorted(set(self.methods)),
            "function_modules": sorted(set(self.function_modules)),
            "tables": sorted(set(self.tables)),
            "external_dependencies": sorted(set(self.external_dependencies)),
        }


_RE_INCLUDE = re.compile(
    r"^\s*INCLUDE\s+([a-zA-Z0-9_/]+)",
    re.IGNORECASE | re.MULTILINE,
)
_RE_CALL_FUNCTION = re.compile(
    r"CALL\s+FUNCTION\s+['\"]([A-Z0-9_/]+)['\"]",
    re.IGNORECASE,
)
_RE_CLASS_REF = re.compile(
    r"\b(ZCL_[A-Z0-9_]+|CL_[A-Z0-9_]+)\b",
    re.IGNORECASE,
)
_RE_INTF_REF = re.compile(r"\b(ZIF_[A-Z0-9_]+|IF_[A-Z0-9_]+)\b", re.IGNORECASE)
_RE_LOOP = re.compile(r"^\s*LOOP\s+", re.IGNORECASE | re.MULTILINE)
_RE_SELECT_IN_LOOP = re.compile(
    r"LOOP[\s\S]{0,2000}?\bSELECT\b",
    re.IGNORECASE,
)
_RE_FOR_ALL = re.compile(r"FOR\s+ALL\s+ENTRIES\s+IN", re.IGNORECASE)
_RE_MODIFY_STD = re.compile(
    r"\bMODIFY\s+(MARA|MARC|MARD|VBAK|VBAP|BKPF|BSEG)\b",
    re.IGNORECASE,
)
_RE_AUTHORITY_CHECK = re.compile(r"AUTHORITY-CHECK\s+", re.IGNORECASE)
_RE_MESSAGE = re.compile(r"\bMESSAGE\s+", re.IGNORECASE)
_RE_HARDCODE_CLIENT = re.compile(r"['\"]500['\"]", re.IGNORECASE)


def extract_dependencies(source: str, main_name: str, object_type: str) -> DependencyMap:
    """Parse ABAP source for cross-object references."""
    dm = DependencyMap(main_object=main_name.upper(), type=object_type.upper())

    for m in _RE_INCLUDE.finditer(source):
        name = m.group(1).strip().upper()
        if name and name != main_name.upper():
            dm.includes.append(name)

    for m in _RE_CALL_FUNCTION.finditer(source):
        dm.function_modules.append(m.group(1).upper())

    for m in _RE_CLASS_REF.finditer(source):
        dm.classes.append(m.group(1).upper())

    for m in _RE_INTF_REF.finditer(source):
        dm.external_dependencies.append(m.group(1).upper())

    # TABLES / DATA declarations referencing Z/Y tables
    for line in source.splitlines():
        u = line.upper()
        if "TABLES " in u or "TYPE TABLE OF " in u or "REF TO " in u:
            for tok in re.findall(r"\b(Z[A-Z0-9_]{3,}|Y[A-Z0-9_]{3,})\b", line.upper()):
                if not tok.startswith("ZCL_") and not tok.startswith("ZIF_"):
                    dm.tables.append(tok)

    # METHOD names (very rough)
    for m in re.finditer(r"^\s*METHOD\s+(\w+)", source, re.IGNORECASE | re.MULTILINE):
        dm.methods.append(m.group(1).upper())

    return dm


def _lines(source: str) -> list[str]:
    return source.splitlines()


def analyze_abap(source: str, object_name: str, object_type: str) -> list[Finding]:
    """Run heuristic analysis; returns categorized findings."""
    findings: list[Finding] = []
    lines = _lines(source)
    line_count = len(lines)

    # Nested LOOP depth (simple brace-less block heuristic)
    loop_depth = 0
    max_depth = 0
    for i, line in enumerate(lines, start=1):
        stripped = line.strip().upper()
        if stripped.startswith("LOOP ") or stripped.startswith("LOOP AT"):
            loop_depth += 1
            max_depth = max(max_depth, loop_depth)
        elif stripped == "ENDLOOP.":
            loop_depth = max(0, loop_depth - 1)
    if max_depth >= 3:
        findings.append(
            Finding(
                category=FindingCategory.PERFORMANCE,
                title="Deeply nested LOOP blocks",
                detail=f"Maximum LOOP nesting observed: {max_depth}. Consider extracting loops or using internal tables / FOR expressions.",
                line_hint=0,
                severity="warning",
            )
        )

    if _RE_SELECT_IN_LOOP.search(source):
        findings.append(
            Finding(
                category=FindingCategory.PERFORMANCE,
                title="SELECT inside LOOP (heuristic)",
                detail="A SELECT appears shortly after a LOOP in the source. Review for row-by-row DB access; prefer bulk reads, JOINs, or CDS.",
                severity="error",
            )
        )

    if _RE_FOR_ALL.search(source):
        findings.append(
            Finding(
                category=FindingCategory.PERFORMANCE,
                title="FOR ALL ENTRIES usage",
                detail="Ensure key fields are populated and consider CDS/CTE alternatives where appropriate.",
                severity="info",
            )
        )

    if _RE_MODIFY_STD.search(source):
        findings.append(
            Finding(
                category=FindingCategory.CLEAN_CORE,
                title="Direct modification of standard tables",
                detail="Updates to SAP standard tables may conflict with Clean Core. Prefer released APIs, BAPIs, or Idoc/BTE exits.",
                severity="warning",
            )
        )

    if not _RE_AUTHORITY_CHECK.search(source) and line_count > 40:
        findings.append(
            Finding(
                category=FindingCategory.CLEAN_CORE,
                title="No AUTHORITY-CHECK detected",
                detail="Long program without explicit AUTHORITY-CHECK. Verify authorization concept for sensitive transactions/data.",
                severity="info",
            )
        )

    if _RE_HARDCODE_CLIENT.search(source):
        findings.append(
            Finding(
                category=FindingCategory.CLEAN_CORE,
                title="Possible hard-coded client",
                detail="Literal '500' found; externalize configuration or use SY-MANDT context appropriately.",
                severity="warning",
            )
        )

    # Readability: very long methods / report
    if line_count > 600:
        findings.append(
            Finding(
                category=FindingCategory.READABILITY,
                title="Large source unit",
                detail=f"Source has {line_count} lines. Consider splitting includes, extracting classes, or local subroutines.",
                severity="info",
            )
        )

    # Maintainability: MESSAGE usage without structured handling
    msg_count = len(_RE_MESSAGE.findall(source))
    if msg_count > 50:
        findings.append(
            Finding(
                category=FindingCategory.MAINTAINABILITY,
                title="High volume of MESSAGE statements",
                detail="Consider centralizing user messages (message classes) and error handling.",
                severity="info",
            )
        )

    # Best practices: inline DATA() available in modern ABAP
    if "DATA(" not in source and line_count > 80 and object_type.upper() in ("PROG", "CLAS"):
        findings.append(
            Finding(
                category=FindingCategory.BEST_PRACTICE,
                title="Limited use of inline declarations",
                detail="Consider inline DATA() / FIELD-SYMBOL() declarations where readability improves (7.40+).",
                severity="info",
            )
        )

    # Redundant dead code hint
    if re.search(r"^\s*\*\s*TODO\s*:\s*remove", source, re.IGNORECASE | re.MULTILINE):
        findings.append(
            Finding(
                category=FindingCategory.MAINTAINABILITY,
                title="Stale TODO markers",
                detail="Comments indicate removable code; prune dead paths.",
                severity="info",
            )
        )

    return findings


def categorize_findings(findings: Iterable[Finding]) -> dict[str, list[Finding]]:
    buckets: dict[str, list[Finding]] = {
        FindingCategory.PERFORMANCE.value: [],
        FindingCategory.CLEAN_CORE.value: [],
        FindingCategory.READABILITY.value: [],
        FindingCategory.MAINTAINABILITY.value: [],
        FindingCategory.BEST_PRACTICE.value: [],
    }
    for f in findings:
        key = f.category.value
        if key not in buckets:
            buckets[key] = []
        buckets[key].append(f)
    return {k: v for k, v in buckets.items() if v}


def suggest_improved_snippet(source: str, findings: list[Finding]) -> str:
    """
    Produce a conservative improved copy of *source* for demo/diff purposes.

    This is **not** a full refactor engine; it applies small safe edits so the
    pipeline can show a two-column diff. Real projects should replace/extend
    this with LLM-generated code after review.
    """
    out = source
    # Example safe insertion: pragma or comment header if performance issues
    perf = [f for f in findings if f.category == FindingCategory.PERFORMANCE]
    if perf and "* consultant review:" not in out.lower():
        header = (
            '* consultant review: performance hotspots flagged — verify DB access pattern\n'
        )
        if out.lstrip().upper().startswith("*&"):
            lines = out.splitlines()
            insert_at = 1 if len(lines) > 1 else 0
            lines.insert(insert_at, header.rstrip())
            out = "\n".join(lines)
        else:
            out = header + out
    return out
