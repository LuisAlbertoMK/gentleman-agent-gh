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
  # For read/status/close
  [string]$Id, [string]$Since, [string]$Status, [string]$Resolution,
  [switch]$Json, [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$bridgeJsonl = "D:\TEMP\opencode-bridge.jsonl"
$bridgeMd    = "D:\TEMP\opencode-error-analysis-report.md"
$checkpoint  = "D:\TEMP\.bridge-checkpoint"

# ── Ensure parent dir exists ─────────────────────────────────────────────
$parent = Split-Path $bridgeJsonl -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

# ── Helpers ──────────────────────────────────────────────────────────────
function Update-Checkpoint {
  $hash = (Get-FileHash -LiteralPath $bridgeJsonl -Algorithm SHA256).Hash
  Set-Content -LiteralPath $checkpoint -Value $hash -NoNewline
}

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
    Update-Checkpoint
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
    Update-Checkpoint
    if (-not $Quiet) { Write-Output "Closed: $Id" }
  }

  "checkpoint" {
    if (-not (Test-Path $bridgeJsonl)) { if (-not $Quiet) { Write-Output "No bridge files" }; return }
    $prevHash = Get-Content $checkpoint -ErrorAction SilentlyContinue
    $currHash = (Get-FileHash -LiteralPath $bridgeJsonl -Algorithm SHA256).Hash
    $changed = ($prevHash -and $currHash -and $prevHash -ne $currHash)
    if ($changed) {
      Set-Content -LiteralPath $checkpoint -Value $currHash -NoNewline
      if (-not $Quiet) {
        Write-Output "Bridge changed! Latest:"
        Get-BridgeEntries | Select-Object -Last 3 | ForEach-Object {
          Write-Output "  [$($_.source)] $($_.id): $($_.message)"
        }
      }
    }
    else { if (-not $Quiet) { Write-Output "Bridge unchanged" } }
    if ($Json) { ConvertTo-Json @{previousHash=$prevHash; currentHash=$currHash; changed=$changed} }
  }
}
