$Host.UI.RawUI.WindowTitle = 'Demo - Hardened health checks'
$ErrorActionPreference = 'Stop'
try {
    Set-Location -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project'
    Write-Host ('=== ' + 'Demo - Hardened health checks' + ' ===') -ForegroundColor Cyan
& .\demo-kit\health-check-loop.ps1 -Phase hardened -Samples 7 -IntervalSeconds 5 -OutFile 'observability\20260709-010940-9e9o\hardened\hardened-health.csv' 2>&1 | Tee-Object -FilePath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-010940-9e9o\hardened\hardened-health.log'
    if ('D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-010940-9e9o\.done\hardened-health.done' -ne '') { Set-Content -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-010940-9e9o\.done\hardened-health.done' -Value 'ok' -Encoding UTF8 }
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    if ('D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-010940-9e9o\.done\hardened-health.done' -ne '') { Set-Content -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-010940-9e9o\.done\hardened-health.done' -Value ('error: ' + $_.Exception.Message) -Encoding UTF8 }
}
Write-Host ''
Write-Host 'Keep this window open for the live demo. Close it manually when finished.' -ForegroundColor Yellow
