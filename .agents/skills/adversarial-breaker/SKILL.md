---
name: adversarial-breaker
description: "Adversarial verification protocol — orchestrator loads this skill to run fixer→breaker chain. Breaker is an independent offensive agent."
triggers: "adversarial, breaker, !breaker, verify fix, romper, verificar fix, try to break, offensive verification"
license: Apache-2.0
metadata:
  tags: [engineering, verification, adversarial]
  author: gentleman-vMK
  version: "3.3"
  changelog: "3.3: Token-save skip — <10 line config-only diffs skip breaker. Pre-regression check — stash+test before launch catches broken builds. Versionable surface — `.agents/attack-surface.{project}.md` override. Test case generation — FAIL attacks produce reproducible test cases via Engram"
  dependencies: [subagent-isolation, engram-protocol]
  config_refs: review-rules.jsonc
---

# Adversarial Breaker

Orchestrator runs independent adversarial check after fix. Builder ≠ Evaluator.

## When to Invoke

Invoke: fixer claims complete + ROJA-zone (always) or AMARILLA touching auth/storage/API + not pure config/whitespace/lock-file.
Skip: VERDE-zone, non-code diffs, comments-only, docs-only.
Skip (token save): diff <10 lines AND touches only config/whitespace/lock-file/comments/docs — even in ROJA-zone, breaker is optional.

## Protocol

1. **Gather artifacts**: diff, changed_files, fixer_claims, test_results, zone, pipeline_mode → Bundle
2. **Engram feedback**: query `topic_key: "breaker/{target}"`. Past findings → inject as `## Past Attack Context`
3. **Zone check**: from `review-rules.jsonc`. AMARILLA touching auth/storage/API → escalate ROJA
4. **Select profiles**: from `references/profiles/` by file extensions. If `.agents/attack-surface.{project}.md` exists → inject as reference
5. **Pre-regression**: `git stash` fix → run tests → `git stash pop`. Tests break → flag `PRE-BREAK`
6. **Dispatch**: diff >50 lines OR ROJA-zone → **Parallel Break-7** (3 specialists). Else → single
7. **Launch**: inject `references/breaker-briefing.md` + profile(s) + past context + bundle. Parallel: specialized briefing
8. **Parse**: validate 4-field format. Parallel → merge. <3 attempts → FAIL, re-run
9. **Calibrate**: score depth, relevance, coverage, specificity → see §Quality Calibration
10. **Verdict**: calibration-adjusted, accounts for PRE-BREAK flag
11. **Round 2**: if FIX → see below
12. **Record**: Engram + generated test cases → see §Engram Integration

## Engram Integration

Breaker saves AND reads from Engram — cross-session learning.

### Query (Step 2)

```
mem_search(query: "breaker/{target}", topic_key: "breaker/{target}")
```

If findings → inject into briefing as `## Past Attack Context` before Phase Selection:

```
## Past Attack Context
This target was broken {N} time(s) before:
- R{round} ({date}): {finding summary} — {vector}

Focus extra attention on these previously-exploited vectors.
```

### Record (Step 12) & Test Case Generation

```yaml
title: "breaker:{target}:R{round}"
type: discovery
topic_key: "breaker/{target}"
content:
  what: "Breaker round {N}/{max} on {target}"
  why: "{pipeline_mode} · {zone}-zone · {changed_files_count} files"
  where: "{changed_files}"
  learned:
    - "Attack vectors tried: {vectors}"
    - "Findings: {N} PASS, {N} FAIL"
    - "Calibration: {depth}/10 · {relevance}/10 · {coverage}/10 · {specificity}/10"
    - "Verdict: {verdict}"
```

For EVERY FAIL attack, generate reproducible test case:

```
## Test Case: {brief name}
- Input: {concrete value that broke the code}
- Expected: {what should happen}
- Actual: {what happened — the bug}
- Code path: {file:line of the vulnerability}
- Regression guard: {assertion that would catch this in CI}
```

Store under `topic_key: "breaker/{target}/testcase"`. 3+ test cases for same target → suggest dedicated test via immune-system.

## Quality Calibration (Step 9)

4-dimension score (not pass/fail, adjusts verdict confidence):

