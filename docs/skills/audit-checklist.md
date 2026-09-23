# Skills Audit Checklist (Ronda 5 S1 — frozen)

> Scope: 96 auditable skills (`_shared` excluded). Validated by `scripts/skills-audit-check.ps1` (RuleId ↔ row).

## A. Anthropic Agent Skills spec compliance

| # | Rule | Check | Script |
|---|------|-------|--------|
| A1 | Frontmatter `name` matches directory | `name: <dir>` exact | `A1-name` |
| A2 | Frontmatter `description` non-empty, third-person, states what it does | ≥10 chars, no TODO/placeholder | `A2-description` |
| A3 | Triggers discoverable | `triggers:` non-empty in frontmatter | `A3-triggers` |
| A4 | Structure + discoverability | ≥1 substantive `##` h2 (any name except meta: `Anti-Rationalization`/`Red Flags`/`Verification`/`Refs`/`Reference Materials`; h3 never counts) AND (local `references/` OR `docs/skills/<name>/` OR `Cross-Refs`/`Refs` line) | `A4-structure` |

## B. Addyosmani structure (anti-rationalization)

| # | Rule | Check | Script |
|---|------|-------|--------|
| B1 | Anti-rationalization table is REAL | `## Anti-Rationalization` + markdown table with ≥2 data rows, skill-specific (no generic copy-paste) | `B1-anti-rat` |
| B2 | Red flags actionable | `## Red Flags` + ≥1 bullet with STOP/force/escalation verb | `B2-red-flags` |
| B3 | Verification steps executable | `## Verification` + ≥1 bullet with command, output contract, or `file:line` | `B3-verification` |

## C. Local rules (post-Ciclo-4)

| # | Rule | Check | Script |
|---|------|-------|--------|
| C1 | Token budget declared | `token_budget: <int>` 500–5000 | `C1-token-budget` |
| C2 | Changelog pointer present | `changelog:` non-empty (path or dated entry) | `C2-changelog` |
| C3 | No bloat (SKILL.md ≤6KB) | Detail lives in `references/` or `docs/skills/<name>/`, not in SKILL.md | `C3-no-bloat` |

## Notes

- Script is syntactic only: B1 cannot detect generic copy-paste — that is the 4R human reviewer's job (BLOCKER-capable).
- `SKILLS-INDEX.md` re-sync is R6 scope, NOT R5 (§8 of slice plan).
- Fail policy: FAIL → `judgment-day`, never auto-fix.
