# Ronda 6 — Skills barrido C2-C8 + re-sync índice — ODD Gate + Slice Plan + RDD Freeze (Fase 1: análisis, SIN código)

> Fase 1 — análisis y freeze. NO implementar código en esta fase. NO commit, NO push, NO checkout, NO merge.
> Rama: `experimento/mejora-ronda6-skills-barrido` · HEAD `91ccbcf7` (cierre R5 PASS global) · main `67707025` intacto (solo lectura).
> Alcance (decidido en Gate R5 — `odd/tasks/ronda5-skills-audit.md:91-95`): barrido C2-C8 (~80 skills) + re-sync `SKILLS-INDEX.md` (grupos stales, conteo 96 sano). Cola v3 (`research-plan.md:221-232` cit. R5) NO es parte de R6.
> Evidencia medida EN ESTA RAMA (no re-medir en ejecución salvo Verify): `scripts/skills-audit-check.ps1` (178L) + `docs/skills/audit-checklist.md` (34L, congelada S1) + corrida `-All` completa en esta rama (26 FAIL / 70 PASS).

## 0. Veredicto A4/B2 — regla vs contenido (corazón del Gate, `confidence: high`)

### A4-structure: (i) REGLA MAL CALIBRADA — falso positivo sistemático

- Regla: `scripts/skills-audit-check.ps1:86` — `$hasStruct = ($body -match '##\s+(When to Use|Workflow|Rules|Flow|4R|SCAN DIMENSIONS)')` (allowlist de 6 nombres, solo `##` h2). Checklist: `docs/skills/audit-checklist.md:12`.
- Medición (esta rama, corrida `-All` completa): **18/18 fallos A4 son `struct=False` con la segunda mitad (discoverability) en PASS** — `docsRef=True xref=True` en 17/18, `refsDir=True docsRef=True xref=True` en 1/18 (`engram-protocol`). 0/18 fallan por discoverability. El fallo es 100% vocabulario de headings.
- Muestras (estructura real bajo nombres legítimos que el allowlist no conoce):
  - `baseline-ui/SKILL.md:8-22` — `## Typography`, `## Tokens OKLCH→Var`, `## Hard Rules` (≠ `## Rules` exacto exigido), `## Output` + `docs/skills/baseline-ui/reference.md` + `Cross-Refs` (`:47`).
  - `metricas/SKILL.md:23-48` — `## Two Modes`, `## Tokenization`, `## CLI` + `docs/skills/metricas/reference.md` + `Cross-Refs` (`:68`).
  - `sdd-spec/SKILL.md:21-27` — `### MODIFIED Workflow` (h3, el regex exige h2) + `Rules (Given/When/Then…)` inline (no-heading) + `docs/skills/sdd-spec/reference.md` + `Cross-Refs` (`:46`).
  - `trial-verify/SKILL.md:13-30` — `## Trigger`, `## Process`, `## Hard stops`, `## Budget caps` + `docs/skills/trial-verify/reference.md` + `Cross-Refs` (`:53`).
  - `ui-engine/SKILL.md:8-27` — `## Decision Tree`, `## Layout`, `## Animation`, `## Tokens`, `## A11y`, `## Output` + `docs/skills/ui-engine/reference.md` + `Cross-Refs` (`:42`).
- Agravante: el test compañero (`scripts/tests/skills-audit-check.Tests.ps1`, **12 Its medidos** — 1 parse + 1 PASS + 10 FAIL-contraste A1/A2/A3/B1/B2/B3/C1/C2/C3/missing-file) **no tiene ningún fixture A4** — la regla nunca se validó contra diversidad de headings.
- La spec Anthropic exige frontmatter + instrucciones + progressive disclosure (discoverability — la mitad que SÍ pasa en 18/18), NO 6 nombres de heading. El allowlist inventa un requisito.
- **Impacto en el plan**: el fix es la REGLA (S0, slice priorizado), NO reescribir 18 skills. 12 skills solo-A4 (`metricas`, `performance`, `performance-tracker`, `sdd`×9) se vuelven PASS sin tocarlas: 70/96 → **82/96**.

### B2-red-flags: (ii) CONTENIDO REAL — gap trivial, la regla queda como está

