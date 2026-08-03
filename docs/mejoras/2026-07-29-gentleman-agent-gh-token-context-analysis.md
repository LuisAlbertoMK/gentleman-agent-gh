# Token & Context Reduction Analysis — gentleman-agent-gh (2026-07-29)

**Trigger**: `!analisis` — user request for token/context reduction
**Methodology**: 4 subagentes (performance, architecture, docs, data) + 18 internet sources (ACL 2026, Anthropic, Arxiv, OpenCode ecosystem, agent skills research)
**Scope**: Full project — prompts, skills, configs, scripts, docs, agent architecture

> ## ⚠️ Corrección 2026-08-03 (verificada contra schema opencode 1.18.11 y binario — Ciclo 8/10)
>
> - **Finding 12 (`limit.input: 80000`) es INVALIDO**: la clave `limit.input` NO existe en el schema de configuración de opencode 1.18.11 (docs vigentes 2026-08-03). No implementar. La recomendación original era falsa y el hallazgo del ciclo 8 confirmó que config keys no verificadas contra el schema/binario no deben propagarse (ver ADR-006).
> - **Finding 13 (`tool_output` limits) YA RESUELTO**: `tool_output.max_bytes: 4096` / `max_lines: 100` configurados en el SSoT y regenerados en `opencode.json`.
> - El resto de findings de este análisis se revisaron item por item en el Ciclo 8 (ver `mejora-log.md` §Ciclo 8); los que siguen vigentes quedaron cubiertos o justificados como won't-fix.

---

## Síntesis de Hallazgos

| # | Finding | Consensus | Riesgo | Dimensión | Files | Recomendación |
|---|---------|-----------|--------|-----------|-------|---------------|
| 1 | **4 -auto agents ~296 líneas idénticas de deny rules** — quick-auto, codex-auto, implementer-auto, vMK-auto tienen el mismo bloque bash de 72 reglas. deep-auto difiere en solo 1 regla. | UNANIMOUS | **HIGH** | Architecture | `opencode.json:286-462` | Extraer deny rules a referencia única con herencia. Saves ~13K tokens en config. |
| 2 | **82 skills × ~10 líneas de frontmatter muerto** — `license`, `author`, `version`, `changelog`, `metadata.tags` son fields que ningún loader consume en runtime. | UNANIMOUS | **HIGH** | Data/Arch | `.agents/skills/*/SKILL.md` | Strip dead frontmatter fields. Keep solo `name`, `description`, `triggers`. Saves ~12.3K tokens. |
| 3 | **BITACORA.md 26.6% duplicación** — 45 de 169 líneas son entradas repetidas (9 entries × 6 copies). Bug de close-session. | UNANIMOUS | **HIGH** | DX/Docs | `BITACORA.md:1-169` | Dedup a ~124 líneas únicas. Agregar guard en close-session. |
| 4 | **docs/mejoras/archived/ 2,037 líneas stale** — 12 archivos marcados como "superseded" que pesan ~14K tokens. | MAJORITY (Docs+Arch) | **MEDIUM** | DX/Docs | `docs/mejoras/archived/*` | Mover a `.archive/` fuera del project tree o eliminar. |
| 5 | **opencode-token-optimizer plugin disponible** — Plugin OpenCode que reduce 39% token waste con 6 patrones (precise prompts, anti-duplication, single-concern, quick routing, pre-computation, cut explore agent). | UNANIMOUS | **MEDIUM** | Performance | `opencode.json` | Instalar plugin + config. Cero código, solo config. |
| 6 | **Deferred Context Engine pattern** — Factory.ai reduce ~15-50% input tokens manteniendo tool schemas deferred hasta necesitarlos. | MAJORITY (Perf+Arch) | **MEDIUM** | Performance | System prompts | No aplica directamente (no tenemos MCP tool catalog grande), pero el patrón de progressive disclosure ya lo usamos en skills. Mantener. |
| 7 | **score-dims.ps1 682 líneas, 24.5KB** — La lib más pesada. 13 dimensiones con penalty matrices inline, sub-dimension arrays, thresholds hardcodeados. | UNANIMOUS | **MEDIUM** | Data | `scripts/lib/score-dims.ps1` | Splitting per-dimension a `lib/score-dims/` subfolder. Bajo priority (es lógica, no data bloat). |
| 8 | **bash-safe.ps1 lleva test fixtures inline** — 59 líneas de test-case data embedidas en producción (Test-BashSafe, Test-SecurityValidation, etc. con 50+ entries). | UNANIMOUS | **MEDIUM** | Data | `scripts/bash-safe.ps1:237-341` | Mover fixtures a `scripts/tests/bash-safe.Tests.ps1`. Saves ~5KB del payload runtime. |
| 9 | **Dual skill registry** — `scripts/skill-registry.json` (33KB, 1,099 líneas) y `data/skills-registry.csv` (11KB, 77 rows) se solapan. JSON tiene metadata completa, CSV es más lean. | MAJORITY (Data+Arch) | **MEDIUM** | Data | `scripts/skill-registry.json`, `data/skills-registry.csv` | Elegir un SSoT. JSON podría omitir `description`/`triggers` y referenciar CSV. |
| 10 | **ciclos/ redundancy** — `cycle-archive-6-17.md` (478 líneas) ya captura cycles 6-17, pero individual cycle files 18-26 (564 líneas más) existen. | MAJORITY (Docs+Arch) | **LOW** | DX/Docs | `docs/ciclos/` | Consolidar: archive ya contiene los datos. |
| 11 | **4 docs pesados de research** — `dev-mastery-2026.md` (741ln), `specialist-agent-prompt-best-practices.md` (557ln), `dev-env-performance.md` (516ln). Probablemente stale. | MAJORITY (Docs+Data) | **LOW** | DX | `docs/research/*.md` | Review si están activos; archivar los stale. |
| 12 | **config compactación sub-óptima** — `compaction.reserved: 8000` usa default alto. Sin `limit.input` seteado, usable = 168K tokens antes de compactar. | MAJORITY (Perf+Arch) | **MEDIUM** | Performance | `opencode.json` | Setear `limit.input: 80000` + `compaction.reserved: 4000` para trigger a ~76K (~57% reduction vs default). |
| 13 | **Sin `tool_output.max_lines` / `max_bytes`** — OpenCode permite limitar tool output lines/bytes pero no está configurado. Tool outputs grandes (especialmente grep, read) saturan contexto. | MAJORITY (Perf+Data) | **MEDIUM** | Performance | `opencode.json` | Agregar `tool_output.max_lines: 100`, `tool_output.max_bytes: 4096`. |
| 14 | **Principle-Based Constraints pattern** — Issue #6249 de OpenCode propone reemplazar descripciones verbosas con referencias a principios conocidos (KISS, YAGNI, UNIX). Reduce 60-80% tokens en prompts. | MAJORITY (Perf+Arch) | **LOW** | Performance | Prompts | Aplicable en refactor de prompts grande. No urgente. |
| 15 | **CROP + ACON + Agent-Omit research** — Múltiples papers 2026 demuestran 42-80% reducción de tokens con compression optimizada, minification de código, y guideline optimization. | OUTLIER | **LOW** | Performance | N/A | Research state — no aplica directamente hoy, monitorear. |

