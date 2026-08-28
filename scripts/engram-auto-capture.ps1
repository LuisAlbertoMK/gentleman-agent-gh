#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Tiered engram auto-capture — HIGH immediate, NORMAL batched, LOW windowed.
.DESCRIPTION
    Called after task/subagent completion. Classifies the outcome by level
    and routes to the appropriate capture tier (per engram-protocol SKILL.md):

      HIGH   → engram_mem_save immediate  (decision, bugfix, architecture)
      NORMAL → batched queue, flush every 3 items
      LOW    → windowed queue (cap 10), flush at session-end

    Windowed compaction (JetBrains 2025: window=10 → 50% cost, 0% perf loss):
    when queue exceeds WindowSize, keep latest WindowSize items (observation
    masking). Prevents unbounded growth in long sessions.

    The orchestrator passes structured fields; this script emits a JSON
    action record to stdout so the caller can invoke the MCP tool.

    Batch queue: .learnings/engram-batch.json (gitignored, local only).
    Session-end flush reads the queue in close-session.ps1.

.PARAMETER Level
    HIGH | NORMAL | LOW. Required.
.PARAMETER Type
    Engram type: decision, architecture, bugfix, pattern, discovery, learning, etc.
.PARAMETER Title
    Short searchable title.
.PARAMETER Content
    Structured What/Why/Where/Learned content.
.PARAMETER TopicKey
    Optional topic_key for dedup (e.g. fix/score-cache-hash).
.PARAMETER DryRun
    Preview without writing.
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("HIGH", "NORMAL", "LOW")]
    [string]$Level,

    [Parameter(Mandatory=$true)]
    [string]$Type,

    [Parameter(Mandatory=$true)]
    [string]$Title,

    [Parameter(Mandatory=$true)]
    [string]$Content,

    [string]$TopicKey = "",

    [switch]$DryRun,

    [switch]$Force,

    [int]$WindowSize = 10
,
    [switch]$Quiet,
    [switch]$Json)

Set-StrictMode -Version Latest

