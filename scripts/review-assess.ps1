#requires -Version 5.1
<#
.SYNOPSIS
    review assess — decide si hay review pendiente tras un work-unit commit.
.DESCRIPTION
    Adaptacion a este repo (sin binario gentle-ai) del `review assess` de upstream v3.4.0.
    Clasifica el diff del candidato (BaseRef) en tiers y devuelve JSON a stdout con el
    siguiente comando verbatim (next_transition) cuando hay review pendiente.
    FAIL-CLOSED por diseno (JD security review BLOCKERs B1/B2):
    - Numstat SIEMPRE via git real. Si git falla (ref invalida, repo roto) el script
      hace throw — nunca devuelve 'passive' silencioso.
    - Estado de consumido: store repo-local .gentleman/review-consumed.json keyed por
      commit sha (resuelto via git rev-parse --verify). Humano-visible en el diff;
      sin env hooks ni temp files globales (no evadible via entorno).
    - High-risk ampliado: opencode.json, scripts/**, *.bat, .github/** (+ preexistentes).
    - 1 archivo non-trivial ya dispara due (slice_budget_reached).
.PARAMETER BaseRef
    Ref base del candidato (default HEAD). Se evalua con git diff --numstat BaseRef.
.PARAMETER CommittedOnly
    Si se indica, compara solo commits (git diff --numstat BaseRef HEAD) ignorando el working tree.
.PARAMETER Agent
    Nombre de agente opcional; se propaga verbatim al next_transition.
.OUTPUTS
    JSON a stdout: {candidate_consumed, review_due, review_due_reason, next_transition}
.EXAMPLE
    pwsh ./scripts/review-assess.ps1 -BaseRef HEAD~1
#>
[CmdletBinding()]
param(
    [string]$BaseRef = 'HEAD',
    [switch]$CommittedOnly,
    [string]$Agent = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-RepoTopLevel {
    $top = & git rev-parse --show-toplevel 2>$null
    $code = $LASTEXITCODE
    if ($code -eq 0 -and $null -ne $top) {
        $first = @($top)[0]
        if (-not [string]::IsNullOrWhiteSpace("$first")) {
            return ("$first").Trim()
        }
    }
    return (Split-Path $PSScriptRoot -Parent)
}

function Get-BaseSha {
    param(
        [string]$Ref
    )
    $sha = & git rev-parse --verify --quiet "$Ref" 2>$null
    $code = $LASTEXITCODE
    if ($code -ne 0 -or $null -eq $sha -or [string]::IsNullOrWhiteSpace("$sha")) {
        throw "review-assess: cannot resolve BaseRef '$Ref' (git rev-parse --verify failed) — fail-closed, refusing silent passive"
    }
    return (("$sha" -split "`r?`n")[0]).Trim()
}

function Get-ConsumedMap {
    param(
        [string]$StorePath
    )
    if (-not (Test-Path -LiteralPath $StorePath)) {
        return @{}
    }
    try {
        $parsed = Get-Content -LiteralPath $StorePath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        throw "review-assess: cannot parse consumed store '$StorePath' — fail-closed: $($_.Exception.Message)"
    }
    $map = @{}
    if ($null -ne $parsed) {
        foreach ($p in $parsed.PSObject.Properties) {
            $map[$p.Name] = $p.Value
        }
    }
    return $map
}

function Get-NumstatLines {
    param(
        [string]$Ref,
        [bool]$Committed
    )
    $gitArgs = @('diff', '--numstat', $Ref, '--')
    if ($Committed) {
        $gitArgs = @('diff', '--numstat', $Ref, 'HEAD', '--')
    }
    $out = & git @gitArgs 2>$null
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        throw "review-assess: git diff --numstat failed for BaseRef '$Ref' (exit $code) — fail-closed, refusing silent passive"
    }
    if ($null -eq $out) {
        return @()
    }
    return @($out)
}

function Test-HighRiskPath {
    param(
        [string]$Path
    )
    $p = $Path
    if ($p -like '*=>*') {
        $sides = $p -split '=>'
        $p = $sides[$sides.Count - 1].Trim().Trim('{', '}', ' ', '"')
    }
    if ($p -like '.githooks/*') {
        return $true
    }
    if ($p -like 'scripts/*') {
        return $true
    }
    if ($p -like '.github/*') {
        return $true
    }
    if ($p -like '*opencode.json') {
        return $true
    }
    if ($p -like '*.bat') {
        return $true
    }
    if ($p -like '*security*') {
        return $true
    }
    if ($p -like '*auth*') {
        return $true
    }
    return $false
}

$baseSha = Get-BaseSha -Ref $BaseRef
$repoTop = Get-RepoTopLevel
$storePath = Join-Path (Join-Path $repoTop '.gentleman') 'review-consumed.json'
$consumedMap = Get-ConsumedMap -StorePath $storePath
$candidateConsumed = $consumedMap.ContainsKey($baseSha)

$numstat = Get-NumstatLines -Ref $BaseRef -Committed $CommittedOnly.IsPresent
$files = @()
foreach ($line in $numstat) {
    if ([string]::IsNullOrEmpty("$line")) {
        continue
    }
    $t = ("$line").Trim()
    if ([string]::IsNullOrEmpty($t)) {
        continue
    }
    $parts = $t -split "`t"
    if ($parts.Count -lt 3) {
        continue
    }
    $raw = $parts[2].Trim()
    if ($raw -like '*=>*') {
        $sides = $raw -split '=>'
        $raw = $sides[$sides.Count - 1].Trim().Trim('{', '}', ' ', '"')
    }
    $files += $raw
}

$nonTrivial = @()
$highRiskHit = $false
foreach ($f in $files) {
    if (Test-HighRiskPath -Path $f) {
        $highRiskHit = $true
    }
    $lower = $f.ToLowerInvariant()
    if (-not $lower.EndsWith('.md') -and -not $lower.EndsWith('.txt')) {
        $nonTrivial += $f
    }
}

$reviewDue = $false
$reason = 'passive'
if ($candidateConsumed) {
    $reason = 'already_reviewed'
}
elseif ($highRiskHit) {
    $reviewDue = $true
    $reason = 'high_risk'
}
elseif ($nonTrivial.Count -ge 1) {
    $reviewDue = $true
    $reason = 'slice_budget_reached'
}
elseif ($files.Count -eq 0) {
    $reason = 'passive'
}
else {
    $reason = 'under_budget'
}

$next = ''
if ($reviewDue) {
    $next = 'pwsh ./scripts/review-status.ps1 -BaseRef ' + $BaseRef
    if (-not [string]::IsNullOrEmpty($Agent)) {
        $next = $next + ' -Agent ' + $Agent
    }
}

$result = [ordered]@{
    candidate_consumed = $candidateConsumed
    review_due         = $reviewDue
    review_due_reason  = $reason
    next_transition    = $next
}
ConvertTo-Json -InputObject $result -Compress | Write-Output
