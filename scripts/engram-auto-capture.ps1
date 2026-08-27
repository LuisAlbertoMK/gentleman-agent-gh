#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Tiered engram auto-capture — HIGH immediate, NORMAL batched, LOW session-end.
.DESCRIPTION
    Called after task/subagent completion. Classifies the outcome by level
    and routes to the appropriate capture tier (per engram-protocol SKILL.md):

      HIGH   → engram_mem_save immediate  (decision, bugfix, architecture)
      NORMAL → batched queue, flush every 3 items
      LOW    → queued for session-end (mem_session_summary + engram-sync)

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

    [switch]$DryRun
)

Set-StrictMode -Version Latest

. (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")
$repoRoot = Get-GentlemanProjectRoot
$batchFile = Join-Path (Join-Path $repoRoot ".learnings") "engram-batch.json"
$batchThreshold = 3

function Write-ActionRecord([string]$action, [hashtable]$payload) {
    $record = [ordered]@{
        action  = $action
        level   = $Level
        payload = $payload
        ts      = (Get-Date -Format "o")
    }
    $record | ConvertTo-Json -Compress | Write-Output
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
        $queue | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $batchFile -Encoding UTF8
        Write-Host "[NORMAL] queued ($($queue.Count)/$batchThreshold): $Title" -ForegroundColor Yellow

        if ($queue.Count -ge $batchThreshold) {
            Write-Host "  → Flushing $($queue.Count) batched items" -ForegroundColor Cyan
            foreach ($item in $queue) {
                $p = [ordered]@{ type = $item.type; title = $item.title; content = $item.content; topic_key = $item.topic_key }
                Write-ActionRecord "flush_batch" $p
            }
            Remove-Item -LiteralPath $batchFile -Force -ErrorAction SilentlyContinue
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
        $queue | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $batchFile -Encoding UTF8
        Write-Host "[LOW] queued (session-end, $($queue.Count) in queue): $Title" -ForegroundColor DarkGray
        Write-ActionRecord "queue_low" $payload
    }
}
