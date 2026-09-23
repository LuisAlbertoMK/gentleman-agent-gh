# Ronda 5 — Skills audit P1-1 + R2-1 — ODD Gate + Slice Plan + RDD Freeze (Fase 1: análisis, SIN código)

> Fase 1 — análisis y freeze. NO implementar código en esta fase. NO commit, NO push, NO checkout, NO merge.
> Rama: `experimento/mejora-ronda5-skills-audit` · HEAD `85b75f71` (cierre R4 rebaseado sobre origin/main `a7458bff`) · main `67707025` intacto (solo lectura).
> Alcance H (decidido en Gate R4 — `odd/tasks/ronda4-lcm-resto.md:52-57`): P1-1 (Anthropic Agent Skills spec compliance audit, HIGH, 2 sesiones — `research-plan.md:58-64`) + R2-1 (estructura addyosmani: anti-rationalization tables, red flags, verification steps — `research-plan.md:194-197`). Cola v3 `research-plan.md:221-232` NO es parte de R5 salvo §8.
> Evidencia existente (no re-investigada): `research-plan.md:58-64 + :194-197 + :227` · `odd/tasks/ronda4-lcm-resto.md` (cadena R1-R4 + Gate H→R5) · `mejora-log.md:356` (protocolo experimento/PR: "esperar orden explícita; no mergear") · KB r2-fundesk-skills-guide + r2-anthropic (Engram 856/858, memoria no web).
> Base post-rebase medida EN ESTA RAMA: skills reorganizadas por remoto (archivadas, dedup creator, reindex) — el audit corre sobre el estado real medido en §1, no sobre los "93 skills" históricos del plan.

## 1. Conciliación conteo 97 vs SKILLS-INDEX (medición directa, `confidence: high`)

- Filesystem: `.agents/skills/` = **97 dirs** (medido `Get-ChildItem -Directory` + sort; lista completa verificada en esta rama).
- `Get-ChildItem -Path ".agents/skills/*/SKILL.md"` = **97 archivos**; ningún dir sin `SKILL.md`, ningún dir con >1 `SKILL.md` (verificado por agrupación — 0 duplicados, 0 faltantes).
- Excluyendo `_shared`: **96 dirs** (`Get-ChildItem -Directory -Exclude "_shared"` = 96).
- SKILLS-INDEX: `SKILLS-INDEX.md:3` dice "all 96 skills"; `:53` dice "96 project + 99 global"; `:5` changelog 5.6 dice explícitamente "count 93→94 (**excl. _shared** per cross-ref Get-SkillDir)".
- **`_shared` ES la #97**: `.agents/skills/_shared/SKILL.md` existe; frontmatter `name: _shared`, `description: "Internal shared references … Not an invokable skill."` (`_shared/SKILL.md:1-13`); cuerpo "Not Invokable … support package only, do not invoke".
- **Veredicto: índice NO stale.** 97 (filesystem, con soporte) − 1 (`_shared`, no invocable, excluido por regla vigente) = **96 skills auditables = índice 96** ✅. Alcance del audit = **96 skills** (los "93" de `research-plan.md:59,62,197` son cifra histórica pre-expansión; la cifra operativa es 96).
- Hallazgo secundario (`confidence: medium`, a confirmar en ejecución S1): los **Quick Groups** de `SKILLS-INDEX.md:33-49` están **parcialmente stales** vs filesystem — familia `sdd-*` tiene **11 dirs** en disco (`sdd, sdd-apply, sdd-archive, sdd-design, sdd-explore, sdd-init, sdd-propose, sdd-quick, sdd-spec, sdd-tasks, sdd-verify`) pero el grupo SDD (`:40`) lista 6; `skill-improver`, `skill-testing`, `lean-context`, `judgment-day`, `state-reconcile` y ~30 dirs más no aparecen en ningún grupo. Por eso el barrido H2+ se clusteriza **desde filesystem (§3)**, no desde los grupos del índice. Re-sync del índice = slice explícito en R6 (§8), NO en R5.

## 2. ODD Gate por ítem

Regla (precedente `ronda4-lcm-resto.md:14`): ALL criteria must pass para SMALL (≤50L, 1 file + test compañero, sin schema/auth/API, sin deps externas, ≤2 commits); si alguno falla → SUBSTANTIAL (slice ≤400L).

