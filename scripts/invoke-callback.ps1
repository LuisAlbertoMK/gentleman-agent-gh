#requires -Version 7
[CmdletBinding()]
<#
.SYNOPSIS
    Push completion callback handler for async subagent delegations.

.DESCRIPTION
    Standalone handler invoked by monitor-subagent.ps1 after an async
    post-delegation check produces its final result. Writes the result
    atomically to {RepoRoot}\{TaskId}.async-result.json and creates a signal
    file {RepoRoot}\{TaskId}.async-done so a FileSystemWatcher-based waiter
    (babyagi-loop.ps1) is notified without polling.

    Logs to stderr so stdout stays clean for the caller. Exits 0 on success.

.PARAMETER ResultJson
    Serialized result object (JSON string) produced by the monitor.

.PARAMETER TaskId
    Delegation task identifier — names the result and signal files.

.PARAMETER RepoRoot
    Repository root where result and signal files are written. Optional: the
    monitor invokes callbacks with only -ResultJson/-TaskId, so this defaults to
    the repo root derived from this script's location.

.EXAMPLE
    scripts\invoke-callback.ps1 -ResultJson '{"status":"OK"}' -TaskId task_1_HEAD -RepoRoot "D:\repo"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ResultJson,

    [Parameter(Mandatory=$true)]
    [string]$TaskId,

    [string]$RepoRoot = $(Split-Path -Parent $PSScriptRoot)
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Sanitize TaskId for path safety (mirrors monitor-subagent.ps1 fileSafeBase)
$fileSafeTask = $TaskId -replace '[/\\:*?"<>|]', '_'
$resultFile = Join-Path $RepoRoot ($fileSafeTask + '.async-result.json')
$signalFile = Join-Path $RepoRoot ($fileSafeTask + '.async-done')

# 1. Write result atomically (temp file + Move-Item)
$tmpFile = $resultFile + '.tmp'
$ResultJson | Set-Content -Path $tmpFile -Encoding UTF8
Move-Item -LiteralPath $tmpFile -Destination $resultFile -Force

# 2. Create signal file AFTER the result exists (waiter reads result on signal)
Set-Content -Path $signalFile -Value (Get-Date -Format "o") -Encoding UTF8

# 3. Log to stderr (stdout stays clean for the orchestrator)
[Console]::Error.WriteLine("[callback] invoked for TaskId=$TaskId")

exit 0
