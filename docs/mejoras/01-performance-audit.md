# Performance Audit Report — Gentleman Agent

**Date**: 2026-07-05
**Auditor**: gentleman-performance (Qwen3.7 Max)
**Scope**: 44 scripts in `scripts/`, pre-session health chain, score-auto.ps1 hot path
**Method**: Static analysis of all source files — no runtime profiling

---

## Executive Summary

**Overall Performance Score: 6.5/10**

The project has solid foundations (parallel patterns already used in score-auto.ps1 lines 37/44, check-skill-drift.ps1 caching), but the **score-auto.ps1 orchestrator** is the single biggest bottleneck — it spawns 3 sub-scripts sequentially, each doing redundant file I/O, and performs 6+ separate `Get-ChildItem` / `Select-String` passes over the same directories.

### Top 3 Bottlenecks (by impact)

| # | Bottleneck | Est. Impact | Location |
|---|-----------|-------------|----------|
| 1 | score-auto.ps1 sequential sub-script chain | **~4-8s** per `!score` | score-auto.ps1:19,28,67 |
| 2 | cross-ref-check.ps1 repeated directory enumeration (4x same dir) | **~800ms** per call | cross-ref-check.ps1:12,20,29,33 |
| 3 | score-auto.ps1 redundant file system scans (6+ Get-ChildItem on overlapping paths) | **~500ms** per `!score` | score-auto.ps1:14-16,30,57 |

**Estimated total savings if all fixes applied**: 5-12 seconds per `!score` invocation (currently ~15-20s estimated, target ~8-10s).

---

## Critical Bottlenecks (Top 5)

### C-1: score-auto.ps1 — Sequential Sub-Script Chain
- **File**: `scripts/score-auto.ps1:19,28,67`
- **Impact**: HIGH (~4-8s sequential wall-clock)
- **Problem**: Three heavy sub-scripts run sequentially:
  - Line 19: `cross-ref-check.ps1` — scans 69 skills, validates cross-refs
  - Line 28: `pssa-gate.ps1 -Mode Check` — Invoke-ScriptAnalyzer on all scripts
  - Line 67: `check-backlog-integrity.ps1 -Json` — parses CYCLE.md + git cat-file per item
- **Fix**: Run all 3 in parallel via `Start-Job` or `ForEach-Object -Parallel`:
  ```powershell
  $jobs = @(
    { & ".\scripts\cross-ref-check.ps1" -Json } | Start-Job
    { & ".\scripts\pssa-gate.ps1" -Mode Check -Quiet } | Start-Job
    { & ".\scripts\check-backlog-integrity.ps1" -Json } | Start-Job
  )
  $results = $jobs | Wait-Job | Receive-Job
  ```
- **Effort**: Medium (1-2 hours) — need to restructure result collection
- **Risk**: LOW — sub-scripts are independent

### C-2: cross-ref-check.ps1 — 4x Redundant Directory Enumeration
- **File**: `scripts/cross-ref-check.ps1:12,20,29,33`
- **Impact**: HIGH (~800ms on NVMe, worse on HDD)
- **Problem**: `Get-ChildItem $cd -Directory` is called 4 times with identical parameters:
  - Line 12: `$sd = Get-ChildItem (Join-Path $cd "*") -Directory`
  - Line 20: `(Get-ChildItem $cd -Directory).Where({...})`
  - Line 29: `(Get-ChildItem $cd -Directory).Where({...})`
  - Line 33: `(Get-ChildItem $cd -Directory).Where({...})`
- **Fix**: Cache once at top: `$allSkillDirs = Get-ChildItem $cd -Directory` and reuse
- **Effort**: Trivial (15 min)
- **Risk**: NONE

