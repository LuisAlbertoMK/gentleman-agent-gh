#requires -Version 7
<#
.SYNOPSIS
  Verify every analysis doc in docs/mejoras/ is referenced from README.md.
.DESCRIPTION
  Fail-closed freshness gate: reads docs/mejoras/README.md once and checks that
  every *.md candidate (excluding README.md, plan-template.md, mejora-log.md)
  appears as a substring in the README text. Exit 0 only when all docs are indexed.
.PARAMETER MejorasDir
  Path to the docs/mejoras directory. When empty, resolves as sibling of repo root.
.PARAMETER Json
  Output a single JSON line instead of human-readable text.
.EXAMPLE
  pwsh -NoProfile -File scripts/mejoras-index-check.ps1
.EXAMPLE
  pwsh -NoProfile -File scripts/mejoras-index-check.ps1 -Json
#>
param(
    [string]$MejorasDir = "",
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Resolve directory ---
if ([string]::IsNullOrWhiteSpace($MejorasDir)) {
    $MejorasDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'docs' 'mejoras'
}
$MejorasDir = $MejorasDir.TrimEnd('\', '/')

# --- Fail-closed: directory + README must exist ---
if (-not (Test-Path -LiteralPath $MejorasDir -PathType Container)) {
    if ($Json) {
        Write-Output (@{ indexed = 0; total = 0; missing = @(); valid = $false } | ConvertTo-Json -Compress)
    } else {
        Write-Host "X  FAIL: directory not found: $MejorasDir" -ForegroundColor Red
    }
    exit 1
}

$readmePath = Join-Path $MejorasDir 'README.md'
if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
    if ($Json) {
        Write-Output (@{ indexed = 0; total = 0; missing = @(); valid = $false } | ConvertTo-Json -Compress)
    } else {
        Write-Host "X  FAIL: README.md not found: $readmePath" -ForegroundColor Red
    }
    exit 1
}

# --- Gather candidates: *.md minus exclusions ---
$excludes = @('README.md', 'plan-template.md', 'mejora-log.md')
$candidates = Get-ChildItem -Path $MejorasDir -Filter '*.md' -File |
    Where-Object { $excludes -notcontains $_.Name } |
    Sort-Object Name

$total = @($candidates).Count

# --- Read README once (fail-closed on unreadable/locked file) ---
try {
    $readmeText = [IO.File]::ReadAllText($readmePath)
} catch {
    if ($Json) {
        Write-Output (@{ indexed = 0; total = 0; missing = @(); valid = $false } | ConvertTo-Json -Compress)
    } else {
        Write-Host "X  FAIL: cannot read README.md: $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}

# --- Check each candidate ---
$missing = [System.Collections.Generic.List[string]]::new()

foreach ($c in $candidates) {
    if ($readmeText -notmatch [regex]::Escape($c.Name)) {
        $missing.Add($c.Name)
    }
}

$indexed = $total - $missing.Count
$valid = $missing.Count -eq 0

# --- Output ---
if ($Json) {
    $result = @{
        indexed = $indexed
        total   = $total
        missing = $missing.ToArray()
        valid   = $valid
    }
    Write-Output ($result | ConvertTo-Json -Compress)
} else {
    foreach ($m in $missing) {
        Write-Host "X  NOT INDEXED: $m"
    }
    if ($valid) {
        Write-Host "OK  $indexed/$total analysis docs indexed" -ForegroundColor Green
    } else {
        Write-Host "X  $indexed/$total analysis docs indexed" -ForegroundColor Red
    }
}

exit ($valid ? 0 : 1)
