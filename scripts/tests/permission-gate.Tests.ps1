#requires -Version 7
<#
.SYNOPSIS
    Tests for permission-gate classification — command classification per mode.
.DESCRIPTION
    Verifies that commands are correctly classified as allow/ask/deny
    in manual, semi, and auto modes.
    Runs IN-PROCESS: dot-sources scripts/lib/permission-gate-lib.ps1 once in
    BeforeAll and calls Get-CommandClass directly (no per-It script spawn).

    Run: Invoke-Pester .\scripts\tests\permission-gate.Tests.ps1
    Run quiet: Invoke-Pester .\scripts\tests\permission-gate.Tests.ps1 -- -Quiet
#>
param([switch]$Quiet)

BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\permission-gate-lib.ps1')

    function Invoke-Gate {
        param([string]$Command, [string]$Mode)
        $verdict = Get-CommandClass -cmd $Command -mode $Mode
        $rule = switch ($verdict) {
            'deny'  { 'Built-in security restriction' }
            'allow' { "Allowed in $Mode mode" }
            'ask'   { "Requires confirmation in $Mode mode" }
            'help'  { 'No command provided' }
        }
        [PSCustomObject]@{
            action  = 'permission-gate'
            command = $Command
            mode    = $Mode
            verdict = $verdict
            rule    = $rule
        }
    }
}

# ============================================================
# MANUAL MODE — everything asks (unless denied)
# ============================================================
Describe "Manual mode — default behaviour" {
    It "returns ask for git status [read]" {
        $r = Invoke-Gate -Command "git status" -Mode manual
        $r.verdict | Should -Be "ask"
    }
    It "returns ask for ls [read]" {
        $r = Invoke-Gate -Command "ls" -Mode manual
        $r.verdict | Should -Be "ask"
    }
    It "returns ask for cat file [read]" {
        $r = Invoke-Gate -Command "cat foo.txt" -Mode manual
        $r.verdict | Should -Be "ask"
    }
    It "returns deny for curl [network]" {
        $r = Invoke-Gate -Command "curl http://example.com" -Mode manual
        $r.verdict | Should -Be "deny"
    }
    It "returns deny for rm [destructive]" {
        $r = Invoke-Gate -Command "rm -rf node_modules" -Mode manual
        $r.verdict | Should -Be "deny"
    }
    It "returns deny for python [interpreter]" {
        $r = Invoke-Gate -Command "python script.py" -Mode manual
        $r.verdict | Should -Be "deny"
    }
}

# ============================================================
# SEMI MODE — safe commands auto-allow, writes ask
# ============================================================
Describe "Semi mode — allowlist" {
    It "ALLOWS git status [git read-only]" {
        $r = Invoke-Gate -Command "git status" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS git diff [git read-only]" {
        $r = Invoke-Gate -Command "git diff" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS git log --oneline -5 [git read-only]" {
        $r = Invoke-Gate -Command "git log --oneline -5" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS git branch [git read-only]" {
        $r = Invoke-Gate -Command "git branch" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS git stash list [git read-only]" {
        $r = Invoke-Gate -Command "git stash list" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS ls -la [filesystem]" {
        $r = Invoke-Gate -Command "ls -la" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS cat file.txt [read file]" {
        $r = Invoke-Gate -Command "cat file.txt" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS pwd [directory info]" {
        $r = Invoke-Gate -Command "pwd" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS grep pattern file [search]" {
        $r = Invoke-Gate -Command "grep 'foo' bar.txt" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS rg pattern [search]" {
        $r = Invoke-Gate -Command "rg 'TODO'" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS which git [query]" {
        $r = Invoke-Gate -Command "which git" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS npm test [build/test]" {
        $r = Invoke-Gate -Command "npm test" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS npm run build [build/test]" {
        $r = Invoke-Gate -Command "npm run build" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS npm ci [safe install from lockfile]" {
        $r = Invoke-Gate -Command "npm ci" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS pytest [test runner]" {
        $r = Invoke-Gate -Command "pytest tests/" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS go test [test runner]" {
        $r = Invoke-Gate -Command "go test ./..." -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS pip freeze [pip info]" {
        $r = Invoke-Gate -Command "pip freeze" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS pip list [pip info]" {
        $r = Invoke-Gate -Command "pip list" -Mode semi
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS pip show requests [pip info]" {
        $r = Invoke-Gate -Command "pip show requests" -Mode semi
        $r.verdict | Should -Be "allow"
    }
}

