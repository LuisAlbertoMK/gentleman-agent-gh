---
name: docs-audit
description: "Trigger: documentation audit, README audit, API docs, onboarding docs, Diátaxis, docs completeness. Audit documentation quality and accuracy."
triggers: "documentation audit, README audit, API docs, onboarding docs, Diátaxis, docs completeness, docs review, doc audit"
---
## WHEN: Reviewing documentation quality, README files, API docs, onboarding. If no docs → report and stop.

## SCAN DIMENSIONS

**README**: `grep -rn "## Quick Start\|## Getting Started\|## Prerequisites\|## Configuration\|## Architecture\|## Contributing" --include="README.md"` → structure
- `grep -rn "TODO\|WIP\|placeholder\|coming soon" --include="*.md"` → stale markers

**API Docs**: `grep -rn "swagger\|openapi\|@param\|@returns\|@example" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` → API docs
- Check: descriptions, schemas, error codes, examples

**Onboarding**: `grep -rn "getting started\|prerequisites\|setup\|installation" --include="*.md"` → onboarding steps

**Standard Files**: Check CHANGELOG.md, CONTRIBUTING.md, LICENSE, SECURITY.md exist
- `grep -rn "Keep a Changelog\|## \[" --include="CHANGELOG.md"` → format check

**Links**: `grep -rn "\[.*\](http" --include="*.md"` → check for localhost, 127.0.0.1, TODO URLs

**Code**: `grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` → tech debt

## DIÁTAXIS DECISION TREE
```
Is the reader learning a skill? → TUTORIAL
Is the reader doing a specific task? → HOW-TO
Is the reader looking up information? → REFERENCE
Is the reader trying to understand why? → EXPLANATION
```
Flag gaps: if only one type exists, others are likely missing.

## RULES
1. **Accuracy BEFORE completeness.** Wrong docs are worse than missing docs. Flag wrong info as CRIT, missing docs as MED.
2. Diátaxis categories first. 3. Every finding: file:line + severity. 4. End with prioritized action plan.

## OUTPUT
```
### Documentation Audit
| Section | Status | Issues | Priority |
### Completeness
- README: [X/Y sections]
- API docs: [X/Y endpoints]
- Standard files: [CHANGELOG/CONTRIBUTING/LICENSE present?]
### Stale Content
- [file]:line — [what's wrong]
### Recommendations
- CRIT: [wrong docs]
- MED: [missing docs]
```

## Refs
code-generation · quality-gate · cognitive-doc-design

## Anti-Patterns
Completeness before accuracy · Skip link validation · No Diátaxis analysis · Ignore standard files · cat README (use grep)
