# Gentleman Agent — OpenCode AI Agent Skills & Scripts

Suite de **69 skills** (+ `_shared`) + **49 scripts PowerShell** para [OpenCode](https://github.com/sst/opencode). Diseñadas para desarrollo de software con arquitectura limpia, TDD, y verificación multi-capa.

> **Repo**: `LuisAlbertoMK/gentleman-agent-gh`
> **Score**: 8.5/10 (13 dimensiones)
> **Skills**: 69 (+ `_shared` = 70 SKILL.md)
> **Cycle**: 21 completado (Universal Optimization)

---

## Características

### Multi-Agent Architecture
12 agentes especializados además del orquestador principal (`gentleman-vMK`):
7 FREE TIER + implementer + 3 core + SDD orchestrator:

| Agent | Model | Specialty |
|-------|-------|-----------|
| `gentleman-deep` | nemotron-3-ultra-free | Architecture, design, complex code |
| `gentleman-codex` | deepseek-v4-flash-free | Code generation, boilerplate |
| `gentleman-quick` | mimo-v2.5-free | Fast tasks, review, simple edits |
| `gentleman-security` | nemotron-3-ultra-free | Vulnerability analysis, secure code (FREE TIER) |
| `gentleman-seo` | nemotron-3-super-free | SEO, GEO, keyword analysis (FREE TIER) |
| `gentleman-infra` | deepseek-v4-flash-free | IaC, Kubernetes, CI/CD (FREE TIER) |
| `gentleman-frontend` | kimi-k2.5-free | React, Tailwind, accessibility (FREE TIER) |
| `gentleman-performance` | nemotron-3-ultra-free | Code optimization, bottlenecks (FREE TIER) |
| `gentleman-datascience` | mimo-v2.5-free | Pandas, SQL, stats (FREE TIER) |
| `gentleman-docs` | big-pickle | Technical writing, docs (FREE TIER) |
| `gentleman-implementer` | deepseek-v4-flash-free | Plan executor (FREE TIER) |
| `sdd-orchestrator` | claude-sonnet-4-6 | SDD pipeline orchestration |

### Self-Improvement Cycle
El proyecto ejecuta ciclos de mejora continua (CYCLE.md):

- **Backlog priorizado** por Impacto/Riesgo
- **Métrica inter(30)**: mínimo 30 interacciones significativas por ciclo
- **Triple verificación** (E1/E2/E3) por dificultad
- **Score auto-actualizado** tras cada cambio significativo
- **Bias calibration** contra external auditor subagent

### Verification Pipeline

| Modo | Verify | Gate | Commit |
|------|--------|------|--------|
| `!ship` | Triple verify | Quality gate + PSSA | ✅ auto |
| `!check` | Verify profiles | Quality gate | ❌ |
| `!fast` | Skip | Quality gate | ✅ auto |
| `!draft` | Skip | Skip | ❌ |
| `!close` | — | — | Session close |

### Workflow Shortcuts
| Keyword | Action |
|---------|--------|
| `!compress` | Karpathy compress skills >2.5KB + score update |
| `!score` | Score auto-update + docs/operations/project-score.md sync |
| `!sync` | Upstream check + drift + score update |
| `!health` | Full diagnostics (git, drift, cross-ref, score, inter) |
| `!batch` | New batch with auto-increment + bitacora + inter-track++ |
| `!cycle` | Cycle status summary |
| `!close` | Session close pipeline (bitacora + inter-track + git status) |

### SDD Pipeline (Spec-Driven Development)
8 fases completas: `init → propose → spec → design → tasks → apply → verify → archive`

---

## Instalación

### Windows (PowerShell 7+)
```powershell
# Clonar e instalar
git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git
cd gentleman-agent-gh
.\scripts\install.ps1
```

### Linux/macOS
```bash
# Clonar e instalar
git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git
cd gentleman-agent-gh
./scripts/install.sh
```

### MCP Setup (recomendado)
El proyecto usa dos MCPs para memoria cross-session:

- **[Engram](https://engram.mentat.ai)**: Memoria persistente. Instalar con `opencode mcp add engram`
- **Context7**: Documentación actualizada de librerías. Instalar con `opencode mcp add context7`

---

## Skills Incluidas

| Categoría | Skills |
|-----------|--------|
| **Compression** | karpathy-loop, lean-context, caveman |
| **Quality** | quality-gate, auto-metrics, external-auditor, immune-system, triple-verify |
| **Code Review** | code-review-agent, judgment-day |
| **Memory** | session-resume, code-memory, dreaming |
| **Skills Meta** | skill-creator, skill-registry, skill-improver, skill-digestion, skill-graph |
| **SDD** | sdd, sdd-onboard (phases consolidated into unified pipeline) |
| **Engineering** | senior-engineer, go-testing, python-async, refactoring-planner, project-mapper |
| **Security** | security-scanner |
| **UI/Web** | baseline-ui, accessibility, performance, seo, web-quality-audit, best-practices |
| **PR/Workflow** | commit-crafter, work-unit-commits, branch-pr, chained-pr |
| **Orchestration** | delivery-harness, subagent-isolation, command-wrapper, opencode-model-router |
| **Decisions** | decision-capture, cognitive-doc-design |
| **Docs** | doc-sync, bitacora, comment-writer |
| **Research** | research, prompt-engineering |
| **Self-Improvement** | self-improvement (merged self-reflection) |
| **DevOps** | ci-cd |
| **Testing** | skill-testing |
| **Others** | recovery-protocol, context-watchdog, performance-tracker, metricas, issue-creation, development-mode, execution-mode |

**Total: 69 skills + `_shared`** — todas con SKILL.md, frontmatter YAML, versionado, cambio previo y licencia Apache-2.0.

---

## Scripts (49 en scripts/)

| Script | Propósito |
|--------|-----------|
| `score-auto.ps1` | Auto-scoring del proyecto en 13 dimensiones + 32 sub-dims |
| `skill-graph.ps1` | Resolución BFS de skills (carga sparse, −85-92%) |
| `verify.ps1` | Triple verificación E1/E2/E3 |
| `pssa-gate.ps1` | PSScriptAnalyzer con auto-fix de BOM |
| `inter-track.ps1` | Tracking de interacciones por ciclo |
| `cross-ref-check.ps1` | Consistencia skills ↔ SKILLS-INDEX |
| `check-skill-drift.ps1` | Detección de drift entre canonical y global |
| `check-backlog-integrity.ps1` | Verificación de backlog vs realidad |
| `check-upstream.ps1` | Monitoreo de repos externos |
| `batch.ps1` | Batch auto-incremental con bitácora |
| `close-session.ps1` | Pipeline unificado de cierre de sesión |
| `restore-project-score.ps1` | Restaura .project.json si vMK lo sobrescribe |
| `run.ps1` | Universal runner desde junction global |
| `ensure-tools.ps1` | Verifica rg/sg/gh en PATH |
| `token-count.ps1` | Cuenta tokens aproximados |
| `session-miner.ps1` | Minería cross-session para patrones |
| `run-dreaming.ps1` | Disparador de dreaming auto |
| `skill-validate.ps1` | Validación multi-trial de skills |
| `smoke/smoke-all.ps1` | Tests de humo para claims de automatización |
| `benchmark.ps1` | Benchmarking de skills y scripts |
| `trend.ps1` | Análisis de tendencias de scoring |
| `install.ps1` / `install.sh` | Instalador multi-plataforma (Windows/Linux/macOS) |

---

## Arquitectura

```
gentleman-agent-gh/
├── .agents/skills/          # 69 skills + _shared (canonical, git-tracked)
│   ├── quality-gate/
│   ├── code-review-agent/
│   └── .../
├── skills/                  # Junctions workspace (git-ignored)
├── scripts/                 # 49 PowerShell scripts
│   └── smoke/               # Smoke tests
├── docs/                    # Documentation
│   ├── metricas/            # Session metrics
│   ├── ciclos/              # Self-improvement cycle reports
│   ├── audits/              # External audit reports
│   ├── errors/               # Error analysis reports
│   ├── architecture/        # Architecture decisions & analysis
│   ├── operations/          # Quality standard, runbooks
│   ├── CHANGELOG.md         # Release history
│   ├── CONTRIBUTING.md      # How to contribute
│   └── ...
├── .learnings/              # Session mining + bias calibration
├── .project.json            # Auto-scored project state
├── AGENTS.md                # Full agent protocol (~350 lines)
├── CYCLE.md                 # Self-improvement cycle manifest
├── ANTI-PATTERN-CATALOG.md  # 23 immunized patterns
├── SKILLS-INDEX.md           # Skill registry with triggers
└── review-rules.jsonc       # Zone-based verification policy
```

---

## Convenciones

- **Commits**: Conventional Commits (`fix(scripts):`, `feat(cycle7):`, `docs(readme):`, etc.)
- **TDD**: Test-first, code-after
- **Memoria**: Engram persistent memory con protocolo MCP
- **Verificación**: Triple verify (E1/E2/E3) antes de `!ship`
- **Anti-patrones**: Catálogo con 23 patrones inmunizados
- **Auto-metrics**: Post-task auto-evaluación en 7 dimensiones con bias calibration

---

---

## Quick Reference

### Flujo típico

```
1. gentleman-vmk               ← abrir agente
2. "haz X"                     ← pedir tarea
3. el agente resuelve solo     ← cambios triviales = sin ceremony
4. !score                      ← opcional: medir resultado
5. !close                      ← cerrar sesión
```

### Tips

- **Ponytail `lite`** = default. Solo chequea si algo es necesario antes de codear.
- **Ponytail `full`** = para cambios complejos. Activa más gates de calidad.
- **No necesitas** acordarte de todo — el agente sabe cuándo aplicar cada cosa.
- **Dudas**: `!health` para diagnóstico, `!manifest` para ver el ciclo actual.

### Shortcuts principales

| Shortcut | Acción |
|----------|--------|
| `!score` | Score-auto + docs update + cross-ref |
| `!health` | Git status, drift, cross-ref, score |
| `!close` | Pipeline de cierre unificado |
| `!setup` | Setup máquina nueva (.ps1 o .sh según OS) |
| `!dev` | Manage background dev servers |
| `!gentleman` | Heredar config en otro proyecto |
| `!analisis` | Análisis multi-agente profundo |
| `!batch` | Batch auto-incremental + bitácora |
| `!cycle` | Inter-track + score + upstream |
| `!ponytail {lite\|full\|ultra\|off}` | Cambiar intensidad de ceremony |

---

## Basado en

- Método Karpathy (prompts mínimos, compresión recursiva)
- SPEAR Framework (prompt engineering)
- Competencias Staff+ Engineer (2026)
- SkillsBench Benchmark
- Engram Persistent Memory (Go + SQLite + FTS5)
- Hermes Agent (SkillForge + Curator + SkillInjector)
