#requires -Version 5.1
<#
.SYNOPSIS
  Expand $import markers in opencode.json — resolves shared deny rules inline.
.DESCRIPTION
  Reads opencode.json, finds all "$import" keys in permission.bash blocks,
  reads the referenced JSON files, merges their properties into the parent,
  and writes the expanded result back to opencode.json.
  Safe to run repeatedly — already-expanded files are left unchanged.
.EXAMPLE
  .\scripts\opencode-config\expand-config.ps1
#>
[CmdletBinding()]
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

# Pattern: match "$import": "..." with leading whitespace capture
$importPattern = [regex]::new('(?m)^(\s+)"\$import":\s*"([^"]+)"')

$match = $importPattern.Match($content)
while ($match.Success) {
    $importPath = $match.Groups[2].Value   # the path
    $indent = $match.Groups[1].Value       # leading whitespace

    # Resolve relative to repo root
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

    # Read the imported JSON
    $imported = Get-Content -LiteralPath $absPath -Raw | ConvertFrom-Json
    if (-not $imported) {
        Write-Warning "Empty or invalid import: $importPath"
        $match = $match.NextMatch()
        continue
    }

    # Count rules
    $props = @($imported.PSObject.Properties)
    $ruleCount = $props.Count

    # Build replacement: each rule on its own line with proper indent + comma
    $ruleLines = @()
    for ($i = 0; $i -lt $ruleCount; $i++) {
        $prop = $props[$i]
        $comma = if ($i -lt $ruleCount - 1) { "," } else { "" }
        $ruleLines += "$indent`"$($prop.Name)`": `"$($prop.Value)`"$comma"
    }
    $replacement = $ruleLines -join "`r`n"

    # Replace the "$import": "..." line with expanded rules
    $content = $content.Remove($match.Index, $match.Length).Insert($match.Index, $replacement)

    $modified = $true
    if (-not $Quiet) {
        Write-Host "  expanded: $importPath → $ruleCount rules" -ForegroundColor Green
    }

    # Re-scan from beginning (positions shifted after replacement)
    $match = $importPattern.Match($content)
}

if ($modified) {
    # Validate JSON before writing
    try {
        $null = $content | ConvertFrom-Json -Depth 10
    } catch {
        Write-Error "Generated JSON is invalid — not writing. Error: $_"
        exit 1
    }

    Set-Content -LiteralPath $configPath -Value $content -Encoding UTF8 -NoNewline
    if (-not $Quiet) {
        Write-Host "`n✅ opencode.json expanded and validated" -ForegroundColor Green
    }
} else {
    if (-not $Quiet) {
        Write-Host "ℹ️ No imports found — opencode.json already expanded" -ForegroundColor Yellow
    }
}
