---
name: dreaming
description: "Cross-session pattern extraction via Engram. Run via !dream — not automatic."
triggers: "!dream, dreaming, patrones, memory review, session end, !close, pattern extraction"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Only on explicit request (`!dream`) or user asking. Recommended weekly or after milestone.
**Auto-pattern**: same error 3x → `auto-pattern-detector.ps1` → propose anti-pattern to immune-system.

## MODES
| Mode | Action |
|------|--------|
| **Quick** `!dream quick` | `mem_context` + `mem_search` + `auto-pattern-detector.ps1` |
| **Harvest** `!close` | `mem_session_summary` + extract patterns |
| **Full** `!dream` (weekly) | `mem_search` + detector + stats. ≥2→anti-pattern. ≥3→AGENTS.md rule |
| **Feed** `!dream feed` | Extract patterns → JSON for skill-graph |
| **Wisdom review** `!dream full` (monthly) | `wisdom-demote.ps1 -All -DryRun` → report → ask → proceed |

## SCRIPTS
`run-dreaming.ps1` · `session-miner.ps1` · `auto-pattern-detector.ps1` · `learning-stats.ps1` · `wisdom-store.ps1` · `wisdom-loader.ps1` · `wisdom-forge.ps1` · `wisdom-demote.ps1` · `pattern-guard.ps1`

## SKILL-GRAPH BRIDGE
```powershell
.\scripts\run-dreaming.ps1 -Mode feed -OutputPath .learnings\skill-graph-patterns.json
.\scripts\skill-graph.ps1 -Task "fix auth bug" -PatternsFile .learnings\skill-graph-patterns.json
```
Pattern format: `{ keywords: [], boost: "skill-name", reason: "..." }`

## RECALL
Extract 3-5 keywords → `mem_search(query="<keywords>", limit=3)` → apply past learnings.

## ANTI-PATTERNS
❌ Isolated sessions · fix-only-no-document · every session fresh · no memory scan
✅ Cross-session patterns · permanent immunity · curate signal/drop noise · scan memory first

## IMMUNE INTEGRATION
When `auto-pattern-detector.ps1` returns `PATTERNS_FOUND`: each proposal → immune-system (detect→diagnose→document→immunize). Same error 3+ times → mandatory catalog + AGENTS.md rule. Cross-ref with `learning-stats.ps1` before promotion.

## Auto-Dream Trigger
At session close (`!close`), count new memories since last dream:
1. `mem_search(type="error|bugfix|decision|discovery", limit=10)` — filter results after last dream timestamp.
2. If **>5 new memories**: auto-execute Quick scan protocol.
3. If **≤5**: skip.
4. After auto-dream, record timestamp: `mem_save(type="config", topic_key="dreaming/last-auto-dream", content="Last auto-dream: {timestamp}")`.

## Refs
immune-system · cross-project-wisdom · auto-metrics · session-resume · bitacora

## EXAMPLES

### Example 1: Quick Mode — Weekly Pattern Scan
```powershell
# User runs: !dream quick
# Agent executes:
mem_context(scope=project)
mem_search(query="bugfix OR error OR decision", limit=20)
.\scripts\auto-pattern-detector.ps1 -Since (Get-Date).AddDays(-7)
```
**Output**: 3 recurring "N+1 query in list endpoints" → promotes to immune-system catalog.

### Example 2: Harvest Mode — Session Close
```powershell
# User runs: !close
# Agent executes:
mem_session_summary(content="## Goal\nRefactor auth to JWT\n## Discoveries\n- Refresh token rotation requires separate store\n- Cookie httpOnly+secure mandatory\n## Accomplished\n- ✅ JWT middleware in src/auth/middleware.ts\n- ✅ Login/logout routes updated\n## Next Steps\n- Add rate limiting to /refresh\n## Relevant Files\n- src/auth/middleware.ts\n- src/routes/auth.ts")
mem_search(type="error|bugfix|decision", limit=10)
# Auto-dream triggers if >5 new memories since last dream
```

### Example 3: Full Mode — Monthly Deep Review
```powershell
# User runs: !dream (weekly) or !dream full (monthly)
# Agent executes:
mem_search(query="pattern OR learning OR discovery", limit=50)
.\scripts\learning-stats.ps1 -Period monthly
.\scripts\auto-pattern-detector.ps1 -All
# If ≥2 patterns of same class → anti-pattern entry
# If ≥3 patterns of same class → AGENTS.md rule
```

