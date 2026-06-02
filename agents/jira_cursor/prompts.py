"""
prompts.py — Templates de prompt e formatação do relatório de análise.
"""

from __future__ import annotations

from typing import Any

from analyzer import AnalysisResult, TimelineEvent, _format_ts
from attachment_analyzer import AttachmentContent


SYSTEM_ANALYST = """Você é um analista técnico sênior especializado em suporte e troubleshooting.
Sua função é analisar chamados do Jira, entender o histórico completo do problema,
identificar padrões e sugerir onde pode estar a causa raiz.

Diretrizes:
- Seja objetivo e direto
- Organize as informações de forma clara
- Destaque os pontos mais críticos
- Sugira próximos passos acionáveis
- Use linguagem técnica mas acessível
"""


def format_analysis_report(result: AnalysisResult) -> str:
    """Formata o resultado da análise como relatório Markdown."""
    lines: list[str] = []

    # Cabeçalho
    lines.append(f"# 📋 Análise do Chamado {result.issue_key}")
    lines.append("")
    lines.append(f"**Resumo:** {result.summary}")
    lines.append(f"**Tipo:** {result.issue_type} | **Status:** {result.status} | **Prioridade:** {result.priority}")
    lines.append("")

    # Métricas rápidas
    lines.append("## 📊 Métricas")
    lines.append("")
    lines.append(f"| Métrica | Valor |")
    lines.append(f"|---------|-------|")
    lines.append(f"| Dias aberto | {result.days_open} |")
    lines.append(f"| Comentários | {result.total_comments} |")
    lines.append(f"| Transições | {result.total_transitions} |")
    lines.append(f"| Reaberturas | {result.reopened_count} |")
    lines.append(f"| Mudanças de responsável | {result.assignee_changes} |")
    lines.append(f"| Participantes únicos | {len(result.unique_participants)} |")
    lines.append("")

    # Participantes
    if result.unique_participants:
        lines.append("**Envolvidos:** " + ", ".join(result.unique_participants))
        lines.append("")

    # Padrões identificados
    if result.patterns:
        lines.append("## 🔍 Padrões Identificados")
        lines.append("")
        for p in result.patterns:
            lines.append(f"- {p}")
        lines.append("")

    # Pontos-chave
    if result.key_points:
        lines.append("## 📌 Pontos-Chave do Histórico")
        lines.append("")
        for point in result.key_points:
            lines.append(f"- {point}")
        lines.append("")

    # Sugestão de causa raiz
    if result.root_cause_hints:
        lines.append("## 🎯 Possíveis Causas / Onde Investigar")
        lines.append("")
        for i, hint in enumerate(result.root_cause_hints, 1):
            lines.append(f"{i}. {hint}")
        lines.append("")

    # Próximos passos
    if result.next_steps:
        lines.append("## ✅ Próximos Passos Sugeridos")
        lines.append("")
        for i, step in enumerate(result.next_steps, 1):
            lines.append(f"{i}. {step}")
        lines.append("")

    # Issues relacionadas
    if result.related_issues:
        lines.append("## 🔗 Issues Relacionadas")
        lines.append("")
        for ri in result.related_issues:
            status_badge = f" [{ri['status']}]" if ri.get("status") else ""
            lines.append(f"- **{ri['key']}**{status_badge}: {ri.get('summary', '')}")
        lines.append("")

    # Anexos
    if result.attachments_summary:
        lines.append("## 📎 Anexos")
        lines.append("")
        for att in result.attachments_summary:
            lines.append(f"- {att}")
        lines.append("")

    # Conteúdo analisado dos anexos
    if result.attachment_analysis and result.attachment_analysis.analyzed_count > 0:
        lines.append("## 🔬 Análise de Conteúdo dos Anexos")
        lines.append("")
        lines.append(
            f"*{result.attachment_analysis.analyzed_count} de "
            f"{result.attachment_analysis.total_attachments} anexos analisados com sucesso*"
        )
        lines.append("")

        if result.attachment_analysis.key_findings:
            lines.append("### Descobertas nos Anexos")
            lines.append("")
            for finding in result.attachment_analysis.key_findings:
                lines.append(f"- {finding}")
            lines.append("")

        if result.attachment_insights:
            lines.append("### Resumo do Conteúdo")
            lines.append("")
            for insight in result.attachment_insights:
                lines.append(f"- {insight}")
            lines.append("")

        # Exibir trechos relevantes do conteúdo extraído
        has_detailed_content = False
        for content in result.attachment_analysis.contents:
            if content.extraction_success and content.extracted_text:
                if not has_detailed_content:
                    lines.append("### Conteúdo Extraído (trechos relevantes)")
                    lines.append("")
                    has_detailed_content = True
                lines.append(f"#### 📄 {content.filename}")
                lines.append(f"*Método: {content.extraction_method} | Tamanho: {content.size_bytes // 1024}KB*")
                lines.append("")
                preview = _get_relevant_preview(content.extracted_text)
                lines.append("```")
                lines.append(preview)
                lines.append("```")
                lines.append("")

        if has_detailed_content:
            lines.append("")

    # Cronologia resumida (últimos 20 eventos)
    if result.timeline:
        lines.append("## 📅 Cronologia (últimos eventos)")
        lines.append("")
        recent = result.timeline[-20:]
        for event in recent:
            ts = _format_ts(event.timestamp)
            icon = _event_icon(event.category)
            lines.append(f"- `{ts}` {icon} **{event.actor}** — {event.description}")
        if len(result.timeline) > 20:
            lines.append(f"- *(... {len(result.timeline) - 20} eventos anteriores omitidos)*")
        lines.append("")

    lines.append("---")
    lines.append("*Relatório gerado pelo agente jira_cursor*")

    return "\n".join(lines)


