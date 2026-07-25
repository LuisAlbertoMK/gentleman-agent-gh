---
name: adversarial-breaker
description: "Adversarial verification protocol — orchestrator loads this skill to run fixer→breaker chain. Breaker is an independent offensive agent."
triggers: "adversarial, breaker, !breaker, verify fix, romper, verificar fix, try to break, offensive verification"
license: Apache-2.0
metadata:
  tags: [engineering, verification, adversarial]
  author: gentleman-vMK
  version: "2.1"
  changelog: "2.1: Karpathy-loop compression — 50% size reduction, no functionality lost"
  dependencies: [subagent-isolation]
  config_refs: review-rules.jsonc
---

# Adversarial Breaker

Orchestrator runs independent adversarial check after fix. Builder ≠ Evaluator.

## When to Invoke

Invoke: fixer claims complete + ROJA-zone (always) or AMARILLA touching auth/storage/API + not pure config/whitespace/lock-file.
Skip: VERDE-zone, non-code diffs, comments-only, docs-only.

## Protocol

| Step | Action | Output |
|------|--------|--------|
| 1 | Gather artifacts: `diff`, `changed_files`, `fixer_claims`, `test_results`, `zone`, `pipeline_mode` | Bundle |
| 2 | Zone check from `review-rules.jsonc`. AMARILLA touching auth/storage/API → escalate ROJA | Zone |
| 3 | Launch breaker — inject `references/breaker-briefing.md` + artifact bundle | Breaker output |
| 4 | Parse output — validate 4-field format. <3 attempts → FAIL, re-run | Parsed |
| 5 | Verdict → see below | APPROVED/FIX/BLOCK/ESCALATE |
| 6 | Round 2 if FIX → see below | Updated verdict |
| 7 | Record to Engram: `title: "breaker:{target}:R{round}"` `type: discovery` `topic_key: "breaker/{target}"` | Memory |

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

**Recording**: Engram — What, Why (pipeline + zone), Where, Attempts (count + vectors), Verdict, Learned.

## Integration & Anti-Patterns

| Skill | Relation |
|-------|----------|
| quality-gate | BEFORE breaker — gate is entry |
| triple-verify | AFTER breaker — pre-verify |
| judgment-day | Independent — JD=4R, breaker=offensive |
| subagent-isolation | Fresh context, artifact bundle |
| external-auditor | On BLOCK → confirmation |
| immune-system | Repeated breaks → permanent fix |

| Anti-Pattern | Fix |
|---|---|
| Breaker trusts fixer | Verify from artifacts |
| No attempts declared | Enforce methodology |
| 3+ rounds | Cap 2 → escalate |
| Before quality-gate | quality-gate first |
| 4R review | Offensive, not evaluative |
| Happy path only | Test adversarial inputs |
| Non-code diffs | Skip breaker |

- [breaker-briefing](references/breaker-briefing.md) · [attack-surface](references/attack-surface.md) · [subagent-isolation](../subagent-isolation/SKILL.md) · [quality-gate](../quality-gate/SKILL.md) · [triple-verify](../triple-verify/SKILL.md) · [judgment-day](../judgment-day/SKILL.md)
