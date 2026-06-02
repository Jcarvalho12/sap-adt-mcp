#!/usr/bin/env python3
"""
jira_cursor — Agente de análise de chamados Jira.

Conecta-se ao Atlassian Jira Cloud, lê o histórico completo de um chamado
e gera um relatório com análise dos principais pontos e sugestões de onde
pode estar o problema.

Uso:
    python agent.py                          # Modo interativo
    python agent.py --issue PROJ-123         # Análise direta
    python agent.py --issue PROJ-123 --json  # Saída em JSON
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any

_AGENT_ROOT = Path(__file__).resolve().parent
if str(_AGENT_ROOT) not in sys.path:
    sys.path.insert(0, str(_AGENT_ROOT))

from jira_client import JiraClient, JiraConfig, JiraIssueData
from analyzer import analyze_issue, AnalysisResult
from attachment_analyzer import analyze_all_attachments, AttachmentAnalysisResult
from prompts import format_analysis_report, format_compact_summary


def load_config(path: Path | None = None) -> dict[str, Any]:
    """Carrega configuração do config.yaml."""
    cfg_path = path or _AGENT_ROOT / "config.yaml"
    raw = cfg_path.read_text(encoding="utf-8")
    try:
        import yaml
        data = yaml.safe_load(raw)
    except ImportError:
        print(
            "Aviso: PyYAML não instalado. Usando configuração mínima via variáveis de ambiente.",
            file=sys.stderr,
        )
        data = {
            "jira": {
                "base_url": os.environ.get("JIRA_BASE_URL", "https://engsmartdesk.atlassian.net"),
                "email": os.environ.get("JIRA_EMAIL", ""),
                "api_token": os.environ.get("JIRA_API_TOKEN", ""),
            },
            "analysis": {},
        }
    except Exception as exc:
        print(f"Aviso: Falha ao parsear config.yaml ({exc}). Usando defaults.", file=sys.stderr)
        data = {}
    if not isinstance(data, dict):
        return {}
    return data


def create_client(cfg: dict[str, Any]) -> JiraClient:
    """Cria e retorna uma instância configurada do JiraClient."""
    jira_config = JiraConfig.from_dict(cfg)
    return JiraClient(jira_config)


def test_connection(client: JiraClient) -> str:
    """Testa conexão com o Jira e retorna nome do usuário."""
    user_info = client.test_connection()
    display_name = user_info.get("displayName", user_info.get("emailAddress", "?"))
    return display_name


def fetch_and_analyze(
    client: JiraClient,
    issue_key: str,
    cfg: dict[str, Any],
) -> tuple[JiraIssueData, AnalysisResult]:
    """Busca dados do chamado e executa análise completa, incluindo anexos."""
    analysis_cfg = cfg.get("analysis", {})

    print(f"  Buscando dados do chamado {issue_key}...", file=sys.stderr)
    issue_data = client.fetch_full_issue_data(
        issue_key,
        include_transitions=analysis_cfg.get("include_transitions", True),
        include_attachments=analysis_cfg.get("include_attachments", True),
        include_subtasks=analysis_cfg.get("include_subtasks", True),
        include_links=analysis_cfg.get("include_links", True),
        max_comments=analysis_cfg.get("max_comments", 200),
    )

    # Análise de conteúdo dos anexos
    attachment_result: AttachmentAnalysisResult | None = None
    analyze_attachments = analysis_cfg.get("analyze_attachment_content", True)

    if analyze_attachments and issue_data.attachments:
        print(f"  Analisando conteúdo de {len(issue_data.attachments)} anexos...", file=sys.stderr)
        attachment_result = analyze_all_attachments(
            attachments_meta=issue_data.attachments,
            raw_issue_data=issue_data.raw,
            email=client.email,
            api_token=client.api_token,
            max_attachments=analysis_cfg.get("max_attachments_to_analyze", 20),
            max_total_text=analysis_cfg.get("max_attachment_text", 200000),
        )
        if attachment_result.analyzed_count > 0:
            print(
                f"  ✓ {attachment_result.analyzed_count} anexos analisados com sucesso",
                file=sys.stderr,
            )
        if attachment_result.failed_count > 0:
            print(
                f"  ⚠ {attachment_result.failed_count} anexos não puderam ser analisados",
                file=sys.stderr,
            )

    print(f"  Analisando histórico ({len(issue_data.comments)} comentários, "
          f"{len(issue_data.transitions)} transições)...", file=sys.stderr)
    analysis = analyze_issue(issue_data, attachment_result)

    return issue_data, analysis


def run_interactive(cfg: dict[str, Any]) -> None:
    """Modo interativo — pede o issue key ao usuário e exibe o relatório."""
    print("=" * 60)
    print("  jira_cursor — Agente de Análise de Chamados Jira")
    print("=" * 60)
    print()

    client = create_client(cfg)

    print("Testando conexão com o Jira...", file=sys.stderr)
    try:
        user_name = test_connection(client)
        print(f"✓ Conectado como: {user_name}")
    except Exception as exc:
        print(f"✗ Falha na conexão: {exc}", file=sys.stderr)
        print("\nVerifique JIRA_EMAIL e JIRA_API_TOKEN.", file=sys.stderr)
        sys.exit(1)

    print(f"  Base URL: {client.base_url}")
    print()

    while True:
        issue_key = input("Informe o chamado (ex: PROJ-123) ou 'sair': ").strip().upper()
        if issue_key in ("SAIR", "EXIT", "Q", "QUIT", ""):
            print("Encerrando.")
            break

        try:
            _, analysis = fetch_and_analyze(client, issue_key, cfg)
            report = format_analysis_report(analysis)
            print()
            print(report)
            print()
        except Exception as exc:
            print(f"\n✗ Erro ao analisar {issue_key}: {exc}\n", file=sys.stderr)


def run_single(cfg: dict[str, Any], issue_key: str, *, output_json: bool = False) -> None:
    """Analisa um único chamado e imprime o resultado."""
    client = create_client(cfg)

    try:
        user_name = test_connection(client)
        print(f"Conectado como: {user_name}", file=sys.stderr)
    except Exception as exc:
        print(f"Falha na conexão: {exc}", file=sys.stderr)
        sys.exit(1)

    issue_data, analysis = fetch_and_analyze(client, issue_key, cfg)

    if output_json:
        output = {
            "issue_key": analysis.issue_key,
            "summary": analysis.summary,
            "status": analysis.status,
            "priority": analysis.priority,
            "issue_type": analysis.issue_type,
            "days_open": analysis.days_open,
            "total_comments": analysis.total_comments,
            "total_transitions": analysis.total_transitions,
            "reopened_count": analysis.reopened_count,
            "assignee_changes": analysis.assignee_changes,
            "unique_participants": analysis.unique_participants,
            "patterns": analysis.patterns,
            "key_points": analysis.key_points,
            "root_cause_hints": analysis.root_cause_hints,
            "next_steps": analysis.next_steps,
            "related_issues": analysis.related_issues,
            "attachments_summary": analysis.attachments_summary,
            "attachment_insights": analysis.attachment_insights,
            "attachment_content_analyzed": (
                analysis.attachment_analysis.analyzed_count
                if analysis.attachment_analysis else 0
            ),
            "attachment_key_findings": (
                analysis.attachment_analysis.key_findings
                if analysis.attachment_analysis else []
            ),
        }
        print(json.dumps(output, ensure_ascii=False, indent=2))
    else:
        report = format_analysis_report(analysis)
        print(report)


def run_batch(cfg: dict[str, Any], issue_keys: list[str]) -> None:
    """Analisa múltiplos chamados em sequência."""
    client = create_client(cfg)

    try:
        user_name = test_connection(client)
        print(f"Conectado como: {user_name}", file=sys.stderr)
    except Exception as exc:
        print(f"Falha na conexão: {exc}", file=sys.stderr)
        sys.exit(1)

    for key in issue_keys:
        key = key.strip().upper()
        if not key:
            continue
        try:
            _, analysis = fetch_and_analyze(client, key, cfg)
            print(format_compact_summary(analysis))
            print("-" * 40)
        except Exception as exc:
            print(f"✗ {key}: {exc}", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="jira_cursor — Agente de análise de chamados Jira"
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help="Caminho para config.yaml",
    )
    parser.add_argument(
        "--issue", "-i",
        dest="issue_key",
        default=None,
        help="Chave do chamado Jira (ex: PROJ-123)",
    )
    parser.add_argument(
        "--batch",
        nargs="+",
        default=None,
        help="Múltiplos chamados para análise em lote",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        dest="output_json",
        help="Saída em formato JSON (apenas com --issue)",
    )

    args = parser.parse_args()
    cfg = load_config(args.config)

    if args.batch:
        run_batch(cfg, args.batch)
    elif args.issue_key:
        run_single(cfg, args.issue_key.strip().upper(), output_json=args.output_json)
    else:
        run_interactive(cfg)


if __name__ == "__main__":
    main()
