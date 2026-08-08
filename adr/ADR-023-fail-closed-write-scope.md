# ADR-023: Fail-Closed Write-Scope Enforcement

## Status
Accepted — 2026-08-08

## Context
`post-delegation-check.ps1` accepted an optional `-AllowedPaths` parameter.
When omitted, the write-scope check returned `passed = $true` with detail
"no AllowedPaths specified (skipped)" — a silent pass that defeated the
entire purpose of the scope validation.

This violated the v3 Perm-4 principle: every delegation must prove its
write scope before the output is trusted.

## Decision
Changed line 147 from:
```powershell
$results.checks += [PSCustomObject]@{ name = "write_scope"; passed = $true; detail = "no AllowedPaths specified (skipped)" }
```
to:
```powershell
$results.checks += [PSCustomObject]@{ name = "write_scope"; passed = $false; detail = "FAIL-CLOSED: AllowedPaths not provided — write-scope mandatory for all subagent delegations" }
$results.passed = $false
```

The orchestrator MUST now pass `-AllowedPaths` for every delegation, or
the post-delegation check fails (exit code 1).

## Consequences
- **Before**: Omitting `-AllowedPaths` → check passes silently → scope violations possible
- **After**: Omitting `-AllowedPaths` → check fails with explicit error → orchestrator must specify scope
- Existing callers that omit `-AllowedPaths` will now get a clear failure instead of a false positive

## Validation
- `post-delegation-check.Tests.ps1`: 2/2 PASS
- Manual: `post-delegation-check.ps1 -BaseRef HEAD -Quiet` → exit 1 (fail-closed)
- Manual: `post-delegation-check.ps1 -BaseRef HEAD -AllowedPaths "scripts/lib/*"` → runs scope check
