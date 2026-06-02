"""Secure credential storage for SAP environments.

Passwords are stored in the OS credential manager via the ``keyring`` library
(Windows Credential Manager, macOS Keychain, Linux Secret Service).
Environment metadata (host, port, client, etc.) is stored in a JSON file
at ``~/.sap-adt/environments.json`` — no secrets in that file.
"""

from __future__ import annotations

import json
import logging
from dataclasses import asdict, dataclass, field
from pathlib import Path

import keyring
import keyring.errors

logger = logging.getLogger("sap_adt.credentials")

_CONFIG_DIR = Path.home() / ".sap-adt"
_ENVIRONMENTS_FILE = _CONFIG_DIR / "environments.json"
_KEYRING_SERVICE = "sap-adt-mcp"


@dataclass
class SapEnvironment:
    system_id: str
    host: str
    port: int = 8000
    client: str = "500"
    user: str = ""
    language: str = "EN"
    use_https: bool = False

    def keyring_key(self) -> str:
        return f"{self.system_id}:{self.user}"


def _ensure_config_dir() -> None:
    _CONFIG_DIR.mkdir(parents=True, exist_ok=True)


def _load_environments() -> dict[str, SapEnvironment]:
    if not _ENVIRONMENTS_FILE.exists():
        return {}
    try:
        raw = json.loads(_ENVIRONMENTS_FILE.read_text(encoding="utf-8"))
        return {
            sid: SapEnvironment(**data)
            for sid, data in raw.items()
        }
    except (json.JSONDecodeError, TypeError) as exc:
        logger.warning("Failed to parse %s: %s", _ENVIRONMENTS_FILE, exc)
        return {}


def _save_environments(envs: dict[str, SapEnvironment]) -> None:
    _ensure_config_dir()
    payload = {sid: asdict(env) for sid, env in envs.items()}
    _ENVIRONMENTS_FILE.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )


def save_environment(env: SapEnvironment, password: str) -> None:
    """Persist environment config and store the password in the OS keyring."""
    envs = _load_environments()
    envs[env.system_id] = env
    _save_environments(envs)

    keyring.set_password(_KEYRING_SERVICE, env.keyring_key(), password)
    logger.info("Saved environment %s (user %s)", env.system_id, env.user)


def get_password(system_id: str, user: str) -> str | None:
    """Retrieve a password from the OS keyring."""
    key = f"{system_id}:{user}"
    return keyring.get_password(_KEYRING_SERVICE, key)


def get_environment(system_id: str) -> SapEnvironment | None:
    """Load a single environment by its ID."""
    return _load_environments().get(system_id)


def list_environments() -> list[SapEnvironment]:
    """Return all stored environments (without passwords)."""
    return list(_load_environments().values())


def delete_environment(system_id: str) -> bool:
    """Remove an environment and its password. Returns True if it existed."""
    envs = _load_environments()
    env = envs.pop(system_id, None)
    if env is None:
        return False

    _save_environments(envs)
    try:
        keyring.delete_password(_KEYRING_SERVICE, env.keyring_key())
    except keyring.errors.PasswordDeleteError:
        logger.debug("No keyring entry found for %s", env.keyring_key())
    return True
