# Análisis Profundo — gentleman-agent-gh

**Fecha**: 2026-07-21
**Especialistas**: Security, Performance, Frontend/UX, Infrastructure, Data Quality, Documentation
**Total findings**: 102 → consolidados a **top 15 por riesgo**

---

## Resumen Ejecutivo

El proyecto tiene una **arquitectura sólida** (22 agentes, 79 skills, CI/CD multi-capa, memoria persistente), pero acumuló deuda técnica significativa en 27 ciclos de mejora. Los problemas más críticos son:

1. **Pipeline de datos roto** — session-miner no puede extraer patrones porque sus archivos fuente no existen
2. **Seguridad del pre-commit** — inyección shell posible via paths mal escaneados
3. **Build roto** — PS 7.6 requerido vs Docker con PS 7.4
4. **SSoT desactualizado** — .project.json dice 9.1, cache dice 7.9
5. **Permisos de agentes** — el orquestador puede modificar opencode.json

---

## Tabla de Síntesis (Top 15)

| # | Finding | Consenso | Riesgo | Dim | Archivos | Recomendación |
|---|---------|----------|--------|-----|----------|---------------|
| 1 | **Pipeline de aprendizaje roto** — session-miner lee `.learnings/LEARNINGS.md` y `ERRORS.md` que no existen. `RepeatedPatterns` siempre es 0. El loop learn→immunize está desconectado. | UNANIMOUS (Data+Docs) | **CRITICAL** | Data | `scripts/session-miner.ps1:8,17-24` | Generar archivos desde Engram o redirigir miner a Engram MCP directamente |
| 2 | **health-check-system.ps1 crashea en Windows** — `Get-PSDrive -Name /` es path Linux. El `!health` (primera herramienta de diagnóstico) no funciona en la plataforma principal. | UNANIMOUS (Frontend+Infra) | **CRITICAL** | UX | `scripts/health-check-system.ps1:20` | Usar `$env:SystemDrive[0]` o `[System.IO.DriveInfo]::GetDrives()` |
| 3 | **Score SSoT divergente** — `.project.json` dice 9.1, `.learnings/score-cache.json` dice 7.9. Gap de 1.2pt. Las decisiones de ciclo se basan en datos stale. | MAJORITY (Data+Docs) | **CRITICAL** | Data | `.project.json:3-4` vs `.learnings/score-cache.json` | Agregar staleness gate: si cache es más nuevo, rechazar .project.json como SSoT |
| 4 | **Dimensiones de calidad desalineadas** — `quality-standard.md` lista 13 dims (Performance, SEO, UI/UX) que score-auto.ps1 nunca computa. score-auto.ps1 tiene 13 dims diferentes (Script Performance, Skill Effectiveness). Nadie sabe qué significa "calidad". | MAJORITY (Docs+Data) | **CRITICAL** | Docs | `docs/operations/quality-standard.md:8-22` vs `CYCLE.md:57-74` | Unificar en taxonomía única; quality-standard = "qué verificar", score-auto = "qué scoring" |
| 5 | **Pre-commit hook: inyección shell via `$REPO_ROOT_ESC`** — El escaping no maneja double-quotes ni backslashes. Un repo path con `$(malicious)` ejecuta código arbitrario durante `git commit`. | UNANIMOUS (Security) | **HIGH** | Security | `.githooks/pre-commit:10-11,107,134,158` | Usar `-File` con temp script en vez de `-Command` con strings interpolados |
| 6 | **Orchestrator puede escribir opencode.json** — `gentleman-vMK` tiene `write.* = allow` sin deny rules para archivos protegidos. Si agent-level overrides ganan sobre global denies → auto-modificación + escalación de privilegios. | MAJORITY (Security+Infra) | **HIGH** | Security | `opencode.json:217-268` | Cambiar orchestrator a `write.* = ask` como todos los otros executing agents |
| 7 | **install.ps1 requiere PS 7.6 pero Docker tiene PS 7.4** — `#requires -Version 7.6` vs `powershell:lts-7.4-ubuntu-22.04`. Build de Docker o ejecución de install.ps1 falla. | UNANIMOUS (Infra) | **HIGH** | Infra | `install.ps1:1` vs `Dockerfile:5` | Bajar `#requires` a 7.4 o subir Dockerfile a 7.6 |
| 8 | **Sin .dockerignore** — `COPY . .` envía `.git/`, `node_modules/`, `.learnings/` al build context. Historial .git filtrado en capas de imagen. | UNANIMOUS (Infra+Security) | **HIGH** | Infra | `Dockerfile:71` (falta .dockerignore) | Crear .dockerignore con .git, node_modules, .learnings, *.ps1 tests |
| 9 | **Release sin quality gate** — `release.yml` trigger solo por tag push, sin dependencia de `quality-gate.yml`. Tag roto = release roto. | UNANIMOUS (Infra) | **HIGH** | Infra | `.github/workflows/release.yml:1-30` | Agregar `workflow_run` dependency on quality-gate |
| 10 | **N+1 reads en score-dims.ps1** — 5+ `Get-Content` passes sobre los mismos 79 SKILL.md files para changelog, triggers, refs, redirects, frontmatter. ~400 reads redundantes por invocación. | MAJORITY (Performance+Data) | **HIGH** | Performance | `scripts/lib/score-dims.ps1:604-617` | Single read pass por SKILL.md, almacenar en hashtable, matchear todos los patrones |
| 11 | **gitleaks excluye archivos .tests.ps1** — `exclude: '.*\.tests\.ps1$'` permite secrets en test files bypass gitleaks. Test files son templates para secrets reales. | UNANIMOUS (Security) | **HIGH** | Security | `.pre-commit-config.yaml:30` | Remover exclusión; usar `# gitleaks:allow` inline para tokens de ejemplo |
| 12 | **npx -y @modelcontextprotocol/server-sequential-thinking — supply chain unpinned** — Descarga y ejecuta código de npm en runtime. Typosquat o publish comprometido = código arbitrario. | MAJORITY (Security+Infra) | **HIGH** | Security | `opencode.json:194` | Instalar a node_modules con lockfile + hash pin, o remover (está disabled) |
| 13 | **SP dimension: código muerto** — `elseif -gt 20` nunca se ejecuta porque `if -gt 15` lo captura primero. El penalty -2 es dead code. Scripts de 15-20KB nunca reciben penalización. | UNANIMOUS (Data) | **HIGH** | Data | `scripts/lib/score-dims.ps1:308-312` | Swap orden: verificar >20 primero, luego >15 |
| 14 | **README vs QUICKSTART: comandos de install diferentes** — README dice `install.ps1`, QUICKSTART dice `setup-machine.ps1`. Dos entry points confunden nuevos usuarios. | MAJORITY (Frontend+Docs) | **HIGH** | UX | `README.md:103-116` vs `QUICKSTART.md:28-32` | Unificar: `install.ps1` como entry point único (ya es wrapper de setup-machine) |
| 15 | **69 de 71 scripts son PS1-only — sin paridad Linux/macOS** — score-auto, verify, pssa-gate, batch, close-session, etc. no tienen .sh equivalentes. Usuarios Linux/macOS obtienen experiencia rota. | MAJORITY (Frontend+Infra) | **HIGH** | UX | `scripts/*.ps1` (69 archivos) | Crear wrappers SH para top 5 scripts user-facing (!score, !close, !health, !verify, !batch) |

