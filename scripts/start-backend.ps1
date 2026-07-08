param(
    [string]$PythonExe = "python",
    [int]$Port = 18080
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Backend = Join-Path $ProjectRoot "backend\app.py"

Write-Host "Starting local backend on 127.0.0.1:$Port"
& $PythonExe $Backend --host 127.0.0.1 --port $Port
