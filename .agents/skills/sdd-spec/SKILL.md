---
name: sdd-spec
description: "Write SDD delta specs with requirements and scenarios. Trigger: orchestrator launches spec work."
triggers: "SDD spec, specification, given when then, requisitos, spec writing"
delegate_only: true
---

> **ORCHESTRATOR GATE**: `skill()` → STOP, delegate to `sdd-spec` sub-agent.

## Input
From orchestrator: change name, artifact store (`engram | openspec | hybrid | none`).

## Persistence (per `sdd-phase-common.md` §B+C)
- **engram**: Read `sdd/{change}/proposal`; save as `sdd/{change}/spec`
- **openspec**: Read `openspec-convention.md`
- **hybrid**: Both
- **none**: Return only

## Workflow
1. **Load Skills** — §A of `sdd-phase-common.md`
2. **Identify Domains** from proposal's Capabilities:
   - New → FULL spec at `openspec/specs/<name>/spec.md`
   - Modified → DELTA spec at `openspec/changes/{change}/specs/<name>/spec.md`; read existing first
   - Fallback: infer from "Affected Areas"
3. **Read Existing Specs** (openspec/hybrid: `openspec/specs/{domain}/spec.md`)
4. **Write Specs** (openspec/hybrid: `openspec/changes/{change}/specs/{domain}/spec.md`)

### Delta Format
```
# Delta for {Domain}
## ADDED Requirements
### Requirement: {Name}
{RFC 2119: MUST/SHALL/SHOULD} {behavior}
#### Scenario: {Name}
- GIVEN {precondition} | WHEN {action} | THEN {outcome}
## MODIFIED Requirements
### Requirement: {Name}
{Full updated text — replaces existing entirely} (Previously: {what changed})
#### Scenario: {Name} - GIVEN/WHEN/THEN
## REMOVED Requirements
### Requirement: {Name} (Reason: {why}) (Migration: {replacement or "None"})
## RENAMED Requirements
### Requirement: {Old} → {New} (Reason: {why}) (Migration: {how to update refs})
```

### MODIFIED Workflow (CRITICAL)
1. Copy ENTIRE requirement block (from `### Requirement:` through ALL scenarios)
2. Paste under `## MODIFIED Requirements`
3. Edit the copy
4. Add "(Previously: {summary})"
NEVER write partial MODIFIED blocks. New behavior without changing existing → ADDED.

### New Domain (No Existing Spec)
Full spec: `# {Domain} Specification` → `## Purpose` → `## Requirements` with Given/When/Then.

5. **Persist** — §C of `sdd-phase-common.md`: artifact `spec`, topic_key `sdd/{change}/spec`, type `architecture`
6. **Return Summary**
```markdown
## Specs Created
**Change**: {change-name}
| Domain | Type | Requirements | Scenarios |
|---|---|---|---|
| {domain} | Delta/New | {N added, M modified, K removed} | {total} |
- Happy paths: {covered/missing} | Edge cases: {covered/missing} | Error states: {covered/missing}
Next: design (sdd-design) or tasks (sdd-tasks).
```

## Rules
- Given/When/Then for all scenarios; RFC 2119 keywords (MUST/SHALL/SHOULD/MAY)
- Every requirement: ≥1 scenario (happy + edge cases); Scenarios TESTABLE — automatable from G/W/T
- Specs describe WHAT, not HOW; MODIFIED: ALWAYS copy full requirement + all scenarios before editing
- REMOVED: include Reason; Migration if consumers affected; RENAMED: state both names; include Migration
- Apply `rules.specs` from `openspec/config.yaml`; Size: <650 words; Prefer tables; Scenarios: 3-5 lines max
- Return envelope per §D of `sdd-phase-common.md`