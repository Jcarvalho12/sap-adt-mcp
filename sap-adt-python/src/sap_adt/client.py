"""Core SAP ADT REST API HTTP client.

Handles session management, Basic Auth, CSRF token lifecycle, and all
low-level HTTP communication with the SAP system's /sap/bc/adt/* endpoints.
"""

from __future__ import annotations

import logging
from typing import Any
from xml.etree import ElementTree as ET

import requests

from .exceptions import (
    AdtAuthenticationError,
    AdtConnectionError,
    AdtCsrfTokenError,
    AdtError,
    AdtLockError,
    AdtObjectNotFoundError,
)

logger = logging.getLogger(__name__)

ADT_DISCOVERY_PATH = "/sap/bc/adt/discovery"

NS = {
    "atom": "http://www.w3.org/2005/Atom",
    "app": "http://www.w3.org/2007/app",
    "adtcore": "http://www.sap.com/adt/core",
    "cts": "http://www.sap.com/cts/adt",
    "chkrun": "http://www.sap.com/adt/checkrun",
    "access": "http://www.sap.com/adt/oo/access",
    "program": "http://www.sap.com/adt/programs",
    "class": "http://www.sap.com/adt/oo/classes",
    "intf": "http://www.sap.com/adt/oo/interfaces",
}


