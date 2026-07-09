param(
    [string]$NginxHome = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$NginxPrefix = Join-Path $ProjectRoot "nginx"

if ($NginxHome -ne "") {
    $NginxExe = Join-Path $NginxHome "nginx.exe"
} else {
    $cmd = Get-Command nginx -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "Nginx was not found in PATH. Pass -NginxHome."
    }
    $NginxExe = $cmd.Source
}

$pidPath = Join-Path $NginxPrefix "logs\nginx.pid"
if (-not (Test-Path -LiteralPath $pidPath)) {
    Write-Host "No project Nginx pid file found; nothing to stop."
    return
}

$pidRaw = Get-Content -LiteralPath $pidPath -Raw -ErrorAction SilentlyContinue
$pidText = "$pidRaw".Trim()
if ($pidText -notmatch '^\d+$') {
    Write-Warning "Removing stale or invalid Nginx pid file: $pidPath"
    Remove-Item -LiteralPath $pidPath -Force
    return
}

$prefixForNginx = ($NginxPrefix -replace "\\", "/") + "/"
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
    $output = & $NginxExe -p $prefixForNginx -c "conf/nginx-baseline.conf" -s stop 2>&1
    $exitCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $oldErrorActionPreference
}
if ($output) {
    $output | ForEach-Object { Write-Host $_ }
}
if ($exitCode -ne 0) {
    throw "Nginx stop failed. Exit code: $exitCode"
}
Write-Host "Stop signal sent to Nginx."
