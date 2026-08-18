#requires -Version 7
# Fixture for adversarial-review tests — intentionally contains a blocked
# pattern (Invoke-Expression) so the breaker emits a critical finding.
# This file is ONLY staged during the test run, never committed.

function Invoke-FixtureUnsafe {
    param([string]$Command)
    $script:result = Invoke-Expression $Command
    $script:result
}