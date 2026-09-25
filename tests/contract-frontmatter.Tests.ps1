#requires -Version 7
<#
.SYNOPSIS
    R8-S2: frontmatter de los 97 SKILL.md valida contra contracts/skill-frontmatter.schema.json.
.DESCRIPTION
    Validador PowerShell nativo Test-Json -SchemaFile (sin deps nuevas). El helper
    Convert-SkillFrontmatterToJson (BeforeAll) parsea el bloque YAML entre los dos
    '---' a JSON: escalares (con comillas peladas), token_budget a integer,
    true/false a boolean, listas '- item' (triggers multilinea de _shared) a array.
    TRAMPA Pester 5: -ForEach se bindea en DISCOVERY, antes de BeforeAll; por eso
    el sweep usa Get-ChildItem INLINE en el -ForEach (97 files) y el helper solo
    dentro de los It (run-time, ya visible via BeforeAll). Solo lectura de los
    skills: nunca modifica SKILL.md. Fixtures negativas hermeticas en TestDrive.
    Sin contradiccion con tests/skill-frontmatter.Tests.ps1 (E1: presencia,
    unicidad y cobertura SIN tipos; este contrato fija TIPOS).
#>

Describe 'Skill frontmatter contract (R8-S2)' {
    BeforeAll {
        $RepoRoot = Split-Path -Parent $PSScriptRoot
        $SchemaPath = Join-Path $RepoRoot 'contracts/skill-frontmatter.schema.json'
        $SkillsRoot = Join-Path $RepoRoot '.agents/skills'

        function Convert-SkillFrontmatterToJson {
            param([string]$Path)
            $lines = Get-Content -LiteralPath $Path
            $dash = '---'
            if ($lines[0] -ne $dash) { throw "missing opening frontmatter in $Path" }
            $end = -1
            for ($i = 1; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -eq $dash) { $end = $i; break }
            }
            if ($end -lt 0) { throw "missing closing frontmatter in $Path" }
            $obj = [ordered]@{}
            $i = 1
            while ($i -lt $end) {
                $m = [regex]::Match($lines[$i], '^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$')
                if (-not $m.Success) { $i++; continue }
                $k = $m.Groups[1].Value
                $v = $m.Groups[2].Value.Trim()
                if ($v -eq '') {
                    $arr = @()
                    $j = $i + 1
                    while ($j -lt $end) {
                        $lm = [regex]::Match($lines[$j], '^\s*-\s+(.+)$')
                        if (-not $lm.Success) { break }
                        $arr += $lm.Groups[1].Value.Trim().Trim('"')
                        $j++
                    }
                    if ($arr.Count -gt 0) { $obj[$k] = $arr; $i = $j; continue }
                    $obj[$k] = ''
                    $i++
                    continue
                }
                $n = 0
                if ([int]::TryParse($v, [ref]$n)) { $obj[$k] = $n }
                elseif ($v -eq 'true') { $obj[$k] = $true }
                elseif ($v -eq 'false') { $obj[$k] = $false }
                else { $obj[$k] = $v.Trim('"') }
                $i++
            }
            return ($obj | ConvertTo-Json -Depth 4 -Compress)
        }
    }

    It 'schema exists and declares draft 2020-12' {
        Test-Path -LiteralPath $SchemaPath | Should -BeTrue
        $decl = (Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties['$schema'].Value
        $decl | Should -Match '2020-12'
    }

    It 'helper parses a sample skill (odd) to JSON with name+description' {
        $sample = Join-Path $SkillsRoot 'odd/SKILL.md'
        Test-Path -LiteralPath $sample | Should -BeTrue
        $o = Convert-SkillFrontmatterToJson $sample | ConvertFrom-Json
        $o.name | Should -Not -BeNullOrEmpty
        $o.description.Length | Should -BeGreaterOrEqual 10
    }

    It 'skill <Name> frontmatter validates against schema' -ForEach @(
        Get-ChildItem (Join-Path $PSScriptRoot '..\\.agents\\skills') -Filter 'SKILL.md' -Recurse -File |
            Sort-Object FullName |
            ForEach-Object { @{ Name = $_.Directory.Name; FullName = $_.FullName } }
    ) {
        Convert-SkillFrontmatterToJson $FullName | Test-Json -SchemaFile $SchemaPath | Should -BeTrue
    }

    It 'negative fixture (missing name) FAILs validation' {
        $p = Join-Path $TestDrive 'missing-name.json'
        '{"description":"0123456789 valid"}' | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'negative fixture (missing description) FAILs validation' {
        $p = Join-Path $TestDrive 'missing-desc.json'
        '{"name":"x"}' | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'negative fixture (name with space) FAILs validation' {
        $p = Join-Path $TestDrive 'bad-name.json'
        '{"name":"bad name","description":"0123456789 valid"}' | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'negative fixture (short description) FAILs validation' {
        $p = Join-Path $TestDrive 'short-desc.json'
        '{"name":"x","description":"short"}' | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'negative fixture (negative token_budget) FAILs validation' {
        $p = Join-Path $TestDrive 'neg-budget.json'
        '{"name":"x","description":"0123456789 valid","token_budget":-1}' | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'negative fixture (triggers as integer) FAILs validation' {
        $p = Join-Path $TestDrive 'bad-triggers.json'
        '{"name":"x","description":"0123456789 valid","triggers":5}' | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'negative fixture (name as integer) FAILs validation' {
        $p = Join-Path $TestDrive 'int-name.json'
        '{"name":5,"description":"0123456789 valid"}' | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'negative fixture (description as integer) FAILs validation' {
        $p = Join-Path $TestDrive 'int-desc.json'
        '{"name":"x","description":5}' | Set-Content -LiteralPath $p -Encoding UTF8
        Get-Content -LiteralPath $p -Raw -Encoding UTF8 | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
    }
}
