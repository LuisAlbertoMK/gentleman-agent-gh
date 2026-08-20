# mini-orchestrator — Reference Materials

> **Externalized from** .agents/skills/mini-orchestrator/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains examples and testing detail.

## Examples
"mini-orchestrator: audit security + apply fixes, max 6 iterations" → `babyagi-loop.ps1 -InitialTask "security audit" -MaxIterations 6` → T1→security-sub (fire-and-forget) → New-TasksFromResult → Sort-TaskQueue → Invoke-TaskAsync → convergence → monitor polls 15s until stable/300s.

## Testing
`Invoke-Pester tests\babyagi-loop.Tests.ps1` → 9/9; `tests\post-delegation-async.Tests.ps1` → 5/5; Async smoke: `post-delegation-check.ps1 -Async` → immediate return; `(Get-Content HEAD.async-result.json | ConvertFrom-Json).passed`.

## Async handoff (fire-and-forget)
```powershell
scripts\post-delegation-check.ps1 -BaseRef HEAD -AllowedPaths "src/*" -Async
# returns immediately; writes {BaseRef}.async-result.json
$r = Get-Content HEAD.async-result.json -Raw | ConvertFrom-Json
if (-not $r.passed) { # FAIL — review before proceeding }
```
`monitor-subagent.ps1` polls (15s) check-subagent-output + validate-write-scope; writes when git stable (2 identical polls) or 300s.