# comment-writer - Reference Materials

> **Externalized from** .agents/skills/comment-writer/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## Edge Cases
| Scenario | Handling |
|---|---|
| Mixed-language thread | Thread language; ambiguous → last human message |
| Non-native author | Simpler sentences, no idioms, explicit "why" |
| High-stakes security finding | Lead with impact, unambiguous, tag owners, immediate mitigation |
| Own PR | Same formula, self-review models the standard |


## Examples
- **Request change**: "Good approach overall. I'd split this into a separate commit because it mixes validation logic with UI wiring. That keeps the reviewer's focus narrower and makes rollback cleaner if integration fails."
- **Security**: "The token is exposed in the query string — logs and browser history capture it. Move it to an `Authorization: Bearer` header or secure cookie."
- **Perf**: "This loop queries the DB per iteration — 50 items = 50 round trips. Batch with `WHERE id IN (...)` / `findMany`. Cuts ~500ms→~50ms."
- **Celebrate**: "Love the simplification on line 89 — flat map cut 60 lines and made intent obvious. Thanks."
