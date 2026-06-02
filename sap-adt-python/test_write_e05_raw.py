"""Raw HTTP test to ensure same TCP connection for lock+write on E05."""
import http.client
import base64
from pathlib import Path
from xml.etree import ElementTree as ET

HOST = "awssbspstx01.engdb.infra"
PORT = 8004
CLIENT = "500"
LANGUAGE = "PT"
OBJECT_NAME = "zdpfisc0003cc"
TRANSPORT = "E05K908791"
SOURCE_FILE = r"c:\Report\ZDPFISC0003.abap"

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))
from sap_adt.credential_store import get_password

USER = "JCARVALHO"
PASSWORD = get_password("E05", USER)
if not PASSWORD:
    print("ERROR: No password found")
    sys.exit(1)

auth = base64.b64encode(f"{USER}:{PASSWORD}".encode()).decode()
base_headers = {
    "Authorization": f"Basic {auth}",
    "sap-client": CLIENT,
    "sap-language": LANGUAGE,
}

source_code = Path(SOURCE_FILE).read_text(encoding="utf-8")
object_uri = f"/sap/bc/adt/programs/programs/{OBJECT_NAME}"
source_uri = f"{object_uri}/source/main"

conn = http.client.HTTPConnection(HOST, PORT, timeout=30)
cookies = {}

def extract_cookies(resp):
    for header in resp.getheaders():
        if header[0].lower() == "set-cookie":
            parts = header[1].split(";")[0]
            k, v = parts.split("=", 1)
            cookies[k.strip()] = v.strip()

def cookie_header():
    return "; ".join(f"{k}={v}" for k, v in cookies.items())

def parse_lock_handle(text):
    body = text.strip()
    if body.startswith("<"):
        try:
            root = ET.fromstring(body)
            for elem in root.iter():
                if "lock_handle" in elem.tag.lower():
                    return elem.text or ""
        except ET.ParseError:
            pass
    return body

# Step 1: Connect + CSRF Token (same TCP connection)
print("=== Step 1: CSRF Token ===")
headers = {**base_headers, "X-CSRF-Token": "Fetch", "Accept": "application/atomsvc+xml"}
conn.request("GET", "/sap/bc/adt/discovery", headers=headers)
resp = conn.getresponse()
body = resp.read().decode("utf-8", errors="replace")
csrf_token = ""
for h in resp.getheaders():
    if h[0].lower() == "x-csrf-token":
        csrf_token = h[1]
extract_cookies(resp)
print(f"  Status: {resp.status}, CSRF: {csrf_token[:20]}...")
print(f"  Cookies: {list(cookies.keys())}")

# Step 2: GET ETag (same TCP connection)
print("\n=== Step 2: GET ETag ===")
headers = {**base_headers, "Accept": "text/plain", "Cookie": cookie_header()}
conn.request("GET", source_uri, headers=headers)
resp = conn.getresponse()
body = resp.read().decode("utf-8", errors="replace")
etag = ""
for h in resp.getheaders():
    if h[0].lower() == "etag":
        etag = h[1]
extract_cookies(resp)
print(f"  Status: {resp.status}, ETag: {etag}")

# Step 3: LOCK (same TCP connection)
print("\n=== Step 3: LOCK ===")
lock_uri = f"{object_uri}?_action=LOCK&accessMode=MODIFY"
headers = {
    **base_headers,
    "X-CSRF-Token": csrf_token,
    "Content-Type": "application/vnd.sap.as+xml",
    "Accept": "application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result",
    "X-sap-adt-sessiontype": "stateful",
    "Cookie": cookie_header(),
    "Content-Length": "0",
}
conn.request("POST", lock_uri, headers=headers)
resp = conn.getresponse()
body = resp.read().decode("utf-8", errors="replace")
lock_handle = parse_lock_handle(body)
extract_cookies(resp)
print(f"  Status: {resp.status}, Handle: {lock_handle}")
print(f"  Response headers:")
for h in resp.getheaders():
    n = h[0].lower()
    if n.startswith(("sap", "x-sap", "set-cookie", "connection", "keep-alive")):
        print(f"    {h[0]}: {h[1][:80]}")

if resp.status >= 400:
    print("  LOCK FAILED!")
    conn.close()
    sys.exit(1)

# Step 4: WRITE (same TCP connection)
print("\n=== Step 4: WRITE ===")
write_uri = f"{source_uri}?lockHandle={lock_handle}"
if TRANSPORT:
    write_uri += f"&corrNr={TRANSPORT}"
data = source_code.encode("utf-8")
headers = {
    **base_headers,
    "X-CSRF-Token": csrf_token,
    "Content-Type": "text/plain; charset=utf-8",
    "Accept": "text/plain",
    "X-sap-adt-sessiontype": "stateful",
    "If-Match": etag,
    "Cookie": cookie_header(),
    "Content-Length": str(len(data)),
}
conn.request("PUT", write_uri, body=data, headers=headers)
resp = conn.getresponse()
body = resp.read().decode("utf-8", errors="replace")
extract_cookies(resp)
print(f"  Status: {resp.status}")
if resp.status < 400:
    print("  >>> WRITE SUCCEEDED! <<<")
else:
    print(f"  Body: {body[:300]}")
    print(f"  Response headers:")
    for h in resp.getheaders():
        print(f"    {h[0]}: {h[1][:80]}")

# Step 5: UNLOCK (same TCP connection)
print("\n=== Step 5: UNLOCK ===")
unlock_uri = f"{object_uri}?_action=UNLOCK&lockHandle={lock_handle}"
headers = {
    **base_headers,
    "X-CSRF-Token": csrf_token,
    "Content-Type": "application/vnd.sap.as+xml",
    "Accept": "application/vnd.sap.as+xml",
    "Cookie": cookie_header(),
    "Content-Length": "0",
}
conn.request("POST", unlock_uri, headers=headers)
resp = conn.getresponse()
body = resp.read().decode("utf-8", errors="replace")
print(f"  Status: {resp.status}")

conn.close()
print("\n=== Done (all on same TCP connection) ===")
