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

## STEPS
1. Read all `*/SKILL.md` files
2. Audit per skill: metadata, trigger clarity, section order, body budget, actionability, decision gates, output contract
3. Return audit report grouped by skill with severity
4. In apply mode: edit safe issues, create supporting files, preserve content
