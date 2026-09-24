#requires -Version 7
<#
.SYNOPSIS
    R8-S1: las 4 receipts .rdd existentes validan contra contracts/rdd-receipt.schema.json.
.DESCRIPTION
    Validador PowerShell nativo Test-Json -SchemaFile (sin deps nuevas; schema declara
    draft 2020-12, aceptado por Test-Json en PS 7). Solo lectura de .rdd: nunca modifica
    las receipts (si una receipt real NO pasa, el test lo reporta como divergencia).
    Fixtures negativas hermeticas en TestDrive. Patron Pester+Test-Json congelado para S2/S3.
#>

Describe 'RDD receipt contract (R8-S1)' {
    BeforeAll {
        $RepoRoot = Split-Path -Parent $PSScriptRoot
        $SchemaPath = Join-Path $RepoRoot 'contracts/rdd-receipt.schema.json'
        $RddDir = Join-Path $RepoRoot '.rdd'
        $ReceiptFiles = Get-ChildItem (Join-Path $RddDir 'rdd-receipt-00*.json') | Sort-Object Name
    }

    It 'schema exists and declares draft 2020-12' {
        Test-Path -LiteralPath $SchemaPath | Should -BeTrue
        $decl = (Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties['$schema'].Value
        $decl | Should -Match '2020-12'
    }

    It 'receipt <Name> validates against schema' -ForEach @(
        @{ Name = 'rdd-receipt-001.json' }
        @{ Name = 'rdd-receipt-002.json' }
        @{ Name = 'rdd-receipt-003.json' }
        @{ Name = 'rdd-receipt-004.json' }
    ) {
        $path = Join-Path $RddDir $Name
        Test-Path -LiteralPath $path | Should -BeTrue
        Get-Content -LiteralPath $path -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath | Should -BeTrue
    }

    It 'exactly 4 receipts indexed (001-004)' {
        @($ReceiptFiles).Count | Should -Be 4
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
