#requires -Version 7.6
<#
.SYNOPSIS
  Bridge CLI for inter-agent communication between opencode-vMK and gentleman-vMK.
  Part of P2 — Autonomous Integration Plan.
.DESCRIPTION
  Reads/writes structured events to D:\TEMP\opencode-bridge.jsonl (machine) and
  updates D:\TEMP\opencode-error-analysis-report.md (human).
  Commands: write, read, status, close, checkpoint
#>
param(
  [Parameter(Mandatory)]
  [ValidateSet("write","read","status","close","checkpoint")]
  [string]$Command,
  # For write
  [ValidateSet("opencode-vmk","gentleman-vmk","opencode-global")]
  [string]$Source,
  [ValidateSet("error","fix","finding","proposal","agreement")]
  [string]$Type,
  [ValidateSet("critical","high","medium","low")]
  [string]$Severity,
  [string]$Component, [string]$Message, [string]$Fix, [string]$Refs,
  # For read/status/close/checkpoint
  [string]$Id, [string]$Since, [string]$Status, [string]$Resolution,
  [switch]$Json, [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$bridgeJsonl = "D:\TEMP\opencode-bridge.jsonl"
$bridgeMd    = "D:\TEMP\opencode-error-analysis-report.md"

# ── Ensure parent dir exists ─────────────────────────────────────────────
$parent = Split-Path $bridgeJsonl -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

# ── Per-agent byte-offset checkpoint ────────────────────────────────────
# Each agent tracks its own cursor position in the JSONL file.
# Write NEVER updates checkpoint — only the reader does, after processing.
function Get-AgentCheckpoint {
  param([string]$Agent)
  if (-not $Agent) { $Agent = "gentleman-vmk" }
  $cp = "D:\TEMP\.bridge-checkpoint.$Agent"
  if (Test-Path $cp) {
    $val = Get-Content $cp -Raw -ErrorAction SilentlyContinue
    if ($val -match '^\d+') { return [long]$val }
  }
  # First time → init to current file size (ignore all existing content)
  $sz = if (Test-Path $bridgeJsonl) { (Get-Item $bridgeJsonl).Length } else { 0L }
  Set-Content $cp -Value $sz -NoNewline
  return $sz
}

function Set-AgentCheckpoint {
  param([string]$Agent, [long]$Offset)
  if (-not $Agent) { $Agent = "gentleman-vmk" }
  $cp = "D:\TEMP\.bridge-checkpoint.$Agent"
  Set-Content $cp -Value $Offset -NoNewline
}

# ── Helpers ──────────────────────────────────────────────────────────────

function Get-Prefix {
  param([string]$Source)
  switch ($Source) {
    "opencode-vmk"   { "ERR" }
    "gentleman-vmk"  { "FND" }
    "opencode-global" { "REF" }
  }
}

function Safe-Prop {
  param($Obj, [string]$Name, $Default)
  if ($null -ne $Obj -and $Obj.PSObject.Properties.Name -contains $Name) { return $Obj.$Name }
  return $Default
}

function Normalize-Entry {
  param($Entry)
  if ($null -eq $Entry) { return $Entry }
  $Entry | Add-Member -NotePropertyName "id" -NotePropertyValue (Safe-Prop $Entry "id" "?") -Force -ErrorAction SilentlyContinue | Out-Null
  $Entry | Add-Member -NotePropertyName "source" -NotePropertyValue (Safe-Prop $Entry "source" (Safe-Prop $Entry "agent" "?")) -Force -ErrorAction SilentlyContinue | Out-Null
  $Entry | Add-Member -NotePropertyName "status" -NotePropertyValue (Safe-Prop $Entry "status" "open") -Force -ErrorAction SilentlyContinue | Out-Null
  return $Entry
}

function Get-BridgeEntries {
  if (-not (Test-Path $bridgeJsonl)) { return @() }
  $items = Get-Content $bridgeJsonl | ForEach-Object { Normalize-Entry ($_ | ConvertFrom-Json) }
  # Use -NoEnumerate to preserve array structure through pipeline
  Write-Output -NoEnumerate $items
}



# ── Command dispatch ─────────────────────────────────────────────────────
switch ($Command) {
  "write" {
    $existing = Get-BridgeEntries
    $last = $existing | Where-Object { $_.source -eq $Source } | Select-Object -Last 1
    $lastId = if ($last) { $last.id } else { $null }
    $nextNum = if ($lastId) { [int]($lastId -replace '^[A-Z]+-','') + 1 } else { 1 }
    $newId = "$(Get-Prefix $Source)-$($nextNum.ToString('D3'))"

    $entry = @{
      ts = (Get-Date -Format "o")
      source = $Source; type = $Type; id = $newId
      severity = $Severity; component = $Component; message = $Message
      fix = $Fix ?? ""
      refs = if ($Refs) { $Refs -split ',' | ForEach-Object { $_.Trim() } } else { @() }
      status = "open"
    }
    Add-Content $bridgeJsonl -Value (ConvertTo-Json $entry -Compress) -Encoding UTF8
    # ponytail: Do NOT update checkpoint on write — writer must not destroy
    # the detection signal for the other agent. Only the reader updates
    # its own per-agent checkpoint after processing new entries.
    if (-not $Quiet) { Write-Output "$newId — $Message (from $Source)" }
  }

  "read" {
    $entries = Get-BridgeEntries
    $total = ($entries | Measure-Object).Count
    if ($total -eq 0) { if (-not $Quiet) { Write-Output "Bridge empty" }; return }
    if ($Source) { $entries = $entries | Where-Object { $_.source -eq $Source } }
    if ($Type)   { $entries = $entries | Where-Object { (Safe-Prop $_ "type" "") -eq $Type } }
    if ($Status) { $entries = $entries | Where-Object { $_.status -eq $Status } }
    if ($Since)  { $entries = $entries | Where-Object { (Safe-Prop $_ "ts" "") -ge $Since } }
    if ($Id)     { $entries = $entries | Where-Object { $_.id -eq $Id } }
    if ($Json) { ConvertTo-Json @{entries = $entries; count = ($entries | Measure-Object).Count} -Depth 3 }
    elseif (-not $Quiet) {
      $remaining = ($entries | Measure-Object).Count
      if ($remaining -eq 0) { Write-Output "No matches" }
      else { $entries | ForEach-Object { Write-Output "$($_.id) [$($_.source)] $($_.message) — $($_.status)" } }
    }
  }

  "status" {
    $entries = Get-BridgeEntries
    $total = ($entries | Measure-Object).Count
    if ($total -eq 0) { if (-not $Quiet) { Write-Output "Bridge: empty" }; return }
    $open = ($entries | Where-Object { $_.status -eq "open" } | Measure-Object).Count
    $resolved = ($entries | Where-Object { $_.status -eq "resolved" } | Measure-Object).Count
    if ($Json) { ConvertTo-Json @{total = $total; open = $open; resolved = $resolved} }
    elseif (-not $Quiet) { Write-Output "Bridge: $total total | $open open | $resolved resolved" }
  }

  "close" {
    if (-not $Id) { Write-Error "close requires -Id"; exit 1 }
    if (-not (Test-Path $bridgeJsonl)) { Write-Error "Bridge not found"; exit 1 }
    $lines = Get-Content $bridgeJsonl
    $found = $false
    $newLines = foreach ($line in $lines) {
      $entry = Normalize-Entry ($line | ConvertFrom-Json)
      if ($entry.id -eq $Id) {
        $entry.status = "resolved"
        if ($Resolution) { $entry | Add-Member -NotePropertyName "resolution" -NotePropertyValue $Resolution -Force }
        $found = $true
        ConvertTo-Json $entry -Compress
      } else { $line }
    }
    if (-not $found) { Write-Error "ID not found: $Id"; exit 1 }
    $newLines | Set-Content $bridgeJsonl -Encoding UTF8
    # ponytail: Do NOT update checkpoint on close — same reason as write.
    # Note: close is NOT atomic (read-modify-write). Safe for sequential
    # use; concurrent close+write risks data loss (known, tracked).
    if (-not $Quiet) { Write-Output "Closed: $Id" }
  }

  "checkpoint" {
    $agent = if ($Source) { $Source } else { "gentleman-vmk" }
    if (-not (Test-Path $bridgeJsonl)) { if (-not $Quiet) { Write-Output "No bridge files" }; return }

    $lastOffset = Get-AgentCheckpoint $agent
    $currentSize = (Get-Item $bridgeJsonl).Length
    $hasNew = $currentSize -gt $lastOffset

      if ($hasNew) {
        # Read only the new bytes since last checkpoint
        $stream = $null; $reader = $null
        try {
          $stream = [System.IO.File]::Open($bridgeJsonl, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
          $stream.Seek($lastOffset, [System.IO.SeekOrigin]::Begin) | Out-Null
          $reader = [System.IO.StreamReader]::new($stream)
          $text = $reader.ReadToEnd()
          $newOffset = $stream.Position
          Set-AgentCheckpoint $agent $newOffset
        } finally {
          if ($reader) { $reader.Dispose() }
          if ($stream) { $stream.Dispose() }
        }

        $newEntries = ($text -split '\r?\n' | Where-Object { $_ -match '\S' } |
          ForEach-Object { Normalize-Entry ($_ | ConvertFrom-Json -ErrorAction SilentlyContinue) })
        $count = ($newEntries | Measure-Object).Count

        if (-not ($Quiet -or $Json)) {
          Write-Output "Bridge changed! $count new entries for $agent :"
          $newEntries | ForEach-Object {
            $icon = switch ($_.status) { "resolved" { "✓" } default { "○" } }
            Write-Output "  $icon [$($_.source)] $($_.id): $($_.message)"
          }
        }
        if ($Json) {
          ConvertTo-Json @{agent=$agent; lastOffset=$lastOffset; newOffset=$newOffset; newEntries=$count; entries=$newEntries} -Depth 3
        }
      } else {
        if (-not ($Quiet -or $Json)) { Write-Output "Bridge unchanged for $agent" }
        if ($Json) { ConvertTo-Json @{agent=$agent; lastOffset=$lastOffset; hasNew=$false} }
      }
  }
}
