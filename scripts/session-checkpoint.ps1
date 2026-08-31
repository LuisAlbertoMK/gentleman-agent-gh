#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Session checkpoint bridge — integrates context-watchdog, engram-validate, and
    session-miner into a single proactive memory-capture pipeline.

.DESCRIPTION
    Bridges the gap between context-window monitoring and Engram persistence.
    Addresses the "medium-term conversational memory" weakness: without this
    bridge, decisions/bugfixes/discoveries made between mem_session_summary
    calls (i.e. mid-session compaction cycles) are lost.

    Pipeline:
      1. ctx_watchdog reports zone (GREEN/YELLOW/ORANGE/RED/CRITICAL)
      2. If YELLOW+ → create checkpoint in Engram (mem_save topic_key checkpoint/session-state)
      3. Validate content via engram-validate (poisoning guard)
      4. Index any large output via ctx_index for cross-session recovery
      5. Optionally trigger session-miner for pattern detection

    Call every 5-10 tool rounds or whenever ctx_watchdog exits YELLOW.

.PARAMETER Mode
    check  — Report current zone + whether a checkpoint is needed (no write)
    mark   — Create checkpoint in Engram (requires mem_save availability)
    full   — check + mark + miner scan (default)

.PARAMETER UsagePercent
    Current context usage percent (alternative to measuring via ctx_stats MCP).

.PARAMETER Quiet
    Output JSON only.

.PARAMETER Force
    Bypass the YELLOW threshold — create checkpoint regardless of zone.

.PARAMETER NoValidate
    Skip engram-validate gate (use only if validator is unavailable).

.EXAMPLE
    .\scripts\session-checkpoint.ps1 -Mode check
    # → OK  GREEN  12% — no checkpoint needed

    .\scripts\session-checkpoint.ps1 -Mode full -Force
    # → Creates checkpoint even in GREEN

.EXAMPLE
    .\scripts\session-checkpoint.ps1 -Mode check -UsagePercent 65 -Json
    # → {"zone":"YELLOW","percent":65,"level":"L1","checkpoint_needed":true,"action":"checkpoint_recommended"}
