#Requires -Module @{ModuleName='PSScriptAnalyzer'; ModuleVersion='1.20.0'}
<#
.SYNOPSIS
    Self-Healing PSSA Gate - run PSScriptAnalyzer, auto-fix safe violations, report remainder.
.DESCRIPTION
    Modes:
      Check   (default) - scan and report violations grouped by auto-fixability.
      Fix     - auto-fix safe categories (BOM encoding, switch defaults), then report.
      Trend   - compare current violations vs stored baseline, show delta.

    Auto-fixable rules:
      - PSUseBOMForUnicodeEncodedFile        -> convert to UTF-8 with BOM
      - PSAvoidDefaultValueSwitchParameter   -> remove $false default from [switch] params

    Tracked (informational, not auto-fixed):
      - PSAvoidUsingWriteHost                -> intentional for colored interactive output

    Requires manual review:
      - PSUseSingularNouns, PSUseDeclaredVarsMoreThanAssignments,
        PSAvoidUsingBrokenHashAlgorithms, PSUseShouldProcessForStateChangingFunctions,
        PSReviewUnusedParameter
.PARAMETER Mode
    Operation mode: Check, Fix, or Trend.
.PARAMETER Path
    Target directory to scan (defaults to repo root).
.PARAMETER Quiet
    Suppress detailed per-file output, show summary only.
.PARAMETER BaselineFile
    Path to baseline JSON for Trend comparison.
