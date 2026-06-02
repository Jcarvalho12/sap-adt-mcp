"""Test write on E05 with a NEW report + exact SourceService approach."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

import requests
from requests.adapters import HTTPAdapter
from xml.etree import ElementTree as ET
from sap_adt.credential_store import get_password

HOST = "awssbspstx01.engdb.infra"
PORT = 8004
CLIENT = "500"
USER = "JCARVALHO"
PASSWORD = get_password("E05", USER)
TRANSPORT = "E05K908791"
NEW_REPORT = "ztestecursore05"

session = requests.Session()
session.auth = (USER, PASSWORD)
session.verify = False
session.headers.update({"sap-client": CLIENT, "sap-language": "PT", "Accept": "application/xml"})
adapter = HTTPAdapter(pool_connections=1, pool_maxsize=1)
session.mount("http://", adapter)

base_url = f"http://{HOST}:{PORT}"

def parse_lock(text):
    try:
        root = ET.fromstring(text.strip())
        for elem in root.iter():
            if "lock_handle" in elem.tag.lower():
                return elem.text or ""
    except ET.ParseError:
        pass
    return text.strip()

# 1. Connect
print("=== 1. CONNECT ===")
resp = session.get(f"{base_url}/sap/bc/adt/discovery",
    headers={"X-CSRF-Token": "Fetch", "Accept": "application/atomsvc+xml"}, timeout=30)
csrf = resp.headers.get("X-CSRF-Token", "")
print(f"  Status: {resp.status_code}, CSRF: {csrf[:20]}...")

# 2. Create the new report first
print(f"\n=== 2. CREATE {NEW_REPORT} ===")
create_xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<program:abapProgram xmlns:program="http://www.sap.com/adt/programs"
    xmlns:adtcore="http://www.sap.com/adt/core"
    adtcore:type="PROG/P"
    adtcore:description="Test Cursor E05"
    adtcore:language="EN"
    adtcore:name="{NEW_REPORT.upper()}"
    adtcore:masterLanguage="EN"
    adtcore:responsible="{USER}"
    program:programType="executableProgram">
    <adtcore:packageRef adtcore:name="$TMP"/>
</program:abapProgram>'''

resp = session.post(f"{base_url}/sap/bc/adt/programs/programs",
    data=create_xml.encode("utf-8"),
    headers={
        "X-CSRF-Token": csrf,
        "Content-Type": "application/vnd.sap.adt.programs.programs.v2+xml",
        "Accept": "application/xml",
    }, timeout=30)
print(f"  Status: {resp.status_code}")
if resp.status_code >= 400 and "already exists" not in resp.text.lower() and "já existe" not in resp.text.lower():
    print(f"  Body: {resp.text[:300]}")
else:
    print("  OK (created or already exists)")

# 3. LOCK
print(f"\n=== 3. LOCK ===")
object_uri = f"/sap/bc/adt/programs/programs/{NEW_REPORT}"
resp = session.post(f"{base_url}{object_uri}",
    params={"_action": "LOCK", "accessMode": "MODIFY"},
    headers={
        "X-CSRF-Token": csrf,
        "Content-Type": "application/vnd.sap.as+xml",
        "Accept": "application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result",
        "X-sap-adt-sessiontype": "stateful",
    }, timeout=30)
lock = parse_lock(resp.text)
print(f"  Status: {resp.status_code}, Handle: {lock}")
ctx = resp.headers.get("sap-contextid", "")
print(f"  sap-contextid: {ctx or 'NOT PRESENT'}")

# Check ALL response headers for any session-related info
print("  All headers:")
for h, v in resp.headers.items():
    print(f"    {h}: {v[:100]}")

if resp.status_code >= 400:
    print("  LOCK FAILED!")
    sys.exit(1)

# 4. WRITE (exact SourceService approach: If-Match=lock, sap-transportrequest header)
print(f"\n=== 4. WRITE ===")
source = "REPORT ztestecursore05.\n\nWRITE: 'Hello from Cursor on E05!'.\n"
source_uri = f"{object_uri}/source/main"

write_headers = {
    "X-CSRF-Token": csrf,
    "Content-Type": "text/plain; charset=utf-8",
    "Accept": "text/plain",
    "If-Match": lock,
    "X-sap-adt-sessiontype": "stateful",
}
if ctx:
    write_headers["sap-contextid"] = ctx

resp = session.put(f"{base_url}{source_uri}",
    data=source.encode("utf-8"),
    headers=write_headers,
    timeout=30)
print(f"  Status: {resp.status_code}")
if resp.status_code < 400:
    print("  >>> WRITE SUCCEEDED! <<<")
else:
    print(f"  Body: {resp.text[:300]}")
    # Try with lockHandle param too
    print("\n  Retrying with lockHandle query param...")
    resp = session.put(f"{base_url}{source_uri}",
        data=source.encode("utf-8"),
        headers=write_headers,
        params={"lockHandle": lock},
        timeout=30)
    print(f"  Status: {resp.status_code}")
    if resp.status_code < 400:
        print("  >>> WRITE SUCCEEDED (with lockHandle param)! <<<")
    else:
        print(f"  Body: {resp.text[:200]}")

# 5. UNLOCK
print(f"\n=== 5. UNLOCK ===")
resp = session.post(f"{base_url}{object_uri}",
    params={"_action": "UNLOCK", "lockHandle": lock},
    headers={"X-CSRF-Token": csrf, "Content-Type": "application/vnd.sap.as+xml", "Accept": "application/vnd.sap.as+xml"},
    timeout=30)
print(f"  Status: {resp.status_code}")

print("\n=== Done ===")
