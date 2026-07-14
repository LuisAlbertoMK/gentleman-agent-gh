---
name: skill-improver
description: "Audit and improve skills — preserve author intent, fix frontmatter, convert tutorial prose to actionable rules, track usage"
triggers: "Skill improvement, audit skills, refactor skills, skill refresher, drift detection, auto-heal"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "2.1"
  changelog: "2.1: Karpathy compression (2.5→1.4KB), merged drift/healing sections"
---
## HARD RULES
Preserve author intent · critical rules · activation semantics · output contract | Default: audit-only — modify only when asked | Never delete content → move to `references/` | Don't invent triggers/policies — mark ambiguous for human
## DECISION GATES
Missing/invalid frontmatter → Fix | Tutorial prose → runtime rules, background→`references/` | Over budget → preserve rules, move examples | Branching prose → decision table | Conflicting rules → report, don't rewrite
## AUDIT STEPS
1. Read all `*/SKILL.md` → 2. Audit: metadata, trigger clarity, section order, body budget, actionability, decision gates, output contract → 3. Check usage (mem_search last 50 loads) → 4. Flag 90d+ untouched as deprecated → 5. Return report grouped by skill + severity → 6. Edit safe issues, create supporting files
## DRIFT (trigger: same bug 2x, unused 5+ sessions, user correction 2x, Karpathy loss >5%)
| Signal | Action |
|--------|--------|
| Same bug 2+ times | Skill missed pattern → update |
| Not loaded 5+ sessions | Flag or merge |
| User corrects same thing 2+ | Skill vague → clarify |
| Loss >5% | Revert, rewrite denser |
Healing: Loaded but didn't help → Engram log (skill, session, why not, suggested fix). Self-test returns `{healthy: bool, issues: []}`.
## REGENERATION FLOW
1. Audit SKILL.md + Engram usage (last 10 sessions) → 2. Check drift: triggers match? → 3. Update: fix gaps, tighten triggers, add patterns → 4. Compress if >5% new content → 5. Bump version (major=structural, minor=content) → 6. Log changelog + commit