### C-3: score-auto.ps1 — Redundant File System Scans
- **File**: `scripts/score-auto.ps1:14-16,30,57`
- **Impact**: MEDIUM (~500ms)
- **Problem**: 6+ `Get-ChildItem` calls on overlapping paths:
  - Line 14: `Get-ChildItem -Directory ".\.agents\skills"` (skill dirs)
  - Line 15: `Get-ChildItem ".\.agents\skills\*\SKILL.md"` (skill files — re-enumerates dirs)
  - Line 16: `Get-ChildItem ".\scripts\*.ps1"` (scripts)
  - Line 30: `Get-ChildItem ".\skills" -File` (workspace skills — overlaps with line 14)
  - Line 57: `Get-ChildItem "commands\*.md"` + `Get-ChildItem "prompts" -Recurse -File`
- **Fix**: Consolidate into 2-3 cached variables at top of script
- **Effort**: Trivial (30 min)
- **Risk**: NONE

### C-4: score-auto.ps1 — Multiple Select-String Passes Over Same Files
- **File**: `scripts/score-auto.ps1:24,26,33`
- **Impact**: MEDIUM (~400ms)
- **Problem**: Three separate `Select-String` invocations scan the same `$scriptFiles`:
  - Line 24: Weak crypto patterns (MD5, SHA1)
  - Line 26: Secrets patterns (api_key, password, token)
  - Line 33: Commented-out code patterns
- **Fix**: Single-pass scan combining all patterns into one regex alternation:
  ```powershell
  $combinedPattern = '(MD5|SHA1\b|api[_-]?key\s*=|password\s*=|^\s*#\s*function)'
  $matches = Select-String -Path $scriptFiles.FullName -Pattern $combinedPattern
  # Then categorize matches by group
  ```
- **Effort**: Medium (1 hour) — regex grouping needs care
- **Risk**: LOW

### C-5: verify.ps1 — Sequential E1/E2/E3 Check Functions
- **File**: `scripts/verify.ps1:119-124`
- **Impact**: MEDIUM (~2-4s for full `All` profile)
- **Problem**: Three check functions run sequentially, each doing heavy I/O:
  - `Invoke-E1Checks`: Parser::ParseFile on all 43 scripts + cross-ref-check.ps1
  - `Invoke-E2Checks`: PSSA gate + secrets scan (ReadAllText on all files in 4 dirs) + git status
  - `Invoke-E3Checks`: Junction checks + file reads + CYCLE.md parsing
- **Fix**: Run E1/E2/E3 as parallel jobs:
  ```powershell
  $jobs = @()
  if ($ProfileName -in 'E1','All') { $jobs += Start-Job { . $using:PSScriptRoot/verify.ps1 -ProfileName E1 -Quiet } }
  # ... same for E2, E3
  ```
- **Effort**: Medium (1-2 hours)
- **Risk**: LOW — checks are independent

---

## Medium Bottlenecks (Top 10)

### M-1: pssa-gate.ps1 — Double Full Recursive Scan
- **File**: `scripts/pssa-gate.ps1:15,54`
- **Impact**: MEDIUM (~1-2s)
- **Problem**: `Invoke-ScriptAnalyzer -Recurse` scans all .ps1 files, then line 54 does ANOTHER full recursive scan via `[IO.Directory]::EnumerateFiles` for `&&` violations
- **Fix**: Combine into single file enumeration; run PSSA and && check in parallel per-file
- **Effort**: Medium (1 hour)

### M-2: score-auto.ps1 — .project.json Read Twice
- **File**: `scripts/score-auto.ps1:20,88`
- **Impact**: LOW (~50ms)
- **Problem**: Line 20 does `Test-Path ".project.json"`, line 88 does `Get-Content ".project.json" -Raw | ConvertFrom-Json` — the file is read again for trend comparison
- **Fix**: Read once at top, cache parsed object
- **Effort**: Trivial (10 min)

### M-3: score-auto.ps1 — BITACORA.md Test-Path + Get-Path Redundancy
- **File**: `scripts/score-auto.ps1:47-48`
- **Impact**: LOW (~30ms)
- **Problem**: Line 47 does `Test-Path "BITACORA.md"` then `Get-Content`, line 48 does `Test-Path "BITACORA.md"` AGAIN in the hashtable expression
- **Fix**: Single Test-Path, cache result
- **Effort**: Trivial (5 min)

