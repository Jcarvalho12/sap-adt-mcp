import sys, re
sys.path.insert(0, "C:/Users/Jhon Carvalho/Documents/ENGDB/Cursor-MCP/sap-adt-python/src")
import requests
from sap_adt.credential_store import get_password, get_environment
env = get_environment("ED2")
s = requests.Session()
s.auth = (env.user, get_password("ED2", env.user))
s.verify = False
resp = s.get(f"http://{env.host}:{env.port}/sap/public/info",
    headers={"Accept": "*/*", "sap-client": env.client}, timeout=10)
print(f"Status: {resp.status_code}")
print(f"Body: {resp.text[:800]}")
