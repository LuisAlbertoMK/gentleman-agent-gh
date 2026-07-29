# Global Gap Analysis — gentleman-agent-gh (2026-07-29)

**Scope**: Full project — 27 agents, 79 skills, 118 scripts, 27 prompts, 13 configs
**Trigger**: `!analisis` global — user request for improvements/optimizations/gaps
**Methodology**: 4 parallel subagents (Security, Performance/Quality, Docs/DX, Architecture/Config) → cross-validated → consolidated top-15

---

## Synthesis Table

| # | Finding | Consensus | Risk | Dim | Files | Recommendation |
|---|---------|-----------|------|-----|-------|---------------|
| 1 | **84% scripts sin tests** — 65/77 root scripts tienen cero cobertura Pester | UNANIMOUS | **CRITICAL** | Quality | 65 scripts (bash-safe, score-auto, cross-ref-check, etc.) | Empezar con bash-safe.ps1 (más dependido) y score-auto.ps1; meta: 20% coverage en ciclo 28 |
| 2 | **Score drift** — README dice 9.1/10, .project.json dice 6.2/10. 4 dimensiones en 0.0 (Clean Code, Best Practices, Cycle Activity, Backlog Integrity) | UNANIMOUS | **HIGH** | Arch/Quality | `README.md:21`, `.project.json:131` | Sincronizar README a .project.json; lanzar ciclo 28 para recuperar las 4 dims caídas |
| 3 | **.gitleaks.toml vacío** — sin reglas custom, solo allowlist genérico. No detecta `ctx7sk_`, `GH_TOKEN`, `github_pat_` | MAJORITY | **HIGH** | Security | `.gitleaks.toml:1-8` | Agregar reglas custom para tokens específicos del proyecto |
| 4 | **-auto agents deny list incompleta** — 5 agents con `*: allow` pero deny list incompleta (~30 reglas faltantes vs opencode-base.json) | MAJORITY | **HIGH** | Security | `opencode.json:289-723` (5 blocks) | Sincronizar deny lists contra `scripts/lib/opencode-base.json` |
| 5 | **Pre-commit secrets scan usa -CaseSensitive** — permite bypass con `GHP_`, `GITHUB_TOKEN=`, `Password=` mayúsculas | UNANIMOUS | **HIGH** | Security | `.githooks/pre-commit:226-230` | Quitar `-CaseSensitive` o agregar variantes mayúsculas |
| 6 | **BITACORA.md ~121 entradas duplicadas** — 394 líneas, ~70% repetido de sesiones de test. Oculta entradas reales | UNANIMOUS | **HIGH** | DX | `BITACORA.md:1-394` | Deducar a ~116 únicas. Agregar guard en close-session para prevenir re-append |
| 7 | **analysis-executor zombie** — referenciado en SKILLS-INDEX triggers (L20+L41) pero su directorio no existe en `.agents/skills/` | MAJORITY | **HIGH** | Arch | `SKILLS-INDEX.md:20,41` | Crear skill o remover referencias |
| 8 | **engram-validate.ps1 detection set limitado** — solo 4 frases de inyección (`ignore previous`, `forget instructions`, `system prompt`, `new instructions`). Bypass trivial | MAJORITY | **MEDIUM** | Security | `scripts/engram-validate.ps1:99` | Expandir detection set: `ignore all`, `override`, `new rule`, `disregard`, `you are now`, homoglyphs Unicode |
| 9 | **14 skills >3KB token-heavy** — seo (8.9KB, 228ln) es el mayor outlier. Promedio saludable ~1.5KB | MAJORITY | **MEDIUM** | Quality | `.agents/skills/seo/SKILL.md`, `adversarial-breaker/SKILL.md`, etc. | Comprimir: mergear trigger tables, dropear boilerplate (## Overview, ## Description). seo necesita Karpathy loop |
| 10 | **DRY: 5 bash blocks idénticos ~200 líneas de copy-paste** en opencode.json | MAJORITY | **MEDIUM** | Arch | `opencode.json` (5 -auto agents) | `opencode.json` no soporta `$ref` — aceptar como limitación del formato, o generar con script |
| 11 | **bash-safe.ps1 no bloquea eval/exec/source/alias/builtin** — bypasses para bash injection | MAJORITY | **MEDIUM** | Security | `scripts/bash-safe.ps1:83-124` | Agregar `eval`, `exec`, `.` (source), `alias`, `builtin`, `declare -f` a unsafe patterns |
| 12 | **skill-graph.ps1 tabla 88-row embebida** — 22.6KB, 335 líneas, datos mezclados con código | MAJORITY | **MEDIUM** | Quality | `scripts/skill-graph.ps1` | Extraer a `.agents/skill-graph/data.csv`; reducir script 60% |
| 13 | **CI/CD SkillSpector sin pin de commit** — `git+https://github.com/NVIDIA/SkillSpector.git` sin SHA fijo | MAJORITY | **MEDIUM** | Security | `.github/workflows/quality-gate.yml:147` | Pinear a SHA específico o usar release tag |
| 14 | **CYCLE.md stale** — ciclo 27 cerrado 2026-07-16, 13 días sin ciclo nuevo. Score freshness ≤1d violado | MAJORITY | **MEDIUM** | Arch | `CYCLE.md:9-11` | Lanzar ciclo 28 con score recovery target |
| 15 | **docs/mejoras/ stale accumulation** — 13 documentos, 4 state JSONs, análisis Jul 13-14 señalados como "superseded" | MAJORITY | **LOW** | DX | `docs/mejoras/` | Archivar a `docs/mejoras/archived/` los análisis superseded y JSONs de estado |

---

## Risk Matrix

```
CRITICAL  ■■■■■■■■■■ (1)  — tests coverage
HIGH      ■■■■■■■■■■■■■ (6)  — score drift, gitleaks, deny lists, pre-commit, BITACORA, zombie skill
MEDIUM    ■■■■■■■■■■■■■■■ (7) — detection set, skills grandes, DRY, bash-safe bypass, skill-graph, CI/CD pin, CYCLE stale
LOW       ■■■■■■■■■ (1)   — mejora archive
```

---

## Trend vs Previous Analysis (2026-07-24)

### Resolved desde Jul 24
| Finding (Jul 24) | Status | Detail |
|------------------|--------|--------|
| SSoT scores compiten (9.1 vs 7.9 cache) | ✅ RESUELTO | Cache unified — ahora solo README vs .project.json (distinto problema) |
| Skill tool retorna "Skills no disponibles" | ✅ RESUELTO | Fallback Read implementado |
| adversarial-breaker missing de SKILLS-INDEX | ✅ RESUELTO | Agregado |
| .dockerignore no excluye secrets | ✅ RESUELTO | Corregido |
| 56 skills >2.5KB necesitan compresión | ✅ MEJORADO | Ahora 14 skills >3KB — reducción de ~75% vía Karpathy |

### Persisten / Nuevos
| Finding (Jul 29) | Delta | Nota |
|------------------|-------|------|
| Score drift README 9.1 vs .project.json 6.2 | 🔴 NUEVO | 4 dims en 0.0 post-cycle 27 |
| Skill count desalineado (93 vs 79) | 🔴 PERSISTE | Ahora es SKILLS-INDEX vs filesystem |
| 84% scripts sin tests | 🔴 NUEVO | No cubierto en análisis previo |
| .gitleaks.toml vacío | 🔴 NUEVO | No se revisó en Jul 24 |
| -auto agents deny list | 🔴 NUEVO | No existían en Jul 24 |
| BITACORA duplicados | 🔴 NUEVO | Acumulado por tests batch |
| engram-validate detection set | 🔴 NUEVO | Creado post-Jul 24 |

---

## Recommendations (ordered by Impact/Effort)

| Priority | Acción | Impact | Effort | Finding # |
|----------|--------|--------|--------|-----------|
| P0 | Lanzar ciclo 28 con score recovery + tests bash-safe | 🔥 High | 2d | 1, 2, 14 |
| P1 | Fix .gitleaks.toml + deny lists -auto agents + pre-commit | 🔥 High | 1d | 3, 4, 5 |
| P2 | Deducar BITACORA + guard en close-session | 🟢 Medium | 0.5d | 6 |
| P3 | Comprimir seo skill + otras >3KB | 🟢 Medium | 1d | 9 |
| P4 | Expandir engram-validate detection set | 🟢 Medium | 0.5d | 8 |
| P5 | Extaer tabla skill-graph a CSV | 🟢 Medium | 0.5d | 12 |
| P6 | Archive mejora docs + remover analysis-executor zombie | 🟡 Low | 0.5d | 7, 15 |

---

## Engram Persistence

- **Observation ID**: `#2068`
- **Topic Key**: `analysis/gentleman-agent-gh`
- **Timestamp**: 2026-07-29
- **Status**: This is the 2nd global analysis for gentleman-agent-gh (baseline: 2026-07-24)

## Trend Analysis

Segundo análisis global del proyecto. Respecto al baseline (2026-07-24):
- **5 hallazgos resueltos** — incluyendo la gran compresión Karpathy (56→14 skills grandes)
- **8 hallazgos nuevos** — la mayoría por crecimiento del proyecto (auto agents, engram-validate) o dimensiones no cubiertas antes (tests coverage, gitleaks)
- **Score general**: estable pero con 4 dims en 0.0 post-cycle — necesita reactivación
