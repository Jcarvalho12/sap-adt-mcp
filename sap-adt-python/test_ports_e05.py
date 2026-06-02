"""Test multiple ports on E05 to find one that supports stateful sessions."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

import requests
from xml.etree import ElementTree as ET
from sap_adt.credential_store import get_password

HOST = "awssbspstx01.engdb.infra"
CLIENT = "500"
USER = "JCARVALHO"
PASSWORD = get_password("E05", USER)
OBJECT_NAME = "zdpfisc0003cc"
TRANSPORT = "E05K908791"

def parse_lock(text):
    try:
        root = ET.fromstring(text.strip())
        for elem in root.iter():
            if "lock_handle" in elem.tag.lower():
                return elem.text or ""
    except ET.ParseError:
        pass
    return ""

def test_port(port):
    print(f"\n{'='*60}")
    print(f"  Testing port {port}")
    print(f"{'='*60}")
    
    session = requests.Session()
    session.auth = (USER, PASSWORD)
    session.verify = False
    session.headers.update({"sap-client": CLIENT, "sap-language": "PT"})
    base = f"http://{HOST}:{port}"
    
    # Connect
    try:
        resp = session.get(f"{base}/sap/bc/adt/discovery",
            headers={"X-CSRF-Token": "Fetch", "Accept": "application/atomsvc+xml"},
            timeout=5)
    except Exception as e:
        print(f"  Connection FAILED: {e}")
        return
    
    if resp.status_code != 200:
        print(f"  Connect failed: {resp.status_code}")
        return
    
    csrf = resp.headers.get("X-CSRF-Token", "")
    print(f"  Connected OK, CSRF: {csrf[:15]}...")
    
    # Lock
    object_uri = f"/sap/bc/adt/programs/programs/{OBJECT_NAME}"
    resp = session.post(f"{base}{object_uri}",
        params={"_action": "LOCK", "accessMode": "MODIFY"},
        headers={
            "X-CSRF-Token": csrf,
            "Content-Type": "application/vnd.sap.as+xml",
            "Accept": "application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result",
            "X-sap-adt-sessiontype": "stateful",
        }, timeout=10)
    
    lock = parse_lock(resp.text)
    ctx = resp.headers.get("sap-contextid", "")
    print(f"  LOCK: {resp.status_code}, Handle: {lock[:20]}..., ContextID: {ctx or 'NONE'}")
    
    if not lock:
        print(f"  No lock handle! Body: {resp.text[:200]}")
        return
    
    # Write
    source = "REPORT zdpfisc0003cc.\n\nWRITE: 'Test'.\n"
    source_uri = f"{object_uri}/source/main"
    write_headers = {
        "X-CSRF-Token": csrf,
        "Content-Type": "text/plain; charset=utf-8",
        "Accept": "text/plain",
        "X-sap-adt-sessiontype": "stateful",
    }
    if ctx:
        write_headers["sap-contextid"] = ctx
    
    resp = session.put(f"{base}{source_uri}",
        data=source.encode("utf-8"),
        headers=write_headers,
        params={"lockHandle": lock, "corrNr": TRANSPORT},
        timeout=10)
    
    print(f"  WRITE: {resp.status_code}")
    if resp.status_code < 400:
        print(f"  >>> SUCCESS ON PORT {port}! <<<")
    else:
        print(f"  Failed: {resp.text[:150]}")
    
    # Unlock
    session.post(f"{base}{object_uri}",
        params={"_action": "UNLOCK", "lockHandle": lock},
        headers={"X-CSRF-Token": csrf, "Content-Type": "application/vnd.sap.as+xml", "Accept": "application/vnd.sap.as+xml"},
        timeout=10)

# Test standard SAP ports (80xx = HTTP for instance xx)
for port in [8000, 8001, 8002, 8003, 8004, 8005, 44300, 44301, 44304]:
    test_port(port)
    
print("\n=== All tests done ===")
