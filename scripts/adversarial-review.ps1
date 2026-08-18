#requires -Version 7
<#
.SYNOPSIS
    Adversarial review wrapper — structured findings with severity (pattern R1).

.DESCRIPTION
    Normalizes the commit-time adversarial-breaker scan into a machine-readable
    findings feed with a uniform severity taxonomy (critical/warning/suggestion,
    Cloudflare R1 style) + dedup by (rule, file), and optionally enriches it
    with PSScriptAnalyzer security findings.

    Severity mapping (breaker 'block'/'warn' -> R1 taxonomy):
      block -> critical, warn -> warning. PSScriptAnalyzer findings are
      'suggestion' unless they carry a security rule name.

    Output: JSON array of findings, one per (rule, file) — deduplicated.
    Exit 0 = no criticals; 1 = criticals present; 2 = error.

    Addresses G3 (auto-mejora v3): breaker/adversarial review without
    structured severity. CI can consume this feed to fail on criticals while
    tolerating suggestions.

.EXAMPLE
    ./scripts/adversarial-review.ps1 | ConvertFrom-Json
    ./scripts/adversarial-review.ps1 -SeverityFilter critical
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? '.',
    [string[]]$SeverityFilter = @('critical', 'warning', 'suggestion'),
    [switch]$IncludeAnalyzer,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$findings = [System.Collections.Generic.List[object]]::new()

# --- 1. Adversarial breaker findings (JSON via -Quiet) ---------------------
$breakerOut = & (Join-Path $RepoRoot 'scripts/check-adversarial.ps1') -RepoRoot $RepoRoot -Quiet 2>&1
$breakerJson = $breakerOut | Out-String
try {
    $breaker = $breakerJson | ConvertFrom-Json
} catch {
    # check-adversarial may print progress lines before JSON — salvage the JSON tail
    $jsonStart = $breakerJson.LastIndexOf('{')
    if ($jsonStart -ge 0) {
        $breaker = $breakerJson.Substring($jsonStart) | ConvertFrom-Json
    } else {
        throw "adversarial-review: could not parse breaker output: $breakerJson"
    }
}

foreach ($issue in @($breaker.issues)) {
    $severity = if ($issue.Severity -eq 'block') { 'critical' } else { 'warning' }
    $finding = [PSCustomObject]@{
        severity  = $severity
        rule      = $issue.RuleId
        name      = $issue.Name
        file      = $issue.File
        line      = [int]$issue.Line
        match     = $issue.Match
        remediation = $issue.Remediation
        source    = 'adversarial-breaker'
    }
    $findings.Add($finding)
}

# --- 2. PSScriptAnalyzer enrichment (optional) ------------------------------
if ($IncludeAnalyzer) {
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -AllowClobber
    }
    $analyzerFindings = Invoke-ScriptAnalyzer -Path (Join-Path $RepoRoot 'scripts') -Recurse -Severity Warning, Error -PassThru
    foreach ($af in $analyzerFindings) {
        $severity = if ($af.RuleName -match 'Avoid|Password|PlainText|Credential|InvokeExpression') { 'warning' } else { 'suggestion' }
        $finding = [PSCustomObject]@{
            severity    = $severity
            rule        = $af.RuleName
            name        = $af.RuleName
            file        = $af.ScriptPath.Replace($RepoRoot + [IO.Path]::DirectorySeparatorChar, '')
            line        = [int]$af.Line
            match       = $af.LineText.Trim()
            remediation = $af.Message
            source      = 'PSScriptAnalyzer'
        }
        $findings.Add($finding)
    }
}

# --- 3. Dedup by (rule, file) — keep the first occurrence -------------------
$seen = @{}
$deduped = @()
foreach ($f in $findings) {
    $key = "$($f.rule)|$($f.file)"
    if (-not $seen.ContainsKey($key)) {
        $seen[$key] = $true
        $deduped += $f
    }
}

# --- 4. Filter + emit --------------------------------------------------------
$filtered = $deduped | Where-Object { $SeverityFilter -contains $_.severity }
$criticalCount = @($filtered | Where-Object severity -eq 'critical').Count

if (-not $Quiet) {
    Write-Host "Adversarial review: $($filtered.Count) finding(s) [critical=$(@($filtered | Where-Object severity -eq 'critical').Count), warning=$(@($filtered | Where-Object severity -eq 'warning').Count), suggestion=$(@($filtered | Where-Object severity -eq 'suggestion').Count)]"
}
$filtered | ConvertTo-Json -Depth 5

exit $(if ($criticalCount -gt 0) { 1 } else { 0 })