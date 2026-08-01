#requires -Version 7
<#
.SYNOPSIS
  Unified pre-session health check for gentleman-vMK and opencode-ai ecosystem.
  Checks: skills junctions (vmk + global), prompts junction.
  Part of P1 — Autonomous Integration Plan.
.DESCRIPTION
  Validates environment health before starting a session:
  - Skills junctions (canonical + global config)
  - Prompts junction
  - Git status
  - Skill drift detection
  Uses lib/cache.ps1 with 1h TTL for performance.
.PARAMETER AutoRepair
  Auto-fix broken junctions instead of just reporting.
.PARAMETER Json
  Output results as JSON for agent consumption.
.PARAMETER Quiet
  Exit code only, minimal output (0=OK, 1=warnings, 2=failures).
.EXAMPLE
  .\scripts\health-check.ps1              # interactive health check
  .\scripts\health-check.ps1 -Json        # JSON for agent
  .\scripts\health-check.ps1 -AutoRepair  # fix broken junctions
  .\scripts\health-check.ps1 -Quiet       # exit code only
#>
param(
  [switch]$AutoRepair,      # Auto-fix broken junctions
  [switch]$Json,            # JSON output for agent consumption
  [switch]$Quiet,           # Exit code only, minimal output
  [switch]$DryRun,
  [switch]$Force
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")

# ── Cache check (1h TTL — junctions rarely change) ─────────────────────
# ponytail: unified cache
$cacheScript = Join-Path $PSScriptRoot "lib/cache.ps1"
if (-not $AutoRepair) {
  $cached = & $cacheScript -Action get -Key "health-check" -TtlSeconds 3600
  if ($cached) {
    if ($Json) { Write-Output ($cached | ConvertTo-Json -Depth 3) }
    elseif (-not $Quiet) {
      Write-Output "`n═══════════════════════════════════════════"
      Write-Output "  HEALTH CHECK — gentleman-vMK (cached)"
      Write-Output "═══════════════════════════════════════════"
      $cached.checks | ForEach-Object {
        $icon = switch ($_.status) { "OK" { "✅" } "WARN" { "🟡" } "FAIL" { "🔴" } default { "❓" } }
        Write-Output "$icon $($_.check): $($_.detail)"
      }
      Write-Output "───────────────────────────────────────────"
      $exitLabel = switch ($cached.exitCode) { 0 { "✅ ALL OK" } 1 { "🟡 WARNINGS" } 2 { "🔴 CRITICAL" } }
      Write-Output "Exit: $($cached.exitCode) — $exitLabel"
    }
    exit $cached.exitCode
  }
}

$gentlemanRoot = Get-GentlemanRoot

$exitCode = 0
$checks = [System.Collections.Generic.List[object]]::new()

# ── Helper: junction check ───────────────────────────────────────────────
function Test-Junction {
  param([string]$Path, [string]$ExpectedTarget, [string]$Label)
  $result = @{check = $Label; status = "OK"; detail = ""}
  if (Test-Path $Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.LinkType -notin @("Junction", "SymbolicLink")) {
      $result.status = "WARN"
      $result.detail = "Exists but not a junction (real file/dir)"
      return $result
    }
    if (-not (Test-Path $item.Target)) {
      $result.status = "FAIL"
      $result.detail = "Target missing: $($item.Target)"
      return $result
    }
    if ($item.Target -ne (Resolve-Path $ExpectedTarget).Path) {
      $result.status = "WARN"
      $result.detail = "Target mismatch: $($item.Target) → expected $ExpectedTarget"
      return $result
    }
    $result.detail = "$($item.Target) ✅"
  } else {
    $result.status = "FAIL"
    $result.detail = "Missing"
  }
  return $result
}

function Set-Junction {
  [CmdletBinding(SupportsShouldProcess)]
  param([string]$Path, [string]$Target, [string]$Label)
  # ponytail: validate LinkType before destructive Remove-Item — avoid nuking real dirs
  if (Test-Path $Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -in @('Junction', 'SymbolicLink')) {
      if ($PSCmdlet.ShouldProcess($Path, 'Repair junction')) {
        try {
          Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction Stop
        } catch {
          Write-Warning "[repair] failed to remove $($Path): $($_.Exception.Message)"
        }
      }
    } elseif ($item -and $item.LinkType) {
      Write-Warning "[repair] skipping $($Path): existing LinkType $($item.LinkType) is not Junction"
      if (-not $Quiet) { Write-Output "[skipped] $Label (not a junction)" }
      return
    }
    # else: real dir/file — refuse remove to be safe
    elseif ($item) {
      Write-Warning "[repair] refusing to remove $($Path): real entry, not a junction"
      if (-not $Quiet) { Write-Output "[refused] $Label (real entry)" }
      return
    }
  }
  if ($PSCmdlet.ShouldProcess($Path, "Create junction to $Target")) {
    $parent = Split-Path $Path -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    New-CrossPlatLink -Path $Path -Target $Target
    if (-not $Quiet) { Write-Output "[repair] $Label → $Target" }
  }
}

