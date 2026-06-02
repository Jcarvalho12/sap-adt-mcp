# Inicia a interface web do agent_consultor_E05 (http://127.0.0.1:8765)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

$py = Join-Path $here "..\..\sap-adt-python\.venv\Scripts\python.exe"
if (-not (Test-Path $py)) {
    Write-Host "Venv sap-adt-python nao encontrado em $py — usando python do PATH."
    $py = "python"
}

& $py (Join-Path $here "web_server.py") @args
