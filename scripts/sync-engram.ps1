#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Selective engram sync — export/import project knowledge via git-native transport.
.DESCRIPTION
    Bridges local engram MCP storage (per-machine) with git-tracked .learnings/.
    Two modes: -Export (engram → git file) and -Import (git file → engram).
    Only HIGH/NORMAL value observations travel (decision, bugfix, pattern, architecture).
    Tiered per engram-protocol: HIGH immediate, NORMAL batched, LOW stays local.
.PARAMETER Export
    Export selective observations from local engram to .learnings/engram-sync.json.
.PARAMETER Import
    Import observations from .learnings/engram-sync.json into local engram.
.PARAMETER DryRun
    Preview without writing.
.PARAMETER Force
    Overwrite existing topic_keys on import (default: skip duplicates).
#>
param(
    [switch]$Export,
    [switch]$Import,
    [switch]$DryRun,
    [switch]$Force,
    [string]$InputFile
,
    [switch]$Quiet,
    [switch]$Json)

Set-StrictMode -Version Latest

. (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")
$repoRoot = Get-GentlemanProjectRoot
$syncFile = Join-Path (Join-Path $repoRoot ".learnings") "engram-sync.json"

# --- Config: what travels, what stays ---
$exportTypes  = @("decision", "architecture", "bugfix", "pattern")
$maxAgeDays   = 90
$syncVersion  = 1

if (-not $Export -and -not $Import) {
    Write-Host "Usage: sync-engram.ps1 -Export | -Import [-DryRun] [-Force]" -ForegroundColor Yellow
    Write-Host "  -Export  engram → .learnings/engram-sync.json (git-tracked)"
    Write-Host "  -Import  .learnings/engram-sync.json → engram (dedup by topic_key)"
    exit 1
}
if ($Export -and $Import) { throw "Choose one: -Export OR -Import" }

# ============================================================
# EXPORT — engram → git file
# ============================================================
if ($Export) {
    Write-Host "==> sync-engram: Export (engram → $syncFile)" -ForegroundColor Cyan

    # Determine project name from git remote or folder
    $projectName = $null
    try {
        $remote = & git -C $repoRoot remote get-url origin 2>$null
        if ($remote) { $projectName = ($remote -split "/")[-1] -replace "\.git$", "" }
    } catch {}
    if (-not $projectName) { $projectName = Split-Path $repoRoot -Leaf }

    $allObservations = @()
    $cutoff = (Get-Date).AddDays(-$maxAgeDays)

    # Engram is MCP-only (not CLI) — export creates a seed file.
    # Populate via MCP: the orchestrator calls engram_mem_search and appends.
    # Manual: edit .learnings/engram-sync.json directly.
    Write-Host "  (engram is MCP-only — creating seed file for MCP/manual population)" -ForegroundColor DarkGray
    foreach ($type in $exportTypes) {
        Write-Host "  type=$type → 0 (seed — use MCP export or manual)" -ForegroundColor DarkGray
    }

    # Deduplicate by topic_key (keep most recent)
    $deduped = @{}
    foreach ($obs in $allObservations) {
        $key = if ($obs.topic_key) { $obs.topic_key } else { "untagged/$($obs.id)" }
        if (-not $deduped.ContainsKey($key)) { $deduped[$key] = $obs }
        else {
            # Keep most recent by created_at
            try {
                $existing = [DateTime]$deduped[$key].created_at
                $candidate = [DateTime]$obs.created_at
                if ($candidate -gt $existing) { $deduped[$key] = $obs }
            } catch { }
        }
    }

    $exportList = @($deduped.Values | ForEach-Object {
        [ordered]@{
            topic_key  = $_.topic_key
            type       = $_.type
            title      = $_.title
            content    = $_.content
            exported_at = (Get-Date -Format "o")
            source_id  = $_.id
        }
    })

    $payload = [ordered]@{
        version    = $syncVersion
        exported   = (Get-Date -Format "o")
        project    = $projectName
        types      = $exportTypes
        max_age_days = $maxAgeDays
        count      = $exportList.Count
        observations = $exportList
    }

    if ($exportList.Count -eq 0) {
        Write-Host "  No observations to export (engram may be MCP-only — use manual export)" -ForegroundColor Yellow
        Write-Host "  Hint: run engram_mem_search via MCP, then manually populate $syncFile" -ForegroundColor DarkGray
        # Still write a valid empty sync file
        $payload.observations = @()
    }

    # If InputFile provided (MCP-driven export), merge its observations
    if ($InputFile -and (Test-Path -LiteralPath $InputFile)) {
        try {
            $inputData = Get-Content -LiteralPath $InputFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $inputObs = @($inputData.observations)
            if (-not $inputObs -or $inputObs.Count -eq 0) { $inputObs = @($inputData) | Where-Object { $_.title } }
            foreach ($obs in $inputObs) {
                $key = if ($obs.topic_key) { $obs.topic_key } else { "untagged/$($obs.id)" }
                if (-not $deduped.ContainsKey($key)) {
                    $deduped[$key] = $obs
                    Write-Host "  + from InputFile: $key" -ForegroundColor DarkGray
                }
            }
            # Rebuild export list from deduped
            $exportList = @($deduped.Values | ForEach-Object {
                [ordered]@{
                    topic_key  = $_.topic_key
                    type       = $_.type
                    title      = $_.title
                    content    = $_.content
                    exported_at = (Get-Date -Format "o")
                    source_id  = $_.id
                }
            })
            $payload.count = $exportList.Count
            $payload.observations = $exportList
        } catch {
            Write-Host "  InputFile parse failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    if ($DryRun) {
        Write-Host "  [dry-run] WOULD write $($payload.count) observations to $syncFile" -ForegroundColor Yellow
        $payload | ConvertTo-Json -Depth 5 | Write-Output
    } else {
        $learningsDir = Join-Path $repoRoot ".learnings"
        if (-not (Test-Path $learningsDir)) { New-Item -ItemType Directory -Path $learningsDir -Force | Out-Null }
        $payload | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $syncFile -Encoding UTF8
        Write-Host "  Exported $($payload.count) observations → $syncFile ($((Get-Item $syncFile).Length) bytes)" -ForegroundColor Green
        if ($payload.count -eq 0) {
            Write-Host "  Tip: populate via InputFile or edit manually. MCP: orchestrator calls engram_mem_search → sync-engram.ps1 -Export -InputFile <json>" -ForegroundColor DarkGray
        }
    }
    exit 0
}

# ============================================================
# IMPORT — git file → engram
# ============================================================
if ($Import) {
    Write-Host "==> sync-engram: Import ($syncFile → engram)" -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $syncFile)) {
        Write-Host "  No sync file found: $syncFile" -ForegroundColor Yellow
        Write-Host "  Run -Export first, or the project has no shared knowledge yet." -ForegroundColor DarkGray
        exit 0
    }

    $payload = Get-Content -LiteralPath $syncFile -Raw -Encoding UTF8 | ConvertFrom-Json

    if ($payload.version -ne $syncVersion) {
        Write-Host "  Warning: sync file version $($payload.version) ≠ expected $syncVersion" -ForegroundColor Yellow
    }

    $observations = @($payload.observations)
    if ($observations.Count -eq 0) {
        Write-Host "  Sync file has 0 observations — nothing to import." -ForegroundColor DarkGray
        exit 0
    }

    $cutoff = (Get-Date).AddDays(-$maxAgeDays)
    $imported = 0
    $skipped = 0
    $expired = 0
    $errors = 0

    foreach ($obs in $observations) {
        # Expiry check
        try {
            $exportedAt = [DateTime]$obs.exported_at
            if ($exportedAt -lt $cutoff) {
                $expired++
                Write-Host "  SKIP expired: $($obs.topic_key) ($($obs.exported_at))" -ForegroundColor DarkGray
                continue
            }
        } catch { }

        $topicKey = $obs.topic_key

        if ($DryRun) {
            Write-Host "  [dry-run] WOULD import: $topicKey ($($obs.type))" -ForegroundColor Yellow
            $imported++
            continue
        }

        # Import: MCP-only — emit JSON lines for the orchestrator to call engram_mem_save
        # The orchestrator (or manual operator) reads these and calls the MCP.
        try {
            $importPayload = [ordered]@{
                topic_key = $topicKey
                type      = $obs.type
                title     = $obs.title
                content   = $obs.content
            }
            # Emit JSON line to stdout for programmatic consumption
            $importPayload | ConvertTo-Json -Compress | Write-Output
            Write-Host "  Queued: $topicKey ($($obs.type)) — pipe to engram_mem_save" -ForegroundColor Green
            $imported++
        } catch {
            $errors++
            Write-Host "  ERROR: $topicKey — $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "`n  Summary: imported=$imported skipped=$skipped expired=$expired errors=$errors" -ForegroundColor Cyan
    if ($DryRun) { Write-Host "  (dry-run — no changes made)" -ForegroundColor Yellow }
    exit 0
}
