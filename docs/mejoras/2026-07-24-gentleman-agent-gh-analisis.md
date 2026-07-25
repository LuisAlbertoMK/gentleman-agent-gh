# Análisis Profundo — gentleman-agent-gh

**Fecha**: 2026-07-24
**Especialistas**: Security, Performance, Frontend/UX, Infrastructure, Data Quality, Documentation
**Total findings**: 47 → consolidados a **top 15 por riesgo**
**Trigger**: `!analisis` (scope: 8 archivos — 4 commit + 4 uncommitted)

---

## Resumen Ejecutivo

El proyecto tiene una **arquitectura sólida** pero acumuló deuda técnica significativa. Los problemas más críticos son:

1. **SSoT de scores roto** — `.project.json` y `score-cache.json` compiten con datos contradictorios (BI2 diverge 10 puntos)
2. **Conteo de skills desalineado** — score files dicen 68, filesystem tiene 80, docs dicen 79 u 80
3. **Skill tool no funciona** — `skill()` retorna "Skills no disponibles", pipeline depende de él
4. **Documentación 30% stale** — README tabla de skills sin actualizar desde cycle 5-6
5. **56 skills > 2.5KB** — karpathy compression pendiente, el más grande es 14.8KB

---

## Tabla de Síntesis (Top 15)

