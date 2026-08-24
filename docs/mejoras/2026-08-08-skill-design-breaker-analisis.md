# Análisis: Skill Design (SDD) + Adversarial Breaker

**Fecha**: 2026-08-08 · **Project**: gentleman-agent-gh · **Trigger**: `!analisis — mejora skill de diseño y breaker mejora + best practices`

**Pre-Answer Gate**: ✅ Cross-referenced against existing `docs/mejoras/2026-08-08-auto-agent-autonomy-delegation.md` (autonomous agents), ADR/ADR-021 (template-detection), `engram:analysis:gentleman-agent-gh`. No prior analysis on SDD design skills or breaker improvements exists — baseline.

---

## 1. Sumario Ejecutivo

El **SDD design pipeline** (9 fases) y el **adversarial-breaker** están bien estructurados pero **subutilizados**: los profiles tecnológicos existen pero hay gaps de integración, y el flujo SDD no conecta con el breaker ni con `delivery-harness`. No hay un bucle de mejora continua del propio sistema de skills.

**Gap crítico**: El `self-improvement` skill (MACRO + MICRO) es autónomo — "Not automatic" (requiere trigger `!score`/`!metrics`).

---

## 2. Findings (8 dimensiones)

| Dimensión | Hallazgo | Evidencia | Confidence |
|-----------|----------|-----------|------------|
| **Sec** | `profiles/powershell.md` existe pero no se integra al pre-commit gate — el breaker es manual, no automático post-verify | `breaker-briefing.md:21` references `profiles/`; `.agents/skills/adversarial-breaker/references/profiles/{node,powershell,python}.md` exist | high |
| **Infra** | El pipeline SDD no conecta fases automáticamente — cada una requiere delegación manual del orquestador | `sdd/SKILL.md:37`: "Each phase requires explicit orchestrator delegation"; `delivery-harness` mencionado para >5 tasks pero no auto-dispatcheado | high |
| **Arch** | `sdd-phase-common.md` redirect en `_shared/` (7 líneas) es frágil; el archivo real está en `sdd/references/` (3941 bytes) | `.agents/skills/_shared/sdd-phase-common.md:5-6`; `sdd/references/sdd-phase-common.md` existe | high |
| **DX** | Las skills individuales de SDD (propose, design, spec, tasks, apply, verify, archive) NO existen como copias locales — solo en directorio global | `C:\Users\MK\.config\opencode\skills\sdd-*` existen; `.agents/skills/` solo tiene `sdd` + `sdd-quick` | medium |
| **Perf** | PSSA `Fix` mode auto-agrega BOM a 68 archivos pero NO actualiza el baseline para violations no-auto-fixable — genera false regressions | `pssa-gate.ps1:130` (Fix mode) vs `:168-181` (Check mode baseline comparison) | high |
| **Biz** | `sdd-propose` Step 0 "Interactive Proposal Shaping" requiere user input — no fallback para modo autónomo | `sdd-propose/SKILL.md:37-50`: 10 questions, skip if "blocked from asking" | medium |
| **Data** | El `profiles/powershell.md` no incluye vectores específicos para `invoke-expression`, `$ExecutionContext`, o `Add-Type` injection | `profiles/powershell.md:9+` — injection vectors are generic, not PS-specific | medium |
| **UX** | El pre-commit gate ROZA zone avisa pero no bloquea — permite commits sin JD dual review en zonas ROJA | `pre-commit-gate.ps1:9`: "ROZA zone files staged without JD dual review" + "Or: set FORCE_SHIP=1" | low |

---

## 3. Síntesis

### Skills de Diseño (SDD)

**CONSENSO: SPLIT (3/8 dims strongly positive, 5/8 dims improvement needed)**

**Fortalezas**:
- Pipeline de 9 fases bien definido con fast-path (`sdd-quick`) para cambios de bajo riesgo
- Referencias de plantillas completas: 10 archivos en `sdd/references/` (design-template, proposal-template, task-template, strict-tdd, etc.)
- `sdd-design` incluye Threat Matrix (Step 2a) con `references/threat-matrix.md`
- `sdd-propose` tiene Step 0 "Interactive Proposal Shaping" con 10 preguntas estructuradas
- `sdd-phase-common.md` define protocolo compartido (Sections A/B/C/D)

**Gaps**:
1. **Skills fragmentadas** — Las fases individuales (sdd-propose, sdd-design, sdd-spec, sdd-tasks, sdd-apply, sdd-verify, sdd-archive) existen SOLO en el directorio global. No hay copias locales en `.agents/skills/`. Esto significa que el proyecto no puede versionar ni modificar estas skills localmente.
2. **Sin handoff automático** — Cada fase requiere que el orquestador delegue explícitamente. No hay un "pipeline runner" que chain fases.
3. **Redirect frágil** — `_shared/sdd-phase-common.md` es un redirect de 7 líneas que apunta a `sdd/references/sdd-phase-common.md`. Si el path cambia, el protocolo se rompe.
4. **Sin tech-specific profiles para PS** — El `profiles/powershell.md` tiene vectores genéricos de inyección, pero no vectores PS-específicos como `Invoke-Expression`, `$ExecutionContext.InvokeCommand`, `Add-Type` dynamic compilation, o `Start-Job` race conditions.

