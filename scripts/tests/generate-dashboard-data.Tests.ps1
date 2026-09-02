#requires -Version 7.0
<#
.SYNOPSIS
  Pester 5 tests for generate-dashboard-data.ps1
#>
Set-StrictMode -Version Latest

Describe 'generate-dashboard-data' {

    BeforeAll {
        $script:repoRoot = (git rev-parse --show-toplevel 2>$null)
        if (-not $script:repoRoot) { $script:repoRoot = (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) }
        $script:generator = Join-Path $script:repoRoot 'scripts/generate-dashboard-data.ps1'
        $script:dataJson = Join-Path $script:repoRoot 'docs/dashboard/data.json'
        $script:tempJson = Join-Path $env:TEMP 'dashboard-data-test.json'
        # expected live counts
        $oc = Get-Content (Join-Path $script:repoRoot 'opencode.json') -Raw | ConvertFrom-Json
        $script:expectedAgents = @($oc.agent.PSObject.Properties).Count
        $script:expectedSkills = (Get-ChildItem (Join-Path $script:repoRoot '.agents/skills') -Directory).Count
    }

    Context 'schema keys exist' {
        BeforeAll {
            $env:PESTER_TEST = '1'
            if (Test-Path $script:tempJson) { Remove-Item $script:tempJson -Force }
            & $script:generator 2>$null
            $script:data = Get-Content $script:tempJson -Raw | ConvertFrom-Json
        }
        AfterAll { $env:PESTER_TEST = $null }

        It 'has top-level keys generatedAt, gate, fast, agents, skills, score' {
            $script:data.PSObject.Properties.Name | Should -Contain 'generatedAt'
            $script:data.PSObject.Properties.Name | Should -Contain 'gate'
            $script:data.PSObject.Properties.Name | Should -Contain 'fast'
            $script:data.PSObject.Properties.Name | Should -Contain 'agents'
            $script:data.PSObject.Properties.Name | Should -Contain 'skills'
            ($script:data.PSObject.Properties.Name -contains 'score' -or $script:data.PSObject.Properties.Name -contains 'projectScore') | Should -Be $true
        }
        It 'gate has passed/pass, total, durationMs/elapsedMs' {
            $g = $script:data.gate
            ($null -ne $g.pass -or $null -ne $g.passed) | Should -Be $true
            ($null -ne $g.total) | Should -Be $true
            ($null -ne $g.durationMs -or $null -ne $g.elapsedMs) | Should -Be $true
        }
        It 'fast has elapsedMs, crossRefMs, tokenBudgetMs' {
            $script:data.fast.elapsedMs | Should -Not -BeNullOrEmpty
            $script:data.fast.PSObject.Properties.Name | Should -Contain 'crossRefMs'
            $script:data.fast.PSObject.Properties.Name | Should -Contain 'tokenBudgetMs'
        }
        It 'agents has total' {
            $script:data.agents.total | Should -Not -BeNullOrEmpty
        }
        It 'skills has total, budgeted, avgBudget, overBudget' {
            $script:data.skills.total | Should -Not -BeNullOrEmpty
            $script:data.skills.budgeted | Should -Not -BeNullOrEmpty
            $script:data.skills.avgBudget | Should -Not -BeNullOrEmpty
            $script:data.skills.overBudget | Should -Not -BeNullOrEmpty
        }
        It 'generatedAt is valid ISO8601' {
            $raw = Get-Content $script:tempJson -Raw
            ($raw -match '"generatedAt"\s*:\s*"[^"]+T[^"]+"') | Should -Be $true
            { [datetime]::Parse([string]$script:data.generatedAt) } | Should -Not -Throw
        }
    }

    Context 'counts match live repo' {
        BeforeAll {
            $env:PESTER_TEST = '1'
            if (Test-Path $script:tempJson) { Remove-Item $script:tempJson -Force }
            & $script:generator 2>$null
            $script:data = Get-Content $script:tempJson -Raw | ConvertFrom-Json
        }
        AfterAll { $env:PESTER_TEST = $null }

        It 'agents.total == 58 matches opencode.json count' {
            $script:data.agents.total | Should -Be $script:expectedAgents
            $script:data.agents.total | Should -Be 58
        }
        It 'skills.total == 93 matches .agents/skills count' {
            $script:data.skills.total | Should -Be $script:expectedSkills
            $script:data.skills.total | Should -Be 93
        }
    }

    Context 'PESTER_TEST=1 writes only to temp' {
        It 'writes to temp and does not create docs/dashboard/data.json' {
            $env:PESTER_TEST = '1'
            # ensure clean state: remove temp but do not assume data.json absence
            if (Test-Path $script:tempJson) { Remove-Item $script:tempJson -Force }
            $beforeStatus = git -C $script:repoRoot status --porcelain 2>$null
            # stash data.json existence before
            $dataExistedBefore = Test-Path $script:dataJson
            $beforeHash = if ($dataExistedBefore) { (Get-FileHash $script:dataJson -Algorithm SHA256).Hash } else { $null }

            & $script:generator 2>$null

            Test-Path $script:tempJson | Should -Be $true
            # verify data.json not modified (hash same or not created if didn't exist)
            if ($dataExistedBefore) {
                Test-Path $script:dataJson | Should -Be $true
                (Get-FileHash $script:dataJson -Algorithm SHA256).Hash | Should -Be $beforeHash
            }
            # no git changes except untracked temp (which is outside repo)
            $afterStatus = git -C $script:repoRoot status --porcelain 2>$null
            # filter out docs/dashboard/data.json if it was already untracked before
            $beforeStatus = $beforeStatus | Where-Object { $_ -match 'docs/dashboard/data\.json' }
            $afterStatusFiltered = $afterStatus | Where-Object { $_ -match 'docs/dashboard/data\.json' }
            # if data.json existed before as untracked, count should be same; if tracked, should be same
            @($afterStatusFiltered).Count | Should -Be @($beforeStatus).Count

            $env:PESTER_TEST = $null
            if (Test-Path $script:tempJson) { Remove-Item $script:tempJson -Force -ErrorAction SilentlyContinue }
        }
    }

    Context 'overBudget top5 shape' {
        BeforeAll {
            $env:PESTER_TEST = '1'
            if (Test-Path $script:tempJson) { Remove-Item $script:tempJson -Force }
            & $script:generator 2>$null
            $script:data = Get-Content $script:tempJson -Raw | ConvertFrom-Json
        }
        AfterAll { $env:PESTER_TEST = $null }

        It 'overBudgetSkills is array with name,size,budget fields' {
            $arr = $script:data.skills.overBudgetSkills
            $arr | Should -Not -BeNullOrEmpty
            $arr.Count | Should -BeLessOrEqual 8
            foreach ($item in @($arr)[0..([Math]::Min(4, $arr.Count - 1))]) {
                $item.PSObject.Properties.Name | Should -Contain 'name'
                ($item.PSObject.Properties.Name -contains 'size' -or $item.PSObject.Properties.Name -contains 'actual') | Should -Be $true
                $item.PSObject.Properties.Name | Should -Contain 'budget'
            }
        }
        It 'overBudget top5 respects budget/size shape' {
            $top5 = @($script:data.skills.overBudgetSkills | Select-Object -First 5)
            $top5.Count | Should -BeLessOrEqual 5
            foreach ($o in $top5) {
                $o.name | Should -Not -BeNullOrEmpty
                ([int]$o.size -gt 0 -or [int]$o.actual -gt 0) | Should -Be $true
            }
        }
    }

    Context 'RepoRoot param resilience' {
        BeforeEach {
            $script:tmpRoot = Join-Path $env:TEMP ("dash-test-" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $script:tmpRoot -Force | Out-Null
        }
        AfterEach {
            if (Test-Path $script:tmpRoot) { Remove-Item $script:tmpRoot -Recurse -Force -ErrorAction SilentlyContinue }
            if (Test-Path $script:tempJson) { Remove-Item $script:tempJson -Force -ErrorAction SilentlyContinue }
            $env:PESTER_TEST = $null
        }

        It 'malformed opencode.json in temp RepoRoot -> agents.total=0 no throw' {
            $env:PESTER_TEST = '1'
            Set-Content -Path (Join-Path $script:tmpRoot 'opencode.json') -Value '{ invalid json ' -Encoding utf8NoBOM
            { & $script:generator -RepoRoot $script:tmpRoot 2>$null } | Should -Not -Throw
            $d = Get-Content $script:tempJson -Raw | ConvertFrom-Json
            $d.agents.total | Should -Be 0
        }

        It 'SKILL.md missing token_budget -> counted unbudgeted no throw' {
            $env:PESTER_TEST = '1'
            Set-Content -Path (Join-Path $script:tmpRoot 'opencode.json') -Value '{"agent":{}}' -Encoding utf8NoBOM
            $skillsDir = Join-Path $script:tmpRoot '.agents/skills/demo-skill'
            New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
            Set-Content -Path (Join-Path $skillsDir 'SKILL.md') -Value "# Demo`nNo budget here" -Encoding utf8NoBOM
            { & $script:generator -RepoRoot $script:tmpRoot 2>$null } | Should -Not -Throw
            $d = Get-Content $script:tempJson -Raw | ConvertFrom-Json
            $d.skills.total | Should -Be 1
            $d.skills.budgeted | Should -Be 0
        }

        It 'fast.exe absent (RepoRoot without bin/) -> fast block null/0 + gate still emitted' {
            $env:PESTER_TEST = '1'
            Set-Content -Path (Join-Path $script:tmpRoot 'opencode.json') -Value '{"agent":{"a":{}}}' -Encoding utf8NoBOM
            $skillsDir = Join-Path $script:tmpRoot '.agents/skills/s1'
            New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
            Set-Content -Path (Join-Path $skillsDir 'SKILL.md') -Value "---`ntoken_budget: 3200`n---`n# S1" -Encoding utf8NoBOM
            { & $script:generator -RepoRoot $script:tmpRoot 2>$null } | Should -Not -Throw
            $d = Get-Content $script:tempJson -Raw | ConvertFrom-Json
            $d.gate | Should -Not -BeNullOrEmpty
            $d.fast | Should -Not -BeNullOrEmpty
            ($d.fast.elapsedMs -eq 0 -or $null -eq $d.fast.elapsedMs) | Should -Be $true
        }
    }
}
