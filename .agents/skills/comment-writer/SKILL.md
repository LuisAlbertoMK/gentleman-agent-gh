---
name: comment-writer
description: "Write warm, direct collaboration comments. Trigger: PR feedback, issue replies, reviews, Slack messages, GitHub."
triggers: "comments, PR feedback, review comment, GitHub comment, write feedback"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use

Load this skill whenever you write a comment that another human will read.

Use it for:

- GitHub PR or issue comments.
- Review feedback and requested changes.
- Maintainer replies.
- Slack, Discord, or async project updates.

## Voice Rules

| Rule | Requirement |
|------|-------------|
| Be useful fast | Start with the actionable point. Do not recap the whole PR before feedback. |
| Be warm and direct | Sound like a thoughtful teammate, not a corporate bot. |
| Keep it short | Prefer 1 to 3 short paragraphs or a tight bullet list. |
| Explain why | Give the technical reason when asking for a change. |
| Avoid pile-ons | Comment on the highest-value issue, not every tiny preference. |
| Match target context language | Write in the target context language by default: Spanish issue/thread -> Spanish comment, English issue/thread -> English comment, mixed context -> target message language. If the user explicitly requests a language or tone, follow that request. For Spanish comments, use neutral/professional Spanish by default unless the user or target context clearly calls for regional tone. |
| No em dashes | Use commas, periods, or parentheses instead. |

## Comment Formula

```text
<Direct observation or request>

<Why it matters, only if needed>

<Concrete next action>
```

## Examples

### Request change

```markdown
Good approach overall. I'd split this into a separate commit because it mixes validation logic with UI wiring.

That keeps the reviewer's focus narrower and makes rollback cleaner if the integration fails.
```

### Approve with a note

```markdown
Approved. The scope is clear and the change is well-contained.

For the next PR, add links to the previous and following PRs so the chain stays navigable.
```

### Ask for split

```markdown
This PR exceeds the 400-line budget, so we need to split it or justify `size:exception`.

Suggested order: foundation + tests first, then integration, then docs. That gives each review a clear start and end.
```

### Security concern (C28)

```markdown
The token is exposed in the query string — logs and browser history will capture it.

Move it to an `Authorization: Bearer` header or a secure cookie. That prevents accidental leakage in proxy logs and Referer headers.
```

### Performance nudge (C28)

```markdown
This loop queries the DB per iteration — 50 items = 50 round trips.

Batch it with a single `WHERE id IN (...)` or use the repository's `findMany`. Cuts latency from ~500ms to ~50ms.
```

### Test coverage gap (C28)

```markdown
The happy path is covered. Missing: empty list, null input, and the timeout branch (line 42).

Add those three cases and the module hits 95%+. CI will gate on it.
```

### Cross-team dependency (C28)

```markdown
This changes the event schema that `billing-service` consumes.

Tag the owners or open a follow-up issue so they can bump their consumer before we merge. Breaking changes need a 2-week notice window.
```

### Celebrate good work (C28)

```markdown
Love the simplification on line 89 — replacing the visitor pattern with a flat map cut 60 lines and made the intent obvious.

That kind of cleanup pays dividends. Thanks for taking the time.
```

## Testing Patterns

### 1. Tone calibration test
```bash
# Input: aggressive PR comment
# Expected: rewrite to warm + direct without losing the ask
echo "This is wrong. Fix it." | ./scripts/tone-check.sh
# Output should include actionable request + "why"
```

### 2. Language matching test
```bash
# Input: Spanish issue thread + English comment draft
# Expected: output in Spanish (neutral/professional)
./scripts/lang-match.sh --context=es --draft="Please fix this bug"
# Output: "Por favor, corrige este error. El caso límite en la línea 12..."
```

### 3. Formula compliance test
```bash
# Input: raw feedback
# Expected: 3-part structure (observation, why, action)
./scripts/formula-check.sh --comment="Good work but add tests"
# FAIL: missing "why" and "action"
# PASS: "Good work. Tests prevent regressions when we refactor. Add unit tests for the parser."
```

## Edge Cases

| Scenario | Handling |
|----------|----------|
| **Mixed-language thread** (English PR, Spanish comments) | Default to thread language; if ambiguous, match the *last human message* |
| **Author is non-native English speaker** | Simpler sentences, avoid idioms, keep "why" explicit — warmth over cleverness |
| **High-stakes security finding** | Lead with impact (not "nice work"), be unambiguous, tag security owners, suggest immediate mitigation |
| **Comment on your own PR** | Same formula. Self-review: "I'm splitting this because..." — models the standard |

## Commands

```bash
# Inspect a PR before writing review feedback
gh pr view <PR_NUMBER> --json title,body,additions,deletions,changedFiles
```

## Refs
code-review-agent · comment-writer · branch-pr

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|--------------|-----|
| Write before reading the PR | Feedback misses context, wastes reviewer time | Read first. Comment on what you actually saw. |
| Recapitulate entire diff | Noise drowns signal; author tunes out | Quote the specific line or block. One observation per comment. |
| Pile-on every nit | Overwhelms author; high-value issues get buried | Pick 1–2 highest-impact items. File nits as separate "nit:" comments if needed. |
| Use em dashes | Breaks the voice rule; reads as corporate/formal | Use commas, periods, or parentheses. |
| Skip "why" when requesting change | Author can't learn or evaluate tradeoffs | Always include the technical reason. |
| Passive-aggressive framing ("You might want to...") | Sounds insincere; creates defensiveness | Direct: "Move X to Y because Z." Warmth ≠ hedging. |
| Generic praise without specificity ("Great job!") | Feels empty; doesn't reinforce the behavior | Specific: "The flat map on line 89 cut 60 lines — that clarity scales." |
