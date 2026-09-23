#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
  Read-only audit check for SKILL.md files against docs/skills/audit-checklist.md.
.DESCRIPTION
  Validates rules A1-A4, B1-B3, C1-C3 per skill. READ-ONLY: never writes outside
  the report stream. B1 is syntactic only (generic copy-paste needs 4R human review).
.PARAMETER SkillName
  Single skill directory name to audit.
.PARAMETER All
  Audit all skills under SkillsRoot (excludes _shared).
.PARAMETER SkillsRoot
  Root containing skill directories. Defaults to .agents/skills. Exposed for hermetic tests.
.PARAMETER Json
  Output results as JSON.
.PARAMETER Quiet
  Suppress console output. Implies -Json.
.EXAMPLE
  .\scripts\skills-audit-check.ps1 -SkillName sdd-quick
.EXAMPLE
  .\scripts\skills-audit-check.ps1 -All -Json
#>
param(
  [string]$SkillName = "",
  [switch]$All,
  [string]$SkillsRoot = (Join-Path (Split-Path $PSScriptRoot -Parent) ".agents\skills"),
  [switch]$Json,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($Quiet) { $Json = $true }

function Get-Frontmatter {
  param([string]$Content)
  if ($Content -match '^\s*---\s*\r?\n([\s\S]*?)\r?\n\s*---') { return $matches[1] }
  return $null
}

function Get-Body {
  param([string]$Content)
  if ($Content -match '^\s*---\s*\r?\n[\s\S]*?\r?\n\s*---\s*\r?\n([\s\S]*)$') { return $matches[1] }
  return $Content
}

function Test-AuditSkill {
  param([string]$SkillDir)
  $dirName = Split-Path $SkillDir -Leaf
  $skillFile = Join-Path $SkillDir "SKILL.md"
  $script:_auditResults = @()
  function Add-Rule($id, $pass, $detail) {
    $script:_auditResults += [PSCustomObject]@{ Rule = $id; Pass = $pass; Detail = $detail }
  }
  if (-not (Test-Path $skillFile)) {
    foreach ($id in @('A1-name','A2-description','A3-triggers','A4-structure','B1-anti-rat','B2-red-flags','B3-verification','C1-token-budget','C2-changelog','C3-no-bloat')) {
      Add-Rule $id $false "SKILL.md missing"
    }
    return $script:_auditResults
  }
  $content = [IO.File]::ReadAllText($skillFile)
  $fm = Get-Frontmatter $content
  $body = Get-Body $content

  # A1: name matches directory
  if ($null -ne $fm -and $fm -match 'name:\s*(\S+)') {
    $n = $matches[1].Trim().Trim('"').Trim("'")
    Add-Rule 'A1-name' ($n -eq $dirName) "name='$n' dir='$dirName'"
  } else { Add-Rule 'A1-name' $false "name field missing" }

  # A2: description non-empty, no placeholder
  if ($null -ne $fm -and $fm -match 'description:\s*(.+?)\s*\r?\n') {
    $d = $matches[1].Trim().Trim('"').Trim("'")
    $ok = ($d.Length -ge 10) -and ($d -notmatch 'TODO|FIXME|placeholder|lorem')
    Add-Rule 'A2-description' $ok "len=$($d.Length)"
  } else { Add-Rule 'A2-description' $false "description missing" }

  # A3: triggers non-empty
  if ($null -ne $fm -and $fm -match 'triggers:\s*(.+?)\s*\r?\n') {
    $t = $matches[1].Trim().Trim('"').Trim("'")
    Add-Rule 'A3-triggers' ($t.Length -ge 3) "triggers len=$($t.Length)"
  } else { Add-Rule 'A3-triggers' $false "triggers missing" }

  # A4: structural section + discoverability
  $hasStruct = ($body -match '##\s+(When to Use|Workflow|Rules|Flow|4R|SCAN DIMENSIONS)')
  $hasRefsDir = Test-Path (Join-Path $SkillDir "references")
  $repoRoot = Split-Path (Split-Path $SkillsRoot -Parent) -Parent
  $docsRef = Join-Path (Join-Path $repoRoot "docs\skills") $dirName
  $hasDocsRef = Test-Path $docsRef
  $hasXref = ($body -match 'Cross-Refs|Refs\b|reference\.md|references/')
  $okA4 = $hasStruct -and ($hasRefsDir -or $hasDocsRef -or $hasXref)
  Add-Rule 'A4-structure' $okA4 "struct=$hasStruct refsDir=$hasRefsDir docsRef=$hasDocsRef xref=$hasXref"

  # B1: anti-rationalization table with >=2 data rows
  $okB1 = $false; $rows = 0
  if ($body -match '(?m)^##\s+Anti-Rationalization([\s\S]*?)(?=^##\s|\Z)') {
    $section = $matches[1]
    $rows = ([regex]::Matches($section, '^\s*\|.*\|\s*$', 'Multiline')).Count - 2  # minus header+separator
    if ($rows -lt 0) { $rows = 0 }
    $okB1 = ($rows -ge 2)
  }
  Add-Rule 'B1-anti-rat' $okB1 "dataRows=$rows"

  # B2: red flags with action verb
  $okB2 = $false; $bullets = 0
  if ($body -match '(?m)^##\s+Red Flags([\s\S]*?)(?=^##\s|\Z)') {
    $section = $matches[1]
    $bullets = ([regex]::Matches($section, '^\s*[-*]\s+', 'Multiline')).Count
    $okB2 = ($bullets -ge 1) -and ($section -match 'STOP|force|escalat|BLOCKER|prioritiz|reject|exigir|STOP')
  }
  Add-Rule 'B2-red-flags' $okB2 "bullets=$bullets"

  # B3: verification with executable evidence
  $okB3 = $false; $vbullets = 0
  if ($body -match '(?m)^##\s+Verification([\s\S]*?)(?=^##\s|\Z)') {
    $section = $matches[1]
    $vbullets = ([regex]::Matches($section, '^\s*[-*]\s+', 'Multiline')).Count
    $okB3 = ($vbullets -ge 1) -and ($section -match '`|file:line|\.ps1|matches|contract|hash|resolves')
  }
  Add-Rule 'B3-verification' $okB3 "bullets=$vbullets"

  # C1: token_budget 500-5000
  if ($null -ne $fm -and $fm -match 'token_budget:\s*(\d+)') {
    $tb = [int]$matches[1]
    Add-Rule 'C1-token-budget' (($tb -ge 500) -and ($tb -le 5000)) "token_budget=$tb"
  } else { Add-Rule 'C1-token-budget' $false "token_budget missing" }

  # C2: changelog non-empty
  if ($null -ne $fm -and $fm -match 'changelog:\s*(.+?)\s*\r?\n') {
    $c = $matches[1].Trim().Trim('"').Trim("'")
    Add-Rule 'C2-changelog' ($c.Length -ge 3) "changelog len=$($c.Length)"
  } else { Add-Rule 'C2-changelog' $false "changelog missing" }

  # C3: no bloat <=6KB
  $bytes = [Text.Encoding]::UTF8.GetByteCount($content)
  Add-Rule 'C3-no-bloat' ($bytes -le 6144) "bytes=$bytes"
  return $script:_auditResults
}

$targets = @()
if ($All) {
  $targets = (Get-ChildItem $SkillsRoot -Directory).Where({ $_.Name -ne '_shared' }).FullName
} elseif ($SkillName -ne "") {
  $targets = @(Join-Path $SkillsRoot $SkillName)
} else {
  Write-Error "Specify -SkillName <name> or -All."
  exit 2
}

$report = @()
$failCount = 0
foreach ($t in $targets) {
  $rules = Test-AuditSkill $t
  $fails = @($rules).Where({ -not $_.Pass })
  if ($fails.Count -gt 0) { $failCount++ }
  $report += [PSCustomObject]@{
    Skill = (Split-Path $t -Leaf)
    Passed = (@($rules).Count - $fails.Count)
    Total = (@($rules).Count)
    AllPass = ($fails.Count -eq 0)
    Rules = $rules
  }
}

if ($Json) {
  $report | ConvertTo-Json -Depth 4 | Write-Output
} else {
  foreach ($r in $report) {
    $status = if ($r.AllPass) { "PASS" } else { "FAIL" }
    Write-Output "$status $($r.Skill) ($($r.Passed)/$($r.Total))"
    foreach ($rule in $r.Rules) {
      $mark = if ($rule.Pass) { "  ok" } else { "  XX" }
      Write-Output "$mark $($rule.Rule): $($rule.Detail)"
    }
  }
}
if ($failCount -gt 0) { exit 1 }
