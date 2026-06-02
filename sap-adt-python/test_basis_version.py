"""Check SAP_BASIS version on E05."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

import requests
from sap_adt.credential_store import get_password

HOST = "awssbspstx01.engdb.infra"
PORT = 8004
CLIENT = "500"
USER = "JCARVALHO"
PASSWORD = get_password("E05", USER)

session = requests.Session()
session.auth = (USER, PASSWORD)
session.verify = False
session.headers.update({"sap-client": CLIENT, "sap-language": "EN"})
base = f"http://{HOST}:{PORT}"

# Try several endpoints to get version info
endpoints = [
    "/sap/bc/adt/core/discovery",
    "/sap/bc/adt/discovery",
    "/sap/bc/adt/compatibility/graph",
    "/sap/public/info",
]

for ep in endpoints:
    print(f"\n=== {ep} ===")
    try:
        resp = session.get(f"{base}{ep}",
            headers={"Accept": "*/*", "X-CSRF-Token": "Fetch"},
            timeout=10)
        print(f"  Status: {resp.status_code}")
        text = resp.text
        # Look for version info
        for keyword in ["BASIS", "version", "release", "kernel", "ABAP", "SAP_ABA"]:
            if keyword.lower() in text.lower():
                idx = text.lower().find(keyword.lower())
                snippet = text[max(0,idx-30):idx+100]
                print(f"  Found '{keyword}': ...{snippet}...")
    except Exception as e:
        print(f"  Error: {e}")

# Also try system info endpoint
print("\n=== /sap/public/info ===")
try:
    resp = session.get(f"{base}/sap/public/info", headers={"Accept": "text/html,application/xml"}, timeout=10)
    print(f"  Status: {resp.status_code}")
    print(f"  Body: {resp.text[:1000]}")
except Exception as e:
    print(f"  Error: {e}")
