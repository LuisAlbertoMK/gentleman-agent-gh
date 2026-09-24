#requires -Version 7
<#
.SYNOPSIS
    Contract tests for scripts/lib/generate-opencode-config.js — TEMPLATE_MAP resolution,
    extraPermKeys merge guard, and permission assembly. Runs against a THROWAWAY copy of
    the generator in a temp repo with CRAFTED fixtures — never touches the real opencode.json.

    Coverage targets:
      1. Unmapped agent            -> process.exit(1) fail-closed
      2. extraPermKeys collision   -> ERROR, process.exit(1)
      3. readwrite merge (ADR-050) -> bash:{*:ask}, single key, ZERO allow/deny
      4. readonly merge            -> bash:{*:deny} (+ edit/write/task deny)
      5. --validate idempotency    -> exit 0 when generated output is in sync
      6. hidden propagation        -> hidden:true from agent-overrides.json only
#>
BeforeAll {
    $script:genSrc = Join-Path $PSScriptRoot '..\lib\generate-opencode-config.js'
    $script:testDir = Join-Path $env:TEMP "generate-config-test-$PID"

    # Production-exact template shapes (subset under test) — contract source of truth.
    # NOTE (ADR-050 single-mode): the auto/auto-sub/semi templates were REMOVED from
    # the SSoT (commit 65bd2a6c); no auto-sub fixture lives here anymore.
    $script:tmplReadonly = @{
        bash = @{ '*' = 'deny' }
        edit = 'deny'
        write = 'deny'
        task = @{ '*' = 'deny' }
    }
    $script:tmplReadwrite = @{
        bash = @{ '*' = 'ask' }
    }

    # Production-shaped mcp section (subset under policy test) — mirrors
    # scripts/lib/opencode-base.json:mcp: exact-allowlisted remote, disabled
    # hygiene servers, pinned npx. Any deviation = policy violation fixture.
    $script:mcpOk = @{
        'codebase-memory-mcp' = @{
            type = 'local'; command = @('codebase-memory-mcp'); enabled = $true
            timeout = 60000; environment = @{ CBM_ALLOWED_ROOT = '{env:GENTLEMAN_AGENT_ROOT}' }
        }
        'context7' = @{ enabled = $true; type = 'remote'; url = 'https://mcp.context7.com/mcp' }
        'headroom' = @{ enabled = $false; type = 'local'; command = @('headroom', 'mcp', 'serve') }
        'chrome-devtools-mcp' = @{
            type = 'local'; command = @('npx', '-y', 'chrome-devtools-mcp@1.6.0', '--no-usage-statistics')
            enabled = $false; timeout = 30000
        }
    }
    $script:agentSec = @{
        'gentleman-security' = @{
            description = 'Security specialist'; model = 'opencode/nemotron-3-ultra-free';
            mode = 'primary'; prompt = '{file:prompts/gentleman-security.md}' }
    }

    function Copy-McpPolicy {
        param([string]$Repo)
        $dst = Join-Path $Repo 'scripts\opencode-config'
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\opencode-config\mcp-policy.json') `
            -Destination (Join-Path $dst 'mcp-policy.json')
    }

    function New-GenRepo {
        param([string]$Name)
        $repo = Join-Path $script:testDir $Name
        $libDir = Join-Path $repo 'scripts\lib'
        New-Item -ItemType Directory -Path $libDir -Force | Out-Null
        Copy-Item -LiteralPath $script:genSrc -Destination (Join-Path $libDir 'generate-opencode-config.js')
        return $repo
    }

    function Set-GenFixture {
        param(
            [string]$Repo,
            [hashtable]$Agent,
            [hashtable]$Templates,
            [hashtable]$Overrides = @{},
            [hashtable]$Extra = @{}
        )
        $libDir = Join-Path $Repo 'scripts\lib'
        $base = @{ agent = $Agent }
        foreach ($k in $Extra.Keys) { $base[$k] = $Extra[$k] }
        $base | ConvertTo-Json -Depth 20 |
            Set-Content -LiteralPath (Join-Path $libDir 'opencode-base.json') -Encoding utf8
        $Templates | ConvertTo-Json -Depth 20 |
            Set-Content -LiteralPath (Join-Path $libDir 'permission-templates.json') -Encoding utf8
        $Overrides | ConvertTo-Json -Depth 20 |
            Set-Content -LiteralPath (Join-Path $libDir 'agent-overrides.json') -Encoding utf8
    }

    function Read-GenOutput {
        param([string]$Path)
        $raw = Get-Content -LiteralPath $Path -Raw
        # Generator writes a UTF-8 BOM — strip it before parsing.
        if ($raw -and $raw[0] -eq [char]0xFEFF) { $raw = $raw.Substring(1) }
        return ($raw | ConvertFrom-Json)
    }
}

