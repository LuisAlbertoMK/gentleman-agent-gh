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
Skip (token save): diff <10 lines AND touches only config/whitespace/lock-file/comments/docs — even in ROJA-zone, breaker is optional. Orchestrator decides based on context budget.

## Protocol

| Step | Action | Output |
|------|--------|--------|
| 1 | Gather artifacts: `diff`, `changed_files`, `fixer_claims`, `test_results`, `zone`, `pipeline_mode` | Bundle |
| 2 | **Engram feedback**: query `topic_key: "breaker/{target}"`. If past findings exist → inject into briefing as `## Past Attack Context` | Past findings (or ∅) |
| 3 | Zone check from `review-rules.jsonc`. AMARILLA touching auth/storage/API → escalate ROJA | Zone |
| 4 | Select attack profile(s) from `references/profiles/` by file extensions. **Versionable surface**: if `.agents/attack-surface.{project}.md` exists → inject as additional reference | Profile set |
| 5 | **Pre-regression check**: `git stash` the fix → run existing tests (`go test`/`npm test`/`pytest`/etc.) → `git stash pop`. If tests break after fix → flag `PRE-BREAK` in bundle as early warning | Pre-regression result |
| 6 | **Dispatch decision**: diff >50 lines OR ROJA-zone? → **Parallel Break-7** (3 specialists). Else → single breaker. See §Parallel Break-7 | Dispatch mode |
| 7 | Launch breaker(s): inject `references/breaker-briefing.md` + profile(s) + past context + artifact bundle. Parallel: inject specialized briefing (see §Parallel Break-7) | Breaker output(s) |
| 8 | Parse ALL outputs — validate 4-field format each. If parallel → merge into unified format. <3 attempts any → FAIL, re-run | Parsed + Merged |
| 9 | **Quality calibration** — score depth, relevance, coverage, specificity on merged output → see §Quality Calibration | Calibration score |
| 10 | Verdict → see below (calibration-adjusted, accounts for PRE-BREAK flag) | APPROVED/FIX/BLOCK/ESCALATE |
| 11 | Round 2 if FIX → see below | Updated verdict |
| 12 | Record to Engram with structured schema + generated test cases → see §Engram Integration | Memory + Tests |

## Engram Integration

Breaker saves AND reads from Engram — learning across sessions.

### Query (Step 2)

```
mem_search(query: "breaker/{target}", topic_key: "breaker/{target}")
```

If findings exist → inject into briefing as `## Past Attack Context` BEFORE the Phase Selection section. Format:

```
## Past Attack Context
This target was broken {N} time(s) before:
- R{round} ({date}): {finding summary} — {vector}
- R{round} ({date}): {finding summary} — {vector}

Focus extra attention on these previously-exploited vectors.
```

### Record (Step 12) & Test Case Generation

Use structured schema for reliable retrieval:

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

### Test Case Generation (from FAIL attacks)

For EVERY attack that resulted in FAIL (found a real bug), generate a **reproducible test case** and include it in the record:

```
## Test Case: {brief name}
- Input: {concrete value that broke the code}
- Expected: {what should happen}
- Actual: {what happened — the bug}
- Code path: {file:line of the vulnerability}
- Regression guard: {assertion that would catch this in CI}
```

Store these in Engram under `topic_key: "breaker/{target}/testcase"` for future regression suites.

When 3+ test cases accumulate for the same target, suggest creating a dedicated test file via immune-system skill.

## Quality Calibration (Step 9)

Score breaker output on 4 dimensions — **not** a pass/fail gate, but adjusts verdict confidence.

### Rubric

| Dimension | 1-3 (Weak) | 4-7 (Adequate) | 8-10 (Strong) |
|-----------|-----------|----------------|----------------|
| **Depth** | Attacks are superficial: "pass null → see if it crashes" | Attacks explore variations: null, empty, boundary | Attacks chain primitives: null+race+injection in sequence |
| **Relevance** | Generic attacks unrelated to diff logic | Attacks match the code type/domain | Attacks target the specific change, not the file |
| **Coverage** | <50% of applicable phases tried (of 7) | 50-80% of applicable phases | All applicable phases including regression (P7) + fuzzing (P6) |
| **Specificity** | "SQL injection" — no detail | Specific input given: `' OR 1=1--` | Full attack trace: input → code path → expected vs actual behavior |

### Calibration → Verdict Adjustment

| Avg Score | Effect |
|-----------|--------|
| ≥8 | **Confirm** — verdict stands as-is |
| 5-7 | **Cautious** — escalate borderline FIX→BLOCK, require explicit user nod |
| <5 | **Override** — verdict downgraded to FAIL. Breaker quality insufficient — re-run with stricter briefing or escalate |

### Recording

Include in Engram record (Step 12): `Calibration: {depth}/10 · {relevance}/10 · {coverage}/10 · {specificity}/10`

## Parallel Break-7 (Step 6-8)

For complex changes (ROJA-zone OR diff >50 lines), dispatch 3 specialized breakers in parallel instead of one generalist. Each sees the same artifact bundle but receives a specialized briefing.

### Dispatch Decision

