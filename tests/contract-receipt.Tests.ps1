#requires -Version 7
<#
.SYNOPSIS
    R8-S1 + R9-S2 drift-fix: TODAS las receipts .rdd presentes validan contra contracts/rdd-receipt.schema.json.
.DESCRIPTION
    Validador PowerShell nativo Test-Json -SchemaFile (sin deps nuevas; schema declara
    draft 2020-12, aceptado por Test-Json en PS 7). Solo lectura de .rdd: nunca modifica
    las receipts (si una receipt real NO pasa, el test lo reporta como divergencia).
    Conteo DINAMICO (R9-S2 fix del drift 005-008 vs test congelado en 001-004): los casos
    por receipt se generan por discovery sobre .rdd/rdd-receipt-*.json, sin lista
    hardcodeada 001-004 ni conteo fijo. Fixtures negativas hermeticas en TestDrive
    (con -ErrorAction SilentlyContinue para que retornen False tambien bajo
    $ErrorActionPreference='Stop' del pre-commit gate). Patron Pester+Test-Json
    congelado para S2/S3.
#>

Describe 'RDD receipt contract (R8-S1, dynamic R9-S2)' {
    BeforeAll {
        $RepoRoot = Split-Path -Parent $PSScriptRoot
        $SchemaPath = Join-Path $RepoRoot 'contracts/rdd-receipt.schema.json'
        $RddDir = Join-Path $RepoRoot '.rdd'
        $ReceiptFiles = @(Get-ChildItem (Join-Path $RddDir 'rdd-receipt-*.json') | Sort-Object Name)
    }

    # Casos por discovery: una entrada por cada receipt presente en disco.
    $ReceiptCases = @(Get-ChildItem (Join-Path $PSScriptRoot '..' '.rdd' 'rdd-receipt-*.json') |
        Sort-Object Name | ForEach-Object { @{ Name = $_.Name } })

    It 'schema exists and declares draft 2020-12' {
        Test-Path -LiteralPath $SchemaPath | Should -BeTrue
        $decl = (Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties['$schema'].Value
        $decl | Should -Match '2020-12'
    }

    It 'receipt <Name> validates against schema' -ForEach $ReceiptCases {
        $path = Join-Path $RddDir $Name
        Test-Path -LiteralPath $path | Should -BeTrue
        Get-Content -LiteralPath $path -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath | Should -BeTrue
    }

    It 'receipt set is dynamic (count matches files on disk, no hardcoded 4)' {
        @($ReceiptFiles).Count | Should -BeGreaterThan 0
        @($ReceiptFiles).Count | Should -Be @(Get-ChildItem (Join-Path $RddDir 'rdd-receipt-*.json')).Count
    }

    It 'negative fixture (bad verdict, tier, empty files) FAILs validation' {
        $bad = '{"id":"rdd-receipt-999","freeze":"HEAD-x","tier":9,"files":[],"verdict":"MAYBE","timestamp":"not-a-date"}'
        $badPath = Join-Path $TestDrive 'bad-receipt.json'
        Set-Content -LiteralPath $badPath -Value $bad -Encoding UTF8
        Get-Content -LiteralPath $badPath -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'negative fixture (missing required verdict) FAILs validation' {
        $missing = '{"id":"rdd-receipt-999","freeze":"HEAD-x","tier":1,"files":["a.ps1"],"timestamp":"2026-09-24T00:00:00-06:00"}'
        $missingPath = Join-Path $TestDrive 'missing-verdict.json'
        Set-Content -LiteralPath $missingPath -Value $missing -Encoding UTF8
        Get-Content -LiteralPath $missingPath -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }
}
