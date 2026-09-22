#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]

<#
.SYNOPSIS
  Track inter(30) -- meaningful interactions per improvement cycle.
  Each "inter" = one fix+verify+log cycle (not trivial changes).

.DESCRIPTION
  Maintains a JSON counter at .learnings/inter-track.json.
  - Increment: .\scripts\inter-track.ps1 -Increment
  - Read current: .\scripts\inter-track.ps1
  - Reset cycle: .\scripts\inter-track.ps1 -Reset
  - Set target: .\scripts\inter-track.ps1 -Target 30

.PARAMETER Increment
  Increment the counter by 1.

.PARAMETER Reset
  Reset counter to 0 for a new cycle.

.PARAMETER Target
  Set the inter target for current cycle (default: 30).

.PARAMETER Quiet
  Output JSON only (machine-readable).

.PARAMETER RecordEngramEvent
  Record a G7 engram directive consumption receipt in history (locked).

.PARAMETER TopicKey
  Topic key for the engram event (required with -RecordEngramEvent).

.PARAMETER EventKind
  Kind label for the engram event (default: pending-consumed).
#>

param(
    [switch]$Increment,
    [switch]$Reset,
    [int]$Target = 30,
    [switch]$Quiet,
    [switch]$RecordEngramEvent,
    [string]$TopicKey = "",
    [string]$EventKind = "pending-consumed"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$trackPath = Join-Path -Path $repoRoot -ChildPath ".learnings\inter-track.json"

# PSSA: explicit param usage at script scope (params are consumed inside Invoke-TrackLocked scriptblock; ScriptAnalyzer doesn't trace into it) — also enforces help-block contract
if ($RecordEngramEvent -and [string]::IsNullOrWhiteSpace($TopicKey)) {
    throw "RecordEngramEvent requires -TopicKey <string> (non-empty)"
}
# Reference remaining params so PSReviewUnusedParameter sees them as used (actual logic is inside the locked scriptblock)
$null = $Increment; $null = $Reset; $null = $Target; $null = $Quiet; $null = $EventKind

# Slice 4: accept engram-saved kind after verification; pending-consumed remains as audit trail
# NOTE (Slice 4): engram-saved es vocabulary-only / advisory — ningún productor verificado existe aún;
# la verificación llega en Slice 2/3. Ningún consumidor debe tratar kind=engram-saved como prueba de persistencia hasta entonces.
$validKinds = @("pending-consumed", "engram-saved")
if ($RecordEngramEvent -and ($validKinds -notcontains $EventKind)) {
    throw "EventKind '$EventKind' is not valid. Allowed kinds: $($validKinds -join ', ')"
}

# Initialize if not exists
if (-not (Test-Path -LiteralPath $trackPath)) {
    if (-not $WhatIfPreference) {
        $init = @{
            cycle  = @{
                id     = ""
                start  = ""
                target = $Target
                count  = 0
            }
            history = @()
        }
        $init | ConvertTo-Json | Set-Content -LiteralPath $trackPath -Encoding UTF8
    }
}

# Exclusive file lock to prevent race conditions on read-modify-write
function Invoke-TrackLocked {
    param(
        [scriptblock]$Action,
        # PSSA FP: CallerPSCmdlet and Action are consumed at L195/L230 inside Invoke-TrackLocked's scriptblock — PSSA cannot trace cross-scope usage
        [System.Management.Automation.Cmdlet]$CallerPSCmdlet
    )
    $null = $CallerPSCmdlet; $null = $Action
    $stream = $null
    $reader = $null
    $writer = $null
    $mutated = $false
    try {
        $stream = [System.IO.FileStream]::new($trackPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8, $true, 1024, $true)
        $content = $reader.ReadToEnd()
        # leaveOpen=$true → Dispose doesn't close $stream
        if ([string]::IsNullOrWhiteSpace($content)) {
            $data = $null
        } else {
            $data = $content | ConvertFrom-Json
        }
        $mutatedRef = [ref]$mutated
        & $action ([ref]$data) $mutatedRef
        # dirty-flag: only write if action mutated data (WhatIf-safe: no write when $mutated stays $false)
        if ($mutatedRef.Value) {
            $stream.SetLength(0)
            $stream.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write(($data | ConvertTo-Json -Depth 4))
            $writer.Flush()
        }
    } finally {
        # E4 perf-ciclo37-clusterA (C36A/E4 anti-leak): Dispose reader/writer +
        # Close/Dispose del stream (el lock FileShare::None se mantiene).
        # Reversible: volver a Close solo.
        try { if ($writer) { $writer.Dispose() } } catch { }
        try { if ($reader) { $reader.Dispose() } } catch { }
        if ($stream) { try { $stream.Close() } catch { }; try { $stream.Dispose() } catch { } }
    }
}

if (-not (Test-Path -LiteralPath $trackPath) -or (Get-Item $trackPath).Length -eq 0) {
    if (-not $WhatIfPreference) {
        $data = @{
            cycle  = @{ id = ""; start = ""; target = $Target; count = 0 }
            history = @()
        }
        $data | ConvertTo-Json | Set-Content -LiteralPath $trackPath -Encoding UTF8
    } else {
        # WhatIf on missing/empty file: use defaults, skip locked write (OpenOrCreate would create the file)
        $data = @{
            cycle  = @{ id = ""; start = ""; target = $Target; count = 0 }
            history = @()
        }
    }
}

# WhatIf guard: skip locked file access when file doesn't exist (OpenOrCreate would create it)
if ($WhatIfPreference -and -not (Test-Path -LiteralPath $trackPath)) {
    # Produce output from defaults (data set above or by init blocks)
    if (-not $data) {
        $data = @{
            cycle  = @{ id = ""; start = ""; target = $Target; count = 0 }
            history = @()
        }
    }
    # Output WhatIf result (mirrors action scriptblock output)
    $result = [PSCustomObject]@{
        cycleId  = $data.cycle.id
        count    = [int]$data.cycle.count
        target   = [int]$data.cycle.target
        complete = ([int]$data.cycle.count -ge [int]$data.cycle.target)
        remaining = [Math]::Max(0, [int]$data.cycle.target - [int]$data.cycle.count)
    }
    if ($Quiet) {
        $result | ConvertTo-Json -Depth 4
    } else {
        Write-Host "  Cycle: $($data.cycle.id) | inter: $($data.cycle.count)/$($data.cycle.target)" -ForegroundColor Cyan
    }
} else {
Invoke-TrackLocked -CallerPSCmdlet $PSCmdlet -Action {
    param([ref]$dataRef, [ref]$mutatedRef)
    $data = $dataRef.Value
    if (-not $data) {
        $data = @{
            cycle  = @{ id = ""; start = ""; target = $Target; count = 0 }
            history = @()
        }
    }

    # Self-heal: init creates cycle with id="" (see lines 62-73); Reset is the
    # only writer of id, but it runs solely manually or on target-met. Any
    # -Increment calls (e.g. via close-session) before the first Reset leave
    # id="" with count>0. Heal lazily: first invocation seeing empty id
    # assigns one — count semantics untouched (no gaming per R3).
    if ([string]::IsNullOrWhiteSpace($data.cycle.id)) {
        # WhatIf: skip heal mutation — init guards already prevent fresh-file creation under WhatIf
        if (-not $WhatIfPreference) {
            # E8: single Get-Date reuse (was 2 calls)
            $healNow = Get-Date
            $data.cycle.id = "CYC-" + $healNow.ToString("yyyyMMdd") + "-" + (Get-Random -Minimum 100 -Maximum 999)
            if ([string]::IsNullOrWhiteSpace($data.cycle.start)) {
                $data.cycle.start = $healNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
            $mutatedRef.Value = $true
            $dataRef.Value = $data
        }
    }

if ($Reset) {
    $shouldProcessMsg = "Reset inter-track cycle (current count: $($data.cycle.count))"
    if ($CallerPSCmdlet -and -not $CallerPSCmdlet.ShouldProcess($trackPath, $shouldProcessMsg)) {
        # WhatIf: skip mutation, report what would happen
        if (-not $Quiet) {
            Write-Host "[inter-track] WhatIf: would reset cycle (current count: $($data.cycle.count))" -ForegroundColor DarkGray
        }
    } else {
        # E8: single Get-Date reuse (was 3 calls)
        $resetNow = Get-Date
        $cycleId = "CYC-" + $resetNow.ToString("yyyyMMdd") + "-" + (Get-Random -Minimum 100 -Maximum 999)
        # Archive current cycle to history
        if ($data.cycle.count -gt 0) {
            $archived = [PSCustomObject]@{
                id     = $data.cycle.id
                start  = $data.cycle.start
                target = $data.cycle.target
                count  = $data.cycle.count
                end    = $resetNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
            $data.history = @($data.history) + @($archived)
        }
        $data.cycle = @{
            id     = $cycleId
            start  = $resetNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
            target = $Target
            count  = 0
        }
        $mutatedRef.Value = $true
        if (-not $Quiet) {
            Write-Host "[inter-track] Reset. New cycle: $cycleId (target: $Target)" -ForegroundColor Cyan
        }
    }
}

if ($Increment) {
    $shouldProcessMsg = "Increment inter-track count ($($data.cycle.count) → $([int]$data.cycle.count + 1))"
    if ($CallerPSCmdlet -and -not $CallerPSCmdlet.ShouldProcess($trackPath, $shouldProcessMsg)) {
        # WhatIf: skip mutation, report what would happen
        if (-not $Quiet) {
            Write-Host "[inter-track] WhatIf: would increment ($($data.cycle.count) → $([int]$data.cycle.count + 1))" -ForegroundColor DarkGray
        }
    } else {
        $data.cycle.count = [int]$data.cycle.count + 1
        $mutatedRef.Value = $true
        if (-not $Quiet) {
            $remaining = [int]$data.cycle.target - [int]$data.cycle.count
            if ($remaining -le 0) {
                Write-Host "[inter-track] [OK] Target met: $($data.cycle.count)/$($data.cycle.target)" -ForegroundColor Green
            } else {
                Write-Host "[inter-track] inter: $($data.cycle.count)/$($data.cycle.target) ($remaining remaining)" -ForegroundColor Yellow
            }
        }
        $dataRef.Value = $data
    }
}

# G7: ensure Reset mutations are persisted via ref (object reference already covers it, but be explicit)
if ($Reset) {
    $dataRef.Value = $data
}

# G7 callback receipt: record engram directive consumption (locked, append to history)
$recordedEvent = $null
$engramRecorded = $false
if ($RecordEngramEvent) {
    if ([string]::IsNullOrWhiteSpace($TopicKey)) {
        throw "RecordEngramEvent requires -TopicKey <string> (non-empty)"
    }
    $shouldProcessMsg = "Record engram event kind='$EventKind' topic_key='$TopicKey'"
    if ($PSCmdlet.ShouldProcess($trackPath, $shouldProcessMsg)) {
        $recordedEvent = [PSCustomObject]@{
            kind      = $EventKind
            topic_key = $TopicKey
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            cycle_id  = $data.cycle.id
        }
        $data.history = @($data.history) + @($recordedEvent)
        $dataRef.Value = $data
        $mutatedRef.Value = $true
        $engramRecorded = $true
        if (-not $Quiet) {
            Write-Host "[inter-track] Recorded engram event: $EventKind / $TopicKey (cycle: $($data.cycle.id))" -ForegroundColor Cyan
        }
    } else {
        # WhatIf: do not mutate, but report what would happen
        $recordedEvent = [PSCustomObject]@{
            kind      = $EventKind
            topic_key = $TopicKey
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            cycle_id  = $data.cycle.id
            whatIf    = $true
        }
        $engramRecorded = $false
        if (-not $Quiet) {
            Write-Host "[inter-track] WhatIf: would record engram event: $EventKind / $TopicKey" -ForegroundColor DarkGray
        }
    }
}

# Output
$result = [PSCustomObject]@{
    cycleId  = $data.cycle.id
    count    = [int]$data.cycle.count
    target   = [int]$data.cycle.target
    complete = ([int]$data.cycle.count -ge [int]$data.cycle.target)
    remaining = [Math]::Max(0, [int]$data.cycle.target - [int]$data.cycle.count)
}
if ($recordedEvent) {
    $result | Add-Member -NotePropertyName "engram_event" -NotePropertyValue $recordedEvent -Force
    $result | Add-Member -NotePropertyName "engram_recorded" -NotePropertyValue $engramRecorded -Force
}

if ($Quiet) {
    $result | ConvertTo-Json -Depth 4
} else {
    Write-Host "  Cycle: $($data.cycle.id) | inter: $($data.cycle.count)/$($data.cycle.target)" -ForegroundColor Cyan
    # Show score when in Show mode (used by !cycle)
    if (-not $Increment -and -not $Reset -and -not $RecordEngramEvent) {
        $scorePath = Join-Path -Path $repoRoot -ChildPath ".project.json"
        if (Test-Path $scorePath) {
            try {
                $scoreData = Get-Content $scorePath -Raw | ConvertFrom-Json
                Write-Host "  Score: $($scoreData.score.current)/10 (trend: $($scoreData.score.trend))" -ForegroundColor Green
            } catch {
                Write-Debug "inter-track: cannot read score ($($_.Exception.Message))"
            }
        }
    }
}
} # /Invoke-TrackLocked -Action
} # /WhatIf guard else
