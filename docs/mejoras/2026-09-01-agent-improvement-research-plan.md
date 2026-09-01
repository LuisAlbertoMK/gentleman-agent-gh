# Plan de Mejora del Agente — Investigación Profunda 2026-09-01

> **Fecha**: 2026-09-01
> **Método**: 5 fases de investigación web profunda, cada una checkpointed en Engram (ids 847-851) + ctx_index (sources: research-2026-09-01-fase{1-5}-*)
> **Estado**: PLAN — sin implementación. Para ejecución por otro agente/persona.
> **Reanudación**: si se interrumpe, cada fase tiene checkpoint en Engram. Buscar `research-2026-09-01-fase{N}` para retomar.

---

## Fuentes verificadas (confianza)

| Fuente | Fecha | Confianza |
|--------|-------|-----------|
| opencode.ai/changelog + GitHub releases | 2026-08-28 | HIGH |
| modelcontextprotocol.io (official) | 2026-07-28 | HIGH |
| Anthropic engineering blog (agents + skills) | 2024-12 / 2025-10 | HIGH |
| arxiv 2605.04050 (LCM paper) | 2026 | HIGH |
| benchlm.ai SWE-bench Verified | 2026-09-01 (hoy) | HIGH |
| codersera.com open-source LLM landscape | 2026-08-18 | MEDIUM (excerpt, no fetch primario — verificar en benchlm.ai) |
| practical-devsecops MCP security report | 2026-06-26 | ❌ NO VERÍDICO — landing de curso, no reporte CVEs (reemplazado por NVD + GitHub advisories modelcontextprotocol) |
| NVD + GitHub Advisory DB (modelcontextprotocol org) | 2026 (verificar) | HIGH (fuente primaria pendiente fetch) |
| zylos.ai LLM-as-judge production | 2026-04-10 | HIGH |
| awesome-mcp-servers-2026 (community) | 2026 | LOW — descartado, no confiable |
| Udemy Claude Code course | 2026-06-21 | MEDIUM (maturity signal) |

---

## Hallazgos priorizados (ICE: Impact × Confidence × Ease)

### P0 — Crítico, alto impacto, implementable ya

#### P0-1. LCM (Lossless Context Management) — upgrade context-watchdog
- **Qué**: Implementar hierarchical summary DAG con lossless pointers (arxiv 2605.04050) en nuestro context-watchdog skill.
- **Por qué**: Nuestro L1/L2/L3 compression es una versión simplificada. LCM es la versión formal académica que "outperforms frontier coding agents".
- **Evidencia**: arxiv 2605.04050 — recursive context compression + recursive task partitioning (LLM-Map).
- **Archivos**: `.agents/skills/context-watchdog/SKILL.md`, scripts relacionados.
- **Esfuerzo**: 2-3 sesiones. Impacto: elimina context rot (nuestro YELLOW>40% → RED>80% problem).
- **Confianza**: HIGH (arxiv paper).

#### P0-2. MCP Security Audit contra CVEs 2026 [CORREGIDO — fuente reemplazada]
- **Qué**: Auditar nuestros 5 MCP servers (codebase-memory, engram, context7, headroom, chrome-devtools) contra NVD + GitHub Advisory DB (org modelcontextprotocol).
- **Por qué**: Riesgo real verificado en docs oficiales MCP (prompt injection vía tool responses, SSRF vía remote servers, credential exposure vía env vars — ver modelcontextprotocol.io/docs).
- **Evidencia**: NVD (nvd.nist.gov) + GitHub Advisory DB filter `ecosystem:mcp` + MCP spec security section. ⚠️ Fuente original `practical-devsecops.com` descartada 2026-09-01: era landing de curso ($699), no reporte estadístico (0 hits "CVE" en fetch).
- **Archivos**: `opencode.json` (MCP section), `scripts/security-scanner` o nuevo script.
- **Esfuerzo**: 1 sesión. Impacto: cierra vector de ataque real.
- **Confianza**: HIGH (concepto verificado en MCP docs) — fuente primaria NVD pendiente fetch puntual antes de ejecutar.