| Condition | Mode | Rationale |
|-----------|------|-----------|
| ROJA-zone AND diff >50 lines | **Parallel** (3 specialists) | High risk + complex = cover all angles |
| ROJA-zone AND diff ≤50 lines | **Parallel** (3 specialists) | High risk = cover all angles, low token cost |
| AMARILLA-zone AND diff >50 lines | **Parallel** (3 specialists) | Moderate risk + complex = cover all angles |
| AMARILLA-zone AND diff ≤50 lines | **Single** (generalist) | Low complexity, one good breaker is enough |
| VERDE-zone | Skip — not invoked | — |

### Specializations

| Breaker | Focus | Phases | Briefing Addition |
|---------|-------|--------|-------------------|
| **Security** | Injection, auth, data leakage, path traversal | P1 (input), P3 (injection), P6 (fuzzing), P7 (regression) | `## Specialization: Security — focus on injection, auth bypass, data leaks. Assume worst.` |
| **Logic** | Edge cases, concurrency, type confusion, off-by-one | P1 (input), P2 (concurrency), P4 (error), P5 (logic), P6 (fuzzing) | `## Specialization: Logic — focus on edge cases, race conditions, contracts. Break assumptions.` |
| **Regression** | Caller impact, side effects, contract breaks, test gaps | P7 (regression) + reads changed files for callers | `## Specialization: Regression — trace all callers, identify contract changes. Break callers.` |

### Merge Protocol (Step 8)

After all 3 complete (or timeout at 120s):

1. **Collect** each breaker's output in 4-field format
2. **Deduplicate** overlapping findings (same vector, same root cause)
3. **Classify** severity: any CRITICAL from any breaker → BLOCK. 2+ breakers find issues in same area → BLOCK
4. **Combine** attack attempts into unified numbered list
5. **Pass to calibration** as single merged output

**Failure handling**: If 1 breaker times out → continue with 2. If 2+ time out → fall back to single generalist. If all 3 time out → FAIL → escalate.

## Breaker Output & Verdicts

**Breaker format**: Attack Attempts (numbered), Attack Vector (Input validation, Injection, Concurrency, Error handling, Logic), Result (PASS/FAIL per attempt), Edge Cases Found.

**Summary**: `AB-{target} | Round:{N}/2 | Attacks:{n} | SAFE/BROKEN | VERDICT: {verdict}`

| Output | Verdict | Action |
|--------|---------|--------|
| All PASS | APPROVED | → triple-verify |
| 1-2 minor | FIX | → fixer (R1) / accept tech debt (R2) |
| Critical | BLOCK | → human |
| Partial coverage | FIX | Re-run, scope mandate |
| <3 attempts / malformed | FAIL | Re-run (stricter briefing / format) |
| Timeout / R2 breaks | ESCALATE | → human with full chain |

## Round 2 & Escalation

**Round 2**: New `git diff` after fixer changes. Pass BOTH diffs — breaker checks R1 resolved + new issues. Re-inject briefing with `## Round 2 — Focus on whether these specific issues were fixed: {R1 findings}`. Max 2 rounds.

**Escalation** (BLOCK/ESCALATE): Target, Rounds, Pipeline, Chain Evidence (R1/R2 attempts→verdict), Blocker, Recommendation (revert/redesign/manual review/merge first).

**Recording**: Engram per structured schema in §Engram Integration (Step 12). Includes calibration scores + generated test cases.

## Integration & Anti-Patterns

| Skill | Relation |
|-------|----------|
| quality-gate | BEFORE breaker — gate is entry |
| triple-verify | AFTER breaker — pre-verify |
| judgment-day | Independent — JD=4R, breaker=offensive |
| subagent-isolation | Fresh context, artifact bundle |
| external-auditor | On BLOCK → confirmation |
| immune-system | Repeated breaks → permanent fix |

### Versionable Attack Surface

Projects can override/extend the generic attack-surface checklist by creating `.agents/attack-surface.{project}.md` in their repo root. The orchestrator checks for this file in Step 4 and injects it alongside the default checklist.

Format: same categories as `references/attack-surface.md`. Additional vectors are merged, not replaced.

### Project-Specific Profiles

Similarly, `.agents/breaker-profiles/{project}/` can contain additional technology profiles. See `references/profiles/` for the default set.

| Anti-Pattern | Fix |
|---|---|
| Breaker trusts fixer | Verify from artifacts |
| No attempts declared | Enforce methodology |
| 3+ rounds | Cap 2 → escalate |
| Before quality-gate | quality-gate first |
| 4R review | Offensive, not evaluative |
| Happy path only | Test adversarial inputs |
| Non-code diffs | Skip breaker |
| Breaker on tiny diffs | Use token-save skip (<10 lines config-only) |
| Skip pre-regression check | Always stash+test before breaker — catches broken builds early |
| Ignore test case generation | Record FAIL attacks as reproducible test cases |
| Generic surface on tailored project | Create `.agents/attack-surface.{project}.md` override |

- [breaker-briefing](references/breaker-briefing.md) · [attack-surface](references/attack-surface.md) · [profiles](references/profiles/) · [subagent-isolation](../subagent-isolation/SKILL.md) · [quality-gate](../quality-gate/SKILL.md) · [triple-verify](../triple-verify/SKILL.md) · [judgment-day](../judgment-day/SKILL.md)
