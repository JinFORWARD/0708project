param(
    [Parameter(Mandatory = $true)]
    [string]$RunRoot
)

$ErrorActionPreference = "Stop"

function Read-CsvSafe {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        return @(Import-Csv -LiteralPath $Path)
    }
    return @()
}

function Get-AttackSummary {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "No attack log found." }
    $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8)
    $target = ($lines | Where-Object { $_ -like "Target:*" } | Select-Object -First 1)
    $rounds = @($lines | Where-Object { $_ -match '^\[round ' })
    $closed = @($lines | Where-Object { $_ -like "All slow connections were closed by the server.*" }).Count -gt 0
    $lastRound = if ($rounds.Count -gt 0) { $rounds[-1] } else { "No round output." }
    if ($closed) {
        return "$target; last round: $lastRound; server closed the slow connections."
    }
    return "$target; last round: $lastRound."
}

function Get-HealthSummary {
    param([string]$Path)
    $rows = Read-CsvSafe -Path $Path
    if ($rows.Count -eq 0) { return "No health CSV found." }
    $ok = @($rows | Where-Object { $_.status -eq "200" }).Count
    $elapsed = @($rows | Where-Object { $_.elapsed_ms -match '^\d+$' } | ForEach-Object { [int]$_.elapsed_ms })
    if ($elapsed.Count -gt 0) {
        $min = ($elapsed | Measure-Object -Minimum).Minimum
        $max = ($elapsed | Measure-Object -Maximum).Maximum
        return "$ok/$($rows.Count) health checks returned 200; elapsed ${min}-${max} ms."
    }
    return "$ok/$($rows.Count) health checks returned 200."
}

function Get-MetricsSummary {
    param([string]$Path)
    $rows = Read-CsvSafe -Path $Path
    if ($rows.Count -eq 0) { return "No metrics CSV found." }
    $first = $rows[0]
    $last = $rows[-1]
    return "first total/established=$($first.tcp_connections_total)/$($first.tcp_connections_established); last total/established=$($last.tcp_connections_total)/$($last.tcp_connections_established)."
}

$baselineDir = Join-Path $RunRoot "baseline"
$hardenedDir = Join-Path $RunRoot "hardened"
$summaryPath = Join-Path $RunRoot "demo-summary.md"
$runName = Split-Path -Leaf $RunRoot

$summary = @"
# Demo Test Summary

Run directory: `$runName`

## Baseline

- Attack: $(Get-AttackSummary -Path (Join-Path $baselineDir 'baseline-attack.log'))
- TCP metrics: $(Get-MetricsSummary -Path (Join-Path $baselineDir 'baseline-metrics.csv'))
- Health checks: $(Get-HealthSummary -Path (Join-Path $baselineDir 'baseline-health.csv'))

## Hardened

- Attack: $(Get-AttackSummary -Path (Join-Path $hardenedDir 'hardened-attack.log'))
- TCP metrics: $(Get-MetricsSummary -Path (Join-Path $hardenedDir 'hardened-metrics.csv'))
- Health checks: $(Get-HealthSummary -Path (Join-Path $hardenedDir 'hardened-health.csv'))

## How to explain this result

- Baseline keeps unfinished HTTP request headers alive for longer, so slow connections can occupy the gateway.
- Hardened config uses `client_header_timeout 5s`, so incomplete headers are closed quickly and Nginx returns 408-like timeout records.
- Normal `/health` checks are included to show whether ordinary users are still served during the experiment.
"@

Set-Content -LiteralPath $summaryPath -Encoding UTF8 -Value $summary
Write-Host "Summary written to $summaryPath"