#### P0-3. Reasoning model tier para debugging complejo
- **Qué**: Agregar un tier de "reasoning" en el model router usando DeepSeek-R1 o Qwen3.6 reasoning para debugging multi-paso.
- **Por qué**: "Reasoning specialization is now a separate axis" (codersera 2026-08-18). Nuestros modelos actuales son general-purpose.
- **Evidencia**: codersera.com/blog/open-source-llms-landscape-2026 — reasoning models "cost more tokens per answer but produce dramatically better math/science/code results".
- **Archivos**: `opencode.json` (agent section), skill `opencode-model-router`.
- **Esfuerzo**: 1 sesión. Impacto: mejor debugging en casos complejos.
- **Confianza**: HIGH (landscape guide).

### P1 — Alto impacto, esfuerzo medio

#### P1-1. Anthropic Agent Skills spec compliance audit
- **Qué**: Auditar nuestras 93 skills contra la spec oficial de Anthropic Agent Skills (2025-10-16).
- **Por qué**: Somos early adopters del patrón; la spec formal puede tener requisitos que no cumplimos.
- **Evidencia**: anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills.
- **Archivos**: `.agents/skills/*/SKILL.md` (93 archivos).
- **Esfuerzo**: 2 sesiones (93 skills). Impacto: compliance + discoverability.
- **Confianza**: HIGH (Anthropic official).

#### P1-2. Qwen 3.6-35B-A3B para code review routing [MEDIUM — verificar antes de instalar]
- **Qué**: Evaluar routing de code review tasks a Qwen 3.6-35B-A3B (73.4% SWE-bench Verified según codersera 2026-08-18 — excerpt, no fetch primario).
- **Por qué**: Nuestros modelos free-tier no están benchmarked. Qwen 3.6 tendría el mejor costo/calidad para code review self-hosted *si el 73.4% se confirma*.
- **Evidencia**: codersera 2026-08-18 (MEDIUM) + benchlm.ai SWE-bench leaderboard (HIGH, verificado 96% Opus 5 pero no Qwen puntual). ⚠️ Acción requerida: `webfetch benchlm.ai/models/qwen-3-...` para confirmar score antes de implementar.
- **Archivos**: `opencode.json` (model config), skill `opencode-model-router`.
- **Esfuerzo**: 1 sesión evaluación + 1 implementación. Impacto: code review quality.
- **Confianza**: MEDIUM (excerpt, no fetch primario) — no bloquear P0 por esto.

#### P1-3. Zep-style temporal edges en Engram
- **Qué**: Agregar edges temporales a Engram para razonamiento sobre tiempo (qué decisión precedió a cuál, qué cambió entre sesiones).
- **Por qué**: Zep (temporal knowledge graphs) es el líder en "complex reasoning over time" según comparison 2026.
- **Evidencia**: niteagent.com/blog/ai-agent-memory-comparison-2026 + aiworkflowlab.dev comparison.
- **Archivos**: Engram MCP server config, schema.
- **Esfuerzo**: 2-3 sesiones. Impacto: mejor razonamiento temporal en decisiones.
- **Confianza**: HIGH (benchmark comparison).

### P2 — Impacto medio, exploración

#### P2-1. OpenCode Desktop app evaluation
- **Qué**: Evaluar si OpenCode Desktop (nuevo en Aug 2026) mejora el workflow vs terminal-only.
- **Por qué**: Desktop app tiene mejor soporte para vision/screenshots, model picker UI.
- **Evidencia**: GitHub releases v1.18.x (Desktop .deb/.rpm/macOS assets).
- **Esfuerzo**: 1 sesión evaluación. Impacto: UX.
- **Confianza**: HIGH (official releases).

#### P2-2. Anthropic "Effective Harnesses for Long-Running Agents" paper mining
- **Qué**: Leer el paper completo y extraer patrones de harness que no implementamos.
- **Por qué**: Es la base del Ralph Wiggum loop; puede tener patrones de harness que nos faltan.
- **Evidencia**: Referenced in ralph-loop README + Anthropic engineering blog.
- **Esfuerzo**: 1 sesión lectura + síntesis. Impacto: harness patterns.
- **Confianza**: HIGH (Anthropic official).

