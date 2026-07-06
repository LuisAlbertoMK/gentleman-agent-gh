# Infrastructure & Caching Audit Report

> **Date**: 2026-07-05
> **Scope**: 44 scripts in `scripts/`, `.learnings/`, pre-session health check pipeline
> **Focus**: Caching mechanisms, file I/O optimization, script architecture, incremental scoring

---

## Executive Summary

The Gentleman Agent infrastructure has **1 existing cache** (drift-cache.json, TTL 300s) and **zero caching** on its most expensive operations. The `score-auto.ps1` script alone performs **~200+ file reads**, spawns **3 subprocess scripts**, and runs a full PSSA scan on every invocation — with no caching whatsoever. The pre-session health check pipeline calls 4 independent scripts that redundantly scan the same directories.

**Estimated savings**: A unified cache layer would reduce `!score` execution from ~15-25s to ~2-3s (90% reduction) on cache hits, and cut pre-session health check from ~8s to ~1s.

**Priority**: 5 quick wins (< 1h each) can save ~60% of total I/O. 3 strategic improvements address the remaining 40%.

---

## Current Caching Inventory

| Cache File | Owner Script | TTL | Invalidation | Hit Rate (est.) |
|---|---|---|---|---|
| `.learnings/drift-cache.json` | `check-skill-drift.ps1` | 300s (env-configurable) | Time-based | ~40% (skipped if -Thorough) |
| `docs/metricas/pssa-baseline.json` | `pssa-gate.ps1` | None (manual -Trend) | Manual | N/A (comparison only) |
| `.upstream-state.json` | `check-upstream.ps1` | None (manual -Update) | Manual | N/A (state file) |
| `.learnings/bias-calibration.json` | `auto-metrics` skill | None | Rolling window | N/A (not a cache) |
| `.learnings/inter-track.json` | `inter-track.ps1` | None | N/A (counter) | N/A (persistent state) |

### What's NOT Cached (the problem)

| Operation | Script | File Reads | Called By | Frequency |
|---|---|---|---|---|
| Full scoring (13 dims) | `score-auto.ps1` | ~200+ | `!score`, `!cycle`, `!close` | High |
| Cross-ref validation | `cross-ref-check.ps1` | ~70 SKILL.md + 5 refs | `score-auto.ps1`, `verify.ps1` | High |
| PSSA scan (all scripts) | `pssa-gate.ps1` | ~44 scripts × full parse | `score-auto.ps1`, `verify.ps1` | High |
| Backlog integrity | `check-backlog-integrity.ps1` | 1 (CYCLE.md) + N git calls | `score-auto.ps1` | Medium |
| Script syntax check | `verify.ps1` E1 | ~44 scripts × Parser | `verify.ps1` | Medium |
| Secrets scan | `verify.ps1` E2 | ~200+ files × full read | `verify.ps1` | Medium |
| Config drift | `check-config-drift.ps1` | 2 JSON files × SHA256 | `!sync`, `!health` | Low |
| Ponytail debt scan | `ponytail-audit.ps1` | ~300+ files × full read | `!pdebt`, `!paudit` | Low |
| Junction health | `health-check.ps1` | ~5 junction checks | Pre-session | High |

---

## Missing Caching Opportunities

### 1. score-auto.ps1 — No Cache (CRITICAL)

**Current**: Every `!score` invocation:
- Reads ALL 69 SKILL.md files (orthography corruption scan — byte-level UTF-8 analysis)
- Reads ALL 44 scripts (syntax, help, params, strictmode, try/catch checks)
- Reads ALL scripts for secrets patterns (Select-String across all files)
- Reads ALL scripts for commented-out code patterns
- Spawns `cross-ref-check.ps1` (reads ALL SKILL.md again + 5 shared refs)
- Spawns `pssa-gate.ps1` (PSSA scan of ALL scripts)
- Spawns `check-backlog-integrity.ps1` (CYCLE.md parse + git cat-file per item)
- Reads `.project.json`, `BITACORA.md`, `CYCLE.md`, `review-rules.jsonc`

