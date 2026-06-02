"""Transport service — CTS transport requests, lock checks, object assignment."""

from __future__ import annotations

import logging
from xml.etree import ElementTree as ET

from .client import AdtClient
from .exceptions import AdtError, AdtLockError, AdtTransportError
from .models import TransportCheckResult, TransportRequest, TransportTask

logger = logging.getLogger(__name__)

TRANSPORT_CHECKS_PATH = "/sap/bc/adt/cts/transportchecks"
TRANSPORT_REQUESTS_PATH = "/sap/bc/adt/cts/transportrequests"


class TransportService:
    """Manage CTS transport requests — check, list, create, release."""

    def __init__(self, client: AdtClient):
        self._client = client

    # ------------------------------------------------------------------
    # Transport check (is object locked / needs transport?)
    # ------------------------------------------------------------------

    def check_transport(
        self,
        object_uri: str,
        object_name: str = "",
    ) -> TransportCheckResult:
        """Check if an object is locked or needs a transport request.

        This is the key call before writing: it tells you if the object is
        already recorded in a transport and which transports are available.
        """
        body = (
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">'
            "<asx:values>"
            "<DATA>"
            f"<PGMID>R3TR</PGMID>"
            f"<OBJECT></OBJECT>"
            f"<OBJ_NAME>{object_name.upper()}</OBJ_NAME>"
            f"<DEVCLASS></DEVCLASS>"
            f"<URI>{object_uri}</URI>"
            "</DATA>"
            "</asx:values>"
            "</asx:abap>"
        )

        resp = self._client.post(
            TRANSPORT_CHECKS_PATH,
            data=body,
            content_type="application/vnd.sap.adt.transportchecks+xml",
            accept="application/xml",
        )

        if resp.status_code >= 400:
            logger.warning("Transport check returned %s: %s", resp.status_code, resp.text[:300])
            return TransportCheckResult()

        return self._parse_transport_check(resp.text)

    @staticmethod
    def _parse_transport_check(xml_text: str) -> TransportCheckResult:
        result = TransportCheckResult()
        try:
            root = ET.fromstring(xml_text.encode("utf-8"))
        except ET.ParseError:
            return result

        for elem in root.iter():
            tag = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
            tag_upper = tag.upper()

            if tag_upper == "RECORDING":
                result.recording_transport = (elem.text or "").strip()
            elif tag_upper == "LOCKED":
                result.locked = (elem.text or "").strip().upper() in ("X", "TRUE", "YES")
            elif tag_upper == "LOCK_HOLDER" or tag_upper == "LOCKHOLDER":
                result.locked_by_user = (elem.text or "").strip()
            elif tag_upper == "LOCK_TRANSPORT":
                result.lock_transport = (elem.text or "").strip()
            elif tag_upper == "REQ_HEADER" or tag_upper == "TRKORR":
                trkorr = (elem.text or "").strip()
                if trkorr:
                    result.needs_transport = True
                    result.available_transports.append(
                        TransportRequest(number=trkorr)
                    )

        # If a recording transport exists, the object is already assigned
        if result.recording_transport:
            result.needs_transport = False

        return result

    # ------------------------------------------------------------------
    # List transport requests
    # ------------------------------------------------------------------

    def list_transport_requests(
        self,
        user: str = "",
        status: str = "D",  # D=modifiable, R=released
    ) -> list[TransportRequest]:
        """List transport requests for a user.

        Args:
            user: SAP user name. Defaults to the connected user.
            status: 'D' for modifiable/open, 'R' for released.
        """
        if not user:
            user = self._client.user

        params = {
            "user": user.upper(),
            "targets": "true",
            "status": status,
        }
        resp = self._client.get(
            TRANSPORT_REQUESTS_PATH,
            params=params,
            accept="application/vnd.sap.adt.transportorganizer.v1+xml, application/xml;q=0.9",
        )
        if resp.status_code >= 400:
            logger.warning("List transports returned %s: %s", resp.status_code, resp.text[:200])
            return []

        return self._parse_transport_list(resp.text)

    def list_open_transports(self, user: str = "") -> list[TransportRequest]:
        """Convenience: list only modifiable (open) transport requests."""
        return self.list_transport_requests(user=user, status="D")

    @staticmethod
    def _parse_transport_list(xml_text: str) -> list[TransportRequest]:
        transports: list[TransportRequest] = []
        try:
            root = ET.fromstring(xml_text.encode("utf-8"))
        except ET.ParseError:
            return transports

        _TM = "{http://www.sap.com/cts/adt/tm}"

        def _local(tag: str) -> str:
            return tag.split("}")[-1] if "}" in tag else tag

        def _attr(elem: ET.Element, key: str) -> str:
            """Read tm:key or plain key attribute."""
            return (
                elem.attrib.get(f"{_TM}{key}", "")
                or elem.attrib.get(key, "")
                or elem.attrib.get(f"tm:{key}", "")
            )

        def _parse_request_elem(tr_elem: ET.Element, target_name: str) -> TransportRequest | None:
            number = _attr(tr_elem, "number") or _attr(tr_elem, "transportNumber")
            if not number:
                for child in tr_elem:
                    ct = _local(child.tag)
                    if ct in ("transportNumber", "number") or ct.upper() == "TRKORR":
                        number = (child.text or "").strip()
                        break
            if not number:
                return None

            desc = _attr(tr_elem, "desc") or _attr(tr_elem, "description")
            owner = _attr(tr_elem, "owner")
            status = _attr(tr_elem, "status")

            tasks: list[TransportTask] = []
            for child in tr_elem:
                if _local(child.tag) == "task":
                    t_num = _attr(child, "number") or _attr(child, "transportNumber")
                    if t_num:
                        tasks.append(TransportTask(
                            number=t_num,
                            description=_attr(child, "desc") or _attr(child, "description"),
                            owner=_attr(child, "owner"),
                            status=_attr(child, "status"),
                        ))

            return TransportRequest(
                number=number, description=desc, owner=owner,
                status=status, target_system=target_name, tasks=tasks,
            )

        for target_elem in root.iter():
            if _local(target_elem.tag) != "target":
                continue
            target_name = _attr(target_elem, "name")

            for mod_elem in target_elem:
                if _local(mod_elem.tag) not in ("modifiable", "released"):
                    continue
                for req_elem in mod_elem:
                    if _local(req_elem.tag) == "request":
                        tr = _parse_request_elem(req_elem, target_name)
                        if tr:
                            transports.append(tr)

        if transports:
            return transports

        for elem in root.iter():
            tag = _local(elem.tag)
            if tag in ("request", "transportRequest"):
                tr = _parse_request_elem(elem, "")
                if tr:
                    transports.append(tr)

        return transports

    # ------------------------------------------------------------------
    # Create transport request
    # ------------------------------------------------------------------

    def create_transport_request(
        self,
        description: str,
        package: str = "",
        target_system: str = "",
    ) -> TransportRequest:
        """Create a new transport request (Workbench Request)."""
        body = (
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">'
            "<asx:values>"
            "<DATA>"
            f"<DESCRIPTION>{description}</DESCRIPTION>"
            f"<REQ_TYPE>K</REQ_TYPE>"  # K = Workbench Request
        )
        if target_system:
            body += f"<TARGET>{target_system.upper()}</TARGET>"
        if package:
            body += f"<DEVCLASS>{package.upper()}</DEVCLASS>"
        body += (
            "</DATA>"
            "</asx:values>"
            "</asx:abap>"
        )

        resp = self._client.post(
            TRANSPORT_REQUESTS_PATH,
            data=body,
            content_type="application/vnd.sap.adt.transportrequests+xml",
            accept="application/xml",
        )

        if resp.status_code >= 400:
            raise AdtTransportError(
                f"Failed to create transport ({resp.status_code}): {resp.text[:300]}",
                status_code=resp.status_code,
            )

        # Response may contain the new transport number in various formats
        tr_number = self._extract_transport_number(resp.text, resp.headers)
        return TransportRequest(number=tr_number, description=description, owner=self._client.user)

    @staticmethod
    def _extract_transport_number(body: str, headers: dict) -> str:
        """Extract transport number from creation response."""
        # Check Location header first
        location = headers.get("Location", "")
        if location:
            parts = location.rstrip("/").split("/")
            if parts:
                return parts[-1]

        # Parse XML body
        body = body.strip()
        if not body:
            return ""
        if body.startswith("<"):
            try:
                root = ET.fromstring(body.encode("utf-8"))
                for elem in root.iter():
                    tag = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
                    if tag.upper() in ("TRKORR", "TRANSPORTNUMBER", "NUMBER"):
                        return (elem.text or "").strip()
                    if "transportNumber" in elem.attrib:
                        return elem.attrib["transportNumber"]
            except ET.ParseError:
                pass
        # Plain text fallback
        for token in body.split():
            token = token.strip()
            if len(token) == 10 and token[3] == "K":
                return token
        return body[:20].strip()

    # ------------------------------------------------------------------
    # Release transport request
    # ------------------------------------------------------------------

    def release_transport(self, transport_number: str) -> bool:
        """Release a transport request."""
        path = f"{TRANSPORT_REQUESTS_PATH}/{transport_number.upper()}/newreleasejobs"
        resp = self._client.post(
            path,
            content_type="application/xml",
            accept="application/xml",
        )
        if resp.status_code >= 400:
            raise AdtTransportError(
                f"Release failed ({resp.status_code}): {resp.text[:300]}",
                status_code=resp.status_code,
            )
        logger.info("Released transport %s", transport_number)
        return True

    # ------------------------------------------------------------------
    # Check lock status (convenience)
    # ------------------------------------------------------------------

    def check_lock(self, object_uri: str) -> dict:
        """Check whether an object is currently locked.

        Returns a dict with keys: locked, locked_by_user, lock_transport.
        """
        result = self.check_transport(object_uri)
        return {
            "locked": result.locked,
            "locked_by_user": result.locked_by_user,
            "lock_transport": result.lock_transport,
            "recording_transport": result.recording_transport,
        }
