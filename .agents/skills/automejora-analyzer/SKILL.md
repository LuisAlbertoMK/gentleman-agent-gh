---
name: automejora-analyzer
description: "Analyzes auto-mejora cycles — detects patterns, scores improvements, validates SkillOpt gates, surfaces drift."
changelog: "2026-08-31 — SD 9.9→10 fix"
triggers: "auto-mejora, automejora, improvement analysis, cycle analysis, SkillOpt validation, improvement scoring"
token_budget: 2500
---

## When to Use
Analyze continuous improvement cycles (macro + micro). Detect patterns across cycles, validate SkillOpt gates, score deltas, surface drift/anti-patterns. Trigger via explicit request or auto after macro cycle completes.

## Core Responsibilities
1. **Pattern Detection**: Scan reflection logs, accepted/rejected edits, immune-system catalog for recurring themes
2. **SkillOpt Validation**: Verify each fix meets gate — size ≤20%/3KB, syntax parse, config trivial, target ≥+0.1, no dim ≤-0.3
3. **Drift Scoring**: Track dimension deltas across cycles; flag regression trends before they breach thresholds
4. **Cycle Health**: Verify budget decay compliance, inter-track ≥30, epoch review completeness
5. **Anti-Pattern Surfacing**: Cross-reference immune-system catalog + rejected-edits.json for repeat offenders

## Inputs
- `CYCLE.md` — current cycle state (budget, inter-track, phase)
- `.learnings/accepted-edits.json` / `rejected-edits.json` — edit history with deltas
- `reflection/{date}/*.md` — per-task micro-reflections
- `immune-system/ANTI-PATTERN-CATALOG.md` — known anti-patterns
- `auto-metrics` output (`!score` JSON) — dimension scores per cycle
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/automejora-analyzer/reference.md

---
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: self-improvement | metricas