**Estimated cost**: ~200+ file reads, ~3 subprocess spawns, ~15-25s total
**Cache potential**: 90% of dimensions only change when files change

**Proposed TTL by dimension**:

| Dimension | Volatility | Suggested TTL | Invalidation Trigger |
|---|---|---|---|
| PA (Project Artifacts) | Low | 1h | Skill dir count change |
| Sec (Security) | Low | 30min | Script/SKILL.md file hash change |
| DC (Dead Code) | Medium | 15min | skills/ dir change |
| CC (Clean Code) | Low | 30min | scripts/ file change |
| BP (Best Practices) | Low | 30min | scripts/ file change |
| Or (Orthography) | Very Low | 1h | SKILL.md file change |
| Bi (Bitacora) | Medium | 5min | BITACORA.md mtime |
| Me (Metrics) | Low | 30min | docs/metricas/ change |
| SP (Script Performance) | Low | 30min | scripts/ file count/size change |
| SE (Skill Effectiveness) | Low | 1h | SKILL.md file change |
| CA (Cycle Activity) | Very Low | 5min | inter-track.json change |
| BI2 (Backlog Integrity) | Low | 15min | CYCLE.md mtime |
| SD (Score Depth) | Derived | — | Computed from others |

### 2. cross-ref-check.ps1 — No Cache (HIGH)

**Current**: Reads ALL 69 SKILL.md files twice (once for cross-refs, once for config_refs), plus 5 _shared file existence checks, plus SKILLS-INDEX.md, plus review-rules.jsonc.

**Estimated cost**: ~75 file reads, ~3-5s
**Called by**: `score-auto.ps1`, `verify.ps1` E1, standalone

**Cache strategy**: Hash-based. Compute composite hash of all SKILL.md files + SKILLS-INDEX.md + review-rules.jsonc. If hash matches cache, return cached result.

### 3. verify.ps1 — No Cache (HIGH)

**Current**: E1 reads all scripts (Parser) + all SKILL.md (frontmatter) + cross-ref-check. E2 reads PSSA + secrets scan (200+ files) + git status. E3 reads junctions + .project.json + script help + CYCLE.md.

**Estimated cost**: ~300+ file reads across all profiles, ~10-15s
**Cache strategy**: Per-profile cache with git-diff invalidation.

### 4. Pre-session Health Check — No Shared Cache (MEDIUM)

**Current** (AGENTS.md §J):
```
0. restore-project-score.ps1 -Quiet     (reads .project.json, maybe git checkout)
1. Parallel block:
   - git status --short                  (git call)
   - check-skill-drift.ps1              (HAS CACHE — 300s TTL)
   - health-check.ps1 -Json             (5 junction checks, no cache)
2. check-upstream.ps1 -Json            (4 git ls-remote calls, network I/O)
```

**Problem**: health-check.ps1 has no cache. check-config-drift.ps1 (called by `!sync` and `!health`) has no cache. These are called every session start.

### 5. ponytail-audit.ps1 — No Cache (LOW)

**Current**: Scans ALL .ps1/.md/.psm1 files recursively for `ponytail:` patterns. Reads full content of every file.

**Estimated cost**: ~300+ file reads, ~5-8s
**Cache strategy**: Git-diff based. If no files changed since last scan, return cached.

---

## Unified Health Cache Design

### Schema: `.learnings/health-cache.json`

