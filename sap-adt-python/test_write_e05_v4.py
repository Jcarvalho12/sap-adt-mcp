"""Test: Create NEW report in $TMP on E05 and write source."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

import requests
from xml.etree import ElementTree as ET
from sap_adt.credential_store import get_password

HOST = "awssbspstx01.engdb.infra"
PORT = 8004
CLIENT = "500"
USER = "JCARVALHO"
PASSWORD = get_password("E05", USER)
NEW_REPORT = "ztestcursortmp"

session = requests.Session()
session.auth = (USER, PASSWORD)
session.verify = False
session.headers.update({"sap-client": CLIENT, "sap-language": "PT"})
base_url = f"http://{HOST}:{PORT}"

def parse_lock(text):
    try:
        root = ET.fromstring(text.strip())
        for elem in root.iter():
            if "lock_handle" in elem.tag.lower():
                return elem.text or ""
    except ET.ParseError:
        pass
    return ""

# 1. Connect
print("=== 1. CONNECT ===")
resp = session.get(f"{base_url}/sap/bc/adt/discovery",
    headers={"X-CSRF-Token": "Fetch", "Accept": "application/atomsvc+xml"}, timeout=30)
csrf = resp.headers.get("X-CSRF-Token", "")
print(f"  OK, CSRF: {csrf[:15]}...")

# 2. Create report in $TMP (correct namespace from sap_create_program)
print(f"\n=== 2. CREATE {NEW_REPORT.upper()} in $TMP ===")
create_xml = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<program:abapProgram xmlns:program="http://www.sap.com/adt/programs/programs" '
    'xmlns:adtcore="http://www.sap.com/adt/core" '
    f'adtcore:description="Test Cursor TMP" '
    f'adtcore:name="{NEW_REPORT.upper()}" '
    'adtcore:type="PROG/P" '
    'adtcore:language="EN">'
    '<adtcore:packageRef adtcore:name="$TMP"/>'
    '</program:abapProgram>'
)
resp = session.post(f"{base_url}/sap/bc/adt/programs/programs",
    data=create_xml.encode("utf-8"),
    headers={
        "X-CSRF-Token": csrf,
        "Content-Type": "application/vnd.sap.adt.programs.programs.v2+xml",
        "Accept": "application/xml",
    }, timeout=30)
print(f"  Status: {resp.status_code}")
if resp.status_code >= 400:
    if "already exists" in resp.text.lower() or "existe" in resp.text.lower():
        print("  Already exists, continuing...")
    else:
        print(f"  Body: {resp.text[:300]}")
        sys.exit(1)
else:
    print("  Created!")

# 3. LOCK (in $TMP, no transport needed)
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
ctx = resp.headers.get("sap-contextid", "")
print(f"  Status: {resp.status_code}, Handle: {lock[:30]}...")
print(f"  sap-contextid: {ctx or 'NONE'}")
print(f"  Full LOCK response body:")
print(f"  {resp.text[:300]}")

if not lock:
    print("  NO LOCK HANDLE!")
    sys.exit(1)

# 4. WRITE (no transport for $TMP)
print(f"\n=== 4. WRITE ===")
source = f"REPORT {NEW_REPORT}.\n\nWRITE: 'Hello from Cursor on E05!'.\n"
source_uri = f"{object_uri}/source/main"

# Method A: lockHandle as param
print("  Method A: lockHandle as query param")
resp = session.put(f"{base_url}{source_uri}",
    data=source.encode("utf-8"),
    headers={
        "X-CSRF-Token": csrf,
        "Content-Type": "text/plain; charset=utf-8",
        "Accept": "text/plain",
        "X-sap-adt-sessiontype": "stateful",
    },
    params={"lockHandle": lock},
    timeout=30)
print(f"  Status: {resp.status_code}")
if resp.status_code < 400:
    print("  >>> METHOD A SUCCEEDED! <<<")
else:
    print(f"  Failed: {resp.text[:150]}")
    
    # Method B: If-Match header  
    print("\n  Method B: If-Match header")
    resp = session.put(f"{base_url}{source_uri}",
        data=source.encode("utf-8"),
        headers={
            "X-CSRF-Token": csrf,
            "Content-Type": "text/plain; charset=utf-8",
            "Accept": "text/plain",
            "If-Match": lock,
            "X-sap-adt-sessiontype": "stateful",
        },
        timeout=30)
    print(f"  Status: {resp.status_code}")
    if resp.status_code < 400:
        print("  >>> METHOD B SUCCEEDED! <<<")
    else:
        print(f"  Failed: {resp.text[:150]}")

# 5. UNLOCK
print(f"\n=== 5. UNLOCK ===")
resp = session.post(f"{base_url}{object_uri}",
    params={"_action": "UNLOCK", "lockHandle": lock},
    headers={"X-CSRF-Token": csrf, "Content-Type": "application/vnd.sap.as+xml", "Accept": "application/vnd.sap.as+xml"},
    timeout=30)
print(f"  Status: {resp.status_code}")

print("\n=== Done ===")
