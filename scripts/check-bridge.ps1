#requires -Version 7.6
<#
.SYNOPSIS
  Session-resume bridge hook — check for new messages from opencode-vMK.
  Part of P2b: automated bridge detection on session start.
.DESCRIPTION
  Reads the per-agent byte-offset checkpoint and detects new entries.
  If new messages exist, reads and displays them, then updates the checkpoint.
  Designed to run automatically at session start (pre-session gate).
.PARAMETER Source
  Agent name (default: gentleman-vmk).
.PARAMETER Json
  Output JSON for agent consumption.
#>
param(
  [string]$Source = "gentleman-vmk",
  [switch]$Json
)
Set-StrictMode -Version Latest

$bridgeJsonl = "D:\TEMP\opencode-bridge.jsonl"
$checkpointFile = "D:\TEMP\.bridge-checkpoint.$Source"

if (-not (Test-Path $bridgeJsonl)) {
  if ($Json) { ConvertTo-Json @{source=$Source; hasNew=$false; error="No bridge file"} }
  else { Write-Output "Bridge: no file yet" }
  exit 0
}

# Get current offset
$lastOffset = if (Test-Path $checkpointFile) {
  $val = Get-Content $checkpointFile -Raw -ErrorAction SilentlyContinue
  if ($val -match '^\d+') { [long]$val } else { 0L }
} else { 0L }

$currentSize = (Get-Item $bridgeJsonl).Length

if ($currentSize -le $lastOffset) {
  if ($Json) { ConvertTo-Json @{source=$Source; hasNew=$false; lastOffset=$lastOffset} }
  else { Write-Output "Bridge: no new messages for $Source" }
  exit 0
}

# Read new bytes and update checkpoint
$stream = $null; $reader = $null
try {
  $stream = [System.IO.File]::Open($bridgeJsonl, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
  $stream.Seek($lastOffset, [System.IO.SeekOrigin]::Begin) | Out-Null
  $reader = [System.IO.StreamReader]::new($stream)
  $text = $reader.ReadToEnd()
  $newOffset = $stream.Position
  Set-Content $checkpointFile -Value $newOffset -NoNewline
} finally {
  if ($reader) { $reader.Dispose() }
  if ($stream) { $stream.Dispose() }
}

$newEntries = ($text -split '\r?\n' | Where-Object { $_ -match '\S' } |
  ForEach-Object { $_ | ConvertFrom-Json -ErrorAction SilentlyContinue } |
  Where-Object { $_ -ne $null })
$count = ($newEntries | Measure-Object).Count

if ($Json) {
  ConvertTo-Json @{
    source=$Source; hasNew=$true; count=$count
    lastOffset=$lastOffset; newOffset=$newOffset
    entries = $newEntries
  } -Depth 3
} else {
  Write-Output ""
  Write-Output "═══════════════════════════════════════════"
  Write-Output "  📨 BRIDGE — $count new message(s) from opencode-vMK"
  Write-Output "═══════════════════════════════════════════"
  $newEntries | ForEach-Object {
    $icon = switch ($_.source) {
      "opencode-vmk"  { "📤" }
      "gentleman-vmk" { "📥" }
      default         { "📋" }
    }
    $idLabel = if ($_.id -and $_.id -ne "?") { " [$($_.id)]" } else { "" }
    Write-Output ""
    Write-Output "$icon$idLabel from $($_.source):"
    Write-Output "  $($_.message)"
    if ($_.type) { Write-Output "  Type: $($_.type) · Severity: $(if($_.severity){$_.severity}else{'—'})" }
  }
  Write-Output ""
  Write-Output "───────────────────────────────────────────"
  Write-Output "  Run 'bridge.ps1 -Command read' for full history"
  Write-Output "  Run 'bridge.ps1 -Command close -Id <id>' to resolve"
  Write-Output "═══════════════════════════════════════════"
}