```json
{
  "version": "1.0.0",
  "last_updated": "2026-07-05T14:30:00Z",
  "git_head": "abc123def456",
  "sections": {
    "junctions": {
      "timestamp": "2026-07-05T14:30:00Z",
      "ttl_seconds": 300,
      "valid": true,
      "result": {
        "exitCode": 0,
        "checks": [
          {"check": "vmk-skills-junction", "status": "OK", "detail": "..."},
          {"check": "vmk-prompts-junction", "status": "OK", "detail": "..."},
          {"check": "global-skills-junction", "status": "OK", "detail": "..."}
        ]
      }
    },
    "skill_drift": {
      "timestamp": "2026-07-05T14:30:00Z",
      "ttl_seconds": 300,
      "valid": true,
      "result": {"allSynced": true, "totalSkills": 69}
    },
    "config_drift": {
      "timestamp": "2026-07-05T14:30:00Z",
      "ttl_seconds": 600,
      "valid": true,
      "invalidation_key": "sha256:abc123...",
      "result": {"totalDrift": 0, "sections": [...]}
    },
    "cross_ref": {
      "timestamp": "2026-07-05T14:30:00Z",
      "ttl_seconds": 900,
      "valid": true,
      "invalidation_key": "composite_hash:def456...",
      "result": {"allClean": true, "errors": [], "warnings": []}
    },
    "score": {
      "timestamp": "2026-07-05T14:30:00Z",
      "ttl_seconds": 1800,
      "valid": true,
      "invalidation_key": "git_head:abc123",
      "dimensions": {
        "PA": {"s": 10, "e": {...}, "r": "..."},
        "Sec": {"s": 10, "e": {...}, "r": "..."}
      },
      "total": 9.2
    },
    "verify_e1": {
      "timestamp": "2026-07-05T14:30:00Z",
      "ttl_seconds": 900,
      "valid": true,
      "invalidation_key": "git_head:abc123",
      "result": {"passed": 3, "failed": 0}
    },
    "verify_e2": {
      "timestamp": "2026-07-05T14:30:00Z",
      "ttl_seconds": 1800,
      "valid": true,
      "invalidation_key": "git_head:abc123",
      "result": {"passed": 4, "failed": 0}
    },
    "verify_e3": {
      "timestamp": "2026-07-05T14:30:00Z",
      "ttl_seconds": 900,
      "valid": true,
      "invalidation_key": "git_head:abc123",
      "result": {"passed": 4, "failed": 0}
    }
  }
}
```

### Invalidation Strategy

| Strategy | Used By | Mechanism |
|---|---|---|
| **Time-based** | junctions, skill_drift | `ttl_seconds` elapsed since timestamp |
| **Git HEAD** | score, verify_*, cross_ref | `git_head` != current `git rev-parse HEAD` |
| **File hash** | config_drift | `invalidation_key` != current SHA256 of monitored files |
| **Force** | all | `-Force` or `-Thorough` flag bypasses cache |

### Cache Read/Write Protocol

```
READ:
  1. Load health-cache.json
  2. For requested section:
     a. Check timestamp + ttl_seconds → expired? → MISS
     b. Check invalidation_key → stale? → MISS
     c. Check valid → false? → MISS
     d. HIT → return cached result
  3. MISS → compute → write back to cache

WRITE:
  1. Compute result
  2. Update section: timestamp, ttl, valid=true, invalidation_key, result
  3. Write entire cache file (atomic: write to .tmp, rename)
```

### Force Bypass

All scripts gain a `-Force` switch that skips cache reads but still writes results.
`-Thorough` in check-skill-drift.ps1 already does this.

---

## Incremental Scoring Architecture

### Change Detection Layer

```
BEFORE full score computation:
  1. current_head = git rev-parse HEAD
  2. cached_head = health-cache.sections.score.invalidation_key
  3. IF current_head == cached_head AND cache not expired:
       → RETURN cached score (FULL HIT)
  4. IF current_head != cached_head:
       → changed_files = git diff --name-only cached_head..current_head
       → Determine which dimensions are affected:
```

### Dimension → File Dependency Map