| Criterio (skill `odd`) | Umbral SMALL | H1. Framework + checklist + script + pilot 5 skills | H2+. Barrido sistemático (~91 restantes) |
|---|---|---|---|
| Líneas est. | ≤50L | ~250-350L ❌ (checklist ~60L + script ~120-150L + 5×~30L pilot + tests) | ~330-400L por cluster ❌ (11-12 skills × ~30L) |
| Files | 1 (+ test) | 8+ ❌ (checklist doc + script + test + 5 SKILL.md) | 11-12 ❌ (un cluster) |
| Schema/auth/API | None | None ✅ (skill-only + script lectura; script NO toca secrets/auth — si el diseño final lo wiring a gate/CI ver Tier §4) | None ✅ (skill-only `.md`) |
| Deps externas | None | Spec Anthropic + addyosmani solo lectura ✅ (KB r2-*, Engram 856/858 — memoria, no web) | Igual ✅ |
| Commits forecast | ≤2 | 1 ✅ | 1 por cluster ✅ |
| **Veredicto** | — | **SUBSTANTIAL → R5-S1** | **SUBSTANTIAL → R5-S2 (solo C1) + R6 (C2-C8)** |

- **H1 (framework + pilot) es slice obligatorio, no muestreo desechable**: a diferencia del "pilot sin framework" descartado en R4 (`ronda4-lcm-resto.md:54-57`), aquí el pilot de 5 skills **valida el framework** (checklist + script verde en 5 shapes diversos antes de congelarlo para el barrido). Sin H1, el barrido sería inconsistente. `confidence: high` en la necesidad; `medium` en el costo exacto del script (diseño en S1).
- **H2+ excede R5 (~2 sesiones)**: 96 − 5 pilot = 91 skills × ~30-50L c/u ≈ 2700-3600L ≈ **8 clusters de ~11-12 skills (~330-400L c/u)**. A ~1 cluster/sesión parcial + overhead de review, el barrido total ≈ 4-5 sesiones > presupuesto R5. **Partición explícita**: R5 = S1 (H1 + pilot) + S2 (C1, cluster de mayor leverage); C2-C8 + re-sync índice → **Ronda 6** (§8). `confidence: medium` en líneas/skill (calibrar con el pilot S1 antes de congelar R6).

## 3. Slice Plan (1 slice = 1 conventional commit ≤400L, verificación en mismo commit)

Orden mandatorio: **S1 (framework + pilot) → S2 (C1 quality/coordinación)**. Framework primero porque congela la checklist que los clusters ejecutan; C1 primero porque quality/coordinación gobiernan reviews y orquestación (mayor leverage si R6 se retrasa).

- **R5-S1 — `feat(skills): audit framework + checklist + pilot 5 skills (P1-1/R2-1 H1)`** (H1 · SUBSTANTIAL)
  Scope: `docs/skills/audit-checklist.md` (checklist congelada: A. spec Anthropic — frontmatter `name`/`description`/triggers, estructura SKILL.md + references/assets, discoverability; B. addyosmani — anti-rationalization table, red flags, verification steps; C. reglas locales — `token_budget`, changelog, no-bloat post-Ciclo-4) + `scripts/skills-audit-check.ps1` (nuevo, solo lectura: valida frontmatter + presencia de las 3 secciones addyosmani + reporta gap por skill; si aplica — si el pilot demuestra que basta checklist manual, el script se reduce a stub documentado) + test compañero (`skills-audit-check.Tests.ps1`: fixture PASS/FAIL por cada regla) + pilot 5 skills llevadas a conforme: `context-watchdog` (shape runtime-touching; frontmatter actual `:1-6` como baseline), `code-review-agent` (shape judge 4R), `security-scanner` (shape security), `delivery-harness` (shape coordinación), `sdd-quick` (shape SDD fast-path). Est. ~250-350L (≤400L ✅). `confidence: medium`.
  Outcome: checklist congelada + script verde en pilot + 5 skills conformes; el pilot calibra el costo/skill real para congelar R6.
- **R5-S2 — `feat(skills): audit cluster C1 quality-coordination (11 skills)`** (H2/C1 · SUBSTANTIAL)
  Scope: barrido con checklist S1 congelada sobre C1 = Quality resto + Coordinación resto (11 skills: `quality-gate, triple-verify, auto-metrics, external-auditor, immune-system, testing-strategy, rdd, branch-pr, issue-creation, command-wrapper, odd`; `code-review-agent` y `delivery-harness` ya conformes en S1, se excluyen). Solo `.agents/skills/*/SKILL.md` (+ `references/` si la skill ya lo usa; NO crear assets nuevos salvo que la checklist lo exija). Est. ~330-400L (11 × ~30L ✅). `confidence: medium`.
  Outcome: cluster de mayor leverage conforme; script S1 corre verde sobre 16/96 skills (pilot + C1).
