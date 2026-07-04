# Resumen Ejecutivo — Auditoría Consolidada gentleman-agent-gh

> **Fecha:** 2026-07-03
> **Metodología:** 3 subagentes de análisis (estado, cross-ref, estructura) sobre 3 fuentes previas
> **Verificación:** Subagente 2 contrastó cada hallazgo contra código real con scores de confianza

---

## Métricas Globales

| Métrica | Valor |
|---------|-------|
| Total hallazgos únicos (deduplicados) | 31 |
| Total original con solapamiento | ~193 |
| 🔴 Críticos | 6 |
| 🟠 Altos | 5 |
| 🟡 Medios | 10 |
| 🟢 Bajos | 10 |
| ✅ Resueltos desde los reportes originales | 17 (55%) |
| Reportes generados | 8/9 originales + 7 nuevos consolidados |

---

## Top 10 Hallazgos Vigentes (pendientes + regresiones)

| # | ID | Sev | Categoría | Descripción | Estado |
|---|----|-----|-----------|-------------|--------|
| 1 | H-001 | 🔴 | **SEG** | Download cradle opcional: `Invoke-Expression (Invoke-WebRequest ...).Content` sin checksum. Flujo principal ya no lo usa (usa setup-machine.ps1), pero el paso opcional de gentle-ai CLI sigue siendo vector de supply-chain attack. | 🔴 Pendiente |
| 2 | H-003 | 🔴 | **ARC** | 8 scripts referenciados en AGENTS.md y docs no existen: auto-metrics.ps1, commit-crafter.ps1, intake.ps1, git-fast.ps1, measure-ps.ps1, memory-tune.ps1, skill-auto-generator.ps1, vmk-safety-check.ps1. Llevan 3 auditorías sin resolver. | 🔴 Pendiente |
| 3 | H-004 | 🔴 | **ARC** | Race condition en inter-track.ps1:56,104 — JSON read-modify-write sin lock. Dos invocaciones simultáneas de -Increment pueden perder incrementos. | 🔴 Pendiente |
| 4 | H-005 | 🔴 | **OPS** | backup.ps1 sin $ErrorActionPreference — fallas silenciosas en git init/add/commit. Backup parece exitoso pero no lo es. ❓ No verificado en código actual. | ❓ Pendiente |
| 5 | H-006 | 🔴 | **OPS** | optimize-system.ps1:54-142 sin rollback — modifica HKLM, pagefile, hibernate, fsutil. Error a mitad de camino deja sistema inconsistente. ❓ No verificado. | ❓ Pendiente |
| 6 | H-007 | 🟠 | **OPS** | Path Git Bash hardcodeado (`C:\Program Files\Git\bin\bash.exe`) en pull-upstream.ps1:71, check-upstream.ps1:71. Rompe en instalaciones alternativas. | 🔴 Pendiente |
| 7 | H-009 | 🟠 | **SEG** | Secrets scan incompleto: verify.ps1 no detecta GH_TOKEN, ghp_, github_pat_, AKIA, claves SSH. score-auto.ps1 solo escanea skills/ no cubre scripts, workflows, config. | 🔴 Pendiente |
| 8 | H-015 | 🟡 | **ARC** | restore.ps1:28,37 — path traversal potencial: `$Revision` de usuario sin validación en `git checkout "$Revision" -- .` | 🔴 Pendiente |
| 9 | H-019 | 🟡 | **OPS** | Overweight skill check (P3 auditoría externa) no cubre commands/ + prompts/ — solo escanea `.agents/skills/*/SKILL.md` | 🟡 Parcial |
| 10 | H-011 | 🟡 | **PERF** | GA2: `ForEach-Object -Parallel` en hot paths no implementado (skill-graph.ps1, score-auto.ps1, pssa-gate.ps1) | 🟡 Parcial |

---

## Matriz de Riesgo por Categoría Consolidada

| Categoría | 🔴 Críticos | 🟠 Altos | 🟡 Medios | 🟢 Bajos | Total | Peso |
|-----------|:----------:|:--------:|:---------:|:--------:|:----:|:----:|
| **SEG** Seguridad | 1 | 1 | 2 | 0 | 4 | 🔒 Crítico |
| **ARC** Arquitectura | 2 | 2 | 2 | 4 | 10 | 🔧 Deuda técnica |
| **PERF** Rendimiento | 0 | 0 | 4 | 4 | 8 | ⚡ Optimización |
| **OPS** Operaciones | 2 | 1 | 2 | 1 | 6 | ⚙️ Infra |
| **ORTO** Consistencia | 0 | 0 | 0 | 3 | 3 | 📐 Docs |

---

## Lo que YA está resuelto (de los reportes originales)

| Hallazgo | Resuelto en |
|----------|-------------|
| PS7 migration (19%→98% scripts con #requires -Version 7.6) | Commit 3b144ab |
| install.ps1 instalaba gentle-ai (F3 externa) | Commit a1ca033 + exclusion list |
| AGENTS.md skill names incorrectos | Commits a656b27 + 70aeffc |
| Pre-commit injection (5 bloques) | Commit 3b144ab |
| skills/ trackeadas en git divergentes | Commit a1ca033 (`git rm --cached`) |
| CI solo Windows → matrix Windows+Ubuntu | quality-gate.yml actualizado |
| README modelos desactualizados | Commit 99c36fe |
| Score desync (4 fuentes, 4 números) | Commit 99c36fe |
| Skill count inconsistente (F1) | Commit 99c36fe |
| .env.example mojibake (P5) | Commit 99c36fe |
| JsonFast module (GA3) | scripts/lib/JsonFast.psm1 creado |
| PSSA Gate auto-fix (GC1) | scripts/pssa-gate.ps1 existe |

---

## Priorización Recomendada

| Prioridad | Acción | Items |
|-----------|--------|-------|
| **P0 - Inmediato** | Decidir sobre 8 scripts fantasmas | H-003 — crear o eliminar referencias |
| **P0 - Inmediato** | Verificar H-005, H-006 en código actual | H-005, H-006 |
| **P1 - Alta** | Seguridad restante | H-001 download cradle, H-009 secrets scan, H-015 path traversal |
| **P1 - Alta** | Race condition | H-004 inter-track.json lock |
| **P2 - Media** | Paths hardcodeados + Parallel | H-007 Git Bash, H-011 GA2 Parallel |
| **P2 - Media** | Overweight check scope | H-019 extender a commands/ + prompts/ |
| **P3 - Baja** | Housekeeping | H-008 docs desactualizados, GB1-GB4 tokens restantes |

---

> **Próximo paso**: Revisar `00-indice-auditoria.md` para detalle completo de cada hallazgo.
> Los archivos `02-hallazgos-*.md` tienen el detalle por categoría con IDs, fuentes y recomendaciones.