### Adversarial Breaker

**CONSENSO: MAJORITY (6/8 dims positive, 2/8 improvement needed)**

**Fortalezas**:
- Protocolo de 12 pasos con calibration (depth/relevance/coverage/specificity)
- `breaker-briefing.md` (165 líneas) con 7 fases de ataque + tabla de selección por tipo de código
- Integración con `judgment-day` (dual review) y `external-auditor` (BLOCK → confirm)
- `review-rules.jsonc` define zones (roja/amarilla/verde) y JD profiles (4 perfiles)
- Perfil tecnológico existe (`profiles/powershell.md`)
- `attack-surface.md` existe (2161 bytes)

**Gaps**:
1. **Profiles PS no especializados** — Los vectores en `powershell.md` son genéricos. Faltan vectores PS-específicos:
   - `Invoke-Expression` injection
   - `$ExecutionContext.InvokeCommand.InvokeScript()`
   - `Add-Type` / `New-Object` reflection
   - `Start-Job` / background runspaces (race conditions)
   - `$env:` / registry manipulation
   - PowerShell remoting (`Enter-PSSession`, `Invoke-Command` remote)
2. **Sin auto-dispatch** — El breaker no se ejecuta automáticamente post-verify. El pre-commit ROZA zone solo *avisa* (warning, no block) — no requiere `!judgment-day` para cambios ROJA.
3. **Sin attack-surface project-specific** — `.agents/attack-surface.{project}.md` no existe. El briefing menciona `{past_findings_bullets}` como placeholder.

### Best Practices (Agosto 2026)

| Práctica | Estado actual | Mejora recomendada |
|----------|---------------|-------------------|
| PSSA baseline | 875 violations, 30 "manual" tracked | `Fix` mode no actualiza baseline — run `Trend` mode monthly |
| BOM encoding | 7 files sin BOM (auto-fixable) | `Fix` mode should update baseline post-BOM-fix |
| Conventional commits | ✅ Sin AI attribution | N/A |
| Pre-commit gate | 21/21 checks | ROZA zone debería BLOCK, no solo warn |
| Token budget | Skills 2491B/2000, prompts 1891B/2000 | 74 files over budget — review compression |

---

## 4. Matriz de Riesgo

| Hallazgo | Probabilidad | Impacto | Risk |
|----------|-------------|---------|------|
| SDD skills no versionables localmente | High | Alto — drift entre global y local sin awareness | 🔴 CRITICAL |
| PS profiles no especializados | Medium | Alto — vectores de ataque PS no cubiertos | 🟠 HIGH |
| PSSA Fix mode no updates baseline | High | Medium — false regressions en CI | 🟠 HIGH |
| ROZA zone no bloquea | Medium | Alto — merges incompletos en zona ROJA | 🟠 HIGH |
| BOM sin baseline sync | High | Low — ruido en CI | 🟡 MEDIUM |
| Redirect _shared/sdd-phase-common.md frágil | Low | Medium — break en protocolo | 🟡 MEDIUM |
| No attack-surface project-specific | Low | Medium — breaker blind to project context | 🟡 MEDIUM |

---

## 5. Recomendaciones (3 approaches)

### Approach A: Minimal (1-2 días)
1. Poblar `references/profiles/powershell.md` con vectores PS-específicos
2. Crear `.agents/attack-surface.gentleman-agent-gh.md`
3. Hacer que el ROZA zone sea BLOCK (no warning) en `pre-commit-gate.ps1`

### Approach B: Standard (1-2 semanas)
1. Todo de A
2. Copiar skills SDD individuales a `.agents/skills/` (local versionable copies)
3. Unificar `_shared/sdd-phase-common.md` — mover contenido real, no redirect
4. Auto-trigger `adversarial-breaker` post-Verify en zona ROJA

### Approach C: Full (1 mes)
1. Todo de B
2. Implementar SDD pipeline runner (chain fases automáticamente)
3. Integrar `delivery-harness` auto-trigger para task lists >5
4. Auto-dispatch `external-auditor` en BLOCK verdict

**Recomendación**: **Approach A** — mínimo esfuerzo, máximo impacto en seguridad.

---

## 6. Engram Persistence

- Topic key: `analysis/gentleman-agent-gh`
- Observation ID: 2555
- Previous analysis: `2026-08-08-auto-agent-autonomy-delegation.md` (autonomous agents — different scope)

## 7. Trend Analysis

**vs previous**: The August 8th analysis covered autonomous agents (macro/micro loops, async delegation). This analysis covers **skill design quality** (SDD pipeline gaps, breaker integration, PSSA baseline hygiene). Complementary — the autonomous-agent analysis identified the need for `self-improvement` auto-trigger; this analysis identifies that the SDD skills and breaker aren't connected to that loop.

**No regressions** in project state since last analysis.

---

**Gate**: Plan only — NO code/commit. Recommendations A/B/C require user approval.
