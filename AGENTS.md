<!-- gentle-ai:persona -->

<!-- gentle-ai:bridge -->
**Bridge to global gentle-orchestrator** — Este repo delega a `gentle-orchestrator`
(que vive en ~/.config/opencode/opencode.json, mode: primary) para operaciones que
requieren native review, lossless prompts, receipt-driven authority y SDD native.
Routing decisivo: si el task lo requiere → delegue a `gentle-orchestrator`; caso
contrario → skill routing normal de gentleman-agent-gh. No duplica el agente:
se resuelve desde la config global fusionada por OpenCode.

## Quick Navigation

| Document | Purpose |
|----------|---------|
| [PROTOCOL.md](PROTOCOL.md) | Operational rules, workflows, shortcuts |
| [SHORTCUTS.md](SHORTCUTS.md) | All `!command` shortcuts |
| [SKILLS-INDEX.md](SKILLS-INDEX.md) | 93 skills trigger table |
| [QUICKSTART.md](QUICKSTART.md) | Getting started guide |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System architecture |
| [docs/agent-context.md](docs/agent-context.md) | Persona, tone, Python env, scripts, learning loop, delegation |

## Rules
- No Co-Authored-By/AI commit attribution. Use conventional commits only.
- Default short. 1 Q → STOP salvo: (a) subtareas pendientes, (b) mejora obvia post-ejecución, (c) pregunta abierta. En esos casos → sugerir sin actuar. Detalle en docs/agent-context.md.
- Verify before agree. Wrong? Prove with evidence. Wrong me? Prove otherwise.
- Pre-answer evidence check: Before answering analytical/"what's missing" questions, search existing docs (glob docs/mejoras/*.md) and memory (ctx_search/mem_search) for prior work. If evidence exists → cite it. If novel → flag as unvalidated.
- Always show alternatives with tradeoffs. Verify technical claims first.

<!-- gentle-ai:engram-protocol -->
> **Engram protocol**: Moved to `.agents/skills/engram-protocol/SKILL.md`. Load via skill when needed.
<!-- /gentle-ai:engram-protocol -->

<!-- gentle-ai:agent-protocol -->
> **Agent protocol**: See [PROTOCOL.md](PROTOCOL.md) for operational rules and workflows.
<!-- /gentle-ai:agent-protocol -->

<!-- agent-version: 2.2 — Project: gentleman-agent-gh, self-contained -->

## Pre-Flight Gate
Before any analytical/gap question → glob docs/mejoras/*.md + ctx_search + mem_search → cite file:line or flag confidence: unvalidated. See gentle-MK.md Pre-Answer Evidence Gate.

## Subagent-First
Decompose → delegate with contract: goal, files, constraints, expected_output → verify no file overlap before parallel delegation → synthesize 4-field results.

## Default-FAIL
Claims without confidence: marker are Default-FAIL. Unvalidated claims flagged. Tool output cited file:line.

## Skills
93 skills via SKILLS-INDEX.md. Load via skill tool.

<!-- /gentle-ai:persona -->
