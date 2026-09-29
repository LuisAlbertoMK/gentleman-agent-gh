#requires -Version 7

<#
.SYNOPSIS
    Tests for sync-n-projects.ps1 -Discover mode (per-machine manifest).
#>

BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'sync-n-projects.ps1'
    $repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $chainLeaf = Split-Path $repoRoot -Leaf

    function Invoke-Discover {
        param([string[]]$Arguments)
        # Child process: the wrapper uses `exit`, which must not kill the test run.
        $output = & pwsh -NoProfile -File $scriptPath @Arguments 2>&1
        $joined = ($output | ForEach-Object { "$_" }) -join "`n"
        return [PSCustomObject]@{
            output   = $output
            joined   = $joined
            exitCode = $LASTEXITCODE
        }
    }

    function New-DiscoverFixture {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ('disco-' + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $root | Out-Null
        # Candidates (created out of alphabetical order on purpose).
        New-Item -ItemType Directory -Path (Join-Path $root 'proj-b') | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'proj-b/.git') | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'proj-a') | Out-Null
        '{}' | Set-Content (Join-Path $root 'proj-a/opencode.json') -Encoding UTF8
        # Excluded: dot-directory (even with .git) and node_modules (even with opencode.json).
        New-Item -ItemType Directory -Path (Join-Path $root '.hidden') | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root '.hidden/.git') | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'node_modules') | Out-Null
        '{}' | Set-Content (Join-Path $root 'node_modules/opencode.json') -Encoding UTF8
        return $root
    }
}

