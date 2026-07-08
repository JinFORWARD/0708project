param(
    [string]$PythonExe = "python",
    [int]$Connections = 30,
    [int]$Duration = 60
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$AttackTool = Join-Path $ProjectRoot "attack\slowloris.py"

Write-Host "Checking hardened gateway health..."
try {
    Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8080/health | Select-Object StatusCode, Content
} catch {
    Write-Warning "Health request failed. Make sure backend and hardened Nginx are running."
}

Write-Host "Starting local Slowloris simulation against hardened config..."
& $PythonExe $AttackTool --host 127.0.0.1 --port 8080 --connections $Connections --duration $Duration
