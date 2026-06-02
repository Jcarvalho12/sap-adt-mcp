# run_agent.ps1 — Executa o agente jira_cursor
# Uso: .\run_agent.ps1
#       .\run_agent.ps1 -Issue "PROJ-123"
#       .\run_agent.ps1 -Issue "PROJ-123" -Json

param(
    [string]$Issue = "",
    [switch]$Json,
    [string[]]$Batch = @()
)

$AgentDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Tenta usar o venv do sap-adt-python se disponível, senão usa python do PATH
$VenvPython = Join-Path $AgentDir "..\..\sap-adt-python\.venv\Scripts\python.exe"
if (Test-Path $VenvPython) {
    $Python = $VenvPython
} else {
    $Python = "python"
}

# Verifica dependências
$ErrorActionPreference = "Continue"
& $Python -c "import requests, yaml" 2>$null
$depCheck = $LASTEXITCODE
$ErrorActionPreference = "Stop"
if ($depCheck -ne 0) {
    Write-Host "Instalando dependências..." -ForegroundColor Yellow
    & $Python -m pip install -r (Join-Path $AgentDir "requirements.txt") --quiet
}

# Monta argumentos
$Args = @()
if ($Issue) {
    $Args += "--issue"
    $Args += $Issue
    if ($Json) {
        $Args += "--json"
    }
} elseif ($Batch.Count -gt 0) {
    $Args += "--batch"
    $Args += $Batch
}

# Executa
Push-Location $AgentDir
try {
    & $Python "agent.py" @Args
} finally {
    Pop-Location
}
