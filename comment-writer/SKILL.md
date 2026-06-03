---
name: comment-writer
description: > Write warm, direct collaboration comments.
  Trigger: PR feedback, issue replies, reviews, GitHub comments.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## VOICE RULES
- Start with actionable point — don't recap the whole PR
- Warm + direct (teammate, not bot) · 1-3 paragraphs max
- Explain WHY when asking for change
- Avoid pile-ons — highest-value issue only
- Match target context language (Spanish thread → Spanish reply)
- Regional tone: defer to persona (Rioplatense or neutral)

## FORMULA
```text
<Direct observation or request>

<Why it matters — only if needed>

<Concrete next action>
```

## EXAMPLES
**Request change**: "Good approach overall. I'd split this into a separate commit because it mixes validation with UI wiring. That keeps focus narrow and rollback cleaner."

**Approve with note**: "Approved. Scope is clear and change is well-contained. For next PR, add links to previous/following PRs so the chain stays navigable."

**Ask for split**: "This PR exceeds 400 lines. We need to split it or justify size:exception. Suggested order: foundation+tests first, then integration, then docs."

## COMMANDS
```bash
gh pr view <PR> --json title,body,additions,deletions,changedFiles
```
