---
name: cross-project-wisdom
description: "Prior-project patterns - advisory cross-repo knowledge. Trigger: patterns, wisdom, cross-project, retrospectiva"
triggers: "patterns, wisdom, lesson learned, in another project I, last time this, cross-project, retrospectiva, experiencia previa, !wisdom, pattern guard"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Load patterns from prior projects relevant to the current ta


## Pattern Load

1. Read all JSON files from `docs/cross-project/patterns/*.json`
2. Parse domain/subdomain/tags/severity from each
3. Cross-reference against current task context:
   - `tech_stack`: match against `context.technologies[]`
   - `domain`: match against `domain` + `tags`
   - `keywords`: match against `signal.keywords[]`
4. Return patterns sorted by relevance score:
   ```
   score = tech_overlap × 0.4 + domain_match × 0.3 + confidence × 0.2 + recency × 0.1
   ```
5. For each matched pattern, present:
   - **Pattern**: `rule.summary` (1 line)
   - **Severity**: `severity`
   - **Context**: where it was learned
   - **Check**: what to verify
   - **Fix**: the recommended approach
6. Always state: *"These are advisory — use judgment."*

## Rung 0b Integration

When invoked from Pre-Flight Gate (rung 0b):
1. Quick read: select patterns where ANY keyword/tag matches task keywords
2. Gate duration: max 200ms / 3 patterns rendered
3. Output format: `⚠ Pattern: {severity} {summary} — see {file}`
4. Never block — always advisory

## Commands

```powershell
# Manual load
Get-ChildItem "docs/cross-project/patterns/*.json" | ForEach-Object { Get-Content $_ | ConvertFrom-Json }

# Search by technology
$patterns | Where-Object { $_.context.technologies -match "gradient" }

# Search by severity
$patterns | Where-Object { $_.severity -eq "HIGH" -or $_.severity -eq "CRITICAL" }
```

## Pattern Lifecycle

- `seed`: manual add (file in `patterns/`)
- `active`: consultable (this skill)
- `confirmed`: seen 3+ contexts → `HIGH` priority
- `forged`: extracted to OpenCode skill or AGENTS.md rule

Each pattern JSON carries `hits` — increment on confirmed re-encounter.

## Anti-Patterns

- Never block commits/PRs based on patterns alone
- Don't load more than 5 patterns into context unless explicitly asked
- Don't treat patterns as authoritative — always verify applicability
- Don't store secrets or credentials in pattern evidence

## Resources

`docs/cross-project/patterns/*.json` · `docs/cross-project/PLAN.md` · `docs/cross-project/README.md`

## Refs
cross-project-forge · dreaming · immune-system · research · session-resume
