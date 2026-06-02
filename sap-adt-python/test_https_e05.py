"""Test E05 via HTTPS on port 44300 and 44304."""
import sys, urllib3
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

import requests
from xml.etree import ElementTree as ET
from sap_adt.credential_store import get_password

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

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

def test_url(base_url, label):
    print(f"\n{'='*60}")
    print(f"  {label}: {base_url}")
    print(f"{'='*60}")
    
    session = requests.Session()
    session.auth = (USER, PASSWORD)
    session.verify = False
    session.headers.update({"sap-client": CLIENT, "sap-language": "PT"})
    
    try:
        resp = session.get(f"{base_url}/sap/bc/adt/discovery",
            headers={"X-CSRF-Token": "Fetch", "Accept": "application/atomsvc+xml"},
            timeout=10)
    except Exception as e:
        print(f"  FAILED: {e}")
        return
    
    if resp.status_code != 200:
        print(f"  Connect: {resp.status_code}")
        if resp.status_code == 401:
            print("  Auth failed (might need different client)")
        return
    
    csrf = resp.headers.get("X-CSRF-Token", "")
    print(f"  Connected OK")
    
    # Lock
    object_uri = f"/sap/bc/adt/programs/programs/{OBJECT_NAME}"
    resp = session.post(f"{base_url}{object_uri}",
        params={"_action": "LOCK", "accessMode": "MODIFY"},
        headers={
            "X-CSRF-Token": csrf,
            "Content-Type": "application/vnd.sap.as+xml",
            "Accept": "application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result",
            "X-sap-adt-sessiontype": "stateful",
        }, timeout=10)
    
    lock = parse_lock(resp.text)
    ctx = resp.headers.get("sap-contextid", "")
    print(f"  LOCK: {resp.status_code}, ContextID: {ctx or 'NONE'}")
    
    if not lock:
        print(f"  Body: {resp.text[:200]}")
        return
    
    # Write  
    source = "REPORT zdpfisc0003cc.\n\nWRITE: 'Test from Cursor HTTPS'.\n"
    write_headers = {
        "X-CSRF-Token": csrf,
        "Content-Type": "text/plain; charset=utf-8",
        "Accept": "text/plain",
        "X-sap-adt-sessiontype": "stateful",
    }
    if ctx:
        write_headers["sap-contextid"] = ctx
    
    resp = session.put(f"{base_url}{object_uri}/source/main",
        data=source.encode("utf-8"),
        headers=write_headers,
        params={"lockHandle": lock, "corrNr": TRANSPORT},
        timeout=10)
    
    print(f"  WRITE: {resp.status_code}")
    if resp.status_code < 400:
        print(f"  >>> SUCCESS! <<<")
    else:
        print(f"  Failed: {resp.text[:150]}")
    
    # Unlock
    session.post(f"{base_url}{object_uri}",
        params={"_action": "UNLOCK", "lockHandle": lock},
        headers={"X-CSRF-Token": csrf, "Content-Type": "application/vnd.sap.as+xml", "Accept": "application/vnd.sap.as+xml"},
        timeout=10)

test_url("https://awssbspstx01.engdb.infra:44300", "HTTPS 44300")
test_url("https://awssbspstx01.engdb.infra:44304", "HTTPS 44304")
test_url("http://awssbspstx01.engdb.infra:8000", "HTTP 8000 (different client?)")

print("\n=== Done ===")