#>
param(
    [ValidateSet('check','mark','full','process-pending')]
    [string]$Mode = 'full',
    [int]$UsagePercent = -1,
    [string[]]$Discoveries = @(),
    [string[]]$Decisions = @(),
    [switch]$Quiet,
    [switch]$Force,
    [switch]$NoValidate
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Redact-Secrets {
    [CmdletBinding()]
    param(
        [string]$Text
    )
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    $redacted = $Text
    # Generic key=value secrets: api_key, api-key, token, password, secret, credential
    $redacted = $redacted -replace '(?i)(api[_-]?key|token|password|secret|credential)(\s*[:=]\s*)\S+', '$1$2[REDACTED]'
    # Bearer tokens
    $redacted = $redacted -replace '(?i)bearer\s+[A-Za-z0-9\-_\.=]+', 'bearer [REDACTED]'
    # AWS keys
    $redacted = $redacted -replace '(?i)aws[_-]?secret[_-]?access[_-]?key(\s*[:=]\s*)\S+', 'aws_secret_access_key$1[REDACTED]'
    $redacted = $redacted -replace '(?i)aws[_-]?access[_-]?key[_-]?id(\s*[:=]\s*)\S+', 'aws_access_key_id$1[REDACTED]'
    # OpenAI / GitHub / generic prefixed secrets
    $redacted = $redacted -replace 'sk-[A-Za-z0-9]{20,}', '[REDACTED]'
    $redacted = $redacted -replace 'sk-proj-[A-Za-z0-9\-_]{20,}', '[REDACTED]'
    $redacted = $redacted -replace 'gh[oprs]_[A-Za-z0-9_]{20,}', '[REDACTED]'
    $redacted = $redacted -replace 'ghu_[A-Za-z0-9_]{20,}', '[REDACTED]'
    # Fallback: any remaining (?i)(api[_-]?key|token|password|secret|credential)\s*[:=]\s*\S+ whole match redacted
    $redacted = $redacted -replace '(?i)(api[_-]?key|token|password|secret|credential)\s*[:=]\s*\S+', '[REDACTED]'
    return $redacted
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$checkpointDir = Join-Path -Path $repoRoot -ChildPath ".opencode\session-checkpoints"

# --- Ensure checkpoint dir exists ---
if (-not (Test-Path -LiteralPath $checkpointDir)) {
    try {
        $null = New-Item -ItemType Directory -Path $checkpointDir -Force -ErrorAction Stop
    } catch {
        Write-Warning "Failed to create checkpoint dir '$checkpointDir': $($_.Exception.Message)"
        throw
    }
}

# --- Step 1: Get context zone from ctx-watchdog ---
$watchdogResult = $null
try {
    $watchdogRaw = & "$PSScriptRoot\ctx-watchdog.ps1" -UsagePercent $UsagePercent -Json -ErrorAction Stop 2>&1 | Out-String
    if (-not [string]::IsNullOrWhiteSpace($watchdogRaw)) {
        $parsed = $watchdogRaw | ConvertFrom-Json -ErrorAction Stop
        if ($null -ne $parsed -and $null -ne $parsed.zone) {
            $watchdogResult = $parsed
        } else {
            Write-Warning "ctx-watchdog returned invalid JSON or missing zone: $watchdogRaw"
        }
    } else {
        Write-Warning "ctx-watchdog returned empty output"
    }
} catch {
    Write-Warning "ctx-watchdog failed: $($_.Exception.Message)"
}
if (-not $watchdogResult -or -not $watchdogResult.zone) {
    $watchdogResult = [PSCustomObject]@{
        zone   = "UNKNOWN"
        percent = $UsagePercent
        level  = ""
        recommendation = "Unable to determine context zone"
    }
}

$contextZone   = $watchdogResult.zone
$contextLevel  = $watchdogResult.level
$zoneNeedsCheckpoint = switch ($contextZone) {
    "GREEN"     { $false }
    "YELLOW"    { $true }
    "ORANGE"    { $true }
    "RED"       { $true }
    "CRITICAL"  { $true }
    default     { $false }
}

# --- Step 2: Decide checkpoint action ---
$checkpointNeeded = $zoneNeedsCheckpoint -or $Force -or $Discoveries.Count -gt 0 -or $Decisions.Count -gt 0

# --- Sanitize Decisions/Discoveries before persistence (P0 secrets guard) ---
$sanitizedDecisions = @($Decisions | ForEach-Object { Redact-Secrets -Text $_ })
$sanitizedDiscoveries = @($Discoveries | ForEach-Object { Redact-Secrets -Text $_ })

# --- Step 3: If checkpoint needed and mode is mark/full, create it ---
$gitFilesTouched = @()
$gitBranch = "unknown"
try {
    $gitStatusRaw = & git -C $repoRoot status --porcelain 2>&1
    if ($LASTEXITCODE -eq 0) {
        if ($gitStatusRaw) {
            $gitFilesTouched = @($gitStatusRaw -split "`n" | Where-Object { $_ -match '\S' })
        }
    } else {
        Write-Warning "git status failed with exit code $LASTEXITCODE : $gitStatusRaw"
        $gitFilesTouched = @()
        $gitBranch = "unknown"
    }
} catch {
    Write-Warning "git status failed: $($_.Exception.Message)"
    $gitFilesTouched = @()
}
try {
    $gitBranchRaw = & git -C $repoRoot rev-parse --abbrev-ref HEAD 2>&1
    if ($LASTEXITCODE -eq 0 -and $gitBranchRaw) {
        $tmpBranch = ($gitBranchRaw | Out-String).Trim()
        if (-not [string]::IsNullOrWhiteSpace($tmpBranch)) {
            $gitBranch = $tmpBranch
        } else {
            Write-Warning "git rev-parse returned empty branch name"
            $gitBranch = "unknown"
        }
    } else {
        Write-Warning "git rev-parse failed with exit code $LASTEXITCODE : $gitBranchRaw"
        $gitBranch = "unknown"
    }
} catch {
    Write-Warning "git rev-parse failed: $($_.Exception.Message)"
    $gitBranch = "unknown"
}

$checkpointData = [PSCustomObject]@{
    timestamp      = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    session_id     = "session-$((Get-Date).ToString('yyyyMMdd-HHmmss'))"
    context_zone   = $contextZone
    context_percent = $watchdogResult.percent
    compression_level = $contextLevel
    decisions      = $sanitizedDecisions
    discoveries    = $sanitizedDiscoveries
    files_touched  = $gitFilesTouched
    branch         = $gitBranch
    recommendation = $watchdogResult.recommendation
}

$checkpointPath = Join-Path -Path $checkpointDir -ChildPath "$($checkpointData.session_id).json"
$tmpPath = "$checkpointPath.tmp"
$checkpointData | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $tmpPath -Encoding UTF8 -ErrorAction Stop
Move-Item -LiteralPath $tmpPath -Destination $checkpointPath -Force -ErrorAction Stop
if (-not (Test-Path -LiteralPath $checkpointPath)) {
    throw "Atomic write failed: checkpoint not found at $checkpointPath"
}

# --- Step 4: Validate before mem_save (poisoning guard) ---
$validated = $true
if (-not $NoValidate) {
    $validatorPath = Join-Path -Path $PSScriptRoot -ChildPath "engram-validate.ps1"
    if (Test-Path -LiteralPath $validatorPath) {
        $contentSummary = "**What**: Session checkpoint at $contextZone zone ($($watchdogResult.percent)% context). " +
                         "**Why**: Proactive capture to prevent memory loss across compaction cycles. " +
                         "**Where**: .opencode/session-checkpoints/$($checkpointData.session_id).json. " +
                         "**Learned**: Zone=$contextZone, decisions=$($sanitizedDecisions.Count), discoveries=$($sanitizedDiscoveries.Count)."
        $contentSummary = Redact-Secrets -Text $contentSummary
        $validationParams = @{
            Content = $contentSummary
            Title = "checkpoint:session-state:$($checkpointData.session_id)"
            Type  = "pattern"
            PassThru = $true
            Quiet = $true
        }
        try {
            $validationResult = & $validatorPath @validationParams -ErrorAction Stop 2>&1
            $exitCode = $LASTEXITCODE
            $hasErrorFlag = $false
            if ($null -eq $validationResult) {
                $hasErrorFlag = $true
            } elseif ($validationResult -is [string] -and $validationResult -match '(?i)error|invalid|injection') {
                $hasErrorFlag = $true
            } elseif ($validationResult -is [PSCustomObject] -and $null -ne $validationResult.valid -and -not $validationResult.valid) {
                $hasErrorFlag = $true
            } elseif ($validationResult -is [PSCustomObject] -and $null -ne $validationResult.errors -and $validationResult.errors.Count -gt 0) {
                $hasErrorFlag = $true
            }
            # Strict: require exit 0, non-null result, no error flag
            if ($null -ne $validationResult -and $exitCode -eq 0 -and -not $hasErrorFlag) {
                $validated = $true
            } else {
                Write-Warning "engram-validate failed or returned invalid content (exit=$exitCode, hasError=$hasErrorFlag, resultNull=$($null -eq $validationResult))"
                $validated = $false
            }
        } catch {
            Write-Warning "engram-validate execution failed: $($_.Exception.Message)"
            $validated = $false
        }
    }
}

# --- Step 5: Persist to Engram (if checkpoint needed and validated) ---
$memSaved = $false
$memSaveDirective = $null

# --- Mode: process-pending — read pending-engram.json and emit directive for orchestrator ---
if ($Mode -eq 'process-pending') {
    $pendingPath = Join-Path $checkpointDir "pending-engram.json"
    if (Test-Path -LiteralPath $pendingPath) {
        try {
            $pendingContent = Get-Content -LiteralPath $pendingPath -Raw -ErrorAction Stop
            $pendingDirective = $pendingContent | ConvertFrom-Json -ErrorAction Stop
            if ($pendingDirective -and $pendingDirective.topic_key) {
                $memSaveDirective = $pendingDirective
                $memSaved = $true
                if (-not $Quiet) {
                    Write-Host "🔄 PROCESS-PENDING: Found pending directive for topic_key=$($pendingDirective.topic_key)" -ForegroundColor Cyan
                }
            } else {
                Write-Warning "process-pending: pending-engram.json missing topic_key"
            }
        } catch {
            Write-Warning "process-pending: failed to read pending-engram.json: $($_.Exception.Message)"
        }
    } else {
        if (-not $Quiet) {
            Write-Host "🔄 PROCESS-PENDING: No pending-engram.json found" -ForegroundColor DarkGray
        }
    }
    # Output result and exit early for process-pending mode
    $result = [PSCustomObject]@{
        zone              = "N/A"
        percent           = 0
        compression_level = ""
        checkpoint_needed = $false
        checkpoint_created = $false
        checkpoint_file   = $null
        validated         = $true
        mem_saved         = $memSaved
        mem_save_directive = $memSaveDirective
        indexed           = $false
        miner_patterns    = 0
        recommendation    = "Processed pending engram directive"
        action            = if ($memSaved) { "pending_directive_emitted" } else { "no_pending" }
    }
    if ($Quiet) { $result | ConvertTo-Json -Compress -Depth 3 } else { $result }
    exit 0
}

if ($Mode -in @('mark', 'full') -and $checkpointNeeded -and $validated) {
    $memContentRaw = "**What**: Session checkpoint at $contextZone zone ($($watchdogResult.percent)% context used). Captured $($sanitizedDecisions.Count) decisions and $($sanitizedDiscoveries.Count) discoveries proactively. **Why**: Prevent memory loss across compaction cycles — medium-term conversational context is lost without explicit persistence. **Where**: .opencode/session-checkpoints/ + Engram checkpoint/session-state. **Learned**: This bridge connects ctx-watchdog zone detection → engram-validate → mem_save → ctx_index. Without it, mid-session decisions vanish at compaction."
    $memContent = Redact-Secrets -Text $memContentRaw
    $topicKey = "checkpoint/session-state"
    # G7 fix: mem_save is an MCP tool call, not available in this .ps1 context.
    # Emit a mem_save directive for the orchestrator (which holds the MCP tool)
    # to invoke engram_mem_save — matching the sync-engram.ps1 emit-then-call pattern.
    $memSaveDirective = [ordered]@{
        topic_key = $topicKey
        type      = "session_checkpoint"
        title     = "Session checkpoint at $contextZone zone ($($watchdogResult.percent)% context used)"
        content   = $memContent
    }
    $memSaved = $true  # directive prepared — orchestrator calls engram_mem_save with $memSaveDirective

    # Persist directive to file for hard-gate recovery (orchestrator reads this even if stdout missed)
    if ($memSaveDirective) {
        $pendingPath = Join-Path $checkpointDir "pending-engram.json"
        $pendingTmp = "$pendingPath.tmp"
        $memSaveDirective | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $pendingTmp -Encoding UTF8 -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $pendingTmp) { Move-Item -LiteralPath $pendingTmp -Destination $pendingPath -Force -ErrorAction SilentlyContinue }
    }
}

# --- Step 6: Index large output via ctx_index (for cross-session recovery) ---
$indexed = $false
if ($checkpointData.recommendation -and $checkpointData.recommendation.Length -gt 500) {
    # Large recommendation text → would be indexed by orchestrator via ctx_index
    # Script tracks that it SHOULD be indexed
    $indexed = $true  # flagged for orchestrator
}

# --- Step 7: Optionally trigger session-miner ---
$minerResult = $null
if ($Mode -eq 'full' -and ($sanitizedDiscoveries -or $sanitizedDecisions)) {
    $minerPath = Join-Path -Path $PSScriptRoot -ChildPath "session-miner.ps1"
    if (Test-Path -LiteralPath $minerPath) {
        try {
            $minerParams = @{ Mode = "populate"; Json = $true }
            if ($sanitizedDiscoveries) { $minerParams.PatternKeys = $sanitizedDiscoveries }
            if ($sanitizedDecisions) { $minerParams.ErrorEntries = $sanitizedDecisions }
            $minerRaw = & $minerPath @minerParams -ErrorAction Stop 2>&1
            if ($minerRaw) {
                $minerResult = $minerRaw | Out-String | ConvertFrom-Json -ErrorAction Stop
            }
        } catch {
            Write-Warning "session-miner failed: $($_.Exception.Message)"
            Write-Debug "session-miner skipped: $($_.Exception.Message)"
        }
    }
}

# --- Output ---
$result = [PSCustomObject]@{
    zone              = $contextZone
    percent           = $watchdogResult.percent
    compression_level = $contextLevel
    checkpoint_needed = $checkpointNeeded
    checkpoint_created = if ($checkpointNeeded) { $true } else { $false }
    checkpoint_file   = if ($checkpointNeeded) { $checkpointPath } else { $null }
    validated         = $validated
    mem_saved         = $memSaved
    mem_save_directive = $memSaveDirective
    indexed           = $indexed
    miner_patterns    = if ($minerResult) { $minerResult.RepeatedPatterns } else { 0 }
    recommendation    = $watchdogResult.recommendation
    action            = if ($checkpointNeeded) {
        "checkpoint_created"
    } else {
        "none_needed"
    }
}

if ($Quiet) {
    $result | ConvertTo-Json -Compress -Depth 3
} else {
    if ($checkpointNeeded) {
        Write-Host "✅ CHECKPOINT  $contextZone  $($watchdogResult.percent)% — $($result.action)" -ForegroundColor Cyan
        Write-Host "  File: $checkpointPath" -ForegroundColor DarkGray
    } else {
        Write-Host "OK  $contextZone  $($watchdogResult.percent)% — no checkpoint needed" -ForegroundColor Green
    }
    if ($minerResult -and $minerResult.RepeatedPatterns -gt 0) {
        Write-Host "  ⛏️  $($minerResult.RepeatedPatterns) repeated pattern(s) — run dreaming" -ForegroundColor DarkYellow
    }
}
