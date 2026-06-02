"""Unit tests for the ADT client — offline, no SAP system needed."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from sap_adt.client import AdtClient
from sap_adt.models import AbapObject, ObjectType, TransportRequest, LockHandle
from sap_adt.exceptions import AdtError, AdtLockError, AdtActivationError
from sap_adt.repository import _adt_package_object_uri
from sap_adt.source import resolve_object_uri, resolve_source_uri


def test_adt_package_object_uri():
    assert _adt_package_object_uri("/TAX/SPED_MONITOR") == "/sap/bc/adt/packages/%2ftax%2fsped_monitor"
    assert _adt_package_object_uri("ZGOETZ") == "/sap/bc/adt/packages/ZGOETZ"
    assert _adt_package_object_uri("$TMP") == "/sap/bc/adt/packages/$TMP"


def test_resolve_object_uri():
    assert resolve_object_uri("PROG", "ZTEST") == "/sap/bc/adt/programs/programs/ztest"
    assert resolve_object_uri("CLAS", "ZCL_MY") == "/sap/bc/adt/oo/classes/zcl_my"
    assert resolve_object_uri("INTF", "ZIF_MY") == "/sap/bc/adt/oo/interfaces/zif_my"
    assert resolve_object_uri("FUGR", "ZFUG") == "/sap/bc/adt/functions/groups/zfug"


def test_resolve_source_uri():
    assert resolve_source_uri("PROG", "ZTEST") == "/sap/bc/adt/programs/programs/ztest/source/main"
    assert resolve_source_uri("CLAS", "ZCL_MY") == "/sap/bc/adt/oo/classes/zcl_my/source/main"


def test_abap_object_model():
    obj = AbapObject(
        name="ZTEST",
        uri="/sap/bc/adt/programs/programs/ztest",
        type="PROG/P",
        package_name="$TMP",
    )
    assert obj.object_root_uri == "/sap/bc/adt/programs/programs/ztest"
    assert obj.source_main_uri == "/sap/bc/adt/programs/programs/ztest/source/main"


def test_abap_object_with_source_in_uri():
    obj = AbapObject(
        name="ZTEST",
        uri="/sap/bc/adt/programs/programs/ztest/source/main",
        type="PROG/P",
    )
    assert obj.object_root_uri == "/sap/bc/adt/programs/programs/ztest"


def test_lock_handle():
    lock = LockHandle(handle="abc123", object_uri="/sap/bc/adt/programs/programs/ztest")
    assert lock.is_valid
    empty_lock = LockHandle(handle="", object_uri="")
    assert not empty_lock.is_valid


def test_object_type_enum():
    assert ObjectType.PROGRAM.search_type == "PROG"
    assert ObjectType.CLASS.adt_type == "CLAS/OC"
    assert ObjectType.INTERFACE.search_type == "INTF"


def test_parse_lock_handle_xml():
    xml = '<asx:values xmlns:asx="http://www.sap.com/abapxml"><DATA><LOCK_HANDLE>HANDLE123</LOCK_HANDLE></DATA></asx:values>'
    assert AdtClient._parse_lock_handle(xml) == "HANDLE123"


def test_parse_lock_handle_plain():
    assert AdtClient._parse_lock_handle("HANDLE123") == "HANDLE123"


def test_parse_lock_handle_empty():
    assert AdtClient._parse_lock_handle("") == ""


def test_adt_client_url_building():
    client = AdtClient(host="example.com", port=8000, client="100", user="test", password="test")
    assert client._url("/sap/bc/adt/discovery") == "http://example.com:8000/sap/bc/adt/discovery"
    assert client._url("programs/programs/ztest") == "http://example.com:8000/sap/bc/adt/programs/programs/ztest"


def test_exception_hierarchy():
    assert issubclass(AdtLockError, AdtError)
    assert issubclass(AdtActivationError, AdtError)

    lock_err = AdtLockError("locked", locked_by_user="USER1", lock_transport="TR001")
    assert lock_err.locked_by_user == "USER1"
    assert lock_err.lock_transport == "TR001"


if __name__ == "__main__":
    test_adt_package_object_uri()
    test_resolve_object_uri()
    test_resolve_source_uri()
    test_abap_object_model()
    test_abap_object_with_source_in_uri()
    test_lock_handle()
    test_object_type_enum()
    test_parse_lock_handle_xml()
    test_parse_lock_handle_plain()
    test_parse_lock_handle_empty()
    test_adt_client_url_building()
    test_exception_hierarchy()
    print("All tests passed!")
