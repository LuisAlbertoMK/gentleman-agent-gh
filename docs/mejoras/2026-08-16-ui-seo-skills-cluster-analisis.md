# UI/UIX/SEO Skills Cluster — Automejora Analysis — 2026-08-16

**Project**: gentleman-agent-gh
**Scope**: 10 skills — baseline-ui, ui-engine, seo, web-quality-audit, performance, performance-tracker, accessibility, visual-testing, vision-analyze, image-pipeline
**Trigger**: `!analisis automejora` — "¿se pueden mejorar los resultados de calidad?"
**Mode**: read-only (analysis-mode GATE). Output to docs/mejoras/. No code changes.

## Summary

**SÍ, los resultados de calidad se pueden mejorar** — 3 palancas directas, con evidencia:

1. **Routing correctness**: 8 colisiones de triggers en el cluster → skill equivocada puede dispararse → output equivocado.
2. **Output contracts**: 4/10 skills sin sección `## Output` → el contrato C4d ya cableado en `post-delegation-check.ps1` (2026-08-15) no tiene contra qué validar.
3. **Regression protection**: 0 suites golden prompts, 0 token budgets en frontmatter → las compresiones futuras (como SEO 146→49) pasan silenciosas.

Estado general del cluster: **estructura buena** (todas tienen When-to-Use, Anti-Patterns, Testing, Examples, Refs — salvo image-pipeline sin Refs), **contenido 2026 al día** (SEO con E-E-A-T/AI Overviews/INP/ProfilePage verificado en checklist). Gaps concentrados en: contratos de salida, colisiones de routing, y verificabilidad.

## Scorecard (10 skills vs skill-testing/skill-improver standard)

| Skill | Líneas | When | Rules/Hard | Output | Anti-Pat | Refs | Testing | Examples |
|---|---|---|---|---|---|---|---|---|
| baseline-ui | 76 | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| ui-engine | 51 | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| seo | 49 | ✅ | ✅ Rules | ✅ | ✅ | ✅ +checklist | ✅ | ✅ |
| web-quality-audit | 88 | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| performance | 195 | ✅ | ✅ budget | ❌ | ✅ | ✅ | ✅ | ✅ |
| performance-tracker | 375 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| accessibility | 202 | ✅ | ✅ | ❌ | ✅ | ✅ +2 refs | ✅ | ✅ |
| visual-testing | 97 | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| vision-analyze | 117 | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| image-pipeline | 196 | ✅* | ❌ | ⚠ QuickRef | ✅ | ❌ | ✅ | ✅ |

\* image-pipeline usa headers propios (`## Pipeline Stages`, `## N Examples`), no estándar — el scanner no detectó `## When to Use` textual pero tiene sección equivalente. Estructura no conforme al estándar skill-testing.

## Findings (evidence-gated)

| # | Finding | Evidencia | Severity | Confidence |
|---|---------|-----------|----------|------------|
| F1 | **8 colisiones de triggers en cluster**: `responsive/container query/flexbox/grid`→baseline-ui+ui-engine; `ui audit`→baseline-ui+web-quality-audit; `inp`→seo+performance; `lighthouse`→web-quality-audit+performance-tracker | probe triggers 16 skills, 144 triggers, 8 dups | HIGH | high |
| F2 | **4/10 sin contrato `## Output`**: baseline-ui, ui-engine, performance, accessibility → validación C4d (`check-subagent-output.ps1`) no puede verificar sus resultados | scorecard headers | HIGH | high |
| F3 | **0/10 con token budget en frontmatter** (`token_budget`, `avg_prompt_tokens`) → skill-testing Pattern 3 (Token Budget Regression) no ejecutable | probe frontmatter 10 skills | MED | high |
| F4 | **0 suites golden prompts** (`tests/prompts/`) → skill-testing Pattern 1 (Golden Prompt Suite) no aplicado al cluster; compresiones sin regresión detectable | walk tests/ — NONE | HIGH | high |
| F5 | **SEO comprimido 146→49 líneas** (C4 bb136a69, cuerpos <2.9KB): contenido v3.0 sobrevive (checklist 39 líneas con EEAT/INP/AI/ProfilePage ✅) pero ultra-denso — legibilidad/recuperación de reglas en riesgo | git log + read SKILL.md + checklist probe | MED | high |
| F6 | **image-pipeline sin Refs/Cross-Refs** — único del cluster sin enlaces a accessibility (alt-text) / performance (LCP) / web-quality-audit; headers no estándar rompen tests default de skill-testing ("required sections exist") | scorecard refs | MED | high |
| F7 | **Análisis previo SEO (2026-07-29, obs-2d6d3edaf5fb98fa) STALE**: documentó v3.0 146 líneas; estado actual 49 líneas comprimidas — sin re-análisis desde entonces | git log + read doc previo | LOW | high |
| F8 | **Falta `## Hard Rules` en 7/10** (solo seo Rules, performance budget, performance-tracker, accessibility tienen reglas explícitas) — estándar skill-improver: actionability | scorecard | LOW | medium |
| F9 | **performance-tracker es el modelo a seguir**: 375 líneas, 6 dims, 5 examples, 3 testing patterns, edge cases, anti-patterns, output — estructura completa | scorecard | LOW | high |
| F10 | **Sin secciones Evidence/Verification estándar** en ninguna (usan `## Testing` embebido, no `## Verification` con gate de salida) | scorecard headers | LOW | medium |

