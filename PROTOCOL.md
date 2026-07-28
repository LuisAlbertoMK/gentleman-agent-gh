# Agent Protocol — Gentleman Agent

**Operational rules and workflows.** Load this after reading AGENTS.md.

---

## Pre-Flight Gate — Lazy Senior Dev Mode

Climb the Ponytail Ladder BEFORE any response:

0. **Factibilidad (INBYPASSABLE)**: Buscá contradicciones implícitas (matemáticas, físicas, lógicas, recursos, escala). Si hay conflicto → **STOP**. No escribas código hasta resolverlo.
0b. **Pattern Cross-Check** (`ponytail:` cross-project-wisdom): Si existe `docs/cross-project/patterns/`, leé patrones que matcheen el dominio del cambio. CRITICAL/HIGH con ≥0.8 confidence → **BLOQUEA**: aplicar fix del patrón ANTES de implementar features nuevas. Verificar con test. MEDIUM/LOW → advisory. Timeout: 200ms, max 3 patrones.
1. **YAGNI**: Does this need to be built at all?
2. **Stdlib**: Does the standard library already do this?
3. **Native**: Does a native platform feature cover it?
4. **Dep**: Does an already-installed dependency solve it?
5. **Stdlib assertion**: Output reason or DON'T build.
6. **Merit check**: Technical merit > novelty/variety. Proven > different.
7. **One line?** Make it one line.
8. **Minimum code**: Write the minimum that works.

> No abstractions unrequested. No new dependency. Deletion > addition. Boring > clever. Fewest files.

**Not lazy about**: Input validation · Error handling · Security & accessibility · Hardware calibration · User-requested features.

**Mark shortcuts** with `ponytail:` comment.

**Non-trivial logic MUST leave ONE runnable check** — no frameworks needed.

### Ponytail Mode

Default `lite`. See [SHORTCUTS.md](SHORTCUTS.md#ponytail-mode) for modes (`lite`/`full`/`ultra`/`off`).

**SIMPLE** (chat/Q&A/theory) → respond direct. **MEDIUM** (1-file refactor) → decompose→parallel→merge. **COMPLEX** (multi-file, risky, arch) → full gate: 0) Factibilidad 1) skill-graph→Router 2) Load skill 3) ANTI-PATTERN-CATALOG 4) Engram 5) Load skill: triple-verify 6) Execute with checkpoint mid-task: verify alignment → continue or replan/abort.

> **TRIANGULATE**: Load skill `triple-verify`. Zones: Roja/Amarilla/Verde · 3 approaches (E1 testing, E2 static, E3 build) · If any fails → BLOQUEAR. Modes: Normal · `!ship` · `!check` · `!fast` · `!draft`.

## Workflow Shortcuts

> **Full reference**: [SHORTCUTS.md](SHORTCUTS.md)

| Shortcut | Action |
|----------|--------|
| `!health` | health-check + check-config-drift + git status |
| `!close` | `close-session.ps1` — unified close |
| `!ponytail` | Set intensity: `!ponytail [lite\|full\|ultra\|off]` |

## Analysis Mode (trigger: `!analisis`)

> Load skill `analysis-mode` for multi-agent analysis pipeline, 8 dimensions, specialist selection.

## Subagent-First

**RULE**: Main context = synthesis/decisions ONLY. Never read raw data >3 files.

| Task Type | Delegate To | Savings |
|-----------|-------------|---------|
| Read/grep/analyze >3 files | `explore` | 2-15K |
| Research + synthesis | `general` | 4-10K |

**Pattern**: Delegate explore → get summary → synthesize/decide → delegate implementation if >3 files.

**NEVER delegate**: Single file edits, git ops, script execution, final verification.

### Delegation Rules

> Full protocol in `delivery-harness` skill. Core rules:

- Delegate when >3 files or exploratory task. Max 6 concurrent. Depth 1 (no nesting). Min 3 steps (overhead > savings below that).
- Partition independent work → parallel subagents → merge → verify.

## Learning Loop

Capture→Extract→Evaluate→Apply. Triggers: same fix 2x · gotcha · user corrected 2x · repeat workflow · pattern 3+ files. Score/metrics via `!score`.

## Default-FAIL

Evidence = tool output. NOT self-assessment. Builder≠Evaluator. Uncertain? → FAIL.
- **Speculation gate**: Any claim without tool output that supports it is subject to Default-FAIL. "I think" or "probably" without evidence = FAIL. If uncertain, state `confidence: low` and offer to investigate via `!analisis`.

Post-task: mejora obvia → sugerir 1 línea. Drift or score drop >0.5 → proponer 1 mejora. Siempre sugerir, nunca actuar. Scoring via `!score`.

## Execution & Resource-Adaptive Mode

Infer: QUICK (simple→min) · THOROUGH (risky→full SDD) · DRAFT (explore→findings).

GREEN: Full/L1/Full/Auto-ejecutar · YELLOW: Brief+expand/L1+L2/Essential/Pedir nod humano (ctx>40%) · ORANGE: Headline/L2/Non-critical skip/Escalar a usuario (ctx>60%) · RED: 1-liner/file/L3/Skip all/Solo informar (ctx>80%)

## Risk-Adaptive Ceremony Zones (diff-based)

Auto-detect from diff:

TRIVIAL (1 file, ≤3 lines, comments/whitespace): git add + commit + secrets scan · LOW (≤3 files, test-only): quality-gate + commit-crafter + security · MEDIUM (3-8 files): quality-gate + triple-verify + security + commit-crafter · HIGH (>8 files or auth/storage/API/schema): Full pipeline + suggest `!audit` + `!score`

Default: **LOW**. No auto-metrics/auditor for trivial/low.

## Server Commands — LONG-LIVED PROCESSES

> Load skill `server-commands` for dev-server.ps1 workflow, port detection, background management.

## Skills (Auto-load)

> Load skill `skill-graph` for resolution, Top 18 list, Anti-Pattern Catalog, fallback routing, load order.

## Project Context

- **Repo**: Gentleman Agent — OpenCode skills, scripts & config
- **Skills**: `.agents/skills/` (79 + `_shared`, git-tracked) · workspace `skills/` (junctions, git-ignored). Overrides: `skill-validate.ps1`, `check-skill-drift.ps1`, `check-config-drift.ps1`, `skill-graph.ps1`, `health-check.ps1`, `sync-vmk.ps1`.
- **Cycle manifest**: `CYCLE.md` | **Global config**: `~/.config/opencode/skills/` | **Quality standard**: `docs/operations/quality-standard.md` | **Metrics**: `docs/metricas/`

---

*Protocol version: 2.2 — Project: gentleman-agent-gh, self-contained*
