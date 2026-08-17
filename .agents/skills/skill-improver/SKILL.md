---
name: skill-improver
description: "Audit and improve skills - preserve intent, fix frontmatter, convert tutorial prose to actionable rules, track usage."
triggers: "Skill improvement, audit skills, refactor skills, skill refresher, drift detection, auto-heal"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Audit and improve skills — preserve author intent, fix frontmatter, convert tutorial prose to actionable rules, track usage

<!-- karpathy-compressed: 2026-07-10 -->

# Skill Improver

Diagnose/repair skill degradation — drift, stale content, tutorial prose.

## Rules

1. **Preserve** author intent, critical rules, activation semantics
2. **Audit-only** by default
3. **Never delete**: content → `references/`
4. **Don't invent** triggers — mark ambiguous
5. **Skills only** — no opencode.json, no AGENTS.md

## Decision Gates

| Signal | Action |
|---|---|
| Invalid frontmatter | Fix metadata |
| Tutorial prose | Convert to rules, bg → `references/` |
| Over budget | Rules stay, examples → `references/` |
| Branching prose | Decision table |
| Conflicting rules | Report both — escalate |

## Audit

1. Read all SKILL.md in target
2. Audit: metadata · triggers · budget · actionability · gates
3. `mem_search(last 50)` — flag 90d+ untouched
4. Report grouped-by-skill with severity

## Drift

Trigger: same bug 2x · unused 5+ · correction 2x · loss >5%

| Signal | Action |
|---|---|
| Same bug 2+ | Update skill |
| Not loaded 5+ sessions | Flag or merge |
| Corrects same 2+ | Clarify rules |
| Loss >5% | Revert, rewrite |

**Healing**: Engram log `(skill, session, why, fix)`.

## Regeneration

1. Audit + Engram (10 sessions) → 2. Drift check → 3. Fix gaps → 4. Compress if >5% new → 5. Version + changelog

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

## Refs

- [karpathy-loop](../karpathy-loop/SKILL.md) · [opencode-skill-creator](../opencode-skill-creator/SKILL.md) · [skill-testing](../skill-testing/SKILL.md) · [immune-system](../immune-system/SKILL.md) · [drift](../dreaming/SKILL.md)

---

## Examples

### Example 1: Audit a Drifting Skill

**Trigger**: `audit skill xyz` (frontmatter: "audit skills, skill refresher")

```powershell
# 1. Read all SKILL.md in target (Audit step 1)
Get-Content .agents/skills/xyz/SKILL.md
# 2. Audit: metadata · triggers · budget · actionability · gates (step 2)
# 3. Engram usage check, 90d+ untouched → drift (step 3)
mem_search(query: ["skill:xyz"])
```

**Expected output** — grouped-by-skill report with severity (Audit step 4):

```json
{"audited":["xyz"],"issues":[{"skill":"xyz","severity":"high","issue":"tutorial prose"}],"drifted":["xyz"]}
```

**Result**: tutorial prose converted to actionable rules; removed content archived to `references/` — never deleted (rule 3).

## Testing

1. **Frontmatter intact** — after any change, the 3 required keys must parse:
   ```powershell
   (Select-String -Path .agents/skills/xyz/SKILL.md -Pattern '^name:|^description:|^triggers:' -EA Stop).Count -eq 3
   ```
   Expected: `True`.

2. **Audit-only default** — run an audit with no fixes, then `git status --short`:
   Expected: empty output (no file modified; rule 2).

3. **Healing logged** — after a fix, `mem_search(query: ["skill:xyz"])` returns the `(skill, session, why, fix)` entry (Healing, Drift section).
