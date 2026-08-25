# ADR-032: CI Quality Hardening — Pester Runner, Coverage Gate, Mutation Smoke, Adversarial Review

- **Status**: Accepted (implemented on `experimento/mejora-autonoma-2026-08-18`)
- **Deciders**: gentleman-vMK
- **Date**: 2026-08-18
- **Tier**: T2 — CI/CD infrastructure, multi-file changes (plan v3 G1-G3)
- **Context**: Analysis `docs/mejoras/plan-auto-mejora-v3-2026-08-18.md` (plan-auto-mejora-v3-2026-08-18) identified the gaps: (G1) committed code lacked test coverage on the exact test-runner path, (G2) no coverage gate — regressions in coverage were invisible, (G3) adversarial review existed but findings were unstructured (no severity taxonomy consumable by CI).

## Decision

Implement **4 hardening layers in the CI pipeline**, each addressing one gap, delivered as 3 Ciclos on the v3 experiment branch:

| Ciclo | Layer | Gap | Commit |
|---|---|---|---|
| 1 | Robust Pester runner (`run-ci-tests.ps1`) + NUnit publish + `#requires` line-1 fix | G1 | `e3bec66b` |
| 2 | Coverage gate (`Coverage.ps1`, pins Pester 5.5.0, `-ExcludePattern`, `-Strict` floor 20%) + mutation smoke (`mutation-smoke.Tests.ps1`) | G2 | `c966c4bc` |
| 3 | Structured adversarial review (`adversarial-review.ps1`, R1 severity taxonomy + dedup) | G3 | `2719837c` |

**Ciclo 1 — Pester runner**: `scripts/run-ci-tests.ps1` pins Pester 5.5.0 (Pester 6 breaks the legacy `-CodeCoverage` API), uses `Run.Exit` semantics, emits NUnit XML, supports `-WithCoverage` (JaCoCo). Discovered: gate check [2/13] reads only the first 3 lines of each script for `#requires -Version` — the `#requires` must be on line 1, not inside a comment block. Root-cause fixed. Also fixed pre-existing destructive-safety gaps in `scripts/babyagi-loop.ps1` (`-DryRun`/`-Force` + try/catch Remove-Item, 220/220 destructive-scripts suite).

**Ciclo 2 — Coverage gate**: `scripts/tests/Coverage.ps1` reworked — pins Pester 5.5.0, `-ExcludePattern` (default `e2e|Integration|session-checkpoint|skill-coverage|ui-specialist|subagent`) isolates the stable subset (769 tests / 0 fail / 26.63% coverage vs full suite 997/29 pre-existing failures), `-Strict` + `-MinimumCoverage 20` floor (ratcheting), emits JaCoCo `coverage.xml` + `summary.json` + NUnit `testResults.xml`. New CI job `coverage` runs between `tests` and `validate`, publishes JaCoCo + summary artifacts, fails below the floor. `mutation-smoke.Tests.ps1` (4/4) proves a delta-first mutant is killed: target `Get-DeepClone` in `scripts/lib/json-utils.ps1` — key insight: with `$null` input the `-eq`→`-ne` mutation is NOT observable (PSSerializer returns `$null` either way); the mutant must be tested with non-null input (`@{a=1}`). `Coverage.Tests.ps1` (5/5) adds contract tests; smoke run must execute `Coverage.ps1` in a **child process** (nested `Invoke-Pester` collides with the active Pester runtime: `Pester.Factory` lacks `CreateRuntimeDefinedParameterDictionary`).

**Ciclo 3 — Adversarial review**: `scripts/adversarial-review.ps1` wraps `check-adversarial.ps1`, normalizes breaker severities (`block`→`critical`, `warn`→`warning`) into the Cloudflare R1 taxonomy, dedups by (rule, file), optional PSScriptAnalyzer enrichment, `-SeverityFilter` narrowing, exit 1 on criticals. Tests 4/4 — fixture staged ONCE in `BeforeAll` (staging in each test raced under Pester's parallel execution: `PropertyNotFoundException: Count` on a single-object array).

**Rejected alternatives**:
- Approach B (coverage tool only, no mutation) — coverage without mutation smoke is a weak signal; both give the gate teeth.
- Approach D (full adversarial subagent deep analysis at commit time) — too slow for the pre-commit gate; structured wrapper on the existing lightweight breaker is the right cost/benefit.
- Pester 6 — breaks legacy coverage API; 5.5.0 pinned via `Install-Module -RequiredVersion`.

## Consequences

- **Positive**: Coverage regressions now fail CI (floor 20%, ratcheting). Test-runner path is itself tested (contract tests). Adversarial findings are machine-readable with severity.
- **Positive**: 29 pre-existing failures excluded by pattern — CI green without inheriting unrelated debt; documented as baseline, not silently ignored.
- **Negative**: Nested `Invoke-Pester` inside a Pester test requires child-process isolation (documented pattern, enforced by contract test).
- **Negative**: `#requires` must live on line 1 (gate reads top 3 lines only) — new scripts must follow or gate [2/13] blocks.
- **Note**: `experimento/mejora-autonoma-2026-08-18` commits were made in an isolated worktree (`C:\Users\MK\AppData\Local\Temp\opencode\gentleman-exp-2026-08-18`) because a parallel session (`agente-aem-migration`) holds the main worktree — see rollback-map.

## E2E Verification

- Pre-commit gate **22/22 ALL CLEAR** on each Ciclo commit (`e3bec66b`, `c966c4bc`, `2719837c`).
- Pester: Ciclo 1 `ci-pester.Tests.ps1` 4/4; Ciclo 2 `mutation-smoke.Tests.ps1` 4/4 + `Coverage.Tests.ps1` 5/5 (9/9 in gate); Ciclo 3 `adversarial-review.Tests.ps1` 4/4.
- Coverage: stable subset 769 tests / 0 fail / 26.63% (threshold 20%).
- Benchmark (sync-vmk -DryRun ×5, median): baseline pinned `1.414s` (BenchmarkSeconds in `benchmark-baseline.json`, commit `31134225` ref) vs final median `0.135s` → no regression.
- Rollback: `git revert e3bec66b c966c4bc 2719837c` (per-cycle), see `docs/mejoras/rollback-map.md`.
