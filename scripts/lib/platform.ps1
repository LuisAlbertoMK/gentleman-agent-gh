#requires -Version 5.1
<#
.SYNOPSIS
    Cross-platform helpers for PowerShell 7 scripts — Windows, Linux, macOS.
.DESCRIPTION
    Dot-sourced by sync-all.ps1, global-setup.ps1, sync-vmk.ps1.
    Provides: Get-GlobalConfigDir, New-CrossPlatLink, Find-Pwsh.
.NOTES
    This file is NOT meant to be invoked directly.
#>

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
    param([string]$Path, [string]$Target)
    if ($IsLinux -or $IsMacOS) {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target -Force | Out-Null
    } else {
        New-Item -ItemType Junction -Path $Path -Target $Target -Force | Out-Null
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