### M-4: check-skill-drift.ps1 — Per-Skill Get-Item in Loop + Second Pass
- **File**: `scripts/check-skill-drift.ps1:38-44,61-62`
- **Impact**: MEDIUM (~300ms for 69 skills)
- **Problem**: Lines 38-44 iterate 69 skills calling `Get-Item` + `ReadAllText` per skill. Lines 61-62 iterate AGAIN calling `Get-Item` to count junction vs real file stats
- **Fix**: Single pass — collect junction/real-file counts during the main loop
- **Effort**: Low (30 min)

### M-5: cross-ref-check.ps1 — O(n*m) Array Lookup for Cross-Refs
- **File**: `scripts/cross-ref-check.ps1:28-29`
- **Impact**: LOW-MEDIUM (~100ms for 69 skills with ~5 refs each)
- **Problem**: `$al` is an array of skill names. `-notcontains` does linear scan. For 69 skills * ~5 refs each = 345 lookups * O(69) = ~24K comparisons
- **Fix**: Convert `$al` to hashtable: `$alSet = @{}; $al | ForEach-Object { $alSet[$_] = $true }`
- **Effort**: Trivial (10 min)

### M-6: check-backlog-integrity.ps1 — git cat-file Per Commit
- **File**: `scripts/check-backlog-integrity.ps1:41`
- **Impact**: LOW (~150ms per commit, ~450ms for 3 items)
- **Problem**: Each `git cat-file -t $hash` spawns a new git process (~50-100ms overhead)
- **Fix**: Batch: `git cat-file --batch-check` with all hashes piped via stdin
- **Effort**: Low (30 min)
- **Scales**: Becomes HIGH impact if backlog grows to 20+ items

### M-7: score-auto.ps1 — Byte-Level Corruption Scan (Line 44)
- **File**: `scripts/score-auto.ps1:44`
- **Impact**: MEDIUM (~500ms for 70 files)
- **Problem**: Reads ALL bytes of ALL 70 SKILL.md files and does byte-by-byte scanning in PowerShell (slow loop)
- **Fix**: Use `[System.IO.File]::ReadAllText` + regex for mojibake patterns instead of byte scanning:
  ```powershell
  $content = [IO.File]::ReadAllText($f.FullName)
  if ($content -match '[Ã][\x80-\xBF]') { $corrupted++ }
  ```
- **Effort**: Low (30 min)