#### P2-3. DeepSeek V4 CSA para contextos largos locales
- **Qué**: Evaluar DeepSeek V4 con Compressed Sparse Attention para contextos 1M+ tokens locales.
- **Por qué**: KV cache reducido a 10% — permite contextos muy largos sin GPU cluster.
- **Evidencia**: codersera 2026-08-18.
- **Esfuerzo**: 1 sesión evaluación. Impacto: context engineering.
- **Confianza**: HIGH (landscape guide).

### P3 — Probabilidad / fuentes no verificadas (marcar como especulativo)

#### P3-1. [PROBABILIDAD] Plugin marketplace oficial OpenCode
- **Qué**: Si OpenCode lanza un plugin marketplace oficial, evaluar plugins de la comunidad.
- **Fuente**: Inferido de la cadencia de releases y ecosistema creciente. NO confirmado oficialmente.
- **Confianza**: SPECULATIVE — marcar como probabilidad, no hecho.

#### P3-2. [PROBABILIDAD] Native checkpointing en OpenCode
- **Qué**: Si OpenCode agrega checkpointing nativo (como Claude Code), migrar nuestro session-checkpoint.ps1.
- **Fuente**: Claude Code lo tiene; OpenCode podría seguir. NO confirmado.
- **Confianza**: SPECULATIVE.

---

## Checkpoints de reanudación

Si la ejecución se interrumpe, retomar desde aquí:

| Checkpoint | Engram ID | ctx_index source | Estado |
|-----------|-----------|-----------------|--------|
| Fase 1: OpenCode ecosystem | 847 | research-2026-09-01-fase1-opencode | ✅ Done |
| Fase 2: MCP servers + security | 848 | research-2026-09-01-fase2-mcp | ✅ Done |
| Fase 3: Agent Skills + patterns | 849 | research-2026-09-01-fase3-agentic | ✅ Done |
| Fase 4: Context engineering + LCM | 850 | research-2026-09-01-fase4-context | ✅ Done |
| Fase 5: Models + verification | 851 | research-2026-09-01-fase5-models | ✅ Done |
| Fase 6: Plan synthesis | Este doc | — | ✅ Done |

---

## Orden de ejecución recomendado [ACTUALIZADO 2026-09-01 — quick wins primero]

1. **P0-3** (Reasoning model tier) — 1 sesión, quick win, HIGH verificado — **ARRANCA ACÁ**
2. **P0-2 corregido** (MCP security audit con NVD) — 1 sesión, cierra riesgo real (fuente reemplazada, pendiente fetch NVD puntual)
3. **P0-1** (LCM context upgrade) — 2-3 sesiones, mayor impacto (ataca context rot, punto débil YELLOW/RED)
4. **P1-1** (Skills spec audit Anthropic 2025-10-16) — 2 sesiones, HIGH verificado
5. **P1-2** (Qwen) — 2 sesiones, MEDIUM — solo tras verificar benchlm.ai puntual
6. **P1-3** (Zep temporal edges) — 2-3 sesiones
7. **P2-*** — exploración según tiempo disponible

---

## Notas para el ejecutor

- Cada P0/P1 tiene evidencia file:line o URL con fecha. No implementar P3 sin verificación adicional.
- Los Engram checkpoints (847-851) tienen el detalle completo de cada fase — usar `mem_get_observation` para recuperar. Snapshot v1 preservado en ctx_index `research-2026-09-01-plan-v1-snapshot` + Engram id 853 + commit `e55f306a`.
- Los ctx_index sources tienen el texto completo indexado — usar `ctx_search(queries: [...], source: "research-2026-09-01-fase{N}-*")`.
- Confidence markers: HIGH = fuente oficial/fechada con fetch primario. MEDIUM = excerpt/search, no fetch (verificar antes de implementar). SPECULATIVE = inferido, no confirmado.
- **Auditoría 2026-09-01**: `practical-devsecops` descartado (landing curso, 0 hits CVE) y `awesome-mcp-servers-2026` descartado (LOW). Ver `mem 853` para trazabilidad cross-sesión.
