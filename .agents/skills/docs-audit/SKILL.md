---
name: docs-audit
description: "Trigger: documentation audit, README audit, API docs, onboarding docs, Diataxis. Audit docs quality and accuracy."
triggers: "documentation audit, README audit, API docs, onboarding docs, Diátaxis, docs completeness, docs review, doc audit"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2159
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
| "audit desde el README solo" | Solo README sin SCAN DIMENSIONS completas | Verificar SCAN DIMENSIONS: README/API/Onboarding/Standard Files/Links/Code greps + stale markers completo |
| "Diataxis como religión no como guía" | Diátaxis aplicado sin criterio invirtiendo Accuracy BEFORE completeness | Verificar Rule 1: Accuracy BEFORE completeness + Diátaxis categories con severity file:line |
| "no checar stale refs" | Links/code greps sin chequeo stale markers | Verificar Stale Content: file:line por hallazgo + greps reference.md + action plan priorizado |


## Red Flags
- README without Diataxis → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- docs-audit checklist
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: research | gap-analysis | project-mapper


## Reference
SCAN DIMENSIONS greps → docs/skills/docs-audit/reference.md

