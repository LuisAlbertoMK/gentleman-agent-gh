#!/usr/bin/env pwsh
#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
<#
.SYNOPSIS
    Universal runner — discover GENTLEMAN_AGENT_ROOT and invoke a repo script.

.DESCRIPTION
    Resolves the repo root even when invoked from the global junction at
    ~/.config/opencode/scripts/. Sets $env:GENTLEMAN_AGENT_ROOT and delegates
    to the named script in the repo's scripts/ directory.

    Portable: works on any machine via $env:USERPROFILE (system env var).
    No PS Profile dependency.

.EXAMPLE
    & "$env:USERPROFILE\.config\opencode\scripts\run.ps1" check-skill-drift.ps1 -Json
    & "$env:USERPROFILE\.config\opencode\scripts\run.ps1" close-session.ps1
#>

# No [Parameter()] block: uses $args (unbound) by design — universal runner delegates to named script.
# See .SYNOPSIS for usage.
$__dir = Split-Path $MyInvocation.MyCommand.Path -Parent
$__item = Get-Item $__dir

if ($__item.LinkType -eq "Junction" -and $__item.Target) {
    $env:GENTLEMAN_AGENT_ROOT = Split-Path $__item.Target -Parent
} else {
    $env:GENTLEMAN_AGENT_ROOT = Split-Path $__dir -Parent
}

if (-not $args -or $args.Count -eq 0) {
    Write-Error "Usage: run.ps1 <script.ps1> [args...]"
    exit 1
}

$__scriptName = $args[0]
$__scriptPath = Join-Path "$env:GENTLEMAN_AGENT_ROOT\scripts" $__scriptName

if (-not (Test-Path $__scriptPath)) {
    Write-Error "Script not found: $__scriptPath"
    exit 1
}

$__scriptArgs = @($args[1..$args.Length])
try {
    & $__scriptPath @__scriptArgs
    exit $LASTEXITCODE
} catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
