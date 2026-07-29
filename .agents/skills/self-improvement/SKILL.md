---
name: self-improvement
description: "Continuous improvement cycle — macro (cycle) + micro (per-task). Merge of self-reflection. inter(30) minimum. SkillOpt-style gated validation."
triggers: "Self-improvement, improvement cycle, auto-mejora, ciclo de mejora, comienza ciclo, self-reflection, Hermes, reflexioná"
---
## MACRO (cycle-level) — "comienza ciclo de auto-mejora"
1st: READ CYCLE.md. Then: Pre-Flight → Diagnose → SkillOpt Gate (per fix) → Verify → Learn → Propagate → Epoch Review.
Validate per fix: SKILL.md lines ≤20%/size<3KB, .ps1 syntax parse, config trivial. Accept if target≥+0.1 and no dim≤-0.3.
Budget: cosine decay `max(4, base_budget × cos(π·n/(2·N)))`. Reject 3x→SKIP.
Exit: inter≥30 + no dim<9.0→SUCCESS; 7d→STOP; score -0.5→revert.
## MICRO (per-task reflection, merged from self-reflection)
Observe→Reflect→Optimize→Apply after every task (≥3 tools) + session end + error recovery.
CAPTURE→EXTRACT(≥2 reps?→skill-creator)→EVALUATE(root cause→immune-system)→SCORE(auto-metrics)→IMMUNIZE(<7→anti-pattern).
Same error 2x→catalog. 3x→AGENTS.md rule. Gotcha→doc skill. Complex workflow→skill-creator.
**If changes touch protected files** (security-scanner, quality-gate, auto-metrics, external-auditor, immune-system, ANTI-PATTERN-CATALOG.md, .project.json):
  → RUN `!audit` BEFORE commit. Gate: external-auditor must PASS. This is NOT optional.
Template: `reflection/{date}` with Outcome/Root cause/Score/What changed.
Frustration signals → `recovery-protocol`.
## Buffer Formats
Schemas: `.learnings/rejected-edits.json` (id/timestamp/target/edit/reason/delta) and `accepted-edits.json` (id/timestamp/target/edit/delta/pattern).
## Refs: CYCLE.md · inter-track · extract-skill · run-improvement-cycle · score-auto · SkillOpt arXiv:2605.23904 · SkillSpector · recovery-protocol · external-improvement (5-phase cycle for external projects)

## Anti-Patterns
Skip learning extraction · Bump score without data · Ignore CYCLE.md guardrails · Never prune unused skills · Same fix fails 3x without abort

## Example: Per-Task Micro-Loop
After fixing a bug (e.g. "catch block was empty"):
1. **Observe**: Write-Debug added to 3 catch blocks
2. **Reflect**: Why were they empty? Copied from template without thinking
3. **Optimize**: Add rule to immune-system: "empty catch → Write-Debug with context"
4. **Apply**: Template now includes Write-Debug by default
5. **Score**: Run `!score` — delta = +0.2 (caught earlier in review)

Same error 2x → catalog entry. 3x → AGENTS.md rule.