| Dimension | 1-3 (Weak) | 4-7 (Adequate) | 8-10 (Strong) |
|-----------|-----------|----------------|----------------|
| **Depth** | Superficial: "pass null → see if crashes" | Variations: null, empty, boundary | Chained: null+race+injection |
| **Relevance** | Generic, unrelated to diff | Matches code type/domain | Targets specific change |
| **Coverage** | <50% applicable phases | 50-80% | All applicable + P7/P6 |
| **Specificity** | "SQL injection" — no detail | Specific input: `' OR 1=1--` | Full trace: input→path→expected vs actual |

### Adjustment

| Avg Score | Effect |
|-----------|--------|
| ≥8 | **Confirm** — verdict stands |
| 5-7 | **Cautious** — escalate borderline FIX→BLOCK, require user nod |
| <5 | **Override** — downgraded to FAIL, re-run with stricter briefing |

## Parallel Break-7 (Step 6-8)

Complex (ROJA-zone OR diff >50 lines) → 3 specialists in parallel. Same bundle, specialized briefing.

### Dispatch

| Condition | Mode |
|-----------|------|
| ROJA-zone (any size) | **Parallel** (3 specialists) |
| AMARILLA + diff >50 | **Parallel** (3 specialists) |
| AMARILLA + diff ≤50 | **Single** (generalist) |
| VERDE | Skip |

### Specializations

| Breaker | Focus | Phases |
|---------|-------|--------|
| **Security** | Injection, auth, data leakage, path traversal | P1, P3, P6, P7 |
| **Logic** | Edge cases, concurrency, type confusion, off-by-one | P1, P2, P4, P5, P6 |
| **Regression** | Caller impact, side effects, contract breaks, test gaps | P7 + caller tracing |

### Merge (Step 8)

1. **Collect** 4-field output from each
2. **Deduplicate** overlapping findings
3. **Classify**: any CRITICAL → BLOCK. 2+ breakers same area → BLOCK
4. **Combine** attacks into unified numbered list
5. **Pass to calibration** as single merged output

**Failure**: 1 timeout → continue with 2. 2+ timeouts → fallback to single generalist. All 3 timeout → FAIL → escalate.

## Breaker Output & Verdicts

**Format**: Attack Attempts (numbered), Attack Vector, Result (PASS/FAIL), Edge Cases Found.
**Summary**: `AB-{target} | Round:{N}/2 | Attacks:{n} | SAFE/BROKEN | VERDICT: {verdict}`

All PASS→APPROVED | 1-2 minor→FIX | Critical→BLOCK→human | <3 attempts/malformed→FAIL | Timeout/R2 breaks→ESCALATE→human

## Round 2 & Escalation

**Round 2**: New `git diff` after fixer. Pass BOTH diffs — check R1 resolved + new issues. Re-inject with `## Round 2 — Focus on whether these specific issues were fixed: {R1 findings}`. Max 2 rounds.

**Escalation** (BLOCK/ESCALATE): Target, Rounds, Pipeline, Chain Evidence (R1/R2→verdict), Blocker, Recommendation (revert/redesign/manual review/merge first).

## Integration & Anti-Patterns

| Skill | Relation |
|-------|----------|
| quality-gate | BEFORE breaker |
| triple-verify | AFTER breaker |
| judgment-day | Independent — 4R vs offensive |
| subagent-isolation | Fresh context, artifact bundle |
| external-auditor | On BLOCK → confirmation |
| immune-system | Repeated breaks → permanent fix |

### Versionable Surface

Projects override via `.agents/attack-surface.{project}.md` (Step 4) — merged, not replaced. Similarly `.agents/breaker-profiles/{project}/` for technology profiles.

| Anti-Pattern | Fix |
|---|---|
| Breaker trusts fixer | Verify from artifacts |
| No attempts declared | Enforce methodology |
| 3+ rounds | Cap 2 → escalate |
| Before quality-gate | quality-gate first |
| 4R review | Offensive, not evaluative |
| Happy path only | Test adversarial inputs |
| Non-code diffs | Skip breaker |
| Tiny diffs | Token-save skip (<10 lines config-only) |
| Skip pre-regression | Always stash+test before breaker |
| Ignore test case gen | Record FAIL attacks as reproducible tests |
| Generic surface on tailored project | Create `.agents/attack-surface.{project}.md` |

[breaker-briefing](references/breaker-briefing.md) · [attack-surface](references/attack-surface.md) · [profiles](references/profiles/) · [subagent-isolation](../subagent-isolation/SKILL.md) · [quality-gate](../quality-gate/SKILL.md) · [triple-verify](../triple-verify/SKILL.md) · [judgment-day](../judgment-day/SKILL.md)