| # | Finding | Consenso | Riesgo | Dim | Archivos | Recomendación |
|---|---------|----------|--------|-----|----------|---------------|
| 1 | **SSoT scores compite** — `.project.json` dice 9.1, `score-cache.json` dice 7.9. BI2 diverge 10.0 puntos (18/18 vs 0/0). Dos escritores sin reconciliación. | UNANIMOUS (Data+Docs) | **CRITICAL** | Data | `.project.json`, `.learnings/score-cache.json` | Establecer `.project.json` como SSoT; cache debe ser derivado, nunca independiente |
| 2 | **Skill count triple desalineado** — score files = 68, SKILLS-INDEX header = 80, load rule = 79, filesystem = 80. Ningún número es consistente. | MAJORITY (Data+Docs+Frontend) | **CRITICAL** | Data | `.project.json`, `SKILLS-INDEX.md`, `QUICKSTART.md` | Unificar: correr scanner de skills, actualizar TODOS los archivos con el count real |
| 3 | **Skill tool roto** — `skill()` retorna "Skills no disponibles". Pipeline `!analisis` no puede cargar instrucciones. Workaround: Read directo de SKILL.md. | UNANIMOUS (all) | **CRITICAL** | UX | opencode platform | Diagnosticar por qué skill tool no funciona; agregar fallback Read en todos los skills |
| 4 | **adversarial-breaker sin entrada en SKILLS-INDEX** — skill existe en `.agents/skills/` con triggers válidos pero cero entrada en la tabla. Agent no lo puede encontrar por keywords. | UNANIMOUS (Docs) | **HIGH** | Docs | `SKILLS-INDEX.md` | Agregar fila: `adversarial, breaker, !breaker, verify fix, romper → adversarial-breaker` |
| 5 | **README tabla skills 30% stale** — Lista 55 de 80 skills. 24 skills agregados en cycles 7-8 no aparecen. Tabla más engañosa que útil. | MAJORITY (Docs+Frontend) | **HIGH** | Docs | `README.md:128-148` | Reemplazar con link a SKILLS-INDEX.md o actualizar tabla completa |
| 6 | **`.dockerignore` no excluye secrets** — `COPY . .` envía `.env*`, `*.pem`, `*.key`, `.learnings/` al build context. Historial filtrado en capas de imagen. | UNANIMOUS (Infra+Security) | **HIGH** | Infra | `Dockerfile:71`, `.dockerignore` | Agregar `.env*`, `*.pem`, `*.key`, `secrets/`, `.learnings/` a .dockerignore |
| 7 | **Dockerfile Python 3.11 hardcoded** — `COPY /usr/local/lib/python3.11/dist-packages` pero Ubuntu 22.04 base image trae Python 3.10. Build falla o copia nada. | UNANIMOUS (Infra) | **HIGH** | Infra | `Dockerfile:63` | Usar RUN para detectar versión dinámicamente o pinneear Python explícitamente |
| 8 | **`!ejecutar` invisible en onboarding** — Agregado a SHORTCUTS.md pero ausente de QUICKSTART.md tabla de shortcuts. Usuario nuevo no lo descubre. | MAJORITY (Frontend+Docs) | **HIGH** | UX | `QUICKSTART.md:84-89` | Agregar fila `!ejecutar` con guía "After `!analisis`" |
| 9 | **Orchestrator bash `"*": "allow"` fail-open** — Depende de 80+ deny rules para bloquear. Nuevo vector = nuevo deny rule. Diseño fail-open. | MAJORITY (Security) | **MEDIUM** | Security | `opencode.json:244` | Considerar invertir a `"*": "ask"` con allowlist explícita |
| 10 | **Select-String re-reads SKILL.md** — `score-dims.ps1:64-69` bypassa `$skillContentCache`, lee cada SKILL.md una 2da vez via Select-String. ~80 reads redundantes. | UNANIMOUS (Performance) | **MEDIUM** | Perf | `scripts/lib/score-dims.ps1:64-69` | Filtrar `$skillContentCache.Values` con regex en vez de pasar paths a Select-String |
| 11 | **Session-miner source files vacíos** — `.learnings/LEARNINGS.md` y `ERRORS.md` solo tienen ejemplos comentados. Pipeline learn→immunize muerto. | MAJORITY (Data+Docs) | **MEDIUM** | Data | `.learnings/LEARNINGS.md`, `.learnings/ERRORS.md` | Poblar desde Engram o documentar que session-miner no está operacional |
| 12 | **"22 agents" vs "80 skills" confusión** — QUICKSTART dice "22 specialized agents" pero SKILLS-INDEX trackea 80 skills. Sin doc que explique la relación. | MAJORITY (Frontend+Docs) | **MEDIUM** | UX | `QUICKSTART.md:9` | Agregar línea: "Each agent loads from 1-5 of 80 specialized skills as needed" |
| 13 | **bash-safe `$` escaping incompleto** — `ProcessStartInfo.Arguments` no escapa `$` ni backtick. Comando con `$` literal puede ser malinterpretado por Windows command processor. | UNANIMOUS (Security) | **MEDIUM** | Security | `scripts/bash-safe.ps1:174` | Agregar `$escapedCommand = $escapedCommand -replace '\$', '`$'` |
| 14 | **56 skills > 2.5KB** — karpathy compression pendiente. sdd-apply = 14.8KB, sdd-tasks = 11.3KB. Token budget erosion severa. | MAJORITY (Performance+Docs) | **MEDIUM** | Perf | `C:\Users\MK\.config\opencode\skills\*` | Ejecutar `!compress` para skills > 2.5KB |
| 15 | **SHORTCUTS date stale** — "Last updated: 2026-07-18" pero `!ejecutar` se agregó hoy. Fecha no refleja modificaciones reales. | UNANIMOUS (Frontend) | **LOW** | UX | `SHORTCUTS.md:80` | Actualizar a fecha actual |

---

## Hallazgos por Dimensión

