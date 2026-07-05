#requires -Version 7.6
<#
.SYNOPSIS
  Lightweight pre-session bridge detect — stat-only, ~0 tokens.
  Called via §J Pre-session Health Check (INBYPASSABLE).
.DESCRIPTION
  Compares JSONL file size vs per-project checkpoint offset.
  DETECTS only — NEVER writes checkpoint. MCP server is sole owner.
  If new messages exist, agent must call MCP bridge_read to process.
.PARAMETER Json
  Output JSON for agent consumption.
#>
param(
  [string]$Source = "gentleman-gh",
  [switch]$Json
)
Set-StrictMode -Version Latest

if ($env:BRIDGE_PROJECT_SLUG) { $Source = $env:BRIDGE_PROJECT_SLUG }

$bridgeJsonl = "D:\TEMP\opencode-bridge.jsonl"
$checkpointFile = "D:\TEMP\.bridge-checkpoint.$Source"

if (-not (Test-Path $bridgeJsonl)) {
  $result = @{source=$Source; hasNew=$false; error="No bridge file"}
  if ($Json) { return ConvertTo-Json $result }
  return $false
}

$lastOffset = if (Test-Path $checkpointFile) {
  $val = Get-Content $checkpointFile -Raw -ErrorAction SilentlyContinue
  if ($val -match '^\d+') { [long]$val } else { 0L }
} else { 0L }

$currentSize = (Get-Item $bridgeJsonl).Length

if ($currentSize -le $lastOffset) {
  $result = @{source=$Source; hasNew=$false; lastOffset=$lastOffset}
  if ($Json) { return ConvertTo-Json $result }
  return $false
}

$result = @{
  source=$Source
  hasNew=$true
  lastOffset=$lastOffset
  newBytes=($currentSize - $lastOffset)
}
if ($Json) { return ConvertTo-Json $result }
return $true
