"""Test script to debug write source on E05 with session management."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

import requests
import json

HOST = "awssbspstx01.engdb.infra"
PORT = 8004
CLIENT = "500"
LANGUAGE = "PT"
OBJECT_NAME = "zdpfisc0003cc"
TRANSPORT = "E05K908791"
SOURCE_FILE = r"c:\Report\ZDPFISC0003.abap"

from sap_adt.credential_store import get_password

USER = "JCARVALHO"
PASSWORD = get_password("E05", USER)

if not PASSWORD:
    print("ERROR: No password found for E05/JCARVALHO")
    sys.exit(1)

base_url = f"http://{HOST}:{PORT}"
session = requests.Session()
session.auth = (USER, PASSWORD)
session.verify = False
session.headers.update({
    "sap-client": CLIENT,
    "sap-language": LANGUAGE,
    "Accept": "application/xml",
})

from requests.adapters import HTTPAdapter
adapter = HTTPAdapter(pool_connections=1, pool_maxsize=1)
session.mount("http://", adapter)
session.mount("https://", adapter)

# Step 1: Connect + fetch CSRF token
print("=== Step 1: Connect ===")
resp = session.get(
    f"{base_url}/sap/bc/adt/discovery",
    headers={"X-CSRF-Token": "Fetch", "Accept": "application/atomsvc+xml"},
    timeout=30,
)
print(f"  Status: {resp.status_code}")
csrf_token = resp.headers.get("X-CSRF-Token", "")
print(f"  CSRF Token: {csrf_token[:20]}...")
print(f"  Response cookies: {dict(resp.cookies)}")
print(f"  Session cookies: {dict(session.cookies)}")
print(f"  sap-contextid: {resp.headers.get('sap-contextid', 'NOT PRESENT')}")

source_code = Path(SOURCE_FILE).read_text(encoding="utf-8")
object_uri = f"/sap/bc/adt/programs/programs/{OBJECT_NAME}"
source_uri = f"{object_uri}/source/main"

from xml.etree import ElementTree as ET

def parse_lock(text):
    body = text.strip()
    if body.startswith("<"):
        try:
            root = ET.fromstring(body)
            for elem in root.iter():
                if elem.tag.upper().endswith("LOCK_HANDLE") or "lock_handle" in elem.tag.lower():
                    return elem.text or ""
        except ET.ParseError:
            pass
    return body

# ===== APPROACH 1: Write WITHOUT lock (optimistic ETag only) =====
print("\n=== APPROACH 1: Write with ETag only (no lock) ===")

# Get ETag
resp = session.get(
    f"{base_url}{source_uri}",
    headers={"Accept": "text/plain"},
    timeout=30,
)
etag = resp.headers.get("ETag", resp.headers.get("etag", ""))
print(f"  GET Status: {resp.status_code}, ETag: {etag}")

params = {}
if TRANSPORT:
    params["corrNr"] = TRANSPORT

resp = session.put(
    f"{base_url}{source_uri}",
    data=source_code.encode("utf-8"),
    headers={
        "X-CSRF-Token": csrf_token,
        "Content-Type": "text/plain; charset=utf-8",
        "Accept": "text/plain",
        "If-Match": etag,
    },
    params=params,
    timeout=30,
)
print(f"  PUT Status: {resp.status_code}")
if resp.status_code < 400:
    print("  >>> APPROACH 1 SUCCEEDED! <<<")
else:
    print(f"  Body: {resp.text[:300]}")

# ===== APPROACH 2: Lock+Write in rapid sequence, no ETag, no stateful =====
print("\n=== APPROACH 2: Lock+Write rapid sequence (no ETag, no stateful) ===")

resp_lock = session.post(
    f"{base_url}{object_uri}",
    params={"_action": "LOCK", "accessMode": "MODIFY"},
    headers={
        "X-CSRF-Token": csrf_token,
        "Content-Type": "application/vnd.sap.as+xml",
        "Accept": "application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result",
    },
    timeout=30,
)
lock_handle = parse_lock(resp_lock.text)
print(f"  LOCK Status: {resp_lock.status_code}, Handle: {lock_handle[:20]}...")

params2 = {"lockHandle": lock_handle}
if TRANSPORT:
    params2["corrNr"] = TRANSPORT
resp = session.put(
    f"{base_url}{source_uri}",
    data=source_code.encode("utf-8"),
    headers={
        "X-CSRF-Token": csrf_token,
        "Content-Type": "text/plain; charset=utf-8",
        "Accept": "text/plain",
    },
    params=params2,
    timeout=30,
)
print(f"  PUT Status: {resp.status_code}")
if resp.status_code < 400:
    print("  >>> APPROACH 2 SUCCEEDED! <<<")
else:
    print(f"  Body: {resp.text[:200]}")
# Unlock
session.post(
    f"{base_url}{object_uri}",
    params={"_action": "UNLOCK", "lockHandle": lock_handle},
    headers={"X-CSRF-Token": csrf_token, "Content-Type": "application/vnd.sap.as+xml", "Accept": "application/vnd.sap.as+xml"},
    timeout=30,
)

# ===== APPROACH 3: Use /sap/bc/adt/cts/transportchecks to find correct approach =====
print("\n=== APPROACH 3: Check object type via discovery ===")
resp = session.get(
    f"{base_url}{object_uri}",
    headers={"Accept": "application/xml"},
    timeout=30,
)
print(f"  GET object Status: {resp.status_code}")
print(f"  Body: {resp.text[:500]}")

print("\n=== Done ===")
