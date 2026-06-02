#!/usr/bin/env python3
"""Launch the SAP ADT MCP server for Cursor IDE integration."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from sap_adt.mcp_server import main

if __name__ == "__main__":
    main()