def format_compact_summary(result: AnalysisResult) -> str:
    """Versão compacta do relatório para visualização rápida."""
    lines: list[str] = []

    lines.append(f"[{result.issue_key}] {result.summary}")
    lines.append(f"Status: {result.status} | Prioridade: {result.priority} | Aberto há {result.days_open} dias")
    lines.append("")

    if result.patterns:
        lines.append("Padrões:")
        for p in result.patterns:
            lines.append(f"  {p}")
        lines.append("")

    if result.root_cause_hints:
        lines.append("Possíveis causas:")
        for h in result.root_cause_hints:
            lines.append(f"  → {h}")

    return "\n".join(lines)


def _event_icon(category: str) -> str:
    icons = {
        "creation": "🆕",
        "status_change": "🔄",
        "assignment": "👤",
        "priority": "⬆️",
        "comment": "💬",
        "attachment": "📎",
        "link": "🔗",
    }
    return icons.get(category, "•")


def _get_relevant_preview(text: str, max_lines: int = 40, max_chars: int = 3000) -> str:
    """
    Extrai um preview relevante do texto, priorizando linhas com
    informações de erro, regras de negócio e dados técnicos.
    """
    lines = text.split("\n")

    priority_keywords = [
        "erro", "error", "exception", "falha", "fail", "dump",
        "causa", "cause", "solução", "solution", "workaround",
        "requisito", "requirement", "regra", "rule", "validação",
        "campo", "field", "tabela", "table", "transação", "transaction",
        "message", "mensagem", "status", "retorno", "return",
        "sy-subrc", "sy-msgty", "bapi", "function module",
    ]

    priority_lines = []
    context_lines = []

    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped:
            continue
        if any(kw in stripped.lower() for kw in priority_keywords):
            start = max(0, i - 1)
            end = min(len(lines), i + 2)
            for j in range(start, end):
                if lines[j].strip() and lines[j] not in priority_lines:
                    priority_lines.append(lines[j])
        elif len(stripped) > 10:
            context_lines.append(line)

    result_lines = priority_lines[:max_lines]
    remaining = max_lines - len(result_lines)
    if remaining > 0 and context_lines:
        result_lines.extend(context_lines[:remaining])

    if not result_lines:
        result_lines = [ln for ln in lines if ln.strip()][:max_lines]

    preview = "\n".join(result_lines)
    if len(preview) > max_chars:
        preview = preview[:max_chars] + "\n... (conteúdo truncado)"
    elif len(lines) > max_lines:
        preview += f"\n... ({len(lines) - max_lines} linhas adicionais omitidas)"

    return preview
