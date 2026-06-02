"""Data models for SAP ADT objects."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class ObjectType(str, Enum):
    PROGRAM = "PROG/P"
    CLASS = "CLAS/OC"
    INTERFACE = "INTF/OI"
    FUNCTION_GROUP = "FUGR/F"
    TABLE = "TABL/DT"
    PACKAGE = "DEVC/K"
    INCLUDE = "PROG/I"

    @property
    def search_type(self) -> str:
        return self.value.split("/")[0]

    @property
    def adt_type(self) -> str:
        return self.value


class ObjectCategory(str, Enum):
    PROGRAM = "programs/programs"
    CLASS = "oo/classes"
    INTERFACE = "oo/interfaces"
    FUNCTION_GROUP = "functions/groups"


@dataclass
class AbapObject:
    name: str
    uri: str
    type: str
    package_name: str = ""
    description: str = ""
    responsible_user: str = ""
    source_uri: str = ""

    @property
    def object_root_uri(self) -> str:
        """URI up to the object root (before /source/main)."""
        if "/source/" in self.uri:
            return self.uri[: self.uri.index("/source/")]
        return self.uri

    @property
    def source_main_uri(self) -> str:
        if self.source_uri:
            return self.source_uri
        return f"{self.object_root_uri}/source/main"


@dataclass
class SearchResult:
    objects: list[AbapObject] = field(default_factory=list)
    total_count: int = 0


@dataclass
class LockHandle:
    handle: str
    object_uri: str

    @property
    def is_valid(self) -> bool:
        return bool(self.handle)


@dataclass
class TransportRequest:
    number: str
    description: str = ""
    owner: str = ""
    status: str = ""
    target_system: str = ""
    tasks: list[TransportTask] = field(default_factory=list)


@dataclass
class TransportTask:
    number: str
    description: str = ""
    owner: str = ""
    status: str = ""


@dataclass
class TransportCheckResult:
    """Result of a CTS transport check for an object."""
    locked: bool = False
    locked_by_user: str = ""
    lock_transport: str = ""
    recording_transport: str = ""
    needs_transport: bool = False
    available_transports: list[TransportRequest] = field(default_factory=list)


@dataclass
class ActivationMessage:
    severity: str = ""  # error, warning, info
    short_text: str = ""
    long_text: str = ""
    line: int = 0
    column: int = 0
    uri: str = ""


@dataclass
class ActivationResult:
    success: bool = False
    messages: list[ActivationMessage] = field(default_factory=list)
    inactive_objects: list[AbapObject] = field(default_factory=list)


@dataclass
class PackageNode:
    name: str
    uri: str
    type: str
    description: str = ""
    children: list[PackageNode] = field(default_factory=list)
