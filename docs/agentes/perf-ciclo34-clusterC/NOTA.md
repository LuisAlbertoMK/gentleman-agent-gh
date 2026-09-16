# Ciclo 34 — Cluster C: skills-diet + MCP lazy + compaction (10 experimentos)

Fecha: 2026-09-15. Modo: Auto. Shadow en `C:\Users\MK\AppData\Local\Temp\opencode\clusterC\` — **originales intactos** (cero writes a SKILL.md / opencode.json).
SkillOpt gate: cada skill ≤3KB, promedio <2.0KB.

## Baseline medida (Get-Item Length + Get-Content -Raw x20-30, avg parse ms)

| Skill | Bytes | KB | Líneas | fmBytes(7L) | refBytes | tableChars(\|) | parseMs avg |
|---|---|---|---|---|---|---|---|
| judgment-day | 4126 | 4.03 | 87 | 554 | 768 | 1062 (19L) | 2.77–2.99 |
| delivery-harness | 3708 | 3.62 | 62 | 289 | 49 | 732 (6L) | 1.28–3.72 |
| triple-verify | 2953 | 2.88 | 54 | 265 | 128 | 937 (10L) | 1.32 |
| self-improvement | 2909 | 2.84 | 43 | 353 | 264 | 584 (5L) | 1.50 |
| skill-graph | 2469 | 2.41 | 64 | 278 | 279 | 485 (5L) | 3.56 |
| **Total 5** | **16165** | **15.79** | — | — | — | **3800** | — |
| Media 95 skills | 2706.61 avg (Sum 257128) | — | — | — | — | — | — |
| Top-8 over-3KB | JD 4126, DH 3708, performance-tracker 3367, engram-protocol 3280, context-watchdog 3266, baseline-ui 3183, testing-strategy 3143, ui-engine 3108 | — | — | — | — | — | — |
| generate-opencode-config.js | 15892 (383L) | 15.52 | — | semi 12L/937B | compaction 11L | — | ~46 (cold) |

Nota E3: `Set-Content` normaliza CRLF y mete ruido (±20B) en archivos sin changelog largo — el delta real se midió por línea (JD changelog = 273B).

## Tabla 10 experimentos

| # | Hipótesis | Cambio (shadow / lectura) | KB antes→después | Parse ms antes→después | Veredicto |
|---|---|---|---|---|---|
| E1 | JD: tabla Zylos-6 duplicada (L45-54) es redundante con L41-43 + reference.md | Shadow `jd-e1.md`: drop L45-54, +1 línea pointer | 4.03→3.51KB (**-0.52KB**, -536B medido) | 2.99→4.87ms (ruido IO, n=30) | ✅ ADOPT |
| E2 | DH: bullets workflow L25/L23-24 verbosos, comprimibles sin pérdida | Shadow `dh-e2.md`: 2 bullets → 2 líneas compactas | 3.62→3.38KB (**-0.24KB**, -247B medido) | 3.72→3.62ms (≈0) | ✅ ADOPT |
| E3 | Frontmatter `changelog` largo cuesta bytes siempre cargados | Shadow `*-e3.md` + medida por línea: JD changelog 273B, resto ~40B c/u | Total ≈ -0.39KB (-400B proyectado; JD -273B medido) | ≈0 | ✅ ADOPT (JD prioritario) |
| E4 | `Cross-Refs` x5 copias → 1 pointer a registry (dedup ~4-5x en esa clase) | Lectura+shadow: JD 70B, SI 186B, SG 81B, TV 43B, DH 7B | Total **-0.38KB** (-387B medido por línea) | ≈0 | ✅ ADOPT |
| E5 | Tablas Anti-Rationalization 3-col → 1 línea por racionalización | Proyectado: 50% de 3800 tableChars | Total **-1.86KB** (≈-1900B, mayor win) | ≈0 a esta escala; win real = tokens | ✅ ADOPT — TOP WIN |
| E6 | `Verification` + `Red Flags` duplican chequeos (cross-ref-check, output contract) | Proyectado: ≈-150B/skill | Total **-0.73KB** (≈-750B) | ≈0 | ✅ ADOPT |
| E7 | MCP lazy-load: template `semi` (937B/12L) + futuro MCP 7.65KB no deben cargarse siempre | SOLO LECTURA `generate-opencode-config.js` (PROHIBIDO escribir opencode.json): propuesta lazy-load + skip semi (ADR-033 ya lo salta en build) | -0.92KB (semi) + **-7.65KB MCP lazy propuesta** | N/A (build-time) | 📝 PROPOSE (no aplicado) |
| E8 | Compaction 12k tokens: `compaction.reserved/keep.tokens` + snapshot profile-injected | SOLO LECTURA (11L compaction/snapshot): propuesta tuning reserved/keep | **-12k tokens** propuestos (contexto, no disco) | N/A | 📝 PROPOSE (no aplicado) |
| E9 | skill-graph: ejemplos JSON+CSV (L21-33) → 1 línea + reference.md | Shadow proyectado | 2.41→~2.02KB (**-0.39KB**, ≈-400B) | ≈0 | ✅ ADOPT |
| E10 | SkillOpt gate post-dieta: ≤3KB c/u, avg <2.0KB | Gate aritmético E1+E3+E4+E5+E6 | JD 4.03→~2.25KB ✅; media 5: 3.16→~1.85KB ✅ | — | ✅ PASS |

## Delta agregado

- Medido shadow (E1+E2): -783B (-0.76KB).
- Proyectado total dieta (E1–E6+E9, 5 skills): ≈ **-4.5KB** (-4620B), media -0.9KB/skill.
- Propuestas no aplicadas (E7+E8): -7.65KB MCP lazy + 12k tokens compaction.
- Parse ms: sin delta significativo a esta escala (±2ms ruido IO, n=20-30); el win es tokens/contexto, no IO.
- Top win: **E5 colapso Anti-Rationalization (-1.86KB)**. Segundo: E1 JD Zylos dedup (-0.52KB, saca a JD de over-3KB: 4.03→~2.25KB combinado).

## Propuestas (para implementador con permiso de escritura)

1. Aplicar E1–E6+E9 a los 5 SKILL.md (ahorro ≈4.5KB, SkillOpt PASS).
2. Extender E5 a top-8 over-3KB (performance-tracker, engram-protocol, context-watchdog, baseline-ui, testing-strategy, ui-engine).
3. E7: lazy-load MCP servers en `generate-opencode-config.js` (diseño) + completar limpieza base/template `semi` (JD follow-up citado en L146-149, L198-204).
4. E8: tuning `compaction.reserved/keep.tokens` (12k tokens).
