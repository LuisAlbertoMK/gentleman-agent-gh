---
name: skill-improver
description: "Audit and improve skills — preserve author intent, fix frontmatter, convert tutorial prose to actionable rules, track usage"
triggers: "Skill improvement, audit skills, refactor skills, skill refresher, drift detection, auto-heal"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "2.0"
  changelog: "2.0: merged skill-refresher (drift detection, health signals, auto-heal)"
---
## HARD RULES
Preserve author intent · critical rules · activation semantics · output contract | Default: audit-only — modify only when asked | Never delete content → move to `references/` | Don't invent triggers/policies/domain rules — mark ambiguous for human
## DECISION GATES
Missing/invalid frontmatter → Fix it | Reads like tutorial → runtime rules, background→`references/` | Body over budget → preserve rules, move examples | Branching prose → decision table | Rules conflict → report, don't rewrite
## USAGE TRACKING (on audit)
1. `mem_search(query="skill load|skill tool|Skill:", limit=50)`
2. Cross-ref: loaded ≤30d vs NOT loaded
3. 90d+ untouched → flag deprecated
4. Report: Active (≤30d) · Rare (30-90d) · Possibly deprecated (90d+)
5. Deprecated → archive or merge into `_shared/`
## STEPS
1. Read all `*/SKILL.md` files
2. Audit per skill: metadata, trigger clarity, section order, body budget, actionability, decision gates, output contract
3. Check usage tracking → flag deprecated
4. Return audit report grouped by skill with severity
5. Apply mode: edit safe issues, create supporting files, preserve content
## DRIFT DETECTION (merged from skill-refresher)
Trigger: repeated bug, skill unused 5+ sessions, user repeats correction, Karpathy loss >5%.
### Health Signals
| Signal | Action |
|--------|--------|
| Same bug 2+ times | Skill missed pattern → update |
| Not loaded 5+ sessions | Unused → flag or merge |
| User corrects same thing 2+ | Skill vague → clarify |
| Karpathy loss >5% | Revert, rewrite denser |
### Healing
Loaded but didn't help → Engram log (skill, session, why not, suggested fix) → next health check.
### Self-Test
Verify loads (`skill name: skill-improver`), YAML valid, triggers fire. Self-test returns `{healthy: true/false, issues: [...]}`.
### Regeneration Flow
1. Audit current SKILL.md + Engram usage (last 10 sessions)
2. Check drift: triggers still match? Too broad/narrow?
3. Update: fix gaps, tighten triggers, add patterns
4. Compress: re-Karpathy if >5% new content
5. Bump version: major=structural, minor=content
6. Log changelog + commit
