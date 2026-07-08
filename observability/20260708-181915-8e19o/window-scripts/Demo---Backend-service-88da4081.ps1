$Host.UI.RawUI.WindowTitle = 'Demo - Backend service'
$ErrorActionPreference = 'Stop'
try {
    Set-Location -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project'
    Write-Host ('=== ' + 'Demo - Backend service' + ' ===') -ForegroundColor Cyan
& .\scripts\start-backend.ps1 -PythonExe 'python' 2>&1 | Tee-Object -FilePath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260708-181915-8e19o\backend.log'
    if ('' -ne '') { Set-Content -LiteralPath '' -Value 'ok' -Encoding UTF8 }
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    if ('' -ne '') { Set-Content -LiteralPath '' -Value ('error: ' + $_.Exception.Message) -Encoding UTF8 }
}
Write-Host ''
Write-Host 'Keep this window open for the live demo. Close it manually when finished.' -ForegroundColor Yellow
