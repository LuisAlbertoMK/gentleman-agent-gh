#requires -Version 7
<#
.SYNOPSIS
    Pester tests for session-checkpoint.ps1 — the proactive memory-capture bridge.
    Validates: ctx-watchdog integration, checkpoint JSON creation, engram-validate
    poisoning guard, check vs mark vs full modes, and YELLOW threshold behavior.

.NOTES
    Tests use inline function definitions (like health-check.Tests.ps1) to avoid
    executing main code on dot-source. Temp dirs cleaned up after.
#>
param([switch]$Quiet)
Set-StrictMode -Version Latest

BeforeAll {
    $script:repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:checkpointDir = Join-Path $repoRoot ".opencode\session-checkpoints"
    # Ronda4 S3: hermetic DAG — session-checkpoint now calls context-watchdog-check,
    # which persists a real node outside PESTER_TEST=1. Dry-run for the whole file.
    $script:prevPesterTest = $env:PESTER_TEST
    $env:PESTER_TEST = '1'

    # Inline replica of the zone determination logic (mirrors ctx-watchdog.ps1)
    function Get-ContextZone {
        param([int]$UsagePercent)
        if ($UsagePercent -le 40) { return @{ zone="GREEN"; level=""; needsCheckpoint=$false } }
        elseif ($UsagePercent -le 60) { return @{ zone="YELLOW"; level="L1"; needsCheckpoint=$true } }
        elseif ($UsagePercent -le 80) { return @{ zone="ORANGE"; level="L1"; needsCheckpoint=$true } }
        elseif ($UsagePercent -le 95) { return @{ zone="RED"; level="L2"; needsCheckpoint=$true } }
        else { return @{ zone="CRITICAL"; level="L3"; needsCheckpoint=$true } }
    }

    # Helper: run session-checkpoint.ps1 in check mode and parse JSON output
    function Invoke-CheckpointCheck {
        param([int]$Percent, [string[]]$Discoveries = @(), [string[]]$Decisions = @())
        # Hashtable splatting — array splatting passes "-Mode" positionally in PS 7.6.5
        # and trips the ValidateSet on -Mode. Use named params.
        $params = @{ Mode = "check"; UsagePercent = $Percent; Quiet = $true }
        if ($Discoveries) { $params.Discoveries = $Discoveries }
        if ($Decisions) { $params.Decisions = $Decisions }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        return $out | ConvertFrom-Json -ErrorAction SilentlyContinue
    }
}

AfterAll {
    # Robust cleanup: restore permissions before removing to handle interrupted tests
    if (Test-Path $script:checkpointDir) {
        Get-ChildItem -LiteralPath $script:checkpointDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $_.IsReadOnly = $false
        }
        Remove-Item -LiteralPath $script:checkpointDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Ronda4 S3: restore PESTER_TEST isolation
    $env:PESTER_TEST = $script:prevPesterTest
}

Describe "Session Checkpoint Bridge — Zone Detection" {
    It "GREEN zone at 25% — no checkpoint needed" {
        $result = Invoke-CheckpointCheck -Percent 25
        $result.zone | Should -Be "GREEN"
        $result.checkpoint_needed | Should -Be $false
    }

    It "YELLOW zone at 45% — checkpoint recommended" {
        $result = Invoke-CheckpointCheck -Percent 45
        $result.zone | Should -Be "YELLOW"
        $result.checkpoint_needed | Should -Be $true
    }

    It "ORANGE zone at 65% — checkpoint recommended" {
        $result = Invoke-CheckpointCheck -Percent 65
        $result.zone | Should -Be "ORANGE"
        $result.checkpoint_needed | Should -Be $true
        $result.compression_level | Should -Be "L1"
    }

    It "RED zone at 85% — aggressive compression" {
        $result = Invoke-CheckpointCheck -Percent 85
        $result.zone | Should -Be "RED"
        $result.compression_level | Should -Be "L2"
        $result.checkpoint_needed | Should -Be $true
    }

    It "CRITICAL zone at 98% — max compression" {
        $result = Invoke-CheckpointCheck -Percent 98
        $result.zone | Should -Be "CRITICAL"
        $result.compression_level | Should -Be "L3"
    }
}