AfterAll {
    Remove-Item -LiteralPath $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'generate-opencode-config.js — fail-closed' {
    It 'exits 1 for an unmapped agent (no TEMPLATE_MAP entry)' {
        $repo = New-GenRepo 'unmapped'
        Set-GenFixture -Repo $repo `
            -Agent @{ 'ghost-agent' = @{ description = 'no mapping'; mode = 'primary' } } `
            -Templates @{ 'readonly' = $script:tmplReadonly }

        $out = & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 1
        $out | Should -Match 'no template mapping'
        $out | Should -Match 'ghost-agent'
    }

    It 'exits 1 when extraPermKeys collides with a template key' {
        $repo = New-GenRepo 'collision'
        Set-GenFixture -Repo $repo `
            -Agent @{ 'gentleman-quick-sub' = @{
                description = 'Fast executor subagent'; model = 'opencode/big-pickle';
                hidden = $true; mode = 'subagent'; prompt = '{file:prompts/gentleman-quick.md}' } } `
            -Templates @{ 'readwrite' = $script:tmplReadwrite } `
            -Overrides @{ 'gentleman-quick-sub' = @{ extraPermKeys = @{ bash = @{ '*' = 'allow' } } } }

        $out = & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 1
        $out | Should -Match 'collides with template keys'
        $out | Should -Match 'bash'
    }

    It 'EXTRA perm-escalation: extraPermKeys with task key on readonly agent is denied (H2 regression, ADR-050 single-mode)' {
        # ADR-050 REMOVED the auto-sub template, so the old premise (task key collides
        # with the auto-sub template) evaporated: readwrite carries NO task key and the
        # escalation would silently merge instead of failing closed. The H2 intent —
        # task-escalation via extraPermKeys is denied — migrates to the live template
        # that still carries a task key: readonly (gentleman-security).
        $repo = New-GenRepo 'collision-task'
        Set-GenFixture -Repo $repo `
            -Agent @{ 'gentleman-security' = @{
                description = 'Security specialist'; model = 'opencode/nemotron-3-ultra-free';
                mode = 'primary'; prompt = '{file:prompts/gentleman-security.md}' } } `
            -Templates @{ 'readonly' = $script:tmplReadonly } `
            -Overrides @{ 'gentleman-security' = @{ extraPermKeys = @{ task = @{ '*' = 'allow' } } } }

        $out = & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 1
        $out | Should -Match 'collides with template keys'
        $out | Should -Match 'task'
    }
}

Describe 'generate-opencode-config.js — permission merge' {
    It 'readwrite merge: bash:{*:ask}, single key, ZERO allow/deny (ADR-050 single-mode)' {
        # ADR-050 REMOVED the auto-sub template (bash allow + task deny, ZERO ask) and
        # re-mapped gentleman-quick-sub -> readwrite (bash ask). A literal port would
        # invert the old ZERO-ask assertion, so this test asserts the NEW merge output
        # for the successor mapping — the old invariant is gone by design, declared here.
        $repo = New-GenRepo 'readwrite-sub'
        Set-GenFixture -Repo $repo `
            -Agent @{ 'gentleman-quick-sub' = @{
                description = 'Fast executor subagent'; model = 'opencode/big-pickle';
                hidden = $true; mode = 'subagent'; prompt = '{file:prompts/gentleman-quick.md}' } } `
            -Templates @{ 'readwrite' = $script:tmplReadwrite }

        & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') | Out-Null
        $LASTEXITCODE | Should -Be 0

        $agent = (Read-GenOutput (Join-Path $repo 'opencode.json')).agent.'gentleman-quick-sub'
        $perm = $agent.permission
        $perm.bash.'*' | Should -Be 'ask'
        ($perm | ConvertTo-Json -Depth 10 -Compress) | Should -Not -Match '"allow"'
        ($perm | ConvertTo-Json -Depth 10 -Compress) | Should -Not -Match '"deny"'
        ($perm.PSObject.Properties.Name -join ',') | Should -Be 'bash'
        # Base fields survive the rebuild untouched.
        $agent.description | Should -Be 'Fast executor subagent'
        $agent.mode | Should -Be 'subagent'
        $agent.hidden | Should -Be $true
    }

    It 'readonly merge: bash:{*:deny} with edit/write/task deny' {
        $repo = New-GenRepo 'readonly'
        Set-GenFixture -Repo $repo `
            -Agent @{ 'gentleman-security' = @{
                description = 'Security specialist'; model = 'opencode/nemotron-3-ultra-free';
                mode = 'primary'; prompt = '{file:prompts/gentleman-security.md}' } } `
            -Templates @{ 'readonly' = $script:tmplReadonly }

        & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') | Out-Null
        $LASTEXITCODE | Should -Be 0

        $perm = (Read-GenOutput (Join-Path $repo 'opencode.json')).agent.'gentleman-security'.permission
        $perm.bash.'*' | Should -Be 'deny'
        $perm.edit | Should -Be 'deny'
        $perm.write | Should -Be 'deny'
        $perm.task.'*' | Should -Be 'deny'
        ($perm | ConvertTo-Json -Depth 10 -Compress) | Should -Not -Match '"allow"'
    }
}

Describe 'generate-opencode-config.js — validation & overrides' {
    It '--validate exits 0 when generated output is in sync (idempotent)' {
        $repo = New-GenRepo 'idem'
        Set-GenFixture -Repo $repo `
            -Agent @{
                'gentleman-quick-sub' = @{ description = 'Fast executor subagent'; model = 'opencode/big-pickle'; hidden = $true; mode = 'subagent'; prompt = '{file:prompts/gentleman-quick.md}' }
                'gentleman-security' = @{ description = 'Security specialist'; model = 'opencode/nemotron-3-ultra-free'; mode = 'primary'; prompt = '{file:prompts/gentleman-security.md}' }
            } `
            -Templates @{ 'readwrite' = $script:tmplReadwrite; 'readonly' = $script:tmplReadonly }

        & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') | Out-Null
        $LASTEXITCODE | Should -Be 0

        $out = & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') --validate 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 0
        $out | Should -Match 'VALID'
    }

    It 'propagates hidden:true from agent-overrides.json (and only from there)' {
        $repo = New-GenRepo 'hidden'
        Set-GenFixture -Repo $repo `
            -Agent @{
                'sdd-apply' = @{ description = 'Implement code changes from task definitions'; model = 'opencode/muse-spark-1.3-contributor-free'; mode = 'subagent'; prompt = '{file:prompts/sdd/sdd-apply.md}' }
                'gentleman-quick-sub' = @{ description = 'Fast executor subagent'; mode = 'subagent' }
            } `
            -Templates @{ 'readwrite' = $script:tmplReadwrite } `
            -Overrides @{ 'sdd-apply' = @{ hidden = $true } }

        & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') | Out-Null
        $LASTEXITCODE | Should -Be 0

        $cfg = Read-GenOutput (Join-Path $repo 'opencode.json')
        $cfg.agent.'sdd-apply'.hidden | Should -Be $true
        $cfg.agent.'gentleman-quick-sub'.PSObject.Properties.Name | Should -Not -Contain 'hidden'
    }
}

Describe 'generate-opencode-config.js — mcp-policy SSoT consumer (Ronda2 S2)' {
    It 'compliant mcp passes and is emitted verbatim (policy→output)' {
        $repo = New-GenRepo 'mcp-ok'
        Set-GenFixture -Repo $repo -Agent $script:agentSec `
            -Templates @{ 'readonly' = $script:tmplReadonly } -Extra @{ mcp = $script:mcpOk }
        Copy-McpPolicy $repo

        & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') | Out-Null
        $LASTEXITCODE | Should -Be 0

        $mcp = (Read-GenOutput (Join-Path $repo 'opencode.json')).mcp
        $mcp.'context7'.url | Should -Be 'https://mcp.context7.com/mcp'
        $mcp.'codebase-memory-mcp'.environment.CBM_ALLOWED_ROOT | Should -Be '{env:GENTLEMAN_AGENT_ROOT}'
        $mcp.'headroom'.enabled | Should -Be $false
    }

    It 'non-allowlisted remote url fails closed (exit 1)' {
        $repo = New-GenRepo 'mcp-evil-remote'
        $evil = $script:mcpOk.Clone()
        $evil['evil-bridge'] = @{ enabled = $true; type = 'remote'; url = 'https://evil.example.com/mcp' }
        Set-GenFixture -Repo $repo -Agent $script:agentSec `
            -Templates @{ 'readonly' = $script:tmplReadonly } -Extra @{ mcp = $evil }
        Copy-McpPolicy $repo

        $out = & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 1
        $out | Should -Match 'NOT allowlisted'
        $out | Should -Match 'evil-bridge'
    }

    It 'enabled hygiene-listed server fails closed (exit 1)' {
        $repo = New-GenRepo 'mcp-hygiene'
        $bad = $script:mcpOk.Clone()
        $bad['headroom'] = @{ enabled = $true; type = 'local'; command = @('headroom', 'mcp', 'serve') }
        Set-GenFixture -Repo $repo -Agent $script:agentSec `
            -Templates @{ 'readonly' = $script:tmplReadonly } -Extra @{ mcp = $bad }
        Copy-McpPolicy $repo

        $out = & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 1
        $out | Should -Match 'must stay disabled'
        $out | Should -Match 'headroom'
    }

    It 'unpinned npx fails closed (exit 1)' {
        $repo = New-GenRepo 'mcp-unpinned'
        $bad = $script:mcpOk.Clone()
        $bad['evil-npx'] = @{ enabled = $true; type = 'local'; command = @('npx', '-y', 'evil-mcp') }
        Set-GenFixture -Repo $repo -Agent $script:agentSec `
            -Templates @{ 'readonly' = $script:tmplReadonly } -Extra @{ mcp = $bad }
        Copy-McpPolicy $repo

        $out = & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 1
        $out | Should -Match 'without @version pin'
        $out | Should -Match 'evil-npx'
    }

    It '--validate catches base-mcp ↔ policy drift (exit 1)' {
        $repo = New-GenRepo 'mcp-validate-drift'
        Set-GenFixture -Repo $repo -Agent $script:agentSec `
            -Templates @{ 'readonly' = $script:tmplReadonly } -Extra @{ mcp = $script:mcpOk }
        Copy-McpPolicy $repo

        & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') | Out-Null
        $LASTEXITCODE | Should -Be 0

        $evil = $script:mcpOk.Clone()
        $evil['evil-bridge'] = @{ enabled = $true; type = 'remote'; url = 'https://evil.example.com/mcp' }
        Set-GenFixture -Repo $repo -Agent $script:agentSec `
            -Templates @{ 'readonly' = $script:tmplReadonly } -Extra @{ mcp = $evil }

        $out = & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') --validate 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 1
        $out | Should -Match 'NOT allowlisted'
    }
}

Describe 'generate-opencode-config.js — missing mcp-policy fail-closed (Ronda3 S1)' {
    It 'real repo (base declares mcp, no policy file) fails closed (exit 1)' {
        $repo = New-GenRepo 'mcp-missing-real'
        Set-GenFixture -Repo $repo -Agent $script:agentSec `
            -Templates @{ 'readonly' = $script:tmplReadonly } -Extra @{ mcp = $script:mcpOk }
        # NOTE: deliberately NO Copy-McpPolicy — the policy file is absent.

        $out = & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 1
        $out | Should -Match 'mcp-policy.json is missing'
        $out | Should -Match 'mcp section'
    }

    It 'pre-policy fixture (base declares no mcp, no policy file) still skips (exit 0)' {
        $repo = New-GenRepo 'mcp-missing-prepolicy'
        Set-GenFixture -Repo $repo -Agent $script:agentSec `
            -Templates @{ 'readonly' = $script:tmplReadonly }
        # NOTE: no mcp in base AND no policy file — pre-policy repo shape.

        $out = & node (Join-Path $repo 'scripts\lib\generate-opencode-config.js') 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 0
        $out | Should -Match 'skipping MCP policy enforcement'
    }
}

Describe 'R9: regen latency benchmark fixture (Gap D — same-context measurement)' {
    # Gap D fix: baseline was measured in orchestrator context (263.8ms) vs
    # subagent context (520.9ms) → false +97.4% regression. This test measures
    # both baseline and comparison in the SAME execution context (this test run),
    # with 5 runs and median + IQR, comparing against a pinned JSON fixture.
    # Threshold: 10% relative regression from pinned baseline.

    It 'regen latency median stays within 10% of pinned baseline (5 runs)' {
        $fixturePath = Join-Path $script:testDir 'fixtures\generate-config-latency-baseline.json'
        # Fall back to repo fixture if testDir copy doesn't exist
        if (-not (Test-Path $fixturePath)) {
            $fixturePath = Join-Path $PSScriptRoot 'fixtures\generate-config-latency-baseline.json'
        }
        $fixture = Get-Content $fixturePath -Raw | ConvertFrom-Json

        $genScript = $script:genSrc
        $runs = @()
        for ($i = 0; $i -lt $fixture.runs; $i++) {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            & node $genScript --validate 2>$null | Out-Null
            $LASTEXITCODE | Should -Be 0
            $sw.Stop()
            $runs += [math]::Round($sw.Elapsed.TotalMilliseconds, 2)
        }

        $sorted = $runs | Sort-Object
        $median = $sorted[2]  # 5 runs → index 2 is median
        $threshold = $fixture.baseline_median_ms * (1 + $fixture.regression_threshold_pct / 100)

        $median | Should -BeLessThan $threshold
    }

    It 'fixture is machine-readable and pinnable for trend tracking' {
        $fixturePath = Join-Path $PSScriptRoot 'fixtures\generate-config-latency-baseline.json'
        $fixture = Get-Content $fixturePath -Raw | ConvertFrom-Json

        $fixture.baseline_median_ms | Should -BeGreaterThan 0
        $fixture.regression_threshold_pct | Should -BeGreaterThan 0
        $fixture.runs | Should -Be 5
        $fixture.methodology | Should -Not -BeNullOrEmpty
    }
}
