#requires -Version 7
<#
.SYNOPSIS
    Async delegation registry — state for non-blocking subagent delegations.
.DESCRIPTION
    Tracks pending/running/completed subagent delegations so the orchestrator keeps
    working while subagents run in background. Actions: register, poll, resolve,
    re-prompt, list. State persisted in .learnings/delegation-registry.json (atomic),
    TTL auto-purge (default 60 min), thread-safe via named mutex.
.PARAMETER Action
    Registry operation to perform.
.PARAMETER TaskId
    Task-tool ID (for poll/resolve/re-prompt).
.PARAMETER AllowedPaths
    Regex pattern(s) for write-scope validation (register).
.PARAMETER ExpectedFiles
    Filenames expected in the diff (register).
.PARAMETER BaseRef
    Git reference to diff against (register, default HEAD).
.PARAMETER NewPrompt
    New instructions for re-prompt.
.PARAMETER TtlMinutes
    TTL for registry entries (default 60).
.PARAMETER RepoRoot
    Repository root (default: parent of script dir).
.PARAMETER Quiet
    JSON-only output on stdout.
.EXAMPLE
    scripts/delegation-registry.ps1 -Action register -TaskId "abc-123" -AllowedPaths "src/*"
    scripts/delegation-registry.ps1 -Action poll -TaskId "abc-123"
    scripts/delegation-registry.ps1 -Action resolve -TaskId "abc-123"
    scripts/delegation-registry.ps1 -Action re-prompt -TaskId "abc-123" -NewPrompt "Focus on error handling"
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
    [int]$TimeoutSeconds = 60,
    [int]$MaxToolCalls = 25,
    [string]$SubagentOutputFile = "",
    [string]$RepoRoot = "",
    [switch]$Quiet
)

# New params documented in header
if ($SubagentOutputFile -and -not $Quiet) {
    Write-Debug "delegation-registry: -SubagentOutputFile '$SubagentOutputFile' stored"
}
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

# Concurrency control: named mutex prevents race on registry file
# Named "Global\..." so it works across pwsh subprocess invocations.
$repoId = ([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($RepoRoot)) | ForEach-Object { $_.ToString("x2") }) -join ''
$mutexName = "Global\GentlemanDelegationRegistry-$repoId"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)
$mutexAcquired = $false
try {
    $mutexAcquired = $mutex.WaitOne(10000)  # 10s timeout
    if (-not $mutexAcquired) {
        throw "delegation-registry: could not acquire lock within 10s (another instance may be stuck)"
    }

# Load registry
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
        Write-Warning "delegation-registry: registry load failed — starting fresh. Error: $($_.Exception.Message)"
        # Preserve a corrupted backup for diagnosis
        $corruptBackup = $registryFile + '.corrupt'
        Copy-Item -LiteralPath $registryFile -Destination $corruptBackup -Force -ErrorAction SilentlyContinue
        return @{}
    }
}

# Save registry (atomic: write .tmp → Move-Item)
function Set-RegistryData {
    [CmdletBinding(SupportsShouldProcess)]
    param([hashtable]$Registry)
    $tmpFile = $registryFile + '.tmp'
    if ($PSCmdlet.ShouldProcess($registryFile, "Save registry")) {
        $Registry | ConvertTo-Json -Depth 10 | Set-Content $tmpFile -Encoding UTF8
        Move-Item -LiteralPath $tmpFile -Destination $registryFile -Force
    }
}

# Prune expired entries
function Clear-RegistryExpired {
    [CmdletBinding(SupportsShouldProcess)]
    param([hashtable]$Registry, [int]$MaxAgeMinutes)
    if ($Registry.Count -eq 0) { return $Registry }
    $now = Get-Date
    $expired = @($Registry.Keys | Where-Object {
        $entry = $Registry[$_]
        if (-not $entry.registered) { return $true }
        try {
            $entryAge = ($now - [datetime]$entry.registered).TotalMinutes
            $entryAge -gt $MaxAgeMinutes
        } catch {
            $true  # Unparseable date → prune
        }
    })
    if ($PSCmdlet.ShouldProcess("registry", "Prune expired entries")) {
        foreach ($k in $expired) { $Registry.Remove($k) }
    }
    return $Registry
}

# TTL pruning throttle: skip if pruned within the last minute
$pruneMarker = Join-Path $registryDir '.last-prune'
$shouldPrune = $true
if (Test-Path $pruneMarker) {
    try {
        $lastPrune = [DateTime](Get-Content $pruneMarker -Raw -Encoding UTF8 -ErrorAction SilentlyContinue)
        if ((Get-Date) - $lastPrune -lt [TimeSpan]::FromMinutes(1)) {
            $shouldPrune = $false
        }
    } catch {
        Write-Debug "delegation-registry: prune marker corrupt — pruning anyway"
    }
}

# Main: load + prune, then dispatch
if ($shouldPrune) {
    $reg = Clear-RegistryExpired (Get-RegistryData) $TtlMinutes
    Set-Content $pruneMarker -Value (Get-Date -Format "o") -NoNewline -Encoding UTF8
} else {
    $reg = Get-RegistryData
}

