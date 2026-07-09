$Host.UI.RawUI.WindowTitle = 'Demo - Summary'
$ErrorActionPreference = 'Stop'
try {
    Set-Location -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project'
    Write-Host ('=== ' + 'Demo - Summary' + ' ===') -ForegroundColor Cyan
Get-Content -LiteralPath 'D:\Workspace\01-onboarding-training\2026-07-08-gateway-tech-intro\0708project\observability\20260709-011352-9e13o\demo-summary.md' -Encoding UTF8
    if ('' -ne '') { Set-Content -LiteralPath '' -Value 'ok' -Encoding UTF8 }
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    if ('' -ne '') { Set-Content -LiteralPath '' -Value ('error: ' + $_.Exception.Message) -Encoding UTF8 }
}
Write-Host ''
Write-Host 'Keep this window open for the live demo. Close it manually when finished.' -ForegroundColor Yellow
