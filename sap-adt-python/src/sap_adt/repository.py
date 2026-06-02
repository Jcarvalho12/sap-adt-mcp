"""ABAP Repository service — search objects, browse packages, read metadata."""

from __future__ import annotations

import logging
from urllib.parse import quote
from xml.etree import ElementTree as ET

from .client import AdtClient, NS
from .models import AbapObject, PackageNode, SearchResult

logger = logging.getLogger(__name__)

SEARCH_PATH = "/sap/bc/adt/repository/informationsystem/search"
NODE_STRUCTURE_PATH = "/sap/bc/adt/repository/nodestructure"

_ADT_CORE = "{http://www.sap.com/adt/core}"
_ATOM = "{http://www.w3.org/2005/Atom}"


def _local_tag(tag: str) -> str:
    return tag.split("}")[-1] if "}" in tag else tag


def _metadata_attrib(elem: ET.Element, key: str) -> str:
    """Read adtcore:* or unprefixed attribute (SAP ADT metadata)."""
    v = elem.attrib.get(f"{_ADT_CORE}{key}", "")
    if v:
        return v
    return elem.attrib.get(key, "") or ""


def _metadata_child_text(elem: ET.Element, local: str) -> str:
    """Read first child like adtcore:name with text."""
    want = (_ADT_CORE + local, local)
    for child in elem:
        if child.tag in want or _local_tag(child.tag) == local:
            return (child.text or "").strip()
    return ""


def _parse_metadata_fields(elem: ET.Element) -> dict[str, str]:
    """Extract name, type, description, package, responsible from one element."""
    name = _metadata_attrib(elem, "name") or _metadata_child_text(elem, "name")
    pkg = _metadata_attrib(elem, "packageName") or _metadata_child_text(
        elem, "packageName"
    )
    if not pkg:
        pref = elem.find(f"{_ADT_CORE}packageRef")
        if pref is not None:
            pkg = _metadata_attrib(pref, "name") or pref.attrib.get("name", "")

    resp_user = (
        _metadata_attrib(elem, "responsibleUser")
        or _metadata_attrib(elem, "responsible")
        or _metadata_child_text(elem, "responsibleUser")
        or _metadata_child_text(elem, "responsible")
    )

    return {
        "name": name,
        "type": _metadata_attrib(elem, "type") or _metadata_child_text(elem, "type"),
        "description": _metadata_attrib(elem, "description")
        or _metadata_child_text(elem, "description"),
        "package_name": pkg,
        "responsible_user": resp_user,
    }


def _find_metadata_element(root: ET.Element) -> ET.Element | None:
    """Locate the ADT object element (abapProgram, class, atom:content child, …)."""
    fields = _parse_metadata_fields(root)
    if fields["name"]:
        return root

    candidate_suffixes = (
        "abapprogram",
        "abapProgram",
        "class",
        "interface",
        "functionGroup",
        "objectReference",
    )
    for el in root.iter():
        lt = _local_tag(el.tag)
        if lt.lower() in {s.lower() for s in candidate_suffixes} or lt.lower().endswith(
            "program"
        ):
            if _parse_metadata_fields(el)["name"]:
                return el

    for content in root.iter(f"{_ATOM}content"):
        for child in list(content):
            if _parse_metadata_fields(child)["name"]:
                return child

    return None


def _accept_header_for_object_uri(object_uri: str) -> str:
    """ADT GET often requires vendor-specific Accept; generic application/xml → 406."""
    u = object_uri.lower()
    if "/programs/programs/" in u:
        return (
            "application/vnd.sap.adt.programs.programs.v2+xml, "
            "application/xml;q=0.9, text/plain;q=0.8"
        )
    if "/oo/classes/" in u:
        return (
            "application/vnd.sap.adt.oo.classes.v4+xml, "
            "application/vnd.sap.adt.oo.classes.v2+xml;q=0.9, "
            "application/xml;q=0.8, text/plain;q=0.7"
        )
    if "/oo/interfaces/" in u:
        return (
            "application/vnd.sap.adt.oo.interfaces.v5+xml, "
            "application/vnd.sap.adt.oo.interfaces.v2+xml;q=0.9, "
            "application/xml;q=0.8, text/plain;q=0.7"
        )
    if "/functions/groups/" in u:
        return (
            "application/vnd.sap.adt.functions.groups.v2+xml, "
            "application/xml;q=0.9, text/plain;q=0.8"
        )
    return "application/xml"


def _collect_source_uri(root: ET.Element, fallback_object_uri: str) -> str:
    """Find rel=source or /source/main link; else derive from object URI."""
    for link in root.iter(f"{_ATOM}link"):
        rel = (link.attrib.get("rel") or "").lower()
        href = (link.attrib.get("href") or "").strip()
        if not href:
            continue
        if "source" in rel or href.endswith("/source/main") or href.endswith("source/main"):
            if href.startswith("/"):
                return href
            base = fallback_object_uri.rstrip("/")
            return f"{base}/{href}" if base else href
    if fallback_object_uri and not fallback_object_uri.endswith("/source/main"):
        return f"{fallback_object_uri.rstrip('/')}/source/main"
    return ""


