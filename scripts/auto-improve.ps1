#requires -Version 5.1
<#
.SYNOPSIS
    Self-improvement auto-trigger. Scans for code quality issues and fixes them
    via the BabyAGI loop (Phase 2).

.DESCRIPTION
    Phase 3 of the mini-orchestrator. Implements the score -> diagnose -> fix -> verify loop.
    - Score: scan for issues (TODO/FIXME, complexity, test failures)
    - Diagnose: create BabyAGI tasks from issues
    - Fix: execute via babyagi-loop.ps1
    - Verify: async result + convergence check

.PARAMETER AllowedPaths
    Comma-separated path patterns to scan. Required (fail-closed).

.PARAMETER CodeRoot
    Root directory to scan. Default: current directory.

.PARAMETER MaxIterations
    Maximum BabyAGI loop iterations. Default: 3.

.EXAMPLE
    auto-improve.ps1 -AllowedPaths @("src/*,tests/*") -MaxIterations 3
#>
param(
    [Parameter(Mandatory=$true)]
    [string[]]$AllowedPaths,

    [string]$CodeRoot = ".",

    [int]$MaxIterations = 3
,
    [switch]$Quiet,
    [switch]$Json)
Set-StrictMode -Version Latest

# Guardrails -- fail-closed
if (-not $AllowedPaths -or $AllowedPaths.Count -eq 0) {
    Write-Error "FAIL-CLOSED: -AllowedPaths is required. Cannot run auto-improvement without path scope."
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Phase 1: Score (scan for issues) ---
function Scan-Issues {
    param([string[]]$Paths, [string]$Root)
    $issues = @()

    foreach ($pathSpec in $Paths) {
        $resolved = Join-Path $Root $pathSpec
        $files = Get-ChildItem -Path $resolved -Include @("*.ps1","*.ts","*.tsx","*.js","*.py","*.go","*.rs") -Recurse -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match "TODO:|FIXME:") {
                $issues += "Fix TODO/FIXME in $($f.Name)"
            }
            if ($content.Length -gt 500) {
                $lineCount = ($content -split "`n").Count
                if ($lineCount -gt 200) {
                    $issues += "Refactor long file ($lineCount lines): $($f.Name)"
                }
            }
        }
    }

    return $issues
}

# --- Phase 2: Diagnose (create goal from issues) ---
function New-ImprovementGoal {
    param([string[]]$Issues)
    if ($Issues.Count -eq 0) { return $null }
    $combined = $Issues -join "; "
    return "Fix code quality issues: $combined"
}

# --- Phase 3-4: Fix + Verify (via BabyAGI loop) ---
function Start-AutoImprove {
    Write-Host "[Auto-Improve] Scanning for issues in $($AllowedPaths -join ', ')" -ForegroundColor Cyan

    $issues = Scan-Issues -Paths $AllowedPaths -Root $CodeRoot
    Write-Host "[Auto-Improve] Found $($issues.Count) issue(s)" -ForegroundColor Cyan

    if ($issues.Count -eq 0) {
        Write-Host "[Auto-Improve] No issues found. Nothing to improve." -ForegroundColor Green
        return [PSCustomObject]@{ status = "OK"; issues_found = 0; fixed = 0 }
    }

    $goal = New-ImprovementGoal -Issues $issues
    Write-Host "[Auto-Improve] Goal: $goal" -ForegroundColor Yellow

    # Execute via BabyAGI loop (Phase 2)
    $loopScript = Join-Path $ScriptDir "babyagi-loop.ps1"
    if (Test-Path $loopScript) {
        Write-Host "[Auto-Improve] Delegating to BabyAGI loop..." -ForegroundColor Cyan
        & "$scriptDir/babyagi-loop.ps1" -Goal $goal -AllowedPaths $AllowedPaths -MaxIterations $MaxIterations
        $loopExit = $LASTEXITCODE
    } else {
        Write-Warning "[Auto-Improve] babyagi-loop.ps1 not found -- issues detected but not auto-fixed"
        $loopExit = 1
    }

    return [PSCustomObject]@{
        status         = "completed"
        issues_found   = $issues.Count
        goal           = $goal
        loop_exit_code = $loopExit
    }
}

# Execute (skip if running under test mode)
if (-not $env:BABYAGI_TEST_MODE) {
    Start-AutoImprove
}
