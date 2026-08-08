#requires -Version 7
<#
.SYNOPSIS
    Async delegation registry — manages state for non-blocking subagent delegations.

.DESCRIPTION
    Tracks pending, running, and completed subagent delegations so the orchestrator
    can continue working while subagents run in the background. Supports:
      - register:  Store delegation metadata (task_id, scope, base_ref)
      - poll:      Check if a delegation is still pending
      - resolve:   Run post-delegation-check for a completed delegation
      - re-prompt: Re-inject instructions into a running subagent (dynamic modification)
      - list:      List all delegations with status

    State is persisted in .learnings/delegation-registry.json (atomic reads/writes).
    Each entry has a TTL (default 60 min) after which it's auto-purged.

.PARAMETER Action
    The registry operation to perform.

.PARAMETER TaskId
    The Task-tool ID (for poll/resolve/re-prompt).

.PARAMETER AllowedPaths
    Regex pattern(s) for write-scope validation (for register).

.PARAMETER ExpectedFiles
    Filenames expected in the diff (for register).

.PARAMETER BaseRef
    Git reference to diff against (for register, default HEAD).

.PARAMETER NewPrompt
    New instructions for re-prompt (for re-prompt).

.PARAMETER TtlMinutes
    Time-to-live for registry entries (default 60).

.PARAMETER RepoRoot
    Repository root (default: parent of script dir).

.PARAMETER Quiet
    JSON-only output on stdout.

.EXAMPLE
    # Register an async delegation
    scripts/delegation-registry.ps1 -Action register -TaskId "abc-123" -AllowedPaths "src/*"

    # Poll status (returns pending/running/done)
    scripts/delegation-registry.ps1 -Action poll -TaskId "abc-123"

    # Resolve (run post-delegation-check on completed work)
    scripts/delegation-registry.ps1 -Action resolve -TaskId "abc-123"

    # Re-prompt a running subagent
    scripts/delegation-registry.ps1 -Action re-prompt -TaskId "abc-123" -NewPrompt "Focus on error handling"

    # List all delegations
    scripts/delegation-registry.ps1 -Action list
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("register","poll","resolve","re-prompt","list")]
    [string]$Action,

    [string]$TaskId = "",
    [string[]]$AllowedPaths = @(),
    [string[]]$ExpectedFiles = @(),
    [string]$BaseRef = "HEAD",
    [string]$NewPrompt = "",
    [int]$TtlMinutes = 60,
    [string]$RepoRoot = "",
    [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
    while ($RepoRoot -and -not (Test-Path (Join-Path $RepoRoot '.git'))) {
        $RepoRoot = Split-Path -Parent $RepoRoot
    }
}

$registryDir = Join-Path $RepoRoot '.learnings'
$registryFile = Join-Path $registryDir 'delegation-registry.json'

# Ensure .learnings exists
if (-not (Test-Path $registryDir)) {
    New-Item -ItemType Directory -Path $registryDir -Force | Out-Null
}

# --- Load registry (with retry) ---
function Get-RegistryData {
    if (-not (Test-Path $registryFile)) { return @{} }
    try {
        $raw = Get-Content $registryFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $result = @{}
        foreach ($prop in $raw.PSObject.Properties) {
            $result[$prop.Name] = $prop.Value
        }
        return $result
    } catch {
        Write-Debug "delegation-registry: load failed: $($_.Exception.Message)"
        return @{}
    }
}

# --- Save registry (atomic write) ---
function Set-RegistryData {
    [CmdletBinding(SupportsShouldProcess)]
    param([hashtable]$Registry)
    $tmpFile = $registryFile + '.tmp'
    if ($PSCmdlet.ShouldProcess($registryFile, "Save registry")) {
        $Registry | ConvertTo-Json -Depth 10 | Set-Content $tmpFile -Encoding UTF8
        Move-Item -LiteralPath $tmpFile -Destination $registryFile -Force
    }
}

# --- Prune expired entries ---
function Clear-RegistryExpired {
    [CmdletBinding(SupportsShouldProcess)]
    param([hashtable]$Registry, [int]$MaxAgeMinutes)
    $now = Get-Date
    $expired = @($Registry.Keys | Where-Object {
        $entry = $Registry[$_]
        $entryAge = ($now - [datetime]$entry.registered).TotalMinutes
        $entryAge -gt $MaxAgeMinutes
    })
    if ($PSCmdlet.ShouldProcess("registry", "Prune expired entries")) {
        foreach ($k in $expired) { $Registry.Remove($k) }
    }
    return $Registry
}

# --- Main ---
$reg = Clear-RegistryExpired (Get-RegistryData) $TtlMinutes

