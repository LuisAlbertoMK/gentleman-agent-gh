#requires -Version 7
<#
.SYNOPSIS
    LCM compression readout — tokens pre/post per level vs watchdog zones (Ronda4 S3, G-d).
.DESCRIPTION
    Reads the LCM DAG and reports, per level (L1/L2/L3): node count, post-compression
    tokens (stored node sizes), pre-compression tokens (resolved pointer bytes ÷ 4,
    same estimator as Add-LcmNode) and the post/pre ratio over pointer-backed nodes.
    Nodes without a resolvable pointer are counted but excluded from the ratio
    (reported as unmeasured — never fail the verdict on suspicion).

    Thresholds (Ronda4 S3 design — documented numbers):
      L1 ≤ 0.35  (design ~20% section summary + slack for small sections)
      L2 ≤ 0.60  (decisions + Engram IDs carry more raw text than L1)
      L3 ≤ 0.15  (pointer-backed: tiny content + lossless ref)
    Verdict PASS when every measured level is within threshold, else WARN.
    With -CurrentTokens/-Budget it also prints the zone readout (zone + expected
    LCM level via ctx-watchdog / Invoke-LcmEscalation) for the YELLOW>40%→RED>80% check.
.EXAMPLE
    pwsh -File scripts/measure-lcm-compression.ps1 -Json
.NOTES
    Read-only: never writes the DAG (Get-LcmDag only creates the file outside
    PESTER_TEST — pass -DagPath to a temp file in tests for full hermeticity).
#>
[CmdletBinding()]
param(
    [string]$DagPath,
    [string]$RepoRoot,
    [int]$Budget = 200000,
    [int]$CurrentTokens = -1,
    [switch]$Json
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) { $RepoRoot = Split-Path $scriptRoot -Parent }
if (-not $DagPath) { $DagPath = Join-Path $RepoRoot '.learnings/lcm-dag.json' }

# Dot-sourcing lcm-dag.ps1 re-binds ITS param defaults ($DagPath/$Budget/$CurrentTokens)
# in this scope — save/restore first (same pattern as context-watchdog-check.ps1:32-35).
$_savedDagPath = $DagPath; $_savedBudget = $Budget; $_savedTokens = $CurrentTokens; $_savedRoot = $RepoRoot
. (Join-Path $scriptRoot 'lcm-dag.ps1')
$DagPath = $_savedDagPath; $Budget = $_savedBudget; $CurrentTokens = $_savedTokens; $RepoRoot = $_savedRoot
Remove-Variable -Name _savedDagPath, _savedBudget, _savedTokens, _savedRoot -ErrorAction SilentlyContinue

$Thresholds = @{ L1 = 0.35; L2 = 0.60; L3 = 0.15 }

function Measure-LcmCompression {
    [CmdletBinding()]
    param(
        [string]$Path = $DagPath,
        [string]$GitDir = $RepoRoot,
        [string]$Root = $RepoRoot
    )
    $dag = Get-LcmDag -Path $Path
    $nodes = @($dag.nodes)
    $levels = [ordered]@{}
    foreach ($lv in @('L1', 'L2', 'L3')) {
        $lvNodes = @($nodes | Where-Object { $_.level -eq $lv })
        $post = 0
        foreach ($n in $lvNodes) { $post += [int]$n.tokens }
        $preSum = 0; $postMeasured = 0; $measured = 0
        foreach ($n in $lvNodes) {
            if (-not $n.pointer) { continue }
            # Split kind:ref (hash suffix ignored — bytes are canonical); engram
            # without -Content and missing refs resolve ok=$false → unmeasured.
            $b = $null
            try {
                $m = [regex]::Match([string]$n.pointer, '^(?<kind>file|engram|diff):(?<ref>.+?)(?:#sha256:[0-9a-f]{64})?$')
                if ($m.Success) {
                    $b = Get-LcmPointerBytes -Kind $m.Groups['kind'].Value -Ref $m.Groups['ref'].Value -GitDir $GitDir -RepoRoot $Root
                }
            } catch { $b = $null }
            if ($b -and $b.ok -and @($b.bytes).Count -gt 0) {
                $preTokens = [math]::Ceiling(@($b.bytes).Count / 4)
                $preSum += $preTokens; $postMeasured += [int]$n.tokens; $measured++
            }
        }
        $ratio = if ($measured -gt 0 -and $preSum -gt 0) { [math]::Round($postMeasured / $preSum, 3) } else { $null }
        $threshold = $Thresholds[$lv]
        $verdict = if ($null -eq $ratio) { 'n/a' } elseif ($ratio -le $threshold) { 'PASS' } else { 'WARN' }
        $levels[$lv] = [PSCustomObject]@{
            count = $lvNodes.Count; tokensPost = $post; tokensPre = $preSum
            measured = $measured; ratio = $ratio; threshold = $threshold; verdict = $verdict
        }
    }
    $overall = 'PASS'
    foreach ($lv in @('L1', 'L2', 'L3')) { if ($levels[$lv].verdict -eq 'WARN') { $overall = 'WARN' } }
    return [PSCustomObject]@{
        dagPath = $Path; levels = $levels
        totalNodes = $nodes.Count; verdict = $overall; thresholds = $Thresholds
    }
}

$result = Measure-LcmCompression -Path $DagPath

# Zone readout vs YELLOW>40% → RED>80% (best-effort reuse of ctx-watchdog, never throws)
$zone = 'n/a'; $expectedLevel = 'n/a'; $pct = $null
if ($CurrentTokens -ge 0) {
    $pct = if ($Budget -gt 0) { [math]::Round(($CurrentTokens / $Budget) * 100, 1) } else { 0 }
    try {
        $w = & (Join-Path $scriptRoot 'ctx-watchdog.ps1') -UsagePercent ([int][math]::Round($pct)) -Json | ConvertFrom-Json -ErrorAction Stop
        $zone = $w.zone; $expectedLevel = $w.level
    } catch { $zone = 'UNKNOWN'; $expectedLevel = 'UNKNOWN' }
}

$out = [PSCustomObject]@{
    dagPath = $result.dagPath; totalNodes = $result.totalNodes
    l1 = $result.levels['L1']; l2 = $result.levels['L2']; l3 = $result.levels['L3']
    verdict = $result.verdict
    zone = $zone; percent = $pct; expectedLevel = $expectedLevel
}
if ($Json) { $out | ConvertTo-Json -Depth 4 -Compress }
else {
    Write-Host "LCM compression readout — $($result.dagPath) ($($result.totalNodes) nodes) — verdict: $($result.verdict)"
    foreach ($lv in @('L1', 'L2', 'L3')) {
        $r = $result.levels[$lv]
        $ratioTxt = if ($null -eq $r.ratio) { 'n/a (no resolvable pointers)' } else { "$($r.ratio) (≤$($r.threshold))" }
        Write-Host ("  {0}: {1} nodes, post={2} pre={3} measured={4} ratio={5} [{6}]" -f $lv, $r.count, $r.tokensPost, $r.tokensPre, $r.measured, $ratioTxt, $r.verdict)
    }
    if ($CurrentTokens -ge 0) { Write-Host "  zone: $zone at $($pct)% (budget $Budget) — expected LCM level: $expectedLevel" }
}
