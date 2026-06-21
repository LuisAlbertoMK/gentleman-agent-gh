#requires -Version 5.1

<#
.SYNOPSIS
  Check skill drift between canonical source (.agents/skills/) and global config (~/.config/opencode/skills/).
  Also optionally sync agent definitions to global config.
  Detects stale junctions or missing global links.

.DESCRIPTION
  Verifies that all skills in the canonical directory (.agents/skills/) have
  corresponding junctions in the global OpenCode config.
  Returns exit code 0 = all in sync, 1 = drift detected.

.PARAMETER Thorough
  Use content hash comparison (slower but accurate). Default: line count comparison (fast).

.PARAMETER AutoFix
  Create missing global junctions for any skills not linked.

.PARAMETER SyncAgents
  Sync gentleman-deep/codex/quick agent definitions from project opencode.json to global config.
  Makes agents available in every project.

.PARAMETER Json
  Output results as JSON.

.EXAMPLE
  .\scripts\check-skill-drift.ps1
  .\scripts\check-skill-drift.ps1 -Thorough
  .\scripts\check-skill-drift.ps1 -AutoFix
  .\scripts\check-skill-drift.ps1 -SyncAgents
  .\scripts\check-skill-drift.ps1 -Json
#>

param(
  [switch]$Thorough,
  [switch]$AutoFix,
  [switch]$SyncAgents,
  [switch]$Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$canonicalDir = Join-Path -Path $PSScriptRoot -ChildPath "..\.agents\skills"
$globalDir = "$env:USERPROFILE\.config\opencode\skills"
$errors = @()
$warnings = @()
$drifted = @()

if (-not (Test-Path $canonicalDir)) { Write-Error "Canonical skills dir not found: $canonicalDir"; exit 2 }
if (-not (Test-Path $globalDir)) { Write-Error "Global skills dir not found: $globalDir"; exit 2 }

$canonicalSkills = @(Get-ChildItem $canonicalDir -Directory | Where-Object { $_.Name -ne '_shared' })

foreach ($skill in $canonicalSkills) {
  $skillName = $skill.Name
  $canonPath = Join-Path -Path $skill.FullName -ChildPath "SKILL.md"
  $globPath = Join-Path -Path $globalDir -ChildPath "$skillName\SKILL.md"

  if (-not (Test-Path $canonPath)) {
    $errors += [PSCustomObject]@{ Skill=$skillName; Status="CANON_MISSING"; Detail="Canonical has no SKILL.md" }
    continue
  }

  $globalItem = Get-Item (Join-Path -Path $globalDir -ChildPath $skillName) -ErrorAction SilentlyContinue

  if (-not $globalItem) {
    $errors += [PSCustomObject]@{ Skill=$skillName; Status="GLOBAL_MISSING"; Detail="No global dir exists" }
    continue
  }

  if ($globalItem.LinkType -ne "Junction") {
    $warnings += [PSCustomObject]@{ Skill=$skillName; Status="GLOBAL_NOT_JUNCTION"; Detail="Global is a real file, not a junction" }
  }

  # Compare content if not a junction (real file copy could drift)
  if ($globalItem.LinkType -ne "Junction") {
    if ($Thorough) {
      $canonHash = (Get-FileHash -LiteralPath $canonPath -Algorithm SHA256).Hash
      $globHash = (Get-FileHash -LiteralPath $globPath -Algorithm SHA256).Hash
      $match = $canonHash -eq $globHash
    } else {
      $canonLines = (Get-Content $canonPath | Measure-Object -Line).Lines
      $globLines = (Get-Content $globPath | Measure-Object -Line).Lines
      $match = $canonLines -eq $globLines
    }
    if (-not $match) {
      $drifted += [PSCustomObject]@{
        Skill = $skillName
        Status = "DRIFT"
        Detail = if ($Thorough) { "Hash mismatch" } else { "Line count: canonical=$canonLines global=$globLines" }
      }
    }
  }
}

# AutoFix: create missing global junctions
if ($AutoFix) {
  $errorsToFix = @($errors) | Where-Object { $_ -and $_.Status -eq "GLOBAL_MISSING" }
  if (@($errorsToFix).Count -gt 0) {
    Write-Output "Creating $($errorsToFix.Count) missing global junctions..."
    foreach ($e in $errorsToFix) {
      $target = Join-Path -Path $canonicalDir -ChildPath $e.Skill
      $link = Join-Path -Path $globalDir -ChildPath $e.Skill
      New-Item -ItemType Junction -Path $link -Target $target -Force | Out-Null
      Write-Output "  Created: $link -> $target"
    }
    $errors = @($errors) | Where-Object { $_ -and $_.Status -ne "GLOBAL_MISSING" }
  }

  # Also ensure global scripts directory exists as junction
  $globalScriptsDir = "$env:USERPROFILE\.config\opencode\scripts"
  $repoScriptsDir = Join-Path -Path $PSScriptRoot -ChildPath "."
  if (-not (Test-Path $globalScriptsDir)) {
    Write-Output "Creating global scripts junction..."
    New-Item -ItemType Junction -Path $globalScriptsDir -Target $repoScriptsDir -Force | Out-Null
    Write-Output "  Created: $globalScriptsDir -> $repoScriptsDir"
  }
}

# --- Output ---
$result = @{
  timestamp = (Get-Date -Format "o")
  totalSkills = $canonicalSkills.Count
  junctionSkills = ($canonicalSkills | ForEach-Object { $globalItem = Get-Item (Join-Path -Path $globalDir -ChildPath $_.Name) -ErrorAction SilentlyContinue; if ($globalItem -and $globalItem.LinkType -eq "Junction") { $_ } else { $null } } | Measure-Object).Count
  realFileSkills = ($canonicalSkills | ForEach-Object { $globalItem = Get-Item (Join-Path -Path $globalDir -ChildPath $_.Name) -ErrorAction SilentlyContinue; if ($globalItem -and $globalItem.LinkType -ne "Junction") { $_ } else { $null } } | Measure-Object).Count
  warnings = $warnings
  drifted = $drifted
  errors = $errors
  allSynced = ($drifted.Count -eq 0 -and $errors.Count -eq 0 -and $warnings.Count -eq 0)
}

if ($Json) {
  Write-Output ($result | ConvertTo-Json -Depth 3)
} else {
  $warnCount = @($result.warnings)
  $driftCount = @($drifted)
  $errCount = @($errors)

  if ($warnCount.Count -gt 0) {
    Write-Output "`nWARNINGS: $($warnCount.Count)"
    $result.warnings | Format-Table Skill, Status, Detail -AutoSize -ErrorAction SilentlyContinue
  }
  if ($result.allSynced) {
    Write-Output "`nOK ALL $($result.totalSkills) skills in sync!"
    Write-Output "   ($($result.junctionSkills) junctions OK, $($result.realFileSkills) real files verified)"
  } else {
    if ($driftCount.Count -gt 0) {
      Write-Output "`nDRIFT: $($driftCount.Count) skills out of sync"
      $drifted | Format-Table Skill, Status, Detail -AutoSize -ErrorAction SilentlyContinue
    }
    if ($errCount.Count -gt 0) {
      Write-Output "`nERRORS: $($errCount.Count)"
      $errors | Format-Table Skill, Status, Detail -AutoSize -ErrorAction SilentlyContinue
    }
    exit 1
  }
}

# ---- Agent definitions sync ----
function Sync-AgentDefinition {
  <#
    .SYNOPSIS
      Sync gentleman-* agent definitions from project opencode.json to global config.
      Ensures gentleman-deep, gentleman-codex, and gentleman-quick are available
      in every project that this user opens.
  #>
  $projectConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\opencode.json"
  $globalConfigPath = "$env:USERPROFILE\.config\opencode\opencode.json"
  $agentNames = @("gentleman-deep", "gentleman-codex", "gentleman-quick")
  $syncResult = @{}

  Write-Output "`n--- Syncing agent definitions to global config ---"

  if (-not (Test-Path $projectConfigPath)) {
    Write-Warning "No project opencode.json at $projectConfigPath"
    return $syncResult
  }
  if (-not (Test-Path $globalConfigPath)) {
    Write-Warning "No global opencode.json at $globalConfigPath"
    return $syncResult
  }

  $projectRaw = Get-Content $projectConfigPath -Raw
  $globalRaw  = Get-Content $globalConfigPath -Raw
  $projectJson = $projectRaw | ConvertFrom-Json
  $globalJson  = $globalRaw  | ConvertFrom-Json

  # Find which agents need to be added
  $globalAgentNames = $globalJson.agent.PSObject.Properties.Name
  $toAdd = @()
  foreach ($name in $agentNames) {
    if ($globalAgentNames -contains $name) {
      Write-Output "  [synced] '$name' already in global config"
    } elseif ($null -eq $projectJson.agent.$name) {
      Write-Warning "Agent '$name' not found in project opencode.json -- skipping"
    } else {
      $toAdd += $name
    }
  }

  if ($toAdd.Count -eq 0) {
    Write-Output "  -> No changes needed"
    return $syncResult
  }

  # Add missing agents
  foreach ($name in $toAdd) {
    $agentDef = $projectJson.agent.$name
    $globalJson.agent | Add-Member -Name $name -Value $agentDef -MemberType NoteProperty -Force
    Write-Output "  + Added '$name' to global config"
  }

  $globalJson | ConvertTo-Json -Depth 10 | Set-Content -Path $globalConfigPath -Encoding UTF8
  Write-Output "  -> Global config updated: $globalConfigPath"
  return $syncResult
}

# Execute agent sync if requested
if ($SyncAgents) {
  Sync-AgentDefinition
}
