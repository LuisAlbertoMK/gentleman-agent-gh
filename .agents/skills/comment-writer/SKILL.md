---
name: comment-writer
description: "Write warm, direct collaboration comments. Trigger: PR feedback, issue replies, reviews, Slack messages, GitHub."
triggers: "comments, PR feedback, review comment, GitHub comment, write feedback"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2293
---

## When to Use
Whenever you write a comment another human will read: GitHub PR/issue comments, review feedback, maintainer replies, Slack/Discord updates.

## Voice Rules
| Rule | Requirement |
|---|---|
| Be useful fast | Start with the actionable point. No PR recap first. |
| Be warm and direct | Thoughtful teammate, not corporate bot. |
| Keep it short | 1-3 short paragraphs or a tight bullet list. |
| Explain why | Give the technical reason when asking for change. |
| Avoid pile-ons | Comment on highest-value issue, not every preference. |
| Match target context language | Spanish thread→Spanish, English→English, mixed→target message language. User request overrides. Spanish default: neutral/professional. |
| No em dashes | Commas, periods, or parentheses instead. |

## Comment Formula
```
<Direct observation or request>
<Why it matters, only if needed>
<Concrete next action>
```

## Testing
1. Tone: aggressive input → warm+direct rewrite, keeps the ask, includes "why". 2. Language: ES thread + EN draft → output ES (neutral). 3. Formula: raw feedback → 3-part structure; missing why/action → FAIL.

## Commands
`gh pr view <PR_NUMBER> --json title,body,additions,deletions,changedFiles`

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
code-review-agent . comment-writer . branch-pr

## Anti-Patterns
Write before reading the PR · Recapitulate entire diff
## Reference
> docs/skills/comment-writer/reference.md

