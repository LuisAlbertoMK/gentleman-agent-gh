# gentleman-vMK Agent Skills — OpenCode AI Agent Skills

Colección de **69 skills profesionales** para OpenCode AI agent. Diseñadas para desarrollo de software con arquitectura limpia, TDD real, y principios SR Engineer.

## Skills Incluidas

| Categoría | Skills | Versión |
|-----------|--------|---------|
| **Prompting** | karpathy-loop (merged karpathy-prompt), prompt-engineering, lean-context, caveman | v2.0 |
| **Self-Improvement** | code-memory, self-reflection, skill-testing, judgment-day, immune-system, auto-metrics, self-improvement | v1.x |
| **Engineering** | senior-engineer, go-testing, skill-creator, skill-registry, python-async | v1.x |
| **Quality & Safety** | quality-gate, context-watchdog, recovery-protocol, security-scanner | v1.0 |
| **SDD Cycle** | sdd-init, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-explore, sdd-archive, sdd-onboard | v1.x |
| **PR & Workflow** | commit-crafter, code-review-agent, work-unit-commits, branch-pr, chained-pr | v1.x |
| **Decisions** | decision-capture | v1.0 |
| **Performance** | performance-tracker, performance, baseline-ui | v1.0 |
| **Routing** | opencode-model-router, skill-graph, execution-mode, development-mode | v1.0 |
| **Docs & Sync** | doc-sync, bitacora, cognitive-doc-design, comment-writer | v1.0 |

**Total: 69 skills + _shared** — todas con SKILL.md, frontmatter YAML y licencia Apache-2.0.

## Instalación

```bash
# Clonar
git clone https://github.com/LuisAlbertoMK/gentleman-vMK-agent-gh
cd gentleman-vMK-agent-gh

# Copiar skills a OpenCode
cp -r */ ~/.config/opencode/skills/
```

## Uso

Las skills se auto-cargan según el contexto detectado. Ver `AGENTS.md` para la tabla completa de triggers.

El flujo principal es **SDD** (Spec-Driven Development):
1. `sdd-init` → bootstrap proyecto
2. `sdd-propose` → definir alcance
3. `sdd-spec` → escribir especificaciones con escenarios
4. `sdd-design` → diseño técnico
5. `sdd-tasks` → breakdown de tareas
6. `sdd-apply` → implementación TDD
7. `sdd-verify` → validación contra spec
8. `sdd-archive` → archivar cambios

Soporte transversal: `quality-gate` (pre-commit), `context-watchdog` (memoria), `decision-capture` (log arquitectura), `recovery-protocol` (manejo de errores).

## Convenciones

- **Commits**: Conventional Commits (`feat:`, `fix:`, `refactor:`, `perf:`, etc.)
- **TDD**: Strict TDD — test primero, código después
- **Memoria**: Engram persistent memory para decisiones cross-session
- **PRs**: SDD evidence adjunta como verificacion

## Basado en

- Método Karpathy (prompts mínimos)
- SPEAR Framework (prompt engineering)
- Competencias Staff+ Engineer (2026)
- SkillsBench Benchmark
- Engram Persistent Memory (Go + SQLite + FTS5)

## Utilidades

| Script | Propósito |
|--------|-----------|
| `scripts/ensure-tools.ps1` | Verifica rg/sg/gh en PATH con triple verificación |
| `scripts/token-count.ps1` | Cuenta tokens aproximados en archivos |
| `scripts/bench-file-io.ps1` | Benchmark de 3 métodos de lectura de archivos |
| `scripts/skill-validate.ps1` | Validación multi-trial de skills |
| `scripts/cross-ref-check.ps1` | Verifica consistencia entre skills y SKILLS-INDEX |
| `scripts/auto-clean.ps1` | Limpia temp files >24h al inicio de sesión |