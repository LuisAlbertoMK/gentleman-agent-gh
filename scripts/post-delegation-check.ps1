#requires -Version 7
<#
.SYNOPSIS
    Post-delegation verification — combines git-diff + write-scope + empty-output
    detection into a single MANDATORY check run after every subagent delegation.

.DESCRIPTION
    Wraps three checks into one protocol-enforced gate:
      1. Empty-output detection (delegates to check-subagent-output.ps1)
      2. Write-scope validation (delegates to validate-write-scope.ps1)
      3. Git status summary

    Run after every subagent delegation BEFORE trusting its output.
    Detects silent failures (empty output, scope violations, unexpected files).

.PARAMETER BaseRef
    Git reference to diff against (default: HEAD).

.PARAMETER AllowedPaths
    Regex pattern(s) that modified files must match. If provided, write-scope
    validation runs. If omitted, only empty-output + git status checks run.

.PARAMETER ExpectedFiles
    Filenames that SHOULD appear in the diff (passed to check-subagent-output).

.PARAMETER RepoRoot
    Repository root (default: parent of script dir).

.PARAMETER Quiet
    JSON summary on stdout.

.EXAMPLE
    scripts\post-delegation-check.ps1                           # git diff + empty + scope
    scripts\post-delegation-check.ps1 -AllowedPaths "src/*" -ExpectedFiles "src/utils.ts"
#>
param(
    [string]$BaseRef        = "HEAD",
    [string[]]$AllowedPaths = @(),
    [string[]]$ExpectedFiles = @(),
    [string]$RepoRoot       = $(Split-Path -Parent $PSScriptRoot),
    [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$results = @{
    baseRef      = $BaseRef
    passed       = $true
    checks       = @()
}

# --- 1. Empty-output detection (git diff + expected files) ---
$csoScript = Join-Path $RepoRoot 'scripts\check-subagent-output.ps1'
if (Test-Path $csoScript) {
    $csoArgs = @('-BaseRef', $BaseRef, '-RepoRoot', $RepoRoot, '-Quiet')
    if ($ExpectedFiles) { $csoArgs += '-ExpectedFiles'; $csoArgs += $ExpectedFiles }
    $csoResult = & pwsh -NoProfile -Command "& '$csoScript' $($csoArgs -join ' ')" 2>&1 |
        ConvertFrom-Json -ErrorAction SilentlyContinue
    $csoOk = $csoResult -and $csoResult.status -ne 'FAIL'
    $results.checks += [PSCustomObject]@{
        name   = "empty_output"
        passed = if ($csoResult) { $csoResult.status -ne 'FAIL' } else { $false }
        detail = if ($csoResult) { $csoResult.status } else { "no JSON returned" }
    }
    if (-not $csoOk) { $results.passed = $false }
}

# --- 2. Write-scope validation ---
if ($AllowedPaths) {
    $wsScript = Join-Path $RepoRoot 'scripts\validate-write-scope.ps1'
    if (Test-Path $wsScript) {
        $wsArgs = @('-AllowedPaths', ($AllowedPaths -join ','), '-BaseRef', $BaseRef)
        $wsResult = & pwsh -NoProfile -Command "& '$wsScript' $($wsArgs -join ' ')" 2>&1
        $wsOk = $LASTEXITCODE -eq 0
        $results.checks += [PSCustomObject]@{
            name   = "write_scope"
            passed = $wsOk
            detail = if ($wsOk) { "in scope" } else { "VIOLATION: files outside allowed paths" }
        }
        if (-not $wsOk) { $results.passed = $false }
    }
} else {
    $results.checks += [PSCustomObject]@{ name = "write_scope"; passed = $true; detail = "no AllowedPaths specified (skipped)" }
}

# --- 3. Git status summary ---
$statusRaw = git -C $RepoRoot status --porcelain 2>&1
$changedFiles = @($statusRaw | Where-Object { $_ -and $_ -notmatch '^warning:' } |
    ForEach-Object { ($_ -replace '^\?\?\s+', '' -replace '^[MADRCU?!]+\s+', '').Trim() } |
    Where-Object { $_ })

$results.changed_files = $changedFiles
$results.file_count    = $changedFiles.Count

# --- Output ---
if ($Quiet) {
    $results | ConvertTo-Json -Compress
} else {
    $icon = if ($results.passed) { "OK  " } else { "FAIL" }
    Write-Output "$icon Post-delegation check ($($results.passed ? 'PASS' : 'FAIL')): $($results.file_count) file(s) changed"
    $results.checks | ForEach-Object {
        $c = if ($_.passed) { "  OK  " } else { "  FAIL" }
        Write-Output "$c $($_.name): $($_.detail)"
    }
    if ($results.changed_files) {
        Write-Output "  Files:"
        $results.changed_files | ForEach-Object { Write-Output "    $_" }
    }
    if (-not $results.passed) {
        Write-Output "`n  X  SILENT FAILURE RISK — review before proceeding"
        Write-Output "     See: mejora-log.md:571, RUNBOOK.md:26"
    }
}

exit (if ($results.passed) { 0 } else { 1 })