### Example 4: Feed Mode — Skill Graph Enrichment
```powershell
# User runs: !dream feed
# Agent executes:
.\scripts\run-dreaming.ps1 -Mode feed -OutputPath .learnings\skill-graph-patterns.json
# Output JSON structure:
{
  "patterns": [
    { "keywords": ["auth", "jwt", "refresh"], "boost": "auth-hardening", "reason": "Recurring JWT refresh token issues across 4 sessions" },
    { "keywords": ["n+1", "query", "list"], "boost": "perf-profiling", "reason": "N+1 detected in 3 list endpoints" }
  ]
}
# Then: skill-graph.ps1 -Task "fix auth bug" -PatternsFile .learnings\skill-graph-patterns.json
```

### Example 5: Wisdom Review — Cross-Project Demotion
```powershell
# User runs: !dream full (monthly)
# Agent executes:
.\scripts\wisdom-demote.ps1 -All -DryRun
# Report shows: 12 patterns ready for demotion to cross-project-wisdom
# Agent asks user: "Proceed with demotion of 12 patterns?"
# On confirmation: .\scripts\wisdom-demote.ps1 -All
```

## TESTING SCENARIOS

### Test 1: Auto-Dream Trigger at Session Close
**Setup**: 7 new memories (3 bugfix, 2 decision, 2 discovery) since last dream
**Action**: Run `!close`
**Expected**: Quick scan executes automatically; `mem_save` records new dream timestamp
**Verify**: `mem_search(query="dreaming/last-auto-dream", type="config")` returns recent timestamp

### Test 2: Pattern Detection Thresholds
**Setup**: Create 3 memories with same error signature "timeout connecting to redis"
**Action**: Run `!dream quick`
**Expected**: `auto-pattern-detector.ps1` returns `PATTERNS_FOUND` with count=3
**Verify**: Each proposal routes to immune-system; AGENTS.md rule created for "Redis connection timeout"

### Test 3: Feed Mode JSON Output Validation
**Setup**: Run `!dream feed` after sessions with auth, perf, and caching patterns
**Action**: Read `.learnings\skill-graph-patterns.json`
**Expected**: Valid JSON with `patterns` array; each entry has `keywords[]`, `boost`, `reason`
**Verify**: `skill-graph.ps1` accepts file and boosts relevant skills for test task

## EDGE CASES

### Edge Case 1: No Memories Since Last Dream
**Scenario**: `mem_search` returns 0 new memories after filtering by last dream timestamp
**Behavior**: Auto-dream skips silently; no `mem_save` for timestamp update
**Handling**: Log "No new memories since last dream — skipping auto-dream"

### Edge Case 2: Corrupted Dream Timestamp
**Scenario**: `mem_search(topic_key="dreaming/last-auto-dream")` returns malformed content
**Behavior**: Treat as "never dreamed"; run full scan on all project memories
**Handling**: Wrap timestamp parse in try/catch; fallback to `Get-Date.AddDays(-30)`

### Edge Case 3: Concurrent Dream Executions
**Scenario**: User runs `!dream` while auto-dream from `!close` is still running
**Behavior**: Second invocation detects in-progress flag (file lock or memory flag); queues or skips
**Handling**: `mem_save(type="config", topic_key="dreaming/in-progress", content="true")` at start; clear at end

### Edge Case 4: Cross-Project Memory Contamination
**Scenario**: `mem_search(all_projects=true)` returns patterns from unrelated project
**Behavior**: Filter by `project` scope before pattern detection; only current project memories feed detector
**Handling**: Explicit `scope="project"` in all `mem_search` calls within dreaming scripts

## ANTI-PATTERNS

### Anti-Pattern 1: Dreaming Without Actionable Output
**Symptom**: Running `!dream` produces report but no immune-system entries, no AGENTS.md updates, no skill-graph feed
**Root Cause**: Thresholds too high, or patterns not specific enough to trigger promotion
**Fix**: Lower threshold to ≥2 for anti-pattern, ≥3 for AGENTS.md; ensure detector outputs structured proposals

### Anti-Pattern 2: Stale Dream Timestamp Blocking Auto-Dream
**Symptom**: Auto-dream never triggers because `last-auto-dream` timestamp is future-dated or corrupted
**Root Cause**: Clock skew, manual mem_save with wrong timestamp, or timezone mismatch
**Fix**: Validate timestamp on read; if > now or parse fails, reset to epoch (forces full scan next close)