.EXAMPLE
    .\scripts\pssa-gate.ps1 -Mode Check
    .\scripts\pssa-gate.ps1 -Mode Fix
    .\scripts\pssa-gate.ps1 -Mode Trend
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Check', 'Fix', 'Trend')]
    [string]$Mode = 'Check',

    [string]$Path = (Get-Location).Path,

    [switch]$Quiet,

    [string]$BaselineFile = (Join-Path $Path 'docs\metricas\pssa-baseline.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Excluded subdirectories (research/experiments not subject to production rules)
$ExcludedDirs = @(
    'experiments',
    'skills'        # junction to .agents/skills/ — skip to avoid duplicate scanning
)

# -- helpers ----------------------------------------------------------
function Write-Status {
    param([string]$Message)
    if (-not $Quiet) { Write-Host "  $Message" }
}

function Get-PSSAViolation {
    param([string]$TargetPath)
    $resolvedTarget = Resolve-Path $TargetPath
    $results = @(Invoke-ScriptAnalyzer -Path $resolvedTarget -Recurse -Severity Warning, Error 2>$null)
    return $results
}

function Get-FullPath {
    param([string]$ScriptName, [string]$BasePath)
    if ([System.IO.Path]::IsPathRooted($ScriptName)) { return $ScriptName }
    $joined = Join-Path $BasePath $ScriptName
    if (Test-Path $joined) { return (Resolve-Path $joined).Path }
    # Try scripts subdir
    $joined2 = Join-Path (Join-Path $BasePath 'scripts') $ScriptName
    if (Test-Path $joined2) { return (Resolve-Path $joined2).Path }
    # Try relative to current dir
    $joined3 = Join-Path (Get-Location).Path $ScriptName
    if (Test-Path $joined3) { return (Resolve-Path $joined3).Path }
    return $ScriptName
}

# -- auto-fix rules ---------------------------------------------------
$autoFixRules = @(
    'PSUseBOMForUnicodeEncodedFile'
    'PSAvoidDefaultValueSwitchParameter'
)

$trackedRules = @(
    'PSAvoidUsingWriteHost'
)

# -- fix: BOM encoding ------------------------------------------------
function Resolve-BomEncoding {
    param([array]$Violations)
    $fixed = 0
    $seen = @{}
    foreach ($v in $Violations) {
        $fullPath = Get-FullPath -ScriptName $v.ScriptName -BasePath $targetPath
        if ($seen.ContainsKey($fullPath)) { continue }
        $seen[$fullPath] = $true

        $fileBytes = $null
        try {
            $fileBytes = [System.IO.File]::ReadAllBytes($fullPath)
        } catch {
            Write-Warning "  BOM: cannot read $fullPath"
            continue
        }

        # Already has BOM (EF BB BF)?
        $hasBom = ($fileBytes.Length -ge 3 -and $fileBytes[0] -eq 0xEF -and $fileBytes[1] -eq 0xBB -and $fileBytes[2] -eq 0xBF)
        if ($hasBom) {
            Write-Status "  BOM: already present - $fullPath"
            continue
        }

        # Non-ASCII check
        $hasNonAscii = $false
        foreach ($b in $fileBytes) {
            if ($b -gt 127) { $hasNonAscii = $true; break }
        }
        if (-not $hasNonAscii) {
            Write-Status "  BOM: skip (ASCII-only) - $fullPath"
            continue
        }

        try {
            $utf8Bom = [System.Text.Encoding]::UTF8.GetPreamble()
            $text = [System.Text.Encoding]::UTF8.GetString($fileBytes)
            $withBom = $utf8Bom + [System.Text.Encoding]::UTF8.GetBytes($text)
            [System.IO.File]::WriteAllBytes($fullPath, $withBom)
            Write-Status "  BOM: FIXED - $fullPath"
            $fixed++
        } catch {
            Write-Warning "  BOM: ERROR on $fullPath - $_"
        }
    }
    return $fixed
}

# -- fix: switch defaults ---------------------------------------------
function Resolve-SwitchDefault {
    param([array]$Violations)
    $fixed = 0
    $seen = @{}
    foreach ($v in $Violations) {
        $fullPath = Get-FullPath -ScriptName $v.ScriptName -BasePath $targetPath
        $key = "$($fullPath):$($v.Line)"
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true

        $lines = $null
        try {
            $lines = Get-Content -LiteralPath $fullPath
        } catch {
            Write-Warning "  SWITCH: cannot read $fullPath"
            continue
        }

        $lineIdx = $v.Line - 1
        $before = $lines[$lineIdx]

        # Remove = $false from switch params: [switch]$Name = $false -> [switch]$Name
        $after = $before -replace '(\[switch\]\s*\$\w+)\s*=\s*\$(?:false|true)', '$1'

        if ($after -ne $before) {
            $lines[$lineIdx] = $after
            try {
                Set-Content -LiteralPath $fullPath -Value $lines -Encoding UTF8
                Write-Status ("  SWITCH: FIXED - ${fullPath}:$($v.Line)")
                $fixed++
            } catch {
                Write-Warning ("  SWITCH: ERROR on ${fullPath}:$($v.Line) - $_")
            }
        }
    }
    return $fixed
}

# -- baseline persistence ---------------------------------------------
function Save-Baseline {
    param([array]$Results, [int]$AmpersandCount)
    $baseline = @{
        timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        total     = $Results.Count
        byRule    = $Results | Group-Object RuleName | ForEach-Object { @{ rule = $_.Name; count = $_.Count } }
        byFile    = $Results | Group-Object ScriptName | ForEach-Object { @{ file = $_.Name; count = $_.Count } }
        autoFixableCount = ($Results | Where-Object { $_.RuleName -in $autoFixRules }).Count
        trackedCount     = ($Results | Where-Object { $_.RuleName -in $trackedRules }).Count
        manualCount      = ($Results | Where-Object { $_.RuleName -notin ($autoFixRules + $trackedRules) }).Count
        ampersandCount   = $AmpersandCount
    }
    $dir = Split-Path $BaselineFile -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $baseline | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $BaselineFile -Encoding UTF8
    return $baseline
}

function Read-Baseline {
    if (Test-Path $BaselineFile) {
        return Get-Content -LiteralPath $BaselineFile -Raw | ConvertFrom-Json
    }
    return $null
}

# =====================================================================
# MAIN
# =====================================================================

$targetPath = Resolve-Path $Path

if (-not $Quiet) {
    Write-Host "================================"
    Write-Host "  PSSA Gate - Mode: $Mode"
    Write-Host "  Target: $targetPath"
    Write-Host "================================"
}

# 1. Run analysis
Write-Status "Running PSScriptAnalyzer..."
$results = Get-PSSAViolation -TargetPath $targetPath

if ($Mode -eq 'Fix') {
    Write-Host "`n-- Auto-fix phase --"
    $bomFixed = Resolve-BomEncoding -Violations ($results | Where-Object { $_.RuleName -eq 'PSUseBOMForUnicodeEncodedFile' })
    $swFixed = Resolve-SwitchDefault -Violations ($results | Where-Object { $_.RuleName -eq 'PSAvoidDefaultValueSwitchParameter' })
    Write-Host "  BOM fixes: $bomFixed | Switch fixes: $swFixed"

    # Re-run after fixes
    Write-Status "Re-running PSSA after fixes..."
    $results = Get-PSSAViolation -TargetPath $targetPath
}

# 2. Categorize
$autoFixable = @($results | Where-Object { $_.RuleName -in $autoFixRules })
$tracked     = @($results | Where-Object { $_.RuleName -in $trackedRules })
$manual      = @($results | Where-Object { $_.RuleName -notin ($autoFixRules + $trackedRules) })

# Exclude research/experiment paths from manual count (naming conventions for research code)
$excludedViolations = @($manual | Where-Object {
    $scriptPath = $_.ScriptPath.Replace('\', '/')
    $shouldExclude = $false
    foreach ($dir in $ExcludedDirs) {
        if ($scriptPath -match "/$dir/") { $shouldExclude = $true; break }
    }
    $shouldExclude
})
$manual       = @($manual | Where-Object {
    $scriptPath = $_.ScriptPath.Replace('\', '/')
    $isExcluded = $false
    foreach ($dir in $ExcludedDirs) {
        if ($scriptPath -match "/$dir/") { $isExcluded = $true; break }
    }
    -not $isExcluded
})

# 2b. POSIX-ism scan: detect && in .ps1 scripts (PS5.1 incompatible)
$ampersandViolations = @()
$knownExceptions = @('bash-safe.ps1', 'pssa-gate.ps1')
Get-ChildItem -Path $targetPath -Recurse -Filter '*.ps1' -ErrorAction SilentlyContinue | ForEach-Object {
    $relPath = $_.FullName.Replace($targetPath, '').TrimStart('\')
    $shouldSkip = $false
    foreach ($ex in $knownExceptions) { if ($relPath -match [regex]::Escape($ex)) { $shouldSkip = $true } }
    foreach ($dir in $ExcludedDirs) { if ($relPath -match "^$dir[\\/]") { $shouldSkip = $true } }
    if ($shouldSkip) { return }

    $lines = Get-Content -LiteralPath $_.FullName -ErrorAction SilentlyContinue
    if (-not $lines) { return }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trimmed = $line.Trim()
        # Skip comments and empty lines
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
        # Check for bare && not inside quotes
        if ($trimmed -match '(^|[^""])&&([^""]|$)') {
            $ampersandViolations += [PSCustomObject]@{
                ScriptName = $relPath
                Line = $i + 1
                Text = $trimmed
            }
        }
    }
}
$ampersandCount = $ampersandViolations.Count

# 3. Report
if (-not $Quiet) {
    Write-Host "`n-- Summary --"
    Write-Host "  Total PSSA violations: $($results.Count)"
    Write-Host "  && chaining violations: $($ampersandCount)"
    Write-Host "  Auto-fixable:          $($autoFixable.Count)"
    Write-Host "  Tracked (info):        $($tracked.Count)"
    $excludedCount = @($excludedViolations).Count
    Write-Host "  Excluded (experiments):  $excludedCount"
    Write-Host "  Manual review needed:    $($manual.Count)"

    if ($ampersandCount -gt 0) {
        Write-Host "`n-- && violations (PS5.1 incompatible) --"
        $ampersandViolations | Select-Object ScriptName, Line, Text | Format-Table -AutoSize | Out-String | Write-Host
    }

    if ($manual.Count -gt 0) {
        Write-Host "`n-- Manual review (PSSA) --"
        $manual | Group-Object RuleName | ForEach-Object {
            Write-Host "  $($_.Name): $($_.Count)"
        }
        $manual | Select-Object RuleName, Line, ScriptName | Format-Table -AutoSize | Out-String | Write-Host
    }
}

# 4. Baseline for Trend mode
switch ($Mode) {
    'Trend' {
        $baseline = Save-Baseline -Results $results -AmpersandCount $ampersandCount
        $prev = Read-Baseline
        if ($prev) {
            $delta = $results.Count - $prev.total
            $sign = if ($delta -gt 0) { '+' } else { '' }
            $prevAmp = if ($prev.PSObject.Properties['ampersandCount']) { ($prev.ampersandCount -as [int]) } else { 0 }
            $ampDelta = $ampersandCount - $prevAmp
            $ampSign = if ($ampDelta -gt 0) { '+' } else { '' }
            Write-Host "`n-- Trend --"
            Write-Host "  PSSA violations: $($prev.total) → $($results.Count) | Delta: $sign$delta"
            Write-Host "  && violations:    $($prev.ampersandCount) → $ampersandCount | Delta: $ampSign$ampDelta"
            if ($delta -gt 0 -or $ampDelta -gt 0) { Write-Warning "  Some violations INCREASED" }
            elseif ($delta -lt 0 -and $ampDelta -le 0) { Write-Host "  Violations DECREASED - good!" }
            else { Write-Host "  No change - steady." }
        } else {
            Write-Host "  Baseline saved (no previous data)."
        }
    }
    'Check' {
        if (-not (Test-Path $BaselineFile)) {
            Save-Baseline -Results $results -AmpersandCount $ampersandCount | Out-Null
            Write-Status "Initial baseline saved to $BaselineFile"
        }
    }
}

# 5. Exit code
$exitCode = 0
if ($manual.Count -gt 0 -and $Mode -ne 'Trend') {
    Write-Warning "PSSA Gate: $($manual.Count) violations require manual review."
    $exitCode = 1
}
if ($ampersandCount -gt 0 -and $Mode -ne 'Trend') {
    Write-Warning "PSSA Gate: $ampersandCount && violations found (PS5.1 incompatible). Run '.\scripts\bash-safe.ps1' for usage instead."
    $exitCode = 1
}
if ($exitCode -eq 0) {
    Write-Host "`nPSSA Gate PASSED."
}
exit $exitCode
