$Host.UI.RawUI.WindowTitle = 'Demo - Baseline Slowloris'
$ErrorActionPreference = 'Stop'
try {
    Set-Location -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project'
    Write-Host ('=== ' + 'Demo - Baseline Slowloris' + ' ===') -ForegroundColor Cyan
& .\scripts\run-baseline-test.ps1 -PythonExe 'python' -Connections 60 -Duration 35 2>&1 | Tee-Object -FilePath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-092156-9e21o\baseline\baseline-attack.log'
    if ('D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-092156-9e21o\.done\baseline-attack.done' -ne '') { Set-Content -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-092156-9e21o\.done\baseline-attack.done' -Value 'ok' -Encoding UTF8 }
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    if ('D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-092156-9e21o\.done\baseline-attack.done' -ne '') { Set-Content -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-092156-9e21o\.done\baseline-attack.done' -Value ('error: ' + $_.Exception.Message) -Encoding UTF8 }
}
Write-Host ''
Write-Host 'Keep this window open for the live demo. Close it manually when finished.' -ForegroundColor Yellow