### 🔒 Security (5 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 0 | — |
| HIGH | 0 | — |
| MEDIUM | 3 | Orchestrator bash fail-open (#9), npx supply chain, bash-safe $ escaping (#13) |
| LOW | 2 | Secrets scan prefix gaps, cross-ref-check symlink traversal |

### ⚡ Performance (4 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 0 | — |
| HIGH | 0 | — |
| MEDIUM | 2 | Select-String re-read (#10), 56 skills > 2.5KB (#14) |
| LOW | 2 | Cache timing, timeout silent drop |

### 🎨 Frontend/UX (6 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 0 | — |
| HIGH | 2 | Skill count inconsistency (#2), !ejecutar invisible (#8) |
| MEDIUM | 3 | 22 agents vs 80 skills (#12), stale year, "6 specialists" misleading |
| LOW | 2 | No reverse bridge, SHORTCUTS date stale (#15) |

### 🏗️ Infrastructure (4 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 0 | — |
| HIGH | 2 | No .dockerignore secrets (#6), Python version mismatch (#7) |
| MEDIUM | 1 | No SLSA attestation |
| LOW | 1 | package-lock.json excluded from Docker |

### 📊 Data Quality (5 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 1 | SSoT scores compete (#1) |
| HIGH | 1 | Skill count triple desalineado (#2) |
| MEDIUM | 2 | Session-miner empty (#11), SE dimension divergence |
| LOW | 1 | Timestamp ordering contradictory |

### 📝 Documentation (6 findings)

| Severity | Count | Highlights |
|----------|-------|------------|
| CRITICAL | 0 | — |
| HIGH | 2 | adversarial-breaker missing (#4), README 30% stale (#5) |
| MEDIUM | 1 | SKILLS-INDEX 80 vs 79 load rule |
| LOW | 3 | QUICKSTART stale, no CONTRIBUTING, analysis-executor Chinese text |

---

## Matriz de Riesgo

```
                    ALTO IMPACTO
                         │
    ┌────────────────────┼────────────────────┐
    │ #1 SSoT scores     │ #4 adversarial-    │
    │ #2 Skill count     │    breaker missing  │
    │ #3 Skill tool roto │ #5 README stale    │
    │                    │ #6 .dockerignore   │
    │   CRITICAL (fix    │ #7 Python version  │
    │   primero)         │ #8 !ejecutar hide  │
    ├────────────────────┼────────────────────┤
    │ #10 Select-String  │ #9 bash fail-open  │
    │ #11 Session-miner  │ #13 bash-safe $    │
    │ #14 56 skills>2.5K │ #12 agents≠skills  │
    │                    │                     │
    │   MEDIUM (fix      │   LOW (backlog)    │
    │   cuando haya      │                    │
    │   tiempo)          │                    │
    └────────────────────┼────────────────────┘
                         │
                    BAJO IMPACTO
```

---

## Recomendaciones por Fase

### Fase 1: Emergencia (esta semana)
1. **#3** — Diagnosticar skill tool; fallback Read ya implementado
2. **#1** — Resolver SSoT scores (correr score-auto o agregar staleness gate)
3. **#2** — Unificar skill count en todos los archivos
4. **#6** — Crear .dockerignore completo con secrets

### Fase 2: Seguridad (próximo ciclo)
5. **#9** — Revisar orchestrator bash permissions
6. **#13** — Fix bash-safe $ escaping
7. **#7** — Fix Dockerfile Python version

### Fase 3: Calidad (ciclos 28-30)
8. **#4** — Agregar adversarial-breaker a SKILLS-INDEX
9. **#10** — Fix Select-String N+1
10. **#14** — Ejecutar `!compress` para 56 skills > 2.5KB
11. **#11** — Decidir: poblar session-miner o documentar como inactivo

### Fase 4: UX (ciclos 30+)
12. **#5** — Actualizar README skills table
13. **#8** — Agregar !ejecutar a QUICKSTART
14. **#12** — Clarificar "22 agents" vs "80 skills"
15. **#15** — Actualizar SHORTCUTS date

---

## Consenso de Especialistas

| Consenso | Findings | Descripción |
|----------|----------|-------------|
| **UNANIMOUS** | #1, #3, #4, #6, #7, #10, #13, #15 | Todos los especialistas involucrados coinciden |
| **MAJORITY** | #2, #5, #8, #9, #11, #12, #14 | ≥50% de especialistas coinciden |
| **OUTLIER** | — | Ningún finding es outlier |

---

## Compresión Requerida

**56 de 93 skills > 2.5KB** — `!compress` SÍ se requiere. Top 5:
1. `sdd-apply`: 14.8KB
2. `sdd-tasks`: 11.3KB
3. `sdd-archive`: 10.7KB
4. `sdd-propose`: 9.3KB
5. `sdd-spec`: 9.2KB

Recomendación: Ejecutar `!compress` después de Fase 1 (emergencia).

---

*Generado por analysis-mode v4.6 — 6 especialistas, 8 dimensiones, 47 findings → 15 consolidados*
*Skill tool fallback: Read directo de SKILL.md (resiliente)*