| Dimension | Monitored Paths | Change Triggers Recompute |
|---|---|---|
| PA | `.agents/skills/`, `SKILLS-INDEX.md`, `README.md`, `.project.json` | Dir count, file existence |
| Sec | `scripts/*.ps1`, `.agents/skills/*/SKILL.md`, `.github/workflows/*.yml`, `opencode.json` | Content hash |
| DC | `skills/` (junction dir), `scripts/*.ps1` | Dir listing, content |
| CC | `scripts/*.ps1` | Content hash |
| BP | `scripts/*.ps1` | Content hash |
| Or | `.agents/skills/*/SKILL.md` | Content hash (byte-level) |
| Bi | `BITACORA.md` | mtime + line count |
| Me | `docs/metricas/` | Dir listing |
| SP | `scripts/*.ps1` | File count, sizes |
| SE | `.agents/skills/*/SKILL.md`, `commands/*.md`, `prompts/**` | File sizes |
| CA | `.learnings/inter-track.json` | Content hash |
| BI2 | `CYCLE.md` | Content hash |
| SD | Derived from all above | Computed |

### Partial Recompute Algorithm

```powershell
# Pseudocode
$changedFiles = git diff --name-only "$cachedHead..HEAD"
$dirtyDims = @()

foreach ($file in $changedFiles) {
    if ($file -match '^scripts/')        { $dirtyDims += @('CC','BP','SP','Sec') }
    if ($file -match '^\.agents/skills/') { $dirtyDims += @('PA','Sec','Or','SE') }
    if ($file -match '^skills/')          { $dirtyDims += 'DC' }
    if ($file -match '^BITACORA\.md')     { $dirtyDims += 'Bi' }
    if ($file -match '^docs/metricas/')   { $dirtyDims += 'Me' }
    if ($file -match '^CYCLE\.md')        { $dirtyDims += 'BI2' }
    if ($file -match '^\.learnings/inter-track') { $dirtyDims += 'CA' }
    if ($file -match '^(commands|prompts)/') { $dirtyDims += 'SE' }
    if ($file -match '^opencode\.json')   { $dirtyDims += 'Sec' }
    if ($file -match '^\.github/')        { $dirtyDims += 'Sec' }
}

$dirtyDims = $dirtyDims | Select-Object -Unique

# Recompute ONLY dirty dimensions
foreach ($dim in $dirtyDims) {
    $h[$dim] = Compute-Dimension $dim
}

# Load clean dimensions from cache
foreach ($dim in ($allDims - $dirtyDims)) {
    $h[$dim] = $cachedScore.dimensions[$dim]
}

# Recompute derived dimensions
$h['SD'] = Compute-ScoreDepth $h
$total = Compute-Average $h
```

### Estimated Savings

| Scenario | Dirs Dirty | Dirs Skipped | Time Saved |
|---|---|---|---|
| Only BITACORA.md changed | 1 (Bi) | 12 | ~90% |
| Only scripts/ changed | 4 (CC,BP,SP,Sec) | 9 | ~60% |
| Only skills/ changed | 4 (PA,Sec,Or,SE) | 9 | ~60% |
| No changes (same HEAD) | 0 | 13 | ~98% |
| Everything changed | 13 | 0 | 0% |

---

## File I/O Optimization Plan

### Problem: N+1 File Reads

The most pervasive anti-pattern. Found in:

| Script | Pattern | Current Reads | Optimized |
|---|---|---|---|
| `score-auto.ps1` | Per-file ReadAllText for orthography | 69 individual reads | Single batch: read all into hashtable |
| `score-auto.ps1` | Per-file ForEach-Object -Parallel for CC | 44 parallel reads | Single batch read |
| `score-auto.ps1` | Select-String per file collection | 44+69+5+1 = 119 calls | Single pass over concatenated content |
| `cross-ref-check.ps1` | Per-SKILL.md ReadAllText for cross-refs | 69 reads | Single batch |
| `cross-ref-check.ps1` | Per-SKILL.md ReadAllText for config_refs | 69 reads (AGAIN) | Reuse from cross-refs pass |
| `verify.ps1` E1 | Per-script Parser::ParseFile | 44 calls | Already sequential, but cacheable |
| `verify.ps1` E2 | Per-file ReadAllText for secrets | 200+ reads | Single batch |
| `verify.ps1` E3 | Per-script ReadAllText for .SYNOPSIS | 44 reads | Reuse from E1 parse |