switch ($Action) {
    "register" {
        if (-not $TaskId) { throw "register requires -TaskId" }
        if (-not $AllowedPaths) { throw "register requires -AllowedPaths (fail-closed)" }

        if ($reg.ContainsKey($TaskId)) {
            Write-Warning "delegation-registry: TaskId '$TaskId' already registered — overwriting"
        }

        $reg[$TaskId] = @{
            registered    = (Get-Date -Format "o")
            task_id       = $TaskId
            base_ref      = $BaseRef
            allowed_paths = @($AllowedPaths)
            expected_files = @($ExpectedFiles)
            status        = "pending"
            prompt        = ""
            re_prompts    = @()
        }
        Set-RegistryData $reg

        if ($Quiet) {
            @{ status = "registered"; task_id = $TaskId; registry = $reg[$TaskId].status } | ConvertTo-Json -Compress
        } else {
            Write-Output "[delegation-registry] registered: $TaskId (status: pending)"
        }
    }

    "poll" {
        if (-not $TaskId) { throw "poll requires -TaskId" }
        if (-not $reg.ContainsKey($TaskId)) {
            if ($Quiet) { @{ status = "not_found"; task_id = $TaskId } | ConvertTo-Json -Compress }
            else { Write-Output "[delegation-registry] not found: $TaskId" }
            exit 1
        }
        $entry = $reg[$TaskId]
        # Update status
        if ($entry.status -eq "pending") {
            $entry.status = "running"
            $reg[$TaskId] = $entry
            Set-RegistryData $reg
        }
        if ($Quiet) {
            @{ status = $entry.status; task_id = $TaskId; registered = $entry.registered } | ConvertTo-Json -Compress
        } else {
            Write-Output "[delegation-registry] $($TaskId): $($entry.status) (since $($entry.registered))"
        }
    }

    "resolve" {
        if (-not $TaskId) { throw "resolve requires -TaskId" }
        if (-not $reg.ContainsKey($TaskId)) {
            if ($Quiet) { @{ status = "not_found"; task_id = $TaskId } | ConvertTo-Json -Compress }
            else { Write-Output "[delegation-registry] not found: $TaskId" }
            exit 1
        }
        $entry = $reg[$TaskId]

        # Run post-delegation-check with stored params
        $pdcScript = Join-Path $RepoRoot 'scripts\post-delegation-check.ps1'
        $cmd = "& '$pdcScript' -BaseRef '$($entry.base_ref)' -RepoRoot '$RepoRoot' -Quiet"
        if ($entry.allowed_paths) {
            $paths = ($entry.allowed_paths | ForEach-Object { "'" + ($_ -replace "'","''") + "'" }) -join ' '
            $cmd += " -AllowedPaths $paths"
        }
        if ($entry.expected_files) {
            $files = ($entry.expected_files | ForEach-Object { "'" + ($_ -replace "'","''") + "'" }) -join ' '
            $cmd += " -ExpectedFiles $files"
        }
        $cmd += " -TimeoutSeconds 30"

        $result = & pwsh -NoProfile -Command $cmd 2>&1
        $jsonLine = $result | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue

        $entry.status = if ($json -and $json.passed) { "resolved" } else { "failed" }
        $entry | Add-Member -NotePropertyName "resolved" -NotePropertyValue (Get-Date -Format "o") -Force
        $reg[$TaskId] = $entry
        Set-RegistryData $reg

        if ($Quiet) {
            @{ status = $entry.status; task_id = $TaskId; passed = if ($json) { $json.passed } else { $false } } | ConvertTo-Json -Compress
        } else {
            $icon = if ($entry.status -eq "resolved") { "OK  " } else { "FAIL" }
            Write-Output "[$icon] delegation-registry: $TaskId resolved -> $($entry.status)"
        }
    }

    "re-prompt" {
        if (-not $TaskId) { throw "re-prompt requires -TaskId" }
        if (-not $reg.ContainsKey($TaskId)) {
            if ($Quiet) { @{ status = "not_found"; task_id = $TaskId } | ConvertTo-Json -Compress }
            else { Write-Output "[delegation-registry] not found: $TaskId" }
            exit 1
        }
        if (-not $NewPrompt) { throw "re-prompt requires -NewPrompt" }

        $entry = $reg[$TaskId]
        $newReprompts = @($entry.re_prompts) + @(@{ at = (Get-Date -Format "o"); prompt = $NewPrompt })
        $entry | Add-Member -NotePropertyName "re_prompts" -NotePropertyValue $newReprompts -Force
        $entry.status = "re-prompted"
        $reg[$TaskId] = $entry
        Set-RegistryData $reg

        # Write the re-prompt instructions to a temp file that the orchestrator
        # can pick up before calling task() with the same task_id
        $promptFile = Join-Path $RepoRoot ".learnings\delegation-$TaskId-re-prompt.md"
        $NewPrompt | Set-Content $promptFile -Encoding UTF8

        if ($Quiet) {
            @{ status = "re-prompted"; task_id = $TaskId; prompt_file = $promptFile } | ConvertTo-Json -Compress
        } else {
            Write-Output "[delegation-registry] re-prompted: $TaskId (prompt saved to $promptFile)"
            Write-Output "  The orchestrator should read this file and re-invoke task() with updated instructions."
        }
    }

    "list" {
        if ($Quiet) {
            $reg.Values | ConvertTo-Json -Compress
        } else {
            Write-Output "[delegation-registry] Active delegations:"
            if ($reg.Count -eq 0) {
                Write-Output "  (none)"
            } else {
                $reg.Values | Sort-Object registered | ForEach-Object {
                    Write-Output "  $($_.task_id): $($_.status) (registered: $($_.registered))"
                }
            }
        }
    }
}
