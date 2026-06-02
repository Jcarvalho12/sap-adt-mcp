"""Activation service — compile/activate ABAP objects, syntax check."""

from __future__ import annotations

import logging
from xml.etree import ElementTree as ET

from .client import AdtClient, NS
from .exceptions import AdtActivationError, AdtError
from .models import ActivationMessage, ActivationResult
from .source import resolve_object_uri

logger = logging.getLogger(__name__)

ACTIVATION_PATH = "/sap/bc/adt/activation"


class ActivationService:
    """Activate (compile) ABAP objects and run syntax checks."""

    def __init__(self, client: AdtClient):
        self._client = client

    # ------------------------------------------------------------------
    # Activate
    # ------------------------------------------------------------------

    def activate(
        self,
        object_name: str,
        object_uri: str = "",
        object_type: str = "",
    ) -> ActivationResult:
        """Activate a single ABAP object.

        Args:
            object_name: Name of the object (e.g. 'ZTEST_REPORT').
            object_uri: Full ADT URI. If empty, resolved from type+name.
            object_type: PROG, CLAS, INTF, FUGR (needed if object_uri is empty).
        """
        if not object_uri and object_type:
            object_uri = resolve_object_uri(object_type, object_name)

        body = self._build_activation_body(object_name, object_uri)

        resp = self._client.post(
            ACTIVATION_PATH,
            data=body,
            content_type="application/xml",
            accept="application/xml",
            params={"method": "activate", "preauditRequested": "true"},
        )

        if resp.status_code == 200 and not resp.text.strip():
            return ActivationResult(success=True)

        result = self._parse_activation_response(resp.text)

        if resp.status_code >= 400 and not result.success:
            logger.warning("Activation failed for %s: %s", object_name, resp.text[:300])

        return result

    def activate_multiple(
        self,
        objects: list[tuple[str, str]],
    ) -> ActivationResult:
        """Activate multiple objects at once.

        Args:
            objects: List of (name, uri) tuples.
        """
        body = self._build_activation_body_multiple(objects)
        resp = self._client.post(
            ACTIVATION_PATH,
            data=body,
            content_type="application/xml",
            accept="application/xml",
            params={"method": "activate", "preauditRequested": "true"},
        )

        if resp.status_code == 200 and not resp.text.strip():
            return ActivationResult(success=True)

        return self._parse_activation_response(resp.text)

    # ------------------------------------------------------------------
    # Syntax check
    # ------------------------------------------------------------------

    def syntax_check(
        self,
        object_name: str,
        object_type: str = "PROG",
        object_uri: str = "",
    ) -> list[ActivationMessage]:
        """Run syntax check on an object. Returns list of messages."""
        if not object_uri:
            object_uri = resolve_object_uri(object_type, object_name)

        source_uri = f"{object_uri}/source/main"
        check_uri = f"{source_uri}?_action=CHECK&version=inactive"

        resp = self._client.post(
            source_uri,
            params={"_action": "CHECK", "version": "inactive"},
            content_type="application/xml",
            accept="application/xml",
        )

        if resp.status_code >= 400:
            # Fallback: try the checkruns endpoint
            return self._syntax_check_via_checkruns(object_name, object_uri)

        return self._parse_check_messages(resp.text)

    def _syntax_check_via_checkruns(
        self,
        object_name: str,
        object_uri: str,
    ) -> list[ActivationMessage]:
        """Alternative syntax check via /sap/bc/adt/checkruns."""
        body = (
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<chkrun:checkObjectList xmlns:chkrun="http://www.sap.com/adt/checkrun" '
            'xmlns:adtcore="http://www.sap.com/adt/core">'
            f'<chkrun:checkObject adtcore:uri="{object_uri}" adtcore:name="{object_name}"/>'
            "</chkrun:checkObjectList>"
        )
        resp = self._client.post(
            "/sap/bc/adt/checkruns",
            data=body,
            content_type="application/xml",
            accept="application/xml",
        )
        if resp.status_code >= 400:
            return []
        return self._parse_check_messages(resp.text)

    # ------------------------------------------------------------------
    # XML builders
    # ------------------------------------------------------------------

    @staticmethod
    def _build_activation_body(name: str, uri: str) -> str:
        return (
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<adtcore:objectReferences xmlns:adtcore="http://www.sap.com/adt/core">'
            f'<adtcore:objectReference adtcore:uri="{uri}" adtcore:name="{name.upper()}"/>'
            "</adtcore:objectReferences>"
        )

    @staticmethod
    def _build_activation_body_multiple(objects: list[tuple[str, str]]) -> str:
        refs = "".join(
            f'<adtcore:objectReference adtcore:uri="{uri}" adtcore:name="{name.upper()}"/>'
            for name, uri in objects
        )
        return (
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<adtcore:objectReferences xmlns:adtcore="http://www.sap.com/adt/core">'
            f"{refs}"
            "</adtcore:objectReferences>"
        )

    # ------------------------------------------------------------------
    # XML parsers
    # ------------------------------------------------------------------

    @staticmethod
    def _parse_activation_response(xml_text: str) -> ActivationResult:
        if not xml_text or not xml_text.strip():
            return ActivationResult(success=True)

        try:
            root = ET.fromstring(xml_text.encode("utf-8"))
        except ET.ParseError:
            return ActivationResult(success=False, messages=[
                ActivationMessage(severity="error", short_text=f"Unparseable response: {xml_text[:200]}")
            ])

        messages: list[ActivationMessage] = []
        has_errors = False

        for msg_elem in root.iter():
            tag = msg_elem.tag.split("}")[-1] if "}" in msg_elem.tag else msg_elem.tag
            if tag in ("msg", "message"):
                severity = msg_elem.attrib.get("severity", msg_elem.attrib.get("type", "info"))
                short_text = msg_elem.attrib.get("shortText", msg_elem.attrib.get("text", ""))
                if not short_text:
                    short_text = msg_elem.text or ""
                line_str = msg_elem.attrib.get("line", "0")
                col_str = msg_elem.attrib.get("column", "0")
                uri = msg_elem.attrib.get("uri", "")

                msg = ActivationMessage(
                    severity=severity,
                    short_text=short_text.strip(),
                    line=int(line_str) if line_str.isdigit() else 0,
                    column=int(col_str) if col_str.isdigit() else 0,
                    uri=uri,
                )
                messages.append(msg)
                if severity in ("error", "E", "A"):
                    has_errors = True

        return ActivationResult(
            success=not has_errors,
            messages=messages,
        )

    @staticmethod
    def _parse_check_messages(xml_text: str) -> list[ActivationMessage]:
        if not xml_text or not xml_text.strip():
            return []
        try:
            root = ET.fromstring(xml_text.encode("utf-8"))
        except ET.ParseError:
            return []

        messages: list[ActivationMessage] = []
        for elem in root.iter():
            tag = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
            if tag in ("msg", "message", "finding"):
                severity = elem.attrib.get("severity", elem.attrib.get("type", "info"))
                text = elem.attrib.get("shortText", elem.attrib.get("text", elem.text or ""))
                line = elem.attrib.get("line", "0")
                col = elem.attrib.get("column", "0")
                messages.append(ActivationMessage(
                    severity=severity,
                    short_text=text.strip() if text else "",
                    line=int(line) if str(line).isdigit() else 0,
                    column=int(col) if str(col).isdigit() else 0,
                ))
        return messages
