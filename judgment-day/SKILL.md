---
name: judgment-day
description: >
  Parallel adversarial review protocol: two blind judge sub-agents review the same target,
  findings synthesized, fixes applied, re-judged until both pass or escalate after 2 iterations.
  Trigger: "judgment day", "judgment-day", "review adversarial", "dual review",
  "doble review", "juzgar", "que lo juzguen".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.4"
---

## When
- User triggers with phrases above
- After significant implementations pre-merge
- High-confidence review needed; cost of production bug > cost of two review rounds

## Protocol

### P0: Skill Resolution (BEFORE judges)
Follow `_shared/skill-resolver.md`:
1. `mem_search(query: "skill-registry", project: "{project}")` → fallback `.atl/skill-registry.md` → skip if none
2. Match relevant skills by code context (extensions/paths) + task context
3. Build `## Project Standards (auto-resolved)` block with compact rules
4. Inject into BOTH Judge prompts AND Fix Agent prompt (identical)

**No registry**: warn user, proceed with generic review.

### P1: Parallel Blind Review
- Launch TWO sub-agents via `delegate` (async, parallel)
- Same target, work independently, neither knows about the other
- NEVER review yourself — only coordinate

### P2: Verdict Synthesis
After both `delegation_read` return:

| Status | Meaning | Action |
|--------|---------|--------|
| Confirmed | Both agents found it | Fix immediately |
| Suspect A/B | One agent only | Triage |
| Contradiction | Disagree | Flag for manual decision |

### P3: Warning Classification
```
WARNING (real)        → Bug, data loss, security hole in normal usage → FIX
WARNING (theoretical) → Contrived scenario, corrupted input → Report as INFO only
```
Question: "Can a normal user trigger this?" YES→real, NO→theoretical.

### P4: Fix and Re-judge
1. Confirmed CRITICALs/real WARNINGs → delegate Fix Agent
2. Fix complete → re-launch BOTH judges in parallel
3. **After 2 fix iterations** → ask user: "Continue iterating?" YES→continue, NO→ESCALATED
4. Both clean → APPROVED ✅

### P5: Convergence Threshold
**Round 1**: Present verdict, ask user to confirm fixes. Re-judge with full scope.

**Round 2+**: Re-judge only for confirmed CRITICALs.
- Real WARNINGs (confirmed) → Fix inline, NO re-judge
- Theoretical WARNINGs → Report as INFO, no fix
- SUGGESTIONS → Fix inline if trivial

**APPROVED**: 0 confirmed CRITICALs + 0 confirmed real WARNINGs.

## Decision Tree
```
User: "judgment day"
├─ Scope clear? → NO: ask user | YES: continue
├─ P0: Resolve skills → build Project Standards block
├─ Launch Judge A + Judge B (parallel delegate)
├─ delegation_read both → synthesize verdict
├─ No issues? → APPROVED ✅
└─ Issues found? → present verdict table
    ├─ Ask: "Fix confirmed issues?" → YES: Fix Agent → re-launch judges (Round 2)
    │   ├─ Clean → APPROVED ✅
    │   └─ Still issues → Fix Agent (Round 3) → re-launch judges
    │       ├─ Clean → APPROVED ✅
    │       └─ Still issues → Ask user: continue?
    └─ NO → ESCALATED ⚠️
```

## Sub-Agent Prompts

### Judge Prompt (identical for A and B)
```
You are an adversarial code reviewer. Find problems ONLY.

## Target
{files, feature, architecture, component}

{if P0 resolved}
## Project Standards (auto-resolved)
{matching compact rules}

## Criteria
- Correctness: logical errors?
- Edge cases: unhandled inputs/states?
- Error handling: caught, propagated, logged?
- Performance: N+1, inefficient loops, allocations?
- Security: injection, secrets, auth?
- Naming: matches project patterns + Project Standards?

## Return
Severity: CRITICAL | WARNING (real) | WARNING (theoretical) | SUGGESTION
File: path (line N)
Description: what + why
Suggested fix: one-line intent

WARNING rule: "Can normal user trigger this?" YES→real, NO→theoretical.
**Skill Resolution**: {injected|fallback-registry|fallback-path|none}

No issues → "VERDICT: CLEAN"
Be adversarial. No praise, no summary.
```

### Fix Agent Prompt
```
Surgical fix agent. Apply ONLY confirmed issues.

## Confirmed Issues
{findings table}

{if P0 resolved}
## Project Standards (auto-resolved)
{matching compact rules}

## Rules
- Fix ONLY confirmed issues — no refactoring beyond scope
- Scope rule: fix same pattern in ALL affected files
- After each fix: file, line, what done

## Fixes Applied
- [file:line] — {what fixed}

**Skill Resolution**: {injected|fallback-registry|fallback-path|none}
```

## Output Format
```markdown
## Judgment Day — {target}
### Round {N} — Verdict

| Finding | Judge A | Judge B | Severity | Status |
|---------|---------|---------|----------|--------|
| Missing null check in auth.go:42 | ✅ | ✅ | CRITICAL | Confirmed |
| Race condition in worker.go:88 | ✅ | ❌ | WARNING | Suspect (A) |
| Error swallowed in db.go:201 | ✅ | ✅ | WARNING | Confirmed |

**Confirmed**: 1 CRITICAL, 1 WARNING | **Suspect**: 1 WARNING

### Fixes Applied
- `auth.go:42` — Added nil check before dereference
- `db.go:201` — Propagated error

### Re-judgment
- Judge A: CLEAN ✅ | Judge B: CLEAN ✅

### JUDGMENT: APPROVED ✅
```

### Escalation Format
```markdown
## Judgment Day — {target}
### JUDGMENT: ESCALATED ⚠️

User stopped after {N} iterations. Manual review required.

### Remaining
| Finding | A | B | Severity |
| {desc} | ✅ | ✅ | CRITICAL |
```

## Skill Resolution Feedback
After every delegation, check `**Skill Resolution**` field:
- `injected` → ✅
- `fallback-*` or `none` → re-read registry, inject in subsequent delegations

## Language
- Spanish → Rioplatense: "Juicio iniciado", "Aprobado", "Escalado"
- English: "Judgment initiated", "Approved", "Escalated"

## Blocking Rules (MANDATORY)
1. NO APPROVED until: Round 1 CLEAN, OR Round 2: 0 CRITICALs + 0 real WARNINGs
2. NO git push/commit after fixes until re-judgment completes
3. NO session summary/"done" until all JDs terminal (APPROVED/ESCALATED)
4. After Fix Agent → IMMEDIATELY re-launch judges
5. Multiple JDs independent — completion of one doesn't skip rounds on others

## Self-Check (before terminal action)
1. List every active JD target
2. Each APPROVED or ESCALATED?
3. Any JD with fixes → did Round 2 run?
4. Round 2 found issues → asked user? Respected answer?

Any "no" → go back, complete step.

## Rules
- Orchestrator NEVER reviews — only launches judges, reads results, synthesizes
- Judges: `delegate` (async, parallel)
- Fix Agent: separate delegation
- Custom criteria → include in BOTH judges
- Unclear scope → ask before launching
- After 2 iterations → ASK user, never auto-escalate
- Wait for BOTH judges before synthesizing

## Commands
Pure orchestration — `delegate()` + `delegation_read()` only.
