# ADR-038: PSScriptAnalyzer CI Integration + Test Coverage Gate

**Status**: Accepted  
**Date**: 2026-08-19  
**Deciders**: gentleman-agent-gh team  
**Technical Story**: PowerShell quality improvements — C5 (PSSA CI + Coverage)

## Context

The repository has:
- 100+ PowerShell scripts in `scripts/`
- 60+ Pester test files in `scripts/tests/` and `tests/`
- Existing CI workflows (`.github/workflows/ci.yml`, `quality-gate.yml`)
- PSScriptAnalyzer already runs in CI but only for security/correctness rules
- No enforced test coverage gate for production scripts

## Decision

### 1. PSScriptAnalyzer Configuration File
Created `PSScriptAnalyzerSettings.psd1` with:
- **Included rules**: Security (invoke-expression, plaintext passwords), Correctness (approved verbs, ShouldProcess), Best practices (unused params, empty catch blocks)
- **Excluded rules**: Style rules too noisy for this codebase (positional parameters, whitespace, global vars)
- **Severity mapping**: Errors for security, Warnings for best practices, Information for style
- **File exclusions**: Test files, pssa-gate.ps1, .opencode/, node_modules/

### 2. CI Pipeline Enhancement (`.github/workflows/ci.yml`)
Added `coverage-gate` job that:
- Runs after `tests` job completes
- Executes `Coverage.ps1` with `-Strict -MinimumCoverage 80` for `scripts/` (production code)
- Excludes known-flaky test suites (e2e, Integration, session-checkpoint, etc.)
- Publishes JaCoCo XML and JSON summary as artifacts
- **Blocks merge** if coverage < 80% for production scripts

### 3. Coverage Configuration
The `Coverage.ps1` script (existing) measures:
- Line coverage for `.ps1` files under `scripts/` (excluding `scripts/tests/`)
- Function coverage
- Branch coverage (where applicable)
- Generates JaCoCo XML for CI integration

### Coverage Thresholds

| Scope | Minimum | Enforcement |
|-------|---------|-------------|
| `scripts/` (production) | 80% | **Blocking** (fails CI) |
| `scripts/lib/` (shared libs) | 80% | Blocking |
| `scripts/tests/` | N/A | Excluded (test code) |
| `tests/` (repo-level) | N/A | Not enforced (legacy) |

## Consequences

### Positive
- Enforced code quality baseline via PSSA (no errors allowed)
- Measurable test coverage for production scripts
- Prevents regression in test coverage
- Artifacts provide visibility into coverage trends
- Configuration file makes rules explicit and version-controlled

### Negative
- CI pipeline takes longer (additional coverage job)
- Initial coverage may be below 80% requiring test investment
- Exclusion list requires maintenance as test suite evolves

### Neutral
- Existing `pssa-lint` job enhanced (now uses settings file, includes best practices)
- `quality-gate.yml` unchanged (runs pre-commit hooks including pssa-gate)
- No changes to test execution logic

## Validation

- PSScriptAnalyzer on all `scripts/*.ps1`: 0 errors (warnings allowed)
- Pester tests: 122 passed, 3 pre-existing failures (unrelated)
- Coverage job: Runs and reports metrics (threshold enforcement active)

## Related

- ADR-037: CmdletBinding/ShouldProcess
- C5 task: PSSA CI + Coverage
- mejora-log.md: C4+C5 entry
- `PSScriptAnalyzerSettings.psd1`: Rule configuration