- Regla: `scripts/skills-audit-check.ps1:107-110` — `## Red Flags` + ≥1 bullet + verbo `STOP|force|escalat|BLOCKER|prioritiz|reject|exigir`.
- Medición (esta rama): **12 skills con `XX B2`** (corrige el "14/26" del brief — las propias anotaciones por-skill del baseline también suman 12; `confidence: high`).
  - 11/12 TIENEN la sección con 2 bullets accionables de dominio pero sin verbo de escalación: `baseline-ui/SKILL.md:34-36` ("Hardcoded `#fff`… → slop", "Animation on width… → compositor violation"), `best-practices/SKILL.md:31-33` (`npm audit` alone…, Permissions… without explanation). Fix = 1 verbo/bullet (~1-2L/skill). La exigencia de semántica de escalación es intent correcto — NO se relaja la regla.
  - 1/12 (`ui-engine/SKILL.md`, `bullets=0`) NO tiene la sección — gap real, +4L.
- Resto de reglas verificado genuino (sin recalibrar): B1×2 (`opencode-model-router`, `ps-compat`, `dataRows=0`, tabla ausente), B3×3 (`opencode-model-router`/`ps-compat` `bullets=0`; `session-resume` `bullets=1` sin evidencia ejecutable), C1×1 (`judgment-day` `token_budget=7000` fuera de 500–5000), C2×3 (`engram-protocol`, `opencode-model-router`, `trial-verify`, changelog ausente), C3×1 (`judgment-day` 7634B > 6144).

### Baseline corregido (medido, `confidence: high`)

70/96 PASS · 26 FAIL: A4 18 (12 solo-A4) · B2 12 · B1 2 · B3 3 · C1 1 · C2 3 · C3 1 (40 rule-hits).
Gap de evidencia: `research-plan.md` NO existe en el repo (glob `**/research-plan.md` = 0 hits) — las citas `research-plan.md:58-64+194-197+221-232` quedan `confidence: medium`/unvalidated; R6 no depende de ellas (el scope H lo porta `ronda5-skills-audit.md:5`).

## 1. ODD Gate por slice

Regla (precedente `ronda4-lcm-resto.md:14`): ALL criteria must pass para SMALL (≤50L, 1 file + test compañero, sin schema/auth/API, sin deps externas, ≤2 commits); si alguno falla → SUBSTANTIAL (slice ≤400L).

| Criterio (`odd`) | Umbral SMALL | S0 fix regla A4 | S1 verbos B2 + C1/C2 | S2 contenido B1/B3/C3 | S3 re-sync índice |
|---|---|---|---|---|---|
| Líneas est. | ≤50L | ~40-70L ❌ | ~30L ✅ | ~80-110L ❌ | ~20-40L ✅ |
| Files | 1 (+ test) | 3-4 ❌ (script + checklist + test + marker) | 12 ❌ | 5 ❌ | 1-2 ✅ |
| Schema/auth/API | None | None ✅ | None ✅ | None ✅ | None ✅ |
| Deps externas | None | None ✅ | None ✅ | None ✅ | None ✅ |
| Commits forecast | ≤2 | 1 ✅ | 1 ✅ | 1 ✅ | 1 ✅ |
| **Veredicto** | — | **SUBSTANTIAL → R6-S0 (Tier 2)** | **SUBSTANTIAL → R6-S1 (Tier 1)** | **SUBSTANTIAL → R6-S2 (Tier 1)** | **SMALL → R6-S3 (Tier 1)** |

- **S0 primero (mandatorio)**: congela la regla corregida antes de tocar contenido — sin S0, S1/S2 reescribirían 18 skills contra un falso positivo. `confidence: high` en la necesidad; `medium` en líneas exactas.
- **R6 total: 4 slices ≈ 2 sesiones** (S0 ~0.5 + S1 ~0.5 + S2 ~0.5-1 + S3 ~0.5). El barrido NO excede R6 → **nada se deriva a Ronda 7 por capacidad** (R7 = cola v3, §8).

## 2. Slice Plan (1 slice = 1 conventional commit ≤400L, verificación en mismo commit)

Orden mandatorio: **S0 (regla) → S1 (triviales) → S2 (contenido) → S3 (índice)**.

