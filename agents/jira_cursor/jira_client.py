"""
jira_client.py — Cliente REST para Atlassian Jira Cloud.

Utiliza a API v3 do Jira Cloud com autenticação Basic (email + API token).
Referência: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Any

import requests
from requests.auth import HTTPBasicAuth


@dataclass
class JiraConfig:
    base_url: str
    email: str
    api_token: str

    @classmethod
    def from_dict(cls, cfg: dict[str, Any]) -> "JiraConfig":
        jira_cfg = cfg.get("jira", {})
        base_url = (jira_cfg.get("base_url") or "").rstrip("/")
        email = (jira_cfg.get("email") or "").strip() or os.environ.get("JIRA_EMAIL", "").strip()
        api_token = (
            (jira_cfg.get("api_token") or "").strip()
            or os.environ.get("JIRA_API_TOKEN", "").strip()
        )
        if not base_url:
            raise ValueError("jira.base_url é obrigatório no config.yaml")
        if not email:
            raise ValueError(
                "E-mail Jira não configurado. Defina JIRA_EMAIL ou preencha jira.email no config.yaml"
            )
        if not api_token:
            raise ValueError(
                "API Token Jira não configurado. Defina JIRA_API_TOKEN ou preencha jira.api_token no config.yaml"
            )
        return cls(base_url=base_url, email=email, api_token=api_token)


@dataclass
class JiraIssueData:
    """Contém todos os dados extraídos de um chamado Jira."""

    key: str = ""
    summary: str = ""
    description: str = ""
    status: str = ""
    priority: str = ""
    issue_type: str = ""
    reporter: str = ""
    assignee: str = ""
    created: str = ""
    updated: str = ""
    resolved: str = ""
    resolution: str = ""
    labels: list[str] = field(default_factory=list)
    components: list[str] = field(default_factory=list)
    comments: list[dict[str, Any]] = field(default_factory=list)
    transitions: list[dict[str, Any]] = field(default_factory=list)
    attachments: list[dict[str, Any]] = field(default_factory=list)
    subtasks: list[dict[str, Any]] = field(default_factory=list)
    links: list[dict[str, Any]] = field(default_factory=list)
    custom_fields: dict[str, Any] = field(default_factory=dict)
    raw: dict[str, Any] = field(default_factory=dict)


class JiraClient:
    """Cliente para interagir com a API REST do Jira Cloud."""

    def __init__(self, config: JiraConfig):
        self._config = config
        self._auth = HTTPBasicAuth(config.email, config.api_token)
        self._session = requests.Session()
        self._session.auth = self._auth
        self._session.headers.update({
            "Accept": "application/json",
            "Content-Type": "application/json",
        })

    @property
    def base_url(self) -> str:
        return self._config.base_url

    def _api_url(self, path: str) -> str:
        return f"{self.base_url}/rest/api/3/{path.lstrip('/')}"

    def _get(self, path: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
        url = self._api_url(path)
        resp = self._session.get(url, params=params, timeout=30)
        resp.raise_for_status()
        return resp.json()

    def test_connection(self) -> dict[str, Any]:
        """Testa a conexão retornando informações do usuário autenticado."""
        return self._get("myself")

    def get_issue(self, issue_key: str) -> dict[str, Any]:
        """Obtém dados completos de um chamado (com changelog expandido)."""
        params = {"expand": "changelog,renderedFields,names,transitions"}
        return self._get(f"issue/{issue_key}", params=params)

    def get_issue_comments(
        self, issue_key: str, max_results: int = 200
    ) -> list[dict[str, Any]]:
        """Obtém todos os comentários de um chamado."""
        params = {"maxResults": max_results, "orderBy": "created"}
        data = self._get(f"issue/{issue_key}/comment", params=params)
        return data.get("comments", [])

    def get_issue_transitions(self, issue_key: str) -> list[dict[str, Any]]:
        """Obtém transições disponíveis para o chamado."""
        data = self._get(f"issue/{issue_key}/transitions")
        return data.get("transitions", [])

    def search_issues(self, jql: str, max_results: int = 50) -> list[dict[str, Any]]:
        """Busca issues via JQL."""
        params = {"jql": jql, "maxResults": max_results}
        data = self._get("search", params=params)
        return data.get("issues", [])

    def fetch_full_issue_data(
        self,
        issue_key: str,
        *,
        include_transitions: bool = True,
        include_attachments: bool = True,
        include_subtasks: bool = True,
        include_links: bool = True,
        max_comments: int = 200,
    ) -> JiraIssueData:
        """
        Busca todas as informações relevantes de um chamado para análise.
        Retorna um JiraIssueData estruturado.
        """
        raw = self.get_issue(issue_key)
        fields = raw.get("fields", {})

        issue = JiraIssueData(
            key=raw.get("key", issue_key),
            summary=fields.get("summary", ""),
            description=self._extract_text(fields.get("description")),
            status=(fields.get("status") or {}).get("name", ""),
            priority=(fields.get("priority") or {}).get("name", ""),
            issue_type=(fields.get("issuetype") or {}).get("name", ""),
            reporter=self._extract_user(fields.get("reporter")),
            assignee=self._extract_user(fields.get("assignee")),
            created=fields.get("created", ""),
            updated=fields.get("updated", ""),
            resolved=fields.get("resolutiondate", ""),
            resolution=(fields.get("resolution") or {}).get("name", ""),
            labels=fields.get("labels", []),
            components=[c.get("name", "") for c in (fields.get("components") or [])],
            raw=raw,
        )

        # Comentários
        comments_data = self.get_issue_comments(issue_key, max_results=max_comments)
        issue.comments = [
            {
                "author": self._extract_user(c.get("author")),
                "created": c.get("created", ""),
                "updated": c.get("updated", ""),
                "body": self._extract_text(c.get("body")),
            }
            for c in comments_data
        ]

        # Histórico de transições (changelog)
        if include_transitions:
            changelog = raw.get("changelog", {})
            histories = changelog.get("histories", [])
            for history in histories:
                author = self._extract_user(history.get("author"))
                created = history.get("created", "")
                for item in history.get("items", []):
                    issue.transitions.append({
                        "author": author,
                        "created": created,
                        "field": item.get("field", ""),
                        "from": item.get("fromString", ""),
                        "to": item.get("toString", ""),
                    })

        # Anexos
        if include_attachments:
            issue.attachments = [
                {
                    "filename": a.get("filename", ""),
                    "author": self._extract_user(a.get("author")),
                    "created": a.get("created", ""),
                    "size": a.get("size", 0),
                    "mimeType": a.get("mimeType", ""),
                    "content_url": a.get("content", ""),
                }
                for a in (fields.get("attachment") or [])
            ]

        # Subtasks
        if include_subtasks:
            issue.subtasks = [
                {
                    "key": st.get("key", ""),
                    "summary": (st.get("fields") or {}).get("summary", ""),
                    "status": ((st.get("fields") or {}).get("status") or {}).get("name", ""),
                }
                for st in (fields.get("subtasks") or [])
            ]

        # Links
        if include_links:
            issue.links = [
                {
                    "type": (link.get("type") or {}).get("name", ""),
                    "direction": "outward" if "outwardIssue" in link else "inward",
                    "issue_key": (
                        (link.get("outwardIssue") or link.get("inwardIssue") or {}).get("key", "")
                    ),
                    "summary": (
                        (
                            (link.get("outwardIssue") or link.get("inwardIssue") or {}).get(
                                "fields"
                            )
                            or {}
                        ).get("summary", "")
                    ),
                    "status": (
                        (
                            (
                                (link.get("outwardIssue") or link.get("inwardIssue") or {}).get(
                                    "fields"
                                )
                                or {}
                            ).get("status")
                            or {}
                        ).get("name", "")
                    ),
                }
                for link in (fields.get("issuelinks") or [])
            ]

        return issue

    @property
    def email(self) -> str:
        return self._config.email

    @property
    def api_token(self) -> str:
        return self._config.api_token

    @staticmethod
    def _extract_user(user_data: dict[str, Any] | None) -> str:
        if not user_data:
            return "Não atribuído"
        return user_data.get("displayName", user_data.get("emailAddress", "Desconhecido"))

    @staticmethod
    def _extract_text(doc: Any) -> str:
        """
        Extrai texto legível do formato ADF (Atlassian Document Format) usado na API v3.
        Também aceita strings simples.
        """
        if doc is None:
            return ""
        if isinstance(doc, str):
            return doc

        if not isinstance(doc, dict):
            return str(doc)

        content = doc.get("content", [])
        return JiraClient._parse_adf_nodes(content)

    @staticmethod
    def _parse_adf_nodes(nodes: list[dict[str, Any]]) -> str:
        parts: list[str] = []
        for node in nodes:
            node_type = node.get("type", "")

            if node_type == "text":
                parts.append(node.get("text", ""))
            elif node_type == "hardBreak":
                parts.append("\n")
            elif node_type == "mention":
                attrs = node.get("attrs", {})
                parts.append(f"@{attrs.get('text', attrs.get('id', ''))}")
            elif node_type in ("paragraph", "heading", "blockquote"):
                inner = JiraClient._parse_adf_nodes(node.get("content", []))
                parts.append(inner + "\n")
            elif node_type == "bulletList":
                for item in node.get("content", []):
                    inner = JiraClient._parse_adf_nodes(item.get("content", []))
                    parts.append(f"  • {inner.strip()}\n")
            elif node_type == "orderedList":
                for i, item in enumerate(node.get("content", []), 1):
                    inner = JiraClient._parse_adf_nodes(item.get("content", []))
                    parts.append(f"  {i}. {inner.strip()}\n")
            elif node_type == "codeBlock":
                inner = JiraClient._parse_adf_nodes(node.get("content", []))
                parts.append(f"```\n{inner}\n```\n")
            elif node_type == "table":
                parts.append(JiraClient._parse_adf_table(node))
            elif node_type == "mediaGroup":
                parts.append("[anexo]\n")
            elif "content" in node:
                parts.append(JiraClient._parse_adf_nodes(node.get("content", [])))
            elif "text" in node:
                parts.append(node["text"])

        return "".join(parts)

    @staticmethod
    def _parse_adf_table(table_node: dict[str, Any]) -> str:
        rows = table_node.get("content", [])
        lines: list[str] = []
        for row in rows:
            cells = row.get("content", [])
            cell_texts = []
            for cell in cells:
                txt = JiraClient._parse_adf_nodes(cell.get("content", [])).strip()
                cell_texts.append(txt)
            lines.append(" | ".join(cell_texts))
        return "\n".join(lines) + "\n"
