param(
    [string]$PythonExe = "python",
    [string]$NginxHome = ""
)

$ErrorActionPreference = "Stop"

Write-Host "Checking Python..."
try {
    & $PythonExe --version
} catch {
    Write-Warning "Python was not found via '$PythonExe'. Pass -PythonExe with a valid executable."
}

Write-Host "Checking Nginx..."
if ($NginxHome -ne "") {
    $nginxExe = Join-Path $NginxHome "nginx.exe"
    if (Test-Path -LiteralPath $nginxExe) {
        & $nginxExe -v
    } else {
        Write-Warning "nginx.exe was not found under $NginxHome"
    }
} else {
    $cmd = Get-Command nginx -ErrorAction SilentlyContinue
    if ($cmd) {
        & nginx -v
    } else {
        Write-Warning "Nginx was not found in PATH. Use -NginxHome when starting Nginx."
    }
}

Write-Host "Environment check finished."
