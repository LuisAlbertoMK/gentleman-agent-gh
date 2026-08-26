#requires -Version 5.1
param([switch]$Json)

Set-StrictMode -Version 5.1

<#
.SYNOPSIS
    Implementer resilience: retry with narrow scope + escalation.
.DESCRIPTION
    When a subagent fails twice, instead of stopping, this retries with
    progressively narrower scope (1-2 files per attempt). After MaxRetries
    failures, escalates with a natural Spanish message.
.PARAMETER Json
    Output structured JSON for orchestrator consumption.
#>

function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 2,
        [scriptblock]$NarrowScope
    )

    $attempts = 0
    $results = @()

    while ($attempts -lt $MaxRetries) {
        $attempts++
        $scope = if ($NarrowScope) { & $NarrowScope $attempts } else { @("*") }

        $logEntry = @{
            attempt = $attempts
            scope   = $scope
            time    = (Get-Date).ToString("o")
        }

        Write-Host "Intento $attempts de $MaxRetries — archivos: $($scope -join ', ')"

        try {
            $result = & $ScriptBlock $attempts $scope
            $logEntry.status = "success"
            $logEntry.result = $result
            $results += $logEntry

            Write-Host "  Exito en intento $attempts."
            return @{
                success     = $true
                attempts    = $attempts
                log         = $results
                final_scope = $scope
            }
        }
        catch {
            $logEntry.status = "failed"
            $logEntry.error  = $_.Exception.Message
            $results += $logEntry

            Write-Host "  Fallo en intento $($attempts): $($_.Exception.Message)"

            if ($attempts -ge $MaxRetries) {
                Write-Host ""
                Write-Host "Escalando al humano: despues de $MaxRetries intentos, el subagente"
                Write-Host "no pudo completar la tarea con scope reducido. Se necesita intervencion."
            }
        }
    }

    return @{
        success     = $false
        attempts    = $attempts
        log         = $results
        escalation  = "Subagente fallo $MaxRetries veces. Escalar a humano."
    }
}

# --- Main ---
$retryResult = Invoke-WithRetry `
    -ScriptBlock {
        param($attempt, $scope)
        # Simula: falla en 1er intento, pasa en 2do
        if ($attempt -eq 1) {
            throw "Error simulado de subagente en intento 1"
        }
        return "Tarea completada en intento $attempt con scope: $($scope -join ', ')"
    } `
    -MaxRetries 2 `
    -NarrowScope {
        param($attempt)
        # Scope progresivamente mas estrecho
        if ($attempt -eq 1) { return @("src/a.ps1", "src/b.ps1", "src/c.ps1") }
        return @("src/a.ps1")
    }

if ($Json) {
    $retryResult | ConvertTo-Json -Depth 4
} else {
    Write-Host ""
    Write-Host "=== Resumen ==="
    Write-Host "Exitoso: $($retryResult.success)"
    Write-Host "Intentos: $($retryResult.attempts)"
    if (-not $retryResult.success) {
        Write-Host "Escalacion: $($retryResult.escalation)"
    }
}
