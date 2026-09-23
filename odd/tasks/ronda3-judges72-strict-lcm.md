# Ronda 3 — Judges parte-2 + Strict + LCM — ODD Task Plan (Fase 1: análisis y freeze)

> Fase 1 — análisis y freeze. NO implementar código en esta fase. NO commit, NO push, NO checkout.
> Rama: `experimento/mejora-ronda3-judges72-strict-lcm` · cierre R2 = `99259f62` · main `67707025` intacto (solo lectura).
> Cola Ronda 3 (orden de ejecución E → D → F1; orden sugerido D/E/F reordenado por Gate: E es SMALL fail-closed y va primero).
> Evidencia existente (no re-investigada):
> `odd/tasks/ronda2-warn-ssot-judges.md` (cadena + Review Log R1/R2) · `docs/mejoras/mejora-log.md:356`
> (protocolo experimento/PR: "esperar orden explícita; no mergear") ·
> `docs/mejoras/2026-09-01-agent-improvement-research-plan.md:208-211` (R2-4) + `:32-38` (P0-1) + `:222-232` (cola v3).

## 1. ODD Gate por ítem

Regla: ALL criteria must pass para SMALL (directo, ≤50L/1 file + test compañero según precedente R2-A: diff 37L → SMALL); si alguno falla → SUBSTANTIAL (task plan).

| Criterio (skill `odd`) | Umbral SMALL | D. Judges parte-2 (Reflexion + constitutional + IRM) | E. Flag --strict S2 (ENOENT → FAIL) | F. P0-1 LCM DAG → context-watchdog |
|------------------------|--------------|------------------------------------------------------|--------------------------------------|-------------------------------------|
| Líneas est. | ≤50L | ~150-280L ❌ (3 patrones restantes + wiring + tests; R2-C1 consumió 142L para 3 patrones) | ~30-50L ✅ (~5L fix + ~20-40L tests, mismo orden que R2-A 37L) | Full ~600L+ / 2-3 sesiones ❌❌ → se slicea (F1 ~200-350L) |
| Files | 1 (+ test compañero) | 2-4 ❌ (SKILL.md + reference.md + jd-verifier/tests) | 1 + test ✅ (`generate-opencode-config.js` + su test; misma convención que R2-A) | 2+ ❌ (SKILL.md + references + scripts) |
| Schema/auth/API | None | None ✅ (skill-only, sin runtime; boundary ya documentado) | None ✅ (tightening fail-closed, sin superficie nueva) | None ✅ (skill-only en F1; sin runtime auth) |
| Deps externas | None | KB Engram 855 lectura ✅ (no dep runtime) | None ✅ | Paper arxiv 2605.04050 lectura ✅ (no dep runtime) |
| Commits forecast | ≤2 | 1 ✅ | 1 ✅ | Full 3-5 ❌ → F1 = 1 ✅ |
| **Veredicto** | — | **SUBSTANTIAL** → Slice 2 | **SMALL** → Slice 1 directo | **SUBSTANTIAL** → Slice 3 = solo F1 (diseño + primer componente); resto → Ronda 4 |

Evidencia por ítem (medición directa en HEAD `99259f62`, `confidence: high` salvo nota):

