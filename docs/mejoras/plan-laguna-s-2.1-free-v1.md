# Plan de Análisis Diamante — gentleman-agent-gh

> **Protocolo**: Análisis Completo (11 dimensiones) → Plan de Mejora (Bronce→Diamante)
> **Modelo**: laguna-s-2.1-free v1
> **Fecha**: 2026-08-11
> **Score actual**: 8.9/10 (oro) — objetivo: 9.8+/10 (diamante)

## 1. Findings (11 dimensiones)

### 1. Performance / Recursos
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| P1 | 43 skills >2.5KB (8 críticos >3KB) | ctx_batch_execute: sdd-spec 4460B, sdd-archive 4406B, ... (8 skills) | 🟠 Alto | M | Alto |
| P2 | Token budget excedido: skills 2638B/2000, prompts 1891B/2000 | verify.ps1 E2 check, 83 files over | 🟠 Alto | M | Alto |
| P3 | opencode.json al 82% del límite (53,556/65,536B) | scripts/lib/opencode-base.json | 🔴 Crítico | B | Alto |
| P4 | score-dims.ps1 741 líneas (complejidad alta) | ctx_batch_execute | 🟡 Medio | L | Medio |
| P5 | use-gentleman.ps1 516 líneas (decompose) | ctx_batch_execute | 🟡 Medio | M | Medio |

### 2. Gaps Funcionales
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| F1 | 8 SDD skills sin Karpathy compress | quality gate [5/13] | 🟠 Alto | M | Alto |
| F2 | QUICKSTART.md missing prerequisites | report: QUICKSTART.md:22-34 | 🟡 Medio | L | Medio |
| F3 | SHORTCUTS.md referencia commands/ inexistente | SHORTCUTS.md:5 | 🟡 Medio | L | Medio |
| F4 | 5 skills "muertas" (no cargadas): cognitive-doc-design, prompt-engineering, senior-engineer | analisis.md:18 | 🟢 Bajo | S | Bajo |