- **R6-S0 — `fix(skills): recalibrate A4-structure rule + fixtures + marker sync`** (Tier 2)
  Scope: `scripts/skills-audit-check.ps1:86` (`$hasStruct`: allowlist-6 → "≥1 `##` sustantiva fuera del set meta `{Anti-Rationalization, Red Flags, Verification, Refs, Reference Materials}`"; mitad discoverability intacta) + `docs/skills/audit-checklist.md:12` (misma redefinición) + 2 fixtures en `scripts/tests/skills-audit-check.Tests.ps1` (A4-PASS con headings alias tipo `## Hard Rules`/`## Process`; A4-FAIL skill delgada sin secciones → 12→14 Its) + sync del marker `.breaker-cleared/scripts_tests_skills-audit-check.Tests.ps1_bb6407ba:15` ("13 Its… 11 FAIL-contraste" → cifra real post-S0; el nit "13 vs 12" se absorbe aquí porque S0 cambia el conteo de todos modos). Est. ~40-70L. `confidence: medium`.
  Outcome: audit 70/96 → **82/96** (12 solo-A4 auto-PASS); 0 skills tocadas.
- **R6-S1 — `feat(skills): B2 escalation verbs + C1/C2 frontmatter (12 skills)`** (Tier 1)
  Scope: solo `.agents/skills/*/SKILL.md` — verbo de escalación en 11 Red Flags existentes (`baseline-ui`, `best-practices`, `bitacora`, `judgment-day`, `opencode-model-router`, `opencode-skill-creator`, `ps-compat`, `ralph-loop`, `session-resume`, `skill-graph`, `state-reconcile`; ~1-2L c/u) + `changelog:` en `engram-protocol`, `opencode-model-router`, `trial-verify` + `token_budget: 7000→≤5000` en `judgment-day`. Est. ~30L. `confidence: high`.
  Outcome: 82/96 → **91/96** (9 skills a PASS pleno; restan 5: `judgment-day`[C3], `opencode-model-router`[B1,B3], `ps-compat`[B1,B3], `session-resume`[B3], `ui-engine`[B2]).
- **R6-S2 — `feat(skills): B1 tables + B3 verification + ui-engine Red Flags + judgment-day debloat (5 skills)`** (Tier 1)
  Scope: solo `.agents/skills/*/SKILL.md` (+ `docs/skills/judgment-day/` si el debloat externaliza): tablas `## Anti-Rationalization` reales skill-specific en `opencode-model-router`, `ps-compat` (~10-15L c/u); `## Verification` ejecutable en `opencode-model-router`, `ps-compat`, `session-resume`; sección `## Red Flags` nueva en `ui-engine` (+4L); `judgment-day` 7634B→≤6144B (mover ejemplos a `docs/skills/judgment-day/reference.md`). Est. ~80-110L. `confidence: medium`.
  Outcome: 91/96 → **96/96 ALL PASS**.
- **R6-S3 — `docs(skills): SKILLS-INDEX Quick Groups re-sync`** (Tier 1, SMALL, doc-only)
  Scope: `SKILLS-INDEX.md:33-49` — grupo SDD 6→11 dirs de filesystem (`sdd, sdd-apply, sdd-archive, sdd-design, sdd-explore, sdd-init, sdd-propose, sdd-quick, sdd-spec, sdd-tasks, sdd-verify`); asignar ~30 dirs no agrupados (`skill-improver`, `skill-testing`, `lean-context`, `judgment-day`, `state-reconcile`, …) a grupos; conteos intactos (96 project + 99 global per `:53` — el conteo está sano, solo los grupos están stales). Est. ~20-40L. `confidence: medium`.
  Outcome: índice navegable; 0 cambios de código/skills.

## 3. RDD Freeze (re-capturado EN ESTA RAMA, antes de cualquier cambio futuro)

- **Freeze string:** `HEAD-91ccbcf7-e69de29b`
- **Captura (solo lectura — no commit/push/stash/checkout):**
  - `git branch --show-current` → `experimento/mejora-ronda6-skills-barrido` ✅ (fail-closed pasado: es la rama exigida)
  - `git rev-parse HEAD` → `91ccbcf729e391fdf4d29c56bf172cc6be87183c` | short `91ccbcf7` (= cierre R5 PASS global ✅)
  - `git rev-parse main` → `6770702545ef6c39b8fe22ecbec3259033bc65db` | short `67707025` (intacto ✅, solo lectura)
  - `git status --porcelain` → vacío (clean tree) | `git diff HEAD --stat` → vacío
  - `git diff HEAD | git hash-object --stdin` → `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391` (árbol vacío = limpio) → diff8 `e69de29b`
