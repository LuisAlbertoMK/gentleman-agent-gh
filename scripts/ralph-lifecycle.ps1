#requires -Version 7
<#
.SYNOPSIS
    Ralph lifecycle hooks + COMPLETE detection — R2-6.
.DESCRIPTION
    Implements wiggumdev/ralph lifecycle hooks for close-session:
      pre-close  — runs before session close (flush, validate)
      post-close — runs after close (cleanup, inter-track reset on COMPLETE)
      on-complete — detects <promise>DONE</promise> or <promise>COMPLETE</promise> in
                    .opencode/ralph-loop.local.md (active:false) or last commit message.

    Called by close-session.ps1 after inter-track increment. PESTER_TEST=1 → dry run.

    Pattern from KB r2-ralph-wiggum-repo (30 sections) + r2-dynamic-workflows crash-resume.
#>
[CmdletBinding()]
param(
    [ValidateSet('pre-close','post-close','check-complete')][string]$Hook = 'check-complete',
    [switch]$Json
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent

function Test-RalphComplete {
    # Check 1: .opencode/ralph-loop.local.md active:false
    $loopFile = Join-Path $repoRoot '.opencode/ralph-loop.local.md'
    if (Test-Path $loopFile) {
        $c = Get-Content $loopFile -Raw -ErrorAction SilentlyContinue
        if ($c -match 'active:\s*false') { return @{ complete = $true; source = 'ralph-loop.local.md active:false' } }
        if ($c -match '<promise>\s*(DONE|COMPLETE)\s*</promise>') { return @{ complete = $true; source = 'ralph-loop.local.md promise' } }
    }
    # Check 2: last commit message contains promise
    try {
        $msg = git log -1 --pretty=%B 2>$null | Out-String
        if ($msg -match '<promise>\s*(DONE|COMPLETE)\s*</promise>') { return @{ complete = $true; source = 'last commit promise' } }
    } catch { Write-Verbose "Ralph complete check failed: $_" }
    # Check 3: .ralph/promise file (explicit)
    $promiseFile = Join-Path $repoRoot '.ralph/promise'
    if (Test-Path $promiseFile) { return @{ complete = $true; source = '.ralph/promise file' } }
    return @{ complete = $false; source = 'none' }
}

$result = switch ($Hook) {
    'check-complete' { Test-RalphComplete }
    'pre-close'  { Write-Host "ralph lifecycle: pre-close — flushing batch" -ForegroundColor DarkGray; Test-RalphComplete }
    'post-close' {
        $check = Test-RalphComplete
        if ($check.complete -and $env:PESTER_TEST -ne '1') {
            # Advance inter-track cycle on COMPLETE (like G7 target met, but explicit)
            try { & (Join-Path $PSScriptRoot 'inter-track.ps1') -Reset -Quiet; Write-Host "ralph lifecycle: COMPLETE detected ($($check.source)) → inter-track cycle advanced" -ForegroundColor Green } catch { Write-Debug $_ }
        } elseif ($check.complete) {
            Write-Host "ralph lifecycle: COMPLETE detected ($($check.source)) — dry run (PESTER_TEST=1)" -ForegroundColor Yellow
        }
        $check
    }
}

if ($Json) { $result | ConvertTo-Json -Depth 3 }
else {
    if ($result.complete) { Write-Host "COMPLETE: $($result.source)" -ForegroundColor Green } else { Write-Host "not complete: $($result.source)" -ForegroundColor DarkGray }
    $result | ConvertTo-Json -Depth 3 | Write-Host
}
