#requires -Version 7.6
<#
.SYNOPSIS
  MCP stdio server for multi-project bridge communication.
  Part of bridge v2 — per-project identity, no gentleman-vmk references.

.DESCRIPTION
  Implements JSON-RPC 2.0 over stdio (MCP protocol).
  Each project runs its own instance with a unique -ProjectId.
  Shared JSONL file, per-project byte-offset checkpoint.

  Tools:
    bridge_write   — Send a message to another project
    bridge_read    — Read new messages since last checkpoint
    bridge_status  — Bridge health and stats

  Resources:
    bridge://status        — Current bridge state
    bridge://messages/new  — Unread messages

.PARAMETER ProjectId
  Unique project slug (e.g. "gentleman-gh", "opencode").
  Used for checkpoint filename and message source field.
  NEVER use "gentleman-vmk" here.
#>
param(
  [Parameter(Mandatory)]
  [string]$ProjectId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Constants ──────────────────────────────────────────────────────────
$bridgeFile = "D:\TEMP\opencode-bridge.jsonl"
$checkpointFile = "D:\TEMP\.bridge-checkpoint.$ProjectId"
$protocolVersion = "2025-03-26"
$serverInfo = @{ name = "bridge-mcp-$ProjectId"; version = "2.0.0" }

# Ponytail: ProjectId is the SOLE identity — no agent name anywhere.
# The checkpoint file, source field, and ID prefix all derive from it.

# ── Helpers ────────────────────────────────────────────────────────────

function Get-Checkpoint {
  if (Test-Path $checkpointFile) {
    $val = Get-Content $checkpointFile -Raw -ErrorAction SilentlyContinue
    if ($val -match '^\d+') { return [long]$val }
  }
  return 0L
}

function Set-Checkpoint {
  param([long]$Offset)
  Set-Content $checkpointFile -Value $Offset -NoNewline
}

function Get-FileSize {
  if (Test-Path $bridgeFile) { return (Get-Item $bridgeFile).Length }
  return 0L
}

function Get-BridgeEntries {
  if (-not (Test-Path $bridgeFile)) { return @() }
  @(Get-Content $bridgeFile | ForEach-Object {
    try { $_ | ConvertFrom-Json -ErrorAction Stop }
    catch { $null }
  } | Where-Object { $_ -ne $null })
}

function Write-Message {
  param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)][string]$Message,
    [string]$Type = "text"
  )
  $entry = @{
    ts = (Get-Date -Format "o")
    source = $ProjectId
    target = $Target
    type = $Type
    message = $Message
  }
  Add-Content $bridgeFile -Value (ConvertTo-Json $entry -Compress) -Encoding UTF8
  # ponytail: NEVER update checkpoint on write — only reader does.
  return @{ ts = $entry.ts; source = $ProjectId; target = $Target }
}

