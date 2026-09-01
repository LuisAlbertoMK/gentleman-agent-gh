---
name: docs-audit
description: "Trigger: documentation audit, README audit, API docs, onboarding docs, Diataxis. Audit docs quality and accuracy."
triggers: "documentation audit, README audit, API docs, onboarding docs, Diátaxis, docs completeness, docs review, doc audit"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1834
---
## When to Use
Reviewing documentation quality, README files, API docs, onboarding. If no docs → report and stop.
## SCAN DIMENSIONS
README/API/Onboarding/Standard Files/Links/Code greps + stale markers → reference.
## Rules
1. **Accuracy BEFORE completeness.** Wrong docs are worse than missing docs. Flag wrong info as CRIT, missing docs as MED.
2. Diátaxis categories first.
3. Every finding: file:line + severity.
4. End with prioritized action plan.
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
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Docs are obvious, no audit needed" | README without Diataxis | docs-audit checklist |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- README without Diataxis → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- docs-audit checklist
- cross-ref-check.ps1 → SKILL.md OK
## Refs
code-generation · quality-gate
## Reference
SCAN DIMENSIONS greps → docs/skills/docs-audit/reference.md

