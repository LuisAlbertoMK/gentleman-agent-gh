---
name: skill-improver
description: "Audit and improve skills — preserve author intent, fix frontmatter, convert tutorial prose to actionable rules, track usage"
triggers: "Skill improvement, audit skills, refactor skills"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.0"
---

Trigger: "improve skills", "audit skills", "refactor skills".
## HARD RULES- Preserve author intent, critical rules, activation semantics, output contract- Default to audit-only â€” modify only when explicitly asked- Never delete meaningful content; move long explanations to `references/` or `assets/`- Don't invent triggers, policies, or domain rules â€” mark ambiguous for human review
## DECISION GATES| Situation | Action ||---|---|| Missing/invalid frontmatter | Fix name, description, license, metadata || Reads like tutorial | Convert to runtime instructions, move background to `references/` || Body exceeds budget | Preserve rules, move examples to supporting files || Branching logic in prose | Convert to compact decision table || Rules conflict/unclear | Report â€” don't rewrite automatically |
## Usage Tracking (skill deprecation)Track which skills are actively used vs stale. Run on audit.1. `mem_search(query="skill load|skill tool|Skill:", limit=50)` â€” find skill load events2. Cross-reference: skills loaded in last 30 days vs skills NOT loaded3. For untouched skills (90d+): flag as possibly deprecated4. Report format:
```
## Skill Usage Report: {date}
### Active (loaded â‰¤30d ago)- skill-name â€” last used: {date}, {context}
### Rarely used (loaded 30-90d ago)- skill-name â€” last used: {date}
### Possibly deprecated (no load in 90d+)- skill-name â€” created: {date}, never loaded
```5. Action: review deprecated â†’ archive or merge into _shared/
## STEPS1. Read all `*/SKILL.md` files2. Audit per skill: metadata, trigger clarity, section order, body budget, actionability, decision gates, output contract3. Check usage tracking â†’ flag deprecated skills4. Return audit report grouped by skill with severity5. In apply mode: edit safe issues, create supporting files, preserve content
