#requires -Version 7
<#
.SYNOPSIS
  Expand $import markers in opencode.json — resolves shared deny rules inline.
  (ADR-033 implemented 2026-09-04: -semi injector retired.)
.DESCRIPTION
  Reads opencode.json, finds all "$import" keys in permission.bash blocks,
  reads the referenced JSON files, merges their properties into the parent,
  and writes the expanded result back to opencode.json.
  Safe to run repeatedly — already-expanded files are left unchanged.
.EXAMPLE
  .\scripts\opencode-config\expand-config.ps1
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$configPath = Join-Path $repoRoot "opencode.json"

if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "opencode.json not found at $configPath"
    exit 1
}

$content = Get-Content -LiteralPath $configPath -Raw
$modified = $false

# --- Expand $import markers ---
$importPattern = [regex]::new('(?m)^(\s+)"\$import":\s*"([^"]+)"')

$match = $importPattern.Match($content)
while ($match.Success) {
    $importPath = $match.Groups[2].Value
    $indent = $match.Groups[1].Value

    $absPath = if ([System.IO.Path]::IsPathRooted($importPath)) {
        $importPath
    } else {
        Join-Path $repoRoot $importPath
    }

    if (-not (Test-Path -LiteralPath $absPath)) {
        Write-Warning "Import not found: $importPath (resolved: $absPath)"
        $match = $match.NextMatch()
        continue
    }

    $imported = Get-Content -LiteralPath $absPath -Raw | ConvertFrom-Json
    if (-not $imported) {
        Write-Warning "Empty or invalid import: $importPath"
        $match = $match.NextMatch()
        continue
    }

    $props = @($imported.PSObject.Properties)
    $ruleCount = $props.Count

    $ruleLines = @()
    for ($i = 0; $i -lt $ruleCount; $i++) {
        $prop = $props[$i]
        $comma = if ($i -lt $ruleCount - 1) { "," } else { "" }
        $ruleLines += "$indent`"$($prop.Name)`": `"$($prop.Value)`"$comma"
    }
    $replacement = $ruleLines -join "`r`n"

    $content = $content.Remove($match.Index, $match.Length).Insert($match.Index, $replacement)

    $modified = $true
    if (-not $Quiet) {
        Write-Host "  expanded: $importPath -> $ruleCount rules" -ForegroundColor Green
    }

    $match = $importPattern.Match($content)
}

# --- ADR-033 implemented (2026-09-04): -semi injector RETIRED ---
# scripts/opencode-config/semi-agents.json deleted; opencode.json is now
# solely the output of scripts/lib/generate-opencode-config.js (which skips
# 'semi' at build). This script only expands $import markers. Any legacy
# *-semi keys found in opencode.json are left untouched (stale) — regen
# via the generator to remove them.

if ($modified) {
    # Validate JSON before writing
    try {
        $null = $content | ConvertFrom-Json
    } catch {
        Write-Error "Generated JSON is invalid -- not writing. Error: $_"
        exit 1
    }

    Set-Content -LiteralPath $configPath -Value $content -Encoding UTF8 -NoNewline
    if (-not $Quiet) {
        Write-Host "`n`u{2705} opencode.json expanded and validated" -ForegroundColor Green
    }
} else {
    if (-not $Quiet) {
        Write-Host "`u{2139} No imports found - opencode.json already expanded" -ForegroundColor Yellow
    }
}
