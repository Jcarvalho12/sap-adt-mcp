"""
analyzer.py — Motor de análise de chamados Jira.

Processa o histórico completo de um issue (comentários, transições, anexos,
links) e gera um relatório estruturado com:
  - Resumo executivo
  - Cronologia dos eventos relevantes
  - Padrões identificados (bounce-back, SLA, escalação)
  - Sugestão de causa raiz e próximos passos
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

from jira_client import JiraIssueData
from attachment_analyzer import AttachmentAnalysisResult


@dataclass
class TimelineEvent:
    """Evento na cronologia do chamado."""

    timestamp: str
    category: str  # comment, status_change, assignment, priority, attachment, link
    actor: str
    description: str


@dataclass
class AnalysisResult:
    """Resultado completo da análise de um chamado."""

    issue_key: str
    summary: str
    status: str
    priority: str
    issue_type: str

    # Cronologia
    timeline: list[TimelineEvent] = field(default_factory=list)

    # Métricas
    total_comments: int = 0
    total_transitions: int = 0
    days_open: int = 0
    reopened_count: int = 0
    assignee_changes: int = 0
    unique_participants: list[str] = field(default_factory=list)

    # Padrões identificados
    patterns: list[str] = field(default_factory=list)

    # Pontos-chave extraídos dos comentários
    key_points: list[str] = field(default_factory=list)

    # Sugestões
    root_cause_hints: list[str] = field(default_factory=list)
    next_steps: list[str] = field(default_factory=list)

    # Informações complementares
    related_issues: list[dict[str, str]] = field(default_factory=list)
    attachments_summary: list[str] = field(default_factory=list)

    # Análise de conteúdo dos anexos
    attachment_analysis: AttachmentAnalysisResult | None = None
    attachment_insights: list[str] = field(default_factory=list)


def _parse_date(date_str: str) -> datetime | None:
    if not date_str:
        return None
    for fmt in (
        "%Y-%m-%dT%H:%M:%S.%f%z",
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%S.%f",
        "%Y-%m-%dT%H:%M:%S",
    ):
        try:
            return datetime.strptime(date_str[:26].replace("+", "+"), fmt)
        except (ValueError, IndexError):
            continue
    try:
        return datetime.fromisoformat(date_str.replace("Z", "+00:00"))
    except Exception:
        return None


def _days_between(start: str, end: str | None = None) -> int:
    d1 = _parse_date(start)
    if not d1:
        return 0
    if end:
        d2 = _parse_date(end)
    else:
        d2 = datetime.now(d1.tzinfo) if d1.tzinfo else datetime.now()
    if not d2:
        return 0
    return max(0, (d2 - d1).days)


def _format_ts(date_str: str) -> str:
    dt = _parse_date(date_str)
    if not dt:
        return date_str[:19] if len(date_str) > 19 else date_str
    return dt.strftime("%d/%m/%Y %H:%M")


def build_timeline(issue: JiraIssueData) -> list[TimelineEvent]:
    """Constrói a cronologia completa do chamado a partir de transições e comentários."""
    events: list[TimelineEvent] = []

    # Evento de criação
    events.append(TimelineEvent(
        timestamp=issue.created,
        category="creation",
        actor=issue.reporter,
        description=f"Chamado criado: {issue.summary}",
    ))

    # Transições (changelog)
    for t in issue.transitions:
        cat = "status_change"
        desc = f"{t['field']}: {t.get('from', '?')} → {t.get('to', '?')}"
        if t["field"].lower() == "status":
            cat = "status_change"
            desc = f"Status alterado: {t.get('from', '?')} → {t.get('to', '?')}"
        elif t["field"].lower() == "assignee":
            cat = "assignment"
            desc = f"Responsável alterado: {t.get('from', '?')} → {t.get('to', '?')}"
        elif t["field"].lower() == "priority":
            cat = "priority"
            desc = f"Prioridade alterada: {t.get('from', '?')} → {t.get('to', '?')}"
        events.append(TimelineEvent(
            timestamp=t.get("created", ""),
            category=cat,
            actor=t.get("author", "Sistema"),
            description=desc,
        ))

    # Comentários
    for c in issue.comments:
        body_preview = c.get("body", "")[:200]
        if len(c.get("body", "")) > 200:
            body_preview += "..."
        events.append(TimelineEvent(
            timestamp=c.get("created", ""),
            category="comment",
            actor=c.get("author", "Desconhecido"),
            description=body_preview,
        ))

    # Anexos
    for a in issue.attachments:
        events.append(TimelineEvent(
            timestamp=a.get("created", ""),
            category="attachment",
            actor=a.get("author", "Desconhecido"),
            description=f"Anexo adicionado: {a.get('filename', '?')}",
        ))

    # Ordenar por timestamp
    events.sort(key=lambda e: e.timestamp or "")
    return events


def detect_patterns(issue: JiraIssueData, timeline: list[TimelineEvent]) -> list[str]:
    """Detecta padrões problemáticos no histórico do chamado."""
    patterns: list[str] = []

    # Bounce-back (reabertura)
    status_changes = [t for t in issue.transitions if t.get("field", "").lower() == "status"]
    reopen_count = sum(
        1
        for t in status_changes
        if any(
            kw in (t.get("to") or "").lower()
            for kw in ("reaberto", "reopened", "open", "aberto", "to do", "backlog")
        )
        and any(
            kw in (t.get("from") or "").lower()
            for kw in ("resolvido", "resolved", "done", "fechado", "closed", "in review")
        )
    )
    if reopen_count > 0:
        patterns.append(
            f"🔄 Chamado reaberto {reopen_count}x — indica resolução incompleta ou recorrência do problema"
        )

    # Múltiplas reatribuições
    assignee_changes = [t for t in issue.transitions if t.get("field", "").lower() == "assignee"]
    if len(assignee_changes) >= 3:
        patterns.append(
            f"👥 {len(assignee_changes)} mudanças de responsável — possível falta de ownership ou escopo mal definido"
        )

    # Tempo sem atividade (gaps longos)
    if len(timeline) >= 2:
        max_gap_days = 0
        gap_period = ""
        for i in range(1, len(timeline)):
            d1 = _parse_date(timeline[i - 1].timestamp)
            d2 = _parse_date(timeline[i].timestamp)
            if d1 and d2:
                gap = (d2 - d1).days
                if gap > max_gap_days:
                    max_gap_days = gap
                    gap_period = f"{_format_ts(timeline[i-1].timestamp)} → {_format_ts(timeline[i].timestamp)}"
        if max_gap_days > 7:
            patterns.append(
                f"⏳ Maior gap de inatividade: {max_gap_days} dias ({gap_period})"
            )

    # Escalação de prioridade
    priority_ups = [
        t for t in issue.transitions
        if t.get("field", "").lower() == "priority"
        and _priority_rank(t.get("to", "")) > _priority_rank(t.get("from", ""))
    ]
    if priority_ups:
        patterns.append(
            f"⬆️ Prioridade escalada {len(priority_ups)}x — gravidade do problema pode ter aumentado"
        )

    # Muitos comentários (discussão prolongada)
    if len(issue.comments) > 15:
        patterns.append(
            f"💬 {len(issue.comments)} comentários — discussão extensa pode indicar ambiguidade no problema"
        )

    # Chamado aberto há muito tempo
    days = _days_between(issue.created, issue.resolved or None)
    if days > 30 and not issue.resolved:
        patterns.append(f"📅 Chamado aberto há {days} dias sem resolução")

    return patterns


def _priority_rank(priority_name: str) -> int:
    ranks = {
        "highest": 5, "blocker": 5, "crítica": 5,
        "high": 4, "alta": 4,
        "medium": 3, "média": 3, "normal": 3,
        "low": 2, "baixa": 2,
        "lowest": 1, "trivial": 1,
    }
    return ranks.get((priority_name or "").lower().strip(), 0)


def extract_key_points(
    issue: JiraIssueData,
    attachment_analysis: AttachmentAnalysisResult | None = None,
) -> list[str]:
    """
    Extrai os pontos-chave dos comentários, descrição e anexos do chamado.
    Foca em: erros reportados, ações tomadas, conclusões parciais.
    """
    points: list[str] = []

    # Da descrição
    if issue.description:
        desc_lines = issue.description.strip().split("\n")
        meaningful = [ln.strip() for ln in desc_lines if len(ln.strip()) > 20]
        if meaningful:
            points.append(f"[Descrição] {meaningful[0]}")
            if len(meaningful) > 1:
                points.append(f"[Descrição] {meaningful[1]}")

    # Dos comentários (extrair os mais relevantes)
    error_keywords = [
        "erro", "error", "falha", "fail", "exception", "dump", "crash",
        "timeout", "não funciona", "problema", "bug", "issue", "causa",
        "solução", "workaround", "fix", "resolvido", "resolved",
        "identificado", "encontrado", "root cause", "causa raiz",
    ]

    for c in issue.comments:
        body = c.get("body", "").lower()
        if any(kw in body for kw in error_keywords):
            first_line = c.get("body", "").strip().split("\n")[0][:150]
            author = c.get("author", "?")
            ts = _format_ts(c.get("created", ""))
            points.append(f"[{ts} - {author}] {first_line}")

    # Dos anexos analisados
    if attachment_analysis and attachment_analysis.key_findings:
        for finding in attachment_analysis.key_findings[:5]:
            points.append(f"[Anexo] {finding}")

    # Limitar a 20 pontos mais relevantes
    return points[:20]


def suggest_root_cause(
    issue: JiraIssueData,
    patterns: list[str],
    attachment_analysis: AttachmentAnalysisResult | None = None,
) -> list[str]:
    """Gera sugestões de possível causa raiz baseado nos dados coletados e anexos."""
    hints: list[str] = []

    # Análise baseada em keywords na descrição, comentários E conteúdo dos anexos
    attachment_text = ""
    if attachment_analysis and attachment_analysis.combined_text:
        attachment_text = attachment_analysis.combined_text

    all_text = (issue.description + " " + " ".join(
        c.get("body", "") for c in issue.comments
    ) + " " + attachment_text).lower()

    if any(kw in all_text for kw in ("timeout", "lentidão", "slow", "performance", "demora")):
        hints.append(
            "Possível problema de performance/timeout — verificar queries, locks de banco, "
            "recursos de servidor ou conexões de rede"
        )

    if any(kw in all_text for kw in ("dump", "short dump", "exception", "abend")):
        hints.append(
            "Dump/Exception reportado — analisar stack trace, verificar dados de entrada "
            "e condições de contorno no código"
        )

    if any(kw in all_text for kw in ("permissão", "autorização", "authorization", "forbidden", "403")):
        hints.append(
            "Possível problema de permissão/autorização — verificar roles, profiles "
            "e objetos de autorização do usuário"
        )

    if any(kw in all_text for kw in ("integração", "integration", "rfc", "idoc", "api", "webservice")):
        hints.append(
            "Problema pode estar na integração entre sistemas — verificar conectividade, "
            "mapeamento de dados e logs de comunicação"
        )

    if any(kw in all_text for kw in ("dados", "data", "inconsist", "cadastro", "registro")):
        hints.append(
            "Possível inconsistência de dados — verificar integridade dos registros, "
            "regras de validação e dependências entre tabelas"
        )

    if any(kw in all_text for kw in ("nota", "note", "oss", "sap note", "patch", "hotfix")):
        hints.append(
            "Referência a SAP Notes/patches — verificar se a correção oficial foi aplicada "
            "corretamente e se há pré-requisitos pendentes"
        )

    if any(kw in all_text for kw in ("transport", "tr ", "request", "ordem")):
        hints.append(
            "Menção a transportes — verificar se todas as ordens de transporte necessárias "
            "foram importadas no ambiente correto e na sequência adequada"
        )

    if any(kw in all_text for kw in ("customizing", "spro", "configuração", "config", "parâmetro")):
        hints.append(
            "Possível problema de customizing/configuração — verificar parâmetros no SPRO "
            "e tabelas de configuração relevantes"
        )

    if any(kw in all_text for kw in ("job", "batch", "sm37", "agendamento", "schedule")):
        hints.append(
            "Referência a jobs/processamento batch — verificar logs do job (SM37), "
            "parâmetros de execução e locks de recursos"
        )

    if any(kw in all_text for kw in ("workflow", "swi1", "aprovação", "liberação")):
        hints.append(
            "Problema relacionado a workflow — verificar status do workflow (SWI1), "
            "agentes responsáveis e regras de determinação"
        )

    # Insights específicos dos anexos (EFs, dumps, screenshots)
    if attachment_analysis and attachment_analysis.key_findings:
        ef_findings = [f for f in attachment_analysis.key_findings if "Especificação Funcional" in f]
        if ef_findings:
            hints.append(
                "EF (Especificação Funcional) anexada — verificar se a implementação "
                "está aderente aos requisitos e regras de negócio documentados na especificação"
            )

        error_findings = [f for f in attachment_analysis.key_findings if "erro" in f.lower() or "error" in f.lower()]
        if error_findings:
            hints.append(
                "Anexos contêm evidências de erro — analisar mensagens de erro, "
                "stack traces e dumps nos arquivos anexados para identificar ponto de falha exato"
            )

    if not hints:
        hints.append(
            "Não foi possível identificar padrão claro — recomenda-se revisão manual "
            "detalhada dos comentários, anexos e reprodução do cenário reportado"
        )

    return hints


def suggest_next_steps(
    issue: JiraIssueData, patterns: list[str], root_cause_hints: list[str]
) -> list[str]:
    """Gera sugestões de próximos passos."""
    steps: list[str] = []

    if not issue.resolved:
        if issue.assignee == "Não atribuído":
            steps.append("Atribuir um responsável para o chamado")

        if any("reaberto" in p for p in patterns):
            steps.append(
                "Investigar por que a resolução anterior não foi efetiva — "
                "documentar critérios de aceite claros"
            )

        if any("gap" in p.lower() or "inatividade" in p.lower() for p in patterns):
            steps.append("Revisar SLA e escalar se necessário para evitar novos gaps")

        if any("performance" in h or "timeout" in h for h in root_cause_hints):
            steps.append("Coletar traces/logs de performance no momento da ocorrência")

        if any("dump" in h or "exception" in h for h in root_cause_hints):
            steps.append("Coletar o short dump completo (ST22) ou stack trace da exceção")

        if any("integração" in h or "integration" in h for h in root_cause_hints):
            steps.append("Verificar logs de comunicação (SM58, SXI_MONITOR, ou equivalente)")

        steps.append("Documentar o cenário de reprodução com dados de teste")
    else:
        steps.append("Chamado já resolvido — verificar se a solução atende os critérios de aceite")
        steps.append("Monitorar por recorrência nas próximas semanas")

    return steps[:6]


def analyze_issue(
    issue: JiraIssueData,
    attachment_analysis: AttachmentAnalysisResult | None = None,
) -> AnalysisResult:
    """Executa a análise completa de um chamado Jira, incluindo conteúdo dos anexos."""

    timeline = build_timeline(issue)
    patterns = detect_patterns(issue, timeline)
    key_points = extract_key_points(issue, attachment_analysis)
    root_cause_hints = suggest_root_cause(issue, patterns, attachment_analysis)
    next_steps = suggest_next_steps(issue, patterns, root_cause_hints)

    # Métricas
    days_open = _days_between(issue.created, issue.resolved or None)

    status_changes = [t for t in issue.transitions if t.get("field", "").lower() == "status"]
    assignee_changes_list = [t for t in issue.transitions if t.get("field", "").lower() == "assignee"]

    reopened = sum(
        1
        for t in status_changes
        if any(
            kw in (t.get("to") or "").lower()
            for kw in ("reaberto", "reopened", "open", "aberto")
        )
    )

    participants = set()
    participants.add(issue.reporter)
    if issue.assignee and issue.assignee != "Não atribuído":
        participants.add(issue.assignee)
    for c in issue.comments:
        if c.get("author"):
            participants.add(c["author"])
    for t in issue.transitions:
        if t.get("author"):
            participants.add(t["author"])

    # Gerar insights dos anexos
    attachment_insights: list[str] = []
    if attachment_analysis:
        for content in attachment_analysis.contents:
            if content.extraction_success and content.content_summary:
                attachment_insights.append(
                    f"**{content.filename}**: {content.content_summary}"
                )

    return AnalysisResult(
        issue_key=issue.key,
        summary=issue.summary,
        status=issue.status,
        priority=issue.priority,
        issue_type=issue.issue_type,
        timeline=timeline,
        total_comments=len(issue.comments),
        total_transitions=len(issue.transitions),
        days_open=days_open,
        reopened_count=reopened,
        assignee_changes=len(assignee_changes_list),
        unique_participants=sorted(participants),
        patterns=patterns,
        key_points=key_points,
        root_cause_hints=root_cause_hints,
        next_steps=next_steps,
        related_issues=[
            {"key": link.get("issue_key", ""), "summary": link.get("summary", ""), "status": link.get("status", "")}
            for link in issue.links
        ],
        attachments_summary=[
            f"{a.get('filename', '?')} ({a.get('mimeType', '?')}, {a.get('size', 0)//1024}KB)"
            for a in issue.attachments
        ],
        attachment_analysis=attachment_analysis,
        attachment_insights=attachment_insights,
    )
