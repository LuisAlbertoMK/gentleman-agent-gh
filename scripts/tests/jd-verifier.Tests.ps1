BeforeAll {
    $script:VerifierPath = Join-Path $PSScriptRoot '../jd-verifier.ps1'
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
    $env:PESTER_TEST = '1'

    function Invoke-Verifier {
        param([string[]]$VerifierArgs)
        $outFile = [IO.Path]::GetTempFileName()
        $errFile = [IO.Path]::GetTempFileName()
        $argList = @('-NoProfile','-File',$script:VerifierPath) + $VerifierArgs
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList $argList -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        $stdout = Get-Content -Raw -LiteralPath $outFile -ErrorAction SilentlyContinue
        if ($null -eq $stdout) { $stdout = '' }
        $stderr = Get-Content -Raw -LiteralPath $errFile -ErrorAction SilentlyContinue
        if ($null -eq $stderr) { $stderr = '' }
        Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue
        return @{ Stdout = $stdout.Trim(); Stderr = $stderr.Trim(); ExitCode = $proc.ExitCode }
    }

    function New-StubPs1 {
        param([string]$Path, [string]$JsonContent)
        $stub = @"
`$json = '$JsonContent'
Write-Output `$json
"@
        Set-Content -LiteralPath $Path -Value $stub -Encoding utf8
    }
}