Describe "Session Checkpoint Bridge — Checkpoint Creation" {
    It "check mode does NOT create checkpoint file" {
        $result = Invoke-CheckpointCheck -Percent 25
        $result.checkpoint_created | Should -Be $false
        $result.checkpoint_file | Should -Be $null
    }

    It "mark mode with Force creates checkpoint JSON at 5%" {
        $before = (Get-ChildItem -LiteralPath $script:checkpointDir -ErrorAction SilentlyContinue | Measure-Object).Count
        $params = @{ Mode = "mark"; UsagePercent = 5; Force = $true; Quiet = $true }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
        $result.checkpoint_created | Should -Be $true
        $result.checkpoint_file | Should -Not -Be $null
        Test-Path -LiteralPath $result.checkpoint_file | Should -Be $true
    }

    It "checkpoint JSON has required fields" {
        $params = @{ Mode = "mark"; UsagePercent = 50; Force = $true; Quiet = $true }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
        $checkpointJson = Get-Content -LiteralPath $result.checkpoint_file -Raw | ConvertFrom-Json
        $checkpointJson.session_id | Should -Not -BeNullOrEmpty
        $checkpointJson.context_zone | Should -Be "YELLOW"
        $checkpointJson.timestamp | Should -Not -BeNullOrEmpty
        $checkpointJson.branch | Should -Not -BeNullOrEmpty
    }

    It "discoveries trigger checkpoint even in GREEN zone" {
        $result = Invoke-CheckpointCheck -Percent 10 -Discoveries @("found N+1 bug")
        $result.checkpoint_needed | Should -Be $true
    }
}

Describe "Session Checkpoint Bridge — Engram-Validate Gate" {
    It "validator path resolves correctly" {
        $validatorPath = Join-Path $PSScriptRoot "..\engram-validate.ps1"
        Test-Path -LiteralPath $validatorPath | Should -Be $true
    }

    It "checkpoint content passes poisoning guard format" {
        # The checkpoint mem_save content must include **What**: field
        $params = @{ Mode = "mark"; UsagePercent = 50; Force = $true; Quiet = $true }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
        $result.validated | Should -Be $true
    }
}

Describe "Session Checkpoint Bridge — Mode Behavior" {
    It "check mode outputs zone info only" {
        $result = Invoke-CheckpointCheck -Percent 30
        $result.zone | Should -Be "GREEN"
        $result.action | Should -Be "none_needed"
    }

    It "full mode with discoveries triggers miner" {
        $params = @{ Mode = "full"; UsagePercent = 45; Discoveries = @("N+1 query in UserList"); Quiet = $true }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
        $result.checkpoint_created | Should -Be $true
    }
}

Describe "Session Checkpoint Bridge — memSaved Flag Fidelity" {
    It "mem_saved is false when no checkpoint needed (GREEN, no discoveries)" {
        $result = Invoke-CheckpointCheck -Percent 10
        $result.mem_saved | Should -Be $false
    }

    It "mem_saved is true after successful write (mark mode with Force)" {
        $params = @{ Mode = "mark"; UsagePercent = 5; Force = $true; Quiet = $true }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
        $result.mem_saved | Should -Be $true
    }

    It "persisted field is false when no checkpoint needed" {
        $result = Invoke-CheckpointCheck -Percent 10
        $result.persisted | Should -Be $false
    }

    It "persisted field is true after successful write" {
        $params = @{ Mode = "mark"; UsagePercent = 5; Force = $true; Quiet = $true }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
        $result.persisted | Should -Be $true
    }

    It "pending_file is null when no checkpoint needed" {
        $result = Invoke-CheckpointCheck -Percent 10
        $result.pending_file | Should -Be $null
    }

    It "pending_file is set after successful write" {
        $params = @{ Mode = "mark"; UsagePercent = 5; Force = $true; Quiet = $true }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
        $result.pending_file | Should -Not -Be $null
        Test-Path -LiteralPath $result.pending_file | Should -Be $true
    }
}

