---
name: adversarial-breaker
description: "Adversarial verification protocol — orchestrator loads this skill to run fixer→breaker chain. Breaker is an independent offensive agent."
triggers: "adversarial, breaker, !breaker, verify fix, romper, verificar fix, try to break, offensive verification"
license: Apache-2.0
metadata:
  tags: [engineering, verification, adversarial]
  author: gentleman-vMK
  version: "2.0"
  changelog: "2.0: Reworked after 4-agent analysis — fixed pipeline integration, output contracts, zone filter, failure paths"
  dependencies: [subagent-isolation]
  config_refs: review-rules.jsonc
---

# Adversarial Breaker

Protocol for the **orchestrator** (main agent) to run an independent adversarial check after a fix. Builder ≠ Evaluator, enforced.

## When to Invoke

Invoke this protocol when:
- A fixer subagent claims a fix is complete
- The change is ROJA-zone (always) or AMARILLA-zone touching auth/storage/API
- The change is NOT pure config/whitespace/lock-file (no attack surface = skip)

Do NOT invoke for:
- VERDE-zone changes
- Non-code diffs (Markdown, YAML, JSON config without logic)
- Fixes that only add comments or documentation

## Protocol

The orchestrator executes these steps. The breaker is a subagent launched at Step 3.

| Step | Orchestrator Action | Output |
|------|-------------------|--------|
| 1 | **Gather artifacts** from fixer output — see Artifact Bundle below | Bundle |
| 2 | **Zone check** — resolve zone from `review-rules.jsonc` (source of truth). If AMARILLA by pattern but diff touches auth/storage/API paths → escalate to ROJA for breaker purposes | Zone |
| 3 | **Launch breaker** — read `references/breaker-briefing.md`, inject as delegation prompt context alongside artifact bundle | Breaker output |
| 4 | **Parse breaker output** — validate format (4-field required). If <3 attack attempts declared → FAIL, re-run | Parsed results |
| 5 | **Synthesize verdict** — see Verdicts below | APPROVED/FIX/BLOCK/ESCALATE |
| 6 | **Round 2** (if FIX) — see Round 2 Protocol | Updated verdict |
| 7 | **Record** — save to Engram per Recording Schema | Memory |

## Artifact Bundle

The orchestrator assembles this from the fixer's output + `git diff`:

```yaml
diff: string              # git diff of changed files (working tree)
changed_files: string[]   # file paths from fixer's "Files Changed"
fixer_claims: string      # fixer's "Key Findings" + "Nuance" fields
test_results: string      # quality-gate output + any test results (if available, else "N/A")
zone: enum                # roja | amarilla | verde (from review-rules.jsonc)
pipeline_mode: enum       # ship | fast | check | manual
```

Pass this bundle to the breaker alongside the briefing template content.

## Breaker Output Contract

The breaker produces a **detailed** 4-field output:

```
## Attack Attempts
[Numbered list of every attack tried]

## Attack Vector
[Categories: Input validation, Injection, Concurrency, Error handling, Logic]

## Result (per test)
[Numbered list matching Attack Attempts — PASS or FAIL with evidence]

## Edge Cases Found
[Unexpected behaviors, regressions, or confirmed failures]
```

The orchestrator then synthesizes the **summary line**:

```
AB-{target} | Round:{N}/2 | Attacks:{n} | SAFE/BROKEN | VERDICT: APPROVED/FIX/BLOCK/ESCALATE
```

These are TWO DIFFERENT formats. Breaker produces detailed. Orchestrator produces summary. Do not confuse them.

## Verdicts

| Breaker Output | Verdict | Orchestrator Action |
|----------------|---------|-------------------|
| All attacks PASS | APPROVED | Proceed to triple-verify |
| 1-2 minor issues, Round 1 | FIX | Send findings back to fixer |
| 1-2 minor issues, Round 2 | APPROVED | Accept — document as tech debt |
| Critical break (security/crash/data loss) | BLOCK | Escalate to human |
| Partial coverage (3 of 5 files) | FIX | Re-run with scope mandate |
| <3 attack attempts | FAIL | Re-run with stricter briefing |
| Breaker subagent timeout | ESCALATE | Partial results → human |
| Breaker returns malformed output | FAIL | Re-run with format emphasis |
| Round 2 breaks | ESCALATE | Full chain evidence → human |

## Round 2 Protocol

When verdict is FIX and fixer applies corrections:

1. **New diff**: Orchestrator runs `git diff` again (working tree reflects fixer's round-2 changes)
2. **Delta context**: Pass BOTH diffs to breaker — original + new. Breaker focuses on whether round-1 findings are resolved AND whether new changes introduce new issues
3. **Briefing injection**: Read `references/breaker-briefing.md` AGAIN (fresh injection). Add header: `## Round 2 — Focus on whether these specific issues were fixed: {round-1 findings}`
4. **Max rounds**: 2 total. If round 2 breaks → ESCALATE with full chain evidence.

## Escalation Template

When verdict is BLOCK or ESCALATE, produce this for the human:

```
## ESCALATION
Target: {file path}
Rounds: {N}/2
Pipeline: {!ship/!fast/manual}

### Chain Evidence
Round 1: {breaker attempts summary} → {verdict}
Round 2: {breaker attempts summary} → {verdict} (if applicable)

### Blocker
{Specific finding that caused BLOCK/ESCALATE}

### Recommendation
{revert / redesign / manual review needed / merge required first}
```

## Recording Schema

Save to Engram after each run:

```yaml
title: "breaker:{target}:R{round}"
type: discovery
topic_key: "breaker/{target}"
content: |
  **What**: Adversarial verification of {target} — {SAFE/BROKEN}
  **Why**: {pipeline_mode} pipeline, zone {zone}
  **Where**: {changed_files}
  **Attempts**: {attack count} across {vectors}
  **Verdict**: {APPROVED/FIX/BLOCK/ESCALATE}
  **Learned**: {any edge cases or gotchas found, omit if none}
```

## Integration

| Skill | Relation |
|-------|----------|
| quality-gate | Runs BEFORE breaker — gate is entry |
| triple-verify | Runs AFTER breaker — breaker is pre-verify |
| judgment-day | Independent — JD=4R evaluation, breaker=offensive testing |
| subagent-isolation | Breaker follows isolation rules — independent (not blind), fresh context, artifact bundle (not 4-field contract) |
| external-auditor | On BLOCK, orchestrator may invoke for independent confirmation |
| immune-system | Repeated pattern breaks → permanent fix |

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| Breaker trusts fixer claims | Verify independently from artifacts |
| "Looks clean" no attempts | Enforce declare-methodology rule |
| 3+ rounds | Cap 2 → escalate to human |
| Breaker before quality-gate | quality-gate ALWAYS first |
| Breaker does 4R review | Offensive, not evaluative |
| Breaker only tests happy path | Must test adversarial inputs |
| Orchestrator accepts output without format validation | Parse 4-field, reject if malformed |
| Breaker ignores non-code files | Skip breaker for non-code diffs |

## Refs
- [breaker-briefing](references/breaker-briefing.md) · [attack-surface](references/attack-surface.md) · [subagent-isolation](../subagent-isolation/SKILL.md) · [quality-gate](../quality-gate/SKILL.md) · [triple-verify](../triple-verify/SKILL.md) · [judgment-day](../judgment-day/SKILL.md)
