"""Source code service — read/write ABAP source with lock management."""

from __future__ import annotations

import logging

from .client import AdtClient
from .exceptions import AdtError, AdtLockError, AdtSourceWriteError
from .models import LockHandle

logger = logging.getLogger(__name__)


# URI patterns for different object types
OBJECT_URI_MAP = {
    "PROG": "/sap/bc/adt/programs/programs/{name}",
    "CLAS": "/sap/bc/adt/oo/classes/{name}",
    "INTF": "/sap/bc/adt/oo/interfaces/{name}",
    "FUGR": "/sap/bc/adt/functions/groups/{name}",
}


def resolve_object_uri(object_type: str, object_name: str) -> str:
    """Build the ADT URI for an object given its type code and name.

    Namespace names like ``/PGTPA/IF_EX_NFI`` are percent-encoded so the
    URI becomes ``.../interfaces/%2fpgtpa%2fif_ex_nfi`` instead of the
    broken ``.../interfaces//pgtpa/if_ex_nfi``.
    """
    from urllib.parse import quote

    type_key = object_type.upper().split("/")[0]
    template = OBJECT_URI_MAP.get(type_key)
    if not template:
        raise AdtError(f"Unsupported object type: {object_type}")
    name = object_name.strip()
    if "/" in name:
        name = quote(name, safe="").lower()
    else:
        name = name.lower()
    return template.format(name=name)


def resolve_source_uri(object_type: str, object_name: str) -> str:
    """Build the source/main URI for an object."""
    return f"{resolve_object_uri(object_type, object_name)}/source/main"


class SourceService:
    """Read, write, lock, and unlock ABAP source code."""

    def __init__(self, client: AdtClient):
        self._client = client

    # ------------------------------------------------------------------
    # Read
    # ------------------------------------------------------------------

    def read_source(
        self,
        object_name: str,
        object_type: str = "PROG",
        version: str = "active",
        uri: str = "",
    ) -> str:
        """Read source code for an ABAP object.

        Args:
            object_name: e.g. 'ZTEST_REPORT' or 'ZCL_MY_CLASS'.
            object_type: PROG, CLAS, INTF, FUGR.
            version: 'active' or 'inactive'.
            uri: Explicit source URI (overrides type/name resolution).
        """
        source_uri = uri or resolve_source_uri(object_type, object_name)
        params = {}
        if version and version != "active":
            params["version"] = version

        resp = self._client.get(source_uri, accept="text/plain", params=params or None)
        if resp.status_code == 404:
            raise AdtError(f"Source not found for {object_type} {object_name}", status_code=404)
        if resp.status_code >= 400:
            raise AdtError(
                f"Read source failed ({resp.status_code}): {resp.text[:300]}",
                status_code=resp.status_code,
            )
        return resp.text

    def read_source_by_uri(self, source_uri: str, version: str = "active") -> str:
        """Read source using a full ADT source URI."""
        params = {}
        if version and version != "active":
            params["version"] = version
        resp = self._client.get(source_uri, accept="text/plain", params=params or None)
        if resp.status_code >= 400:
            raise AdtError(f"Read source failed ({resp.status_code})", status_code=resp.status_code)
        return resp.text

    # ------------------------------------------------------------------
    # Lock / Unlock
    # ------------------------------------------------------------------

    def lock(self, object_name: str, object_type: str = "PROG", uri: str = "") -> LockHandle:
        """Acquire an edit lock on an ABAP object."""
        object_uri = uri or resolve_object_uri(object_type, object_name)
        handle = self._client.lock(object_uri)
        return LockHandle(handle=handle, object_uri=object_uri)

    def unlock(self, lock: LockHandle) -> None:
        """Release an edit lock."""
        if lock.is_valid:
            self._client.unlock(lock.object_uri, lock.handle)

    # ------------------------------------------------------------------
    # Write
    # ------------------------------------------------------------------

    def write_source(
        self,
        object_name: str,
        source_code: str,
        object_type: str = "PROG",
        lock_handle: str = "",
        transport_request: str = "",
        uri: str = "",
    ) -> None:
        """Write source code to an ABAP object.

        The caller must provide a lock_handle (from lock()) or
        this method will acquire and release the lock automatically.
        """
        object_uri = uri or resolve_object_uri(object_type, object_name)
        source_uri = f"{object_uri}/source/main"
        auto_locked = False

        if not lock_handle:
            try:
                lock_handle = self._client.lock(object_uri)
                auto_locked = True
            except AdtLockError:
                raise

        try:
            headers: dict[str, str] = {"If-Match": lock_handle}
            if transport_request:
                headers["sap-transportrequest"] = transport_request

            resp = self._client.put(
                source_uri,
                data=source_code,
                content_type="text/plain",
                accept="text/plain",
                headers=headers,
            )
            if resp.status_code >= 400:
                raise AdtSourceWriteError(
                    f"Write source failed ({resp.status_code}): {resp.text[:500]}",
                    status_code=resp.status_code,
                )
            logger.info("Source written to %s", object_uri)
        finally:
            if auto_locked and lock_handle:
                self._client.unlock(object_uri, lock_handle)

    def write_and_activate(
        self,
        object_name: str,
        source_code: str,
        object_type: str = "PROG",
        transport_request: str = "",
    ) -> dict:
        """Write source code and activate in one operation. Returns activation result."""
        from .activation import ActivationService

        object_uri = resolve_object_uri(object_type, object_name)
        lock_handle = self._client.lock(object_uri)

        try:
            headers: dict[str, str] = {"If-Match": lock_handle}
            if transport_request:
                headers["sap-transportrequest"] = transport_request

            source_uri = f"{object_uri}/source/main"
            resp = self._client.put(
                source_uri,
                data=source_code,
                content_type="text/plain",
                accept="text/plain",
                headers=headers,
            )
            if resp.status_code >= 400:
                raise AdtSourceWriteError(
                    f"Write failed ({resp.status_code}): {resp.text[:500]}",
                    status_code=resp.status_code,
                )

            activator = ActivationService(self._client)
            result = activator.activate(object_name, object_uri)
            return {
                "written": True,
                "activated": result.success,
                "messages": [
                    {"severity": m.severity, "text": m.short_text, "line": m.line}
                    for m in result.messages
                ],
            }
        finally:
            self._client.unlock(object_uri, lock_handle)
