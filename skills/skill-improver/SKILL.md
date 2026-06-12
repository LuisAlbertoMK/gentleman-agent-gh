---
name: skill-improver
description: > Audit and upgrade existing skills.
  Trigger: "improve skills", "audit skills", "refactor skills".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## HARD RULES
- Preserve author intent, critical rules, activation semantics, output contract
- Default to audit-only — modify only when explicitly asked
- Never delete meaningful content; move long explanations to `references/` or `assets/`
- Don't invent triggers, policies, or domain rules — mark ambiguous for human review

## DECISION GATES
| Situation | Action |
|---|---|
| Missing/invalid frontmatter | Fix name, description, license, metadata |
| Reads like tutorial | Convert to runtime instructions, move background to `references/` |
| Body exceeds budget | Preserve rules, move examples to supporting files |
| Branching logic in prose | Convert to compact decision table |
| Rules conflict/unclear | Report — don't rewrite automatically |

## Usage Tracking (skill deprecation)
Track which skills are actively used vs stale. Run on audit.

1. `mem_search(query="skill load|skill tool|Skill:", limit=50)` — find skill load events
2. Cross-reference: skills loaded in last 30 days vs skills NOT loaded
3. For untouched skills (90d+): flag as possibly deprecated
4. Report format:
```
## Skill Usage Report: {date}
### Active (loaded ≤30d ago)
- skill-name — last used: {date}, {context}
### Rarely used (loaded 30-90d ago)
- skill-name — last used: {date}
### Possibly deprecated (no load in 90d+)
- skill-name — created: {date}, never loaded
```
5. Action: review deprecated → archive or merge into _shared/

## STEPS
1. Read all `*/SKILL.md` files
2. Audit per skill: metadata, trigger clarity, section order, body budget, actionability, decision gates, output contract
3. Check usage tracking → flag deprecated skills
4. Return audit report grouped by skill with severity
5. In apply mode: edit safe issues, create supporting files, preserve content
