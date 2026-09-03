---
name: trial-verify
description: When facing >=2 viable options for a non-trivial reversible decision, implement/evaluate ALL of them, verify via independent subagent scoring, and PROCEED with the verified winner without asking the user to choose. Triggered by exception (d) of the 1-question rule.
triggers: trial-verify, multi-option decision, which option, autonomous option resolution
token_budget: 2950
changelog: "2026-09-02 cycle32-p2 — externalize examples/patterns to reference.md (ADR-048)"
---

# Trial-Verify Protocol

Empirically validated 2026-08-24 (2 trials, subagent verified — detail -> reference.md).

## Trigger
>=2 viable approaches for reversible decision, blast radius Bajo/Medio (v3 s1), material (>1 file or session impact). Trivial skip.

## Process
1. **ENUMERATE**: 2-3 candidates (cap 3).
2. **PROTOTYPE**: concrete artifacts only (text/diff/config), never prose. Over budget? Prototype diff part only.
3. **VERIFY**: independent subagent review — NEVER self-grade alone. Rubric 0-5 each: efficacy | token economy | failure-mode exposure | protocol consistency | learning persistence.
4. **SELECT**: highest verified total wins. Disagreement -> synthesize with BOTH objections as constraints; ledger.
5. **PROCEED**: implement immediately; NO menu. T2+ PEV plan stays single human touchpoint.
6. **LEDGER**: mem_save(topic_key="trial/<topic>", type=decision): What/Options/Scores/Winner/Why/Synthesis.

## Hard stops (ask human)
- Irreversible/destructive or blast Alto
- Verification unavailable after 2 attempts -> simplest, confidence:low
- User asks "which do you prefer?" -> recommendation + tradeoffs; agency overrides

## Budget caps
Max 3 options | max 2 verifications | abort if >15 tool calls.

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format -> STOP, re-read skill
- Second occurrence same rationalization -> force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 -> SKILL.md OK

---
## Reference Materials
Externalized to keep <=3KB (ADR-048). Worked examples (trial #1/#2), testing patterns, edge cases/anti-patterns -> docs/skills/trial-verify/reference.md
Template: .agents/skills/automejora-analyzer/SKILL.md
---
## Refs
Cross-Refs: triple-verify | testing-strategy