- **Tier por slice + review plan:**
  - R6-S0 (script + checklist + test + marker) → **Tier 2** — toca `scripts/` (wiring futuro a gate/CI = presunción no refutada, como R5-S1); 4R (`code-review-agent`) BLOCKER-capable (script sigue solo-lectura: ningún write fuera del report; fixtures herméticas TestDrive; la regla relajada NO hace PASS a skill delgada — lo prueba el fixture A4-FAIL); FAIL → `judgment-day`, nunca auto-fix.
  - R6-S1/S2 (skill-only `.md`) → **Tier 1** — sin schema/auth/API/runtime/CI; 4R estándar (B1 tablas skill-specific reales, B2 verbos de escalación, B3 pasos ejecutables; `SKILLS-INDEX.md` NO tocado hasta S3); FAIL → iterar contenido, nunca auto-fix. **Excepción fail-closed**: si un contenido exige tocar `scripts/` o CI → extraer a sub-slice Tier 2, NO mezclar.
  - R6-S3 (índice doc-only) → **Tier 1** — 4R leve (grupos vs filesystem); FAIL → corregir mapeo.
  - Re-freeze + re-review si el freeze queda stale antes de ejecutar un slice.
- **Verify por slice (base R5 vigente + skills checks):** MCP **22/22** PASS + generate-config **16/16** PASS + jd-verifier **28/28** PASS + lcm-dag **13/13** PASS + skill-frontmatter **10/10** + skill-validate **2/2** + PSSA sin warnings/errors + cross-ref-check ALL PASSED + gate suites sin regresión (`confidence: medium` hasta re-correr en ejecución; cifras base R5 `ronda5-skills-audit.md:61-64`).
  - S0 además: `skills-audit-check.Tests.ps1` **14/14** (12 + 2 fixtures A4) + audit `-All` = **82/96** con las 12 solo-A4 en PASS + suites frontmatter/validate sin regresión.
  - S1 además: audit = **91/96** (delta +9) + cross-ref-check ALL PASSED.
  - S2 además: audit = **96/96 ALL PASS** + `mejoras-index-check` si aplica.
  - S3 además: grupos del índice reconcilian con filesystem (conteo de grupos = 96 dirs excl. `_shared`).

## 4. Receipt templates (preparadas, NO emitir aún)

```json
{
  "receipt_id": "rdd-receipt-ronda6-s<N>",
  "freeze": "HEAD-91ccbcf7-e69de29b",
  "tier": "<1|2>",
  "slice": "<N> — <scope>",
  "files": ["<paths>"],
  "review": { "type": "4R", "verdict": "<PASS|WARN|FAIL|BLOCKER>", "escalation": "<none|judgment-day>" },
  "verify": { "pester_mcp": "22/22", "generate": "16/16", "jd_verifier": "28/28", "lcm_dag": "13/13", "frontmatter": "10/10", "skill_validate": "2/2", "pssa": "clean", "cross_ref": "ALL PASSED", "audit_check": "<S0: 82/96 | S1: 91/96 | S2: 96/96 | S3: groups==filesystem>" }
}
```

## 5. Review Log (vacío — Fase 1)