- Total Ronda 5: 2 slices, cada uno ≤400L ✅, ~2 sesiones (S1 ~1 + S2 ~1) ✅.

## 4. RDD Freeze (re-capturado EN ESTA RAMA, antes de cualquier cambio futuro)

- **Freeze string:** `HEAD-85b75f71-e69de29b`
- **Captura (solo lectura — no commit/push/stash/checkout):**
  - `git branch --show-current` → `experimento/mejora-ronda5-skills-audit` ✅ (fail-closed pasado: es la rama exigida)
  - `git rev-parse HEAD` → `85b75f719192d33edea2abb9feb731ea7138d2d3` | `--short` → `85b75f71` (= cierre R4 rebaseado ✅)
  - `git rev-parse origin/main` → `a7458bff0c61d81f6f71727eb3fc65bffbede578` | `--short` → `a7458bff` (base del rebase ✅)
  - `git rev-parse main` → `6770702545ef6c39b8fe22ecbec3259033bc65db` | `--short` → `67707025` (intacto ✅, solo lectura — ningún comando de escritura lo tocó)
  - `git status --porcelain` → vacío (0 líneas, clean tree) | `git diff HEAD --stat` → vacío
  - `git diff HEAD | git hash-object --stdin` → `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391` (árbol vacío = limpio) → diff8 `e69de29b`
- **Tier por slice + review plan:**
  - R5-S1 (framework + script + pilot) → **Tier 2** — el script nuevo vive en `scripts/` y su wiring futuro a gate/CI es presunción no refutada (si S1 solo entrega checklist + script standalone sin wiring, el reviewer puede degradar a Tier 1 con justificación; por defecto Tier 2); 4R (`code-review-agent`) BLOCKER-capable (script solo-lectura real: ningún write fuera del report; pilot no introduce placeholders — anti-rationalization y verification steps reales por skill); FAIL → `judgment-day`, nunca auto-fix.
  - R5-S2 (cluster C1 skill-only) → **Tier 1** — solo `.agents/skills/*/SKILL.md` (+ `references/` existentes), sin schema/auth/API/runtime/CI; 4R estándar (cada skill: tabla anti-rationalization real, red flags accionables, verification steps ejecutables; SKILLS-INDEX.md NO tocado en R5); FAIL → iterar contenido, nunca auto-fix. **Excepción fail-closed**: si durante S2 una skill exige tocar `scripts/` o CI → extraer ese cambio a sub-slice Tier 2 separado, NO mezclar en el commit Tier 1.
  - Re-freeze + re-review si el freeze queda stale antes de ejecutar un slice.
- **Verify por slice (base R4 vigente + skills checks):** MCP **22/22** PASS + generate-config **16/16** PASS + jd-verifier **28/28** PASS + lcm-dag **13/13** PASS (medido en esta rama: `scripts/tests/lcm-dag.Tests.ps1` = 13 Its — reconcilia `ronda4-lcm-resto.md:111` "6/6" pre-R4 + 7 tests S1-S3) + lcm-measure 6/6 informativo + gate suites sin regresión + PSSA sin warnings/errors + cross-ref-check + skill-frontmatter **10/10** (medido `tests/skill-frontmatter.Tests.ps1` = 10 Its) + skill-validate **2/2** (medido `scripts/tests/skill-validate.Tests.ps1` = 2 Its) + skillspector-gate.
  - S1 además: `skills-audit-check.Tests.ps1` PASS (fixture por regla: frontmatter ausente → FAIL; sin anti-rationalization → FAIL; sin red flags → FAIL; sin verification → FAIL; skill conforme → PASS) + script verde sobre las 5 pilot + suites frontmatter/validate sin regresión.
  - S2 además: script verde sobre 16/96 (pilot + C1) + cross-ref-check ALL PASSED (ningún link `skills/{name}` roto por los edits) + `mejoras-index-check` si aplica.
  - Conteos MCP/generate/jd/gate se re-confirman en ejecución (cifras base de R4 `ronda4-lcm-resto.md:110-117`; `confidence: high` en lcm-dag 13/frontmatter 10/validate 2 medidos aquí, `medium` en el resto hasta re-correr).

## 5. Receipt templates (preparadas, NO emitir aún)

