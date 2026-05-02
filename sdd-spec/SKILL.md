---
name: sdd-spec
description: >
  Write specifications: requirements + scenarios (delta specs for changes).
  Trigger: Orchestrator launches you to write/update specs for a change.
license: MIT
metadata:
  author: gentleman-programming
  version: "2.0"
---

## Purpose
SPECIFICATIONS sub-agent. Take proposal → produce delta specs (ADDED/MODIFIED/REMOVED requirements + Given/When/Then scenarios).

## Persistence Contract
Per `_shared/sdd-phase-common.md` Sections B+C.
- **engram**: Read proposal. Concatenate multi-domain into single artifact. Save `sdd/{change}/spec`
- **openspec**: Follow `_shared/openspec-convention.md`
- **hybrid**: BOTH — single concatenated engram + domain files on filesystem
- **none**: Return result only

## Steps

### 1: Load Skills
Per `_shared/sdd-phase-common.md` Section A.

### 2: Identify Domains (from Proposal Capabilities)
```
FOR EACH "New Capabilities" → NEW full spec: openspec/specs/<capability>/spec.md
FOR EACH "Modified Capabilities" → DELTA spec: openspec/changes/{change}/specs/<capability>/spec.md
  → Read existing spec first — delta modifies it
No Capabilities? → Fall back to "Affected Areas"
```

### 3: Read Existing Specs
openspec/hybrid: read `openspec/specs/{domain}/spec.md` if exists. engram: already retrieved. none: skip.

### 4: Write Delta Specs

**CRITICAL — MODIFIED Requirements Workflow:**
1. Locate requirement in main spec
2. COPY ENTIRE block (from `### Requirement:` through ALL scenarios)
3. PASTE under `## MODIFIED Requirements`
4. EDIT copy for new behavior
5. Add `(Previously: {one-line summary})`
**Why?** Archive REPLACES requirement with your MODIFIED block. Partial blocks lose scenarios.

#### Delta Format
```markdown
# Delta for {Domain}

## ADDED Requirements
### Requirement: {Name}
{RFC 2119: MUST/SHALL/SHOULD/MAY}
#### Scenario: {Name}
- GIVEN {precondition}
- WHEN {action}
- THEN {outcome}

## MODIFIED Requirements
### Requirement: {Name}
{Full updated text}
(Previously: {what changed})
#### Scenario: {Name}
- GIVEN / WHEN / THEN

## REMOVED Requirements
### Requirement: {Name}
(Reason: {why})
```

#### New Domain (Full Spec)
```markdown
# {Domain} Specification
## Purpose
{High-level description}
## Requirements
### Requirement: {Name}
The system {MUST/SHALL/SHOULD} {behavior}.
#### Scenario: {Name}
- GIVEN {precondition}
- WHEN {action}
- THEN {outcome}
```

### 5: Persist (MANDATORY)
artifact: `spec` | topic_key: `sdd/{change}/spec` | type: `architecture`

### 6: Return Summary
```
## Specs Created
**Change**: {name}
| Domain | Type | Requirements | Scenarios |
| {domain} | Delta/New | {N added, M modified, K removed} | {total} |

### Coverage
Happy paths: {covered/missing} | Edge cases: {covered/missing} | Error states: {covered/missing}
```

## Rules
- ALWAYS Given/When/Then for scenarios
- ALWAYS RFC 2119 keywords (MUST/SHALL/SHOULD/MAY)
- Read proposal Capabilities FIRST
- Existing specs → DELTA (ADDED/MODIFIED/REMOVED)
- No existing specs → FULL spec
- Every requirement MUST have ≥1 scenario
- Include happy path AND edge cases
- Scenarios MUST be testable
- NO implementation details — WHAT, not HOW
- MODIFIED = FULL block (copy all + edit)
- New behavior without changing existing → ADDED, not MODIFIED
- Size budget: <650 words. Tables over narrative. Scenarios: 3-5 lines max.
- Return envelope per `_shared/sdd-phase-common.md` Section D.

## RFC 2119 Quick Reference
| Keyword | Meaning |
|---------|---------|
| MUST / SHALL | Absolute requirement |
| MUST NOT / SHALL NOT | Absolute prohibition |
| SHOULD | Recommended, exceptions OK with justification |
| SHOULD NOT | Not recommended, OK with justification |
| MAY | Optional |
