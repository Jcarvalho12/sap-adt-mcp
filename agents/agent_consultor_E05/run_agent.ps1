# Executa o agente com o Python do venv do sap-adt-python (pacote `mcp` e demais deps).
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$venvPython = Join-Path $here "..\..\sap-adt-python\.venv\Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    Write-Host "Venv nao encontrado: $venvPython" -ForegroundColor Red
    Write-Host "Crie o ambiente em sap-adt-python ou use: pip install mcp PyYAML" -ForegroundColor Yellow
    exit 1
}
& $venvPython (Join-Path $here "agent.py") @args