```json
{
  "receipt_id": "rdd-receipt-ronda5-s<N>",
  "freeze": "HEAD-85b75f71-e69de29b",
  "tier": "<1|2>",
  "slice": "<N> — <scope>",
  "files": ["<paths>"],
  "review": { "type": "4R", "verdict": "<PASS|WARN|FAIL|BLOCKER>", "escalation": "<none|judgment-day>" },
  "verify": { "pester_mcp": "22/22", "generate": "16/16", "jd_verifier": "28/28", "lcm_dag": "13/13", "gate": "ALL CLEAR", "pssa": "clean", "cross_ref": "ALL PASSED", "frontmatter": "10/10", "skill_validate": "2/2", "audit_check": "<S1: PASS 5/5 pilot | S2: PASS 16/96>" }
}
```

## 6. Review Log (vacío — Fase 1)

| Slice | Commit | 4R veredicto | Gate | Estado |
|-------|--------|--------------|------|--------|
| S1 (H1 framework + pilot 5) | `2d86c794` feat(skills): audit framework + checklist + pilot 5 skills (Ronda5 S1) | 4R PASS (JD 9/8/9/8, [10/26] OK) | Gate **28/28 ALL CLEAR** (hook pre-commit; [23/26] PS-CI-03 resuelto via marker) | ✅ commit A: 10 files +397/−11; costo/skill pilot 0–10L (delivery-harness 0L ya conforme; context-watchdog +4; code-review-agent ±4; security-scanner ±2; sdd-quick ±5); Pester audit-check 12/12; checklist congelada `docs/skills/audit-checklist.md` (34L); script 178L + test 145L; breaker marker new-format `scripts_tests_skills-audit-check.Tests.ps1_bb6407ba` |
| S2 (H2/C1 11 skills) | (este commit) feat(skills): audit cluster C1 quality-coordination (Ronda5 S2) | 4R PASS (B1 copy-paste humano: 4 tablas skill-specific reales) | Gate **28/28 ALL CLEAR** (sin marker; [25/26] token-regression exigió budget rdd 2850→3900) | ✅ 4 files +24/−2 (branch-pr +4 B3; testing-strategy +4 B2; rdd +15 B1/B2/B3 + budget; odd ±1 B1 heading); 7/11 ya conformes 0L; audit 16/16 (pilot 5 + C1 11) + repo 70/96 |

## 7. Rollback por slice

Cada slice commitea independiente en ESTA rama (nunca main): `git revert <slice-N>` sin tocar el otro slice ni `85b75f71`. Si un slice invalida el freeze del pendiente → re-freeze (§4) antes de continuar. Si S1 calibra costo/skill fuera de ~30-50L → re-slicear C1-C8 antes de S2 (no forzar 400L). Prohibido: merge a main sin orden explícita (`mejora-log.md:356`); prohibido: tocar main incluso para "verificar" (solo lectura `rev-parse`/`log`, nunca checkout).

## 8. Para Ronda 6 (explícito, NO parte de esta ronda)

- **H3-H9 = barrido C2-C8 (~80 skills, 7 slices Tier 1, cada uno ≤400L)**: C2 familia SDD resto (~11: `sdd, sdd-propose, sdd-design, sdd-apply, sdd-verify, sdd-archive, sdd-explore, sdd-init, sdd-spec, sdd-tasks, …` menos `sdd-quick` ya pilot); C3 Security+Testing (~12); C4 Memory+Analysis+Engineering (~12); C5 UI/Docs+Communication (~12); C6 Skills-meta+Specialized incl. `skill-improver, skill-testing, karpathy-loop, recovery-protocol, trial-verify` (~12); C7 restante A (~11); C8 restante B (~10) + re-sync `SKILLS-INDEX.md` (grupos + conteo; el índice de conteo está bien — §1 — lo stale son los grupos). Composición exacta de C2-C8 se congela en R6 con el costo/skill calibrado del pilot S1; lo de arriba es partición provisional.
- **I — cola v3 no tocada** (`research-plan.md:228-232`): R2-5 initializer-agent, R2-2 listings, P1-2/P1-3, R2-3/R2-6/P2-*. Ningún adelanto justificado: R5 satura ~2 sesiones con S1+S2.
- **Recalibración vs estimado original**: `research-plan.md:227` estima P1-1+R2-1 en 2-4 sesiones para 93 skills; con 96 skills y triple requisito addyosmani (~30-50L/skill) el total real ≈ 9-10 slices ≈ 4-5 sesiones → R5 (2) + R6 (2-3). El Gate R6 decide si comprime (bajar a ~20L/skill con plantillas) o acepta el costo.
