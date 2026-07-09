$Host.UI.RawUI.WindowTitle = 'Demo - Hardened Slowloris'
$ErrorActionPreference = 'Stop'
try {
    Set-Location -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project'
    Write-Host ('=== ' + 'Demo - Hardened Slowloris' + ' ===') -ForegroundColor Cyan
& .\scripts\run-hardened-test.ps1 -PythonExe 'python' -Connections 5 -Duration 8 2>&1 | Tee-Object -FilePath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-010404-9e4o\hardened\hardened-attack.log'
    if ('D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-010404-9e4o\.done\hardened-attack.done' -ne '') { Set-Content -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-010404-9e4o\.done\hardened-attack.done' -Value 'ok' -Encoding UTF8 }
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    if ('D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-010404-9e4o\.done\hardened-attack.done' -ne '') { Set-Content -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-010404-9e4o\.done\hardened-attack.done' -Value ('error: ' + $_.Exception.Message) -Encoding UTF8 }
}
Write-Host ''
Write-Host 'Keep this window open for the live demo. Close it manually when finished.' -ForegroundColor Yellow
