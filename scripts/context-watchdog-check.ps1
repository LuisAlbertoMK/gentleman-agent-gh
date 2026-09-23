#requires -Version 7
<#
.SYNOPSIS
    Context watchdog check — wiring LCM DAG escalation at ORANGE/RED zones (P0-1 parte 3/3).
.DESCRIPTION
    Called by session-checkpoint or manually: checks current token usage vs budget,
    escalates via lcm-dag.ps1, and creates a DAG node when L1/L2/L3 is warranted.

    Implements the 3-boundary rule (Zylos) for the LCM DAG: build DAG node
      (a) before user-facing output — when agent is about to answer
      (b) before irreversible tool exec — git push / Write
      (c) on persistent memory writes — Engram

    PESTER_TEST=1 → dry run (no DAG persistence, returns escalation only).
.NOTES
    Wire point (part 3): session-checkpoint.ps1 calls this at YELLOW/ORANGE thresholds.
    Until that wiring lands, this script is the integration seam and can be called directly:
      & scripts/context-watchdog-check.ps1 -CurrentTokens 145000 -Budget 200000 -Reason "pre-output"
      & scripts/context-watchdog-check.ps1 -CurrentTokens 90000  -Budget 200000 -Reason "pre-push" -Content "summary of session"
#>
[CmdletBinding()]
param(
    [int]$CurrentTokens = 0,
    [int]$Budget = 200000,
    [ValidateSet('pre-output','pre-tool','pre-memory','periodic','manual')][string]$Reason = 'periodic',
    [string]$Content,
    [string]$Pointer
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$_savedTokens = $CurrentTokens; $_savedBudget = $Budget
. (Join-Path $PSScriptRoot 'lcm-dag.ps1')
$CurrentTokens = $_savedTokens; $Budget = $_savedBudget
Remove-Variable -Name _savedTokens, _savedBudget -ErrorAction SilentlyContinue

$escalationLevel = Invoke-LcmEscalation -CurrentTokens $CurrentTokens -Budget $Budget
$pct = if ($Budget -gt 0) { [math]::Round(($CurrentTokens / $Budget) * 100, 1) } else { 0 }

# Periodic below threshold → no node
if ($escalationLevel -eq 'NONE') {
    Write-Host "watchdog: $pct% ($CurrentTokens/$Budget) — $Reason — no escalation" -ForegroundColor DarkGray
    return @{ level = 'NONE'; pct = $pct; created = $false }
}

# Build content if not supplied — level-shaped via lcm-dag.ps1 builders (Ronda4 S2).
if (-not $Content) {
    $seed = "watchdog escalation at $pct% — reason: $Reason"
    switch ($escalationLevel) {
        'L1' { $Content = New-LcmL1Content -Sections @($seed) }
        'L2' { $Content = New-LcmL2Content -Decisions @("escalated to L2 at $pct% — reason: $Reason") }
        default { $Content = "watchdog escalation $escalationLevel at $pct% — reason: $Reason — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" }
    }
}
if ($escalationLevel -eq 'L3' -and -not $Pointer) {
    # Default L3 pointer: current cycle state in canonical hash-verified form
    # (schema §2: kind:ref#sha256:hex64). Best-effort: inter-track.json
    # absent → bare path (unverified, same as pre-S2).
    try { $Pointer = New-LcmL3Pointer -Kind file -Ref '.learnings/inter-track.json' -RepoRoot $repoRoot }
    catch { $Pointer = '.learnings/inter-track.json' }
}

Write-Host "watchdog: $pct% ($CurrentTokens/$Budget) — $Reason — escalate to $escalationLevel" -ForegroundColor Yellow

$created = $false
$node = $null
if ($env:PESTER_TEST -ne '1') {
    # Parent-chain (Ronda 4 S1): chain to the last node of the current cycle so
    # edges[] form parent→child. Best-effort: lookup failure → $null parent (same as before).
    $parentId = $null
    try {
        $chainDag = Get-LcmDag
        $chainCycle = $null
        try { $chainCycle = (Get-Content (Join-Path $repoRoot '.learnings/inter-track.json') -Raw | ConvertFrom-Json).cycle.id } catch {
            Write-Debug "what failed: $($_.Exception.Message)"
        }
        $chainNodes = @($chainDag.nodes)
        if ($chainCycle) { $chainNodes = @($chainNodes | Where-Object { $_.cycle -eq $chainCycle }) }
        if ($chainNodes.Count -gt 0) { $parentId = $chainNodes[-1].id }
    } catch {
        Write-Debug "parent-chain lookup failed: $($_.Exception.Message)"
    }
    $node = Add-LcmNode -Level $escalationLevel -Content $Content -Pointer $Pointer -ParentId $parentId
    $created = $true
    Write-Host "  DAG node: $($node.id) ($escalationLevel, $($node.tokens) tokens, pointer: $($Pointer ?? '—'))" -ForegroundColor Cyan
} else {
    Write-Host "  (PESTER_TEST=1 — dry run, no persistence)" -ForegroundColor DarkGray
}

# 3-boundary instrumentation hint (for Engram/telemetry)
$boundary = switch ($Reason) {
    'pre-output' { '(a) before user output' }
    'pre-tool'   { '(b) before irreversible tool' }
    'pre-memory' { '(c) persistent memory write' }
    default      { '(periodic)' }
}

return @{ level = $escalationLevel; pct = $pct; created = $created; node = $node; boundary = $boundary; pointer = $Pointer }
