#requires -Version 7
<#
.SYNOPSIS
  E2E probe for the 4 subagent types I route via Task():
    gentleman-implementer-sub-auto, gentleman-deep-sub-auto,
    gentleman-quick-sub-auto, gentleman-codex-sub-auto.
  Read-only: parses global opencode.json; asserts the 4 subagents are
  registered under [agent] with non-empty description/model/mode/prompt.
  (Subagents are global config, not repo artifacts — AGENTS.md is persona-only.)
  Data via BeforeAll + $script: — the Pester 6 It-scope-safe pattern.
  Run: Invoke-Pester scripts/tests/subagent-e2e.Tests.ps1
#>

Set-StrictMode -Version Latest

Describe 'E2E: Subagent Routing (4 agents I use)' {
    BeforeAll {
        $script:proj = (git rev-parse --show-toplevel 2>$null); if (-not $script:proj) { $script:proj = $PWD.Path }
        $script:cfg  = 'C:\Users\MK\.config\opencode\opencode.json'
        if (-not (Test-Path $script:cfg)) { throw "global opencode.json not found: $script:cfg" }
        $script:json = Get-Content $script:cfg -Raw | ConvertFrom-Json -ErrorAction Stop
        $script:used = @('gentleman-implementer-sub-auto','gentleman-deep-sub-auto',
                         'gentleman-quick-sub-auto','gentleman-codex-sub-auto')
    }

    It 'global opencode.json registers all 4 used subagents under [agent]' {
        foreach ($a in $script:used) {
            ($null -ne $script:json.agent.$a) | Should -BeTrue -Because "$a not registered under [agent] in global opencode.json"
        }
    }

    It 'each subagent has non-empty description + model + mode + prompt' {
        foreach ($a in $script:used) {
            $s = $script:json.agent.$a
            ($s.description -and $s.description -ne '') | Should -BeTrue -Because "$a.description empty"
            ($s.model -and $s.model -ne '')              | Should -BeTrue -Because "$a.model empty"
            ($s.mode -and $s.mode -ne '')                | Should -BeTrue -Because "$a.mode empty"
            ($s.prompt -and $s.prompt -ne '')            | Should -BeTrue -Because "$a.prompt empty"
        }
    }
}
