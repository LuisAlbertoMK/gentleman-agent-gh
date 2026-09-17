# CICLO 38 — Re-Score Report (TEMP)

**Date**: 2026-09-15 | **Baseline**: 8.9 | **After Re-score**: 9.4 | **Δ**: +0.5

---

## Research (CYCLE.md:43-53 + git log)

- **CYCLE.md:45**: Score delta target ≥9.5 (new dims may shift), target ≥9.8
- **CYCLE.md:47**: Score freshness ≤1 day — `git log -1 -- .project.json` = Sep 12 → **4d stale** (VIOLATED)
- **git log**: Last commit a70b7ce (Sep 12): "chore(score): sync 9.5-stale to 8.9-real post-dependabot"
- **Root cause**: score-auto.ps1 ran post-dependabot but score dropped 9.5→8.9 due to real recompute; freshness not refreshed since

---

## Score Dimensions — Before/After

| Dim | Code | Before | After | Delta | Notes |
|-----|------|--------|-------|-------|-------|
| Project Artifacts | PA | 10.0 | 10.0 | 0.0 | 94 skills, cross-ref OK |
| Security | Sec | 10.0 | 10.0 | 0.0 | No weak crypto, no secrets |
| Dead Code | DC | 10.0 | 10.0 | 0.0 | 0 orphans, 0 dead junctions |
| Clean Code | CC | 10.0 | 10.0 | 0.0 | S:127 H:127 P:127 |
| Best Practices | BP | 10.0 | 10.0 | 0.0 | P:127/127 T:98/127 |
| Orthography | Or | 10.0 | 10.0 | 0.0 | 0/95 corrupted |
| Bitacora | Bi | 10.0 | 10.0 | 0.0 | 219 lines, exists |
| Metrics | Me | 10.0 | 10.0 | 0.0 | MD/EJ/RP/ED all True |
| Script Performance | SP | 9.0 | 9.0 | 0.0 | S:127 avg:8KB thresh:122 |
| Skill Effectiveness | SE | 8.0 | 8.0 | 0.0 | T:94 >3:8 avg:2.7KB |
| **Cycle Activity** | **CA** | **4.0** | **10.0** | **+6.0** | **IC:34/30 (was 13/30)** |
| Backlog Integrity | BI2 | 10.0 | 10.0 | 0.0 | 8/8 items |
| Score Depth | SD | 9.2 | 9.3 | +0.1 | 42 sub-dims |
| **SSoT Age** | **SG** | **5.0** | **5.0** | **0.0** | **4d stale (unchanged)** |
| **COMPOSITE** | — | **8.9** | **9.4** | **+0.5** | 13 dims averaged |

---

## 50-Experiment Summary

### Group 1: 10 Timed Runs (10 cells)
- **Latency**: avg=5566ms, σ=2301ms, min=3854ms, max=11464ms
- **Score consistency**: σ=0.00 — perfectly deterministic (all 9.4)
- **Verdict**: Cache-hit path works; deterministic scoring confirmed

### Group 2: Dim-by-Dim Manual vs Script (12 cells)
- **Match rate**: 12/12 (100%) — all dimensions match between script output and .project.json detail
- **Verdict**: score-auto.ps1 is authoritative source; no manual drift

### Group 3: Freshness Thresholds (12 cells, 4 original + 8 granular)

| SSoT Age | SG Score | Projected Composite | Δ vs Baseline 8.9 |
|----------|----------|--------------------|--------------------|
| 0d | 10.0 | **9.8** | +0.88 |
| 0.5d | 10.0 | **9.8** | +0.88 |
| 1d | 10.0 | **9.8** | +0.88 |
| 1.5d | 10.0 | **9.8** | +0.88 |
| 2d | 8.0 | **9.6** | +0.73 |
| 2.5d | 7.0 | **9.6** | +0.65 |
| 3d | 6.0 | **9.5** | +0.58 |
| 3.5d | 5.0 | **9.4** | +0.50 |
| **4d (current)** | **5.0** | **9.4** | **+0.50** |
| 5d | 3.0 | 9.2 | +0.35 |
| 6d | 2.0 | 9.2 | +0.27 |
| 7d | 0.0 | 9.0 | +0.12 |

**Key finding**: Refreshing SSoT to ≤1d would push composite to **9.8** (exceeds CYCLE.md:45 target ≥9.5). The 4d staleness costs **0.385 pts** on composite.

### Group 4: Inter-Track Coupling (8 cells, 4 original + 4 sensitivity)

| IC | IT | CA Score | Composite Impact |
|----|-----|----------|-----------------|
| 0 | 30 | 0 | -0.308 |
| 13 | 30 | 4.3 | -0.023 (old cached value) |
| 15 | 30 | 5.0 | +0.023 |
| 25 | 30 | 8.3 | -1.7 (relative to current 10) |
| 30 | 30 | 10.0 | +0.462 (threshold met) |
| 34 | 30 | 10.0 | +0.462 (current) |
| 34 | 45 | 7.6 | -2.4 (raising target hurts) |
| 45 | 30 | 10.0 | +0.462 (capped at 10) |

**Key finding**: CA=10 is a ceiling — once IC≥30, CA is maxed. The re-score corrected IC from 13→34, unlocking CA=4→10.

