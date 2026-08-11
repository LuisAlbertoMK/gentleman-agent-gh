---
name: sdd-spec
description: "Write SDD delta specs with requirements and scenarios. Trigger: orchestrator launches spec work for a change."
license: MIT
metadata:
  author: gentleman-programming
version: 1.0.0-local
triggers: "SDD spec, specification, given when then, requisitos, spec writing"
  version: "2.0"
  delegate_only: true
---

> **ORCHESTRATOR GATE**: If loaded via `skill()` tool, STOP. Delegate to `sdd-spec` sub-agent. If you ARE the sub-agent, ignore this gate — execute below.

## Language
Artifacts: English (default); Spanish only if requested (neutral/professional). Comments follow target context language.

## Input
From orchestrator: change name, artifact store mode (`engram | openspec | hybrid | none`).

## Persistence
Per `sdd-phase-common.md` §B+C:
- **engram**: Read `sdd/{change-name}/proposal` (concatenate multi-domain with domain headers); save as `sdd/{change-name}/spec`.
- **openspec**: Read `openspec-convention.md`.
- **hybrid**: Both — Engram + filesystem.
- **none**: Return only. No file creation.

## Workflow

### 1. Load Skills — §A of `sdd-phase-common.md`

### 2. Identify Domains
Read proposal's **Capabilities section**:
- **New Capabilities** → FULL spec at `openspec/specs/<name>/spec.md`
- **Modified Capabilities** → DELTA spec at `openspec/changes/{change-name}/specs/<name>/spec.md`; read existing first

Fallback: infer from "Affected Areas" if no Capabilities section.

### 3. Read Existing Specs
- **openspec/hybrid**: Read `openspec/specs/{domain}/spec.md` if exists
- **engram**: Already retrieved. Skip.
- **none**: Skip.

### 4. Write Specs

**openspec/hybrid**: Create in `openspec/changes/{change-name}/specs/{domain}/spec.md`.

**engram/none**: Compose in memory — persist in step 5.

#### Delta Format
```
# Delta for {Domain}

## ADDED Requirements
### Requirement: {Name}
{RFC 2119: MUST/SHALL/SHOULD} {behavior}.

#### Scenario: {Name}
- GIVEN {precondition}
- WHEN {action}
- THEN {outcome}

## MODIFIED Requirements
### Requirement: {Name}
{Full updated text — replaces existing entirely}
(Previously: {what changed})

#### Scenario: {Name}
- GIVEN / WHEN / THEN

## REMOVED Requirements
### Requirement: {Name}
(Reason: {why})
(Migration: {replacement or "None"})

## RENAMED Requirements
### Requirement: {Old} → {New}
(Reason: {why})
(Migration: {how to update refs})
```

#### MODIFIED Workflow (CRITICAL)
1. Copy ENTIRE requirement block (from `### Requirement:` through ALL scenarios)
2. Paste under `## MODIFIED Requirements`
3. Edit the copy
4. Add "(Previously: {summary})" under requirement text

NEVER write partial MODIFIED blocks — archive replaces the full requirement; partial blocks lose scenarios.

New behavior without changing existing → use ADDED.

#### New Domain (No Existing Spec)
Full spec: `# {Domain} Specification` → `## Purpose` → `## Requirements` with Given/When/Then scenarios.

### 5. Persist (MANDATORY)
Follow **Section C** from `skills/_shared/sdd-phase-common.md`. artifact: `spec`, topic_key: `sdd/{change-name}/spec`, type: `architecture`.

### 6. Return Summary
```markdown
## Specs Created
**Change**: {change-name}

| Domain | Type | Requirements | Scenarios |
|--------|------|-------------|-----------|
| {domain} | Delta/New | {N added, M modified, K removed} | {total} |

- Happy paths: {covered/missing}
- Edge cases: {covered/missing}
- Error states: {covered/missing}

Next step: design (sdd-design) or tasks (sdd-tasks).
```

## Rules

- Given/When/Then for all scenarios
- RFC 2119 keywords (MUST/SHALL/SHOULD/MAY) for requirement strength
- Every requirement: ≥1 scenario, include happy path + edge cases
- Scenarios must be TESTABLE — automatable from Given/When/Then
- Specs describe WHAT, not HOW — no implementation details
- MODIFIED blocks: ALWAYS copy full requirement + all scenarios before editing
- REMOVED: include Reason; include Migration when consumers/behavior/docs/tests affected
- RENAMED: state both names; include Migration guidance
- Apply `rules.specs` from `openspec/config.yaml`
- **Size**: spec artifact <650 words. Prefer requirement tables. Each scenario: 3-5 lines max
- Return envelope per **Section D** from `skills/_shared/sdd-phase-common.md`
(RFC 2119: MUST/SHALL=absolute, MUST NOT/SHALL NOT=prohibited, SHOULD=recommended w/ justification, MAY=optional — see Rules above)

