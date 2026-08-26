---
name: trial-verify
description: When facing >=2 viable options for a non-trivial reversible decision, implement/evaluate ALL of them, verify via independent subagent scoring, and PROCEED with the verified winner without asking the user to choose. Triggered by exception (d) of the 1-question rule.
triggers: trial-verify, multi-option decision, which option, autonomous option resolution
---

# Trial-Verify Protocol

Empirically validated 2026-08-24 (2 trials, verdicts confirmed by independent
subagent verification — see mejora-log V7). Not theoretical.

## Trigger

>=2 viable approaches for a decision that is reversible, blast radius Bajo/Medio
(v3 §1), material (>1 file or session impact). Trivial decisions skip this.

## Process

1. **ENUMERATE**: 2-3 candidates (cap at 3 = analysis-paralysis guard).
2. **PROTOTYPE**: concrete artifacts only (text/diff/config), never prose.
   Over budget? Prototype only the differentiating part of each.
3. **VERIFY**: independent subagent review — NEVER self-grade alone (verified
   bias, trial #1). Rubric 0-5 each: efficacy · token economy · failure-mode
   exposure · protocol consistency (v3 §1, PEV, autonomy zones) · learning
   persistence.
4. **SELECT**: highest verified total wins. Verifier disagreement → synthesize
   with BOTH objections as constraints; document in ledger.
5. **PROCEED**: implement immediately; NO option menu. For T2+ the PEV plan
   (chosen approach inside) stays the single human touchpoint.
6. **LEDGER**: `mem_save(topic_key="trial/<topic>", type=decision)`:
   What/Options/Scores/Winner/Why/Synthesis(if hybrid).

## Hard stops (still ask the human)

- Irreversible/destructive ops · blast radius Alto (v3 §1)
- Verification unavailable after 2 attempts → simplest option, confidence: low
- User explicitly asks "which do you prefer?" → recommendation + tradeoffs;
  user agency overrides automation

## Budget caps

Max 3 options · max 2 verification delegations · abort if >15 tool calls total.

## Validation & Anti-Patterns

Validated pre-codification (trial #1: synthesis of deep-sub C=21/25 +
quick-sub A=20/25; trial #2: P3 won 20/25, detection regex fixture-tested
1 hit / 0 FP). Known gap at validation: authoring clone lacked core.hooksPath
— verify wiring per clone, never trust "wired per docs".

- NEVER self-grade candidates without an independent subagent.
- Never promote defaults that bypass Alto checkpoints (compliance risk).
- Registering a skill without updating canonical counts breaks cross-ref,
  coverage, and drift gates (happened once; fixed same session).

## Learning loop

Every 10 ledgers run automejora-analyzer: an option-TYPE winning >70% within
a domain becomes default-first-candidate — never bypassing Alto checkpoints.
