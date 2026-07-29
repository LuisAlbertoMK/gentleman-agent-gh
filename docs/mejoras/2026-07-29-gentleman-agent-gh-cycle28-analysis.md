---
title: Cycle 28 — Post-Sprint Analysis
date: 2026-07-29
project: gentleman-agent-gh
type: analysis
previous: 2026-07-29-gentleman-agent-gh-global-analysis.md
---

# Cycle 28 Analysis — gentleman-agent-gh

**Date**: 2026-07-29
**Commit**: `9fab7941` (safety checkpoint)
**Scope**: Post-sprint evaluation — 17 improvements applied, state assessment, remaining gaps.

---

## Session Summary

17 improvements across 15 files in one session. Net: **+1086/-620 lines**.

| Domain | Items | Status |
|--------|-------|--------|
| Security hardening | 4 (.gitleaks, deny lists, pre-commit, engram-validate) | ✅ |
| Testing | 1 (bash-safe: 83 tests) | ✅ |
| Architecture | 3 (skill-graph CSV, .dockerignore, LEARNING.md) | ✅ |
| Quality | 4 (score sync, BITACORA, close-session guard, SEO compress) | ✅ |
| Infrastructure | 2 (MCP posture, pre-commit taste check) | ✅ |
| Meta | 3 (gentleman-reviewer agent, PEV gate, context budgets) | ✅ |

---

## 8-Dimension Assessment

### 1. Security — 🟢 Score: 10/10
- .gitleaks.toml: 3 new rules (GH_TOKEN, AWS AKIA, PASSWORD)
- pre-commit: secrets scan [10/12], 12/12 quality gate
- engram-validate: 4→16 patterns, homoglyph detection
- chrome-devtools-mcp: disabled (enabled: false)
- bash-safe: 83 tests covering all 10 injection patterns
- **Remaining**: No MCP tool-level restrictions per agent (low risk, all risky MCPs disabled)

### 2. Testing — 🟡 Score: 6/10
- bash-safe.Tests.ps1: 83 tests ✅ (new)
- 13/77 scripts have direct test coverage (17%)
- 64 scripts still uncovered
- **CRITICAL gap**: Most-depended scripts (bash-safe now covered, but score-auto.ps1, cross-ref-check.ps1, health-check-system.ps1, close-session.ps1, etc. remain untested)
- E2E pipeline: 3 pre-existing failures (hook step numbering, stale state artifact)

### 3. Architecture — 🟢 Score: 8/10
- skill-graph.ps1: 335→261 lines, data extracted to CSV ✅
- README reflects 28 agents (was 27) ✅
- gentleman-reviewer agent added (claude-sonnet-4-6) ✅
- PEV Gate + context budgets for T2+ tasks ✅
- 23 skills >3KB (needs improvement cycle)
- 12 non-junction skills (GLOBAL_NOT_JUNCTION — real files, not symlinked)

### 4. Infra — 🟡 Score: 7/10
- .dockerignore: +8 exclusions ✅
- MCP server security assessed (all documented) ✅
- **Pending**: Performance plan 7/9 items
  - P0: Incremental PSSA gate (28.5s full scan)
  - P0: ThreadJob for parallel scoring
  - P1: Health-check optimization, cache pruning, lazy MCP loading
  - P2: Minify opencode.json, config pre-compile, skip untouched scripts

### 5. Performance — 🟡 Score: 5/10
- `!ship` approx 46s→32s (previous improvement)
- **Pending**: No incremental PSSA, no ThreadJob
- Benchmark: skill bytes grew 165KB→248KB (>3KB skills: 2→23)

### 6. Data — 🟢 Score: 8/10
- data/skills-registry.csv created ✅
- BITACORA: 394→122 lines (clean) ✅
- .project.json: 6.2/10 (4 dims at 0.0)
- **Remaining**: Score SSoT drift (README synced, but scorer might produce different result)

