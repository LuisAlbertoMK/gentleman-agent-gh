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
    scripts/cross-ref-check.ps1 [10/9] RETIRED (ADR-033 implemented 2026-09-04:
    semi-agents.json deleted, allowlist sync no longer applicable). The production
    script therefore keeps a comment mirror of the arrays below. Keep that mirror
    in sync when editing the patterns here. Runtime 'semi' branch below is legacy
    backward-compat (single-mode Refactor-AP S2: mode file is a no-op, -auto/-semi are compat aliases) — JD follow-up decides removal.
#>

# ===== COMMAND CLASSIFICATION RULES =====

# These patterns are checked in order: deny → allow → ask (default)

# C4b: Convert shared-deny-rules.json glob → PowerShell regex
# "curl *" → '^curl\b' (matches "curl" bare or "curl <args>")
# "npm install *" → '^npm\s+install\b'
function Convert-FromDenyGlob {
    param([string]$Glob)
    $trimmed = $Glob.Trim()
    if ($trimmed -match '\s+\*\s*$') {
        $prefix = $trimmed -replace '\s+\*\s*$', ''
        $escaped = [regex]::Escape($prefix) -replace '\\ ', '\s+'
        return '^' + $escaped + '\b'
    }
    return '^' + ([regex]::Escape($trimmed) -replace '\\ ', '\s+') + '\b'
}

# C4b: Load deny patterns from shared-deny-rules.json (SSoT for runtime gate)
# Eliminates 22 hardcoded patterns duplicated across permission-gate-lib.ps1,
# shared-deny-rules.json, and permission-templates.json.
# Runtime gate deny patterns live in shared-deny-rules.json; config-generation
# deny rules (opencode-base.json) mirror these values — keep in sync.
$denyRulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'opencode-config' 'shared-deny-rules.json'
$script:denyPatterns = @()
$script:allowPatterns = @()

if (Test-Path $denyRulesPath) {
    try {
        $denyRules = Get-Content $denyRulesPath -Raw | ConvertFrom-Json
        # C4b: Exclude destructive patterns from deny list — they're handled by
        # $script:destructivePatterns with mode-specific behavior (ask in auto, deny in manual/semi)
        $destructiveGlobs = @('git checkout -- *', 'git clean *', 'git restore *', 'git rm *')
        $script:denyPatterns = @($denyRules.PSObject.Properties |
            Where-Object { $_.Value -eq 'deny' -and $destructiveGlobs -notcontains $_.Name } |
            ForEach-Object { Convert-FromDenyGlob $_.Name } |
            Sort-Object -Unique)
        # C4b: Load "ask" patterns (commands that prompt for approval instead of
        # being hard-denied). Merged into autoAskPatterns below.
        $script:askPatterns = @($denyRules.PSObject.Properties |
            Where-Object { $_.Value -eq 'ask' } |
            ForEach-Object { Convert-FromDenyGlob $_.Name } |
            Sort-Object -Unique)
        # ADR-046: Load explicit "allow" patterns (toolchain freedom — docker,
        # python, pip, pnpm, node, npx, npm installs). Checked AFTER deny but
        # BEFORE destructive/mode logic, in every mode.
        $script:allowPatterns = @($denyRules.PSObject.Properties |
            Where-Object { $_.Value -eq 'allow' } |
            ForEach-Object { Convert-FromDenyGlob $_.Name } |
            Sort-Object -Unique)
    } catch {
        Write-Debug "permission-gate-lib: shared-deny-rules.json load failed: $($_.Exception.Message)"
    }
}

# C4b: Fallback — if JSON load failed, use embedded patterns (safety net)
# This preserves the original 22 patterns as a fallback if shared-deny-rules.json
# is missing or corrupt. In normal operation, patterns load from the JSON file.
if ($script:denyPatterns.Count -eq 0) {
    Write-Warning "permission-gate-lib: shared-deny-rules.json not loaded, using embedded fallback"
    $script:denyPatterns = @(
        '^curl\s', '^wget\s', '^Invoke-WebRequest', '^Invoke-RestMethod',
        '^irm\s', '^iwr\s', '^iex\s', '^icm\s', '^Invoke-Expression', '^wsl\s', '^Start-BitsTransfer',
        '^ssh\s', '^docker\s', '^docker-compose\s', '^docker compose',
        '^telnet\s', '^ncat\s', '^nc\s', '^Test-NetConnection',
        '^python\s', '^python3\s', '^ruby\s', '^perl\s', '^php\s',
        '^certutil\s', '^bitsadmin\s', '^schtasks\s', '^reg\s', '^sc\s', '^icacls\s',
        '^cmd /c', '^cmd\.exe',
        '^Start-Process', '^Invoke-Command', '^Register-ScheduledTask', '^New-Service',
        '^net user', '^net localgroup', '^net share', '^net use', '^net session',
        '^Add-MpPreference', '^Set-MpPreference',
        '^saps\s', '^start\s',
        '^npm\sexec\s',
        '^npm\suninstall\s', '^npm\sremove\s', '^npm\supdate\s', '^npm\spublish\s',
        '^pip\sinstall\s', '^pip3\sinstall\s',
        '^yarn\s(install|add)\s', '^pnpm\s(install|add|i)\s', '^bun\s(install|add)\s'
    )
    # C4b: Fallback ask patterns (commands that prompt for approval instead of deny)
    if (-not $script:askPatterns) {
        $script:askPatterns = @(
            '^node\s', '^npx\s',
            '^npm\s+install\b', '^npm\si\b', '^npm\sadd\b'
        )
    }
    # Explicit allow patterns — wrapper invocation + safe-path Remove-Item (temp only)
    if (-not $script:allowPatterns) {
        $script:allowPatterns = @(
            '^pwsh\s+scripts/clean-worktree-temp\.ps1\b',
            '^Remove-Item\s+-LiteralPath\s+.*\\opencode\\',
            '^Remove-Item\s+-LiteralPath\s+.*\.tmp-\w'
        )
    }
}