### Optimization 1: Single-Pass File Reading

```powershell
# BEFORE (cross-ref-check.ps1 lines 29, 33 — reads each SKILL.md TWICE)
$sd | ForEach-Object { $c = [IO.File]::ReadAllText($mp); ... cross-refs ... }
$sd | ForEach-Object { $c = [IO.File]::ReadAllText($mp); ... config_refs ... }

# AFTER: Read once, process both patterns
$contentCache = @{}
$sd | ForEach-Object {
    $mp = Join-Path $_.FullName "SKILL.md"
    $contentCache[$_.Name] = [IO.File]::ReadAllText($mp)
}
# Pass 1: cross-refs
$contentCache.GetEnumerator() | ForEach-Object { ... }
# Pass 2: config_refs (reuses same content)
$contentCache.GetEnumerator() | ForEach-Object { ... }
```

**Savings**: 69 file reads eliminated (50% reduction in cross-ref-check.ps1)

### Optimization 2: Batch Directory Enumeration

```powershell
# BEFORE (score-auto.ps1 lines 14-16 — 3 separate Get-ChildItem calls)
$skillDirs = Get-ChildItem -Directory ".\.agents\skills" -Name
$skillMdFiles = Get-ChildItem ".\.agents\skills\*\SKILL.md"
$scriptFiles = Get-ChildItem ".\scripts\*.ps1"

# AFTER: Single enumeration, partition in memory
$allFiles = Get-ChildItem -Path ".\.agents\skills", ".\scripts" -Recurse -File
$skillMdFiles = $allFiles | Where-Object { $_.Name -eq 'SKILL.md' }
$scriptFiles = $allFiles | Where-Object { $_.Directory.Name -eq 'scripts' -and $_.Extension -eq '.ps1' }
$skillDirs = $allFiles | Where-Object { $_.Name -eq 'SKILL.md' } | ForEach-Object { $_.Directory.Name }
```

**Savings**: 2 directory scans eliminated

### Optimization 3: StringBuilder Consolidation (Already Done)

`verify.ps1` and `cross-ref-check.ps1` already use `[System.Text.StringBuilder]` for accumulating results. This is good — it avoids array copy-on-grow. **No action needed.**

### Optimization 4: Reuse PSSA Results

```
CURRENT: pssa-gate.ps1 runs Invoke-ScriptAnalyzer on ALL scripts.
         verify.ps1 E1 runs Parser::ParseFile on ALL scripts (syntax check).
         These are REDUNDANT — PSSA includes syntax checking.

PROPOSED: If PSSA ran successfully (exit 0), skip verify.ps1 E1 syntax check.
         Cache PSSA results with git-head invalidation.
```

**Savings**: 44 Parser::ParseFile calls eliminated when PSSA cache is warm

---

## Quick Wins (< 1 hour each)

### QW-1: Add Cache to cross-ref-check.ps1 (IMPACT: HIGH, EFFORT: 30min)

**What**: Add composite hash cache. Hash all SKILL.md + SKILLS-INDEX.md + review-rules.jsonc. If hash matches `.learnings/crossref-cache.json`, return cached result.

**Savings**: ~75 file reads, ~3-5s per invocation. Called 2-3x per `!score`/`!ship`.

**Implementation**:
```powershell
# At top of cross-ref-check.ps1
$cachePath = Join-Path $PSScriptRoot "..\.learnings\crossref-cache.json"
$compositeHash = Get-FileHash (all SKILL.md paths concatenated) -Algorithm SHA256
if (Test-Path $cachePath) {
    $cache = Get-Content $cachePath -Raw | ConvertFrom-Json
    if ($cache.hash -eq $compositeHash) { return $cache.result }
}
# ... existing logic ...
# At bottom: write cache
@{ hash = $compositeHash; result = $res; timestamp = (Get-Date -Format "o") } |
    ConvertTo-Json | Set-Content $cachePath
```