Describe 'sync-n-projects.ps1 — syntax validation' {
    It 'parses without errors' {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}

Describe 'sync-n-projects.ps1 — discovery manifest generation' {
    It 'creates the manifest with the real schema, sorted and deterministic' {
        $root = New-DiscoverFixture
        # H2 mutation guard: reverse the enumeration order so the
        # Sort-Object in the wrapper is load-bearing (NTFS returns
        # alphabetical order by chance and would mask a missing sort).
        $env:SYNC_DISCOVER_REVERSE_INPUT = '1'
        try {
            $manifest = Join-Path $root 'out/projects.json'
            $r = Invoke-Discover @('-Manifest', $manifest, '-Discover', '-DiscoverRoot', $root, '-AllowExternalManifest')
            $r.exitCode | Should -Be 0
            Test-Path $manifest | Should -BeTrue
            $m = Get-Content $manifest -Raw | ConvertFrom-Json
            $m.version | Should -Be 1
            $m.chainRoot | Should -Be '.'
            $m.defaultMode | Should -Be 'chain-wins'
            $m.projects.Count | Should -Be 2
            $m.projects[0].path | Should -Be '../proj-a'
            $m.projects[1].path | Should -Be '../proj-b'
            $m.projects[0].defaultAgent | Should -Be 'gentle-MK'
            $m.projects[1].defaultAgent | Should -Be 'gentle-MK'
            # Deterministic: re-running with -Force produces byte-identical output.
            $before = Get-Content $manifest -Raw
            $r2 = Invoke-Discover @('-Manifest', $manifest, '-Discover', '-DiscoverRoot', $root, '-Force', '-AllowExternalManifest')
            $r2.exitCode | Should -Be 0
            Get-Content $manifest -Raw | Should -Be $before
        } finally {
            Remove-Item Env:SYNC_DISCOVER_REVERSE_INPUT -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
        }
    }

    It '-DryRun does not write the manifest' {
        $root = New-DiscoverFixture
        try {
            $manifest = Join-Path $root 'preview/projects.json'
            $r = Invoke-Discover @('-Manifest', $manifest, '-Discover', '-DiscoverRoot', $root, '-DryRun')
            $r.exitCode | Should -Be 0
            Test-Path $manifest | Should -BeFalse
            $r.joined | Should -Match 'proj-a'
        } finally {
            Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
        }
    }

    It 'refuses to overwrite an existing manifest without -Force' {
        $root = New-DiscoverFixture
        try {
            $manifest = Join-Path $root 'projects.json'
            'sentinel' | Set-Content $manifest -Encoding UTF8
            $r = Invoke-Discover @('-Manifest', $manifest, '-Discover', '-DiscoverRoot', $root, '-AllowExternalManifest')
            $r.exitCode | Should -Not -Be 0
            $r.joined | Should -Match 'already exists'
            Get-Content $manifest -Raw | Should -Match 'sentinel'
            # With -Force the overwrite succeeds.
            $r2 = Invoke-Discover @('-Manifest', $manifest, '-Discover', '-DiscoverRoot', $root, '-Force', '-AllowExternalManifest')
            $r2.exitCode | Should -Be 0
            Get-Content $manifest -Raw | Should -Not -Match 'sentinel'
        } finally {
            Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
        }
    }

    It '-Json dry-run emits valid, parseable JSON with the real schema' {
        $root = New-DiscoverFixture
        try {
            $r = Invoke-Discover @('-Manifest', (Join-Path $root 'x.json'), '-Discover', '-DiscoverRoot', $root, '-DryRun', '-Json')
            $r.exitCode | Should -Be 0
            $m = $r.joined | ConvertFrom-Json -ErrorAction Stop
            $m.version | Should -Be 1
            $m.projects.Count | Should -Be 2
            $m.projects[0].path | Should -Be '../proj-a'
        } finally {
            Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
        }
    }

    It 'excludes the chain repo itself when scanning the real parent (dry-run)' {
        $parent = Split-Path $repoRoot -Parent
        $probe = Join-Path ([System.IO.Path]::GetTempPath()) ('disco-probe-' + [System.IO.Path]::GetRandomFileName() + '.json')
        $r = Invoke-Discover @('-Manifest', $probe, '-Discover', '-DiscoverRoot', $parent, '-DryRun', '-Json')
        $r.exitCode | Should -Be 0
        Test-Path $probe | Should -BeFalse
        $m = $r.joined | ConvertFrom-Json -ErrorAction Stop
        $m.projects.path | Should -Not -Contain "../$chainLeaf"
    }

    It '-WhatIf prints no [ok] and writes nothing (H3)' {
        $root = New-DiscoverFixture
        try {
            $manifest = Join-Path $root 'out/projects.json'
            $r = Invoke-Discover @('-Manifest', $manifest, '-Discover', '-DiscoverRoot', $root, '-AllowExternalManifest', '-Force', '-WhatIf')
            $r.exitCode | Should -Be 0
            $r.joined | Should -Not -Match '\[ok\]'
            Test-Path $manifest | Should -BeFalse
        } finally {
            Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
        }
    }

    It 'excludes junctions/symlinks — reparse points are never candidates (H4)' {
        $root = New-DiscoverFixture
        $target = Join-Path ([System.IO.Path]::GetTempPath()) ('disco-target-' + [System.IO.Path]::GetRandomFileName())
        try {
            New-Item -ItemType Directory -Path $target | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $target '.git') | Out-Null
            $link = Join-Path $root 'link-proj'
            $created = $false
            try {
                New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop | Out-Null
                $created = $true
            } catch {
                New-Item -ItemType SymbolicLink -Path $link -Target $target -ErrorAction Stop | Out-Null
                $created = $true
            }
            if (-not $created) { throw 'could not create junction or symlink for H4 test' }
            $r = Invoke-Discover @('-Manifest', (Join-Path $root 'x.json'), '-Discover', '-DiscoverRoot', $root, '-DryRun', '-Json')
            $r.exitCode | Should -Be 0
            $m = $r.joined | ConvertFrom-Json -ErrorAction Stop
            $m.projects.path | Should -Not -Contain '../link-proj'
            $m.projects.path | Should -Contain '../proj-a'
        } finally {
            Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $target -ErrorAction SilentlyContinue
        }
    }

    It 'refuses a directory as manifest destination with zero residue (H5)' {
        $root = New-DiscoverFixture
        try {
            $destDir = Join-Path $root 'adir'
            New-Item -ItemType Directory -Path $destDir | Out-Null
            $r = Invoke-Discover @('-Manifest', $destDir, '-Discover', '-DiscoverRoot', $root, '-Force', '-AllowExternalManifest')
            $r.exitCode | Should -Not -Be 0
            $r.joined | Should -Match 'is a directory'
            @(Get-ChildItem -LiteralPath $destDir -Force).Count | Should -Be 0
        } finally {
            Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
        }
    }

    It 'refuses an external manifest without -AllowExternalManifest (H6)' {
        $root = New-DiscoverFixture
        try {
            $manifest = Join-Path $root 'out/projects.json'
            $r = Invoke-Discover @('-Manifest', $manifest, '-Discover', '-DiscoverRoot', $root)
            $r.exitCode | Should -Not -Be 0
            $r.joined | Should -Match 'AllowExternalManifest'
            Test-Path $manifest | Should -BeFalse
        } finally {
            Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
        }
    }

    It 'refuses protected locations even with -AllowExternalManifest (H6)' {
        $root = New-DiscoverFixture
        try {
            $probe = Join-Path $env:SystemRoot 'sync-n-projects-discover-probe.json'
            $r = Invoke-Discover @('-Manifest', $probe, '-Discover', '-DiscoverRoot', $root, '-Force', '-AllowExternalManifest')
            $r.exitCode | Should -Not -Be 0
            $r.joined | Should -Match 'protected location'
            Test-Path $probe | Should -BeFalse
        } finally {
            Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
        }
    }

    It 'dry-run text abbreviates HOME as ~ instead of absolute profile paths (H7)' {
        $root = New-DiscoverFixture
        try {
            $r = Invoke-Discover @('-Manifest', (Join-Path $root 'x.json'), '-Discover', '-DiscoverRoot', $root, '-DryRun')
            $r.exitCode | Should -Be 0
            $r.joined | Should -Match '~'
            $r.joined | Should -Not -Match ([regex]::Escape($HOME))
        } finally {
            Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
        }
    }
}

Describe 'projects.json.example — template with the real schema' {
    It 'is valid JSON with version/chainRoot/defaultMode and path+defaultAgent entries' {
        $example = Join-Path $repoRoot 'projects.json.example'
        Test-Path $example | Should -BeTrue
        $ex = Get-Content $example -Raw | ConvertFrom-Json -ErrorAction Stop
        $ex.version | Should -Be 1
        $ex.chainRoot | Should -Be '.'
        $ex.defaultMode | Should -Be 'chain-wins'
        $ex.projects.Count | Should -BeGreaterOrEqual 2
        foreach ($p in $ex.projects) {
            $p.path | Should -Not -BeNullOrEmpty
            $p.defaultAgent | Should -Not -BeNullOrEmpty
        }
        # No stale-schema fields (the old doc claimed name+mode per project).
        # PSObject.Properties (StrictMode-safe: missing props throw under Latest).
        $stale = @($ex.projects | Where-Object {
            ($_.PSObject.Properties.Name -contains 'name') -or
            ($_.PSObject.Properties.Name -contains 'mode')
        })
        $stale.Count | Should -Be 0
    }
}