- **D**: `docs/skills/judgment-day/reference.md:311-313` — boundary R3 explícito dejado por implementer R2
  ("Pattern 4 Reflexion grounding beyond re-judge delta, Pattern 5 constitutional runtime revision loop,
  Pattern 6 IRM/reward-ranker wiring → resto exacto que R2 Slice C1 dejó fuera por diseño; R2 puso 3/6").
  Taxonomía filas 4-6 en `:178-199` (Reflexion solo con grounding externo; constitutional = generate→critique→revise;
  IRM = ranker over N samples, "not yet wired"). Fuente raíz `research-plan.md:208-211` (6 patrones zylos,
  esfuerzo R2-4 total 1-2 sesiones — R2 consumió ~1 sesión en 3/6, resto ~1 sesión). `confidence: medium` en estimación.
- **E**: `scripts/lib/generate-opencode-config.js:193-200` — catch ENOENT hace skip silencioso
  (`'No mcp-policy.json found, skipping MCP policy enforcement'`) mientras corrupt/wrong-$schema = fail-closed
  (`process.exit(1)`). Follow-up menor propuesto por Verify R2 (Finding 6): convertir skip en FAIL para repos reales
  (no fixture). NUNCA fix sobre el freeze R2 — slice nuevo propio. Scope: distinguir repo real vs fixture
  (marker/env/path — determinar en ejecución) + test que aserta FAIL en real y skip en fixture.
  `confidence: high` en el gap (líneas citadas); `medium` en el discriminador fixture-vs-real (diseño en ejecución).
- **F**: `research-plan.md:32-38` — P0-1 LCM (hierarchical summary DAG + lossless pointers, arxiv 2605.04050),
  esfuerzo 2-3 sesiones, `confidence: HIGH`, "mayor impacto" (cola v3 `:226`). Target actual
  `.agents/skills/context-watchdog/SKILL.md` (36L, medido en esta rama). Full excede el presupuesto R3
  (R3 ya lleva D ~1 sesión + E trivial) → **decisión explícita del Gate**: R3 = F1 (diseño DAG + schema de
  lossless pointers + primer componente cableado, ≤400L); implementación completa + migración L1/L2/L3 +
  medición → Ronda 4. No es omisión silenciosa: ver §7.

## 2. Slice Plan (1 slice = 1 conventional commit ≤400L, tests/verificación en mismo commit)

Orden mandatorio: **E primero** (SMALL fail-closed-ish, 1-línea-ish, desbloquea enforcement real del SSoT) → D → F1.

- **Slice 1 — `fix(config): generator fails closed on missing mcp-policy outside fixtures`** (E · SMALL)
  Scope: `scripts/lib/generate-opencode-config.js:193-196` — ENOENT → `process.exit(1)` salvo fixture detectado;
  tests: repo real sin policy → FAIL; fixture (predate-policy) → skip. Est. ~30-50L (≤50L ✅).
  Outcome: ningún repo real genera `opencode.json` sin enforcement MCP silenciosamente.
- **Slice 2 — `feat(skills): judgment-day adopts judge patterns part 2 (3/6 restantes)`** (D · SUBSTANTIAL)
  Scope: Reflexion grounding más allá de re-judge delta (citas obligatorias a tests/diff/retrieval) +
  constitutional runtime revision loop (generate→critique→revise) + IRM/reward-ranker wiring pre-push sobre
  `judgment-day/SKILL.md` (68L) + `docs/skills/judgment-day/reference.md` (taxonomía filas 4-6 `:178-199`) +
  extensión `jd-verifier`/tests. Est. ~150-280L (≤400L ✅). `confidence: medium`.
  Outcome: 6/6 patrones zylos operativos; R2-4 cerrado.
- **Slice 3 — `feat(skills): context-watchdog LCM DAG design + lossless pointer schema (part 1)`** (F1 · SUBSTANTIAL)
  Scope: diseño hierarchical summary DAG + schema de lossless pointers + primer componente cableado en
  `context-watchdog` (SKILL.md 36L + references). Est. ~200-350L (≤400L ✅). `confidence: medium`.
  Outcome: base diseñada y primer componente verificable; resto (implementación completa, migración L1/L2/L3,
  medición vs YELLOW>40%→RED>80%) → Ronda 4.

Total Ronda 3: 3 slices, cada uno ≤400L ✅, ~2 sesiones (S1 trivial + S2 ~1 + S3 ~1) ✅.

## 3. RDD Freeze (re-capturado EN ESTA RAMA, antes de cualquier cambio futuro)

> **Re-freeze R3-S2 (2026-09-23, implementer, solo lectura):** Slice 1 (E) movió HEAD `99259f62` →
> `2661fb2b`. Re-captura limpia al inicio del Slice 2: `HEAD-2661fb2b-e69de29b`
> (`git rev-parse HEAD` → `2661fb2b05da5ecf2f92207976222ea18ef99768`; `main` → `67707025` intacto;
> `git status --porcelain` vacío; `git diff HEAD | git hash-object --stdin` → `e69de29b`).

- **Freeze string:** `HEAD-99259f62-e69de29b`
- **Captura (solo lectura — no commit/push/stash/checkout):**
  - `git branch --show-current` → `experimento/mejora-ronda3-judges72-strict-lcm` ✅ (fail-closed pasado)
  - `git rev-parse HEAD` → `99259f62b040596d3de01a5bec6c9a08eccbdb6b` | `--short` → `99259f62` (= cierre R2 PASS global ✅)
  - `git rev-parse main` → `6770702545ef6c39b8fe22ecbec3259033bc65db` | `--short` → `67707025` (intacto ✅, solo lectura)
  - `git status --porcelain` → vacío (0 líneas, clean tree) | `git diff --stat HEAD` → vacío
  - `git diff HEAD | git hash-object --stdin` → `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391` (árbol vacío = limpio) → diff8 `e69de29b`
- **Tier por slice + review plan:**
  - Slice 1 (E) → **Tier 2** — mismo archivo/blast-radius que R2-B (el generator produce `opencode.json`;
    presunción auth-relevante MCP no refutada); 4R (`code-review-agent`) BLOCKER-capable; FAIL → `judgment-day`, nunca auto-fix.
  - Slice 2 (D) → **Tier 1** — skill-only, sin schema/auth/API ni runtime; 4R estándar (coherencia de patrones
    + grounding verificable en Reflexion + ranker cableado sin wire fantasma); FAIL → iterar diseño, nunca auto-fix.
  - Slice 3 (F1) → **Tier 1** — skill-only diseño + primer componente, sin schema/auth/API; 4R estándar
    (fidelidad al paper + pointers lossless reales, no placeholders); FAIL → iterar diseño, nunca auto-fix.
  - Re-freeze + re-review si el freeze queda stale antes de ejecutar un slice.
- **Verify por slice (base vigente R2):** Pester suite MCP **22/22** PASS + generate-config **14/14** PASS +
  jd-verifier **18/18** PASS + gate **28/28** ALL CLEAR + PSSA sin warnings/errors.
  - Slice 1 además: test fail-closed nuevo PASS (repo real sin policy → FAIL; fixture → skip) + `--validate` sin regresión.
  - Slice 2 además: 6/6 patrones con evidencia (grounding citado en Reflexion; loop revise medible;
    ranker pre-push ejecutado, no documentado-en-falso) + suites 22/22 + 18/18 sin regresión.
  - Slice 3 además: schema de pointers validado por test (round-trip lossless) + cross-ref-check ALL PASSED.

## 4. Receipt templates (preparadas, NO emitir aún)

```json
{
  "receipt_id": "rdd-receipt-ronda3-s<N>",
  "freeze": "HEAD-99259f62-e69de29b",
  "tier": "<1|2>",
  "slice": "<N> — <scope>",
  "files": ["<paths>"],
  "review": { "type": "4R", "verdict": "<PASS|WARN|FAIL|BLOCKER>", "escalation": "<none|judgment-day>" },
  "verify": { "pester_mcp": "22/22", "generate": "14/14", "jd_verifier": "18/18", "gate": "28/28", "pssa": "clean" }
}
```

## 5. Review Log (vacío — Fase 1)

| Slice | Commit | 4R veredicto | Gate | Estado |
|-------|--------|--------------|------|--------|
| 1 (E --strict) | fix(config): generator fails closed on missing mcp-policy outside fixtures (Ronda3 S1) — este commit | Tier 2 en Verify (implementer: discriminador `base.mcp`-presente; generate-config 16/16 — 14 previas + 2 nuevas R3S1; MCP 22/22 = audit-mcp 5/5 + mcp-resilience 4/4 + sync-all 11/11 + regenerate 2/2; jd-verifier 18/18; --validate VALID; PSSA 0 nuevos; diff ~40L ≤50L) | 28/28 ALL CLEAR (regla exacta; JD [10/28] Pass por markers pre-existentes, sin FORCE_SHIP ni markers nuevos) | ✅ implementado en esta rama, NO push |
| 2 (D judges 3/6 restantes) | feat(skills): judgment-day adopts judge patterns part 2 (Ronda3 S2) — este commit | Tier 1 en Verify (implementer: P4 grounding gate + P5 loop lines + P6 ranker argmax ejecutados live con transcript en reference.md; jd-verifier 28/28 — 18 previas + 10 nuevas R3S2; MCP 22/22 = audit-mcp 5/5 + mcp-resilience 4/4 + sync-all 11/11 + regenerate 2/2; generate-config 16/16; cross-ref-check ALL PASSED; diff 289+/17- ≤400L; boundary honesto: auto pre-push hook wiring = future, manual -Rank es el contrato) | gate 28/28 ALL CLEAR — [2/26] #requires + [25/26] token_budget 7000 justificado (precedente R2-S3; 7637 ≤ 7700); sin FORCE_SHIP ni markers nuevos) | ✅ implementado en esta rama, NO push |
| 3 (F1 LCM diseño + primer componente) | feat(skills): context-watchdog LCM DAG design + lossless pointer schema (Ronda3 S3) — este commit | Tier 1 en Verify (implementer: DAG ya en ancestry main parte 2/3+3/3 — gap F1 era schema formal + round-trip; schema `file:ref#sha256:hash` + kinds file/engram/diff + resolver contract en references/lcm-pointer-schema.md; round-trip Add→Get→resolve→hash match en lcm-dag.Tests.ps1 6/6 — 5 previas + 1 nueva R3S3; MCP 22/22; generate-config 16/16; jd-verifier 28/28; cross-ref-check ALL PASSED; diff ~112L ≤400L; R4: auto-escalation hook + GC + migración L1/L2/L3 + medición) | gate 28/28 ALL CLEAR (regla exacta; sin FORCE_SHIP ni markers nuevos) | ✅ implementado en esta rama, NO push |

## 6. Rollback por slice

Cada slice commitea independiente en ESTA rama (nunca main): `git revert <slice-N>` sin tocar los otros
slices ni `99259f62`. Si un slice invalida el freeze de otro pendiente → re-freeze (§3) antes de continuar.
Prohibido: merge a main sin orden explícita (`mejora-log.md:356`).

## 7. Para Ronda 4 (explícito, NO parte de esta ronda)

- **F-resto**: implementación completa LCM DAG + migración L1/L2/L3 + medición (context rot YELLOW>40%→RED>80%)
  + tests de compresión lossless. Estimación pendiente de lo que F1 revele; si excede 400L → partir de nuevo.
- Cola v3 no tocada (`research-plan.md:222-232`): P1-1 + R2-1 skills audit, R2-5 initializer-agent,
  R2-2 listings, P1-2/P1-3, R2-3/R2-6/P2-*.
- R2-4 se cierra en R3-S2 (6/6 patrones); no arrastra resto.
