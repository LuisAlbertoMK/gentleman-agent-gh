#requires -Version 7.0
<#
.SYNOPSIS
    Shared file manifest for repo analysis scripts (pssa-gate, score-auto).
.DESCRIPTION
    Dot-sourced by analysis scripts. Exposes Get-FileManifest — a single
    inventory of analyzable files with content hashes, so consumers don't
    each walk the tree independently.
.NOTES
    This file is NOT meant to be invoked directly.
#>

function Get-FileManifest {
    [CmdletBinding()]
    param(
        [Alias('Root')]
        [string]$Path = (Get-Location).Path
    )
    $root = (Resolve-Path $Path).Path

    $rxExclude = '(^|[\\/])(node_modules|experiments|skills)([\\/]|$)'
    $rxExt     = '\.(ps1|psm1)$'

    $scriptPaths = @(Get-ChildItem -LiteralPath $root -File -Recurse -EA SilentlyContinue |
        Where-Object { $_.FullName -notmatch $rxExclude -and $_.FullName -match $rxExt })

    $skillPaths = @(Get-ChildItem -LiteralPath (Join-Path $root '.agents\skills') -File -Filter 'SKILL.md' -Recurse -EA SilentlyContinue)

    $manifest = @($scriptPaths + $skillPaths | ForEach-Object -Parallel {
        $f = $_
        $rp = $f.FullName.Substring($using:root.Length).TrimStart('\').Replace('\', '/')
        $sha256 = ''
        try {
            $h = [Security.Cryptography.SHA256]::Create()
            $sha256 = ([BitConverter]::ToString($h.ComputeHash([IO.File]::ReadAllBytes($f.FullName)))).Replace('-', '').ToLower()
            $h.Dispose()
        } catch { $sha256 = '' }
        $grp = if ($rp -match '^\.agents/skills/') { 'skill' } else { 'script' }
        [PSCustomObject]@{
            relpath = $rp
            length  = $f.Length
            mtime   = $f.LastWriteTimeUtc.Ticks
            sha256  = $sha256
            group   = $grp
        }
    } -ThrottleLimit 8)

    @($manifest | Sort-Object relpath)
}
