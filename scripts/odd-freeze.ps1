#requires -Version 5.1
param(
    [switch]$Help
)

Set-StrictMode -Version Latest
<#
.SYNOPSIS
    RDD freeze hash generator — HEAD-xxxxxxxx-hash format.
.DESCRIPTION
    Computes a reproducible freeze snapshot for Review-Driven Development.
    Two components: HEAD short ref (12 chars) + content diff hash (8 chars).
    No side effects: no -w, no stash, no commit, no branch.
.EXAMPLE
    . "$env:GENTLEMAN_AGENT_ROOT\scripts\bash-safe.ps1"
    . "$env:GENTLEMAN_AGENT_ROOT\scripts\odd-freeze.ps1"
    # Output: HEAD-a1b2c3d4e5f6-9f8e7d6c
.NOTES
    Exit codes: 0=success, 1=not a git repo, 2=bash-safe not loaded, 3=hash computation failed.
#>

if ($Help) { Get-Help $MyInvocation.MyCommand.Path -Full; exit 0 }

# --- Guard: bash-safe.ps1 must be loaded ---
if (-not (Get-Command Invoke-Bash -ErrorAction SilentlyContinue)) {
    $bashSafe = Join-Path $env:GENTLEMAN_AGENT_ROOT "scripts\bash-safe.ps1"
    if (Test-Path $bashSafe) {
        . $bashSafe
    } else {
        Write-Error "bash-safe.ps1 not found at $bashSafe. Load it first."
        exit 2
    }
}

# --- Guard: must be in a git repo ---
$repoCheck = Invoke-Bash "git rev-parse --is-inside-work-tree" -CaptureOutput
if ($repoCheck.ExitCode -ne 0 -or $repoCheck.Output -notmatch "true") {
    Write-Error "Not inside a git working tree."
    exit 1
}

# --- Step 1: HEAD short ref (12 chars) ---
$headResult = Invoke-Bash "git rev-parse --short HEAD" -CaptureOutput
if ($headResult.ExitCode -ne 0) {
    Write-Error "Failed to get HEAD ref."
    exit 3
}
$headRaw = ($headResult.Output | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -Last 1).Trim()
$headShort = $headRaw.Substring(0, [Math]::Min(12, $headRaw.Length))

# --- Step 2: diff content hash (8 chars, no -w) ---
$diffResult = Invoke-Bash "git diff HEAD | git hash-object --stdin" -CaptureOutput
if ($diffResult.ExitCode -ne 0) {
    Write-Error "Failed to compute diff hash."
    exit 3
}
$diffHash = ($diffResult.Output | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -Last 1).Trim()
$diffShort = $diffHash.Substring(0, [Math]::Min(8, $diffHash.Length))

# --- Output ---
$freeze = "HEAD-$headShort-$diffShort"
Write-Output $freeze
exit 0
