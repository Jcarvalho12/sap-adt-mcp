"""Custom exceptions for SAP ADT operations."""


class AdtError(Exception):
    """Base exception for all ADT errors."""

    def __init__(self, message: str, status_code: int | None = None, response_body: str = ""):
        super().__init__(message)
        self.status_code = status_code
        self.response_body = response_body


class AdtConnectionError(AdtError):
    """Failed to connect to the SAP system."""


class AdtAuthenticationError(AdtError):
    """Authentication failed (wrong user/password/client)."""


class AdtCsrfTokenError(AdtError):
    """CSRF token fetch or validation failed."""


class AdtObjectNotFoundError(AdtError):
    """Requested ABAP object does not exist."""


class AdtLockError(AdtError):
    """Object is locked by another user or transport."""

    def __init__(
        self,
        message: str,
        locked_by_user: str = "",
        lock_transport: str = "",
        **kwargs,
    ):
        super().__init__(message, **kwargs)
        self.locked_by_user = locked_by_user
        self.lock_transport = lock_transport


class AdtActivationError(AdtError):
    """Object activation (compilation) failed."""

    def __init__(self, message: str, messages: list[dict] | None = None, **kwargs):
        super().__init__(message, **kwargs)
        self.messages = messages or []


class AdtTransportError(AdtError):
    """Transport request operation failed."""


class AdtSourceWriteError(AdtError):
    """Failed to write source code."""
