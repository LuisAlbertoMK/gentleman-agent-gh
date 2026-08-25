---
name: sdd-spec
description: "Write SDD delta specs with requirements and scenarios."
delegate_only: true
---

> **GATE**: Loaded via `skill()` -> STOP. Delegate to `sdd-spec` sub-agent. Executor -> run below.

## Input
change name, artifact store mode (`engram|openspec|hybrid|none`).

## Persistence (sdd-phase-common B+C)
- engram: read `sdd/{change}/proposal`; save `sdd/{change}/spec`
- openspec: per `openspec-convention.md`
- hybrid: both · none: return only

## Workflow
1. Load skills (Section A).
2. **Domains**: proposal Capabilities - New -> FULL spec `openspec/specs/<name>/spec.md`; Modified -> DELTA `openspec/changes/{change}/specs/<name>/spec.md` (read existing first). Fallback: Affected Areas.
3. Read existing specs (openspec/hybrid only; engram already retrieved).
4. **Write**: openspec/hybrid -> files; engram/none -> in memory.
   Delta format: `## ADDED|MODIFIED|REMOVED|RENAMED Requirements` with `### Requirement:` + RFC 2119 + GIVEN/WHEN/THEN scenarios; REMOVED -> Reason(+Migration); RENAMED -> Old->New + Migration.
   **MODIFIED (CRITICAL)**: copy ENTIRE block + all scenarios -> paste -> edit -> add "(Previously: {summary})". NEVER partial blocks (archive replaces full requirement). New behavior w/o change -> ADDED. New domain -> `# {Domain} Specification` -> Purpose -> Requirements GWT.
5. **Persist (MANDATORY)**: Section C; artifact `spec`, key `sdd/{change}/spec`, type `architecture`.
6. **Return**: change, table (Domain|Type|counts), happy/edge/error coverage, next: design or tasks.

## Rules
- GWT for all scenarios; RFC 2119 (MUST/SHALL/SHOULD/MAY)
- >=1 scenario: happy path + edge cases; TESTABLE (automatable)
- WHAT not HOW - no implementation details
- MODIFIED: full copy before edit · REMOVED: Reason + Migration if consumers affected · RENAMED: both names + Migration
- `rules.specs` from `openspec/config.yaml`; artifact <650 words; prefer tables; scenario <=5 lines
- Envelope per Section D (sdd-phase-common)
- RFC 2119: MUST/SHALL=absolute, MUST NOT/SHALL NOT=prohibited, SHOULD=recommended w/ justification, MAY=optional
