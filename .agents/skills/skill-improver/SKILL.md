---
name: skill-improver
description: "Audit and improve skills - preserve intent, fix frontmatter, convert tutorial prose to actionable rules, track usage."
triggers: "Skill improvement, audit skills, refactor skills, skill refresher, drift detection, auto-heal"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2540
---

## When to Use
Audit and improve skills — preserve author intent, fix frontmatter, convert tutorial prose to actionable rules, track usage.

## Rules
1. **Preserve** author intent, critical rules, activation semantics. 2. **Audit-only** by default. 3. **Never delete**: content → `references/`. 4. **Don't invent** triggers — mark ambiguous. 5. **Skills only** — no opencode.json, no AGENTS.md.

## Decision Gates
| Signal | Action |
|---|---|
| Invalid frontmatter | Fix metadata |
| Tutorial prose | Convert to rules, bg → `references/` |
| Over budget | Rules stay, examples → `references/` |
| Branching prose | Decision table |
| Conflicting rules | Report both — escalate |

## Audit
1. Read all SKILL.md in target. 2. Audit: metadata · triggers · budget · actionability · gates. 3. `mem_search(last 50)` — flag 90d+ untouched. 4. Report grouped-by-skill with severity.

## Regeneration
1. Audit + Engram (10 sessions) → 2. Drift check → 3. Fix gaps → 4. Compress if >5% new → 5. Version + changelog.

## Anti-Patterns
| Anti-Pattern | Fix |
|---|---|
| Rewrite entire skill | Audit → fix gaps → repeat |
| Add unintended triggers | Mark ambiguous |
| Delete instead of archive | `references/` |
| Major bump for trivial | minor=content |
| Ignore Engram | `mem_search` first |
| Over-compress rules | Preserve rules, compress examples |

## Output
```json
{"audited":["skill-a"],"issues":[{"skill":"skill-a","severity":"high"}],"drifted":["skill-b"]}
```

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
karpathy-loop · opencode-skill-creator · skill-testing · immune-system · dreaming

## Reference
> docs/skills/skill-improver/reference.md

