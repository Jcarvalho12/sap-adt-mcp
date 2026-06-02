#!/usr/bin/env python3
"""Quick test: connect to SAP ED2 and verify ADT services are reachable."""

import getpass
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from sap_adt.client import AdtClient
from sap_adt.repository import RepositoryService
from sap_adt.transport import TransportService


def main():
    host = "awsntwpstx01.engdb.infra"
    port = 8000
    sap_client = "500"
    user = "egoetz"
    language = "EN"

    print(f"SAP ADT Connection Test")
    print(f"  Host:     {host}:{port}")
    print(f"  Client:   {sap_client}")
    print(f"  User:     {user}")
    print(f"  Language:  {language}")
    print()

    password = getpass.getpass(f"Password for {user}: ")
    if not password:
        print("ERROR: Password is required.")
        sys.exit(1)

    client = AdtClient(
        host=host,
        port=port,
        client=sap_client,
        user=user,
        password=password,
        language=language,
    )

    # 1. Connect / Discovery
    print("[1/4] Connecting (discovery + CSRF)...")
    try:
        discovery = client.connect()
        print(f"  OK — CSRF token acquired, discovery response: {len(discovery)} bytes")
    except Exception as exc:
        print(f"  FAILED: {exc}")
        sys.exit(1)

    # 2. Search
    print("[2/4] Searching for objects matching 'Z*' (max 5)...")
    repo = RepositoryService(client)
    try:
        result = repo.search("Z*", max_results=5)
        print(f"  OK — {result.total_count} objects found:")
        for obj in result.objects[:5]:
            print(f"    {obj.type:12s} {obj.name:30s} {obj.description}")
    except Exception as exc:
        print(f"  WARNING: Search failed: {exc}")

    # 3. Transport requests
    print(f"[3/4] Listing open transports for {user}...")
    transport_svc = TransportService(client)
    try:
        transports = transport_svc.list_open_transports(user=user)
        print(f"  OK — {len(transports)} open transport(s):")
        for tr in transports[:5]:
            print(f"    {tr.number}  {tr.description}")
    except Exception as exc:
        print(f"  WARNING: Transport list failed: {exc}")

    # 4. Package browse
    print("[4/4] Browsing package $TMP...")
    try:
        nodes = repo.browse_package("$TMP")
        print(f"  OK — {len(nodes)} object(s) in $TMP:")
        for n in nodes[:5]:
            print(f"    {n.type:12s} {n.name}")
    except Exception as exc:
        print(f"  WARNING: Package browse failed: {exc}")

    print()
    print("Connection test complete.")


if __name__ == "__main__":
    main()