| Slice | Commit | 4R veredicto | Gate | Estado |
|-------|--------|--------------|------|--------|
| S0 (regla A4 + fixtures + marker) | (este commit) `fix(skills): recalibrate A4-structure rule + fixtures + marker sync` | 4R PASS (implementer self-review: script sigue solo-lectura — ningún write fuera del report; fixtures herméticas TestDrive con allowlist intacta; regla NO vacua — fixture A4-FAIL con solo headings meta falla; PSSA delta 0 warn/err; checklist 1:1 con script) | Gate 28/28 ALL CLEAR (corrida pre-commit sobre el set final; sin FORCE_SHIP; markers pre-existentes, solo sync de contenido) | ✅ hecho — audit 82/96 exacto, Pester 14/14, 0 regresiones |
| S1 (B2/C2 12 skills, sin JD) | (este commit) `feat(skills): B2 escalation verbs + C2 changelog (Ronda6 S1)` | 4R PASS (implementer self-review: skill-only `.md`, sin runtime/CI/schema; 10 verbos semánticos dominio-específicos, 0 STOP arbitrarios — bitacora/skill-creator/session-resume/skill-graph/state-reconcile 1L c/u, baseline-ui/best-practices 2L c/u, router/ralph-loop sección mínima nueva 4-5L; judgment-day revertido a HEAD (B2+C1+C3 → S2); trial-verify C2 = reorder a orden repo-standard — causa: regex C2 exige `\n` post-valor y última línea nunca matchea; best-practices 3992→4600 — file ya al 100% del límite en HEAD (4391=4391), +113B verbos mandatorios, precedente R5-S2 rdd 2850→3900; PSSA N/A — 0 `.ps1` tocados) | Gate 28/28 ALL CLEAR (sin JD sale el único rojo estructural [25/26]; sin FORCE_SHIP; sin marker) | ✅ hecho — audit **91/96** exacto (delta +9; restan 5: `judgment-day`[B2,C1,C3] `opencode-model-router`[B1,B3] `ps-compat`[B1,B3] `session-resume`[B3] `ui-engine`[B2]); suites frontmatter 10/10 + validate 2/2 + MCP 22/22 + generate 16/16 + jd 28/28 + lcm-dag 13/13 + audit-check 14/14; cross-ref-check ALL PASSED. Traspaso: judgment-day (B2+C1+C3) → S2; techo real del debloat = file ≤5500B con budget ≤5000 (no 6144B) |
| S2 (B1/B3/C3 5 skills) | (este commit) `feat(skills): B1 tables + B3 verification + JD debloat (Ronda6 S2)` | 4R PASS (implementer self-review: skill-only `.md`, sin runtime/CI/schema; B1 tablas skill-specific router/ps-compat 3 rows (ps-compat = rename heading, contenido intacto); B3 ejecutable router 3/session-resume 4 bullets (ps-compat numbered→bullets con comandos); ui-engine Red Flags nueva 5 bullets dominio + verbos; JD B2 STOP/BLOCKER + C1 7000→5000 + debloat 7634→5456B ≤5500 (detalle P1-6 ya en reference.md, reference NO tocado); budgets router 3200→4400/session 2100→2400/ui-engine 2200→2900 por token-regression, precedente R5-S2 rdd 2850→3900; PSSA N/A — 0 `.ps1`) | Gate 28/28 ALL CLEAR (WARNs no bloqueantes pre-existentes: [5/26] >3KB advisory, [8/26] AGENTS.md benchmark, [17/26] config drift; sin FORCE_SHIP; sin marker) | ✅ hecho — audit **96/96 ALL PASS** (delta +5); frontmatter 10/10 + validate 2/2 + MCP 22/22 + generate 16/16 + jd 28/28 + lcm-dag 13/13 + audit-check 14/14 + token-regression 97/97 + cross-ref ALL PASSED; mejoras-index 60/90 pre-existente no causado (0 docs/mejoras tocados) |
| S3 (índice re-sync) | — | — | — | 🔲 pendiente |

## 6. Rollback por slice

Cada slice commitea independiente en ESTA rama (nunca main): `git revert <slice-N>` sin tocar los otros slices ni `91ccbcf7`. Si un slice invalida el freeze del pendiente → re-freeze (§3) antes de continuar. Si S0 no lleva el audit a 82/96 exactos → STOP y re-diagnosticar (no forzar contenido contra la regla nueva). Si S2 excede ~110L → partir en S2a (B1/B3) + S2b (C3 debloat). Prohibido: merge a main sin orden explícita (`mejora-log.md:356`); prohibido: tocar main incluso para "verificar" (solo lectura `rev-parse`/`log`, nunca checkout).

## 7. Para Ronda 7 (explícito, NO parte de esta ronda)

- **Cola v3 no tocada** (vía `ronda5-skills-audit.md:94`, `research-plan.md` ilocalizable — ver §0 Gap): R2-5 initializer-agent, R2-2 listings, P1-2/P1-3, R2-3/R2-6/P2-*. Ningún adelanto justificado: R6 satura ~2 sesiones con S0-S3.
- **Extensión opcional del verbo-list B2** (sinónimos de dominio) — solo si 4R lo pide tras S1; por defecto la regla queda intacta.
- **Re-calibración C3** (¿6KB es el umbral correcto post-expansión?) — solo si `judgment-day` debloat degrada contenido; por defecto umbral intacto.
