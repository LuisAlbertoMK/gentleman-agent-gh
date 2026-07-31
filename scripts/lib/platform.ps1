#requires -Version 5.1
<#
.SYNOPSIS
    Cross-platform helpers for PowerShell 7 scripts — Windows, Linux, macOS.
.DESCRIPTION
    Dot-sourced by sync-all.ps1, global-setup.ps1, sync-vmk.ps1.
    Provides: Get-GentlemanRoot, Get-GlobalConfigDir, New-CrossPlatLink, Find-Pwsh.
.NOTES
    This file is NOT meant to be invoked directly.
#>

function Get-GentlemanRoot {
    <#
    .SYNOPSIS
        Returns the canonical gentleman-agent-gh repo root.
    .DESCRIPTION
        The script's own repo is ALWAYS canonical when platform.ps1 lives in a
        repo: repo root is derived from $PSScriptRoot (scripts/lib → root).
        GENTLEMAN_AGENT_ROOT is only a fallback for shims that are not
        repo-resident (e.g. ~/.config/opencode/scripts/run.ps1).
    #>
    $libDir = $PSScriptRoot                    # scripts/lib
    $repoRoot = Split-Path (Split-Path $libDir -Parent) -Parent
    if (Test-Path -LiteralPath (Join-Path $repoRoot 'scripts\lib\platform.ps1')) { return $repoRoot }
    return $env:GENTLEMAN_AGENT_ROOT           # shim fallback only
}

function Get-GlobalConfigDir {
    <#
    .SYNOPSIS
        Returns the opencode global config directory for the current OS.
        Windows: $env:USERPROFILE\.config\opencode
        Linux/macOS: $HOME/.config/opencode
    #>
    if ($IsLinux -or $IsMacOS) {
        return Join-Path (Join-Path $HOME ".config") "opencode"
    }
    return Join-Path (Join-Path $env:USERPROFILE ".config") "opencode"
}

function New-CrossPlatLink {
    <#
    .SYNOPSIS
        Creates a directory link: Junction on Windows, Symlink on Linux/macOS.
    .PARAMETER Path
        The link path to create.
    .PARAMETER Target
        The existing directory to link to.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path, [string]$Target)
    if ($PSCmdlet.ShouldProcess($Path, 'Create cross-platform link')) {
        if ($IsLinux -or $IsMacOS) {
            New-Item -ItemType SymbolicLink -Path $Path -Target $Target -Force | Out-Null
        } else {
            New-Item -ItemType Junction -Path $Path -Target $Target -Force | Out-Null
        }
    }
}

function Find-Pwsh {
    <#
    .SYNOPSIS
        Finds PowerShell 7+ executable. Returns the CommandInfo or $null.
        Checks 'pwsh' first (Linux/macOS), then 'pwsh.exe' (Windows).
    #>
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd }
    return Get-Command pwsh.exe -ErrorAction SilentlyContinue
}