### QW-2: Add Git-HEAD Cache to score-auto.ps1 (IMPACT: CRITICAL, EFFORT: 45min)

**What**: Before computing each dimension, check if relevant files changed since last score. If not, load from cache.

**Savings**: 60-90% of computation on unchanged repos. Most `!score` calls happen after no/minimal changes.

**Implementation**: Store per-dimension hashes in `.learnings/score-cache.json`. On `!score`, compute `git diff --name-only` against cached HEAD, determine dirty dimensions, skip clean ones.

### QW-3: Eliminate Double-Read in cross-ref-check.ps1 (IMPACT: MEDIUM, EFFORT: 15min)

**What**: Lines 29 and 33 read ALL SKILL.md files separately for cross-refs and config_refs. Read once into a hashtable, process both patterns from memory.

**Savings**: 69 file reads per invocation.

### QW-4: Add Cache to health-check.ps1 (IMPACT: MEDIUM, EFFORT: 20min)

**What**: Cache junction check results. Junctions rarely change between sessions. TTL: 300s (match drift-cache).

**Savings**: 5 junction checks (each involves Test-Path + Get-Item + Target resolution). Called every session start.

### QW-5: Reuse Script Content Across score-auto.ps1 Dimensions (IMPACT: HIGH, EFFORT: 30min)

**What**: score-auto.ps1 reads all scripts multiple times:
- Line 24: Select-String for weak crypto (Sec)
- Line 26: Select-String for secrets (Sec)
- Line 33: Select-String for commented-out code (DC)
- Line 37: ForEach-Object -Parallel for CC (help, params, strictmode, try)
- Line 100-102: ReadAllText for .SYNOPSIS check (via verify.ps1 E3)

Read all scripts ONCE into a hashtable `$scriptContent[name] = content`, then run all pattern matches against the cached content.

**Savings**: ~130 redundant file reads.

---

## Strategic Improvements (Architectural Changes)

### S-1: Unified Cache Module (`scripts/lib/cache.ps1`)

**What**: Create a shared cache module that all scripts import. Provides:
- `Get-CachedSection -Name <section> -Ttl <seconds> -Key <invalidation_key>` → $null on miss, cached result on hit
- `Set-CachedSection -Name <section> -Result <object> -Key <invalidation_key> -Ttl <seconds>`
- `Invalidate-Cache -Name <section>` (or `-All`)
- Atomic writes (write to .tmp, rename)
- Corruption recovery (if JSON parse fails, treat as empty cache)

**Why**: Currently each script implements its own cache logic (or none). A shared module ensures consistency and reduces boilerplate.

**Impact**: Enables caching in ALL scripts with ~5 lines of code each.

### S-2: Git-Change-Aware Pipeline

**What**: The pre-session health check (AGENTS.md §J) should:
1. Get `git rev-parse HEAD` ONCE
2. Get `git diff --name-only HEAD~1..HEAD` ONCE
3. Pass changed file list to all downstream scripts
4. Each script uses the change list to determine what to recompute

**Why**: Currently `git status`, `git diff`, and `git rev-parse` are called independently by multiple scripts. Consolidating saves ~3-5 git subprocess calls per session.

**Impact**: Reduces pre-session health check from ~8s to ~1s on cache hits.

### S-3: Incremental Score Computation with Dirty-Flag Tracking

**What**: Extend the unified cache with per-dimension dirty flags:
- On every git commit, run a lightweight hook that marks affected dimensions as dirty
- On `!score`, only recompute dirty dimensions
- Clean dimensions are loaded from cache

**Why**: Full scoring takes 15-25s. Most invocations happen when only 1-2 dimensions are affected. Incremental scoring would take 2-3s.

