#requires -Version 5.1
<#
.SYNOPSIS
    review status — stub fail-closed hasta que exista revisor nativo (B3).
.DESCRIPTION
    Stub intencional fail-closed: NO existe revisor nativo conectado, por lo que
    este script NUNCA puede reportar un review cumplido. Siempre sale con exit
    distinto de cero y el mensaje 'native reviewer not connected'. La integracion
    con el revisor nativo se conecta aqui cuando exista (ese cambio debe voltear
    este comportamiento y sus tests).
.PARAMETER BaseRef
    Ref base del candidato (default HEAD). Se reporta en el resumen, sin efecto.
.PARAMETER Agent
    Nombre de agente opcional. Se reporta en el resumen, sin efecto.
.EXAMPLE
    pwsh ./scripts/review-status.ps1 -BaseRef HEAD~1
#>
[CmdletBinding()]
param(
    [string]$BaseRef = 'HEAD',
    [string]$Agent = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$summary = 'candidate BaseRef=' + $BaseRef
if (-not [string]::IsNullOrEmpty($Agent)) {
    $summary = $summary + ' Agent=' + $Agent
}
Write-Output $summary
Write-Output 'native reviewer not connected — review-status cannot report a completed review (fail-closed stub)'
exit 1
