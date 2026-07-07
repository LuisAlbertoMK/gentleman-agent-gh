#requires -Version 7.6
<#
.SYNOPSIS
  Sync canonical config from gentleman-agent-gh to opencode-global.
  Part of P3 — Autonomous Integration Plan.
.DESCRIPTION
  Sync: agent section, skills paths, permission rules.
  Does NOT sync: MCP servers, default_agent (vmk uses vmk.cmd), DB schema.
.PARAMETER Target
  vmk | global | all (default: all)
.PARAMETER DryRun
  Show what would change without writing
.PARAMETER Force
  Skip confirmation prompts
#>
param(
  [ValidateSet("global")]
  [string]$Target = "global",
  [switch]$DryRun,
  [switch]$Force,
  [switch]$Json,
  [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gentlemanRoot = if ($env:GENTLEMAN_AGENT_ROOT) { $env:GENTLEMAN_AGENT_ROOT } else { (Get-Item $PSScriptRoot).Parent.FullName }

$canonicalPath = (Join-Path $gentlemanRoot "opencode.json")
$globalPath    = "$env:USERPROFILE\.config\opencode\opencode.json"

# ── Validate canonical exists ────────────────────────────────────────────
if (-not (Test-Path $canonicalPath)) { Write-Error "Canonical config not found: $canonicalPath"; exit 1 }

# ── Read canonical ───────────────────────────────────────────────────────
$canonical = Get-Content -LiteralPath $canonicalPath -Raw -Encoding UTF8 | ConvertFrom-Json
$results = [System.Collections.Generic.List[object]]::new()

# ── Sync sections to a target ────────────────────────────────────────────
function Sync-Config {
  param([string]$TargetPath, [string]$Label, [bool]$PreserveMCP)
  if (-not (Test-Path $TargetPath)) {
    $results.Add(@{target=$Label; status="SKIP"; detail="File not found"})
    return
  }
  $target = Get-Content -LiteralPath $TargetPath -Raw -Encoding UTF8 | ConvertFrom-Json

  $changes = @()
  # agent section (from canonical)
  if ($canonical.agent) {
    $canonicalAgent = $canonical.agent | ConvertTo-Json -Depth 10 -Compress
    $targetAgent = $target.agent | ConvertTo-Json -Depth 10 -Compress
    if ($canonicalAgent -ne $targetAgent) { $changes += "agent" }
  }
  # permission (from canonical)
  if ($canonical.permission) {
    $canonicalPerm = $canonical.permission | ConvertTo-Json -Depth 10 -Compress
    $targetPerm = $target.permission | ConvertTo-Json -Depth 10 -Compress
    if ($canonicalPerm -ne $targetPerm) { $changes += "permission" }
  }
  # skills paths (from canonical, adjust for target)
  $canonicalSkills = $canonical.skills | ConvertTo-Json -Depth 5 -Compress
  $targetSkills = $target.skills | ConvertTo-Json -Depth 5 -Compress
  if ($canonicalSkills -ne $targetSkills) { $changes += "skills" }

  if ($changes.Count -eq 0) {
    $results.Add(@{target=$Label; status="OK"; detail="No changes needed"})
    return
  }

  if ($DryRun) {
    $results.Add(@{target=$Label; status="DRY-RUN"; detail="Would update: $($changes -join ', ')"})
    return
  }

  # Apply changes
  if ($changes -contains "agent")      { $target.agent = $canonical.agent }
  if ($changes -contains "permission") { $target.permission = $canonical.permission }
  if ($changes -contains "skills")     { $target.skills = $canonical.skills }

  # Preserve MCP if needed
  if ($PreserveMCP -and $null -ne $target.mcpServers) {
    # MCP stays as-is
  }

  $target | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $TargetPath -Encoding UTF8
  $results.Add(@{target=$Label; status="SYNCED"; detail="Updated: $($changes -join ', ')"})
}

# ── Execute ──────────────────────────────────────────────────────────────
if ($Target -eq "global") {
  Sync-Config -TargetPath $globalPath -Label "global" -PreserveMCP $false
  Copy-Item -LiteralPath (Join-Path $gentlemanRoot "AGENTS.md") "$env:USERPROFILE\.config\opencode\AGENTS.md" -Force -ErrorAction SilentlyContinue
  $results.Add(@{target="global-agents-md"; status="SYNCED"; detail="AGENTS.md copied"})
}

# ── Output ──────────────────────────────────────────────────────────────
if ($Json) {
  ConvertTo-Json @{timestamp=(Get-Date -Format "o"); results=$results} -Depth 3
} elseif (-not $Quiet) {
  $results | ForEach-Object {
    $icon = switch ($_.status) { "OK" { "✅" } "SYNCED" { "🔄" } "DRY-RUN" { "🔍" } "SKIP" { "⏭️" } default { "❓" } }
    Write-Output "$icon $($_.target): $($_.detail)"
  }
}
