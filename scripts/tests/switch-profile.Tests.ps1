#requires -Version 7
<#
.SYNOPSIS
    Pester tests for switch-profile.ps1 — hermetic (operates on temp copies).
.DESCRIPTION
    Tests DryRun, idempotency, backup naming, counts, and JSON validity.
    Never touches the real opencode.json.
#>
#Requires -Version 7

BeforeAll {
    $ScriptDir = Split-Path -Parent $PSScriptRoot
    $ProjectRoot = Split-Path -Parent $ScriptDir
    $SwitchScript = Join-Path $ScriptDir 'switch-profile.ps1'
    $GoProfilePath = Join-Path $ScriptDir 'opencode-configs' 'profile-go.json'
    $ZenProfilePath = Join-Path $ScriptDir 'opencode-configs' 'profile-zen.json'
    $RealOpencodeJson = Join-Path $ProjectRoot 'opencode.json'

    # Helper: create a temp copy of opencode.json for testing
    function New-TempOpencodeCopy {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "switch-profile-test-$(Get-Random)"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $tempJson = Join-Path $tempDir 'opencode.json'
        Copy-Item -LiteralPath $RealOpencodeJson -Destination $tempJson -Force
        # Create a fake scripts dir with profile JSONs
        $tempScripts = Join-Path $tempDir 'scripts' 'opencode-configs'
        New-Item -ItemType Directory -Path $tempScripts -Force | Out-Null
        Copy-Item -LiteralPath $GoProfilePath -Destination (Join-Path $tempScripts 'profile-go.json') -Force
        Copy-Item -LiteralPath $ZenProfilePath -Destination (Join-Path $tempScripts 'profile-zen.json') -Force

        # Hermetic baseline: normalize the fixture to ZEN deterministically.
        # The live repo may be GO when the suite runs (pre-commit hook / workflow);
        # tests must never depend on the real profile state. Uses -ProjectRoot so
        # no $env:GENTLEMAN_AGENT_ROOT is mutated (process-global, racy in parallel).
        & $SwitchScript -ProjectRoot $tempDir -Profile zen -Force -Quiet
        # Remove normalization artifacts so backup/marker assertions start clean
        Get-ChildItem -Path $tempDir -Filter 'opencode.json.bak-zen-*' -ErrorAction SilentlyContinue | Remove-Item -Force
        Remove-Item -LiteralPath (Join-Path $tempDir '.opencode-profile') -ErrorAction SilentlyContinue
        return $tempDir
    }

    # Helper: count zen-free agents in opencode.json
    function Get-ZenFreeCount {
        param([string]$Path)
        $config = Get-Content $Path -Raw | ConvertFrom-Json
        $agentKeys = @($config.agent.PSObject.Properties.Name)
        $subagentKeys = $agentKeys | Where-Object { $_ -match '-sub(-auto)?$' }
        return ($subagentKeys | Where-Object {
            $m = $config.agent.$_.model
            $m -and $m -match 'contributor-free$'
        }).Count
    }

    # Helper: count contributor (non-free) subagents
    function Get-ContributorSubCount {
        param([string]$Path)
        $config = Get-Content $Path -Raw | ConvertFrom-Json
        $agentKeys = @($config.agent.PSObject.Properties.Name)
        $subagentKeys = $agentKeys | Where-Object { $_ -match '-sub(-auto)?$' }
        return ($subagentKeys | Where-Object {
            $m = $config.agent.$_.model
            $m -and $m -match 'muse-spark-1\.3-contributor$'
        }).Count
    }
}