### M-8: ponytail-audit.ps1 — Full File Read for Pattern Match
- **File**: `scripts/ponytail-audit.ps1:54-55`
- **Impact**: LOW (~200ms for full repo scan)
- **Problem**: `Get-Content -Raw` reads entire file content, then splits by line, then filters. For large files this is wasteful when only searching for `ponytail:` pattern
- **Fix**: Use `Select-String -Path $files -Pattern 'ponytail:'` directly (streams, doesn't load full content)
- **Effort**: Trivial (15 min)

### M-9: verify.ps1 E2 — Secrets Scan Reads All Files Sequentially
- **File**: `scripts/verify.ps1:55-61`
- **Impact**: LOW-MEDIUM (~300ms)
- **Problem**: Iterates 4 directories, reads every .ps1/.md/.psm1 file with `ReadAllText`, checks 17 patterns sequentially per file
- **Fix**: Use `Select-String` with combined pattern across all dirs in one call
- **Effort**: Low (30 min)

### M-10: run-improvement-cycle.ps1 — Sequential Sub-Script Calls
- **File**: `scripts/run-improvement-cycle.ps1:42,46`
- **Impact**: LOW (~2s)
- **Problem**: Calls cross-ref-check.ps1 then run-dreaming.ps1 sequentially
- **Fix**: Run in parallel
- **Effort**: Low (30 min)

---

## Low Bottlenecks (Top 10)

### L-1: score-auto.ps1 — `Measure-Object` Pipeline Overhead
- **File**: `scripts/score-auto.ps1:52,55,80,84`
- **Impact**: LOW (~50ms total)
- **Problem**: `Measure-Object -Average` and `Measure-Object -Sum` create pipeline objects. Called 4+ times
- **Fix**: Use `[Linq.Enumerable]::Average()` or manual sum/count for hot paths
- **Effort**: Low

### L-2: benchmark.ps1 — Get-Content Per Skill in Loop
- **File**: `scripts/benchmark.ps1:6`
- **Impact**: LOW (~200ms for 69 skills)
- **Problem**: `Get-Content $m -Raw` called per skill in a PSForEach loop
- **Fix**: Use `[IO.File]::ReadAllText()` (already used elsewhere) — avoids cmdlet overhead
- **Effort**: Trivial

### L-3: trend.ps1 — Get-Content + ConvertFrom-Json Per Snapshot
- **File**: `scripts/trend.ps1:14`
- **Impact**: LOW (~100ms per snapshot file)
- **Problem**: Each snapshot file read + parsed individually in a loop
- **Fix**: Minor — use `ConvertTo-JsonFast` from lib/ (already exists but unused)
- **Effort**: Trivial

### L-4: close-session.ps1 — Get-Content + Set-Content for BITACORA
- **File**: `scripts/close-session.ps1:38-39`
- **Impact**: LOW (~30ms)
- **Problem**: Reads entire BITACORA.md, prepends line, writes entire file back
- **Fix**: Use `Add-Content` with `-Position Beginning` (not natively supported) or accept the pattern — it's fine for a file this size
- **Effort**: N/A (acceptable pattern)

### L-5: batch.ps1 — Get-Content + Regex for Batch Number
- **File**: `scripts/batch.ps1:35-38`
- **Impact**: LOW (~30ms)
- **Problem**: Reads entire BITACORA.md, runs regex match collection, then Measure-Object
- **Fix**: Minor — could use `Select-String` with `-List` but negligible savings
- **Effort**: N/A

### L-6: session-miner.ps1 — Get-Content + Regex Per File
- **File**: `scripts/session-miner.ps1:11-23`
- **Impact**: LOW (~100ms)
- **Problem**: Three separate `Get-Content -Raw` calls for 3 files, each followed by regex parsing
- **Fix**: Minor — files are small (<100KB typically)
- **Effort**: N/A

### L-7: health-check.ps1 — Resolve-Path in Test-Junction
- **File**: `scripts/health-check.ps1:37`
- **Impact**: LOW (~10ms per call)
- **Problem**: `Resolve-Path $ExpectedTarget` called inside junction check — could be pre-computed
- **Fix**: Pre-compute expected target path once before loop
- **Effort**: Trivial

### L-8: sync-vmk.ps1 — ConvertTo-Json Depth 10 for Comparison
- **File**: `scripts/sync-vmk.ps1:51-63`
- **Impact**: LOW (~50ms)
- **Problem**: Serializes JSON to depth 10 just to compare strings. Could use structural comparison
- **Fix**: Compare section hashes (like check-config-drift.ps1 does) instead of full serialization
- **Effort**: Low

### L-9: run-dreaming.ps1 — Line-by-Line File Read with String Operations
- **File**: `scripts/run-dreaming.ps1:51-77,108-129`
- **Impact**: LOW (~100ms)
- **Problem**: Uses `[System.IO.File]::ReadLines()` (good!) but then does multiple string operations per line
- **Fix**: Already reasonably optimized. Minor: could use `switch -Regex` for faster pattern matching
- **Effort**: N/A

### L-10: tokenize-all.ps1 — Python Subprocess Per Skill
- **File**: `scripts/tokenize-all.ps1:38`
- **Impact**: LOW (~200ms per skill for Python startup)
- **Problem**: Spawns a Python process per skill for tiktoken counting. Already uses ForEach-Object -Parallel (good!)
- **Fix**: Batch all files into a single Python invocation that outputs CSV
- **Effort**: Low (1 hour)

---

## Quick Wins (< 1 hour each)

| # | Fix | File | Effort | Savings |
|---|-----|------|--------|---------|
| 1 | Cache `Get-ChildItem $cd -Directory` in cross-ref-check.ps1 | cross-ref-check.ps1 | 15 min | ~600ms |
| 2 | Convert `$al` array to hashtable in cross-ref-check.ps1 | cross-ref-check.ps1:28 | 10 min | ~80ms |
| 3 | Cache .project.json read in score-auto.ps1 | score-auto.ps1:20,88 | 10 min | ~50ms |
| 4 | Eliminate duplicate Test-Path BITACORA.md | score-auto.ps1:47-48 | 5 min | ~20ms |
| 5 | Use Select-String in ponytail-audit.ps1 instead of Get-Content | ponytail-audit.ps1:54 | 15 min | ~150ms |
| 6 | Single-pass Select-String for crypto/secrets/comments | score-auto.ps1:24,26,33 | 1 hour | ~300ms |
| 7 | Cache Get-ChildItem results at top of score-auto.ps1 | score-auto.ps1:14-16,30,57 | 30 min | ~400ms |
| 8 | Use ConvertTo-JsonFast (already exists!) in trend.ps1 | trend.ps1:14 | 10 min | ~50ms |
| 9 | Pre-compute Resolve-Path in health-check.ps1 | health-check.ps1:37 | 5 min | ~10ms |
| 10 | Collect junction stats in single pass in check-skill-drift.ps1 | check-skill-drift.ps1:38-62 | 30 min | ~200ms |

**Total Quick Win Savings**: ~1.9 seconds per `!score` invocation
**Total Quick Win Effort**: ~3.5 hours

---

## Strategic Improvements (Architectural Changes)

### S-1: Introduce Script Result Cache Layer
**Problem**: Every invocation of score-auto.ps1 re-computes everything from scratch.
**Solution**: Implement a TTL-based cache (like check-skill-drift.ps1 already does with drift-cache.json):
- Cache file: `.learnings/score-cache.json`
- TTL: 5 minutes (configurable via env var)
- Store: dimension scores + timestamp + input hashes
- On hit: return cached JSON immediately
- **Impact**: Reduces `!score` from ~15s to <100ms on cache hit
- **Effort**: 3-4 hours
- **Precedent**: check-skill-drift.ps1 already implements this pattern (lines 13-26)

### S-2: Unified File Enumeration Service
**Problem**: Every script independently enumerates `.agents/skills/`, `scripts/`, etc.
**Solution**: Create a shared module `scripts/lib/file-enumerator.psm1` that:
- Caches directory listings with filesystem watcher invalidation
- Provides `Get-SkillDirs`, `Get-ScriptFiles`, `Get-SkillMdFiles` as fast lookups
- Used by all scripts that need these enumerations
- **Impact**: Eliminates ~40% of redundant I/O across all scripts
- **Effort**: 4-6 hours
- **Risk**: MEDIUM — changes many files

### S-3: Parallel Pipeline for verify.ps1
**Problem**: E1/E2/E3 checks run sequentially (~4s total).
**Solution**: Restructure as parallel job pipeline:
```powershell
$profiles = switch ($ProfileName) { 'All' { @('E1','E2','E3') } default { @($ProfileName) } }
$jobs = $profiles | ForEach-Object { Start-Job -ScriptBlock $checkMap[$_] -ArgumentList $Root }
$results = $jobs | Wait-Job | Receive-Job
```
- **Impact**: Reduces verify All from ~4s to ~2s
- **Effort**: 2-3 hours

### S-4: Migrate score-auto.ps1 to Incremental Scoring
**Problem**: All 13 dimensions computed every time, even when only 1 changed.
**Solution**: Track per-dimension input hashes. Only recompute dimensions whose inputs changed:
- PA: hash of skill dir listing + README.md existence + .project.json existence
- Sec: hash of script files content
- DC: hash of skills/ dir listing
- etc.
- **Impact**: Reduces typical `!score` from ~15s to ~3s (only 2-3 dims usually change)
- **Effort**: 6-8 hours
- **Risk**: MEDIUM — complex state management

### S-5: Pre-Session Health Check — Already Parallelized (Validate)
**Status**: AGENTS.md section J already specifies parallel execution for step 1:
```
1. Parallel block: git status + check-skill-drift + health-check
```
**Action**: Verify this is actually implemented in the agent's runtime (opencode MCP layer), not just documented. If not enforced, the documented parallelism is aspirational.
- **Impact**: Ensures documented ~2s savings are realized
- **Effort**: 1 hour (verification only)

---

## Metrics Baseline

| Metric | Current (estimated) | Target | Improvement |
|--------|-------------------|--------|-------------|
| `!score` wall-clock time | ~15-20s | ~8-10s | 50% reduction |
| `!score` with cache hit | N/A | <100ms | New capability |
| `verify -ProfileName All` | ~4-6s | ~2-3s | 50% reduction |
| `cross-ref-check.ps1` | ~1.5-2s | ~0.8-1s | 40% reduction |
| `check-skill-drift.ps1` (cold) | ~1-1.5s | ~0.7-1s | 30% reduction |
| `check-skill-drift.ps1` (cached) | <100ms | <100ms | Already optimal |
| `health-check.ps1` | ~200-500ms | ~200-500ms | Already fast |
| Pre-session health chain | ~2-3s | ~1-2s | 30-50% reduction |
| File I/O operations per `!score` | ~80-100 | ~30-40 | 60% reduction |
| Get-ChildItem calls per `!score` | ~12-15 | ~4-5 | 65% reduction |

### Token/Size Metrics (from .project.json)

| Dimension | Current | Notes |
|-----------|---------|-------|
| Scripts | 43 files, avg 5.5KB | Healthy |
| Skills | 69 total, avg 1.8KB | Well compressed |
| AGENTS.md | ~15KB (estimated) | Monitor for growth |
| Total skill bytes | 124,702 | <125KB target met |
| Skills >3KB | 0 | Excellent |
| Scripts >50KB | 0 | Excellent |

---

## Implementation Priority

### Phase 1 — Quick Wins (Day 1, ~3.5 hours)
1. Cache directory enumerations in cross-ref-check.ps1
2. Convert array lookups to hashtables in cross-ref-check.ps1
3. Eliminate redundant Test-Path/Get-Content in score-auto.ps1
4. Use Select-String in ponytail-audit.ps1
5. Consolidate Get-ChildItem calls in score-auto.ps1

### Phase 2 — Parallel Execution (Day 2, ~4 hours)
6. Parallelize sub-script chain in score-auto.ps1 (C-1)
7. Parallelize E1/E2/E3 in verify.ps1 (C-5)
8. Single-pass Select-String in score-auto.ps1 (C-4)

### Phase 3 — Strategic (Week 2, ~12 hours)
9. Implement score cache layer (S-1)
10. Create shared file enumerator module (S-2)
11. Incremental scoring (S-4)

---

## Appendix: File I/O Heat Map

Hottest files (most frequently read across all scripts):

| File | Read By | Times |
|------|---------|-------|
| `.agents/skills/*/SKILL.md` | score-auto, cross-ref, check-skill-drift, benchmark, ponytail-audit, tokenize-all | 6 scripts |
| `scripts/*.ps1` | score-auto, verify, pssa-gate, ponytail-audit, benchmark | 5 scripts |
| `.project.json` | score-auto (2x), verify, inter-track | 3 scripts |
| `BITACORA.md` | score-auto, close-session, batch | 3 scripts |
| `CYCLE.md` | check-backlog-integrity, verify, run-improvement-cycle | 3 scripts |
| `ANTI-PATTERN-CATALOG.md` | session-miner, run-dreaming, cross-ref-check | 3 scripts |
| `opencode.json` | check-config-drift, sync-vmk, check-skill-drift | 3 scripts |

---

*Report generated by gentleman-performance. All estimates based on static analysis of 44 scripts. Runtime profiling recommended for validation.*