Describe 'jd-verifier.ps1' {

    Context 'missing bin/ -> ESCALATE with warn, exit 1' {
        It 'escalates when bin/fast.exe missing' {
            $tmp = Join-Path ([IO.Path]::GetTempPath()) ("jd-test-missing-" + [Guid]::NewGuid())
            New-Item -ItemType Directory -Path $tmp -Force | Out-Null
            try {
                $orig = $env:JD_FAST_EXE
                $env:JD_FAST_EXE = $null
                $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-FastPath','-RepoRoot',$tmp)
                $res.Stdout | Should -Match 'ESCALATE dual-judge'
                $res.Stdout | Should -Match 'SELF-CONSISTENCY'
                $res.Stderr | Should -Match 'WARN: bin/fast.exe not found'
                $res.ExitCode | Should -Be 1
            } finally {
                $env:JD_FAST_EXE = $orig
                Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'fake fast.exe stub via JD_FAST_EXE -> VERIFY-OK' {
        It 'returns VERIFY-OK when stub passes within budget' {
            $tmp = [IO.Path]::GetTempFileName() + '.ps1'
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
            $stubPath = $tmp
            New-StubPs1 -Path $stubPath -JsonContent '{"passed":true,"elapsedMs":97}'
            $orig = $env:JD_FAST_EXE
            try {
                $env:JD_FAST_EXE = $stubPath
                $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-FastPath')
                $res.Stdout | Should -Match 'VERIFY-OK mechanical \(97ms\)'
                $res.Stdout | Should -Match 'SELF-CONSISTENCY'
                $res.ExitCode | Should -Be 0
            } finally {
                $env:JD_FAST_EXE = $orig
                Remove-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
            }
        }

        It 'escalates when stub fails (passed false)' {
            $stubPath = [IO.Path]::GetTempFileName() + '.ps1'
            Remove-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
            New-StubPs1 -Path $stubPath -JsonContent '{"passed":false,"elapsedMs":95}'
            $orig = $env:JD_FAST_EXE
            try {
                $env:JD_FAST_EXE = $stubPath
                $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-FastPath')
                $res.Stdout | Should -Match 'ESCALATE dual-judge'
                $res.ExitCode | Should -Be 1
            } finally {
                $env:JD_FAST_EXE = $orig
                Remove-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
            }
        }

        It 'escalates when stub exceeds budget (elapsedMs >162)' {
            $stubPath = [IO.Path]::GetTempFileName() + '.ps1'
            Remove-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
            New-StubPs1 -Path $stubPath -JsonContent '{"passed":true,"elapsedMs":200}'
            $orig = $env:JD_FAST_EXE
            try {
                $env:JD_FAST_EXE = $stubPath
                $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-FastPath')
                $res.Stdout | Should -Match 'ESCALATE dual-judge'
                $res.ExitCode | Should -Be 1
            } finally {
                $env:JD_FAST_EXE = $orig
                Remove-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'rounds cap' {
        It 'exits 2 and shows ASK-USER when Rounds >2' {
            $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-Rounds','3')
            $res.Stdout | Should -Match 'ASK-USER \(Reflexion cap\)'
            $res.ExitCode | Should -Be 2
        }

        It 'does not cap when Rounds <=2' {
            $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-Rounds','2')
            $res.ExitCode | Should -Not -Be 2
            $res.Stdout | Should -Not -Match 'ASK-USER'
        }

        It 'textual -Rounds 3 exits 2' {
            $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-Rounds','3')
            $res.ExitCode | Should -Be 2
            $res.Stdout | Should -Match 'ASK-USER'
        }
    }

    Context 'RepeatFinding' {
        It 'outputs constitutional line when switch present' {
            $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-RepeatFinding')
            $res.Stdout | Should -Match 'CONSTITUTIONAL.*register via immune-system'
            $res.Stdout | Should -Match 'SELF-CONSISTENCY'
            $res.ExitCode | Should -Be 0
        }

        It 'does not output constitutional when absent' {
            $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA')
            $res.Stdout | Should -Not -Match 'CONSTITUTIONAL'
        }

        It '-RepeatFinding -Json has constitutional true' {
            $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-RepeatFinding','-Json')
            $json = $res.Stdout | ConvertFrom-Json -ErrorAction Stop
            $json.constitutional | Should -BeTrue
        }

        It '-Json without RepeatFinding has constitutional false' {
            $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-Json')
            $json = $res.Stdout | ConvertFrom-Json -ErrorAction Stop
            $json.constitutional | Should -BeFalse
        }
    }

    Context 'self-consistency always present (textual mode)' {
        It 'contains self-consistency line' {
            $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA')
            $res.Stdout | Should -Match 'SELF-CONSISTENCY: profiles A/B = majority-of-2'
        }
    }

    Context '-Json schema' {
        It 'emits valid JSON with all required keys' {
            $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-Json')
            $json = $res.Stdout | ConvertFrom-Json -ErrorAction Stop
            $json.verifier | Should -Be 'jd-verifier'
            $json.zone | Should -Be 'ROJA'
            $null -ne $json.fastPath | Should -BeTrue
            $null -ne $json.rounds | Should -BeTrue
            $null -ne $json.PSObject.Properties['constitutional'] | Should -BeTrue
            $null -ne $json.PSObject.Properties['timestamp'] | Should -BeTrue
            $json.fastPath.ran | Should -BeFalse
            $json.fastPath.decision | Should -Be 'NOT_RUN'
            $json.rounds.value | Should -Be 0
            $json.rounds.capped | Should -BeFalse
            $ts = if ($json.timestamp -is [DateTime]) { $json.timestamp.ToString('o') } else { "$($json.timestamp)" }
            $ts | Should -Match '^\d{4}-\d{2}-\d{2}T'
        }

        It 'json with AMARILLA zone and FastPath missing -> ESCALATE' {
            $tmp = Join-Path ([IO.Path]::GetTempPath()) ("jd-test-json-" + [Guid]::NewGuid())
            New-Item -ItemType Directory -Path $tmp -Force | Out-Null
            $orig = $env:JD_FAST_EXE
            try {
                $env:JD_FAST_EXE = $null
                $res = Invoke-Verifier -VerifierArgs @('-Zone','AMARILLA','-FastPath','-Json','-RepoRoot',$tmp)
                $json = $res.Stdout | ConvertFrom-Json -ErrorAction Stop
                $json.zone | Should -Be 'AMARILLA'
                $json.fastPath.ran | Should -BeTrue
                $json.fastPath.decision | Should -Be 'ESCALATE'
                $json.fastPath.passed | Should -BeFalse
            } finally {
                $env:JD_FAST_EXE = $orig
                Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
            }
        }

        It 'json with FastPath VERIFY-OK stub' {
            $stubPath = [IO.Path]::GetTempFileName() + '.ps1'
            Remove-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
            New-StubPs1 -Path $stubPath -JsonContent '{"passed":true,"elapsedMs":88}'
            $orig = $env:JD_FAST_EXE
            try {
                $env:JD_FAST_EXE = $stubPath
                $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-FastPath','-Rounds','1','-RepeatFinding','-Json')
                $json = $res.Stdout | ConvertFrom-Json -ErrorAction Stop
                $json.verifier | Should -Be 'jd-verifier'
                $json.fastPath.ran | Should -BeTrue
                $json.fastPath.passed | Should -BeTrue
                $json.fastPath.elapsedMs | Should -Be 88
                $json.fastPath.decision | Should -Be 'VERIFY-OK'
                $json.rounds.value | Should -Be 1
                $json.rounds.capped | Should -BeFalse
                $json.constitutional | Should -BeTrue
            } finally {
                $env:JD_FAST_EXE = $orig
                Remove-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
            }
        }

        It 'json rounds capped' {
            $res = Invoke-Verifier -VerifierArgs @('-Zone','ROJA','-Rounds','3','-Json')
            $json = $res.Stdout | ConvertFrom-Json -ErrorAction Stop
            $json.rounds.value | Should -Be 3
            $json.rounds.capped | Should -BeTrue
            $res.ExitCode | Should -Be 2
        }
    }

    Context 'AMARILLA textual VERIFY-OK path' {
        It 'AMARILLA -FastPath textual returns VERIFY-OK with stub' {
            $stubPath = [IO.Path]::GetTempFileName() + '.ps1'
            Remove-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
            New-StubPs1 -Path $stubPath -JsonContent '{"passed":true,"elapsedMs":55}'
            $orig = $env:JD_FAST_EXE
            try {
                $env:JD_FAST_EXE = $stubPath
                $res = Invoke-Verifier -VerifierArgs @('-Zone','AMARILLA','-FastPath')
                $res.Stdout | Should -Match 'VERIFY-OK mechanical \(55ms\)'
                $res.Stdout | Should -Match 'SELF-CONSISTENCY'
                $res.ExitCode | Should -Be 0
                $res.Stderr | Should -Be ''
            } finally {
                $env:JD_FAST_EXE = $orig
                Remove-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'PESTER_TEST isolation — no repo mutation' {
        It 'does not modify tracked files' {
            $before = git -C $script:RepoRoot status --porcelain
            $null = Invoke-Verifier -VerifierArgs @('-Zone','ROJA')
            $after = git -C $script:RepoRoot status --porcelain
            $before | Should -Be $after
        }
    }
}
