---
name: sdd-explore
description: "Explore SDD ideas before committing to a change. Trigger: orchestrator launches exploration or requirement clarification."
license: MIT
metadata:
  author: gentleman-programming
version: 1.0.0-local
triggers: "SDD explore, explore ideas, investigation, discovery, SDD exploration"
  version: "2.0"
  delegate_only: true
---

> **ORCHESTRATOR GATE**: If you loaded via `skill()`, you are ORCHESTRATOR — STOP.
> Delegate to `sdd-explore` sub-agent. For EXECUTORS only.

## Executor Override

If you ARE the `sdd-explore` sub-agent, gate does not apply. Execute directly.

## Language Contract

Artifacts default to English. Spanish: neutral/professional unless regional variant requested.

## Purpose

Explore codebase for a topic/feature, compare approaches, return structured analysis. Research only by default; create `exploration.md` only for named changes.

## Input

- Topic or feature to explore
- Artifact store mode (`engram | openspec | hybrid | none`)

## Persistence Contract

> Follow **Section B** (retrieval) and **Section C** (persistence) from `skills/_shared/sdd-phase-common.md`.

- **engram**: Optionally read `sdd-init/{project}`. Save as `sdd/{change-name}/explore` (or `sdd/explore/{topic-slug}` standalone).
- **openspec**: Read `skills/_shared/openspec-convention.md`.
- **hybrid**: Both — Engram + filesystem.
- **none**: Return result only.
- **Retrieval**: engram searches `sdd-init/{project}` + `sdd/`; openspec reads config + specs; none uses orchestrator prompt.

## Workflow

1. **Load Skills** — Follow **Section A** from `skills/_shared/sdd-phase-common.md`.
2. **Understand Request** — Parse: feature? bug fix? refactor? Domain?
3. **Investigate** — Read entry points, search related code, check tests, identify patterns, map dependencies.
4. **Analyze Options** — Compare approaches:

| Approach | Pros | Cons | Complexity |
|----------|------|------|------------|
| Option A | ... | ... | Low/Med/High |
| Option B | ... | ... | Low/Med/High |

5. **Persist Artifact** — Mandatory for named changes. Follow **Section C** from `skills/_shared/sdd-phase-common.md`.
   - artifact: `explore`, topic_key: `sdd/{change-name}/explore`, type: `architecture`
6. **Return Analysis** — Return this format (write to `exploration.md` if saving):

```markdown
## Exploration: {topic}

### Current State
{How system works today relevant to topic}

### Affected Areas
- `path/file.ext` — {why}

### Approaches
1. **{Name}** — {desc}
   - Pros: ... | Cons: ... | Effort: Low/Med/High
2. **{Name}** — {desc}
   - Pros: ... | Cons: ... | Effort: Low/Med/High

### Recommendation
{Chosen approach and why}

### Risks
- {Risk 1}

### Ready for Proposal
{Yes/No — what to tell user}
```

## Rules

- Only file you MAY create: `exploration.md` in change folder
- DO NOT modify existing code
- ALWAYS read real code, never guess
- Keep CONCISE — summary, not novel
- State if info insufficient or request too vague
- Return envelope per **Section D** from `skills/_shared/sdd-phase-common.md`.