Describe "Semi mode — ask (not in allowlist)" {
    It "ASKS for git commit [write operation]" {
        $r = Invoke-Gate -Command "git commit -m 'fix'" -Mode semi
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for git push [write operation]" {
        $r = Invoke-Gate -Command "git push origin main" -Mode semi
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for mkdir [create dir]" {
        $r = Invoke-Gate -Command "mkdir newdir" -Mode semi
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for New-Item [create file]" {
        $r = Invoke-Gate -Command "New-Item -Path test.txt -ItemType File" -Mode semi
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for Set-Content [write file]" {
        $r = Invoke-Gate -Command "Set-Content -Path test.txt -Value 'hello'" -Mode semi
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for pip install [env change]" {
        $r = Invoke-Gate -Command "pip install requests" -Mode semi
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for npm install [env change]" {
        $r = Invoke-Gate -Command "npm install lodash" -Mode semi
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for npm uninstall [env change]" {
        $r = Invoke-Gate -Command "npm uninstall lodash" -Mode semi
        $r.verdict | Should -Be "ask"
    }
}

Describe "Semi mode — deny (all modes)" {
    It "DENIES curl [network]" {
        $r = Invoke-Gate -Command "curl http://evil.com" -Mode semi
        $r.verdict | Should -Be "deny"
    }
    It "DENIES ssh [network]" {
        $r = Invoke-Gate -Command "ssh user@host" -Mode semi
        $r.verdict | Should -Be "deny"
    }
    It "DENIES docker [network/system]" {
        $r = Invoke-Gate -Command "docker ps" -Mode semi
        $r.verdict | Should -Be "deny"
    }
    It "DENIES rm -rf [destructive]" {
        $r = Invoke-Gate -Command "rm -rf /tmp/data" -Mode semi
        $r.verdict | Should -Be "deny"
    }
    It "DENIES python [interpreter]" {
        $r = Invoke-Gate -Command "python -c 'print(1)'" -Mode semi
        $r.verdict | Should -Be "deny"
    }
    It "DENIES git push --force [forced push]" {
        $r = Invoke-Gate -Command "git push --force origin main" -Mode semi
        $r.verdict | Should -Be "deny"
    }
    It "DENIES git push -f [forced push shorthand]" {
        $r = Invoke-Gate -Command "git push -f origin main" -Mode semi
        $r.verdict | Should -Be "deny"
    }
}

# ============================================================
# AUTO MODE — everything allowed except push/deletes
# ============================================================
Describe "Auto mode — allow behaviour" {
    It "ALLOWS git status [read]" {
        $r = Invoke-Gate -Command "git status" -Mode auto
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS git commit [write]" {
        $r = Invoke-Gate -Command "git commit -m 'fix'" -Mode auto
        $r.verdict | Should -Be "allow"
    }
    It "ALLOWS mkdir [create dir]" {
        $r = Invoke-Gate -Command "mkdir newdir" -Mode auto
        $r.verdict | Should -Be "allow"
    }
}

Describe "Auto mode — ask (push + deletes)" {
    It "ASKS for git push [in auto mode]" {
        $r = Invoke-Gate -Command "git push origin main" -Mode auto
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for rm [destructive, user confirms in auto]" {
        $r = Invoke-Gate -Command "rm -rf /tmp" -Mode auto
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for Remove-Item [destructive, user confirms in auto]" {
        $r = Invoke-Gate -Command "Remove-Item -Recurse -Force C:\tmp\data" -Mode auto
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for git branch -D [branch deletion]" {
        $r = Invoke-Gate -Command "git branch -D old-feature" -Mode auto
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for git stash drop [stash deletion]" {
        $r = Invoke-Gate -Command "git stash drop" -Mode auto
        $r.verdict | Should -Be "ask"
    }
    It "ASKS for git reset --hard [destructive reset]" {
        $r = Invoke-Gate -Command "git reset --hard HEAD~2" -Mode auto
        $r.verdict | Should -Be "ask"
    }
}

Describe "Auto mode — deny (network + forced push)" {
    It "DENIES curl [network, even in auto]" {
        $r = Invoke-Gate -Command "curl http://example.com" -Mode auto
        $r.verdict | Should -Be "deny"
    }
    It "DENIES git push --force [forced push, even in auto]" {
        $r = Invoke-Gate -Command "git push --force origin main" -Mode auto
        $r.verdict | Should -Be "deny"
    }
}

# ============================================================
# Edge cases
# ============================================================
Describe "Edge cases" {
    It "returns help for empty command" {
        $r = Invoke-Gate -Command "" -Mode semi
        $r.verdict | Should -Be "help"
    }

    It "returns expected JSON fields" {
        $r = Invoke-Gate -Command "git status" -Mode semi
        $r.action | Should -Be "permission-gate"
        $r | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name } | Sort-Object
        $expectedFields = @('action', 'command', 'mode', 'verdict')
        $actualFields = ($r | Get-Member -MemberType NoteProperty).Name
        foreach ($f in $expectedFields) {
            $f -in $actualFields | Should -Be $true
        }
    }

    It "always returns a valid verdict for any command" {
        $r = Invoke-Gate -Command "obscure-command-that-should-ask" -Mode semi
        $r.verdict | Should -BeIn @("allow", "ask", "deny", "help")
    }
}
