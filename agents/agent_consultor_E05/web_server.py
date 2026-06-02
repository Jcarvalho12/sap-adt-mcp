#!/usr/bin/env python3
"""
Servidor HTTP local para a interface web do agent_consultor_E05.

Utiliza **exclusivamente** as ferramentas e parâmetros documentados em
``sap-adt-python/docs/MCP_COMMAND_REFERENCE.md``.

Uso (recomendado: Python do venv sap-adt-python com mcp instalado):

    pip install fastapi uvicorn[standard]
    python web_server.py

Ou: ..\\..\\sap-adt-python\\.venv\\Scripts\\python.exe web_server.py

Abre http://127.0.0.1:8765 — apenas rede local; não exponha na internet sem TLS e autenticação.
"""

from __future__ import annotations

import sys
from pathlib import Path

_AGENT_ROOT = Path(__file__).resolve().parent
if str(_AGENT_ROOT) not in sys.path:
    sys.path.insert(0, str(_AGENT_ROOT))

from agent import load_config, run_analysis_phase, run_clone_phase  # noqa: E402

try:
    from fastapi import FastAPI, HTTPException
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import FileResponse
    from fastapi.staticfiles import StaticFiles
    from pydantic import BaseModel, Field
except ImportError as exc:
    raise SystemExit(
        "Dependências da UI web não instaladas. Execute: pip install fastapi uvicorn[standard] pydantic"
    ) from exc

STATIC_DIR = _AGENT_ROOT / "static"


class AnalyzeRequest(BaseModel):
    object_name: str = Field(..., min_length=1, description="Nome do objeto ABAP")
    object_type: str = Field(..., min_length=1, description="Ex.: PROGRAM, CLASS, PROG")
    include_name: str | None = Field(None, description="Include opcional para escopo")
    system_id: str | None = Field(None, description="Sobrescreve connection.system_id (ex.: E05)")
    password: str | None = Field(None, description="Senha SAP se não houver env/chaveiro")


class CloneRequest(BaseModel):
    scope_name: str
    effective_type: str
    improved: str
    new_name: str = Field(..., min_length=1)
    package: str = Field(..., min_length=1)
    transport: str = ""
    transport_description: str | None = None
    system_id: str | None = None
    password: str | None = None


def create_app(config_path: Path | None = None) -> FastAPI:
    cfg = load_config(config_path)

    app = FastAPI(
        title="agent_consultor_E05",
        description="Interface web do consultor SAP (pipeline de análise e clone)",
        version="2.0.0",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    if STATIC_DIR.is_dir():
        app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok", "agent": "agent_consultor_E05"}

    @app.post("/api/analyze")
    def api_analyze(body: AnalyzeRequest) -> dict:
        try:
            return run_analysis_phase(
                cfg,
                body.object_name,
                body.object_type,
                include_name=body.include_name,
                system_id=body.system_id,
                password=body.password,
            )
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e)) from e

    @app.post("/api/clone")
    def api_clone(body: CloneRequest) -> dict:
        try:
            return run_clone_phase(
                cfg,
                scope_name=body.scope_name,
                effective_type=body.effective_type,
                improved=body.improved,
                new_name=body.new_name,
                package=body.package,
                transport=body.transport,
                transport_description=body.transport_description,
                system_id=body.system_id,
                password=body.password,
            )
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e)) from e
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e)) from e

    @app.get("/")
    def index() -> FileResponse:
        index_html = STATIC_DIR / "index.html"
        if not index_html.is_file():
            raise HTTPException(
                status_code=404,
                detail=f"Arquivo estático não encontrado: {index_html}",
            )
        return FileResponse(index_html)

    return app


app = create_app()


def main() -> None:
    import argparse
    import uvicorn

    parser = argparse.ArgumentParser(description="UI web agent_consultor_E05")
    parser.add_argument("--host", default="127.0.0.1", help="Bind host (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=8765, help="Port (default: 8765)")
    parser.add_argument("--config", type=Path, default=None, help="config.yaml path")
    args = parser.parse_args()

    application = create_app(args.config)
    uvicorn.run(application, host=args.host, port=args.port, reload=False)


if __name__ == "__main__":
    main()
