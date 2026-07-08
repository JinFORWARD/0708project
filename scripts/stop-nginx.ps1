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

$prefixForNginx = ($NginxPrefix -replace "\\", "/") + "/"
& $NginxExe -p $prefixForNginx -c "conf/nginx-baseline.conf" -s stop
Write-Host "Stop signal sent to Nginx."

