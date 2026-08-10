# Análisis gentleman-agent-gh — 2026-08-09

## Resumen Ejecutivo

**Proyecto**: gentleman-vMK-agent-gh (configuración de agente opencode)
**Branch**: `experimento/mejora-autonoma-2026-08-09`
**Fecha**: 2026-08-09
**Modo**: auto

**Stack**: 87 skills, 192 scripts PowerShell, 45 agents, configuración multi-modo

**Conclusión**: Arquitectura sólida (skill-driven, multi-agent orchestration) con gaps en testing (solo 3 archivos), seguridad de auto-mode (bash casi sin restricciones), y onboarding (78 skills abrumadores).

---

## Hallazgos por Dimensión

### 1. Security — UNANIMOUS (3 findings críticos)

**[CRITICAL] Auto-mode agents tienen bash casi sin restricciones**
- **Archivos**: `opencode.json:352, 493, 629, 1018, 1073, 1124, 1178, 1231, 1485`
- **Problema**: `gentleman-*-auto` y `gentleman-*-sub-auto` configuran `"bash": "*": "allow"` con deny-list mínima. Pueden ejecutar `rm -rf /`, `git reset --hard`, `npm run <malicious-script>`.
- **Recomendación**: Agregar denials explícitos para `rm *`, `Remove-Item *`, `git reset --hard`, `git clean -fd` en auto-mode.

**[HIGH] bash-safe.ps1 background path tiene escaping frágil**
- **Archivo**: `scripts/bash-safe.ps1:207-209`
- **Problema**: Construye `ProcessStartInfo.Arguments` con escaping manual (`$Command -replace '\\', '\\\\' -replace '"', '\"' -replace '\$', '``$'`). Orden importa, pero no protege contra backticks o ANSI-C `$'...'`.
- **Recomendación**: Usar `ProcessStartInfo.ArgumentList` (array) en lugar de string concatenado, o validar con regex whitelist.

**[HIGH] Deny patterns incompletos en permission-gate-lib.ps1**
- **Archivo**: `scripts/lib/permission-gate-lib.ps1:78-81`
- **Problema**: Patrones `^npx\s`, `^bun\s(install|add)\s` no bloquean invocaciones bare (`npx`, `bun`, `pnpm`, `yarn` sin args). Fallback tiene solo 22 reglas vs 83 en JSON.
- **Recomendación**: Agregar `^npx$`, `^bun$`, `^pnpm$`, `^yarn$` como denials bare.

### 2. Infrastructure — MAJORITY (3 findings)

**[CRITICAL] Root-level clutter**
- **Archivos**: `_testrun.log`, `_toolout.log`, `$null`, `temp/`, `coverage.xml` en root
- **Problema**: 15+ archivos sueltos polucionan root del proyecto.
- **Recomendación**: Mover a `tmp/` o agregar a `.gitignore`. Limpiar root.

**[HIGH] Dual opencode.json sin SSoT enforcement**
- **Archivos**: `opencode.json`, `.opencode/opencode.json`
- **Problema**: Dos instancias de configuración sin mecanismo de sincronización automática.
- **Recomendación**: Designar uno como SSoT, el otro como symlink o generado automáticamente.

**[HIGH] Zero CI/CD configuration**
- **Problema**: No hay `.github/workflows`, Jenkinsfile, o pipeline definition. Scripts existen pero no hay enforcement automático.
- **Recomendación**: Agregar GitHub Actions workflow para validación de scripts (PSSA), tokenización, y tests.

### 3. Documentation — MAJORITY (3 findings)

**[HIGH] README lacks onboarding sections**
- **Archivo**: `README.md:1-60`
- **Problema**: No tiene `## Quick Start`, `## Getting Started`, `## Prerequisites`, o `## Configuration`. Depende de `QUICKSTART.md` externo.
- **Recomendación**: Agregar bloque de 5 líneas inline con quick-start mínimo.

**[MEDIUM] Standard files in non-root locations**
- **Archivos**: `docs/CHANGELOG.md`, `docs/CONTRIBUTING.md`
- **Problema**: GitHub auto-detecta root `CHANGELOG.md`/`CONTRIBUTING.md` para UI badges. Layout no-estándar rompe convenciones.
- **Recomendación**: Mover a root o crear symlinks. Documentar decisión en ADR.

**[MEDIUM] Script documentation inconsistency**
- **Archivos**: `scripts/*.ps1`
- **Problema**: Solo 2/91 scripts verificados con documentación completa (`.SYNOPSIS`/`.DESCRIPTION`/`.PARAMETER`/`.EXAMPLE`).
- **Recomendación**: Establecer estándar de documentación mínima para scripts públicos.

### 4. Architecture — SPLIT (bien diseñado pero complejo)

**[HIGH] Skill organization buena pero abrumadora**
- **Archivos**: `.agents/skills/` (87 skills), `SKILLS-INDEX.md:33-47`
- **Problema**: 78 skills categorizados en 10 grupos. Bien organizado pero cognitive load alto para nuevos usuarios.
- **Recomendación**: Crear "skill starter pack" con top-10 skills esenciales. Progressive disclosure.