def _adt_package_object_uri(package_name: str) -> str:
    """Build the ADT URI for a package (OBJECT_URI in nodestructure requests).

    Namespace packages like ``/TAX/SPED_MONITOR`` must have slashes
    percent-encoded (e.g. ``%2ftax%2fsped_monitor``), matching ADT search
    URIs. Plain names (``ZPKG``, ``$TMP``) are used as-is.
    """
    pkg = package_name.strip().upper()
    if "/" in pkg:
        # SAP often emits lowercase hex in paths; match that for compatibility.
        segment = quote(pkg, safe="").lower()
    else:
        segment = pkg
    return f"/sap/bc/adt/packages/{segment}"


class RepositoryService:
    """Operations on the ABAP repository: search, browse, metadata."""

    def __init__(self, client: AdtClient):
        self._client = client

    # ------------------------------------------------------------------
    # Quick search
    # ------------------------------------------------------------------

    def search(
        self,
        query: str,
        object_type: str = "",
        max_results: int = 50,
    ) -> SearchResult:
        """Search the ABAP repository for objects matching *query*.

        Args:
            query: Search pattern (supports * wildcards).
            object_type: Optional ADT type filter (PROG, CLAS, INTF, FUGR, TABL).
            max_results: Cap on returned results.
        """
        params: dict[str, str | int] = {
            "operation": "quickSearch",
            "query": query.upper(),
            "maxResults": max_results,
        }
        if object_type:
            params["objectType"] = object_type.upper()

        resp = self._client.get(SEARCH_PATH, params=params)
        if resp.status_code >= 400:
            logger.warning("Search returned %s: %s", resp.status_code, resp.text[:200])
            return SearchResult()

        return self._parse_search_results(resp.text)

    @staticmethod
    def _parse_search_results(xml_text: str) -> SearchResult:
        root = ET.fromstring(xml_text.encode("utf-8"))
        objects: list[AbapObject] = []

        for elem in root.iter():
            tag_local = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
            if tag_local == "objectReference":
                uri = elem.attrib.get("uri", elem.attrib.get("{http://www.sap.com/adt/core}uri", ""))
                name = elem.attrib.get("name", elem.attrib.get("{http://www.sap.com/adt/core}name", ""))
                obj_type = elem.attrib.get("type", elem.attrib.get("{http://www.sap.com/adt/core}type", ""))
                desc = elem.attrib.get("description", elem.attrib.get("{http://www.sap.com/adt/core}description", ""))
                pkg = elem.attrib.get("packageName", elem.attrib.get("{http://www.sap.com/adt/core}packageName", ""))
                resp_user = elem.attrib.get("responsibleUser", "")
                if name:
                    objects.append(AbapObject(
                        name=name, uri=uri, type=obj_type,
                        description=desc, package_name=pkg,
                        responsible_user=resp_user,
                    ))

        # Also check adtcore:objectReference in attributes-based XML
        for elem in root.iter("{http://www.sap.com/adt/core}objectReference"):
            uri = elem.attrib.get("uri", "")
            name = elem.attrib.get("name", "")
            obj_type = elem.attrib.get("type", "")
            desc = elem.attrib.get("description", "")
            pkg = elem.attrib.get("packageName", "")
            if name and not any(o.name == name and o.uri == uri for o in objects):
                objects.append(AbapObject(
                    name=name, uri=uri, type=obj_type,
                    description=desc, package_name=pkg,
                ))

        return SearchResult(objects=objects, total_count=len(objects))

    # ------------------------------------------------------------------
    # Package tree (nodestructure)
    # ------------------------------------------------------------------

    # Ordered newest-first so modern systems hit on the first try;
    # older systems fall through to the legacy dataname and finally */*.
    _NODESTRUCTURE_ACCEPT_VARIANTS = [
        "application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.repository.tree.result",
        "application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.RepositoryObjectTreeContent",
        "application/vnd.sap.as+xml",
        "*/*",
    ]

    _nodestructure_accept_hit: str | None = None

    def browse_package(self, package_name: str) -> list[PackageNode]:
        """List the immediate children of a package.

        On the first successful call the working Accept header is cached so
        subsequent calls skip the negotiation round-trip.  This lets the same
        MCP server work against both modern and older SAP systems.
        """
        pkg = package_name.strip().upper()
        params = {
            "parent_name": pkg,
            "parent_tech_name": pkg,
            "parent_type": "DEVC/K",
            "withShortDescriptions": "true",
        }

        if self._nodestructure_accept_hit:
            resp = self._client.post(
                NODE_STRUCTURE_PATH,
                data="",
                content_type="text/plain",
                accept=self._nodestructure_accept_hit,
                params=params,
            )
            if resp.status_code < 400:
                return self._parse_node_structure(resp.text)
            self._nodestructure_accept_hit = None

        resp = None
        for accept in self._NODESTRUCTURE_ACCEPT_VARIANTS:
            resp = self._client.post(
                NODE_STRUCTURE_PATH,
                data="",
                content_type="text/plain",
                accept=accept,
                params=params,
            )
            if resp.status_code < 400:
                self._nodestructure_accept_hit = accept
                logger.info("nodestructure negotiated Accept=%s", accept)
                break
            logger.debug(
                "nodestructure Accept=%s returned %s, trying next",
                accept, resp.status_code,
            )

        if resp is None or resp.status_code >= 400:
            logger.warning(
                "Node structure returned %s: %s",
                resp.status_code if resp else "N/A",
                (resp.text[:200] if resp else "no response"),
            )
            return []

        nodes = self._parse_node_structure(resp.text)
        if not nodes:
            logger.info(
                "Node structure returned 0 children for %s (response sample): %s",
                pkg,
                resp.text[:1500].replace("\n", " "),
            )
        return nodes

    @staticmethod
    def _parse_node_structure(xml_text: str) -> list[PackageNode]:
        root = ET.fromstring(xml_text.encode("utf-8"))
        nodes: list[PackageNode] = []

        # Same shape as quick search: atom-style objectReference children
        for elem in root.iter():
            tag_local = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
            if tag_local != "objectReference":
                continue
            uri = elem.attrib.get("uri", elem.attrib.get("{http://www.sap.com/adt/core}uri", ""))
            name = elem.attrib.get("name", elem.attrib.get("{http://www.sap.com/adt/core}name", ""))
            obj_type = elem.attrib.get("type", elem.attrib.get("{http://www.sap.com/adt/core}type", ""))
            desc = elem.attrib.get("description", elem.attrib.get("{http://www.sap.com/adt/core}description", ""))
            if name:
                nodes.append(PackageNode(
                    name=name,
                    uri=uri,
                    type=obj_type,
                    description=desc,
                ))

        for elem in root.iter():
            tag_local = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
            if tag_local in ("objectNode", "node"):
                name_el = elem.find(".//{*}OBJECT_NAME") or elem.find(".//OBJECT_NAME")
                uri_el = elem.find(".//{*}OBJECT_URI") or elem.find(".//OBJECT_URI")
                type_el = elem.find(".//{*}OBJECT_TYPE") or elem.find(".//OBJECT_TYPE")
                desc_el = elem.find(".//{*}DESCRIPTION") or elem.find(".//DESCRIPTION")
                if name_el is not None and name_el.text:
                    nodes.append(PackageNode(
                        name=name_el.text.strip(),
                        uri=(uri_el.text.strip() if uri_el is not None and uri_el.text else ""),
                        type=(type_el.text.strip() if type_el is not None and type_el.text else ""),
                        description=(desc_el.text.strip() if desc_el is not None and desc_el.text else ""),
                    ))

        # Fallback: look for TREE_CONTENT rows
        for row in root.iter():
            tag_local = row.tag.split("}")[-1] if "}" in row.tag else row.tag
            if tag_local == "SEU_ADT_REPOSITORY_OBJ_NODE":
                name_el = row.find("OBJECT_NAME")
                if name_el is None:
                    continue
                uri_el = row.find("OBJECT_URI")
                type_el = row.find("OBJECT_TYPE")
                desc_el = row.find("DESCRIPTION")
                n = name_el.text.strip() if name_el.text else ""
                if n and not any(x.name == n for x in nodes):
                    nodes.append(PackageNode(
                        name=n,
                        uri=(uri_el.text.strip() if uri_el is not None and uri_el.text else ""),
                        type=(type_el.text.strip() if type_el is not None and type_el.text else ""),
                        description=(desc_el.text.strip() if desc_el is not None and desc_el.text else ""),
                    ))

        seen: set[tuple[str, str]] = set()
        unique: list[PackageNode] = []
        for n in nodes:
            key = (n.name, n.uri)
            if key in seen:
                continue
            seen.add(key)
            unique.append(n)
        return unique

    # ------------------------------------------------------------------
    # Object metadata
    # ------------------------------------------------------------------

    def get_object_metadata(self, object_uri: str) -> AbapObject:
        """Fetch metadata for a single ABAP object by its ADT URI."""
        resp = self._client.get(
            object_uri,
            accept=_accept_header_for_object_uri(object_uri),
        )
        if resp.status_code >= 400:
            return AbapObject(name="", uri=object_uri, type="unknown")

        root = self._client.parse_xml(resp.text)
        if root is None:
            return AbapObject(name="", uri=object_uri, type="unknown")

        meta_el = _find_metadata_element(root)
        if meta_el is None:
            return AbapObject(name="", uri=object_uri, type="unknown")

        fields = _parse_metadata_fields(meta_el)
        source_uri = _collect_source_uri(root, object_uri)

        return AbapObject(
            name=fields["name"],
            uri=object_uri,
            type=fields["type"] or "unknown",
            description=fields["description"],
            package_name=fields["package_name"],
            responsible_user=fields["responsible_user"],
            source_uri=source_uri,
        )
