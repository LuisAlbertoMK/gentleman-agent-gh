#requires -Version 7
<#
.SYNOPSIS
    Shared runtime permission gate classification logic.
.DESCRIPTION
    Dot-sourced by scripts/permission-gate.ps1 (and by its Pester tests).
    Exposes:
    - Get-CommandClass: allow/ask/deny/help verdict for a command in a mode
    - Get-ConfiguredMode: mode-file resolution with 'manual' fallback
.NOTES
    This file is NOT meant to be invoked directly.
    scripts/cross-ref-check.ps1 [10/9] TEXT-SCANS scripts/permission-gate.ps1
    for single-quoted '^cmd' pattern literals to keep semi-agents.json in sync
    with the gate. The production script therefore keeps a comment mirror of the
    arrays below. Keep that mirror in sync when editing the patterns here.
#>

# ===== COMMAND CLASSIFICATION RULES =====

# These patterns are checked in order: deny → allow → ask (default)

$script:denyPatterns = @(
    # Network — always blocked
    '^curl\s', '^wget\s', '^Invoke-WebRequest', '^Invoke-RestMethod',
    '^irm\s', '^iwr\s', '^iex\s', '^icm\s', '^Invoke-Expression', '^wsl\s', '^Start-BitsTransfer',
    '^ssh\s', '^docker\s', '^docker-compose\s', '^docker compose',
    '^telnet\s', '^ncat\s', '^nc\s', '^Test-NetConnection',
    # Interpreters
    '^python\s', '^python3\s', '^node\s', '^ruby\s', '^perl\s', '^php\s', '^npx\s',
    # System/admin — always blocked
    '^certutil\s', '^bitsadmin\s', '^schtasks\s', '^reg\s', '^sc\s', '^icacls\s',
    '^cmd /c', '^cmd\.exe', '^powershell\s-c\s', '^powershell\s-command\s',
    '^powershell\s-enc\s', '^powershell\s-File\s', '^powershell\.exe',
    '^pwsh\s', '^pwsh\.exe',
    '^Start-Process', '^Invoke-Command', '^Register-ScheduledTask', '^New-Service',
    '^net user', '^net localgroup', '^net share', '^net use', '^net session',
    '^Add-MpPreference', '^Set-MpPreference',
    '^saps\s', '^start\s',
    # Push --force is always denied
    '^git push --force', '^git push -f'
)

# Destructive filesystem — DENY in manual/semi, ASK in auto (user confirms deletes)
$script:destructivePatterns = @(
    '^rm\s', '^rm -rf', '^Remove-Item',
    '^git clean\s', '^git rm\s'
)

# Semi-auto allowlist (safe commands that run without asking in semi mode)
$script:semiAllowPatterns = @(
    # Git read-only
    '^git status', '^git log', '^git diff', '^git show', '^git branch',
    '^git stash list', '^git stash show',
    # Filesystem read-only
    '^ls$', '^ls\s', '^dir$', '^dir\s', '^Get-ChildItem', '^Test-Path',
    '^pwd$', '^Get-Location', '^cat\s', '^Get-Content', '^type\s',
    # Output
    '^echo\s', '^Write-Output',
    # Search
    '^grep\s', '^rg\s', '^Select-String', '^findstr\s',
    # Query
    '^which\s', '^Get-Command', '^Get-Help', '^Get-Alias',
    # Build/test
    '^npm test', '^pytest\s', '^go test', '^Invoke-Pester',
    '^dotnet test', '^cargo test', '^npm run', '^npm ci',
    '^pip (freeze|list|show|install --user)(\s|$)',
    # Git read-only (no args)
    '^git stash list$', '^git status$', '^git diff$', '^git log$'
)

# Auto-mode: everything allowed EXCEPT pushes + deletes (both ask)
$script:autoAskPatterns = @(
    '^git push$', '^git push\s', # git push ASKS (not denied) in auto mode
    '^git push --delete',
    '^git branch -D', '^git branch -d', # branch deletion
    '^git stash drop', # stash deletion
    '^git reset' # destructive reset (--hard deletes working tree changes)
)

# ===== CLASSIFY =====
function Get-CommandClass {
    param([string]$cmd, [string]$mode)

    if (-not $cmd) { return 'help' }

    # Normalize whitespace so anchored ^patterns can't be evaded with
    # multiple spaces/tabs or leading padding (e.g. "git  clean" or " git clean").
    $cmd = $cmd -replace '\s+', ' '
    $cmd = $cmd.Trim()

    # 1. Check deny patterns (all modes) — hard security floor
    foreach ($p in $script:denyPatterns) {
        if ($cmd -match $p) { return 'deny' }
    }

    # 2. Destructive filesystem: DENY in manual/semi, ASK in auto
    foreach ($p in $script:destructivePatterns) {
        if ($cmd -match $p) {
            return $(if ($mode -eq 'auto') { 'ask' } else { 'deny' })
        }
    }

    # 3. Mode-specific checks
    switch ($mode) {
        'manual' {
            # Everything asks unless allowed by explicit patterns
            return 'ask'
        }
        'semi' {
            # Check allowlist first
            foreach ($p in $script:semiAllowPatterns) {
                if ($cmd -match $p) { return 'allow' }
            }
            # Not in allowlist → ask
            return 'ask'
        }
        'auto' {
            # Check auto-mode ask patterns (push, delete)
            foreach ($p in $script:autoAskPatterns) {
                if ($cmd -match $p) { return 'ask' }
            }
            # Everything else → allow
            return 'allow'
        }
    }

    return 'ask' # safe default
}

# ===== MODE RESOLUTION =====
function Get-ConfiguredMode {
    param(
        [string]$Mode,
        [string]$ModeFilePath,
        [string]$RepoRoot
    )
    $modeFile = if ($ModeFilePath) { $ModeFilePath } else { Join-Path -Path $RepoRoot '.gentleman-mode' }
    if (-not $Mode) {
        $Mode = if (Test-Path -LiteralPath $modeFile) {
            (Get-Content -LiteralPath $modeFile -Raw).Trim()
        } else { 'manual' }
    }
    return $Mode
}
