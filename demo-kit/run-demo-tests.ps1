param(
    [string]$NginxHome = "C:\nginx-1.31.2",
    [string]$PythonExe = "python",
    [int]$Connections = 60,
    [int]$Duration = 35,
    [int]$IntervalSeconds = 5,
    [int]$Samples = 7,
    [switch]$SkipBackend
)

$ErrorActionPreference = "Stop"
$DemoRoot = $PSScriptRoot
$ProjectRoot = Split-Path -Parent $DemoRoot
$RunId = (Get-Date).ToString("yyyyMMdd-HHmmss-demo")
$RelRunRoot = Join-Path "observability" $RunId
$RunRoot = Join-Path $ProjectRoot $RelRunRoot
$MarkerDir = Join-Path $RunRoot ".done"

New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $RunRoot "baseline") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $RunRoot "hardened") | Out-Null
New-Item -ItemType Directory -Force -Path $MarkerDir | Out-Null

function Quote-PS {
    param([string]$Value)
    return "'" + ($Value -replace "'", "''") + "'"
}

function Test-HttpOk {
    param([string]$Url)
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
        return ($response.StatusCode -eq 200)
    } catch {
        return $false
    }
}

function Wait-HttpOk {
    param(
        [string]$Url,
        [string]$Name,
        [int]$TimeoutSeconds = 25
    )

    Write-Host "Waiting for ${Name}: $Url"
    for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
        if (Test-HttpOk -Url $Url) {
            Write-Host "$Name is ready." -ForegroundColor Green
            return
        }
        Start-Sleep -Seconds 1
    }
    throw "$Name did not become ready in $TimeoutSeconds seconds."
}

function Start-DemoWindow {
    param(
        [string]$Title,
        [string]$Command,
        [string]$DoneName = ""
    )

    $titleValue = Quote-PS $Title
    $projectValue = Quote-PS $ProjectRoot
    $donePath = ""
    if ($DoneName -ne "") {
        $donePath = Join-Path $MarkerDir $DoneName
    }
    $doneValue = Quote-PS $donePath

    $windowCommand = @"
`$Host.UI.RawUI.WindowTitle = $titleValue
`$ErrorActionPreference = 'Stop'
try {
    Set-Location -LiteralPath $projectValue
    Write-Host ('=== ' + $titleValue.Trim("'" ) + ' ===') -ForegroundColor Cyan
$Command
    if ($doneValue -ne '') { Set-Content -LiteralPath $doneValue -Value 'ok' -Encoding UTF8 }
} catch {
    Write-Host ('ERROR: ' + `$_.Exception.Message) -ForegroundColor Red
    if ($doneValue -ne '') { Set-Content -LiteralPath $doneValue -Value ('error: ' + `$_.Exception.Message) -Encoding UTF8 }
}
Write-Host ''
Write-Host 'Keep this window open for the live demo. Close it manually when finished.' -ForegroundColor Yellow
"@

    Start-Process -FilePath "powershell.exe" -WindowStyle Normal -WorkingDirectory $ProjectRoot -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $windowCommand) | Out-Null
}

function Wait-ForMarker {
    param(
        [string]$DoneName,
        [int]$TimeoutSeconds = 120
    )

    $donePath = Join-Path $MarkerDir $DoneName
    for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
        if (Test-Path -LiteralPath $donePath) {
            $content = Get-Content -LiteralPath $donePath -Encoding UTF8 -Raw
            if ($content -like "error:*") {
                throw "Window task failed: $DoneName - $content"
            }
            return
        }
        Start-Sleep -Seconds 1
    }
    throw "Timed out waiting for $DoneName."
}

