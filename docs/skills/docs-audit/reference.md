# Docs Audit — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/docs-audit/SKILL.md) for the core scan dimensions, Diátaxis decision tree, and rules.

---

## Examples (5)

### 1. README Audit
```bash
grep -rn "## Quick Start\|## Prerequisites" --include="README.md"
# → finds missing getting-started section → flag MED
```

### 2. API Schema Validation
```bash
grep -rn "@param\|@returns" --include="*.ts"
# → compares JSDoc params to actual function signature → finds drift → flag CRIT
```

### 3. Diátaxis Gap Check
```bash
# counts docs per category (TUTORIAL/HOW-TO/REFERENCE/EXPLANATION)
# → only 1 of 4 present → report missing types
```

### 4. Link Rot Detection
```bash
grep -rn "\[.*\](http" --include="*.md" | grep -E "localhost|127\.0\.0\.1|TODO"
# → flags dev URLs in production docs
```

### 5. CHANGELOG Format
```bash
grep -rn "## \[" --include="CHANGELOG.md"
# → validates Keep a Changelog format → missing version headers → flag MED
```

---

## Testing Patterns (3)

### 1. Round-trip Verification
Parse extracted examples as executable code (TypeScript/Python/Go) → verify they compile/run without errors

### 2. Cross-reference Integrity
Build graph of all internal links (`[text](#anchor)` or `[text](file.md)`) → verify every target exists and anchors match headings

### 3. Diátaxis Coverage Test
For each user journey (install → configure → use → troubleshoot), verify at least one doc of each Diátaxis type covers it

---

## Edge Cases (4)

### 1. Generated vs Hand-written
Distinguish auto-generated API docs (Swagger/OpenAPI) from manual docs; only audit manual for accuracy drift

### 2. Versioned Documentation
Multi-version docs (v1/, v2/) → audit each version independently; don't conflate missing in v2 with missing in v1

### 3. Monorepo Fragmentation
Docs scattered across packages (`packages/*/README.md`) → aggregate before scoring; penalize only truly missing content

### 4. I18n/Localization
Non-English docs present → audit source-of-truth language first; flag translation drift separately from structural gaps

---

## Anti-Patterns (7)

1. **Completeness before accuracy** — Counting sections without verifying content correctness (wrong params, broken examples) → CRIT severity
2. **Skip link validation** — Assuming internal/external links work → broken UX, security risk (open redirects)
3. **No Diátaxis analysis** — Treating all docs as same type → misses structural gaps for different reader intents
4. **Ignore standard files** — Missing CHANGELOG/CONTRIBUTING/LICENSE/SECURITY.md → governance gaps, contributor friction
5. **cat README (use grep)** — Reading entire file instead of targeted grep → token waste, misses cross-file patterns
6. **Conflating generated with manual** — Auditing Swagger output as if hand-written → false positives, wasted effort
7. **Single-version audit in multi-version repo** — Only checking `latest/` → misses regressions in maintained versions

## Externalized Sections (ADR-007 compression)
## DIÁTAXIS DECISION TREE
```
Is the reader learning a skill? → TUTORIAL
Is the reader doing a specific task? → HOW-TO
Is the reader looking up information? → REFERENCE
Is the reader trying to understand why? → EXPLANATION
```
Flag gaps: if only one type exists, others are likely missing.

## SCAN DIMENSIONS
**README**: `grep -rn "## Quick Start\|## Getting Started\|## Prerequisites\|## Configuration\|## Architecture\|## Contributing" --include="README.md"` → structure; `grep -rn "TODO\|WIP\|placeholder\|coming soon" --include="*.md"` → stale markers.
**API Docs**: `grep -rn "swagger\|openapi\|@param\|@returns\|@example" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` → descriptions, schemas, error codes, examples.
**Onboarding**: `grep -rn "getting started\|prerequisites\|setup\|installation" --include="*.md"` → onboarding steps.
**Standard Files**: Check CHANGELOG.md, CONTRIBUTING.md, LICENSE, SECURITY.md exist; `grep -rn "Keep a Changelog\|## \[" --include="CHANGELOG.md"` → format.
**Links**: `grep -rn "\[.*\](http" --include="*.md"` → localhost, 127.0.0.1, TODO URLs.
**Code**: `grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` → tech debt.