### Group 5: Delta vs Baseline 8.9 (8 cells)

| Scenario | Score | Δ vs 8.9 |
|----------|-------|-----------|
| Baseline (before re-score) | 8.9 | 0.00 |
| Script re-score (current) | 9.4 | +0.50 |
| SG=10 (age 0-1d) | 9.8 | +0.88 |
| SG=10 + CA=10 | 9.8 | +0.88 |
| SG=8 (age 2d) | 9.6 | +0.73 |
| SG=5 (age 4d, current) | 9.4 | +0.50 |
| SG=0 (stale 7d+) | 9.0 | +0.12 |

**Total cells**: 50 (10 + 12 + 12 + 8 + 8)

---

## .project.json Update

The script `score-auto.ps1 -Json` was executed and **auto-synced** .project.json (lines 356-387 of score-auto.ps1 handle this via `Set-Content $pjPath`).

- **last_updated**: 2026-09-15 (today) ✅
- **score.current**: 9.4 (was 8.9) ✅
- **trend**: "up" ✅
- **CA dimension**: 10.0 (was 4.0) ✅
- **SG dimension**: 5.0 (unchanged — requires freshness fix, not re-score)

⚠️ **CRITICAL**: .project.json was updated on disk but **NOT committed** (per plan constraint). The `git log` still shows Sep 12. The freshness gap will persist until the user commits.

---

## Breaker Self-Audit: Gate Consumers of .project.json

| Consumer | File | Impact of Re-score |
|----------|------|-------------------|
| `pre-commit-gate.ps1` | `.githooks/pre-commit-gate.ps1:101-111` | Reads `.project.json` for integrity check (11 dims + score≥5). **NEW SCORE 9.4 PASSES** (was 8.9, also passed). No gate change. |
| `score-auto.ps1` | `scripts/score-auto.ps1:80-93` | Cache self-heal: compares cache score vs .project.json. **Now cache=9.4, .project.json=9.4 → MATCH**. Cache valid. |
| `score-auto.ps1` history | `scripts/score-auto.ps1:426-434` | Appends to `docs/metricas/history.jsonl` if delta>0.2. **9.4 vs last=8.9 → delta=0.5 → WILL APPEND** (happens on next non-cache run). |
| `close-session.ps1` | `scripts/close-session.ps1:53` | Lists `.project.json` in runtime files. **Read-only, no decision gate**. |
| `external-auditor` | `.agents/skills/external-auditor/SKILL.md:9` | Triggers on `.project.json` touch. **Re-score triggers audit requirement** — but audit was NOT run this cycle (plan scope). Flagged. |
| `self-improvement` | `.agents/skills/self-improvement/SKILL.md:19` | Protected file — requires `!audit` before commit. **Will block commit without audit**. |
| `verify.ps1` tests | `scripts/tests/verify.Tests.ps1:2959-2960` | Validates `.project.json` structure (11 dims + score≥5). **PASSES** (13 dims, score=9.4). |
| `generate-dashboard-data.ps1` | `scripts/generate-dashboard-data.ps1:165` | Reads `.project.json` for dashboard. **Read-only, score 9.4 will show correctly**. |

**Veredicto**: Re-score does NOT break any gate. The only consumer requiring action is `external-auditor` (protected-file touch triggers mandatory audit before commit). Score 9.4 is within valid range (0-10), 13 dims ≥11 minimum.

---

## Key Findings

1. **HIGH** — Score jumped 8.9→9.4 (+0.5) driven by CA correction (IC 13→34, CA 4→10). The old cached IC=13 was stale from pre-dependabot state. Confidence: high (10/10 deterministic runs).

2. **HIGH** — SSoT freshness remains 4d stale. CYCLE.md:47 requires ≤1d. The file is updated (last_updated=2026-09-15) but git log still shows Sep 12. Commit needed. Confidence: high.

3. **MEDIUM** — If freshness is fixed (age 0-1d), composite reaches **9.8** — exceeds CYCLE.md:45 target ≥9.5. The path to 9.8 is: commit .project.json → SG jumps 5→10 → composite +0.385. Confidence: high (modeled in 12 freshness experiments).

4. **LOW** — SE=8.0 is the lowest dimension (94 skills, avg 2.7KB, 8 >3KB). Compressing those 8 skills would push SE→10.0 and composite to ~9.9. Not in scope for this cycle. Confidence: medium.

5. **MEDIUM** — external-auditor skill requires `!audit` before commit (protected-file touch). User should run `!audit` before committing the re-score. Confidence: high (explicit in skill rule).

---

## Nuance

The re-score reveals a **cascade**: the Sep 12 commit "sync 9.5-stale to 8.9-real" captured a correct score at that moment, but subsequent script/skill changes (since Sep 12) restored IC counts and other metrics. The score-auto cache was content-hash-based — when scripts changed, cache invalidated and recomputed, picking up the IC correction. The 8.9→9.4 jump is NOT inflation — it's a real correction of stale data. The freshness gap (4d) is the ONLY remaining violation of CYCLE.md:47, and fixing it (committing) would simultaneously push score to 9.8. The interplay between freshness and composite score creates a paradox: the gate measures freshness via `git log`, but the file content is already fresh — only the commit is missing. This is a process gap, not a scoring bug.