function Read-NewMessages {
  param([bool]$Acknowledge = $true)
  $lastOffset = Get-Checkpoint
  $currentSize = Get-FileSize

  if ($currentSize -le $lastOffset) {
    return @{ hasNew = $false; lastOffset = $lastOffset; entries = @() }
  }

  # Delta read — only new bytes since last checkpoint
  $stream = $null; $reader = $null
  try {
    $stream = [System.IO.File]::Open($bridgeFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $stream.Seek($lastOffset, [System.IO.SeekOrigin]::Begin) | Out-Null
    $reader = [System.IO.StreamReader]::new($stream)
    $text = $reader.ReadToEnd()
    $newOffset = $stream.Position
    if ($Acknowledge) { Set-Checkpoint $newOffset }
  } finally {
    if ($reader) { $reader.Dispose() }
    if ($stream) { $stream.Dispose() }
  }

  $entries = @($text -split '\r?\n' | Where-Object { $_ -match '\S' } |
    ForEach-Object { try { $_ | ConvertFrom-Json -ErrorAction Stop } catch { $null } } |
    Where-Object { $_ -ne $null })

  # Filter: only messages TARGETED at this project OR broadcast (*)
  # AND not from ourselves
  # ponytail: @() ensures array type even under StrictMode (Where-Object
  # returns $null for 0 matches, and $null.Count throws with StrictMode)
  $myEntries = @($entries | Where-Object {
    $src = Safe-Prop $_ "source" (Safe-Prop $_ "agent" "")
    $tgt = Safe-Prop $_ "target" "*"
    $src -ne $ProjectId -and ($tgt -eq $ProjectId -or $tgt -eq "*")
  })

  return @{
    hasNew = ($myEntries.Count -gt 0)
    count = $myEntries.Count
    lastOffset = $lastOffset
    newOffset = $newOffset
    entries = $myEntries
  }
}

function Get-BridgeStatus {
  $fileSize = Get-FileSize
  $checkpoint = Get-Checkpoint
  $hasNew = $fileSize -gt $checkpoint
  $entries = Get-BridgeEntries
  $total = $entries.Count
  $toMe = @($entries | Where-Object {
    $tgt = Safe-Prop $_ "target" "*"
    $src = Safe-Prop $_ "source" (Safe-Prop $_ "agent" "")
    $src -ne $ProjectId -and ($tgt -eq $ProjectId -or $tgt -eq "*")
  }).Count
  $sources = @($entries | ForEach-Object {
    $s = Safe-Prop $_ "source" $null
    if ($s -and $s -ne $ProjectId) { $s }
  } | Select-Object -Unique)

  return @{
    projectId = $ProjectId
    fileSize = $fileSize
    checkpointOffset = $checkpoint
    hasNew = $hasNew
    totalMessages = $total
    unreadCount = $toMe
    connectedProjects = @($sources)
    checkpointFile = $checkpointFile
  }
}

# ── JSON-RPC 2.0 handlers ──────────────────────────────────────────────

# ponytail: StrictMode blocks non-existent property access on PSCustomObject.
# Use Safe-Prop everywhere when reading JSON request fields.
function Safe-Prop {
  param($Obj, [string]$Name, $Default)
  if ($null -ne $Obj -and $Obj.PSObject.Properties.Name -contains $Name) { return $Obj.$Name }
  return $Default
}

function New-JsonRpcError {
  param([int]$Code, [string]$Message, $Data)
  return @{ code = $Code; message = $Message; data = $Data }
}

function Send-Response {
  param($Id, $Result)
  $msg = @{ jsonrpc = "2.0"; id = $Id; result = $Result }
  ConvertTo-Json $msg -Compress -Depth 10
  Write-Output ""
}

function Send-Error {
  param($Id, [int]$Code, [string]$Message, $Data)
  $msg = @{ jsonrpc = "2.0"; id = $Id; error = New-JsonRpcError $Code $Message $Data }
  ConvertTo-Json $msg -Compress -Depth 5
  Write-Output ""
}

function Send-Notification {
  param([string]$Method, $Params)
  $msg = @{ jsonrpc = "2.0"; method = $Method; params = $Params }
  ConvertTo-Json $msg -Compress -Depth 10
  Write-Output ""
}

# ── MCP tool definitions ───────────────────────────────────────────────

$tools = @(
  @{
    name = "bridge_write"
    description = "Send a message to another project via the shared bridge"
    inputSchema = @{
      type = "object"
      properties = @{
        target = @{
          type = "string"
          description = "Project ID to send to (e.g. 'opencode') or '*' for broadcast"
        }
        message = @{
          type = "string"
          description = "Message content"
        }
        type = @{
          type = "string"
          description = "Message type: text, error, fix, proposal, agreement"
          enum = @("text", "error", "fix", "proposal", "agreement")
        }
      }
      required = @("target", "message")
    }
  }
  @{
    name = "bridge_read"
    description = "Read new messages sent to this project since last checkpoint"
    inputSchema = @{
      type = "object"
      properties = @{
        acknowledge = @{
          type = "boolean"
          description = "Update checkpoint after reading (default: true)"
        }
      }
      required = @()
    }
  }
  @{
    name = "bridge_status"
    description = "Show bridge health, checkpoint status, and project connections"
    inputSchema = @{
      type = "object"
      properties = @{}
      required = @()
    }
  }
)

$resources = @(
  @{
    uri = "bridge://status"
    name = "Bridge Status"
    description = "Current bridge state for $ProjectId"
    mimeType = "application/json"
  }
  @{
    uri = "bridge://messages/new"
    name = "New Messages"
    description = "Unread messages for $ProjectId"
    mimeType = "application/json"
  }
)

# ── Request router ────────────────────────────────────────────────────

function Handle-Request {
  param($Request)
  # ponytail: StrictMode requires Safe-Prop for all JSON property access
  $id = Safe-Prop $Request "id" $null
  $method = Safe-Prop $Request "method" $null
  $params = Safe-Prop $Request "params" @{}

  switch ($method) {
    "initialize" {
      Send-Response $id @{
        protocolVersion = $protocolVersion
        capabilities = @{
          tools = @{}
          resources = @{}
        }
        serverInfo = $serverInfo
      }
    }
    "initialized" {
      # Notification — no response needed
    }
    "ping" {
      Send-Response $id @{}
    }
    "tools/list" {
      Send-Response $id @{ tools = $tools }
    }
    "tools/call" {
      $toolName = Safe-Prop $params "name" ""
      $arguments = Safe-Prop $params "arguments" @{}
      if (-not $arguments) { $arguments = @{} }

      switch ($toolName) {
        "bridge_write" {
          $target = Safe-Prop $arguments "target" ""
          $message = Safe-Prop $arguments "message" ""
          $type = Safe-Prop $arguments "type" "text"
          # backward compat: `text` legacy param
          if (-not $message) { $message = Safe-Prop $arguments "text" "" }
          if (-not $target -or -not $message) {
            Send-Error $id -32602 "Missing required parameters: target, message"
            return
          }
          $result = Write-Message -Target $target -Message $message -Type $type
          # Signal resource change so client can refresh
          Send-Notification "notifications/resources/list_changed" @{}
          Send-Response $id $result
        }
        "bridge_read" {
          $ack = if ($arguments.PSObject.Properties.Name -contains "acknowledge") { [bool]$arguments.acknowledge } else { $true }
          $result = Read-NewMessages -Acknowledge $ack
          Send-Response $id $result
        }
        "bridge_status" {
          $result = Get-BridgeStatus
          Send-Response $id $result
        }
        default {
          Send-Error $id -32601 "Tool not found: $toolName"
        }
      }
    }
    "resources/list" {
      Send-Response $id @{ resources = $resources }
    }
    "resources/read" {
      $uri = Safe-Prop $params "uri" ""
      switch ($uri) {
        "bridge://status" {
          $status = Get-BridgeStatus
          Send-Response $id @{
            contents = @(@{
              uri = $uri
              mimeType = "application/json"
              text = (ConvertTo-Json $status -Depth 3)
            })
          }
        }
        "bridge://messages/new" {
          $msgs = Read-NewMessages -Acknowledge $false
          Send-Response $id @{
            contents = @(@{
              uri = $uri
              mimeType = "application/json"
              text = (ConvertTo-Json $msgs -Depth 5)
            })
          }
        }
        default {
          Send-Error $id -32602 "Resource not found: $uri"
        }
      }
    }
    default {
      Send-Error $id -32601 "Method not found: $method"
    }
  }
}

# ── Main loop ──────────────────────────────────────────────────────────

# Ensure bridge file parent exists
$parent = Split-Path $bridgeFile -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

# Initialize checkpoint to current file size on first run (ignore history)
if (-not (Test-Path $checkpointFile)) {
  Set-Checkpoint (Get-FileSize)
}

# Read stdin line by line (JSON-RPC 2.0 over stdio)
try {
  $stdin = [System.Console]::OpenStandardInput()
  $reader = [System.IO.StreamReader]::new($stdin)
  while (($line = $reader.ReadLine()) -ne $null) {
    $line = $line.Trim()
    if (-not $line) { continue }
    try {
      $request = $line | ConvertFrom-Json
      if ($request.id -and $request.method) {
        Handle-Request $request
      }
      # Notifications (no id) are silently accepted per JSON-RPC spec
    } catch {
      # Try to send error for parse failures with id, else ignore
      try {
        $partial = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($partial.id) {
          Send-Error $partial.id -32700 "Parse error: $_"
        }
      } catch {
        # Completely unparseable — ignore
      }
    }
  }
} finally {
  if ($reader) { $reader.Dispose() }
  if ($stdin) { $stdin.Dispose() }
}
