#requires -Version 7.6
<#
.SYNOPSIS
  Sync canonical config from gentleman-agent-gh to opencode-global.
  Part of P3 — Autonomous Integration Plan.
.DESCRIPTION
  Sync: agent section, skills paths, permission rules, plugin list.
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

# ── Cross-platform helpers ──────────────────────────────────────────────
. (Join-Path $PSScriptRoot "lib" "platform.ps1")

$gentlemanRoot = if ($env:GENTLEMAN_AGENT_ROOT) { $env:GENTLEMAN_AGENT_ROOT } else { (Get-Item $PSScriptRoot).Parent.FullName }

$canonicalPath = (Join-Path $gentlemanRoot "opencode.json")
$globalConfig  = Get-GlobalConfigDir
$globalPath    = Join-Path $globalConfig "opencode.json"

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
  if ($canonical.PSObject.Properties['skills']) {
    $canonicalSkills = $canonical.skills | ConvertTo-Json -Depth 5 -Compress
    $targetSkills = if ($target.PSObject.Properties['skills']) { $target.skills | ConvertTo-Json -Depth 5 -Compress } else { "null" }
    if ($canonicalSkills -ne $targetSkills) { $changes += "skills" }
  }
  # plugin list (from canonical — replace, don't merge)
  if ($canonical.PSObject.Properties['plugin']) {
    $canonicalPlugin = $canonical.plugin | ConvertTo-Json -Compress
    $targetPlugin = if ($target.PSObject.Properties['plugin']) { $target.plugin | ConvertTo-Json -Compress } else { "null" }
    if ($canonicalPlugin -ne $targetPlugin) { $changes += "plugin" }
  }

  if ($changes.Count -eq 0) {
    $results.Add(@{target=$Label; status="OK"; detail="No changes needed"})
    return
  }

  if ($DryRun) {
    $results.Add(@{target=$Label; status="DRY-RUN"; detail="Would update: $($changes -join ', ')"})
    return
  }

  # Apply changes (use Add-Member for properties that may not exist yet)
  if ($changes -contains "agent")      { $target.agent = $canonical.agent }
  if ($changes -contains "permission") { $target.permission = $canonical.permission }
  if ($changes -contains "skills")     {
    if ($target.PSObject.Properties['skills']) { $target.skills = $canonical.skills }
    else { $target | Add-Member -Name "skills" -Value $canonical.skills -MemberType NoteProperty }
  }
  if ($changes -contains "plugin")     {
    if ($target.PSObject.Properties['plugin']) { $target.plugin = $canonical.plugin }
    else { $target | Add-Member -Name "plugin" -Value $canonical.plugin -MemberType NoteProperty }
  }

  # MCP is NOT synced by design — managed separately by global-setup.ps1

  $target | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $TargetPath -Encoding UTF8
  $results.Add(@{target=$Label; status="SYNCED"; detail="Updated: $($changes -join ', ')"})
}

# ── Execute ──────────────────────────────────────────────────────────────
if ($Target -eq "global") {
  Sync-Config -TargetPath $globalPath -Label "global" -PreserveMCP $false
  if (-not $DryRun) {
    $agentsMdDest = Join-Path $globalConfig "AGENTS.md"
    Copy-Item -LiteralPath (Join-Path $gentlemanRoot "AGENTS.md") $agentsMdDest -Force -ErrorAction SilentlyContinue
    $results.Add(@{target="global-agents-md"; status="SYNCED"; detail="AGENTS.md copied"})
  } else {
    $results.Add(@{target="global-agents-md"; status="DRY-RUN"; detail="Would copy AGENTS.md"})
  }
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