### 7. DX — 🟢 Score: 9/10
- LEARNING.md created for cross-session knowledge
- close-session.ps1: dedup guard prevents BITACORA flooding
- Engram protocol well-documented
- PROTOCOL.md, SHORTCUTS.md, SKILLS-INDEX.md all current

### 8. Business — 🟡 Score: 6/10
- 4 dimensions at 0.0 in score:
  - **Cycle Activity**: No automated cycle tracking
  - **Best Practices**: No lint/policy enforcement
  - **Clean Code**: No static analysis gate
  - **Backlog Integrity**: Open items not tracked

---

## Findings Table

| # | Finding | Consensus | Risk | Files | Recommendation |
|---|---------|-----------|------|-------|---------------|
| 1 | **64/77 scripts untested** — bash-safe now covered but 64 remain | UNANIMOUS | 🔴 CRITICAL | scripts/*.ps1 | Continue per-script test coverage; next: score-auto.ps1 (most business logic) |
| 2 | **4 score dims at 0.0** — Cycle Activity, Best Practices, Clean Code, Backlog | UNANIMOUS | 🟡 HIGH | .project.json | Run `!score` after checkpoint; investigate why dims are 0 |
| 3 | **Benchmark regression** — skill bytes 165KB→248KB (>3KB: 2→23) | MAJORITY | 🟡 HIGH | .agents/skills/*/SKILL.md | Improvement cycle on skills >3KB (adversarial-breaker: 7.9KB, seo: 6.5KB) |
| 4 | **No incremental PSSA gate** — full scan 28.5s | MAJORITY | 🟡 MEDIUM | scripts/pssa-gate.ps1 | Implement incremental (changed files only) |
| 5 | **12 non-junction skills** — real files, not junctions | MAJORITY | 🟢 LOW | .agents/skills/ | Convert to junctions for consistency |

---

## Risk Matrix

```
CRITICAL  ■■■■■■■■■■ (1) — test coverage
HIGH      ■■■■■■■■■■ (2) — score dims at 0, benchmark regression
MEDIUM    ■■■■■■■■■■ (1) — PSSA incremental gate
LOW       ■■■■■■■■■■ (1) — non-junction skills
```

---

## Trend vs Previous Analysis (Jul 29)

| Prior Finding | Status | Notes |
|--------------|--------|-------|
| .gitleaks vacío | ✅ RESOLVED | +3 rules |
| -auto deny lists | ✅ RESOLVED | 5 agents synced |
| BITACORA dupes | ✅ RESOLVED | 394→122 + guard |
| Score drift | ✅ RESOLVED | README synced to 6.2 |
| bash-safe bypass | ✅ RESOLVED | 83 Pester tests |
| SEO skill | ✅ RESOLVED | Compressed 27% |
| 84% sin tests | ➡️ IMPROVED | Was 65/77, still 64/77 (bash-safe now covered) |
| Performance plan | ➡️ SAME | 7/9 items remaining |

---

## Recommendations

### Immediate (next session)
1. **Run `!score`** — recalculate after all changes, may fix 0.0 dims
2. **Tests for `score-auto.ps1`** — most business logic, high impact
3. **Skill improvement for adversarial-breaker** (7.9KB → target <4KB)

### Short-term
4. **Incremental PSSA gate** — ~2h, saves 28.5s per commit
5. **ThreadJob for parallel scoring** — ~1h, parallelizes 7-dim calc
6. **Convert 12 non-junction skills to junctions** — ~30 min

### Medium-term
7. **Achieve 25% test coverage** (20/77 scripts)
8. **Compress remaining 23 skills >3KB**

---

## Engram Persistence
- **Title**: `analysis:gentleman-agent-gh:2026-07-29`
- **Topic Key**: `analysis/gentleman-agent-gh`
- **Observation ID**: TBD (saved via mem_save)

## Trend Analysis
First full Cycle 28 analysis. Previous global-analysis (2026-07-29) had 15 findings of which 6 were resolved in this session. 8 remain with various severity.