---

## Hallazgos por Dimensión

### 🔒 Security (18 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 0 | — |
| HIGH | 3 | Shell injection pre-commit (#5), orchestrator write override (#6), gitleaks test exclusion (#11) |
| MEDIUM | 9 | npx unpinned, .gitleaks backup allowlist, Dockerfile pip bypass, ensure-tools PATH injection, SkillSpector silent fail, Engram no sandbox, .gitleaks no custom rules |
| LOW | 6 | ExecutionPolicy Bypass, .dockerignore excludes gitleaks, dev-server temp registry, no Dependabot config, release.yml mutable tag, non-standard .githooks |

### ⚡ Performance (12 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 0 | — |
| HIGH | 2 | N+1 SKILL.md reads (#10), CI zero dependency caching |
| MEDIUM | 6 | smoke-all hash before cache, skill-graph rebuild, verify sequential, CI identical checks on 2 OS |
| LOW | 4 | LATEST_error.json triple read, no token budget tracking, benchmark no timing, score-auto timeout silent |

### 🎨 Frontend/UX (20 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 1 | health-check Windows crash (#2) |
| HIGH | 3 | Install UX mismatch (#14), no Linux parity (#15), incomplete SHORTCUTS |
| MEDIUM | 10 | SKILLS-INDEX ambiguous triggers, QUICKSTART unrealistic, PROTOCOL wall of text, inconsistent error messages, stale score, vague troubleshooting |
| LOW | 6 | Duplicate skill entry, language mixing, ANTI-PATTERN-CATALOG not human-facing, SKILLS-INDEX load rule, no !score feedback, AGENTS.md no "what first" |

### 🏗️ Infrastructure (24 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 0 | — |
| HIGH | 3 | No HEALTHCHECK (#1), no .dockerignore (#8), release no quality gate (#9) |
| MEDIUM | 12 | Dockerfile redundant COPY, unpinned Node.js, no build cache, release empty notes, no checksums, Dependabot no Docker, no MCP monitoring, devcontainer missing features, PS version mismatch, SkillSpector silent fail, no CI caching, no SLSA |
| LOW | 9 | Two health checks overlap, no Pester matrix, no container registry push, install.sh no checksum, backup no push, Dockerfile chown, Dependabot no grouping, devcontainer no lifecycle |

### 📊 Data Quality (13 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 1 | Session-miner source files missing (#1) |
| HIGH | 3 | Score SSoT divergence (#3), unreachable SP code (#13), inter-track.json oscillation |
| MEDIUM | 5 | Benchmark stale, anti-pattern regex loose, delegation rate keyword count, bitacora line-count, metrics file-existence only |
| LOW | 3 | AGENTS.md regex loose, benchmark no baseline, anti-pattern no enforcement |

### 📝 Documentation (15 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 1 | Quality dimensions desalignadas (#4) |
| HIGH | 2 | .project.json skill count stale (68≠79), SHORTCUTS.md incomplete (missing 11) |
| MEDIUM | 5 | 3 skills missing license, SKILLS-INDEX 78≠79, no CONTRIBUTING link, CHANGELOG no versions, SECURITY.md no email |
| LOW | 7 | Script count 3 numbers, SPECIALIZED-AGENTS mis-categorize, install instructions differ, PROTOCOL bilingual, CYCLE.md inconsistent counts, no skill changelog, score in header |

---

## Matriz de Riesgo

```
                    ALTO IMPACTO
                         │
    ┌────────────────────┼────────────────────┐
    │ #1 Pipeline roto   │ #5 Shell injection │
    │ #2 health-crash    │ #6 Write override  │
    │ #3 Score SSoT      │ #7 PS version      │
    │ #4 Dim desalineadas│ #8 No .dockerignore│
    │                    │ #9 Release no gate │
    │   CRITICAL (fix    │   HIGH (fix en     │
    │   primero)         │   este ciclo)      │
    ├────────────────────┼────────────────────┤
    │ #10 N+1 reads      │ #11 gitleaks test  │
    │ #13 Dead code      │ #12 npx unpinned   │
    │                    │ #14 Install UX     │
    │   HIGH (fix cuando │   MEDIUM (backlog) │
    │   haya tiempo)     │                    │
    └────────────────────┼────────────────────┘
                         │
                    BAJO IMPACTO
```

---

## Recomendaciones por Fase

### Fase 1: Emergencia (esta semana)
1. **#2** — Fix `health-check-system.ps1:20` (1 línea, platform detection)
2. **#7** — Align PS versions (install.ps1 o Dockerfile)
3. **#1** — Reconectar session-miner a Engram o generar archivos fuentes
4. **#3** — Resolver score SSoT (correr score-auto.ps1 o agregar staleness gate)

### Fase 2: Seguridad (próximo ciclo)
5. **#5** — Fix pre-commit injection (usar -File en vez de -Command)
6. **#6** — Restrict orchestrator write permissions
7. **#11** — Remover gitleaks test exclusion
8. **#12** — Pin or remove npx MCP

### Fase 3: Calidad (ciclos 28-30)
9. **#4** — Unificar dimensiones de calidad
10. **#8** — Crear .dockerignore
11. **#9** — Agregar quality gate a release
12. **#10** — Optimizar score-dims.ps1 (single read pass)

### Fase 4: UX (ciclos 30+)
13. **#14** — Unificar entry points de install
14. **#15** — Crear wrappers SH para top 5 scripts
15. **#13** — Fix dead code en SP dimension

---

## Consenso de Especialistas

| Consenso | Findings | Descripción |
|----------|----------|-------------|
| **UNANIMOUS** | #1, #2, #5, #8, #9, #11, #13 | Todos los especialistas involucrados coinciden |
| **MAJORITY** | #3, #4, #6, #10, #12, #14, #15 | ≥50% de especialistas coinciden |
| **OUTLIER** | — | Ningún finding es outlier |

**Acknowledged limitation**: Architecture y Business se validaron por self-verification del orquestador (no hay especialista independiente para estas dimensiones).

---

*Generado por analysis-mode v4.4 — 6 especialistas, 8 dimensiones, 102 findings → 15 consolidados*