## Synthesis

- **UNANIMOUS**: Las 10 skills tienen When-to-Use + Anti-Patterns + Testing + Examples → base estructural sólida post-C29 (deb22a1c).
- **MAJORITY**: Output contract ausente o informal (6/10) + sin medición de calidad (0/10 budget, 0/10 golden) → "resultados de calidad" no son verificables hoy.
- **SPLIT**: Colisiones de triggers (8) — todas intra-cluster, resolubles por desambiguación en vez de merge.

## Risk Matrix

| Riesgo | Prob | Impacto | Mitigación |
|--------|------|---------|------------|
| Skill equivocada dispara por trigger colisionante | MED | ALTO (output incorrecto silencioso) | Trigger Collision Matrix (skill-testing P2) |
| Compresión futura degrada contenido sin detectarse | ALTO | MED | Golden Prompt Suite (P1) + Token Budget (P3) |
| Subagente devuelve output no validable (sin ## Output) | MED | ALTO | Agregar Output contract a 4 skills; C4d ya validado |
| image-pipeline aislado del grafo de skills | BAJO | MED | Agregar Refs + headers estándar |

## Recommendations (ICE — Impact × Confidence / Effort)

| # | Acción | I | C | E | ICE | Blast | Prioridad |
|---|--------|---|---|---|-----|-------|-----------|
| R1 | **Trigger Collision Matrix** para el cluster (skill-testing P2) → resolver 8 dups: baseline-ui vs ui-engine (disambiguate por intención: audit-cleanup vs implementación), `ui audit`, `inp`, `lighthouse` | 9 | 8 | 4 | 18 | **ALTO** | **C1→HUMAN CHECKPOINT** |
| R2 | **Agregar `## Output` contract** a baseline-ui, ui-engine, performance, accessibility (formato: findings → fix → verify, alineado al return-contract 4-field) | 8 | 7 | 3 | 18.7 | ALTO | C1 |
| R3 | **Golden Prompt Suite** del cluster: `tests/prompts/` con 5-10 prompts reales por skill (skill-testing P1) → regression en cada compresión | 9 | 4 | 5 | 7.2 | ALTO | C1→requiere setup |
| R4 | **Token budgets en frontmatter** ×10 (Pattern 3) — medir avg/max reales, registrar, assert <1.1× | 6 | 10 | 2 | 30 | MEDIO | C2 |
| R5 | **image-pipeline**: headers estándar (`## When to Use`, `## Anti-Patterns`) + `## Refs` → accessibility/performance/web-quality-audit | 7 | 5 | 2 | 17.5 | MEDIO | C2 |
| R6 | **Re-análisis SEO** contra checklist v3.0 (verificar que la compresión no perdió reglas accionables) | 6 | 6 | 1 | 36 | MEDIO | C2 |
| R7 | **`## Hard Rules`** en 7 skills (MUST/MUST-NOT por skill) | 6 | 7 | 3 | 14 | BAJO | C3 |

**Orden sugerido**: R1+R2 (impacto inmediato en calidad de resultados, sin infra) → R4+R5+R6 (higiene) → R3 (infra de regresión, mayor setup).

## Engram Persistence

- Observation: `analysis:gentleman-agent-gh:2026-08-16` (topic_key: `analysis/skills-ui-cluster`)
- Cross-ref: `analysis/seo-skill` (obs-2d6d3edaf5fb98fa, 2026-07-29) — F7: stale
- Cross-ref: C28/C29 cycle docs (skill compression + depth-add)

## Trend vs Previous

- **vs 2026-07-29 (SEO skill)**: contenido v3.0 implementado ✅ → comprimido a 49 líneas ⚠ → contenido sobrevive ✅. Gap nuevo: densidad extrema + sin golden tests.
- **vs C29 (2026-08-16)**: depth sections agregadas ✅ → ahora el gap es de **verificabilidad** (output contracts + golden suite), no de contenido.

## Files Examined

- `.agents/skills/{baseline-ui,ui-engine,seo,web-quality-audit,performance,performance-tracker,accessibility,visual-testing,vision-analyze,image-pipeline}/SKILL.md` (+ seo/references/audit-checklist.md, accessibility/references/*)
- `docs/mejoras/2026-07-29-seo-skill-analisis.md`, `docs/mejoras/2026-08-15-subagent-result-quality.md`
- `docs/ciclos/cycle28-20260815.md`, `docs/agentes/skill-compression-C28/05-implementacion-completada.md`
- git log: bb136a69 (C4 compression), deb22a1c (C29 depth), 5b1b2e58 (UI/SEO improve)

## Execution Report — R1+R2 (2026-08-16, post-analysis)

### R1: Trigger collisions resolved (8 → 0) ✅

| Skill | Change |
|-------|--------|
| baseline-ui | Dropped `responsive, container query, flexbox, grid, ui audit` → added `anti-slop, ui polish, polish ui` (audit-intent only) |
| seo | Dropped `INP` (trigger belongs to performance; metric stays in content) |
| performance-tracker | Dropped `lighthouse` → added `perf tracking, performance trend` |
| infra-audit | Deduped `terraform`/`Terraform` self-collision |

**Verify**: probe re-run = **0 collisions** in cluster + neighbors.

### R2: Output contracts added (4 skills) ✅

| Skill | Output format |
|-------|---------------|
| baseline-ui | `UI-CLEANUP:<file>—<date> CRITICAL:[a11y|contrast]→ HIGH:[layout|responsive]→ MEDIUM:[tokens|anim]→ VERIFY:→` |
| ui-engine | `UI-IMPL:<component>—<date> PATTERN: VERIFY:[a11y|contrast|reduced-motion|CQ]→ FALLBACK:[@supports]→` |
| performance | `PERF:<page>—<date> BUDGET:[LCP|INP|CLS|TBT]vs→PASS/FAIL FIX: VERIFY:[lhci|test]→` |
| accessibility | `A11Y:<page>—<date> CRITICAL:[wcag-2.x]→ HIGH: MEDIUM: VERIFY:[axe|nvda|tab]→` |

All aligned to severity-bucket → fix → verify pattern of seo/web-quality-audit, matching the 4-field return contract for C4d validation.

### Verification (all green)

```
cross-ref-check.ps1: ALL CHECKS PASSED (9/9)
skill-coverage-e2e.Tests.ps1: 4/4 PASSED
git diff: 7 files, +16/−4 (minimal, intent-preserving)
```

### Correction to scorecard

performance-tracker, visual-testing, vision-analyze express output as "Expected output/Result" inside Examples — **not** a formal `## Output` section. Scorecard column corrected: they are ⚠ informal, not ✅ (recommendation R2-ext: promote to formal sections in a later pass).

### R2-ext, R4, R5 (2026-08-16, second pass) ✅

**R2-ext — Output formal ×3**: performance-tracker (`PERF-SCORE:...TREND:`), visual-testing (`VRT:...DIFF:...VIEWPORTS:`), vision-analyze (`VISION:...MODEL:...`). **10/10 skills now have formal `## Output`** (was 6/10).

**R4 — Token budgets ×10**: added `token_budget: <N>` to frontmatter of all 10 cluster skills (measured bytes/4, range 883–4054). Convention created per skill-testing Pattern 3 (assert actual < recorded × 1.1 on every test run). Baselines: baseline-ui 1029, ui-engine 1026, seo 963, web-quality-audit 1117, performance 1916, performance-tracker 4054, accessibility 2431, visual-testing 883, vision-analyze 1036, image-pipeline 1782.

**R5 — image-pipeline conformed**: added `## When to Use` (with NOT-scope guard vs visual-testing/vision-analyze), renamed `## 2 Anti-Patterns` → `## Anti-Patterns` (standard header), added `## Refs` → performance/accessibility/web-quality-audit/visual-testing (was the only cluster skill without cross-refs), added formal `## Output` (IMG-PIPE).

**Verification (all green)**
```
cross-ref-check.ps1:      ALL CHECKS PASSED (9/9)  [twice, after both passes]
skill-coverage-e2e:       4/4 PASSED               [twice]
collision probe:          0 collisions             [was 8]
## Output formal:         10/10                    [was 6/10, 4 informal]
token_budget frontmatter: 10/10                    [was 0/10]
git diff:                 11 files, +48/−7         [both passes]
```

### R6 + R7 (2026-08-16, third pass) ✅

**R6 — SEO re-analysis vs v3.0 checklist + encoding corruption repair**: content v3.0 survives compression intact (checklist 39→37 lines: Critical/High/Medium/AI Visibility with E-E-A-T, INP<200ms, ProfilePage, GSC GenAI report all present). Found + repaired **encoding corruption** (control chars ate first letters of keywords): `seo/references/audit-checklist.md` (2 lines: "no noindex", "robots.txt" broken by CR) + `accessibility/SKILL.md` (**24 control chars in 14 lines** — BELL U+0007 ate "a" of aria-*/alt/axe-core, CR ate "r" of role/rem, ESC ate "e" of eslint-plugin, BS ate "b" of ```bash, TAB ate "t" of typescript). All normalized CRLF→LF, verified **0 control chars** across all 10 skills + references.

**R7 — `## Hard Rules` added (5 skills)**: baseline-ui (6 rules: anim transform/opacity only, reduced-motion, OKLCH-only, no fixed widths, CQ inline-size, 1 primary color), web-quality-audit (6: reachable target, thresholds, Critical/High blocks gate, severity buckets, cadence, inline-size), performance-tracker (5: measure never guess, platform-in-title isolation, no skipped dims, N≥5 trend, median-of-3 CI), vision-analyze (3: no visual regression, RAM-aware model, 100% local), image-pipeline (6: source-only encoding, validate-first, per-image quality, ICC strip, >32K downscale, SSIM verify). All derived strictly from existing content, placed before `## Output`. (Note: 5/10 already had rule sections — ui-engine Decision Tree, seo Rules, performance Budget, accessibility POUR, visual-testing Decision Tree — so F8 corrected from 7/10 to 5/10.)

**Verification (all green)**
```
cross-ref-check.ps1:        ALL CHECKS PASSED (9/9)   [3rd time]
skill-coverage-e2e:         4/4 PASSED                [3rd time]
control chars (10 skills):  0                         [was 24 in accessibility + 3 in seo checklist]
## Hard Rules sections:     5/5 valid, order before ## Output
token_budget + Output:      still 10/10 (no regression)
```

### R3 — Golden Prompt Suite (2026-08-16, fourth pass) ✅

Created `tests/prompts/` — 10 golden prompts (1 per cluster skill) + README documenting the runtime harness pattern (LOAD→APPLY→VERIFY vs `## Output` contract).

**Static gate** `tests/golden-prompts.Tests.ps1` (7 tests, Pester, repo convention):
- Coverage: 10/10 prompts, no orphans, count = cluster size
- Trigger activation: each prompt matches ≥1 real frontmatter trigger + **Trigger line** is a real trigger of its skill
- Primary-trigger collision: each prompt's primary trigger is NOT an exact trigger of another cluster skill

**New finding — R1 gap (F1 follow-up)**: the gate caught a real collision R1 missed: `screenshot` was an exact trigger of BOTH `vision-analyze` and `visual-testing`. Resolved by removing `screenshot` from vision-analyze (its owner is visual-testing's `toHaveScreenshot`; vision-analyze keeps `capture, vision, analyze-ui, visual-review, captura, analizar-imagen`). Prompt golden de vision-analyze updated to match. This proves the suite's value: **static trigger-collision probes can miss substring/context collisions; golden-prompt routing checks catch them**.

**Verification (all green)**
```
golden-prompts.Tests.ps1:  7/7 PASSED        [new gate]
cross-ref-check.ps1:       ALL CHECKS PASSED (9/9)   [4th time]
skill-coverage-e2e:        4/4 PASSED                [4th time]
trigger collisions:        0 (R1's 8) + 1 more found+fixed (screenshot) = 0
```

### Remaining (deferred)

- R2-note: `## Cross-Refs` header (standardized name) still not used — skills use `## Refs` (compatible, cross-ref-check passes)
- R3 runtime harness: static gate proves suite integrity; runtime LOAD→APPLY→VERIFY requires opencode runtime (documented in tests/prompts/README.md)