Describe "Session Checkpoint Bridge — Failure Injection (F1 fix)" {
    It "write failure (file locked) → mem_saved=false AND persisted=false" {
        # Pre-create pending file with stale content
        if (-not (Test-Path -LiteralPath $script:checkpointDir)) {
            $null = New-Item -ItemType Directory -Path $script:checkpointDir -Force
        }
        $pendingPath = Join-Path $script:checkpointDir "pending-engram.json"
        $staleContent = @{ topic_key = "stale/old"; type = "session_checkpoint"; title = "stale"; content = "old" }
        $staleContent | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $pendingPath -Encoding UTF8 -Force

        # Open exclusive lock on target to prevent Move-Item overwrite
        # (PS7 -Force ignores IsReadOnly, so read-only is insufficient — FileStream locks the inode)
        $lockedStream = [System.IO.File]::Open($pendingPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        try {
            $params = @{ Mode = "mark"; UsagePercent = 55; Force = $true; Quiet = $true }
            $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
            $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue

            # UNCONDITIONAL assertions — must fail in pre-fix code where $memSaved=true was set before write
            $result.persisted | Should -Be $false
            $result.mem_saved | Should -Be $false
        } finally {
            $lockedStream.Close()
            $lockedStream.Dispose()
            if (Test-Path -LiteralPath $pendingPath) {
                Set-ItemProperty -LiteralPath $pendingPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $pendingPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Session Checkpoint Bridge — Process-Pending Coverage (F2 fix)" {
    It "process-pending with no pending file → mem_saved=false, pending_file=null" {
        # Ensure no pending file exists
        $pendingDir = Join-Path $script:checkpointDir "pending-engram.json"
        if (Test-Path -LiteralPath $pendingDir) {
            Remove-Item -LiteralPath $pendingDir -Force -ErrorAction SilentlyContinue
        }
        $params = @{ Mode = "process-pending"; Quiet = $true }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
        $result.mem_saved | Should -Be $false
        $result.persisted | Should -Be $false
        $result.pending_file | Should -Be $null
    }

    It "process-pending with valid pending → mem_saved=true, pending_file not null" {
        # Create valid pending file
        $pendingDir = Join-Path $script:checkpointDir "pending-engram.json"
        if (-not (Test-Path -LiteralPath $script:checkpointDir)) {
            $null = New-Item -ItemType Directory -Path $script:checkpointDir -Force
        }
        $valid = @{ topic_key = "checkpoint/session-state"; type = "session_checkpoint"; title = "test"; content = "test content" }
        $valid | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $pendingDir -Encoding UTF8

        try {
            $params = @{ Mode = "process-pending"; Quiet = $true }
            $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
            $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
            $result.mem_saved | Should -Be $true
            $result.persisted | Should -Be $true
            # F2: pending_file should be set (file exists AND mem_saved=true)
            $result.pending_file | Should -Not -Be $null
            Test-Path -LiteralPath $result.pending_file | Should -Be $true
        } finally {
            if (Test-Path -LiteralPath $pendingDir) {
                Remove-Item -LiteralPath $pendingDir -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It "process-pending with pending missing topic_key → mem_saved=false" {
        $pendingDir = Join-Path $script:checkpointDir "pending-engram.json"
        if (-not (Test-Path -LiteralPath $script:checkpointDir)) {
            $null = New-Item -ItemType Directory -Path $script:checkpointDir -Force
        }
        $invalid = @{ type = "session_checkpoint"; title = "test"; content = "no topic_key" }
        $invalid | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $pendingDir -Encoding UTF8

        try {
            $params = @{ Mode = "process-pending"; Quiet = $true }
            $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
            $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
            $result.mem_saved | Should -Be $false
            # F2: pending_file should be null (file exists but mem_saved=false)
            $result.pending_file | Should -Be $null
        } finally {
            if (Test-Path -LiteralPath $pendingDir) {
                Remove-Item -LiteralPath $pendingDir -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Session Checkpoint Bridge — LCM Auto-Escalation (Ronda4 S3)" {
    It "GREEN mark+Force creates checkpoint but does NOT escalate (threshold gate)" {
        $params = @{ Mode = "mark"; UsagePercent = 5; Force = $true; Quiet = $true }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
        $result.checkpoint_created | Should -Be $true
        $result.dag_escalation | Should -Be "NONE"
        $result.dag_node_created | Should -Be $false
        $result.dag_discriminator | Should -Be $null
    }

    It "YELLOW mark escalates L1 with discriminator bound to the checkpoint session_id" {
        $params = @{ Mode = "mark"; UsagePercent = 45; Quiet = $true }
        $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
        $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
        $result.checkpoint_created | Should -Be $true
        $result.dag_escalation | Should -Be "L1"
        $result.dag_node_created | Should -Be $false  # PESTER_TEST=1 dry-run
        $result.dag_discriminator | Should -Not -Be $null
        $checkpointJson = Get-Content -LiteralPath $result.checkpoint_file -Raw | ConvertFrom-Json
        $result.dag_discriminator | Should -Be $checkpointJson.session_id
    }

    It "check mode at 85% never escalates (read-only preserved)" {
        $result = Invoke-CheckpointCheck -Percent 85
        $result.checkpoint_needed | Should -Be $true
        $result.dag_escalation | Should -Be "NONE"
        $result.dag_node_created | Should -Be $false
        $result.dag_discriminator | Should -Be $null
    }

    It "escalation level follows Invoke-LcmEscalation (L2 at 65%, L3 at 85%, dry-run)" {
        foreach ($case in @(@{ pct = 65; level = "L2" }, @{ pct = 85; level = "L3" })) {
            $params = @{ Mode = "mark"; UsagePercent = $case.pct; Quiet = $true }
            $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
            $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
            $result.dag_escalation | Should -Be $case.level
        }
    }

    It "no-double-disparo: one mark at 65% persists exactly 1 DAG node bound to 1 checkpoint" {
        $dagPath = Join-Path $script:repoRoot ".learnings\lcm-dag.json"
        $hadDag = Test-Path -LiteralPath $dagPath
        $backup = $null
        if ($hadDag) { $backup = Get-Content -LiteralPath $dagPath -Raw -ErrorAction Stop }
        $before = 0
        if ($hadDag) { $before = @((($backup | ConvertFrom-Json).nodes)).Count }
        $oldPester = $env:PESTER_TEST
        $env:PESTER_TEST = $null
        try {
            $params = @{ Mode = "mark"; UsagePercent = 65; Quiet = $true }
            $out = & (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null
            $result = $out | ConvertFrom-Json -ErrorAction SilentlyContinue
            $result.dag_escalation | Should -Be "L2"
            $result.dag_node_created | Should -Be $true
            $after = @(((Get-Content -LiteralPath $dagPath -Raw | ConvertFrom-Json).nodes)).Count
            ($after - $before) | Should -Be 1
            $result.dag_node_id | Should -Not -Be $null
            $checkpointJson = Get-Content -LiteralPath $result.checkpoint_file -Raw | ConvertFrom-Json
            $result.dag_discriminator | Should -Be $checkpointJson.session_id
        } finally {
            $env:PESTER_TEST = $oldPester
            if ($hadDag) { $backup | Set-Content -LiteralPath $dagPath -Encoding UTF8 -ErrorAction SilentlyContinue }
            elseif (Test-Path -LiteralPath $dagPath) { Remove-Item -LiteralPath $dagPath -Force -ErrorAction SilentlyContinue }
        }
    }

    It "two mark runs yield distinct discriminators (no node reuse across escalations)" {
        $params = @{ Mode = "mark"; UsagePercent = 45; Quiet = $true }
        $first = (& (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue)
        # session_id granularity is 1s (pre-existing checkpoint naming) — sleep past the boundary
        Start-Sleep -Milliseconds 1100
        $second = (& (Join-Path $PSScriptRoot "..\session-checkpoint.ps1") @params 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue)
        $first.dag_discriminator | Should -Not -Be $null
        $second.dag_discriminator | Should -Not -Be $null
        $second.dag_discriminator | Should -Not -Be $first.dag_discriminator
    }
}