class AdtClient:
    """HTTP client for the SAP ADT REST API."""

    def __init__(
        self,
        host: str,
        port: int | str = 8000,
        client: str = "500",
        user: str = "",
        password: str = "",
        language: str = "EN",
        use_https: bool = False,
        verify_ssl: bool = False,
        timeout: int = 30,
    ):
        scheme = "https" if use_https else "http"
        self.base_url = f"{scheme}://{host}:{port}"
        self.client = client
        self.user = user
        self.password = password
        self.language = language
        self.timeout = timeout

        self._session = requests.Session()
        self._session.auth = (user, password)
        self._session.verify = verify_ssl
        self._session.headers.update({
            "sap-client": client,
            "sap-language": language,
            "Accept": "application/xml",
        })

        self._csrf_token: str = ""
        self._connected: bool = False
        self._stateful: bool = False
        self._context_id: str = ""

    @property
    def is_connected(self) -> bool:
        return self._connected

    # ------------------------------------------------------------------
    # Authentication & CSRF
    # ------------------------------------------------------------------

    def connect(self) -> str:
        """Authenticate, fetch CSRF token, return discovery XML."""
        try:
            resp = self._session.get(
                f"{self.base_url}{ADT_DISCOVERY_PATH}",
                headers={
                    "X-CSRF-Token": "Fetch",
                    "Accept": "application/atomsvc+xml",
                },
                timeout=self.timeout,
            )
        except requests.ConnectionError as exc:
            raise AdtConnectionError(
                f"Cannot connect to {self.base_url}: {exc}"
            ) from exc

        if resp.status_code == 401:
            raise AdtAuthenticationError(
                f"Authentication failed for user {self.user} on client {self.client}",
                status_code=401,
            )
        if resp.status_code >= 400:
            raise AdtConnectionError(
                f"Discovery request failed with HTTP {resp.status_code}",
                status_code=resp.status_code,
                response_body=resp.text,
            )

        self._csrf_token = resp.headers.get("X-CSRF-Token", resp.headers.get("x-csrf-token", ""))
        if not self._csrf_token:
            raise AdtCsrfTokenError("Server did not return a CSRF token")

        self._connected = True
        logger.info("Connected to %s as %s (client %s)", self.base_url, self.user, self.client)
        return resp.text

    def _refresh_csrf(self) -> None:
        resp = self._session.get(
            f"{self.base_url}{ADT_DISCOVERY_PATH}",
            headers={
                "X-CSRF-Token": "Fetch",
                "Accept": "application/atomsvc+xml",
            },
            timeout=self.timeout,
        )
        self._csrf_token = resp.headers.get("X-CSRF-Token", resp.headers.get("x-csrf-token", ""))

    def _ensure_connected(self) -> None:
        if not self._connected:
            self.connect()

    # ------------------------------------------------------------------
    # Stateful session management
    # ------------------------------------------------------------------

    def begin_stateful(self) -> None:
        """Open a stateful ADT session.

        Subsequent requests will include ``X-sap-adt-sessiontype: stateful``
        and track the ``sap-contextid`` response header so that the SAP
        application server keeps the same ABAP session across HTTP calls.
        This is required on systems where the ICF service is configured as
        stateless — without this, lock handles become invalid between
        separate HTTP requests.
        """
        self._stateful = True
        self._context_id = ""
        logger.debug("Stateful session mode enabled")

    def end_stateful(self) -> None:
        """Close the stateful ADT session."""
        if self._stateful and self._context_id:
            try:
                self._session.get(
                    f"{self.base_url}{ADT_DISCOVERY_PATH}",
                    headers={
                        "X-sap-adt-sessiontype": "stateless",
                        "sap-contextid": self._context_id,
                        "Accept": "application/atomsvc+xml",
                    },
                    timeout=self.timeout,
                )
            except Exception:
                pass
        self._stateful = False
        self._context_id = ""
        logger.debug("Stateful session mode disabled")

    def _capture_context_id(self, resp: requests.Response) -> None:
        """Extract sap-contextid from the response and store it for reuse."""
        ctx = resp.headers.get("sap-contextid", "")
        if ctx:
            self._context_id = ctx
            logger.debug("Captured sap-contextid: %s", ctx[:30])

    def _stateful_headers(self) -> dict[str, str]:
        """Build headers needed to maintain a stateful ADT session."""
        hdrs: dict[str, str] = {}
        if self._stateful:
            hdrs["X-sap-adt-sessiontype"] = "stateful"
            if self._context_id:
                hdrs["sap-contextid"] = self._context_id
        return hdrs

    # ------------------------------------------------------------------
    # Low-level HTTP helpers
    # ------------------------------------------------------------------

    def _url(self, path: str) -> str:
        if path.startswith("http"):
            return path
        if not path.startswith("/"):
            path = f"/sap/bc/adt/{path}"
        return f"{self.base_url}{path}"

    def _modifying_headers(self, extra: dict[str, str] | None = None) -> dict[str, str]:
        headers = {"X-CSRF-Token": self._csrf_token}
        headers.update(self._stateful_headers())
        if extra:
            headers.update(extra)
        return headers

    def _handle_response(self, resp: requests.Response, context: str = "") -> requests.Response:
        if resp.status_code == 401:
            raise AdtAuthenticationError(f"Auth failed during {context}", status_code=401)
        if resp.status_code == 404:
            raise AdtObjectNotFoundError(f"Not found: {context}", status_code=404)
        return resp

    def get(
        self,
        path: str,
        accept: str = "application/xml",
        params: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> requests.Response:
        self._ensure_connected()
        hdrs = {"Accept": accept}
        hdrs.update(self._stateful_headers())
        if headers:
            hdrs.update(headers)
        resp = self._session.get(self._url(path), headers=hdrs, params=params, timeout=self.timeout)
        self._capture_context_id(resp)
        return self._handle_response(resp, path)

    def post(
        self,
        path: str,
        data: str | bytes = "",
        content_type: str = "application/xml",
        accept: str = "application/xml",
        params: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> requests.Response:
        self._ensure_connected()
        hdrs = self._modifying_headers({
            "Content-Type": content_type,
            "Accept": accept,
        })
        if headers:
            hdrs.update(headers)
        resp = self._session.post(
            self._url(path), data=data.encode("utf-8") if isinstance(data, str) else data,
            headers=hdrs, params=params, timeout=self.timeout,
        )
        if resp.status_code == 403 and "csrf" in resp.text.lower():
            logger.info("CSRF token expired, refreshing...")
            self._refresh_csrf()
            hdrs["X-CSRF-Token"] = self._csrf_token
            resp = self._session.post(
                self._url(path), data=data.encode("utf-8") if isinstance(data, str) else data,
                headers=hdrs, params=params, timeout=self.timeout,
            )
        self._capture_context_id(resp)
        return self._handle_response(resp, path)

    def put(
        self,
        path: str,
        data: str | bytes = "",
        content_type: str = "text/plain",
        accept: str = "text/plain",
        params: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> requests.Response:
        self._ensure_connected()
        hdrs = self._modifying_headers({
            "Content-Type": content_type,
            "Accept": accept,
        })
        if headers:
            hdrs.update(headers)
        resp = self._session.put(
            self._url(path), data=data.encode("utf-8") if isinstance(data, str) else data,
            headers=hdrs, params=params, timeout=self.timeout,
        )
        if resp.status_code == 403 and "csrf" in resp.text.lower():
            self._refresh_csrf()
            hdrs["X-CSRF-Token"] = self._csrf_token
            resp = self._session.put(
                self._url(path), data=data.encode("utf-8") if isinstance(data, str) else data,
                headers=hdrs, params=params, timeout=self.timeout,
            )
        self._capture_context_id(resp)
        return self._handle_response(resp, path)

    def delete(
        self,
        path: str,
        headers: dict[str, str] | None = None,
        params: dict[str, Any] | None = None,
    ) -> requests.Response:
        self._ensure_connected()
        hdrs = self._modifying_headers()
        if headers:
            hdrs.update(headers)
        resp = self._session.delete(
            self._url(path), headers=hdrs, params=params, timeout=self.timeout,
        )
        if resp.status_code == 403 and "csrf" in resp.text.lower():
            self._refresh_csrf()
            hdrs["X-CSRF-Token"] = self._csrf_token
            resp = self._session.delete(
                self._url(path), headers=hdrs, params=params, timeout=self.timeout,
            )
        self._capture_context_id(resp)
        return self._handle_response(resp, path)

    # ------------------------------------------------------------------
    # Object locking
    # ------------------------------------------------------------------

    def lock(self, object_uri: str) -> str:
        """Lock an ABAP object for editing. Returns the lock handle string."""
        resp = self.post(
            object_uri,
            params={"_action": "LOCK", "accessMode": "MODIFY"},
            accept="application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result",
            content_type="application/vnd.sap.as+xml",
        )
        if resp.status_code == 409:
            raise AdtLockError(
                f"Object is locked: {resp.text}",
                status_code=409,
                response_body=resp.text,
            )
        if resp.status_code >= 400:
            raise AdtError(
                f"Lock failed ({resp.status_code}): {resp.text}",
                status_code=resp.status_code,
            )
        lock_handle = self._parse_lock_handle(resp.text)
        logger.info("Locked %s → handle=%s", object_uri, lock_handle[:20] if lock_handle else "?")
        return lock_handle

    def unlock(self, object_uri: str, lock_handle: str) -> None:
        """Unlock a previously locked ABAP object."""
        resp = self.post(
            object_uri,
            params={"_action": "UNLOCK", "lockHandle": lock_handle},
            accept="application/vnd.sap.as+xml",
            content_type="application/vnd.sap.as+xml",
        )
        if resp.status_code >= 400:
            logger.warning("Unlock returned %s: %s", resp.status_code, resp.text)

    @staticmethod
    def _parse_lock_handle(body: str) -> str:
        """Extract lock handle from XML or plain-text response."""
        body = body.strip()
        if not body:
            return ""
        if body.startswith("<"):
            try:
                root = ET.fromstring(body)
                # <asx:values><DATA><LOCK_HANDLE>...</LOCK_HANDLE></DATA></asx:values>
                for elem in root.iter():
                    if elem.tag.upper().endswith("LOCK_HANDLE") or "lock_handle" in elem.tag.lower():
                        return elem.text or ""
                    if "LOCK_HANDLE" in (elem.text or ""):
                        continue
            except ET.ParseError:
                pass
        return body

    # ------------------------------------------------------------------
    # XML helpers
    # ------------------------------------------------------------------

    @staticmethod
    def parse_xml(text: str) -> ET.Element | None:
        """Parse XML text, returning root element or None on failure."""
        try:
            return ET.fromstring(text.encode("utf-8") if isinstance(text, str) else text)
        except ET.ParseError:
            logger.warning("Failed to parse XML response")
            return None