function Stop-ProjectNginxBestEffort {
    Write-Host "Stopping project Nginx if it is running..."
    try {
        & (Join-Path $ProjectRoot "scripts\stop-nginx.ps1") -NginxHome $NginxHome | Out-Host
    } catch {
        Write-Warning "Stop attempt finished with warning: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 2
}

function Run-Phase {
    param(
        [ValidateSet("baseline", "hardened")]
        [string]$Phase
    )

    $phaseDir = Join-Path $RunRoot $Phase
    $phaseRelDir = Join-Path $RelRunRoot $Phase
    $phaseTitle = $Phase.Substring(0, 1).ToUpper() + $Phase.Substring(1)
    $startLog = Join-Path $phaseDir "$Phase-nginx-start.log"
    $metricsLog = Join-Path $phaseDir "$Phase-metrics.log"
    $healthLog = Join-Path $phaseDir "$Phase-health.log"
    $attackLog = Join-Path $phaseDir "$Phase-attack.log"
    $metricsRel = Join-Path $phaseRelDir "$Phase-metrics.csv"
    $healthRel = Join-Path $phaseRelDir "$Phase-health.csv"

    Start-DemoWindow -Title "Demo - Start Nginx $phaseTitle" -DoneName "$Phase-nginx.done" -Command @"
& .\scripts\start-nginx.ps1 -Mode $Phase -NginxHome $(Quote-PS $NginxHome) 2>&1 | Tee-Object -FilePath $(Quote-PS $startLog)
"@
    Wait-ForMarker -DoneName "$Phase-nginx.done" -TimeoutSeconds 40
    Wait-HttpOk -Url "http://127.0.0.1:8080/health" -Name "$phaseTitle gateway" -TimeoutSeconds 25

    Start-DemoWindow -Title "Demo - $phaseTitle metrics" -DoneName "$Phase-metrics.done" -Command @"
& .\scripts\collect-metrics.ps1 -Port 8080 -IntervalSeconds $IntervalSeconds -Samples $Samples -OutFile $(Quote-PS $metricsRel) 2>&1 | Tee-Object -FilePath $(Quote-PS $metricsLog)
"@

    Start-DemoWindow -Title "Demo - $phaseTitle health checks" -DoneName "$Phase-health.done" -Command @"
& .\demo-kit\health-check-loop.ps1 -Phase $Phase -Samples $Samples -IntervalSeconds $IntervalSeconds -OutFile $(Quote-PS $healthRel) 2>&1 | Tee-Object -FilePath $(Quote-PS $healthLog)
"@

    Start-Sleep -Seconds 1
    $runScript = ".\scripts\run-$Phase-test.ps1"
    Start-DemoWindow -Title "Demo - $phaseTitle Slowloris" -DoneName "$Phase-attack.done" -Command @"
& $runScript -PythonExe $(Quote-PS $PythonExe) -Connections $Connections -Duration $Duration 2>&1 | Tee-Object -FilePath $(Quote-PS $attackLog)
"@

    Wait-ForMarker -DoneName "$Phase-attack.done" -TimeoutSeconds ($Duration + 120)
    Wait-ForMarker -DoneName "$Phase-metrics.done" -TimeoutSeconds (($Samples * $IntervalSeconds) + 120)
    Wait-ForMarker -DoneName "$Phase-health.done" -TimeoutSeconds (($Samples * $IntervalSeconds) + 120)

    Start-DemoWindow -Title "Demo - Stop Nginx after $phaseTitle" -DoneName "$Phase-stop.done" -Command @"
& .\scripts\stop-nginx.ps1 -NginxHome $(Quote-PS $NginxHome)
"@
    Wait-ForMarker -DoneName "$Phase-stop.done" -TimeoutSeconds 40
    Start-Sleep -Seconds 2
}

Write-Host "Demo run id: $RunId" -ForegroundColor Cyan
Write-Host "Logs will be written to: $RunRoot"

if (-not $SkipBackend) {
    if (Test-HttpOk -Url "http://127.0.0.1:18080/health") {
        Write-Host "Backend is already running." -ForegroundColor Green
    } else {
        $backendLog = Join-Path $RunRoot "backend.log"
        Start-DemoWindow -Title "Demo - Backend service" -Command @"
& .\scripts\start-backend.ps1 -PythonExe $(Quote-PS $PythonExe) 2>&1 | Tee-Object -FilePath $(Quote-PS $backendLog)
"@
        Wait-HttpOk -Url "http://127.0.0.1:18080/health" -Name "Backend" -TimeoutSeconds 25
    }
}

Stop-ProjectNginxBestEffort
Run-Phase -Phase baseline
Run-Phase -Phase hardened

$summaryScript = Join-Path $DemoRoot "summarize-demo-results.ps1"
& $summaryScript -RunRoot $RunRoot
$summaryPath = Join-Path $RunRoot "demo-summary.md"

Start-DemoWindow -Title "Demo - Summary" -Command @"
Get-Content -LiteralPath $(Quote-PS $summaryPath) -Encoding UTF8
"@

Write-Host "Demo finished." -ForegroundColor Green
Write-Host "Summary: $summaryPath"
Write-Host "Keep the opened PowerShell windows for the presentation, or close them after rehearsal."

