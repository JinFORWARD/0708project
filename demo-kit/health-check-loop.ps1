param(
    [string]$Phase = "baseline",
    [string]$Url = "http://127.0.0.1:8080/health",
    [int]$Samples = 7,
    [int]$IntervalSeconds = 5,
    [string]$OutFile = "observability\demo-health.csv"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if ([System.IO.Path]::IsPathRooted($OutFile)) {
    $OutPath = $OutFile
} else {
    $OutPath = Join-Path $ProjectRoot $OutFile
}
$OutDir = Split-Path -Parent $OutPath
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$rows = @()
for ($i = 1; $i -le $Samples; $i++) {
    $timestamp = (Get-Date).ToString("s")
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = ""
    $errorText = ""
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 5
        $status = [string]$response.StatusCode
    } catch {
        $status = "ERROR"
        $errorText = $_.Exception.Message
    } finally {
        $sw.Stop()
    }

    $row = [PSCustomObject]@{
        timestamp = $timestamp
        phase = $Phase
        status = $status
        elapsed_ms = [int]$sw.ElapsedMilliseconds
        error = $errorText
    }
    $rows += $row
    $row

    if ($i -lt $Samples) {
        Start-Sleep -Seconds $IntervalSeconds
    }
}

$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $OutPath
Write-Host "Health check results written to $OutPath"
