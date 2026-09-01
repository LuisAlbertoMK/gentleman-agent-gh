---
name: self-improvement
description: "Continuous improvement cycle - macro + micro, self-reflection merge, inter(30) minimum, SkillOpt gated validation."
triggers: "Self-improvement, improvement cycle, auto-mejora, ciclo de mejora, comienza ciclo, self-reflection, Hermes, reflexioná"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2537
---
## When to Use
Macro (cycle) + micro (per-task reflection).
## MACRO (cycle-level) — "comienza ciclo de auto-mejora"
1st: READ CYCLE.md. Then: Pre-Flight → Diagnose → SkillOpt Gate (per fix) → Verify → Learn → Propagate → Epoch Review.
Validate per fix: SKILL.md lines ≤20%/size<3KB, .ps1 syntax parse, config trivial. Accept if target≥+0.1 and no dim≤-0.3.
Budget: cosine decay `max(4, base_budget × cos(π·n/(2·N)))`. Reject 3x→SKIP.
Exit: inter≥30 + no dim<9.0→SUCCESS; 7d→STOP; score -0.5→revert.
## MICRO (per-task reflection, merged from self-reflection)
Observe→Reflect→Optimize→Apply (every task ≥3 tools + session end + recovery).
CAPTURE→EXTRACT(≥2 reps?→opencode-skill-creator)→EVALUATE(root cause→immune-system)→SCORE(auto-metrics)→IMMUNIZE(<7→anti-pattern).
Same error 2x→catalog. 3x→AGENTS.md rule. Gotcha→doc skill. Complex workflow→opencode-skill-creator.
**Protected files** (security-scanner, quality-gate, auto-metrics, external-auditor, immune-system, ANTI-PATTERN-CATALOG.md, .project.json): RUN `!audit` BEFORE commit; external-auditor must PASS — NOT optional.
Template: `reflection/{date}` with Outcome/Root cause/Score/What changed.
Frustration signals → `recovery-protocol`.
## Buffer Formats
Schemas: `.learnings/rejected-edits.json` (id/timestamp/target/edit/reason/delta) and `accepted-edits.json` (id/timestamp/target/edit/delta/pattern).
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
## Cross-Refs: recovery-protocol | external-improvement | immune-system | auto-metrics | security-scanner | quality-gate | external-auditor | opencode-skill-creator
---
docs/skills/self-improvement/reference.md
---

