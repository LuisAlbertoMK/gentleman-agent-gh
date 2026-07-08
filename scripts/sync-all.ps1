#requires -Version 7.6
<#
.SYNOPSIS
  Run global-setup + sync-vmk in sequence — full global sync in one shot.
.DESCRIPTION
  1. global-setup.ps1 -Force — AGENTS.md, prompts, scripts, MCPs, junctions, registry
  2. sync-vmk.ps1 -Force — opencode.json agent/permission/skills sections
.PARAMETER Json
  JSON output for agent consumption
.PARAMETER Quiet
  Minimal output
.EXAMPLE
  .\scripts\sync-all.ps1
.EXAMPLE
  .\scripts\sync-all.ps1 -Json
#>
param([switch]$Json,[switch]$Quiet)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$globalSetup = Join-Path $repoRoot "scripts\global-setup.ps1"
$syncVmk    = Join-Path $repoRoot "scripts\sync-vmk.ps1"
$results = [System.Collections.Generic.List[object]]::new()
$ok = $true

# ── Step 1: global-setup ──────────────────────────────────────────────────
if (Test-Path $globalSetup) {
    try {
        if ($Json) {
            $out = & $globalSetup -Force -Json 2>&1
            $results.Add(@{step="global-setup"; status="OK"; detail="Completed"})
        } else {
            & $globalSetup -Force -Quiet:$Quiet
            $results.Add(@{step="global-setup"; status="OK"; detail="Completed"})
        }
    } catch {
        $results.Add(@{step="global-setup"; status="FAIL"; detail=$_.Exception.Message})
        $ok = $false
    }
} else {
    $results.Add(@{step="global-setup"; status="SKIP"; detail="Script not found"})
}

# ── Step 2: sync-vmk ──────────────────────────────────────────────────────
if (Test-Path $syncVmk) {
    try {
        & $syncVmk -Force -Quiet:$Quiet
        $results.Add(@{step="sync-vmk"; status="OK"; detail="Completed"})
    } catch {
        $results.Add(@{step="sync-vmk"; status="FAIL"; detail=$_.Exception.Message})
        $ok = $false
    }
} else {
    $results.Add(@{step="sync-vmk"; status="SKIP"; detail="Script not found"})
}

# ── Output ────────────────────────────────────────────────────────────────
if ($Json) {
    ConvertTo-Json @{
        timestamp = (Get-Date -Format "o")
        results   = $results
        success   = $ok
    } -Depth 3
} elseif (-not $Quiet) {
    Write-Output "`n═══════ SYNC-ALL COMPLETE ═══════"
    $results | ForEach-Object {
        $icon = switch ($_.status) { "OK" { "✅" } "SKIP" { "⏭️" } "FAIL" { "❌" } default { "❓" } }
        Write-Output "$icon $($_.step): $($_.detail)"
    }
    if (-not $ok) { Write-Output "⚠️  Some steps failed — check output above" }
}
exit $(if ($ok) { 0 } else { 1 })
