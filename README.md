# gentleman-vMK Agent Skills — OpenCode AI Agent Skills

Colección de **58 skills profesionales** para OpenCode AI agent. Diseñadas para desarrollo de software con arquitectura limpia, TDD real, y principios SR Engineer.

## Skills Incluidas

| Categoría | Skills | Versión |
|-----------|--------|---------|
| **Prompting** | karpathy-prompt, prompt-engineering, karpathy-loop, caveman, lean-context | v1.x |
| **Self-Improvement** | code-memory, self-reflection, skill-testing, judgment-day | v1.x |
| **Engineering** | senior-engineer, go-testing, skill-creator, skill-registry | v1.x |
| **Quality & Safety** | quality-gate, context-watchdog, recovery-protocol | v1.0 |
| **SDD Cycle** | sdd-init, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-explore, sdd-archive, sdd-onboard | v1.x |
| **PR & Workflow** | branch-pr, pr-evidence, issue-creation | v1.x |
| **Decisions** | decision-capture | v1.0 |
| **Performance** | performance-tracker | v1.0 |

**Total: 58 skills + _shared** — todas con SKILL.md, frontmatter YAML y licencia Apache-2.0.

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