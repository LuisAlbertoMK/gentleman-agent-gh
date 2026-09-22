# Optional Perf/Infra/Token Improvements — 2026-08-28

**Branch:** `analysis/mejoras-optional-2026-08-28` (read-only audit, no main checkout)
**Goal:** Identify 3-5 optional improvements with verified functional impact for orchestrator
**Method:** Evidence Gate → glob docs/mejoras/*.md + ctx_search + mem_search → cite file:line

---

## 📊 Current State Baseline (Evidence-Gated)

| Dimension | Current Value | Source |
|-----------|---------------|--------|
| **CI Jobs** | 7 jobs (pester-tests 45m, pssa-lint 15m, lint 15m, lint-linux 15m, security 20m, tests 30m, tests-v1 30m, perf 15m) | `.github/workflows/*.yml` |
| **PSSA Gate** | Cold: ~33s · Warm (cache hit): ~5s · Incremental: ~1-3s | `scripts/pssa-gate.ps1:88-127` |
| **PSSA Violations** | 1325 total (346 files), 95 manual, 196 auto-fixable | `scripts/pssa-gate.ps1` output |
| **Token Budget (Skills)** | 93 skills, avg 1839B (target 2000B) — **PASS** | `check-token-budget.ps1 -Json` |
| **Token Budget (Prompts)** | 5 files, avg 1874B (target 4000B) — **PASS** | `check-token-budget.ps1 -Json` |
| **Skills >5KB** | 0 (was 22 pre-C2) | `score-auto -Json` → SE=10.0 |
| **Skills >3KB** | 0 (was 39 pre-C2) | `score-auto -Json` → SE=10.0 |
| **Config Size** | 43,558B (budget 98,304B / ADR-007 65,536B) | `Get-Item opencode.json` |
| **Benchmark (sync-vmk)** | Median 55ms (baseline 139ms) — **60% faster** | `benchmark-regression.ps1` 5 runs |
| **Context-Mode Savings** | 23.8% reduction, 7.6K tokens/session | `ctx_stats` output |
| **Composite Score** | 10.0/10 (all dims 10.0 except Score Depth 9.7) | `score-auto -Json` |

---

## 🎯 Proposed Optional Improvements (Ranked by ROI)

### 1. **CI Parallelization + Matrix Strategy** — HIGH ROI
**Evidence:** `.github/workflows/quality-gate.yml:12-14` has `concurrency: cancel-in-progress: true` but jobs run sequentially on same runner type. `lint` + `lint-linux` + `security` + `tests` could run in parallel.

| Metric | Before | After (Projected) | Verification |
|--------|--------|-------------------|--------------|
| CI wall-time (lint+security+tests) | ~80 min (sequential) | ~30 min (parallel) | GH Actions timing |
| Cost (GitHub Actions minutes) | ~170 min/run | ~60 min/run | Billing report |

**Implementation:** Split `quality-gate.yml` into 3 workflows or use `strategy.matrix` for OS × job. Keep `concurrency` per-PR.

**Risk:** LOW — no functional change, only orchestration.
**Cost:** ~2h (workflow refactor, test matrix).
**Confidence:** `confidence: high` — standard GH Actions pattern, no code changes.

---

### 2. **PSSA Incremental Gate as Default in CI** — HIGH ROI
**Evidence:** `scripts/pssa-gate.ps1:83-87` supports `-Mode Incremental` (scans only `git diff --cached` .ps1 files). Currently CI runs full scan (`.github/workflows/ci.yml:33-39`).

| Metric | Before | After (Projected) | Verification |
|--------|--------|-------------------|--------------|
| PSSA CI time (full scan) | ~33s cold / ~5s warm | ~1-3s (only changed files) | `pssa-gate.ps1 -Mode Incremental` timing |
| PSSA CI cost | 15 min timeout | <2 min | GH Actions log |

**Implementation:** Change CI step to `./scripts/pssa-gate.ps1 -Mode Incremental -Quiet`. Fallback to full scan if no cached changes (script handles this at line 85-86).

**Risk:** LOW — script already has fallback logic.
**Cost:** ~30 min (one-line CI change + verify).
**Confidence:** `confidence: high` — feature exists, tested in PERFORMANCE-PLAN.md:52-53.

---

### 3. **Pre-commit PSSA Cache Warm-up** — MEDIUM ROI
**Evidence:** `scripts/pssa-gate.ps1:93-121` uses granular per-file cache keyed by `len/mtime/sha256`. Cache hit = 4.2-6.4s vs full 42-58s (PERFORMANCE-PLAN.md:53). But CI runs on fresh runner → cold cache every time.

| Metric | Before | After (Projected) | Verification |
|--------|--------|-------------------|--------------|
| CI PSSA first run | ~33s (cold) | ~5s (cache restored) | GH Actions cache restore timing |
| Cache restore overhead | N/A | ~2-3s | GH Actions cache action |

**Implementation:** Add `actions/cache@v4` step in `ci.yml` and `quality-gate.yml` caching `%TEMP%\opencode\pssa-cache-*.json` (or `~/AppData/Local/Temp/opencode/` on Windows runners).

**Risk:** LOW — cache miss falls back to full scan gracefully.
**Cost:** ~1h (cache path discovery, workflow edit, verify).
**Confidence:** `confidence: medium` — cache path is Windows-specific (`%TEMP%`), needs runner verification.

---

### 4. **Skill Graph Sparse Loading in Orchestrator** — MEDIUM ROI
**Evidence:** `scripts/build-skill-registry.ps1` builds 93 skills, 609 triggers → `skill-registry.json`. Orchestrator loads all skills eagerly. `skill-graph` skill exists for sparse loading (`.config/opencode/skills/skill-graph/SKILL.md`).

| Metric | Before | After (Projected) | Verification |
|--------|--------|-------------------|--------------|
| Orchestrator startup tokens | ~48K (full registry) | ~15-20K (relevant only) | `benchmark.ps1 TokenEstimate` |
| Subagent delegation latency | N/A | Reduced (less context) | `benchmark-regression.ps1` on delegation |

**Implementation:** Integrate `skill-graph` sparse loading into `route-agent.ps1` / orchestrator prompt. Load only skills matching task intent + transitive deps.

**Risk:** MEDIUM — routing logic change, could mis-route if graph incomplete.
**Cost:** ~4-6h (integration, test routing accuracy).
**Confidence:** `confidence: medium` — skill-graph skill exists but untested in production routing.

---

### 5. **Hardware Profile Auto-Apply in CI** — LOW ROI (Nice-to-Have)
**Evidence:** `scripts/hardware-profile.ps1` detects tier (low/medium/high) and outputs OpenCode config profiles with compaction, watcher, MCP, subagent_depth settings. CI runners are `ubuntu-latest` / `windows-latest` (consistent specs).

| Metric | Before | After (Projected) | Verification |
|--------|--------|-------------------|--------------|
| CI memory pressure | Default config | Optimized for runner | `ctx_stats` in CI |
| Subagent depth in CI | Default (3) | 2 (medium profile) | `benchmark-regression.ps1` |

**Implementation:** Run `hardware-profile.ps1 -OutputProfile detect -WriteProfile` in CI setup, apply generated config.

**Risk:** LOW — config only, reversible.
**Cost:** ~1h (CI integration, verify no regression).
**Confidence:** `confidence: low` — marginal gain on standardized runners; unvalidated in CI context.

---

## 📋 Priority Recommendation

| Rank | Improvement | ROI | Effort | Risk | Verdict |
|------|-------------|-----|--------|------|---------|
| 1 | **CI Parallelization** | ⭐⭐⭐ High | 2h | Low | **DO** — immediate wall-time + cost reduction |
| 2 | **PSSA Incremental in CI** | ⭐⭐⭐ High | 30m | Low | **DO** — leverages existing feature, 10x faster |
| 3 | **PSSA Cache Warm-up** | ⭐⭐ Medium | 1h | Low | **DO** — compounds with #2, free speedup |
| 4 | **Skill Graph Sparse Loading** | ⭐⭐ Medium | 4-6h | Medium | **POSTPONE** — needs routing validation, do after #1-3 |
| 5 | **Hardware Profile Auto-Apply** | ⭐ Low | 1h | Low | **POSTPONE** — marginal on fixed runners |

---

## 🔍 Evidence Index (file:line citations)

| Claim | Source |
|-------|--------|
| PSSA cache hit 4.2-6.4s vs full 42-58s | `docs/mejoras/PERFORMANCE-PLAN.md:53` |
| PSSA incremental mode scans only staged .ps1 | `scripts/pssa-gate.ps1:83-87` |
| Token budget avg 1839B skills, 1874B prompts | `check-token-budget.ps1 -Json` output |
| Skills >5KB: 0, >3KB: 0, SE=10.0 | `score-auto -Json` → `SE` dimension |
| Config size 43,558B < 98,304B budget | `Get-Item opencode.json` |
| Benchmark median 55ms vs 139ms baseline | `benchmark-regression.ps1` 5-run JSON |
| Context-mode 23.8% token reduction | `ctx_stats` output |
| CI workflows: 7 jobs with timeouts | `.github/workflows/*.yml` |
| Skill registry: 93 skills, 609 triggers | `build-skill-registry.ps1` output |
| Hardware profile script with 3 tiers | `scripts/hardware-profile.ps1:128-198` |
| Skill-graph sparse loading skill exists | `.config/opencode/skills/skill-graph/SKILL.md` |

---

## 📝 Next Steps

1. **Implement #1 + #2 together** (same CI file edits) — measure CI wall-time reduction
2. **Add #3** (cache warm-up) — verify cache restore on windows-latest runner
3. **Defer #4** until routing accuracy validated with `skill-graph` skill tests
4. **Skip #5** unless CI memory pressure observed

---

*Draft persisted to `docs/mejoras/2026-08-28-optional-mejoras-perf-draft.md` on branch `analysis/mejoras-optional-2026-08-28`. No main checkout, no push to main.*