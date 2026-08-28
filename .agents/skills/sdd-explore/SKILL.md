---
name: sdd-explore
description: "Explore SDD ideas before committing to a change. Trigger: orchestrator launches exploration or requirement clarification."
triggers: "SDD explore, explore ideas, investigation, discovery, SDD exploration"
delegate_only: true
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1797
---

## Executor Override
If you ARE the `sdd-explore` sub-agent, gate does not apply. Execute directly.

## Language
Artifacts default to English. Spanish: neutral/professional unless regional variant requested.

## Purpose
Explore codebase for a topic/feature, compare approaches, return structured analysis. Research only by default; create `exploration.md` only for named changes.

## Input
- Topic or feature to explore
- Artifact store mode (`engram | openspec | hybrid | none`)

## Workflow
1. **Load Skills** — §A from `sdd-phase-common.md`
2. **Understand Request** — Parse: feature? bug fix? refactor? Domain?
3. **Investigate** — Read entry points, search related code, check tests, identify patterns, map dependencies.
4. **Analyze Options** — Compare approaches (table: Approach | Pros | Cons | Complexity: Low/Med/High).
5. **Persist Artifact** — Mandatory for named changes. §C from `sdd-phase-common.md`: artifact `explore`, topic_key `sdd/{change}/explore`, type `architecture`.
6. **Return Analysis** (write to `exploration.md` if saving): Current State, Affected Areas, Approaches (table), Recommendation, Risks, Ready for Proposal.

## Rules
- Only file you MAY create: `exploration.md` in change folder
- DO NOT modify existing code
- ALWAYS read real code, never guess
- Keep CONCISE — summary, not novel
- State if info insufficient or request too vague
- Return envelope per §D from `sdd-phase-common.md`
---
---

docs/skills/sdd-explore/reference.md
---
## Refs
Cross-Refs: sdd | sdd-propose