### 3. Optimización I/O
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| IO1 | 337 tracking branches de upstream (git fetch slow) | git branch -r | 🟡 Medio | L | Medio |
| IO2 | BITACORA.md churn 134x (alta frecuencia write) | git churn | 🟡 Medio | L | Bajo |
| IO3 | AGENTS.md churn 134x | git churn | 🟡 Medio | L | Bajo |
| IO4 | No file caching layer en scripts | scripts/*.ps1 leen disco repetidamente | 🟢 Bajo | M | Medio |

### 4. Aprendizaje / Memoria
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| L1 | Engram protocol existe pero no hay uso cross-session activo | .agents/skills/engram-protocol/ | 🟡 Medio | M | Alto |
| L2 | No auto-consolidación de aprendizajes | BITACORA no enlaza a mem_search automáticamente | 🟡 Medio | M | Alto |
| L3 | ADR-021+ pendientes para gaps detectados | adr/ (0 ADRs >21) | 🟢 Bajo | S | Bajo |

### 5. Testing
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| T1 | 44 test files, 709 tests (0 fail) | Pester suite verde | ✅ Bueno | — | — |
| T2 | permission-gate.Tests.ps1: 556L (demasiado grande) | ctx_batch_execute | 🟡 Medio | M | Medio |
| T3 | session-miner.Tests.ps1: 434L (monolítico) | ctx_batch_execute | 🟡 Medio | M | Medio |
| T4 | No tests de integración para merge/push flows | .github/workflows/quality-gate.yml | 🟢 Bajo | L | Bajo |
| T5 | check-mcp-security.Tests.ps1: 198L — security testing sólido | ctx_batch_execute | ✅ Bueno | — | — |

### 6. UI/UX
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| UX1 | QUICKSTART.md sin prerequisites | QA-F2 | 🟡 Medio | L | Alto |
| UX2 | SHORTCUTS.md referencia commands/ fantasma | QA-F3 | 🟡 Medio | L | Medio |
| UX3 | 30+ shortcuts abruman — sin top-5 destacados | SHORTCUTS.md:9-105 | 🟢 Bajo | L | Medio |

### 7. Seguridad
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| S1 | security-scanner skill (2504B >2.5KB) | scripts/*.ps1 | 🟡 Medio | S | Alto |
| S2 | llm-security skill (2865B) | skill sizes | 🟢 Bajo | S | Alto |
| S3 | No secret scanning en CI (sólo en pre-push hook) | quality-gate.yml | 🟡 Medio | L | Alto |
| S4 | 61 deny rules en opencode.json | quality gate | ✅ Bueno | — | — |

### 8. Escalabilidad
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| E1 | opencode.json 82% (will hit 65KB ceiling) | P3 | 🔴 Crítico | B | Alto |
| E2 | 337 upstream tracking branches | IO1 | 🟡 Medio | L | Alto |
| E3 | 43 skills >2.5KB = lento load | P1 | 🟠 Alto | M | Alto |

### 9. Calidad de Código
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| C1 | score-dims.ps1 741L (mayor script) | ctx_batch_execute | 🟠 Alto | L | Alto |
| C2 | 43 skills >2.5KB | P1 | 🟠 Alto | M | Alto |
| C3 | BITACORA.md/AGENTS.md churn 134x cada uno | git churn | 🟡 Medio | L | Medio |
| C4 | 8 skills con "tutorial prose" en lugar de reglas | analisis.md:51 | 🟡 Medio | M | Medio |

### 10. Calidad de Resultados
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| R1 | 709/709 tests pass (0 fail) | quality gate | ✅ Excelente | — | — |
| R2 | Quality gate 22/22 ALL CLEAR | pre-commit | ✅ Excelente | — | — |
| R3 | Score 8.9/10 estable | score-auto | ✅ Bueno | — | — |
| R4 | No test result trend tracking | BITACORA | 🟢 Bajo | S | Medio |

### 11. Otras dimensiones
| ID | Finding | Evidencia | Severidad | Esfuerzo | Impacto |
|----|---------|----------|-----------|----------|---------|
| O1 | commands/ dir referenciado pero inexistente | SHORTCUTS.md:5, commands/*.md existen pero no commands/ dir | 🟡 Medio | L | Medio |
| O2 | commands/*.md son archivos markdown (no scripts) | commands/ tiene .md files | 🟡 Medio | L | Bajo |

## 2. Prioridad y roadmap (Bronce→Diamante)

### Fase 1: Quick Wins (Rubí — 1-7 días)
| ID | Acción | Esfuerzo | Impacto | Risk | Verificación |
|----|--------|----------|---------|------|-------------|
| F2 | Agregar Prerequisites a QUICKSTART.md | S | Alto | 🔵 Bajo | `Read QUICKSTART.md`, validar instalación PS/OpenCode |
| F3 | Arreglar SHORTCUTS.md reference a commands/ | S | Medio | 🔵 Bajo | grep -n "commands/" SHORTCUTS.md |
| F4 | Archivar 3 skills muertas → .agents/skills/_archived/ | S | Bajo | 🔵 Bajo | `ls .agents/skills/cognitive-doc-design/` — 45 días sin uso |
| T5 | Agregar security scanning a CI | S | Alto | 🔵 Bajo | quality-gate.yml + bandit/gitleaks |
| UX3 | Highlight top-5 shortcuts en QUICKSTART | S | Medio | 🔵 Bajo | Edit README + QUICKSTART |
| O2 | Documentar commands/ como .md shortcuts, no dir | S | Bajo | 🔵 Bajo | Update SHORTCUTS.md line 5 |

### Fase 2: Estructural Media (Oro — 1-3 semanas)
| ID | Acción | Esfuerzo | Impacto | Risk | Verificación |
|----|--------|----------|---------|------|-------------|
| P1 | Karpathy T2 compress 8 SDD skills >3KB | M | Alto | 🟡 Medio | `benchmark.ps1 -Gate` → 0 skills >3KB |
| P3 | Reducir opencode.json (extraer agents a sub-archivos) | B | Alto | 🟠 Alto | Verificar <60KB + funcionan todos los agentes |
| P4 | Decompose score-dims.ps1 (741L → ~300L + modules) | L | Alto | 🟡 Medio | Refactor: Functions.ps1, Dimensions.ps1, Scores.ps1 |
| P5 | Decompose use-gentleman.ps1 (516L) | M | Medio | 🟡 Medio | Split: Installer, Validator, Syncer |
| IO1 | Prune 337 upstream tracking branches | S | Medio | 🔵 Bajo | `git fetch --prune upstream` + verify local unaffected |
| IO2 | Consolidar BITACORA.md writes (batch mode) | M | Bajo | 🔵 Bajo | Medir ops/escritura antes/después |
| S1-S2 | Compress security-scanner + llm-security skills | S | Alto | 🔵 Bajo | Karpathy compress → <2.5KB |

### Fase 3: Estructural Profunda (Diamante — 1-2 meses)
| ID | Acción | Esfuerzo | Impacto | Risk | Verificación |
|----|--------|----------|---------|------|-------------|
| E1 | Arquitectura multi-archivo opencode.json (plugin system) | XL | Alto | 🔴 Alto | opencode.json <50KB + 37 agentes funcionando |
| L1 | Integrar Engram cross-session memory hooks | L | Alto | 🟡 Medio | mem_search recall <5s, cross-session context |
| L2 | Auto-consolidación: BITACORA → Engram sync | L | Alto | 🟡 Medio | Decisiones de sesiones pasadas visibles en nueva |
| C1 | Refactor score-dims.ps1 + lib/score-dims.ps1 (monolito) | L | Alto | 🟡 Medio | Pester score tests 0 regressions |
| C2 | Karpathy T2-T3 compress restantes 13 skills (2.8-3KB) | M | Alto | 🟡 Medio | 0 skills >2.5KB |
| IO4 | File caching layer en scripts lib | M | Medio | 🟡 Medio | Medir I/O ops reduction ≥30% |

## 3. Matriz de Riesgo

| ID | Severidad | Esfuerzo | Prioridad | Acción |
|---|---|---|---|---|
| P3 / E1 | 🔴 Crítico | B/XL | ⭐⭐⭐ | **URGENTE** — límite de tamaño opencode.json |
| F1 / P1 | 🟠 Alto | M | ⭐⭐⭐ | Karpathy compress SDD skills |
| P4 / C1 | 🟠 Alto | L | ⭐⭐ | Decompose score-dims.ps1 |
| L1 | 🟡 Medio | L | ⭐⭐ | Engram cross-session |
| IO1 | 🟡 Medio | S | ⭐ | Prune upstream tracking branches |
| T2 / T3 | 🟡 Medio | M | ⭐ | Split test files |
| UX1 | 🟡 Medio | S | ⭐ | QUICKSTART prerequisites |

## 4. Cómo verificar progreso

| Métrica (KPI) | Baseline | Target (Rubí) | Target (Oro) | Target (Diamante) | Fuente |
|---|---|---|---|---|---|
| Skills >3KB | 8 | 0 | 0 | 0 | quality gate [5/13] |
| Score | 8.9/10 | 9.0 | 9.3 | 9.8+ | score-auto.ps1 |
| Quality gate | 22/22 | 22/22 | 22/22 | 22/22 | pre-commit |
| Tests | 709 pass /0 fail | same | same | same | Pester |
| Token budget | 2638B/2000 | ≤2200B | ≤2000B | ≤1800B | verify.ps1 E2 |
| opencode.json | 53,556B (82%) | ≤50KB | ≤45KB | ≤40KB | file size |
| score-dims.ps1 lines | 741 | ≤500 | ≤400 | ≤300 | wc -l |
| Dead skills | 3 | 0 | 0 | 0 | skill graph analysis |
| Security scan in CI | 0 | 1 | 1 | 1 | quality-gate.yml |

## 5. Enfoques alternativos evaluados (≥2 por gap)

### P3 — opencode.json size (E1)
- **E1-a (elegido): Extracción plugin system** — mover agentes a `.opencode/agents/{name}/` JSON individuales. **Ventaja:** escala indefinidamente, mantiene compatibilidad. **Desventaja:** refactor de carga.
- **E1-b: Karpathy compression extrema** — minificar JSON, remover spaces. **Contraincda:** JSON no es comprimible sin perder readability; max ~15% savings. Rechazado.

### P1 — 8 SDD skills >3KB
- **E1-a (elegido): Karpathy T2 + merge boilerplate a _shared/** — comprimir a ≤2.5KB, mover frontmatter común a `prompts/shared/_sdd-template.md`. **Ventaja:** mantiene intents, reduce duplicación.
- **E1-b: Split en sub-skills** — separar sdd-apply-enroll, sdd-apply-execute, sdd-apply-verify. **Contraincda:** aumenta complejidad de routing, el usuario prefiere monolito cohesive.

### P4 — score-dims.ps1 741L
- **E1-a (elegido): Extract Functions.ps1 + Dimensions.ps1 + Scores.ps1** — split por responsabilidad. **Ventaja:** 709 tests siguen pasando, mejor testabilidad.
- **E1-b: Convertir a JSON-DSL + interpreter** — definir dimensions en JSON, evaluator genérico. **Contraincda:** refactor masivo, 709 tests requieren rewrite.

---

**⚠️ ESTE PLAN ES ANÁLISIS + PLAN. CERO implementación.** (por restricción crítica)

**Next**: Aprobación manual para Fase 1 (Quick Wins), luego Fase 2, luego Fase 3.

```
┌─────────────────────────────────────────────────────────┐
│  BRONCE (actual)  →  RUBÍ (quick wins)  →  ORO (estruct)  │
│  8.9/10               9.0-9.3/10          9.3-9.5/10      │
│                    ↓                                    │
│                 DIAMANTE (deep arch)                     │
│                   9.8+/10                              │
└─────────────────────────────────────────────────────────┘
```
