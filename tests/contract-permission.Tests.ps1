#requires -Version 7
<#
.SYNOPSIS
    R8-S2: scripts/lib/permission-templates.json valida contra contracts/permission-templates.schema.json.
.DESCRIPTION
    Validador PowerShell nativo Test-Json -SchemaFile (sin deps nuevas). El schema
    fija ESTRUCTURA (subset seguro de Test-Json); la SEMANTICA de valores vive aqui:
    leaf-scan allow/deny/ask sobre los 5 templates + spot-checks de lockdown
    (readonly), minimalismo (readwrite) y defaults (orchestrator). Solo lectura de
    la fuente: nunca modifica permission-templates.json. Fixtures negativas
    hermeticas en TestDrive (estructurales: el schema no tipa hojas anidadas).
#>

Describe 'Permission templates contract (R8-S2)' {
    BeforeAll {
        $RepoRoot = Split-Path -Parent $PSScriptRoot
        $SchemaPath = Join-Path $RepoRoot 'contracts/permission-templates.schema.json'
        $SourcePath = Join-Path $RepoRoot 'scripts/lib/permission-templates.json'
        $Templates = @('orchestrator', 'readonly', 'readwrite', 'reviewer', 'sddorchestrator')
        $AllowedLeaves = @('allow', 'deny', 'ask')

        function Get-LeafValues {
            param([object]$Node)
            $out = @()
            if ($Node -is [string]) { return @($Node) }
            if ($Node -is [System.Management.Automation.PSCustomObject]) {
                foreach ($p in $Node.PSObject.Properties) {
                    $out += Get-LeafValues $p.Value
                }
            }
            return $out
        }
    }

    It 'schema exists and declares draft 2020-12' {
        Test-Path -LiteralPath $SchemaPath | Should -BeTrue
        $decl = (Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties['$schema'].Value
        $decl | Should -Match '2020-12'
    }

    It 'source permission-templates.json exists' {
        Test-Path -LiteralPath $SourcePath | Should -BeTrue
    }

    It 'real templates file validates against schema' {
        Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath | Should -BeTrue
    }

    It 'all 5 required templates are present' {
        $j = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
        foreach ($t in $Templates) {
            $j.PSObject.Properties.Name | Should -Contain $t
        }
    }

    It '_used_by metadata covers the 5 templates' {
        $j = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
        foreach ($t in $Templates) {
            $j._used_by.PSObject.Properties.Name | Should -Contain $t
        }
    }

    It 'every leaf value inside templates is allow/deny/ask' {
        $j = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
        $bad = @()
        foreach ($t in $Templates) {
            foreach ($leaf in (Get-LeafValues $j.$t)) {
                if ($leaf -notin $AllowedLeaves) { $bad += "$t=$leaf" }
            }
        }
        $bad.Count | Should -Be 0
    }

    It 'readonly is locked down (bash/task deny, no edit/write)' {
        $j = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
        $j.readonly.bash.'*' | Should -Be 'deny'
        $j.readonly.task.'*' | Should -Be 'deny'
        "$($j.readonly.edit)" | Should -Be 'deny'
        "$($j.readonly.write)" | Should -Be 'deny'
    }

    It 'readwrite is minimal (bash ask only)' {
        $j = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
        $j.readwrite.bash.'*' | Should -Be 'ask'
    }

    It 'orchestrator denies task by default with allow exceptions' {
        $j = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
        $j.orchestrator.bash.'*' | Should -Be 'ask'
        $j.orchestrator.task.'*' | Should -Be 'deny'
        $j.orchestrator.task.explore | Should -Be 'allow'
        @($j.orchestrator.task.PSObject.Properties | Where-Object { $_.Value -eq 'allow' }).Count | Should -BeGreaterThan 0
    }

    It 'negative fixture (missing required template) FAILs validation' {
        $j = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
        $j.PSObject.Properties.Remove('reviewer')
        $p = Join-Path $TestDrive 'missing-template.json'
        $j | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'negative fixture (template as scalar) FAILs validation' {
        $j = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
        $j.readonly = 'deny'
        $p = Join-Path $TestDrive 'scalar-template.json'
        $j | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'negative fixture (top-level extra scalar key) FAILs validation' {
        $j = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
        $j | Add-Member -NotePropertyName 'zzz_extra' -NotePropertyValue 'junk' -Force
        $p = Join-Path $TestDrive 'extra-scalar.json'
        $j | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }
}
