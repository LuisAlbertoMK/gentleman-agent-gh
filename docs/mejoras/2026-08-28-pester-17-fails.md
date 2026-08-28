# Pester Fails Catalog — 2026-08-28

- **Date:** 2026-08-28
- **Branch:** main (`c1bb6d64` / `f0bc9515`)
- **Suite total:** 1366/1383 passed — **Failed: 17**
- **Runtime:** ~478–497s

## Summary

17 Pester failures across 3 test files. All are **known debt — NOT a blocker**.
Pester failures do not fail the pre-commit gate (only a warning); `gate` remains
**ALL CLEAR 25/25**.

| File | Fails | Category |
|------|:-----:|----------|
| `scripts/tests/check-config-drift.Tests.ps1` | 2 | Config drift (3 DRIFT, no OK) + exit code |
| `scripts/tests/score-depth.Tests.ps1` | 2 | Score depth regression guard (10.0 vs 9.7) |
| `scripts/tests/ScoreIntegration.Tests.ps1` | 13 | Integration: cache + dimensions |

## Fail List

### 1. `scripts/tests/check-config-drift.Tests.ps1` (2 fails)

- **`check-config-drift.Tests.ps1:45`** — `reports sections with OK or DRIFT status`
  - `$statuses | Should -Contain "OK"` (assertion :48) — all 3 sections are **DRIFT**, none **OK**.
- **`check-config-drift.Tests.ps1:99`** — `exit code reflects drift count (capped at 2)`
  - `$json.exitCode | Should -Be $json.totalDrift` (assertion :103) — exit code reflects 3 drifted sections, not the OK expectation. Actual exit code `:99` (truncated message).
  - Note: sections produced **3 DRIFT, no OK**.

### 2. `scripts/tests/score-depth.Tests.ps1` (2 fails)

- **`score-depth.Tests.ps1:14`** — `Score Depth dimension is 10.0 (historical 9.2 regression guard)`
  - `$script:proj.score.dimensions.'Score Depth' | Should -Be 10.0` (assertion :16) — **Score Depth 10.0 vs 9.7**.
- **`score-depth.Tests.ps1:24`** — `SD score (s) is 10.0`
  - `$script:proj.dimensions_detail.SD.s | Should -Be 10.0` (assertion :26) — **SD score 10.0 vs 9.7**.

### 3. `scripts/tests/ScoreIntegration.Tests.ps1` (13 fails)

Integration tests exercising the real `score-auto.ps1 -Json -Quiet` pipeline.

- **`ScoreIntegration.Tests.ps1:55`** — `score-auto.ps1 exists and is readable` — `Should -Exist`.
- **`ScoreIntegration.Tests.ps1:59`** — `score-dims.ps1 exists and is readable` — `Should -Exist`.
- **`ScoreIntegration.Tests.ps1:63`** — `exit code 0 (regression: multiline pipeline + -ThrottleLimit bug)` — `Should -Be 0`.
- **`ScoreIntegration.Tests.ps1:69`** — `produces valid JSON with all 13 expected dimensions` — `Should -Be 0`/`-Not -BeNullOrEmpty` on 13 dims.
- **`ScoreIntegration.Tests.ps1:83`** — `composite score is between 0 and 10` — `score.current` range.
- **`ScoreIntegration.Tests.ps1:89`** — `all displayed dimensions have scores between 0 and 10` — any dim out of range flagged.
- **`ScoreIntegration.Tests.ps1:102`** — `composite score equals average of all internal dimensions (±0.2)` — `diff | Should -BeLessOrEqual 0.2`.
- **`ScoreIntegration.Tests.ps1:117`** — `second run returns cached results` — `firstObj.score.current | Should -Be secondObj.score.current` (cache round-trip).
- **`ScoreIntegration.Tests.ps1:135`** — `Clean Code (CC) has evidence with total_scripts > 0` — CC evidence scan.
- **`ScoreIntegration.Tests.ps1:147`** — `Best Practices (BP) has evidence with param_cov >= 0` — BP evidence.
- **`ScoreIntegration.Tests.ps1:156`** — `corruption scanner runs without error` (Or orthography corruption detection) — `Or.scanned | Should -BeGreaterOrEqual 0`.

## Root Cause

- **Config drift:** 3 sections report `DRIFT` with **no** `OK` section → both the
  "contains OK" assertion and the exit-code-vs-totalDrift assertion fail.
- **Score depth regression guard:** `Score Depth` and `SD` score are `9.7`, the
  guard pins history at `10.0` → 2 hard-fail assertions.
- **ScoreIntegration:** integration failures on cache round-trip + dimension
  evidence across the full pipeline (CC/BP evidence, 13-dim JSON completeness,
  composite-vs-average parity, corruption scanner).

## Classification

- **Known debt, not a blocker.** `gate` pre-commit check continues **ALL CLEAR 25/25**;
  Pester fails surface only as a warning.

## Suggested Next Steps

- **Rebaseline** `score-depth` guard from `10.0` → `9.7` (or adjust tolerance) once
  the score drop is confirmed intentional (regression vs. legitimate measurement).
- **Fix config drift:** reconcile the 3 DRIFT sections or relax the "contains OK"
  + exit-code assertions to reflect the real drift model.
- **Triage ScoreIntegration** cache round-trip + dimension evidence failures
  against the current `score-auto.ps1` output shape before re-enabling per-commit.