. (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")
$repoRoot = Get-GentlemanProjectRoot
$batchFile = Join-Path (Join-Path $repoRoot ".learnings") "engram-batch.json"
$batchThreshold = 3
$compactThreshold = $WindowSize

function Compact-QueueWindow {
    param([array]$Queue, [int]$Window)
    if ($Queue.Count -le $Window) { return $Queue }
    $dropped = $Queue.Count - $Window
    Write-Host "  ⊘ Windowed compaction: $($Queue.Count)→$Window (dropped $dropped oldest)" -ForegroundColor DarkYellow
    return @($Queue | Select-Object -Last $Window)
}

function Write-ActionRecord([string]$action, [hashtable]$payload) {
    $record = [ordered]@{
        action  = $action
        level   = $Level
        payload = $payload
        ts      = (Get-Date -Format "o")
    }
    $record | ConvertTo-Json -Compress | Write-Output
}

function Write-Ledger([string]$levelKey, [int]$contentChars) {
    # Per-agent token ledger (Azure insight #1): track cost per capture tier
    # chars/3.5 heuristic (metricas skill T2). No MCP call, local file only.
    try {
        $ledgerFile = Join-Path (Join-Path $repoRoot ".learnings") "token-ledger.jsonl"
        $estTokens = [math]::Ceiling($contentChars / 3.5)
        $entry = [ordered]@{ ts = (Get-Date -Format "o"); level = $levelKey; type = $Type; tokens = $estTokens; title = $Title }
        ($entry | ConvertTo-Json -Compress) | Add-Content -LiteralPath $ledgerFile -Encoding UTF8
    } catch { Write-Debug "ledger: $($_.Exception.Message)" }
}

$payload = [ordered]@{
    type      = $Type
    title     = $Title
    content   = $Content
    topic_key = $TopicKey
}

switch ($Level) {
    "HIGH" {
        # Immediate: caller invokes engram_mem_save directly
        if ($DryRun) {
            Write-Host "[HIGH] WOULD save immediate: $Title ($Type)" -ForegroundColor Green
            Write-ActionRecord "save_immediate" $payload
        } else {
            # Emit action record — caller pipes to engram_mem_save via MCP
            Write-ActionRecord "save_immediate" $payload
            Write-Ledger "HIGH" $Content.Length
            Write-Host "[HIGH] queued immediate: $Title" -ForegroundColor Green
        }
    }
    "NORMAL" {
        # Batched: append to queue, flush when threshold reached
        $queue = @()
        if (Test-Path -LiteralPath $batchFile) {
            try { $queue = @(Get-Content -LiteralPath $batchFile -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { $queue = @() }
        }
        # Handle single-object vs array from ConvertFrom-Json
        if ($queue -isnot [Array] -and $null -ne $queue) { $queue = @($queue) }

        $entry = [ordered]@{
            level     = "NORMAL"
            type      = $Type
            title     = $Title
            content   = $Content
            topic_key = $TopicKey
            queued_at = (Get-Date -Format "o")
        }

        if ($DryRun) {
            $nextCount = $queue.Count + 1
            Write-Host "[NORMAL] WOULD queue ($nextCount/$batchThreshold): $Title" -ForegroundColor Yellow
            if ($nextCount -ge $batchThreshold) { Write-Host "  → WOULD flush $nextCount items" -ForegroundColor Yellow }
            Write-ActionRecord "queue_normal" $payload
            break
        }

        $learningsDir = Join-Path $repoRoot ".learnings"
        if (-not (Test-Path -LiteralPath $learningsDir)) { New-Item -ItemType Directory -Path $learningsDir -Force | Out-Null }

        $queue += $entry
        $queue = Compact-QueueWindow -Queue $queue -Window $compactThreshold
        $queue | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $batchFile -Encoding UTF8
        Write-Ledger "NORMAL" $Content.Length
        Write-Host "[NORMAL] queued ($($queue.Count)/$batchThreshold, window $compactThreshold): $Title" -ForegroundColor Yellow

        if ($queue.Count -ge $batchThreshold) {
            Write-Host "  → Flushing $($queue.Count) batched items" -ForegroundColor Cyan
            foreach ($item in $queue) {
                $p = [ordered]@{ type = $item.type; title = $item.title; content = $item.content; topic_key = $item.topic_key }
                Write-ActionRecord "flush_batch" $p
            }
            Remove-Item -LiteralPath $batchFile -Force
            Write-Host "  Batch flushed + queue cleared" -ForegroundColor Cyan
        }
    }
    "LOW" {
        # Session-end: append to queue, only flushed at close-session / mem_session_summary
        $queue = @()
        if (Test-Path -LiteralPath $batchFile) {
            try { $queue = @(Get-Content -LiteralPath $batchFile -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { $queue = @() }
        }
        if ($queue -isnot [Array] -and $null -ne $queue) { $queue = @($queue) }

        $entry = [ordered]@{
            level     = "LOW"
            type      = $Type
            title     = $Title
            content   = $Content
            topic_key = $TopicKey
            queued_at = (Get-Date -Format "o")
        }

        if ($DryRun) {
            Write-Host "[LOW] WOULD queue (session-end): $Title" -ForegroundColor DarkGray
            Write-ActionRecord "queue_low" $payload
            break
        }

        $learningsDir = Join-Path $repoRoot ".learnings"
        if (-not (Test-Path -LiteralPath $learningsDir)) { New-Item -ItemType Directory -Path $learningsDir -Force | Out-Null }

        $queue += $entry
        $queue = Compact-QueueWindow -Queue $queue -Window $compactThreshold
        $queue | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $batchFile -Encoding UTF8
        Write-Ledger "LOW" $Content.Length
        Write-Host "[LOW] queued (session-end, $($queue.Count)/$compactThreshold window): $Title" -ForegroundColor DarkGray
        Write-ActionRecord "queue_low" $payload
    }
}
