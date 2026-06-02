"""
Diff generator: unified diff and two-column comparison for consultant review.
"""

from __future__ import annotations

import difflib
from typing import Iterable


def unified_diff_text(
    original: str,
    improved: str,
    from_name: str = "original",
    to_name: str = "improved",
) -> str:
    """Return a unified diff (like ``diff -u``)."""
    a = original.splitlines()
    b = improved.splitlines()
    return "".join(
        difflib.unified_diff(
            a,
            b,
            fromfile=from_name,
            tofile=to_name,
            lineterm="\n",
        )
    )


def two_column_diff(
    original: str,
    improved: str,
    width: int = 56,
    sep: str = " │ ",
) -> str:
    """
    Format *original* and *improved* in two columns for terminal display.

    Long lines are truncated. Changes are easier to spot alongside unified_diff.
    """
    left = original.splitlines()
    right = improved.splitlines()
    n = max(len(left), len(right))
    lines: list[str] = []
    header = f"{'ORIGINAL':<{width}}{sep}{'IMPROVED':<{width}}"
    lines.append(header)
    lines.append("-" * (width * 2 + len(sep)))
    for i in range(n):
        l = left[i] if i < len(left) else ""
        r = right[i] if i < len(right) else ""
        if len(l) > width:
            l = l[: width - 3] + "..."
        if len(r) > width:
            r = r[: width - 3] + "..."
        lines.append(f"{l:<{width}}{sep}{r:<{width}}")
    return "\n".join(lines)


def summarize_changes(unified: str) -> Iterable[str]:
    """Yield human-readable hints from unified diff lines."""
    for line in unified.splitlines():
        if line.startswith("+") and not line.startswith("+++"):
            yield f"addition: {line[1:].strip()[:120]}"
        elif line.startswith("-") and not line.startswith("---"):
            yield f"removal: {line[1:].strip()[:120]}"