Describe 'switch-profile.ps1' {

    Context 'Profile overlay files' {
        It 'profile-go.json exists and is valid JSON' {
            $goProfile = Get-Content $GoProfilePath -Raw | ConvertFrom-Json
            $goProfile.mapping | Should -Not -BeNullOrEmpty
            @($goProfile.mapping.PSObject.Properties.Name).Count | Should -Be 19
        }

        It 'profile-zen.json exists and is valid JSON' {
            $zenProfile = Get-Content $ZenProfilePath -Raw | ConvertFrom-Json
            $zenProfile.mapping | Should -Not -BeNullOrEmpty
            @($zenProfile.mapping.PSObject.Properties.Name).Count | Should -Be 19
        }
    }

    Context 'Status mode' {
        It '-Status returns without error' {
            { & $SwitchScript -ProjectRoot $ProjectRoot -Status } | Should -Not -Throw
        }

        It '-Status -Json returns valid JSON' {
            $output = & $SwitchScript -ProjectRoot $ProjectRoot -Status -Json
            { $output | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    Context 'DryRun mode' {
        It '-Profile go -DryRun does NOT modify opencode.json' {
            $tempDir = New-TempOpencodeCopy
            try {
                $before = Get-Content (Join-Path $tempDir 'opencode.json') -Raw
                & $SwitchScript -ProjectRoot $tempDir -Profile go -DryRun -Quiet
                $after = Get-Content (Join-Path $tempDir 'opencode.json') -Raw
                $before | Should -Be $after
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }

        It '-Profile zen -DryRun does NOT modify opencode.json' {
            $tempDir = New-TempOpencodeCopy
            try {
                $before = Get-Content (Join-Path $tempDir 'opencode.json') -Raw
                & $SwitchScript -ProjectRoot $tempDir -Profile zen -DryRun -Quiet
                $after = Get-Content (Join-Path $tempDir 'opencode.json') -Raw
                $before | Should -Be $after
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }

        It '-Profile go -DryRun -Json returns correct structure' {
            $tempDir = New-TempOpencodeCopy
            try {
                $output = & $SwitchScript -ProjectRoot $tempDir -Profile go -DryRun -Json | ConvertFrom-Json
                $output.dry_run | Should -Be $true
                $output.profile | Should -Be 'go'
                $output.changed | Should -Not -BeNullOrEmpty
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Apply mode — Go profile' {
        It 'applies Go profile and persists 19 model overrides to minified JSON' {
            $tempDir = New-TempOpencodeCopy
            try {
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                $configPath = Join-Path $tempDir 'opencode.json'
                $config = Get-Content $configPath -Raw | ConvertFrom-Json
                # Correct behavior: scoped raw-text replacement writes the go models
                # even though opencode.json is minified (single line)
                $config.agent.'gentleman-deep-sub'.model | Should -Be 'opencode-go/muse-spark-1.3-contributor'
                $config.agent.'gentleman-codex-sub'.model | Should -Be 'opencode-go/muse-spark-1.3-contributor'
                Get-ContributorSubCount -Path $configPath | Should -Be 19
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }

        It 'creates backup with profile-timestamp naming' {
            $tempDir = New-TempOpencodeCopy
            try {
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                $backups = @(Get-ChildItem -Path $tempDir -Filter 'opencode.json.bak-go-*')
                $backups.Count | Should -BeGreaterOrEqual 1
                $backups[0].Name | Should -Match 'opencode\.json\.bak-go-\d{8}-\d{6}-\d{3}'
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Apply mode — Zen profile' {
        It 'applies Zen profile after Go and sets subagents back to free' {
            $tempDir = New-TempOpencodeCopy
            try {
                # Start from Go state so Zen apply actually persists changes
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                & $SwitchScript -ProjectRoot $tempDir -Profile zen -Force -Quiet
                $configPath = Join-Path $tempDir 'opencode.json'
                $zenCount = Get-ZenFreeCount -Path $configPath
                $zenCount | Should -BeGreaterOrEqual 19
                $config = Get-Content $configPath -Raw | ConvertFrom-Json
                $config.agent.'gentleman-deep-sub'.model | Should -Be 'opencode/muse-spark-1.3-contributor-free'
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }

        It 'does not create backup when already on zen (0 changes)' {
            $tempDir = New-TempOpencodeCopy
            try {
                & $SwitchScript -ProjectRoot $tempDir -Profile zen -Force -Quiet
                $backups = @(Get-ChildItem -Path $tempDir -Filter 'opencode.json.bak-zen-*')
                $backups.Count | Should -Be 0
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Idempotency' {
        It 'skips when already on target profile' {
            $tempDir = New-TempOpencodeCopy
            try {
                # Apply Go first
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                # Apply Go again — should be no-op
                $output = & $SwitchScript -ProjectRoot $tempDir -Profile go -Json | ConvertFrom-Json
                $output.message | Should -Match 'Already on profile'
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }

        It '-Force with 0 changes reports no changes needed and creates no backup' {
            $tempDir = New-TempOpencodeCopy
            try {
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                # Second -Force: already applied, 0 changes — no backup, no write
                $output = & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Json | ConvertFrom-Json
                $output.message | Should -Match 'no changes needed'
                $output.changed | Should -BeNullOrEmpty
                $output.backup | Should -BeNullOrEmpty
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }

        It 'second consecutive -Force apply with 0 changes creates no backup and keeps content intact' {
            $tempDir = New-TempOpencodeCopy
            try {
                # First apply — creates backup + writes 19 overrides
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                $backupsAfterFirst = @(Get-ChildItem -Path $tempDir -Filter 'opencode.json.bak-*')
                $contentAfterFirst = Get-Content (Join-Path $tempDir 'opencode.json') -Raw

                # Second apply — real no-op (0 changes, no new backup)
                $output = & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Json | ConvertFrom-Json
                $backupsAfterSecond = @(Get-ChildItem -Path $tempDir -Filter 'opencode.json.bak-*')
                $contentAfterSecond = Get-Content (Join-Path $tempDir 'opencode.json') -Raw

                $backupsAfterSecond.Count | Should -Be $backupsAfterFirst.Count
                $contentAfterSecond | Should -Be $contentAfterFirst
                $output.message | Should -Match 'no changes needed'
                $output.changed | Should -BeNullOrEmpty
                $output.backup | Should -BeNullOrEmpty
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'JSON validity post-apply' {
        It 'opencode.json remains valid JSON after Go apply' {
            $tempDir = New-TempOpencodeCopy
            try {
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                $configPath = Join-Path $tempDir 'opencode.json'
                { Get-Content $configPath -Raw | ConvertFrom-Json } | Should -Not -Throw
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }

        It 'opencode.json remains valid JSON after Zen apply' {
            $tempDir = New-TempOpencodeCopy
            try {
                & $SwitchScript -ProjectRoot $tempDir -Profile zen -Force -Quiet
                $configPath = Join-Path $tempDir 'opencode.json'
                { Get-Content $configPath -Raw | ConvertFrom-Json } | Should -Not -Throw
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Counts per profile' {
        It 'Go profile applies to exactly 19 subagent entries' {
            $tempDir = New-TempOpencodeCopy
            try {
                $output = & $SwitchScript -ProjectRoot $tempDir -Profile go -DryRun -Json | ConvertFrom-Json
                $output.changed.Count | Should -Be 19
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }

        It 'Zen profile applies to 0 subagent entries when already zen' {
            $tempDir = New-TempOpencodeCopy
            try {
                $output = & $SwitchScript -ProjectRoot $tempDir -Profile zen -DryRun -Json | ConvertFrom-Json
                $output.changed.Count | Should -Be 0
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Sidecar marker' {
        It 'writes .opencode-profile after apply' {
            $tempDir = New-TempOpencodeCopy
            try {
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                $marker = Join-Path $tempDir '.opencode-profile'
                Test-Path $marker | Should -Be $true
                (Get-Content $marker -Raw).Trim() | Should -Be 'go'
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Round-trip Go→Zen→Go byte-identical' {
        It 'go→zen→go round-trip restores byte-identical content at each step' {
            $tempDir = New-TempOpencodeCopy
            try {
                $opencodePath = Join-Path $tempDir 'opencode.json'

                # Baseline: fixture copy is normalized to zen state
                $baseline = Get-Content $opencodePath -Raw
                $baselineHash = (Get-FileHash -LiteralPath $opencodePath -Algorithm SHA256).Hash

                # Apply GO — persists 19 overrides to contributor models
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                $afterGo = Get-Content $opencodePath -Raw
                $afterGoHash = (Get-FileHash -LiteralPath $opencodePath -Algorithm SHA256).Hash
                $afterGo | Should -Not -Be $baseline
                $goConfig = $afterGo | ConvertFrom-Json
                $goConfig.agent.'gentleman-deep-sub'.model | Should -Be 'opencode-go/muse-spark-1.3-contributor'

                # Go → Zen — restores free models byte-identical to the zen baseline
                & $SwitchScript -ProjectRoot $tempDir -Profile zen -Force -Quiet
                $afterZen = Get-Content $opencodePath -Raw
                $afterZen | Should -Be $baseline

                # Zen → Go — restores the go state byte-identical
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                $afterGoHash2 = (Get-FileHash -LiteralPath $opencodePath -Algorithm SHA256).Hash
                $afterGoHash2 | Should -Be $afterGoHash
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Allowlist validation — rejects manipulated overlay' {
        It 'rejects overlay with unknown model — no writes, no backups' {
            $tempDir = New-TempOpencodeCopy
            try {
                $opencodePath = Join-Path $tempDir 'opencode.json'
                $originalHash = (Get-FileHash -LiteralPath $opencodePath -Algorithm SHA256).Hash
                $beforeBackups = @(Get-ChildItem -Path $tempDir -Filter 'opencode.json.bak-*').Count

                # Tamper profile-go.json: replace model with unknown value
                $goProfilePath = Join-Path $tempDir 'scripts' 'opencode-configs' 'profile-go.json'
                $goProfile = Get-Content $goProfilePath -Raw | ConvertFrom-Json
                $goProfile.mapping.'gentleman-deep-sub' = 'opencode-go/unknown-model'
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($goProfilePath, ($goProfile | ConvertTo-Json -Depth 10).Replace("`r`n", "`n"), $utf8NoBom)

                { & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet -ErrorAction Stop } | Should -Throw '*ALLOWLIST REJECTED*'

                # Verify nothing changed
                $afterHash = (Get-FileHash -LiteralPath $opencodePath -Algorithm SHA256).Hash
                $afterHash | Should -Be $originalHash
                $afterBackups = @(Get-ChildItem -Path $tempDir -Filter 'opencode.json.bak-*').Count
                $afterBackups | Should -Be $beforeBackups
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }

        It 'rejects overlay with invalid agent key pattern — no writes, no backups' {
            $tempDir = New-TempOpencodeCopy
            try {
                $opencodePath = Join-Path $tempDir 'opencode.json'
                $originalHash = (Get-FileHash -LiteralPath $opencodePath -Algorithm SHA256).Hash
                $beforeBackups = @(Get-ChildItem -Path $tempDir -Filter 'opencode.json.bak-*').Count

                # Tamper profile-go.json: add key with invalid pattern
                $goProfilePath = Join-Path $tempDir 'scripts' 'opencode-configs' 'profile-go.json'
                $goProfile = Get-Content $goProfilePath -Raw | ConvertFrom-Json
                $goProfile.mapping | Add-Member -NotePropertyName 'invalid-key' -NotePropertyValue 'opencode-go/muse-spark-1.3-contributor'
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($goProfilePath, ($goProfile | ConvertTo-Json -Depth 10).Replace("`r`n", "`n"), $utf8NoBom)

                { & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet -ErrorAction Stop } | Should -Throw '*ALLOWLIST REJECTED*'

                # Verify nothing changed
                $afterHash = (Get-FileHash -LiteralPath $opencodePath -Algorithm SHA256).Hash
                $afterHash | Should -Be $originalHash
                $afterBackups = @(Get-ChildItem -Path $tempDir -Filter 'opencode.json.bak-*').Count
                $afterBackups | Should -Be $beforeBackups
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'No CRLF introduced' {
        It 'opencode.json after apply has no CRLF line endings' {
            $tempDir = New-TempOpencodeCopy
            try {
                & $SwitchScript -ProjectRoot $tempDir -Profile go -Force -Quiet
                $configPath = Join-Path $tempDir 'opencode.json'
                $raw = [System.IO.File]::ReadAllText($configPath)
                $raw.Contains("`r`n") | Should -Be $false
            } finally {
                Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
            }
        }
    }
}
