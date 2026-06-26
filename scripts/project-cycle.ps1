#requires -Version 5.1
<#
.SYNOPSIS
  !pcycle orchestrator — run external project improvement cycle.
.DESCRIPTION
  Pipeline: detect → profile → resolve dimensions → N sub-agents → report → .learnings log.
  Works on ANY project (Node, Go, Python, Rust, .NET, Ruby, PHP).
.PARAMETER Path
  Target project root (default: cwd).
.PARAMETER Focus
  Optional: focus on specific dimension (e.g. "security", "npm_to_pnpm").
.PARAMETER Migrate
  Shortcut: --migrate npm_to_pnpm (implies Focus + migration dimension).
.PARAMETER N
  Override number of sub-agents (default: auto-calculated from file count).
.PARAMETER AnalysisOnly
  Generate report only, do NOT create .learnings entry.
.PARAMETER Quiet
  Output JSON only.
.EXAMPLE
  .\scripts\project-cycle.ps1 -Path ..\my-project
  .\scripts\project-cycle.ps1 -Path ..\my-project -Focus security
  .\scripts\project-cycle.ps1 -Path ..\my-project -Migrate npm_to_pnpm -AnalysisOnly
#>
param(
    [string]$Path = "",
    [string]$Focus = "",
    [string]$Migrate = "",
    [int]$N = 0,
    [switch]$AnalysisOnly,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent

# ── Help ───────────────────────────────────────────────────────
if ($Path -eq "--help" -or $Path -eq "-h") {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# ── 1. Detect project ──────────────────────────────────────────
if (-not $Path) { $Path = (Get-Location).Path }
Write-Host "[!pcycle] Project: $Path" -ForegroundColor Cyan

$projectProfileScript = Join-Path $PSScriptRoot "project-profile.ps1"
if (-not (Test-Path $projectProfileScript)) {
    Write-Host "[!pcycle] ERROR: project-profile.ps1 not found" -ForegroundColor Red
    exit 1
}

$projectProfileJson = & $projectProfileScript -Path $Path -Quiet 2>$null
if (-not $projectProfileJson) {
    Write-Host "[!pcycle] ERROR: could not profile project" -ForegroundColor Red
    exit 1
}
try {
    $projectProfile = $projectProfileJson | ConvertFrom-Json
} catch {
    Write-Host "[!pcycle] ERROR: invalid profile output" -ForegroundColor Red
    exit 1
}

# ── 2. Resolve dimensions ──────────────────────────────────────
$configPath = Join-Path $PSScriptRoot "cycle-config.jsonc"
$dimensions = @()

if (Test-Path $configPath) {
    # Strip comments for JSON parsing
    $configRaw = Get-Content $configPath -Raw
    $configRaw = $configRaw -replace '//.*?(?=\r?\n|$)', '' -replace '/\*.*?\*/', '' -replace '(?m)^\s*$', ''
    try {
        $config = $configRaw | ConvertFrom-Json
        $stack = $projectProfile.stack.type
        $allDims = $config.dimensions

        if ($Migrate -ne "") {
            # Migration mode: find migration dimension + specific migration
            $focus = $Migrate
            # Also set focus trigger
            $hasMigration = $false
            foreach ($d in $allDims) {
                if ($d.id -eq "migration_readiness") { $hasMigration = $true; break }
            }
            if ($hasMigration) {
                $dimensions = @($allDims | Where-Object { $_.id -eq "migration_readiness" })
                # Always include security with migration
                $securityDim = $allDims | Where-Object { $_.id -eq "security" }
                if ($securityDim) { $dimensions = @($dimensions) + @($securityDim) }
                Write-Host "[!pcycle] Mode: migration ($Migrate)" -ForegroundColor Magenta
            }
        }
        elseif ($Focus -ne "") {
            # Focus mode: single dimension
            $dimensions = @($allDims | Where-Object { $_.id -eq $Focus })
            if ($dimensions.Count -eq 0) {
                Write-Host "[!pcycle] WARNING: dimension '$Focus' not found, using defaults" -ForegroundColor Yellow
            }
        }

        # If no dimensions resolved yet, use defaults
        if ($dimensions.Count -eq 0) {
            $defaultIds = $config.default_dimensions
            # Also include stack-specific dims
            $additionalIds = @()
            foreach ($d in $allDims) {
                if ($d.id -in @("dependencies", "testing", "ci_cd")) {
                    $hasStackCheck = ($d.stacks.PSObject.Properties.Name -contains $stack)
                    if ($d.always -or $hasStackCheck) { $additionalIds += $d.id }
                }
            }
            $selectedIds = @($defaultIds) + @($additionalIds) | Select-Object -Unique
            $dimensions = @($allDims | Where-Object { $_.id -in $selectedIds })
        }

        # Calculate N
        if ($N -le 0) {
            $fileCount = [int]$projectProfile.size.files
            $scaling = $config.n_subagent_scaling.by_files
            foreach ($s in $scaling) {
                $max = [int]$s.max
                if ($max -eq -1 -or $fileCount -le $max) {
                    $N = [int]$s.N
                    break
                }
            }
            if ($N -le 0) { $N = 3 }
        }
    } catch {
        Write-Host "[!pcycle] WARNING: config parse error, using defaults" -ForegroundColor Yellow
        $dimensions = @()
        if ($N -le 0) { $N = 3 }
    }
} else {
    if ($N -le 0) { $N = 3 }
}

# Ensure at least one dimension
if ($dimensions.Count -eq 0) {
    # Fallback: create security-only dimension
    $dimensions = @(New-Object PSObject -Property @{
        id = "security"
        label = "Security"
        subagent_prompt = "Audit project security comprehensively."
    })
}

# ── 3. Summary ──────────────────────────────────────────────────
$cycleId = "PCYC-" + (Get-Date -Format "yyyyMMdd") + "-" + (Get-Random -Minimum 100 -Maximum 999)
$stackLabel = $projectProfile.stack.type
$pkgMgr = $projectProfile.stack.pkgManager
$fileCount = $projectProfile.size.files
$loc = $projectProfile.size.loc

if (-not $Quiet) {
    Write-Host "=== !pcycle $cycleId ===" -ForegroundColor Green
    Write-Host "  Project: $($projectProfile.profile.name)" -ForegroundColor White
    Write-Host "  Stack:   $stackLabel / $pkgMgr" -ForegroundColor Yellow
    Write-Host "  Size:    $fileCount files / $loc LOC" -ForegroundColor Gray
    Write-Host "  N:       $N sub-agents" -ForegroundColor Cyan
    Write-Host "  Dims:    $($dimensions.Count) dimensions" -ForegroundColor Magenta
    foreach ($d in $dimensions) { Write-Host "    - $($d.label)" -ForegroundColor DarkCyan }
}

# ── 4. Generate report ──────────────────────────────────────────
$reportDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
$report = @()
$report += "---"
$report += "cycle_id: $cycleId"
$report += "project: $($projectProfile.profile.name)"
$report += "type: external"
$report += "stack: $stackLabel"
$report += "pkg_manager: $pkgMgr"
if ($Migrate -ne "") { $report += "migration: $Migrate" }
$report += "n_subagents: $N"
$report += "status: analysis_only"
$report += "date: $reportDate"
$report += "---"
$report += ""
$report += "# Project Cycle: $($projectProfile.profile.name)"
$report += ""
$report += "**Date**: $((Get-Date).ToString('yyyy-MM-dd'))"
$report += "**Stack**: $stackLabel / $pkgMgr"
$report += "**Size**: $fileCount files / $loc LOC"
$report += "**N sub-agents**: $N"
$report += "**Status**: Analysis complete - ready for execution"
$report += ""
$report += "## Profile"
$report += ""
$report += "| Property | Value |"
$report += "|----------|-------|"
$report += "| Stack | $stackLabel |"
$report += "| Package Manager | $pkgMgr |"
$report += "| Frameworks | $($projectProfile.stack.frameworks -join ', ') |"
$report += "| Test Runner | $($projectProfile.stack.testRunner) |"
$report += "| CI Provider | $($projectProfile.stack.ciProvider) |"
$report += "| Docker | $($projectProfile.stack.hasDocker) |"
$report += "| Files | $fileCount |"
$report += "| LOC | $loc |"
$report += "| Maturity | $($projectProfile.size.maturity) |"
$report += ""
$report += "## Analysis Dimensions"
$report += ""
foreach ($d in $dimensions) {
    $report += "### $($d.label)"
    $report += ""
    $report += "**Sub-agent prompt**: $($d.subagent_prompt)"
    $report += ""
    $hasStack = ($d.stacks.PSObject.Properties | Select-Object -First 1) -ne $null
    if ($hasStack -and ($d.stacks.PSObject.Properties.Name -contains $stackLabel)) {
        $checks = $d.stacks.$stackLabel.checks
        if ($checks) {
            $report += "**Checks**:"
            foreach ($c in $checks) { $report += "- [ ] $c" }
            $report += ""
        }
    }
    if ($Migrate -ne "" -and $d.id -eq "migration_readiness") {
        $migConfig = $d.stacks.node.migrations.$Migrate
        if ($migConfig) {
            $report += "**Migration checks**:"
            foreach ($c in $migConfig.checks) { $report += "- [ ] $c" }
            $report += ""
        }
    }
}
$report += "## Recommendations"
$report += ""
$report += "*(To be filled by sub-agents after analysis execution)*"
$report += ""
$report += "## Decisions"
$report += ""
$report += "*(To be filled)*"
$report += ""
$report += "## Next Steps"
$report += ""
$report += "- Execute sub-agent analysis for each dimension"
$report += "- Merge findings"
$report += "- Fill recommendations above"
$report += "- Run execution cycle if analysis passes review"
$report += ""

# ── 5. Save report ─────────────────────────────────────────────
$cyclesDir = Join-Path $repoRoot "docs\cycles"
if (-not (Test-Path $cyclesDir)) {
    New-Item -ItemType Directory -Path $cyclesDir -Force | Out-Null
}

$dateStr = (Get-Date).ToString("yyyyMMdd")
$slug = $projectProfile.profile.name -replace '[^a-zA-Z0-9-]', '-'
$filename = "cycle-${slug}-${dateStr}.md"
$reportPath = Join-Path $cyclesDir $filename
$report | Out-String | Set-Content -LiteralPath $reportPath -Encoding UTF8
Write-Host "[!pcycle] Report: $reportPath" -ForegroundColor Green

# ── 6. Save .learnings entry ────────────────────────────────────
if (-not $AnalysisOnly) {
    $learningsDir = Join-Path $repoRoot ".learnings\cycles"
    if (-not (Test-Path $learningsDir)) {
        New-Item -ItemType Directory -Path $learningsDir -Force | Out-Null
    }
    $learnFile = "pcyc-${dateStr}-$($projectProfile.profile.name -replace '[^a-zA-Z0-9-]', '-').md"
    $learnPath = Join-Path $learningsDir $learnFile

    $learnEntry = @()
    $learnEntry += "---"
    $learnEntry += "type: project"
    $learnEntry += "cycle_id: $cycleId"
    $learnEntry += "date: $reportDate"
    $learnEntry += "project: $($projectProfile.profile.name)"
    $learnEntry += "stack: $stackLabel"
    $learnEntry += "pkg_manager: $pkgMgr"
    if ($Migrate -ne "") { $learnEntry += "migration: $Migrate" }
    $learnEntry += "status: analysis_only"
    $learnEntry += "---"
    $learnEntry += ""
    $learnEntry += "## Learning Entry"
    $learnEntry += ""
    $learnEntry += "### What"
    $learnEntry += "!pcycle analysis of $($projectProfile.profile.name) ($stackLabel/$pkgMgr, $fileCount files, $loc LOC)"
    $learnEntry += ""
    $learnEntry += "### Decisions"
    $learnEntry += "- N sub-agents: $N"
    $learnEntry += "- Dimensions: $($dimensions.Count) ($($dimensions.label -join ', '))"
    if ($Migrate -ne "") { $learnEntry += "- Migration focus: $Migrate" }
    $learnEntry += ""
    $learnEntry += "### Key Findings"
    $learnEntry += "*(Pending sub-agent execution)*"
    $learnEntry += ""
    $learnEntry += "### Cross-Ref"
    $learnEntry += "- Report: docs/cycles/$filename"
    $learnEntry += ""

    $learnEntry | Out-String | Set-Content -LiteralPath $learnPath -Encoding UTF8
    Write-Host "[!pcycle] Learnings: $learnPath" -ForegroundColor Green
}

# ── 7. Output ──────────────────────────────────────────────────
$result = [PSCustomObject]@{
    cycle_id       = $cycleId
    project        = $projectProfile.profile.name
    stack          = $stackLabel
    pkgManager     = $pkgMgr
    n_subagents    = $N
    dimensions     = @($dimensions | ForEach-Object { $_.id })
    report         = $reportPath
    learnings      = if (-not $AnalysisOnly) { $learnPath } else { $null }
    status         = "analysis_only"
}

if ($Quiet) {
    $result | ConvertTo-Json -Depth 3
} else {
    Write-Host ""
    Write-Host "[!pcycle] Done. Run with N=$N sub-agents to analyze $($dimensions.Count) dimensions." -ForegroundColor Green
    Write-Host "[!pcycle] To execute: review report, then re-run with sub-agent orchestration." -ForegroundColor Yellow
}

exit 0