# Forced push (--force/-f/--delete) is destructive in ALL modes — deny floor
# Bypass-proof: catches "git push --force", "git push -f", "git push --delete",
# "git.exe push --force", "git -C repo push --force", etc.
$script:denyPatterns += '^git(\.exe)?(\s+\S+)*\s+push(\s|$).*(--force|--delete|-f\b)'

# Destructive filesystem — DENY in manual/semi, ASK in auto (user confirms deletes)
$script:destructivePatterns = @(
    '^rm\s', '^rm -rf', '^Remove-Item',
    '^git clean\s', '^git rm\s', '^git checkout --', '^git restore\s'
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
    '^pnpm run', '^pnpm test', '^pnpm exec',
    '^pip (freeze|list|show)(\s|$)',
    # Git read-only (no args)
    '^git stash list$', '^git status$', '^git diff$', '^git log$'
)

# Auto-mode: everything allowed EXCEPT deletes (ask) + push (deny via autoDenyPatterns)
# C4b: push moved from deny-floor → autoDenyPatterns (auto=deny, manual/semi=ask)
$script:autoAskPatterns = @(
    '^git branch -D', '^git branch -d', # branch deletion
    '^git stash drop', # stash deletion
    '^git reset' # destructive reset (--hard deletes working tree changes)
)
# C4b: Merge "ask" patterns (from shared-deny-rules.json or fallback) into autoAskPatterns
# so that these commands prompt for approval in auto mode instead of being hard-denied
if ($script:askPatterns) {
    $script:autoAskPatterns = $script:autoAskPatterns + $script:askPatterns | Sort-Object -Unique
}
# C4b: Auto-mode deny patterns (push: DENY in auto, ASK in manual/semi)
# Pattern catches: git push, git -C repo push, git --git-dir=X push, git.exe push
# Does NOT false-positive on: git push-foo (no space/$ after "push")
$script:autoDenyPatterns = @(
    '^git(\.exe)?(\s+\S+)*\s+push(\s|$)'
)

# ===== CLASSIFY =====
function Get-CommandClass {
    param([string]$cmd, [string]$mode)

    if (-not $cmd) { return 'help' }

    # Normalize whitespace so anchored ^patterns can't be evaded with
    # multiple spaces/tabs, leading padding (e.g. "git  clean" or " git clean"),
    # or Unicode whitespace/format characters (e.g. "git`u{200B}clean" —
    # zero-width space, U+00A0 no-break space, U+202F narrow no-break space,
    # U+180E Mongolian vowel separator). \s alone misses the Cf format chars;
    # \p{Zs} adds every space-separator, \p{Cf} every format char (ZWSP etc.).
    # The collapse maps them all to a regular space so .Trim() can then strip
    # any leading/trailing padding.
    $cmd = $cmd -replace '[\s\p{Zs}\p{Cf}]+', ' '
    $cmd = $cmd.Trim()

    # 1. Check deny patterns (all modes) — hard security floor
    foreach ($p in $script:denyPatterns) {
        if ($cmd -match $p) { return 'deny' }
    }

    # 1.5 ADR-046: Explicit allow patterns (toolchain: docker/python/pip/pnpm/
    # node/npx/npm installs) — permitted in EVERY mode; human oversight in
    # manual/semi comes from those modes' default-ask, not from blocking here.
    foreach ($p in $script:allowPatterns) {
        if ($cmd -match $p) { return 'allow' }
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
            # C4b: Check auto-mode deny patterns first (push: hard deny, no prompt)
            foreach ($p in $script:autoDenyPatterns) {
                if ($cmd -match $p) { return 'deny' }
            }
            # Check auto-mode ask patterns (delete, reset)
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