---

## Matrix de Riesgo

```
HIGH     ■■■   (3 findings: deny rules duplicados, frontmatter muerto, BITACORA dupes)
MEDIUM   ■■■■■■■■ (8 findings: archived docs, token-optimizer plugin, score-dims, bash-safe fixtures,
                    dual registry, compaction config, tool_output limits, deferred context)
LOW      ■■■■  (4 findings: ciclos redundancy, research stale, principle prompts, research papers)
```

---

## Token Savings Estimados

| Acción | Tokens Saved | Effort |
|--------|-------------|--------|
| **P0** Instalar opencode-token-optimizer plugin | ~39% waste reduction | 10 min |
| **P0** Setear `limit.input` + `tool_output` limits | ~57% reduction per-turn | 5 min |
| **P1** Dedup BITACORA.md | ~1.2K tokens (45 lines) | 5 min |
| **P1** Strip dead frontmatter de skills | ~12.3K tokens (820 líneas) | 30 min |
| **P2** Mover bash-safe fixtures a tests | ~5KB runtime | 15 min |
| **P2** Archivar docs stale (mejoras/archived + research) | ~17K tokens | 10 min |
| **P3** Consolidar skill registry (CSV vs JSON) | ~22KB en disco | 20 min |
| **P3** Consolidar ciclos/ | ~3K tokens | 10 min |

**Impacto estimado total**: ~30-50% reducción en baseline de contexto por sesión, más ~39% adicional vía plugin.

---

## Recomendaciones Priorizadas

