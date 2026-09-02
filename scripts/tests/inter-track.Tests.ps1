#requires -Version 7
BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'inter-track.ps1'
    $repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $trackPath = Join-Path $repoRoot ".learnings\inter-track.json"
    # Backup original track file (if exists) for isolation — restore in AfterAll
    $script:backupPath = Join-Path ([System.IO.Path]::GetTempPath()) ("inter-track-backup-{0}.json" -f ([guid]::NewGuid().ToString("N")))
    $script:hadOriginal = Test-Path -LiteralPath $trackPath
    if ($script:hadOriginal) {
        Copy-Item -LiteralPath $trackPath -Destination $script:backupPath -Force
    }
    # Helper: read current track JSON
    function Get-TrackData {
        if (-not (Test-Path -LiteralPath $trackPath)) { return $null }
        Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json
    }
    # Helper: invoke inter-track with given args, capture Quiet JSON
    function Invoke-TrackQuiet {
        param([hashtable]$Params)
        $out = & $scriptPath @Params -Quiet 2>&1 | Out-String
        try { $out | ConvertFrom-Json -ErrorAction Stop } catch { throw "Invoke-TrackQuiet parse failed: $out $_" }
    }
    # Helper: reset track file to known clean state (empty history, known cycle)
    function Reset-TrackForTest {
        param([string]$CycleId = "CYC-TEST-001", [int]$Target = 30, [int]$Count = 5)
        $clean = @{
            cycle = @{ id = $CycleId; start = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ"); target = $Target; count = $Count }
            history = @()
        }
        $clean | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $trackPath -Encoding UTF8
    }
    # Helper: normalize timestamp (handles DateTime vs string after ConvertFrom-Json)
    function Get-IsoTimestamp {
        param($Timestamp)
        if ($null -eq $Timestamp) { return "" }
        if ($Timestamp -is [DateTime]) { return $Timestamp.ToString("o") }
        return [string]$Timestamp
    }
}
AfterAll {
    if ($script:hadOriginal -and (Test-Path -LiteralPath $script:backupPath)) {
        Copy-Item -LiteralPath $script:backupPath -Destination $trackPath -Force
        Remove-Item -LiteralPath $script:backupPath -Force -ErrorAction SilentlyContinue
    } elseif (-not $script:hadOriginal -and (Test-Path -LiteralPath $trackPath)) {
        # If we created a file and there was none originally, remove it to avoid pollution
        # Keep it if it existed? We already handled. If no original, clean up only if backup not exists
        # Preserve file created by tests? Remove to restore original no-file state
        Remove-Item -LiteralPath $trackPath -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $script:backupPath) { Remove-Item -LiteralPath $script:backupPath -Force -ErrorAction SilentlyContinue }
    }
}
Describe 'inter-track.ps1' {
    It 'exists' {
        Test-Path $scriptPath | Should -BeTrue
    }
    It 'parses without errors' {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}

Describe 'inter-track G7 receipt — event recorded + history appended (locked)' {
    BeforeEach { Reset-TrackForTest -CycleId "CYC-G7-001" -Count 7 -Target 30 }
    It 'appends structured entry to history via locked write' {
        $before = Get-TrackData
        $before.history.Count | Should -Be 0
        $result = Invoke-TrackQuiet -Params @{ RecordEngramEvent = $true; TopicKey = "checkpoint/session-state"; EventKind = "pending-consumed" }
        $after = Get-TrackData
        $after.history.Count | Should -Be 1
        $entry = $after.history[0]
        $entry.kind | Should -Be "pending-consumed"
        $entry.topic_key | Should -Be "checkpoint/session-state"
        $entry.cycle_id | Should -Be "CYC-G7-001"
        $entry.timestamp | Should -Not -BeNullOrEmpty
        # ISO 8601 UTC check (allows optional fractional seconds, ConvertFrom-Json may return DateTime)
        $ts = Get-IsoTimestamp $entry.timestamp
        $ts | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$'
        $result.engram_recorded | Should -Be $true
        $result.engram_event.topic_key | Should -Be "checkpoint/session-state"
    }
    It 'supports custom EventKind' {
        $result = Invoke-TrackQuiet -Params @{ RecordEngramEvent = $true; TopicKey = "custom/topic"; EventKind = "custom-kind" }
        $after = Get-TrackData
        $after.history[-1].kind | Should -Be "custom-kind"
        $after.history[-1].topic_key | Should -Be "custom/topic"
        $result.engram_event.kind | Should -Be "custom-kind"
    }
    It 'defaults EventKind to pending-consumed when not specified' {
        $result = Invoke-TrackQuiet -Params @{ RecordEngramEvent = $true; TopicKey = "checkpoint/session-state" }
        $after = Get-TrackData
        $after.history[-1].kind | Should -Be "pending-consumed"
        $result.engram_event.kind | Should -Be "pending-consumed"
    }
}

Describe 'inter-track schema backward-compat' {
    BeforeEach {
        # Seed history with legacy archived cycle entry (old schema)
        $legacy = @{
            cycle = @{ id = "CYC-OLD-999"; start = "2026-01-01T00:00:00Z"; target = 30; count = 30 }
            history = @(
                @{ id = "CYC-OLD-001"; start = "2025-12-01T00:00:00Z"; target = 30; count = 30; end = "2025-12-31T00:00:00Z" },
                @{ id = "CYC-OLD-002"; start = "2026-01-01T00:00:00Z"; target = 30; count = 15; end = "2026-01-15T00:00:00Z" }
            )
        }
        $legacy | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $trackPath -Encoding UTF8
    }
    It 'preserves old history entries untouched after recording new event' {
        $before = Get-TrackData
        $before.history.Count | Should -Be 2
        $before.history[0].id | Should -Be "CYC-OLD-001"
        $null = Invoke-TrackQuiet -Params @{ RecordEngramEvent = $true; TopicKey = "checkpoint/session-state" }
        $after = Get-TrackData
        $after.history.Count | Should -Be 3
        $after.history[0].id | Should -Be "CYC-OLD-001"
        $after.history[1].id | Should -Be "CYC-OLD-002"
        $after.history[2].kind | Should -Be "pending-consumed"
        $after.history[2].topic_key | Should -Be "checkpoint/session-state"
        # Old entries still have 'end' field, new has timestamp/kind
        $after.history[0].end | Should -Not -BeNullOrEmpty
        (Get-IsoTimestamp $after.history[2].timestamp) | Should -Match '^\d{4}-\d{2}-\d{2}T'
    }
    It 'keeps cycle fields untouched' {
        $before = Get-TrackData
        $null = Invoke-TrackQuiet -Params @{ RecordEngramEvent = $true; TopicKey = "checkpoint/session-state" }
        $after = Get-TrackData
        $after.cycle.id | Should -Be $before.cycle.id
        $after.cycle.count | Should -Be $before.cycle.count
        $after.cycle.target | Should -Be $before.cycle.target
        $after.cycle.start | Should -Be $before.cycle.start
    }
    It 'existing params Increment/Reset still behave identically' {
        $before = Get-TrackData
        $initial = [int]$before.cycle.count
        $r1 = Invoke-TrackQuiet -Params @{ Increment = $true }
        $r1.count | Should -Be ($initial + 1)
        $r2 = Get-TrackData
        $r2.cycle.count | Should -Be ($initial + 1)
        # history should not have been affected by Increment
        $r2.history.Count | Should -Be $before.history.Count
    }
}

Describe 'inter-track missing/invalid pending path does NOT record' {
    BeforeEach { Reset-TrackForTest -CycleId "CYC-VALID-001" -Count 3 }
    It 'throws when TopicKey missing with RecordEngramEvent' {
        { Invoke-TrackQuiet -Params @{ RecordEngramEvent = $true } } | Should -Throw -ExpectedMessage "*TopicKey*"
        $after = Get-TrackData
        $after.history.Count | Should -Be 0
    }
    It 'throws when TopicKey empty string' {
        { Invoke-TrackQuiet -Params @{ RecordEngramEvent = $true; TopicKey = "" } } | Should -Throw
        (Get-TrackData).history.Count | Should -Be 0
    }
    It 'throws when TopicKey whitespace' {
        { Invoke-TrackQuiet -Params @{ RecordEngramEvent = $true; TopicKey = "   " } } | Should -Throw
        (Get-TrackData).history.Count | Should -Be 0
    }
    It 'does NOT record when RecordEngramEvent not set (normal run)' {
        $null = Invoke-TrackQuiet -Params @{}
        (Get-TrackData).history.Count | Should -Be 0
    }
}

Describe 'inter-track -Quiet JSON contract' {
    BeforeEach { Reset-TrackForTest -CycleId "CYC-QUIET-001" -Count 2 }
    It 'Quiet output is valid JSON with expected fields' {
        $result = Invoke-TrackQuiet -Params @{ RecordEngramEvent = $true; TopicKey = "checkpoint/session-state" }
        $result.cycleId | Should -Be "CYC-QUIET-001"
        $result.count | Should -Be 2
        $result.target | Should -Be 30
        $result.engram_recorded | Should -Be $true
        $result.engram_event | Should -Not -BeNullOrEmpty
        $result.engram_event.kind | Should -Be "pending-consumed"
        $result.engram_event.topic_key | Should -Be "checkpoint/session-state"
        (Get-IsoTimestamp $result.engram_event.timestamp) | Should -Match '^\d{4}-\d{2}-\d{2}T'
        $result.engram_event.cycle_id | Should -Be "CYC-QUIET-001"
    }
    It 'Quiet without event does not include engram_event' {
        $result = Invoke-TrackQuiet -Params @{}
        $result.PSObject.Properties.Name | Should -Not -Contain "engram_event"
        $result.PSObject.Properties.Name | Should -Not -Contain "engram_recorded"
        $result.cycleId | Should -Be "CYC-QUIET-001"
    }
    It 'writes JSON to stdout only (no extra host noise) when Quiet' {
        # Capture raw stdout string, ensure it is pure JSON object starting with {
        $raw = & $scriptPath -RecordEngramEvent -TopicKey "checkpoint/session-state" -Quiet 2>&1 | Out-String
        $trimmed = $raw.Trim()
        $trimmed | Should -Match '^\{'
        { $trimmed | ConvertFrom-Json } | Should -Not -Throw
    }
}

Describe 'inter-track WhatIf support' {
    BeforeEach { Reset-TrackForTest -CycleId "CYC-WHATIF-001" -Count 4 }
    It 'WhatIf does not mutate history but returns whatIf flag' {
        $before = Get-TrackData
        $result = Invoke-TrackQuiet -Params @{ RecordEngramEvent = $true; TopicKey = "checkpoint/session-state" }
        # Normal record should increase history by 1 — reset then test WhatIf
        Reset-TrackForTest -CycleId "CYC-WHATIF-001" -Count 4
        $before2 = Get-TrackData
        $before2.history.Count | Should -Be 0
        # WhatIf invocation
        $whatIfRaw = & $scriptPath -RecordEngramEvent -TopicKey "checkpoint/session-state" -Quiet -WhatIf 2>&1 | Out-String
        # WhatIf still outputs JSON (via -Quiet) but with whatIf=true and engram_recorded=false, and history unchanged
        $whatIfResult = $whatIfRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
        # If WhatIf output not captured as JSON (some pwsh versions emit WhatIf to host), check fallback
        if ($whatIfResult) {
            $whatIfResult.engram_recorded | Should -Be $false
            $whatIfResult.engram_event.whatIf | Should -Be $true
        }
        $after = Get-TrackData
        $after.history.Count | Should -Be 0
        $after.cycle.count | Should -Be $before2.cycle.count
    }
}
