#requires -Version 7
<#
.SYNOPSIS
    R8-S3: testdata/golden/*.golden.json re-ejecutables + comparador hash determinista.
.DESCRIPTION
    Cada golden fija el output canonico de su generador (plan §1-Q2). El test
    re-ejecuta cada generador, normaliza (keys ordenadas recursivas, arrays en
    orden explicito del generador, SIN timestamps volatiles) y compara contra
    el golden + verifica el sha256 byte-level contra golden-manifest.json.
    Determinismo: doble re-run debe dar el mismo hash (Tier 1 + §4).
    Comparador inline en BeforeAll (AllowedPaths S3: solo testdata/golden/*,
    tests/contract-*.Tests.ps1, odd/tasks/ronda8-contratos.md; el helper
    scripts/tests/contract-helpers.ps1 del plan NO se crea en este slice).
    Mitigacion no-determinismo (riesgo declarado §S3): registry excluye
    .generated (locale datetime volatil); resto es sort + conteos.
    Solo lectura de fuentes: nunca modifica .rdd/, scripts/lib/, skills.
    NO toca tests/prompts/ (solo re-corre su gate aparte).
#>

Describe 'Contract goldens comparator (R8-S3)' {
    BeforeAll {
        $RepoRoot = Split-Path -Parent $PSScriptRoot
        $GoldenDir = Join-Path $RepoRoot 'testdata/golden'
        $ManifestPath = Join-Path $GoldenDir 'golden-manifest.json'
        $GoldenNames = @(
            'validate-rdd-receipts.golden.json'
            'permission-matrix-expansion.golden.json'
            'skill-frontmatter-parse.golden.json'
            'registry-build.golden.json'
            'audit-check-report.golden.json'
        )
        # Hermetic registry builds: canonical generator + skills source, cached
        # once here; each Invoke-GoldenGenerator call builds into its own temp
        # file (never scripts/skill-registry.json — gitignored, absent in CI).
        $RegistryBuilder = Join-Path $RepoRoot 'scripts/build-skill-registry.ps1'
        $RegistrySkillsDir = Join-Path $RepoRoot '.agents/skills'

        function ConvertTo-SortedObject {
            param([object]$Node)
            if ($Node -is [System.Management.Automation.PSCustomObject]) {
                $o = [ordered]@{}
                foreach ($p in ($Node.PSObject.Properties | Sort-Object Name)) {
                    $o[$p.Name] = ConvertTo-SortedObject $p.Value
                }
                return $o
            }
            if ($Node -is [System.Collections.IDictionary]) {
                $o = [ordered]@{}
                foreach ($k in ($Node.Keys | Sort-Object)) {
                    $o[$k] = ConvertTo-SortedObject $Node[$k]
                }
                return $o
            }
            if ($Node -is [System.Collections.IList] -and $Node -isnot [string]) {
                # return/Write-Output unroll single-element arrays and void empty
                # ones; NoEnumerate preserves array-ness (PS unrolling trap).
                $list = [System.Collections.Generic.List[object]]::new()
                foreach ($it in $Node) { $list.Add((ConvertTo-SortedObject $it)) }
                Write-Output -NoEnumerate $list.ToArray()
                return
            }
            return $Node
        }

        function ConvertTo-CanonicalJson {
            param([object]$Node)
            return (ConvertTo-SortedObject $Node | ConvertTo-Json -Depth 12 -Compress)
        }

        function Get-LeafValues {
            param([object]$Node)
            $out = @()
            if ($Node -is [string]) { Write-Output -NoEnumerate @($Node); return }
            if ($Node -is [System.Management.Automation.PSCustomObject]) {
                foreach ($p in $Node.PSObject.Properties) { $out += Get-LeafValues $p.Value }
            }
            Write-Output -NoEnumerate @($out)
            return
        }

        function Convert-SkillFrontmatterToJson {
            param([string]$Path)
            $lines = Get-Content -LiteralPath $Path
            if ($lines[0] -ne '---') { throw "missing opening frontmatter in $Path" }
            $end = -1
            for ($i = 1; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -eq '---') { $end = $i; break }
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
                    $arr = @(); $j = $i + 1
                    while ($j -lt $end) {
                        $lm = [regex]::Match($lines[$j], '^\s*-\s+(.+)$')
                        if (-not $lm.Success) { break }
                        $arr += $lm.Groups[1].Value.Trim().Trim('"'); $j++
                    }
                    if ($arr.Count -gt 0) { $obj[$k] = $arr; $i = $j; continue }
                    $obj[$k] = ''; $i++; continue
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

        function Invoke-GoldenGenerator {
            param([string]$Name)
            switch ($Name) {
                'validate-rdd-receipts.golden.json' {
                    $schema = Join-Path $RepoRoot 'contracts/rdd-receipt.schema.json'
                    $passed = @(); $failed = @()
                    $files = Get-ChildItem (Join-Path $RepoRoot '.rdd/rdd-receipt-00*.json') | Sort-Object Name
                    foreach ($f in $files) {
                        $ok = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 | Test-Json -SchemaFile $schema
                        if ($ok) { $passed += $f.Name } else { $failed += $f.Name }
                    }
                    return [ordered]@{
                        args      = '.rdd/rdd-receipt-00*.json (sorted by name)'
                        failed    = $failed
                        generator = 'Get-Content -Raw | Test-Json -SchemaFile contracts/rdd-receipt.schema.json'
                        passed    = $passed
                        schema    = 'contracts/rdd-receipt.schema.json'
                        total     = $passed.Count + $failed.Count
                    }
                }
                'permission-matrix-expansion.golden.json' {
                    $src = Join-Path $RepoRoot 'scripts/lib/permission-templates.json'
                    $j = Get-Content -LiteralPath $src -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10
                    $exp = [ordered]@{}
                    foreach ($t in (@('orchestrator', 'readonly', 'readwrite', 'reviewer', 'sddorchestrator') | Sort-Object)) {
                        $leaves = Get-LeafValues ($j.$t)
                        $exp[$t] = [ordered]@{
                            allow = @($leaves | Where-Object { $_ -eq 'allow' }).Count
                            ask   = @($leaves | Where-Object { $_ -eq 'ask' }).Count
                            deny  = @($leaves | Where-Object { $_ -eq 'deny' }).Count
                            total = $leaves.Count
                        }
                    }
                    return [ordered]@{
                        expansion = $exp
                        generator = 'leaf-scan allow/deny/ask per template over scripts/lib/permission-templates.json (sorted templates)'
                        source    = 'scripts/lib/permission-templates.json'
                        templates = @('orchestrator', 'readonly', 'readwrite', 'reviewer', 'sddorchestrator')
                    }
                }
                'skill-frontmatter-parse.golden.json' {
                    $root = Join-Path $RepoRoot '.agents/skills'
                    $samples = [ordered]@{}
                    foreach ($s in @('engram-protocol', 'odd', 'ps-compat')) {
                        $p = Join-Path $root "$s/SKILL.md"
                        $samples[$s] = Convert-SkillFrontmatterToJson $p | ConvertFrom-Json
                    }
                    return [ordered]@{
                        generator = "Convert-SkillFrontmatterToJson (tests/contract-frontmatter.Tests.ps1 pattern: scalars, token_budget int, '- item' lists)"
                        samples   = $samples
                        schema    = 'contracts/skill-frontmatter.schema.json'
                        total     = $samples.Count
                    }
                }
                'registry-build.golden.json' {
                    # Hermetic: build the registry into a fresh temp file per
                    # invocation (never read scripts/skill-registry.json — it is
                    # gitignored and absent from clean CI checkouts). Each call
                    # builds exactly once, so the double re-run determinism test
                    # below still exercises 2 real builder runs.
                    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("registry-build-{0}-{1}.json" -f $PID, [guid]::NewGuid().ToString('N'))
                    try {
                        & $RegistryBuilder -SkillsDir $RegistrySkillsDir -OutputFile $tmp -Quiet
                        if (-not (Test-Path -LiteralPath $tmp)) {
                            throw "registry builder produced no output file: $tmp (scripts/build-skill-registry.ps1 swallows errors via Write-Warning — see warnings above)"
                        }
                        $r = Get-Content -LiteralPath $tmp -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
                        if (-not $r.skills -or -not $r.trigger_index) {
                            throw "registry builder output at $tmp is missing 'skills' or 'trigger_index' (fail-silent build?)"
                        }
                        $names = @($r.skills.PSObject.Properties.Name | Sort-Object)
                        return [ordered]@{
                            excluded_volatile = @('generated')
                            generator         = 'scripts/build-skill-registry.ps1 + normalization (drop .generated locale datetime, sort skill names)'
                            normalization     = 'drop .generated (locale datetime, non-deterministic); sort skill names; trigger_index as count only'
                            skill_count       = $names.Count
                            skills            = $names
                            source            = 'scripts/skill-registry.json'
                            trigger_index_count = @($r.trigger_index.PSObject.Properties).Count
                        }
                    }
                    finally {
                        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
                    }
                }
                'audit-check-report.golden.json' {
                    $script = Join-Path $RepoRoot 'scripts/skills-audit-check.ps1'
                    if ($script -ne (Join-Path $RepoRoot 'scripts/skills-audit-check.ps1')) { throw "unexpected script path: $script" }
                    $out = & $script -SkillName odd -Json | ConvertFrom-Json
                    $rules = @($out.Rules | Sort-Object Rule | ForEach-Object {
                        [ordered]@{ detail = $_.Detail; pass = $_.Pass; rule = $_.Rule }
                    })
                    return [ordered]@{
                        all_pass  = [bool]$out.AllPass
                        args      = '-SkillName odd -Json'
                        generator = 'scripts/skills-audit-check.ps1 -SkillName odd -Json'
                        passed    = [int]$out.Passed
                        rules     = $rules
                        skill     = 'odd'
                        total     = [int]$out.Total
                    }
                }
                default { throw "unknown golden: $Name" }
            }
        }
    }

    It 'manifest exists with 5 goldens (name, generator, sha256 required)' {
        Test-Path -LiteralPath $ManifestPath | Should -BeTrue
        $m = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        @($m.goldens).Count | Should -Be 5
        foreach ($g in $m.goldens) {
            $g.name | Should -Not -BeNullOrEmpty
            $g.generator | Should -Not -BeNullOrEmpty
            $g.sha256 | Should -Match '^[0-9a-f]{64}$'
            $GoldenNames | Should -Contain $g.name
        }
    }

    It 'golden file <Name> hash matches manifest sha256' -ForEach @(
        @{ Name = 'validate-rdd-receipts.golden.json' }
        @{ Name = 'permission-matrix-expansion.golden.json' }
        @{ Name = 'skill-frontmatter-parse.golden.json' }
        @{ Name = 'registry-build.golden.json' }
        @{ Name = 'audit-check-report.golden.json' }
    ) {
        $m = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $entry = @($m.goldens | Where-Object { $_.name -eq $Name })[0]
        $entry | Should -Not -BeNullOrEmpty
        $actual = (Get-FileHash -LiteralPath (Join-Path $GoldenDir $Name) -Algorithm SHA256).Hash.ToLower()
        $actual | Should -Be $entry.sha256
    }

    It 're-executed generator for <Name> matches golden content' -ForEach @(
        @{ Name = 'validate-rdd-receipts.golden.json' }
        @{ Name = 'permission-matrix-expansion.golden.json' }
        @{ Name = 'skill-frontmatter-parse.golden.json' }
        @{ Name = 'registry-build.golden.json' }
        @{ Name = 'audit-check-report.golden.json' }
    ) {
        $fresh = Invoke-GoldenGenerator $Name
        $stored = Get-Content -LiteralPath (Join-Path $GoldenDir $Name) -Raw -Encoding UTF8 | ConvertFrom-Json
        (ConvertTo-CanonicalJson $fresh) | Should -Be (ConvertTo-CanonicalJson $stored)
    }

    It 'double re-run of <Name> yields same hash (determinism)' -ForEach @(
        @{ Name = 'validate-rdd-receipts.golden.json' }
        @{ Name = 'permission-matrix-expansion.golden.json' }
        @{ Name = 'skill-frontmatter-parse.golden.json' }
        @{ Name = 'registry-build.golden.json' }
        @{ Name = 'audit-check-report.golden.json' }
    ) {
        $h1 = ConvertTo-CanonicalJson (Invoke-GoldenGenerator $Name)
        $h2 = ConvertTo-CanonicalJson (Invoke-GoldenGenerator $Name)
        $h1 | Should -Be $h2
    }

    It 'goldens carry no volatile timestamp data fields' {
        foreach ($n in $GoldenNames) {
            $o = Get-Content -LiteralPath (Join-Path $GoldenDir $n) -Raw -Encoding UTF8 | ConvertFrom-Json
            $o.PSObject.Properties.Name | Should -Not -Contain 'generated'
            $o.PSObject.Properties.Name | Should -Not -Contain 'timestamp'
        }
    }
}
