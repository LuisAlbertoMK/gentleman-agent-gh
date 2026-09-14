#requires -Version 5.1
[CmdletBinding()]
<#
.SYNOPSIS
    Pre-delegation fit gate: validates a planned subagent delegation BEFORE launching it.

.DESCRIPTION
    Mechanical enforcement of the Orchestrator Guard rule (AGENTS.md): T2+
    (>1 file or >20 lines) must never go to gentleman-quick — decompose into
    clusters of <=10 files instead. The post-delegation side is already covered
    by scripts/post-delegation-check.ps1 and scripts/validate-write-scope.ps1;
    this script is the missing PRE side.

    Fail-closed verdict matrix (FAIL patterns checked BEFORE warns; FAIL wins):
      FAIL quick-too-big : quick* agent AND (FileCount > 1 OR LineCount > 20)
      FAIL cluster-over-10 : FileCount > 10 (clusters must be <=10 files)
      WARN domain-reroute : -Domain given AND its specialist exists AND AgentName
                            is not that specialist (base, -sub, -auto variants)
      WARN quick-high-risk : quick* agent AND RiskLevel == high
      WARN over-5-files : FileCount > 5 (suggest chained-pr / work-unit-commits)
      PASS otherwise.

    Domain routing overrides file-count: when a domain specialist exists, the
    delegation should go to it even if the size would otherwise fit quick.

.PARAMETER AgentName
    The intended subagent, e.g. gentleman-quick, gentleman-quick-auto,
    gentleman-codex-sub, gentleman-security-sub. (Mandatory, Position 0.)

.PARAMETER FileCount
    Files the cluster will touch. (Default: 1.)

.PARAMETER LineCount
    Total estimated lines changed. (Default: 0.)

.PARAMETER RiskLevel
    low, medium, or high. (Default: low.)

.PARAMETER Domain
    Optional work domain. Recognized: security, seo, infra, performance,
    frontend, datascience, docs. Unrecognized values are ignored (no reroute).

.PARAMETER Json
    Print {"verdict":"...","reasons":[...],"patterns":[...]} on stdout.

.PARAMETER Quiet
    Print just the verdict.

.EXAMPLE
    & "./scripts/delegation-fit-gate.ps1" -AgentName gentleman-quick -FileCount 93 -LineCount 500
    # VERDICT: FAIL — ... (exit 2, the historic 2026-08-29 incident)

.EXAMPLE
    & "./scripts/delegation-fit-gate.ps1" -AgentName gentleman-codex-sub -FileCount 3 -LineCount 120
    # VERDICT: PASS — ... (exit 0)

.EXAMPLE
    & "./scripts/delegation-fit-gate.ps1" -AgentName gentleman-codex-sub -FileCount 3 -Domain security -Json
    # {"verdict":"WARN",...} (exit 0)
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$AgentName,

    [int]$FileCount = 1,

    [int]$LineCount = 0,

    [ValidateSet('low', 'medium', 'high')]
    [string]$RiskLevel = 'low',

    [string]$Domain = '',

    [switch]$Json,

    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$failHits = @()
$warnHits = @()
$failReasons = @()
$warnReasons = @()

$isQuick = $AgentName -match '^gentleman-quick(-sub)?(-auto)?$'

# ---------- FAIL PATTERNS (checked BEFORE warns) ----------

if ($isQuick -and (($FileCount -gt 1) -or ($LineCount -gt 20))) {
    $failHits += 'quick-too-big'
    $failReasons += 'Orchestrator Guard T2+: never delegate >1 file or >20 lines to a quick agent — decompose into clusters of <=10 files or use a T2+ agent'
}

if ($FileCount -gt 10) {
    $failHits += 'cluster-over-10'
    $failReasons += 'cluster exceeds 10 files — split into clusters of <=10 files before delegating'
}

# ---------- WARN PATTERNS ----------

# Domain routing overrides file-count: each domain maps to its specialist.
$domainSpecialists = @{
    'security'    = 'gentleman-security'
    'seo'         = 'gentleman-seo'
    'infra'       = 'gentleman-infra'
    'performance' = 'gentleman-performance'
    'frontend'    = 'gentleman-frontend'
    'datascience' = 'gentleman-datascience'
    'docs'        = 'gentleman-docs'
}

$domainKey = $Domain.Trim().ToLowerInvariant()
if ($domainKey -and $domainSpecialists.ContainsKey($domainKey)) {
    $specialist = $domainSpecialists[$domainKey]
    $specialistPattern = "^$([regex]::Escape($specialist))(-sub)?(-auto)?$"
    if ($AgentName -notmatch $specialistPattern) {
        $warnHits += 'domain-reroute'
        $warnReasons += ("domain '{0}' should route to {1} (or its -sub/-auto variant), not '{2}'" -f $domainKey, $specialist, $AgentName)
    }
}

if ($isQuick -and ($RiskLevel -eq 'high')) {
    $warnHits += 'quick-high-risk'
    $warnReasons += 'quick agent with high risk — use a T2+ agent instead'
}

if ($FileCount -gt 5) {
    $warnHits += 'over-5-files'
    $warnReasons += 'cluster over 5 files — consider a chained-pr / work-unit-commits split'
}

# ---------- VERDICT (FAIL wins; FAIL output also carries warning patterns) ----------

$verdict = 'PASS'
$reasons = @()
$patterns = @()

if ($failHits.Count -gt 0) {
    $verdict = 'FAIL'
    $reasons = $failReasons
    $patterns = $failHits
    if ($warnHits.Count -gt 0) {
        foreach ($w in $warnHits) { $patterns += $w }
        foreach ($r in $warnReasons) { $reasons += $r }
    }
}
elseif ($warnHits.Count -gt 0) {
    $verdict = 'WARN'
    $reasons = $warnReasons
    $patterns = $warnHits
}
else {
    $reasons = @('fit for delegation')
    $patterns = @()
}

Write-Debug ("delegation-fit-gate agent={0} files={1} lines={2} risk={3} domain={4} verdict={5} patterns={6}" -f $AgentName, $FileCount, $LineCount, $RiskLevel, $Domain, $verdict, ($patterns -join ','))
if ($verdict -eq 'WARN') {
    Write-Warning (($reasons -join '; '))
}

if ($Quiet) {
    Write-Output $verdict
}
elseif ($Json) {
    $obj = [pscustomobject]@{
        verdict  = $verdict
        reasons  = $reasons
        patterns = $patterns
    }
    Write-Output ($obj | ConvertTo-Json -Compress)
}
else {
    $reasonText = $reasons -join '; '
    Write-Output ("VERDICT: {0} — {1}" -f $verdict, $reasonText)
}

if ($verdict -eq 'FAIL') { exit 2 } else { exit 0 }
