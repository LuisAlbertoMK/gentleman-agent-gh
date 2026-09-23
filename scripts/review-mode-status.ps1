#requires -Version 5.1
<#
.SYNOPSIS
    review-mode status — RDD on-by-default (upstream v3.5.0 adaptado, sin binario gentle-ai).
.DESCRIPTION
    Readonly: reporta effective mode + deciding source como JSON a stdout. No escribe nada.
    Precedencia: $env:RDD_MODE (global) > .gentleman/rdd-mode.json (clone) > default on.
    Hook de test: $env:RDD_MODE_FILE (ruta alternativa al clone file, hermetico).
    NOTA: .gentleman-mode ("auto") es legado no relacionado con review; .gentleman/state.json
    guarda last_synced_at, no el modo. No se duplican fuentes de verdad.
.OUTPUTS
    JSON a stdout: {mode: on|off, source: global|clone|default}
.EXAMPLE
    pwsh ./scripts/review-mode-status.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-CloneModePath {
    if (-not [string]::IsNullOrEmpty($env:RDD_MODE_FILE)) {
        return $env:RDD_MODE_FILE
    }
    $repoRoot = Split-Path $PSScriptRoot -Parent
    return (Join-Path (Join-Path $repoRoot '.gentleman') 'rdd-mode.json')
}

$mode = 'on'
$source = 'default'

$globalMode = $env:RDD_MODE
if (-not [string]::IsNullOrEmpty($globalMode)) {
    $g = $globalMode.Trim().ToLowerInvariant()
    if ($g -eq 'on' -or $g -eq 'off') {
        $mode = $g
        $source = 'global'
    }
}
else {
    $clonePath = Get-CloneModePath
    if (Test-Path -LiteralPath $clonePath) {
        try {
            $parsed = Get-Content -LiteralPath $clonePath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($parsed.PSObject.Properties['mode']) {
                $c = ([string]$parsed.mode).Trim().ToLowerInvariant()
                if ($c -eq 'on' -or $c -eq 'off') {
                    $mode = $c
                    $source = 'clone'
                }
            }
        }
        catch {
        }
    }
}

$result = [ordered]@{
    mode   = $mode
    source = $source
}
ConvertTo-Json -InputObject $result -Compress | Write-Output
