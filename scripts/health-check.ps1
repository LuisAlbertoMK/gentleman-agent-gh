#requires -Version 7.6
<#
.SYNOPSIS
  Unified pre-session health check for 3-layer ecosystem (gentleman-vMK, opencode-vMK, opencode-global).
  Checks: junctions, config drift, bridge state, binary, DB schema, MCP status.
  Part of P1 — Autonomous Integration Plan.
#>
param(
  [switch]$AutoRepair,      # Auto-fix broken junctions
  [switch]$Json,            # JSON output for agent consumption
  [switch]$Quiet            # Exit code only, minimal output
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$exitCode = 0
$checks = [System.Collections.Generic.List[object]]::new()

# ── Helper: junction check ───────────────────────────────────────────────
function Test-Junction {
  param([string]$Path, [string]$ExpectedTarget, [string]$Label)
  $result = @{check = $Label; status = "OK"; detail = ""}
  if (Test-Path $Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.LinkType -ne "Junction") {
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

function Repair-Junction {
  param([string]$Path, [string]$Target, [string]$Label)
  if (Test-Path $Path) {
    Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue
  }
  $parent = Split-Path $Path -Parent
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  New-Item -ItemType Junction -Path $Path -Target $Target -Force | Out-Null
  Write-Output "[repair] $Label → $Target"
}

# ── Check 1: vmk skills junction ────────────────────────────────────────
$check1 = Test-Junction -Path "D:\opencode\.vmk-config\skills" `
  -ExpectedTarget "D:\gentleman-agent-gh\.agents\skills" `
  -Label "vmk-skills-junction"
if ($check1.status -eq "FAIL" -and $AutoRepair) {
  Repair-Junction -Path "D:\opencode\.vmk-config\skills" `
    -Target "D:\gentleman-agent-gh\.agents\skills" `
    -Label "vmk-skills"
  $check1 = Test-Junction -Path "D:\opencode\.vmk-config\skills" `
    -ExpectedTarget "D:\gentleman-agent-gh\.agents\skills" `
    -Label "vmk-skills-junction"
}
$checks.Add($check1)
if ($check1.status -eq "FAIL") { $exitCode = 2 }

# ── Check 2: vmk prompts junction ───────────────────────────────────────
$check2 = Test-Junction -Path "D:\opencode\prompts\sdd" `
  -ExpectedTarget "D:\gentleman-agent-gh\prompts\sdd" `
  -Label "vmk-prompts-junction"
if ($check2.status -eq "FAIL" -and $AutoRepair) {
  Repair-Junction -Path "D:\opencode\prompts\sdd" `
    -Target "D:\gentleman-agent-gh\prompts\sdd" `
    -Label "vmk-prompts"
  $check2 = Test-Junction -Path "D:\opencode\prompts\sdd" `
    -ExpectedTarget "D:\gentleman-agent-gh\prompts\sdd" `
    -Label "vmk-prompts-junction"
}
$checks.Add($check2)
if ($check2.status -eq "FAIL") { $exitCode = 2 }

# ── Check 3: global skills junction ─────────────────────────────────────
$globalSkills = "$env:USERPROFILE\.config\opencode\skills"
if (Test-Path $globalSkills) {
  # Junction or real dir — check first skill
  $sample = Get-ChildItem -LiteralPath $globalSkills -Directory | Select-Object -First 1
  if ($sample) {
    $item = Get-Item $sample.FullName -Force
    if ($item.LinkType -eq "Junction") {
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

# ── Check 4: vMK binary ─────────────────────────────────────────────────
$vmkBinary = "D:\opencode\packages\opencode\dist\opencode-windows-x64\bin\opencode-vMK.exe"
if (Test-Path $vmkBinary) {
  $ver = & $vmkBinary --version 2>&1 | Out-String
  $checks.Add(@{check = "vmk-binary"; status = "OK"; detail = "$vmkBinary → $($ver.Trim())"})
} else {
  $checks.Add(@{check = "vmk-binary"; status = "FAIL"; detail = "Binary not found at $vmkBinary"})
  $exitCode = 2
}

# ── Check 5: DB schema (replacement_seq + revision) ─────────────────────
$dbPath = "D:\opencode\.vmk-data\opencode.db"
$dbIssues = @()
if (Test-Path $dbPath) {
  $schema = sqlite3 $dbPath ".schema session_context_epoch" 2>&1
  if ($schema -match "replacement_seq") { $dbIssues += "replacement_seq ✅" }
  else { $dbIssues += "replacement_seq ❌" }
  if ($schema -match "revision") { $dbIssues += "revision ✅" }
  else { $dbIssues += "revision ❌" }
  if ($dbIssues -match "❌") {
    $checks.Add(@{check = "db-schema"; status = "FAIL"; detail = "Missing columns: $($dbIssues -join ', ')" })
    $exitCode = 2
  } else {
    $checks.Add(@{check = "db-schema"; status = "OK"; detail = "All columns present ✅" })
  }
} else {
  $checks.Add(@{check = "db-schema"; status = "WARN"; detail = "DB not found at $dbPath (first run?)" })
  if ($exitCode -lt 1) { $exitCode = 1 }
}

# ── Check 6a: Bridge new entries (per-agent checkpoint) ────────────────
$checkpointFile = "D:\TEMP\.bridge-checkpoint.gentleman-vmk"
$bridgeJsonl = "D:\TEMP\opencode-bridge.jsonl"
if (Test-Path $bridgeJsonl) {
  $lastOffset = if (Test-Path $checkpointFile) { [long](Get-Content $checkpointFile -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+' }) } else { 0L }
  $currentSize = (Get-Item $bridgeJsonl).Length
  if ($currentSize -gt $lastOffset) {
    $checks.Add(@{check = "bridge-new-entries"; status = "INFO"; detail = "New bridge messages since last checkpoint (offset $lastOffset → $currentSize bytes). Run 'bridge.ps1 -Command checkpoint -Source gentleman-vmk' to read." })
  } else {
    $checks.Add(@{check = "bridge-new-entries"; status = "OK"; detail = "No new messages ✅" })
  }
}

# ── Check 6b: Bridge file state ─────────────────────────────────────────
$bridgeMd = "D:\TEMP\opencode-error-analysis-report.md"
$bridgeJsonl = "D:\TEMP\opencode-bridge.jsonl"
$openItems = 0
if (Test-Path $bridgeMd) {
  $openCount = @(Select-String -Path $bridgeMd -Pattern "\*\*Abierto\*\*" -SimpleMatch).Count
  $openItems += $openCount
}
if (Test-Path $bridgeJsonl) {
  $jsonlLines = Get-Content $bridgeJsonl -ErrorAction SilentlyContinue
  if ($jsonlLines) {
    $jsonlOpen = $jsonlLines | ForEach-Object { try { $_ | ConvertFrom-Json -ErrorAction Stop } catch {} } |
      Where-Object { $null -ne $_ -and $_.PSObject.Properties.Name -contains 'status' -and $_.status -eq "open" } |
      Measure-Object | Select-Object -ExpandProperty Count
    $openItems += $jsonlOpen
  }
}
if ($openItems -gt 0) {
  $checks.Add(@{check = "bridge-items"; status = "WARN"; detail = "$openItems open item(s)" })
  if ($exitCode -lt 1) { $exitCode = 1 }
} else {
  $checks.Add(@{check = "bridge-items"; status = "OK"; detail = "No open items ✅" })
}

# ── Output ──────────────────────────────────────────────────────────────
if ($Json) {
  ConvertTo-Json @{
    timestamp = (Get-Date -Format "o")
    version   = "1.0.0"
    checks    = $checks
    exitCode  = $exitCode
  } -Depth 3
} elseif (-not $Quiet) {
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
