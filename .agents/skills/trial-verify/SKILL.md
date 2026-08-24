---
name: trial-verify
description: When facing >=2 viable options for a non-trivial reversible decision, implement/evaluate ALL of them, verify via independent subagent scoring, and PROCEED with the verified winner without asking the user to choose. Triggered by exception (d) of the 1-question rule.
triggers: trial-verify, multi-option decision, which option, autonomous option resolution
---

# Trial-Verify Protocol

Validated empirically 2026-08-24: 2 trials, both verdicts confirmed by
independent subagent verification (see mejora-log V7). Not theoretical.

## Trigger

Orchestrator identifies >=2 viable approaches for a decision that is:
reversible, blast radius Bajo/Medio (v3 §1), and material (>1 file or >1 session impact).
Trivial decisions (naming, one-liners) skip this — just pick and go.

## Process

1. **ENUMERATE**: 2-3 candidate approaches. More than 3 = analysis paralysis; cap at 3.
2. **PROTOTYPE**: produce each candidate as a concrete artifact (actual text/diff/config),
   never as prose descriptions. If prototyping all candidates exceeds the budget caps,
   prototype only the differentiating part of each.
3. **VERIFY**: delegate independent review to a subagent — NEVER self-grade alone
   (verified failure mode: self-grading bias, trial #1). Rubric, 0-5 each:
   - Efficacy: does it change real behavior reliably?
   - Token economy: always-loaded cost + per-invocation cost
   - Failure-mode exposure: what breaks when it breaks?
   - Protocol consistency: v3 §1 checkpoints, PEV gate, autonomy zones
   - Learning persistence: does the verdict survive compaction/sessions?
4. **SELECT**: highest verified total wins. Verifier disagreement -> synthesize with
   BOTH verifiers' objections folded in as constraints; document the synthesis in the ledger.
5. **PROCEED**: implement the winner immediately. Do NOT present an option menu.
   For T2+ multi-file work the PEV plan (with the chosen approach already inside)
   remains the single human touchpoint — no separate "which approach?" question.
6. **LEDGER**: `mem_save(topic_key="trial/<topic>", type=decision)`:
   ```
   **What**/<topic> | **Options**: A/B/C one-line each |
   **Scores**: verifier output verbatim | **Winner**: X |
   **Why**: deciding factor | **Synthesis**: if hybrid, what was merged from losers
   ```

## Hard stops (still ask the human)

- Irreversible or destructive operations
- Blast radius Alto (protocol v3 §1 checkpoint rule)
- Verification unavailable after 2 delegation attempts -> pick simplest option,
  flag confidence: low
- User explicitly asked "which do you prefer?" -> answer with recommendation +
  tradeoffs; user agency overrides automation

## Budget caps

Max 3 options · max 2 verification delegations · abort trial if total >15 tool calls.

## Testing

Validated empirically before codification (2026-08-24):
- Trial #1 (self-application): variants scored by gentleman-deep-sub-auto
  (C=21/25) + gentleman-quick-sub-auto (A=20/25); disagreement resolved as
  documented synthesis. Ledgers: Engram trial/trial-verify-implementation.
- Trial #2 (hardcoded-path prevention): P3 won 20/25 with repo evidence;
  detection regex tested against dirty+clean fixtures (1 hit / 0 false positive).
- Known limitation at validation time: hooks were NOT active in the authoring
  clone (core.hooksPath unset) — gate integration verified only by manual
  fixture test until hooks are configured. See Anti-Patterns.

## Anti-Patterns

- NEVER self-grade candidates without an independent subagent (observed bias).
- Never let the learning loop promote defaults that bypass Alto checkpoints.
- Do not trust "wired per docs" — verify `git config core.hooksPath` per clone.
- Registering a new skill WITHOUT updating canonical counts breaks cross-ref,
  skill-coverage, and drift gates (happened once; fixed same session).

## Learning loop

After every 10 ledgers, review them (automejora-analyzer): if one option-TYPE wins
>70% of trials within a domain, make it the default-first-candidate for that class
(faster convergence) — but NEVER promote a pattern that would bypass Alto blast-radius
checkpoints (verified compliance risk, trial #1).
