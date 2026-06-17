---
name: review-pipeline
description: "Skill stacking pipeline: quality-gate → 4R code-review → commit-crafter. One execution, three phases, gate-protected."
triggers: "review pipeline, pipeline, full review, preparar commit, ready to ship, listo para commit"
license: Apache-2.0
metadata:
  tags:
    - engineering
    - pipeline
    - review
  author: gentleman-vMK
  version: "1.0"
  dependencies:
    - quality-gate
    - code-review-agent
    - commit-crafter
---

Skill stacking pipeline that chains: **quality-gate → 4R code review → commit craft**.

Each phase feeds the next. If a phase fails (gate blocks), the pipeline stops and reports.

## When
- "ready to ship", "listo para commit", "full review", "review pipeline"
- Before creating a PR or pushing complex changes
- After implementing, before committing

## Pipeline

```
[Phase 0: Load review profile] ──> Engram (review-profile/{project})
       │
       ▼
[Phase 1: quality-gate] ──fail──> ❌ STOP (report gate failure)
       │ pass
       ▼
[Phase 2: 4R code review] ──fail──> ❌ STOP (report review findings)
       │ pass (4R all ≥ 6)
       ▼
[Phase 3: commit craft] ──> ✅ output commit message
```

## Phase Details

### Phase 0 — Load Review Profile
Before any gate, load the project's review profile from Engram:

```
mem_search("review-profile/{project}")
```

If profile exists:
- Note previous 4R scores (trend awareness)
- Pre-load known sensitive files and recurring patterns
- Focus extra attention on the R that most commonly fails for this project

If no profile exists (first review for this project):
- Skip adaptive phase
- Profile will be created after Phase 2

**Output to Phase 1**: `SENSITIVE_FILES` list + `FOCUS_R` (most common failure dimension).

### Phase 1 — Quality Gate
Load skill `quality-gate`. Run ALL gates:
- Tests MUST pass
- Secrets scan MUST be clean
- PSSA gate MUST pass

**Output to Phase 2**: `GATE_RESULT=pass` + test evidence.

### Phase 2 — 4R Code Review
Load skills `code-review-agent` (4R framework) + `judgment-day` (dual adversarial for high-risk).

Evaluate the diff with 4R framework — Risk/Readability/Reliability/Resilience.

**Decision**:
- All 4R ≥ 6 → PASS → continue to Phase 3
- Any 4R < 6 → FAIL → STOP, report severity per R. User must fix or explicitly override.
- Any 4R < 4 → BLOCKED → STOP. Cannot override.

**After scoring**: Save/update review profile in Engram:

```
mem_save(topic_key: "review-profile/{project}", type: "pattern", content: "4R scores, findings, recurring patterns")
```

**Output to Phase 3**: `REVIEW_PASSED=true` + key findings summary (informs commit scope).

### Phase 3 — Commit Craft
Load skill `commit-crafter`.

Craft conventional commit message from:
- `git diff --cached` (what changed)
- Review findings from Phase 2 (informs scope — e.g., `fix` if Reliability issue, `refactor` if Readability)

**Output**: Conventional commit message + suggested scope based on 4R findings.

## Output Format

```
## Pipeline: review-pipeline

### Phase 0: Review Profile ✅
- Project: {name}
- Previous 4R score: {score}/10
- Focus R: {R} (most common failure)
- Known sensitive files: {file1}, {file2}
- Recurring patterns to check: {pattern}

### Phase 1: Quality Gate ✅ / ❌
- Tests: X/X pass
- Secrets: clean / BLOCKED
- PSSA: pass / fail
→ Result: PASS / FAIL

### Phase 2: 4R Code Review ✅ / ❌
| R | Score | Verdict |
|---|-------|---------|
| Risk | X/10 | 🟢/🟡/🔴 |
| Readability | X/10 | 🟢/🟡/🔴 |
| Reliability | X/10 | 🟢/🟡/🔴 |
| Resilience | X/10 | 🟢/🟡/🔴 |
→ Result: PASS / FAIL ({lowest R} = {score})

### Phase 3: Commit Message ✅
{conventional commit message}

### Summary
Pipeline: ✅ ALL CLEAR / ❌ BLOCKED at Phase {N}
Duration: {phases completed}/{total phases}
```

## Rules
1. **Gate authority**: Phase 1 failure ALWAYS stops pipeline. No override.
2. **Review override**: Phase 2 failure at 4-5 range can be overridden with user confirmation (tagged as `review-override`). Below 4 cannot.
3. **Evidence chain**: Each phase emits structured output consumed by next. Never skip evidence.
4. **Scope injection**: Phase 3 SHOULD use Phase 2 findings to suggest scope (e.g., `fix(db)` if Reliability flagged DB error handling).
5. **Max runtime**: If any phase takes >3 tool calls without progress, ask user.

## Anti-patterns
| ❌ | ✅ |
|---|-----|
| Running phases in parallel (race conditions) | Sequential, each feeding the next |
| Ignoring gate failure and proceeding | Block at Phase 1 until resolved |
| Generic commit message ignoring review | Scope/type informed by 4R findings |
| Overriding 4R < 4 without user confirmation | Hard block — ask for explicit override |