**Impact**: 80-90% score computation time reduction for typical workflows.

---

## Implementation Priority Matrix

| Item | Impact | Effort | Priority | Savings |
|---|---|---|---|---|
| QW-2: score-auto git-HEAD cache | CRITICAL | 45min | **P0** | 60-90% score time |
| QW-5: Reuse script content in score-auto | HIGH | 30min | **P0** | ~130 file reads |
| QW-1: cross-ref-check cache | HIGH | 30min | **P1** | ~75 file reads |
| QW-3: Eliminate double-read in cross-ref | MEDIUM | 15min | **P1** | 69 file reads |
| QW-4: health-check cache | MEDIUM | 20min | **P1** | 5 junction checks |
| S-1: Unified cache module | HIGH | 2h | **P2** | Enables all caching |
| S-2: Git-change-aware pipeline | MEDIUM | 1.5h | **P2** | 3-5 git calls |
| S-3: Incremental scoring | CRITICAL | 3h | **P3** | 80-90% score time |

### Recommended Implementation Order

1. **S-1** first (unified cache module) — enables everything else
2. **QW-2** + **QW-5** together (score-auto overhaul) — biggest impact
3. **QW-1** + **QW-3** together (cross-ref overhaul) — second biggest
4. **QW-4** (health-check cache) — quick win for session start
5. **S-2** + **S-3** (architectural) — long-term optimization

---

## Appendix: File I/O Hotspot Map

```
score-auto.ps1 ──────────────────────────────────────────────────────────
  ├── Get-ChildItem ×3 (skillDirs, skillMdFiles, scriptFiles)
  ├── cross-ref-check.ps1 ──── Get-ChildItem + ReadAllText ×69 ×2 passes
  ├── pssa-gate.ps1 ─────────── Invoke-ScriptAnalyzer (44 scripts)
  ├── check-backlog-integrity ── Get-Content CYCLE.md + git cat-file ×N
  ├── Select-String ×4 (crypto, secrets, commented-out, orthography)
  ├── ForEach-Object -Parallel ×2 (CC scan, orthography byte scan)
  ├── Get-Content ×5 (BITACORA, .project.json, inter-track, bias, errors)
  └── Get-ChildItem ×3 (orphans, dead junctions, metrics)

verify.ps1 ──────────────────────────────────────────────────────────────
  ├── E1: ParseFile ×44 + ReadAllText ×69 + cross-ref-check.ps1
  ├── E2: PSSA scan + ReadAllText ×200+ (secrets) + git status
  └── E3: junction checks + .project.json + ReadAllText ×44 + CYCLE.md

Pre-session health check ────────────────────────────────────────────────
  ├── restore-project-score.ps1 ── Get-Content + git checkout (maybe)
  ├── git status --short ────────── git subprocess
  ├── check-skill-drift.ps1 ────── CACHE HIT (300s) or full scan
  ├── health-check.ps1 ──────────── 5 junction checks (no cache)
  └── check-config-drift.ps1 ───── 2 JSON reads + SHA256 ×4
```

---

## Appendix: Cache File Inventory (Proposed)

| File | Owner | TTL | Invalidation | Size (est.) |
|---|---|---|---|---|
| `.learnings/health-cache.json` | Unified cache module | Per-section | Git HEAD + time | ~5-10KB |
| `.learnings/crossref-cache.json` | cross-ref-check.ps1 | 15min | Composite hash | ~2-3KB |
| `.learnings/score-cache.json` | score-auto.ps1 | 30min | Git HEAD + per-dim | ~8-15KB |
| `.learnings/verify-cache.json` | verify.ps1 | 15min | Git HEAD | ~3-5KB |
| `.learnings/drift-cache.json` | check-skill-drift.ps1 | 5min | Time (EXISTS) | ~0.2KB |

Total cache storage: ~20-35KB. Negligible disk footprint.