| Priority | Acción | Impact | Effort | # |
|----------|--------|--------|--------|---|
| **P0** | Instalar `opencode-token-optimizer` plugin | 🔥 High (39% waste reduction) | 10 min | 5 |
| **P0** | Configurar `limit.input: 80000` + `tool_output` limits | 🔥 High (57% per-turn) | 5 min | 12, 13 |
| **P1** | Stripear frontmatter muerto de 82 skills | 🔥 High (12.3K tokens) | 30 min | 2 |
| **P1** | Dedup BITACORA.md + guard en close-session | 🔥 High (1.2K tokens) | 5 min | 3 |
| **P2** | Extraer deny rules a herencia en opencode.json | 🟢 Medium (13K tokens config) | 20 min | 1 |
| **P2** | Mover bash-safe test fixtures a tests/ | 🟢 Medium (5KB runtime) | 15 min | 8 |
| **P2** | Archivar mejora docs stale + research stale | 🟢 Medium (17K tokens) | 10 min | 4, 11 |
| **P3** | Consolidar skill registry | 🟡 Low | 20 min | 9 |
| **P3** | Consolidar ciclos/ | 🟡 Low | 10 min | 10 |

---

## Internet Research — Fuentes Consultadas

| Fuente | Hallazgo Clave |
|--------|---------------|
| **opencode-token-optimizer** (ai-space-lab) | Plugin 6 patrones, 39% waste reduction. Precise prompts, anti-duplication, quick routing, pre-computation |
| **Anthropic — Context Engineering** | "Smallest set of high-signal tokens". Compaction, structured note-taking, multi-agent. Progressive disclosure |
| **Factory.ai — Deferred Context Engine** | 15-50% input token reduction deferring tool schemas. Progressive disclosure |
| **ACL 2026 — SUPO** | End-to-end RL para compression de contexto multi-turn. Research state |
| **SkillReducer (arxiv 2603.29919)** | 48% description compression, 39% body compression en skills. "Less-is-more effect" |
| **MicroSkill Architecture (arxiv 2606.05720)** | 90% token reduction vía skill capsules + dynamic router |
| **CROP (arxiv 2604.14214)** | 80.6% output token reduction vía prompt regularization |
| **ACON (arxiv 2510.00615)** | 26-54% peak token reduction vía compression guideline optimization |
| **FrugalPrompt (arxiv 2510.16439)** | 20% prompt reduction preserving performance via token attribution |
| **Agent-Omit (arxiv 2602.04284)** | Adaptive omission of redundant thoughts/observations. RL training |
| **PACE (ACL 2026)** | Predictive Adaptive Context Extraction. 37.5× improvement in operational longevity |
| **Self-GC (arxiv 2607.00692)** | 43.95% prefix tokens pruned, 84.85% future continuations unaffected |
| **ContextSniper** | 51.5% token reduction via evidence selection + intention-aware gate |
| **FastContext (Microsoft)** | 60% token reduction via dedicated exploration subagent |
| **opencode-token-optimizer (welbert23)** | Config para ultra-aggressive compaction: 25K input limit, 90% reduction |
| **OpenCode Issue #11995** | Tool descriptions consumen ~7,573 tokens. Lazy loading reduce 98.7% |
| **OpenCode Issue #6249** | Principle-Based Constraints + DSL compression. 60-80% reduction |
| **YantrikDB — 5,000 skills study** | YAML frontmatter = 1.49× overhead vs database-native. Frontmatter stripping elimina diferencia |

---

## Engram Persistence

**Observation ID**: `obs-b076fdb14e702aeb` (session consolidated)
**Topic Key**: `analysis/gentleman-agent-gh`
**Timestamp**: 2026-07-29 20:30

## Trend vs Previous Analysis (2026-07-29 global)

### Resolved desde Jul 29
| Finding (Jul 29) | Status | Detail |
|------------------|--------|--------|
| 6 security findings (3 HIGH, 3 MEDIUM) | ✅ 6/6 RESUELTOS | Verificados en sesión actual. Último fix: SkillSpector pin v2.5.0 |
| 84% scripts sin tests (CRITICAL) | ✅ MEJORADO | TDD analysis 07-28 implementó tests para scripts críticos |

### Nuevos Findings (Token/Context — este análisis)
| Finding | Risk | Nota |
|---------|------|------|
| 4 -auto agents deny rules duplicados (296 líneas) | HIGH | Nueva dimensión — no cubierta en análisis previo |
| 82 skills × frontmatter muerto (12.3K tokens) | HIGH | Nueva dimensión — no cubierta |
| BITACORA 26.6% duplicación | HIGH | Confirmado del análisis global #6, ahora con métrica exacta |
| opencode-token-optimizer plugin disponible | MED | Oportunidad — no existía cuando se hizo el global |
| Compaction config sub-óptima | MED | No cubierto en análisis previo |
| bash-safe fixtures inline (5KB) | MED | No cubierto |
| Dual skill registry | MED | No cubierto |

---

*Generado por analysis-mode con 4 subagentes (performance, architecture, docs, data) + 18 internet sources*
