#requires -Version 7.6
<#
.SYNOPSIS
  3-way config drift detection between gentleman-agent-gh (canonical),
  opencode-vMK (.vmk-config/), and opencode-global (~/.config/opencode/).
  Part of P3b — Autonomous Integration Plan.
#>
param(
  [switch]$Json,
  [switch]$Quiet,
  [switch]$Fix     # Sync vmk config from canonical (not global)
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Config paths ─────────────────────────────────────────────────────────
$canonicalPath = "D:\gentleman-agent-gh\opencode.json"
$vmkPath       = "D:\opencode\.vmk-config\opencode.json"
$globalPath    = "$env:USERPROFILE\.config\opencode\opencode.json"

$results = [System.Collections.Generic.List[object]]::new()

# ── Helper: hash a JSON section ──────────────────────────────────────────
function Get-SectionHash {
  param([string]$Path, [string[]]$SectionKeys)
  if (-not (Test-Path $Path)) { return @{path = $Path; sections = @{}; error = "File not found"} }
  try {
    $parsed = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    $hashes = @{}
    foreach ($key in $SectionKeys) {
      $section = $parsed.$key
      if ($null -ne $section) {
        $json = ($section | ConvertTo-Json -Depth 10 -Compress)
        $hashes[$key] = [System.BitConverter]::ToString(
          [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($json)
          )
        ).Replace("-", "").Substring(0, 12).ToLower()
      } else {
        $hashes[$key] = $null
      }
    }
    return @{path = $Path; sections = $hashes; error = $null}
  } catch {
    return @{path = $Path; sections = @{}; error = $_.Exception.Message}
  }
}

$sectionKeys = @("agent", "skills", "mcp", "permission")
$canonical = Get-SectionHash -Path $canonicalPath -SectionKeys $sectionKeys
$vmk       = Get-SectionHash -Path $vmkPath -SectionKeys $sectionKeys
$global    = Get-SectionHash -Path $globalPath -SectionKeys $sectionKeys

# ── Compare ──────────────────────────────────────────────────────────────
$totalDrift = 0
foreach ($key in $sectionKeys) {
  $cHash = $canonical.sections[$key]
  $vHash = $vmk.sections[$key]
  $gHash = $global.sections[$key]

  $c_v = ($cHash -eq $vHash) -or ($null -eq $cHash -and $null -eq $vHash)
  $c_g = ($cHash -eq $gHash) -or ($null -eq $cHash -and $null -eq $gHash)

  $drift = @()
  if (-not $c_v) { $drift += "canonical≠vmk"; $totalDrift++ }
  if (-not $c_g) { $drift += "canonical≠global"; $totalDrift++ }

  $status = if ($drift.Count -eq 0) { "OK" } else { "DRIFT" }
  $results.Add(@{
    section  = $key
    status   = $status
    canonical = $cHash
    vmk       = $vHash
    global    = $gHash
    drift     = $drift
  })
}

# ── Fix mode: sync vmk from canonical ────────────────────────────────────
if ($Fix -and $totalDrift -gt 0) {
  Write-Output "[fix] Syncing vmk config from canonical..."
  $canonicalContent = Get-Content -LiteralPath $canonicalPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $vmkContent = @{}
  $vmkContent["`$schema"] = $canonicalContent.'$schema'
  $vmkContent["default_agent"] = $canonicalContent.default_agent
  $vmkContent["skills"] = @{paths = @(".vmk-config/skills/*")}
  $vmkContent["agent"] = $canonicalContent.agent
  # Preserve mcp from vmk's mcp.json, not from canonical or global
  $vmkMCP = "D:\opencode\.vmk-config\mcp.json"
  if (Test-Path $vmkMCP) {
    $mcpData = Get-Content -LiteralPath $vmkMCP -Raw -Encoding UTF8 | ConvertFrom-Json
    $vmkContent["mcpServers"] = $mcpData.mcpServers
  }
  $vmkContent | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $vmkPath -Encoding UTF8
  Write-Output "[fix] vmk config updated → $vmkPath"
}

# ── Output ──────────────────────────────────────────────────────────────
if ($Json) {
  ConvertTo-Json @{
    timestamp = (Get-Date -Format "o")
    version   = "1.0.0"
    files     = @{
      canonical = $canonicalPath
      vmk       = $vmkPath
      global    = $globalPath
    }
    sections  = $results
    totalDrift = $totalDrift
    exitCode  = [Math]::Min($totalDrift, 2)
  } -Depth 4
} elseif (-not $Quiet) {
  Write-Output "`n═══════════════════════════════════════════"
  Write-Output "  CONFIG DRIFT CHECK — 3-way Comparison"
  Write-Output "═══════════════════════════════════════════"
  $results | ForEach-Object {
    $icon = if ($_.status -eq "OK") { "✅" } else { "🔴" }
    Write-Output "$icon $($_.section): $($_.status)"
    if ($_.drift.Count -gt 0) {
      $_.drift | ForEach-Object { Write-Output "   └─ $_" }
    }
    Write-Output "   canonical: $($_.canonical)"
    Write-Output "   vmk:       $($_.vmk)"
    Write-Output "   global:    $($_.global)"
  }
  Write-Output "───────────────────────────────────────────"
  Write-Output "Total drifts: $totalDrift"
}
exit [Math]::Min($totalDrift, 2)
