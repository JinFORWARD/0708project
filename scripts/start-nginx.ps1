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
        throw "Nginx was not found in PATH. Pass -NginxHome, for example: .\scripts\start-nginx.ps1 -NginxHome C:\nginx-1.31.2"
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

$pidPath = Join-Path $NginxPrefix "logs\nginx.pid"
if (Test-Path -LiteralPath $pidPath) {
    $pidRaw = Get-Content -LiteralPath $pidPath -Raw -ErrorAction SilentlyContinue
    $pidText = "$pidRaw".Trim()
    if ($pidText -notmatch '^\d+$') {
        Write-Warning "Removing stale or invalid Nginx pid file: $pidPath"
        Remove-Item -LiteralPath $pidPath -Force
    }
}

function Invoke-NginxChecked {
    param(
        [string[]]$Arguments,
        [string]$FailureMessage
    )

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $NginxExe @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldErrorActionPreference
    }
    if ($output) {
        $output | ForEach-Object { Write-Host $_ }
    }
    if ($exitCode -ne 0) {
        throw "$FailureMessage Exit code: $exitCode"
    }
}

$prefixForNginx = ($NginxPrefix -replace "\\", "/") + "/"
$conf = "conf/nginx-$Mode.conf"

Write-Host "Testing Nginx config: $conf"
Invoke-NginxChecked -Arguments @("-p", $prefixForNginx, "-c", $conf, "-t") -FailureMessage "Nginx config test failed."

Write-Host "Starting Nginx with $conf"
$arguments = @("-p", $prefixForNginx, "-c", $conf)
$process = Start-Process -FilePath $NginxExe -ArgumentList $arguments -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 1
Write-Host "Nginx start command launched. Bootstrap process id: $($process.Id)"
Write-Host "Nginx should now listen on http://127.0.0.1:8080"



