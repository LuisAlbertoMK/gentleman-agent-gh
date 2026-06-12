---
name: comment-writer
description: > Write warm, direct collaboration comments.
  Trigger: PR feedback, issue replies, reviews, GitHub comments.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## VOICE
Actionable first · Warm+direct (teammate) · 1-3¶ max · Explain WHY
No pile-ons · Match thread language · Regional tone → persona

## FORMULA
`<observation/request>` → `<why (optional)>` → `<next action>`

## QUICK REFS
**Request change**: "Good approach. I'd split this because it mixes validation with UI wiring — keeps focus narrow and rollback cleaner."
**Approve**: "Approved. Well-contained. Next PR: link chain PRs."
**Split**: "This exceeds 400 lines. Split or justify size:exception. Order: foundation+tests → integration → docs."

## CMD
```bash
gh pr view <PR> --json title,body,additions,deletions,changedFiles
```