**[HIGH] Prompt structure two-layer bien diseñada**
- **Archivos**: `prompts/shared/` (5 contratos), `prompts/specialists/` (15 agentes)
- **Fortaleza**: Composición de contratos base + especialistas. Orchestrator inyecta `_core-behavior-gp.md` universalmente.
- **Recomendación**: Documentar patrón de composición en ADR.

**[MEDIUM] Agent configuration con mode-aware routing**
- **Archivos**: `opencode.json` (40+ agents), `PROTOCOL.md:11-16`
- **Problema**: Mode-aware routing implementado via suffix permutation (`-semi`, `-auto`), requiere mantener 3x variantes de agentes.
- **Recomendación**: Considerar runtime mode resolution en lugar de static variants.

### 5. DX — UNANIMOUS (3 findings críticos)

**[HIGH] Onboarding overwhelming**
- **Archivos**: `AGENTS.md:31-75`, `QUICKSTART.md:1-144`
- **Problema**: QUICKSTART claro pero AGENTS.md lista 45 agents + 78 skills simultáneamente. No hay progressive disclosure.
- **Recomendación**: Crear "Day 1 path" con 5 agentes esenciales + 10 skills básicas.

**[HIGH] Testing minimal coverage**
- **Archivos**: `tests/` (solo 3 archivos)
- **Problema**: Solo 3 test files (`validate-write-scope.Tests.ps1`, `check-subagent-output.Tests.ps1`, `opencode.json-size.Tests.ps1`). No hay test discovery convention, no CI integration, no coverage tracking.
- **Recomendación**: Agregar tests para scripts críticos (bash-safe.ps1, permission-gate-lib.ps1, health-check.ps1). Objetivo: 10+ test files.

**[HIGH] Configuration management implícito**
- **Archivos**: `.gentleman-mode`, `scripts/switch-mode.ps1:47-63`
- **Problema**: Mode switching via file-based pero no hay indicador visual en OpenCode UI. MCP section excluida de drift detection (intencional).
- **Recomendación**: Agregar status bar indicator o prompt prefix mostrando modo actual.

### 6-8. Performance / Data / Business — N/A

Proyecto es configuración de agente, no aplicación runtime. No aplica análisis de performance, datos, o business logic.

---

## Priorización ICE (Top 5 gaps)

| # | Gap | Impacto (1-10) | Confianza (1-10) | Esfuerzo (1-10) | Score ICE |
|---|-----|----------------|------------------|-----------------|-----------|
| 1 | Testing coverage (3 → 10+ files) | 9 | 9 | 6 | **486** |
| 2 | Auto-mode bash restrictions | 8 | 8 | 4 | **256** |
| 3 | README onboarding sections | 7 | 9 | 3 | **189** |
| 4 | Root-level cleanup + .gitignore | 6 | 9 | 2 | **108** |
| 5 | Script documentation consistency | 5 | 7 | 8 | **280** |

**Criterios ICE**:
- **Impacto**: ¿Cuánto mejora la calidad del proyecto? (1=mínimo, 10=máximo)
- **Confianza**: ¿Qué tan seguros estamos de que esta es la solución correcta? (1=duda, 10=certeza)
- **Esfuerzo**: ¿Cuánto trabajo requiere? (1=fácil, 10=muy difícil) — **inverso**: menor esfuerzo = mayor score

---

## Baseline Capturado

**Métricas actuales**:
- Skills: 87 (SKILL.md files)
- Scripts PowerShell: 192
- Tests: 3 archivos (cobertura ~1.5%)
- Agentes: 45 definidos en opencode.json
- Documentación de skills: 100% frontmatter coverage
- Scripts sin documentación: ~6/192 (3%)
- Vulnerabilidades npm: no verificado (npm audit bloqueado por permisos)

**Branch**: `experimento/mejora-autonoma-2026-08-09` (desde main)

---

## Próximos Pasos (Ciclo 1)

Según protocolo de mejora autónoma:

1. **Atacar gap #1 (Testing coverage)** — Score ICE más alto (486)
   - Generar ≥3 enfoques distintos
   - Implementar enfoque elegido
   - Ejecutar batería de ruptura
   - Medir métricas vs baseline

2. **Presupuesto definido**:
   - Máx ciclos: 5
   - Máx tiempo por ciclo: 45 min
   - Umbral decreciente: 5% mejora marginal
   - Checkpoint humano: cada 3 ciclos

3. **Condición de parada**:
   - Gap #1 resuelto (10+ test files)
   - 100% tests pasan
   - Benchmark mejora vs baseline
   - O presupuesto agotado

---

## Enram Persistence

**Memory ID**: 2565
**Topic Key**: `analysis/gentleman-agent-gh`
**Timestamp**: 2026-08-09T04:19:17Z
