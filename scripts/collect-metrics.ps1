param(
    [int]$Port = 8080,
    [int]$IntervalSeconds = 5,
    [int]$Samples = 12,
    [string]$OutFile = "observability\metrics.csv"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutPath = Join-Path $ProjectRoot $OutFile
$OutDir = Split-Path -Parent $OutPath
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$rows = @()
for ($i = 0; $i -lt $Samples; $i++) {
    $timestamp = (Get-Date).ToString("s")
    try {
        $connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        $established = @($connections | Where-Object { $_.State -eq "Established" }).Count
        $total = @($connections).Count
    } catch {
        $established = ""
        $total = ""
    }

    $row = [PSCustomObject]@{
        timestamp = $timestamp
        local_port = $Port
        tcp_connections_total = $total
        tcp_connections_established = $established
        note = ""
    }
    $rows += $row
    $row
    Start-Sleep -Seconds $IntervalSeconds
}

$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $OutPath
Write-Host "Metrics written to $OutPath"