switch ($Action) {
    "register" {
        if (-not $TaskId) { throw "register requires -TaskId" }
        if (-not $AllowedPaths) { throw "register requires -AllowedPaths (fail-closed)" }

        if ($reg.ContainsKey($TaskId)) {
            Write-Warning "delegation-registry: TaskId '$TaskId' already registered — overwriting"
        }

        $reg[$TaskId] = @{
            registered         = (Get-Date -Format "o")
            task_id            = $TaskId
            base_ref           = $BaseRef
            allowed_paths      = @($AllowedPaths)
            expected_files     = @($ExpectedFiles)
            timeout_seconds    = $TimeoutSeconds
            max_tool_calls     = $MaxToolCalls
            subagent_output    = $SubagentOutputFile
            status             = "pending"
            prompt             = ""
            re_prompts         = @()
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
        # Update status: pending → running on first poll
        if ($entry.status -eq "pending") {
            $entry.status = "running"
            $reg[$TaskId] = $entry
            Set-RegistryData $reg
        }
        # Compute budget tracking
        $registered = if ($entry.registered) { [DateTime]$entry.registered } else { Get-Date }
        $elapsedSeconds = (Get-Date) - $registered | Select-Object -ExpandProperty TotalSeconds
        $timeoutSeconds = if ($entry.timeout_seconds) { $entry.timeout_seconds } else { 300 }
        $budgetExceeded = $elapsedSeconds -gt $timeoutSeconds
        $effectiveStatus = if ($budgetExceeded) { "timeout" } else { $entry.status }
        if ($Quiet) {
            @{
                status           = $effectiveStatus
                task_id          = $TaskId
                registered       = $entry.registered
                budget_exceeded  = $budgetExceeded
                elapsed_seconds  = [math]::Round($elapsedSeconds, 1)
                timeout_seconds  = $timeoutSeconds
            } | ConvertTo-Json -Compress
        } else {
            $icon = if ($budgetExceeded) { "TIMEOUT" } else { "OK   " }
            Write-Output "[$icon] budget-guard: $($TaskId) elapsed=$([math]::Round($elapsedSeconds,1))s / limit=$($timeoutSeconds)s"
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

        # Run post-delegation-check in a subprocess — it uses exit which would kill us via &
        $pdcScript = Join-Path $RepoRoot 'scripts\post-delegation-check.ps1'
        $resolveTimeout = if ($entry.timeout_seconds) { $entry.timeout_seconds } else { 30 }
        $pwshExe = Join-Path $PSHOME 'pwsh'
        if (-not (Test-Path $pwshExe)) { $pwshExe = "pwsh" }
        $pdcArgs = "-NoProfile -File `"$pdcScript`" -BaseRef `"$($entry.base_ref)`" -RepoRoot `"$RepoRoot`" -Quiet -TimeoutSeconds $resolveTimeout"
        if ($entry.allowed_paths) {
            foreach ($p in @($entry.allowed_paths)) { $pdcArgs += " -AllowedPaths `"$p`"" }
        }
        if ($entry.expected_files) {
            foreach ($f in @($entry.expected_files)) { $pdcArgs += " -ExpectedFiles `"$f`"" }
        }
        if ($entry.subagent_output) {
            $pdcArgs += " -SubagentOutputFile `"$($entry.subagent_output -replace '"','\"')`""
        }

        $resolveStart = Get-Date
        $result = try {
            $psi = [System.Diagnostics.ProcessStartInfo]::new($pwshExe, $pdcArgs)
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError  = $true
            $psi.UseShellExecute = $false
            $psi.WorkingDirectory = $RepoRoot
            $proc = [System.Diagnostics.Process]::Start($psi)
            $completed = $proc.WaitForExit($resolveTimeout * 1000)
            if (-not $completed) { $proc.Kill(); @("TIMEOUT after $resolveTimeout s") }
            else {
                $out = @()
                $stdout = $proc.StandardOutput.ReadToEnd()
                $stderr = $proc.StandardError.ReadToEnd()
                if ($stdout) { $out += ($stdout -split "`n") }
                if ($stderr)  { $out += ($stderr  -split "`n") }
                $out
            }
        } catch {
            @($_ | Out-String)
        }
        $jsonLine = $result | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue

        # No JSON from subprocess → fallback quality object
        if (-not $json) {
            $json = [PSCustomObject]@{
                passed          = $false
                contract_valid  = $false
                file_count      = 0
                checks          = @([PSCustomObject]@{ name = "post_deployment"; passed = $false; detail = "resolve: no JSON from pdc" })
                changed_files   = @()
            }
        }

        # Update entry status
        $entry.status = if ($json -and $json.passed) { "resolved" } else { "failed" }
        $entry.resolved = (Get-Date -Format "o")
        $reg[$TaskId] = $entry
        Set-RegistryData $reg

        # Compute budget tracking
        $registered = if ($entry.registered) { [DateTime]$entry.registered } else { Get-Date }
        $elapsedSeconds = (Get-Date) - $registered | Select-Object -ExpandProperty TotalSeconds
        $budgetExceeded = $elapsedSeconds -gt $resolveTimeout

        if ($Quiet) {
            # Quality object from post-delegation-check + budget tracking
            $quality = if ($json) { $json } else { [PSCustomObject]@{ passed = $false } }
            $quality | Add-Member -NotePropertyName budget_exceeded -NotePropertyValue $budgetExceeded -ErrorAction SilentlyContinue
            $quality | Add-Member -NotePropertyName resolve_duration_s -NotePropertyValue ([math]::Round(((Get-Date) - $resolveStart).TotalSeconds, 1)) -ErrorAction SilentlyContinue
            @{
                status    = $entry.status
                task_id   = $TaskId
                passed    = if ($json) { $json.passed } else { $false }
                quality   = $quality
            } | ConvertTo-Json -Compress -Depth 5
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
        $entry.re_prompts = @($entry.re_prompts) + @(@{ at = (Get-Date -Format "o"); prompt = $NewPrompt })
        $entry.status = "re-prompted"
        $reg[$TaskId] = $entry
        Set-RegistryData $reg

        # Write re-prompt instructions to a temp file the orchestrator picks up before task()
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
} finally {
    if ($mutexAcquired) {
        $mutex.ReleaseMutex() | Out-Null
    }
    $mutex.Dispose()
}
