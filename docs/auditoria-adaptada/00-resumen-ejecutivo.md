# Resumen Ejecutivo — Auditoría Adaptada gentleman-agent-gh

**Fecha:** 2026-07-03
**Metodología:** 9 subagentes en 4 categorías (GAPS, Seguridad, Revisión Lineal, Otros)
**Estado:** Solo lectura — no se modificó código

---

## Métricas Globales

| Métrica | Valor |
|---------|-------|
| **Total hallazgos** | **~193** (con solapamiento entre reportes) |
| 🔴 Críticos | 21 |
| 🟠 Altos | 38 |
| 🟡 Medios | 65 |
| 🟢 Bajos | 69 |
| **Reportes generados** | 8/9 (falta `scripts-parte2.md` — subagente no persistió el archivo) |
| **Score proyecto** | 10.0/10.0 (refleja código, no prevención) |

> **Nota:** Los hallazgos están solapados entre categorías (un mismo issue aparece en 2-3 reportes). El top 10 abajo está deduplicado.

---

## Top 10 Hallazgos Críticos (deduplicados)

| # | Severidad | Categoría | Descripción | Reportes |
|---|-----------|-----------|-------------|----------|
| 1 | 🔴 Crítico | **Seguridad** | `install.ps1:46` y `bootstrap.ps1:17` — **Download cradle sin verificación**: `Invoke-Expression (Invoke-WebRequest ...).Content` ejecuta código remoto sin checksum ni firma. Vector de supply-chain attack. | Negocio(#2), Auth(#1), Inyección(#1) |
| 2 | 🔴 Crítico | **Seguridad** | `.githooks/pre-commit` — **5 bloques de inyección de comandos**: `$REPO_ROOT` embebido sin escape en cadenas `-Command` de pwsh.exe. Permite inyección si el path del repo contiene caracteres especiales. | Auth(#3,#4) |
| 3 | 🔴 Crítico | **Consistencia** | `AGENTS.md` — **3 skill names incorrectos**: `gentle-ai-chained-pr` → `chained-pr`, `a11y` → `accessibility`, `model-router` → `opencode-model-router`. Afecta el routing del agente. | Consistencia(#1-#3), Funcional(#3) |
| 4 | 🔴 Crítico | **Lineal** | **3 scripts referenciados no existen**: `scripts/auto-metrics.ps1`, `scripts/commit-crafter.ps1`, `scripts/intake.ps1`. AGENTS.md los lista como parte del pipeline. | RevLineal P1(#19-#21) |
| 5 | 🔴 Crítico | **Edge Cases** | `scripts/inter-track.ps1:56,104` — **Race condition en JSON read-modify-write**: dos invocaciones simultáneas de `-Increment` pueden perder incrementos. | Negocio(#7) |
| 6 | 🔴 Crítico | **Edge Cases** | `scripts/backup.ps1` — **Sin `$ErrorActionPreference`**: fallas silenciosas en git init/add/commit. Backup parece exitoso pero no lo es. | Negocio(#1) |
| 7 | 🔴 Crítico | **Edge Cases** | `scripts/optimize-system.ps1:54-142` — **Sin rollback**: modifica registro HKLM, pagefile, hibernate, fsutil. Error a mitad de camino deja sistema inconsistente. | Negocio(#4) |
| 8 | 🔴 Crítico | **Edge Cases** | `scripts/pull-upstream.ps1:71`, `check-upstream.ps1:71` — **Path hardcodeado a Git Bash**: `C:\Program Files\Git\bin\bash.exe`. Rompe en instalaciones alternativas. | Negocio(#5,#6), Técnico(#2) |
| 9 | 🔴 Crítico | **Consistencia** | `docs/hallazgos-completos.md` — **Referencia a 5 scripts inexistentes** (`git-fast.ps1`, `measure-ps.ps1`, `memory-tune.ps1`, `skill-auto-generator.ps1`, `vmk-safety-check.ps1`). Docs desactualizados. | Consistencia(#4) |
| 10 | 🔴 Crítico | **Seguridad** | `scripts/restore.ps1:28,37` — **Path traversal potencial**: `$Revision` de usuario sin validación en `git checkout "$Revision" -- .`. | Inyección(#2) |

---

## Hallazgos Prioritarios Altos (top 10)

| # | Severidad | Descripción | Reporte |
|---|-----------|-------------|---------|
| 11 | 🟠 Alto | `scripts/skillspector-gate.ps1:124` — **Docker command injection**: `$DockerImage` sin validación permite ejecutar contenedor arbitrario. | Inyección(#5) |
| 12 | 🟠 Alto | **BOM inconsistente**: 35/55 scripts con BOM, 20 sin BOM. PSSA recomienda sin BOM. | Consistencia(#9) |
| 13 | 🟠 Alto | `scripts/verify.ps1:48` — **Secrets scan incompleto**: no detecta `GH_TOKEN`, `ghp_`, `github_pat_`, `AKIA`, claves SSH. | Datos(#1), Auth(#7) |
| 14 | 🟠 Alto | `scripts/score-auto.ps1:23` — **Skill secrets scan limitado**: solo skills/ no cubre scripts, workflows, config. | Datos(#2) |
| 15 | 🟠 Alto | `scripts/cross-ref-check.ps1:5` — **Parámetros de una letra** (`$J`, `$D`, `$s`, `$i`). Afecta mantenibilidad. Mismo patrón en 11 scripts. | Consistencia(#11) |
| 16 | 🟠 Alto | `opencode.json:202,218` — **Supply chain risk**: `npx -y` sin version pinning para MCPs context7 y sequential-thinking. | Auth(#6) |
| 17 | 🟠 Alto | **Falta secrets scan en pre-commit hook**: ninguno de los 9 checks escanea el diff por tokens/passwords. | Datos(#4) |
| 18 | 🟠 Alto | `scripts/bash-safe.ps1:60-66` — **Invoke-Bash sin sanitizar**: cualquier caller con input de usuario permite ejecución arbitraria (by design, pero sin documentar). | Auth(#12) |
| 19 | 🟠 Alto | `scripts/intake-verify.ps1:3` — **[bool] en vez de [switch]**: rompe convención PowerShell. Mismo patrón en `check-backlog-integrity.ps1`. | Técnico(#11) |
| 20 | 🟠 Alto | `scripts/check-upstream.ps1:91` — **Git ls-remote sin timeout**: si el remote no responde, script se cuelga. | Negocio(#29), Auth(#11) |

---

## Matriz de Riesgo por Categoría

| Categoría | 🔴 | 🟠 | 🟡 | 🟢 | Total | Peso |
|-----------|:--:|:--:|:--:|:--:|:-----:|:----:|
| GAPS · Funcional | 0 | 3 | 5 | 5 | 13 | 📄 Doc |
| GAPS · Técnico | 0 | 7 | 10 | 8 | 25 | 🔧 Deuda técnica |
| GAPS · Negocio/Edge | 7 | 11 | 13 | 12 | 43 | ⚠️ Riesgo |
| Seguridad · Auth | 4 | 3 | 8 | 8 | 23 | 🔒 Crítico |
| Seguridad · Inyección | 2 | 5 | 7 | 7 | 21 | 🔒 Crítico |
| Seguridad · Datos | 0 | 0 | 4 | 5 | 9 | ✅ Bueno |
| Revisión Lineal P1 | 3 | 1 | 3 | 14 | 21 | 🔧 Variado |
| Consistencia Global | 5 | 5 | 8 | 6 | 24 | 📐 Estructural |
| Otros Transversal | 0 | 3 | 7 | 4 | 14 | 🧹 Cosmético |

**Categorías más críticas:** Seguridad (6 críticos) + Edge Cases (7 críticos)

---

## Fortalezas Identificadas

- ✅ **Sin secretos hardcodeados** en 99 commits de git history
- ✅ `.gitignore` robusto (.env, .pem, .key, secrets/, credentials.json)
- ✅ `opencode.json` usa `{env:VAR}` para `CONTEXT7_API_KEY`
- ✅ **Multiples capas de detección**: check-mcp-security.ps1, verify.ps1, score-auto.ps1, quality-gate skill
- ✅ **55/56 scripts con ayuda .SYNOPSIS** documentada
- ✅ **Sin TODOs, FIXMEs, HACKs** en el código (disciplina encomiable)
- ✅ **Sin bloques grandes de código comentado**
- ✅ **Tests reales**: 34 archivos en .skillspector/tests/ con asserts genuinos
- ✅ **Score .project.json = 10.0/10.0**

---

## Recomendación de Priorización

| Prioridad | Acción | Items |
|-----------|--------|-------|
| **P0 - Inmediato** | Seguridad | Download cradles (install.ps1, bootstrap.ps1), inyección en pre-commit hook, secrets scan en pre-commit |
| **P1 - Alta** | Bugs funcionales | Scripts faltantes (auto-metrics.ps1, commit-crafter.ps1), AGENTS.md skill names, race conditions |
| **P2 - Media** | Deuda técnica | #requires duplicados, Set-StrictMode faltante, BOM inconsistente, paths hardcodeados |
| **P3 - Baja** | Housekeeping | JsonFast sin consumidor, comandos huérfanos, scripts huérfanos, encoding corruption |

---

**¿Apruebas iniciar implementación de P0 (seguridad) o querés revisar los reportes completos primero?**
