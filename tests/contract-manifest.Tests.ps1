#requires -Version 7
<#
.SYNOPSIS
    R9-S1: testdata/golden/golden-manifest.json valida contra schema formal.
.DESCRIPTION
    Gate BLOQUEANTE: PowerShell nativa Test-Json -SchemaFile (PS 7+, cero deps)
    sobre el manifest REAL + negativas en TestDrive (sin sha256, sha256
    malformado -> Should -BeFalse). Refleja datos reales: 'created' ausente
    5/5 (opcional), 'schema' vacio en registry/audit (permitido).
    Ajv 8.20.0 vendored SOLO spot-check INFO con strict:true/allErrors:true
    (try/catch, NUNCA gatea, NUNCA se declara en package.json).
    NO toca tests/prompts/, NO toca workflows, NO toca README (eso es S2).
#>

Describe 'Contract golden-manifest schema (R9-S1)' {
    BeforeAll {
        $RepoRoot = Split-Path -Parent $PSScriptRoot
        $SchemaPath = Join-Path $RepoRoot 'contracts/golden-manifest.schema.json'
        $ManifestPath = Join-Path $RepoRoot 'testdata/golden/golden-manifest.json'
    }

    It 'schema file exists (draft 2020-12, safe subset without $ref)' {
        Test-Path -LiteralPath $SchemaPath | Should -BeTrue
        $raw = Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8
        $raw | Should -Not -Match '"\$ref"'
        $raw | Should -Not -Match '"\$defs"'
    }

    It 'real manifest validates PASS against the schema (blocking gate)' {
        Test-Path -LiteralPath $ManifestPath | Should -BeTrue
        Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 |
            Test-Json -SchemaFile $SchemaPath | Should -BeTrue
    }

    It 'real manifest carries 5 goldens with empty schema allowed in registry/audit' {
        $m = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        @($m.goldens).Count | Should -BeGreaterOrEqual 5
        $empties = @($m.goldens | Where-Object { $_.schema -eq '' })
        $empties.Count | Should -Be 2
        @($empties.name | Sort-Object) | Should -Be @('audit-check-report.golden.json', 'registry-build.golden.json')
    }

    It 'manifest without sha256 FAILS schema validation (negative control)' {
        $bad = [ordered]@{
            version = 1
            goldens = @([ordered]@{
                name      = 'fake.golden.json'
                generator = 'test-generator'
            })
        }
        $badPath = Join-Path $TestDrive 'manifest-no-sha256.json'
        ($bad | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $badPath -Encoding UTF8
        Get-Content -LiteralPath $badPath -Raw -Encoding UTF8 |
            Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'manifest with malformed sha256 FAILS schema validation (negative control)' {
        $bad = [ordered]@{
            version = 1
            goldens = @([ordered]@{
                name      = 'fake.golden.json'
                generator = 'test-generator'
                sha256    = 'NOT-A-HASH'
            })
        }
        $badPath = Join-Path $TestDrive 'manifest-bad-sha256.json'
        ($bad | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $badPath -Encoding UTF8
        Get-Content -LiteralPath $badPath -Raw -Encoding UTF8 |
            Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'Ajv 8.20.0 strict spot-check compiles the schema (INFO only, never gates)' {
        $script = "try { new (require('ajv'))({strict:true,allErrors:true}).compile(require('./contracts/golden-manifest.schema.json')); console.log('AJV-STRICT-OK') } catch (e) { console.log('AJV-STRICT-WARN: ' + e.message) }"
        $out = (& node -e $script 2>&1 | Out-String)
        Write-Warning ("Ajv-strict INFO: " + $out.Trim())
        $true | Should -BeTrue
    }
}
