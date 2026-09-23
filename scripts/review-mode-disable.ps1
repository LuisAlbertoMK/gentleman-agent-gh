#requires -Version 5.1
<#
.SYNOPSIS
    review-mode disable — opt-out humano de RDD review (upstream v3.5.0 adaptado).
.DESCRIPTION
    Escribe mode=off SOLO donde el USUARIO lo pide (-Scope clone|global).
    El disable es decision humana: el agente NUNCA llama a este script por
    iniciativa propia; solo lo ejecuta a pedido explicito del usuario.
    - clone: .gentleman/rdd-mode.json (o $env:RDD_MODE_FILE en tests).
    - global: variable de entorno de usuario RDD_MODE=off (persistente) + sesion actual.
    B4 (fail-closed anti self-disable): requiere confirmacion interactiva
    (SupportsShouldProcess + ConfirmImpact High) y anexa una linea de auditoria
    (timestamp, scope, user) a .gentleman/audit.log (o $env:RDD_AUDIT_FILE en tests).
    Sin confirmacion no hay escritura; sin auditoria no hay disable silencioso.
.EXAMPLE
    pwsh ./scripts/review-mode-disable.ps1 -Scope clone
.EXAMPLE
    pwsh ./scripts/review-mode-disable.ps1 -Scope global
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('clone', 'global')]
    [string]$Scope
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-DisableAuditPath {
    param(
        [string]$ClonePath
    )
    if (-not [string]::IsNullOrEmpty($env:RDD_AUDIT_FILE)) {
        return $env:RDD_AUDIT_FILE
    }
    $dir = Split-Path $ClonePath -Parent
    if ([string]::IsNullOrEmpty($dir)) {
        $repoRoot = Split-Path $PSScriptRoot -Parent
        $dir = Join-Path $repoRoot '.gentleman'
    }
    return (Join-Path $dir 'audit.log')
}

function Write-DisableAudit {
    param(
        [string]$AuditPath,
        [string]$ScopeName
    )
    $dir = Split-Path $AuditPath -Parent
    if (-not [string]::IsNullOrEmpty($dir) -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $user = $env:USERNAME
    if ([string]::IsNullOrEmpty($user)) {
        $user = $env:USER
    }
    if ([string]::IsNullOrEmpty($user)) {
        $user = 'unknown'
    }
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "$stamp action=review-mode-disable scope=$ScopeName user=$user"
    Add-Content -LiteralPath $AuditPath -Value $line -Encoding UTF8
}

if ($Scope -eq 'clone') {
    $clonePath = $env:RDD_MODE_FILE
    if ([string]::IsNullOrEmpty($clonePath)) {
        $repoRoot = Split-Path $PSScriptRoot -Parent
        $clonePath = Join-Path (Join-Path $repoRoot '.gentleman') 'rdd-mode.json'
    }
    if ($PSCmdlet.ShouldProcess($clonePath, 'Disable review mode (clone scope)')) {
        $dir = Split-Path $clonePath -Parent
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $existing = @{}
        if (Test-Path -LiteralPath $clonePath) {
            try {
                $parsed = Get-Content -LiteralPath $clonePath -Raw -Encoding UTF8 | ConvertFrom-Json
                foreach ($p in $parsed.PSObject.Properties) {
                    $existing[$p.Name] = $p.Value
                }
            }
            catch {
            }
        }
        $existing['mode'] = 'off'
        ($existing | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $clonePath -Encoding UTF8
        Write-DisableAudit -AuditPath (Get-DisableAuditPath -ClonePath $clonePath) -ScopeName 'clone'
        Write-Output ('review-mode disabled (clone): ' + $clonePath)
    }
}
else {
    if ($PSCmdlet.ShouldProcess('user env RDD_MODE', 'Disable review mode (global scope)')) {
        [Environment]::SetEnvironmentVariable('RDD_MODE', 'off', 'User')
        $env:RDD_MODE = 'off'
        $repoRoot = Split-Path $PSScriptRoot -Parent
        $defaultAudit = Join-Path (Join-Path $repoRoot '.gentleman') 'audit.log'
        $auditPath = $defaultAudit
        if (-not [string]::IsNullOrEmpty($env:RDD_AUDIT_FILE)) {
            $auditPath = $env:RDD_AUDIT_FILE
        }
        Write-DisableAudit -AuditPath $auditPath -ScopeName 'global'
        Write-Output 'review-mode disabled (global): RDD_MODE=off (user env, decision humana)'
    }
}

Write-Warning 'Desactivar review es decision humana: el agente nunca debe llamar a este script por iniciativa propia.'