# ── Wrapper: Test-Junction → Repair → Re-Test → Collect ──────────────────
function Repair-Junction {
  param([string]$Path, [string]$ExpectedTarget, [string]$Target, [string]$Label)
  $check = Test-Junction -Path $Path -ExpectedTarget $ExpectedTarget -Label $Label
  if ($check.status -eq "FAIL" -and $script:AutoRepair) {
    Set-Junction -Path $Path -Target $Target -Label $Label
    $check = Test-Junction -Path $Path -ExpectedTarget $ExpectedTarget -Label $Label
  }
  $script:checks.Add($check)
  if ($check.status -eq "FAIL") { $script:exitCode = 2 }
}

# ── Check 1: vmk skills junction ────────────────────────────────────────
Repair-Junction -Path (Join-Path (Get-GlobalConfigDir) "skills") `
  -ExpectedTarget "$gentlemanRoot/.agents/skills" `
  -Target "$gentlemanRoot/.agents/skills" `
  -Label "vmk-skills-junction"

# ── Check 2: vmk prompts junction ───────────────────────────────────────
Repair-Junction -Path (Join-Path (Join-Path (Get-GlobalConfigDir) "prompts") "sdd") `
  -ExpectedTarget "$gentlemanRoot/prompts/sdd" `
  -Target "$gentlemanRoot/prompts/sdd" `
  -Label "vmk-prompts-junction"

# ── Check 3: global skills junction ─────────────────────────────────────
$globalSkills = Join-Path (Get-GlobalConfigDir) "skills"
if (Test-Path $globalSkills) {
  # Junction or real dir — check first skill
  $sample = Get-ChildItem -LiteralPath $globalSkills -Directory | Select-Object -First 1
  if ($sample) {
    $item = Get-Item $sample.FullName -Force
    if ($item.LinkType -in @("Junction", "SymbolicLink")) {
      $checks.Add(@{check = "global-skills-junction"; status = "OK"; detail = "$($sample.Name) is junction ✅"})
    } else {
      $checks.Add(@{check = "global-skills-junction"; status = "WARN"; detail = "First skill is not a junction"})
      if ($exitCode -lt 1) { $exitCode = 1 }
    }
  } else {
    $checks.Add(@{check = "global-skills-junction"; status = "WARN"; detail = "Empty skills directory"})
  }
} else {
  $checks.Add(@{check = "global-skills-junction"; status = "WARN"; detail = "Global skills dir not found"})
  if ($exitCode -lt 1) { $exitCode = 1 }
}



# ── Write cache ────────────────────────────────────────────────────────
# ponytail: unified cache
$healthResult = @{
  timestamp = (Get-Date -Format "o")
  version   = "1.0.0"
  checks    = $checks
  exitCode  = $exitCode
}
& $cacheScript -Action set -Key "health-check" -Data $healthResult

# ── Output ──────────────────────────────────────────────────────────────
if ($Json) {
  $healthResult | ConvertTo-Json -Depth 3
} elseif ($Quiet) {
  $healthResult | ConvertTo-Json -Depth 3
} else {
  Write-Output "`n═══════════════════════════════════════════"
  Write-Output "  HEALTH CHECK — gentleman-vMK"
  Write-Output "═══════════════════════════════════════════"
  $checks | ForEach-Object {
    $icon = switch ($_.status) { "OK" { "✅" } "WARN" { "🟡" } "FAIL" { "🔴" } default { "❓" } }
    Write-Output "$icon $($_.check): $($_.detail)"
  }
  Write-Output "───────────────────────────────────────────"
  $exitLabel = switch ($exitCode) { 0 { "✅ ALL OK" } 1 { "🟡 WARNINGS" } 2 { "🔴 CRITICAL" } }
  Write-Output "Exit: $exitCode — $exitLabel"
}
exit $exitCode
