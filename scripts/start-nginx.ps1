param(
    [ValidateSet("baseline", "hardened")]
    [string]$Mode = "baseline",
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
        throw "Nginx was not found in PATH. Pass -NginxHome, for example: .\scripts\start-nginx.ps1 -NginxHome C:\nginx"
    }
    $NginxExe = $cmd.Source
}

if (-not (Test-Path -LiteralPath $NginxExe)) {
    throw "nginx.exe not found: $NginxExe"
}

$tempDirs = @(
    "logs",
    "temp",
    "temp\client_body_temp",
    "temp\proxy_temp",
    "temp\fastcgi_temp",
    "temp\uwsgi_temp",
    "temp\scgi_temp"
)

foreach ($dir in $tempDirs) {
    New-Item -ItemType Directory -Force -Path (Join-Path $NginxPrefix $dir) | Out-Null
}

$prefixForNginx = ($NginxPrefix -replace "\\", "/") + "/"
$conf = "conf/nginx-$Mode.conf"

Write-Host "Testing Nginx config: $conf"
& $NginxExe -p $prefixForNginx -c $conf -t

Write-Host "Starting Nginx with $conf"
& $NginxExe -p $prefixForNginx -c $conf
Write-Host "Nginx should now listen on http://127.0.0.1:8080"
