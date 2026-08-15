# Subagent Result Quality Improvements (C4d + Budget Enforcement + CI)

## Problem

`!analisis` (analysis-mode) and `!automejora` (self-improvement) subagents
produce 4-field return contract output (Decision Taken | Files Changed |
Key Findings | Nuance), but this was **never validated** — the
`check-subagent-output.ps1 -AgentOutput` validation existed but the wiring
was dead code in `post-delegation-check.ps1`.

Additionally, no budget enforcement (timeout/tool-call limits) or quality
scoring existed for subagent delegations.

## What Was Done

### C4d: Contract Validation Wiring

`scripts/post-delegation-check.ps1` — the `-SubagentOutput`/`-SubagentOutputFile`
parameters were already at HEAD (pre-existing wiring), confirmed working via
integration tests. The contract validation check (`contract_validation`) is now
included in the results JSON and stored in quality metrics.

### C7: Budget Enforcement

**NEW** `scripts/subagent-budget-guard.ps1` — budget enforcement wrapper:

| Action | Purpose |
|--------|---------|
| `poll` | Check if delegation exceeded `-TimeoutSeconds` (default 300s) |
| `enforce` | Run post-delegation-check + compute quality score (0-10) |

Quality score formula: passed (+4), files produced (+1), contract valid (+2),
zero failed checks (+2), within budget (+1).

### G5: Delegation Registry Extensions

`scripts/delegation-registry.ps1` — extended with:

- `-TimeoutSeconds` (default: 300), `-MaxToolCalls` (default: 25), `-SubagentOutputFile`
- `poll`: returns `budget_exceeded` based on elapsed time vs registered timeout
- `resolve`: forwards `-SubagentOutputFile` to post-delegation-check, stores quality
  metrics (`contract_valid`, `checks`, `duration_seconds`) in registry entry
- `report-toolcalls`: new action to update `quality.tool_calls_reported` after resolution

### Async Monitor Integration

`scripts/monitor-subagent.ps1` — added `-SubagentOutputFile` parameter. After git
status stabilility detection (2 consecutive identical snapshots), the monitor now
runs C4d contract validation via `check-subagent-output.ps1 -AgentOutput` and
includes `contract_valid` + `contract_detail` in the `async-result.json`.

### Test Coverage

**NEW** `scripts/tests/post-delegation-contract.Tests.ps1` — 8 tests:
- Syntax check
- Baseline JSON output
- Backward compat (no contract_validation when SubagentOutputFile omitted)
- Wiring (contract_validation present when provided)
- PASS for well-formed 4-field output
- FAIL for missing Nuance
- FAIL for empty Key Findings
- End-to-end with file-based transport
- Missing file handling (graceful warning)

**NEW** `scripts/tests/subagent-quality-e2e.Tests.ps1` — 5 tests:
- Full pipeline: register → poll → enforce → quality scoring
- Malformed output detection (missing Nuance)
- Timeout detection (poll flags `budget_exceeded`)
- Syntax validation for both new scripts

**FIXED** `scripts/tests/post-delegation-check.Tests.ps1` — restored modern
Pester 6 syntax (`Should -Be` instead of deprecated `Should Be`). Pre-existing
failure — tests were broken before this work began.

### Pre-existing Test Fix

`scripts/tests/post-delegation-check.Tests.ps1` was at HEAD using deprecated
Pester 6 syntax (`Should Be` without dashes). Restored to `Should -Be` pattern
that works with Pester 6.1.0.

## Verification

```
Tests Passed: 22, Failed: 0
  CONTRACT:    8/8  ✅
  E2E:         5/5  ✅
  PDC-REG:     2/2  ✅
  CSO-REG:     6/6  ✅
```

Run via: `pwsh -File scripts/tests/Coverage.ps1` (CI auto-discovers `*.Tests.ps1`)

## References

- `adr/ADR-019` — Automated post-delegation empty-output detection
- `adr/ADR-023` — Async delegation decision record
- `docs/mejoras/2026-08-08-gentleman-agent-gh-execution-report.md` — prior execution context
