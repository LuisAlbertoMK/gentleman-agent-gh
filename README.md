# Gentleman Agent — OpenCode AI Agent Skills & Scripts

Suite de **70 skills** (+ `_shared`) + **40 scripts PowerShell** para [OpenCode](https://github.com/sst/opencode). Diseñadas para desarrollo de software con arquitectura limpia, TDD, y verificación multi-capa.

> **Repo**: `LuisAlbertoMK/gentleman-agent-gh`
> **Score**: 10/10 (13 dimensiones)
> **Skills**: 69 (+ `_shared` = 70 SKILL.md)
> **Cycle**: 10 activo (full-spectrum quality)

---

## Características

### Multi-Agent Architecture
4 agentes especializados además del orquestador principal (`gentleman-vMK`):

| Agent | Model | Specialty |
|-------|-------|-----------|
| `gentleman-deep` | Claude Sonnet | Architecture, design, complex code |
| `gentleman-codex` | GPT-4o | Code generation, boilerplate |
| `gentleman-quick` | Haiku | Fast tasks, review, simple edits |
| `sdd-orchestrator` | Claude Sonnet | SDD pipeline orchestration |

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

### Windows (PowerShell 5.1+)
```powershell
# Clonar e instalar
git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git
cd gentleman-agent-gh
.\scripts\install.ps1
```

### Linux/macOS
```bash
# Clonar
git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git
cd gentleman-agent-gh

# Copiar skills a OpenCode
mkdir -p ~/.config/opencode/skills/
cp -r .agents/skills/* ~/.config/opencode/skills/
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
| **Code Review** | code-review-agent, judgment-day, review-pipeline |
| **Memory** | session-resume, code-memory, dreaming |
| **Skills Meta** | skill-creator, skill-registry, skill-improver, skill-digestion, skill-graph |
| **SDD** | sdd-init, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-explore, sdd-archive, sdd-onboard + 9 backward-compat wrappers |
| **Engineering** | senior-engineer, go-testing, python-async, refactoring-planner, project-mapper |
| **Security** | security-scanner |
| **UI/Web** | baseline-ui, accessibility, performance, seo, web-quality-audit, best-practices |
| **PR/Workflow** | commit-crafter, work-unit-commits, branch-pr, chained-pr |
| **Orchestration** | delivery-harness, subagent-isolation, command-wrapper, opencode-model-router |
| **Decisions** | decision-capture, cognitive-doc-design |
| **Docs** | doc-sync, bitacora, comment-writer |
| **Research** | research, prompt-engineering |
| **Self-Improvement** | self-reflection, self-improvement |
| **DevOps** | ci-cd |
| **Testing** | skill-testing |
| **Others** | recovery-protocol, context-watchdog, performance-tracker, metricas, issue-creation, development-mode, execution-mode |

**Total: 70 skills + `_shared`** — todas con SKILL.md, frontmatter YAML, versionado, cambio previo y licencia Apache-2.0.

---

## Scripts (36 en scripts/)

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
| `install.ps1` | Instalador de gentleman-agent-gh (junctions globales) |

---

## Arquitectura

```
gentleman-agent-gh/
├── .agents/skills/          # 70 skills + _shared (canonical, git-tracked)
│   ├── quality-gate/
│   ├── code-review-agent/
│   └── .../
├── skills/                  # Junctions workspace (git-ignored)
├── scripts/                 # 40 PowerShell scripts
│   └── smoke/               # Smoke tests
├── docs/                    # Documentation
│   ├── metricas/            # Session metrics
│   ├── quality-standard.md  # Quality framework
│   └── ...
├── .learnings/              # Session mining + bias calibration
├── .project.json            # Auto-scored project state
├── AGENTS.md                # Full agent protocol (~350 lines)
├── CYCLE.md                 # Self-improvement cycle manifest
├── ANTI-PATTERN-CATALOG.md  # 20 immunized patterns
├── SKILLS-INDEX.md           # Skill registry with triggers
└── review-rules.jsonc       # Zone-based verification policy
```

---

## Convenciones

- **Commits**: Conventional Commits (`fix(scripts):`, `feat(cycle7):`, `docs(readme):`, etc.)
- **TDD**: Test-first, code-after
- **Memoria**: Engram persistent memory con protocolo MCP
- **Verificación**: Triple verify (E1/E2/E3) antes de `!ship`
- **Anti-patrones**: Catálogo con 20 patrones inmunizados
- **Auto-metrics**: Post-task auto-evaluación en 7 dimensiones con bias calibration

---

## Basado en

- Método Karpathy (prompts mínimos, compresión recursiva)
- SPEAR Framework (prompt engineering)
- Competencias Staff+ Engineer (2026)
- SkillsBench Benchmark
- Engram Persistent Memory (Go + SQLite + FTS5)
- Hermes Agent (SkillForge + Curator + SkillInjector)
