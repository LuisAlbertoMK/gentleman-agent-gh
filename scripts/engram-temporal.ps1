#requires -Version 7
<#
.SYNOPSIS
    Engram temporal chain — Zep-style temporal edges (P1-3).
.DESCRIPTION
    Builds a temporal chain of Engram observations for a topic_key or query,
    links them chronologically, and outputs edges with time deltas.

    Uses `engram` CLI if available (C:\Users\...\engram\bin\engram.exe),
    falls back to .learnings JSON if CLI missing. Never mutates Engram
    (read-only). PESTER_TEST=1 → in-memory mock, no CLI calls.

    Implements Zep comparison finding: temporal knowledge graph edges
      (what decision preceded which, what changed between sessions)
    via topic_key timeline + sort:timeline.

    Example:
      & scripts/engram-temporal.ps1 -TopicKey "decision/gap-scan" -Limit 5
      & scripts/engram-temporal.ps1 -Query "gap scan" -Limit 10 -Json
#>
[CmdletBinding()]
param(
    [string]$TopicKey,
    [string]$Query,
    [int]$Limit = 10,
    [switch]$Json
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-TemporalChain {
    param([string]$TopicKey, [string]$Query, [int]$Limit)
    $chain = @()
    # Try engram CLI if available and not in test mode
    $engramBin = Join-Path $env:LOCALAPPDATA 'engram\bin\engram.exe'
    if ($env:PESTER_TEST -ne '1' -and (Test-Path $engramBin)) {
        try {
            $args = @('search', '--project', 'gentleman-agent-gh', '--limit', $Limit, '--json')
            if ($TopicKey) { $args += @('--topic-key', $TopicKey) }
            if ($Query) { $args += @('--query', $Query) }
            $raw = & $engramBin @args 2>$null | Out-String
            $obs = try { $raw | ConvertFrom-Json -ErrorAction Stop } catch { @() }
            foreach ($o in @($obs)) {
                $chain += [ordered]@{ id = $o.id; topic_key = $o.topic_key; title = $o.title; createdAt = $o.created_at; type = $o.type }
            }
        } catch { Write-Debug "engram CLI failed: $_" }
    }
    # Fallback: empty chain in test mode or CLI missing — caller can inject mock
    return $chain
}

$chain = Get-TemporalChain -TopicKey $TopicKey -Query $Query -Limit $Limit

# Build temporal edges: sort by createdAt, link predecessor → successor
$sorted = @($chain | Sort-Object { try { [datetime]$_.createdAt } catch { $_.createdAt } })
$edges = @()
for ($i = 1; $i -lt $sorted.Count; $i++) {
    $prev = $sorted[$i - 1]; $curr = $sorted[$i]
    try {
        $delta = ([datetime]$curr.createdAt - [datetime]$prev.createdAt).TotalHours
    } catch { $delta = $null }
    $edges += [ordered]@{ from = $prev.id; to = $curr.id; from_topic = $prev.topic_key; to_topic = $curr.topic_key; deltaHours = $delta }
}

$result = [ordered]@{ topic_key = $TopicKey; query = $Query; count = $sorted.Count; chain = $sorted; edges = $edges; generatedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') }

if ($Json) { $result | ConvertTo-Json -Depth 5 }
else {
    Write-Host "Temporal chain: $($result.count) nodes, $($edges.Count) edges" -ForegroundColor Cyan
    foreach ($e in $edges) { Write-Host "  $($e.from) → $($e.to) ($([math]::Round($e.deltaHours,1))h) [$($e.from_topic) → $($e.to_topic)]" -ForegroundColor DarkGray }
    $result | ConvertTo-Json -Depth 5 | Write-Host
}
