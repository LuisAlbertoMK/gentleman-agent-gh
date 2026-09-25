# Ronda 4 — LCM resto (F-resto) — ODD Gate + Slice Plan + RDD Freeze (Fase 1: análisis, SIN código)

> Fase 1 — análisis y freeze. NO implementar código en esta fase. NO commit, NO push, NO checkout.
> Rama: `experimento/mejora-ronda4-lcm-resto` · cierre R3 = `1e071648` · main `67707025` intacto (solo lectura).
> Cola Ronda 4: G (F-resto LCM) en slices; H (P1-1 + R2-1) → decisión del Gate §1; resto cola v3 → Ronda 5+ (§7).
> Evidencia existente (no re-investigada):
> `odd/tasks/ronda3-judges72-strict-lcm.md` (cadena R1-R3 + Review Logs) · `docs/mejoras/mejora-log.md:356`
> (protocolo experimento/PR: "esperar orden explícita; no mergear") ·
> `docs/mejoras/2026-09-01-agent-improvement-research-plan.md:32-38` (P0-1) + `:58-64` (P1-1) +
> `:194-197` (R2-1) + `:222-232` (cola v3) · KB r2-* + Engram 847-858/961-985 (memoria, no web).

## 1. ODD Gate por ítem

Regla (precedente R3 §1): ALL criteria must pass para SMALL (≤50L, 1 file + test compañero,
sin schema/auth/API, sin deps externas, ≤2 commits); si alguno falla → SUBSTANTIAL (slice ≤400L).
G se parte en sub-slices a–d (ningún sub-slice supera 400L, pero el total excede 1 sesión → R4 = G entero en 3 slices, H → R5).

| Criterio (skill `odd`) | Umbral SMALL | G-a. Hook auto-escalation (entry real determinada) | G-b. GC ciclos viejos | G-c. Migración L1/L2/L3 al DAG | G-d. Medición compresión vs zones | H. P1-1 + R2-1 (primer slice útil?) |
|---|---|---|---|---|---|---|
| Líneas est. | ≤50L | ~60-100L ❌ | ~80-150L ❌ | ~150-250L ❌ | ~80-150L ❌ | Pilot ~200L+ / full 2-4 sesiones ❌❌ |
| Files | 1 (+ test) | 2 ❌ (`session-checkpoint.ps1` + tests) | 2 ❌ (`lcm-dag.ps1` + `lcm-dag.Tests.ps1`) | 3+ ❌ (dag + watchdog-check + SKILL.md + tests) | 2 ❌ (nuevo medida + tests) | 93 ❌ (`.agents/skills/*/SKILL.md`) |
| Schema/auth/API | None | None ✅ (wiring interno) pero toca P0 secrets guard ⚠️ | None ✅ (poda local) pero destructivo ⚠️ | None ✅ (resolvers file/engram/diff) | None ✅ | None ✅ (skill-only) |
| Deps externas | None | None ✅ | None ✅ | Engram IDs lectura ✅ (no dep runtime) | None ✅ | Anthropic spec + addyosmani lectura ✅ |
| Commits forecast | ≤2 | 1 ✅ | 1 ✅ | 1-2 ✅ | 1 ✅ | Full 3-6 ❌ → pilot 1 ❌ (desechable, ver veredicto) |
| **Veredicto** | — | **SUBSTANTIAL** → Slice 3 con G-d | **SUBSTANTIAL** → Slice 1 con parent-chain | **SUBSTANTIAL** → Slice 2 | **SUBSTANTIAL** → Slice 3 con G-a | **→ RONDA 5 ENTERO** (decisión explícita abajo) |

Evidencia por sub-slice (medición directa en HEAD `1e071648`, `confidence: high` salvo nota):

- **Entry real determinada por lectura** (cierra la duda del briefing "o entry real"):
  el seam es `scripts/context-watchdog-check.ps1` (75L) — dot-sourcea `lcm-dag.ps1` (`:33-34`),
  llama `Invoke-LcmEscalation` (`:37`) y `Add-LcmNode` (`:60`). Lo que falta es el wire INVERSO:
  `scripts/session-checkpoint.ps1` (450L) llama a `ctx-watchdog.ps1` (`:93`) pero NUNCA a
  `context-watchdog-check.ps1` ni a `lcm-dag`; su `.NOTES:16` lo confiesa
  ("Until that wiring lands, this script is the integration seam"). Además `session-checkpoint.ps1:118-125`
  duplica el switch de zonas en vez de delegar a `Invoke-LcmEscalation`. G-a = ese wire + delegación.
  `confidence: high` en el gap (líneas citadas); `medium` en el diseño del discriminador de doble-disparo
  (checkpoint YELLOW+ vs nodo DAG — evitar checkpoints duplicados).
- **G-b**: `scripts/lcm-dag.ps1:20` ("GC not yet") + schema `:21` ("GC: not yet → Ronda 4").
  `Add-LcmNode -ParentId` existe (`:79`) pero ningún caller lo pasa (grep: 0 callers con `-ParentId`) —
  la cadena parent→child nunca se forma; G-b incluye pasar `-ParentId` en `context-watchdog-check.ps1:60`
  (último nodo del ciclo como parent) junto con `Remove-LcmOldCycles`. `confidence: high`.
- **G-c**: `context-watchdog/SKILL.md:20,24` ya referencian `lcm-dag.ps1` (doc-contract), pero es solo
  contrato-doc: sin builders de contenido L1/L2 (hoy `watchdog-check.ps1:47-49` genera placeholder
  genérico `"watchdog escalation …"`), sin resolver kinds `engram`/`diff` del schema (`§2` define 3 kinds;
  solo `file` tiene regex de resolución en schema `:44`), y L3 default pointer (`:52`) es
  `.learnings/inter-track.json` sin `#sha256:` → cuenta como **unverified** por schema `:39-40`.
  G-c = builders + resolvers engram/diff + hash canónico en default pointer. `confidence: medium`.
- **G-d**: cero código de medición hoy (grep `compression|ratio` en `scripts/lcm-*.ps1` = 0 hits);
  P0-1 promete "elimina context rot (YELLOW>40%→RED>80%)" (`research-plan.md:37`) sin prueba numérica.
  G-d = `Measure-LcmCompression` (tokens pre/post por nivel vs zonas) + test con thresholds.
  `confidence: medium` en thresholds (diseño en ejecución).
- **H — decisión explícita del Gate**: P1-1 = 2 sesiones / 93 skills (`research-plan.md:63`);
  R2-1 = 2-3 sesiones / 93 skills (`:197`); combinados 2-4 sesiones (`cola v3 :227`).
  R4 ya satura ~2 sesiones con G (3 slices). Un "pilot" H (auditar 3-5 skills) sin el framework
  de audit completo sería trabajo desechable: el valor de P1-1 está en el barrido sistemático, no en
  el muestreo. **Veredicto: H VA ENTERO A RONDA 5** (con su propio Gate allí: probable slice H1 =
  framework de audit + pilot 5 skills, H2+ = barrido). Ningún adelanto trivial se justifica en R4.

## 2. Slice Plan (1 slice = 1 conventional commit ≤400L, tests/verificación en mismo commit)

Orden mandatorio: **Slice 1 (GC + parent-chain) → Slice 2 (migración/resolvers) → Slice 3 (hook + medición)**.
GC+chain primero porque cierra el loop funcional del DAG (nodos encadenados y podados antes de
inyectarles contenido real en S2); hook+medición después porque miden el sistema ya completo.

- **Slice 1 — `feat(lcm): DAG garbage-collects old cycles and chains parent nodes`** (G-b · SUBSTANTIAL)
  Scope: `Remove-LcmOldCycles` en `scripts/lcm-dag.ps1` (retención por ciclo `meta.cycle` de
  `inter-track.json`, best-effort si ausente — mismo patrón que `Initialize-LcmDag :52-55`) +
  `context-watchdog-check.ps1:60` pasa `-ParentId` (último nodo del ciclo). Tests: poda deja ciclo
  actual intacto; chain forma `edges[]` padre→hijo. Est. ~120-200L (≤400L ✅). `confidence: medium`.
  Outcome: DAG acotado y encadenado; sin esto S2 inyecta contenido en un DAG plano e impodable.
- **Slice 2 — `feat(lcm): L1/L2/L3 migration with lossless resolvers`** (G-c · SUBSTANTIAL)
  Scope: builders de contenido por nivel (L1 section summary, L2 decisions+Engram IDs, L1/L2/L3 vía
  `lcm-dag.ps1`) + resolvers kinds `engram`/`diff` del schema §2 + default L3 pointer con `#sha256:`
  canónico (`watchdog-check.ps1:50-53`) + `SKILL.md` Verification ya existe (contrato). Tests:
  resolver engram/diff round-trip; L3 default pointer verifica hash. Est. ~150-250L (≤400L ✅).
  `confidence: medium`.
  Outcome: migración funcional L1/L2/L3; P0-1 "mayor impacto" materializado salvo medición.
- **Slice 3 — `feat(lcm): session-checkpoint auto-escalates via watchdog + compression readout`** (G-a+G-d · SUBSTANTIAL)
  Scope: `session-checkpoint.ps1` llama a `context-watchdog-check.ps1` en thresholds YELLOW/ORANGE
  (reemplaza switch duplicado `:118-125` por delegación a `Invoke-LcmEscalation`, sin tocar
  `Redact-Secrets` ni pipeline mark/full) + `Measure-LcmCompression` (tokens pre/post por nivel vs
  zonas YELLOW>40%→RED>80%) + tests (no-doble-disparo checkpoint/DAG; readout con thresholds).
  Est. ~140-220L (≤400L ✅). `confidence: medium`.
  Outcome: loop cerrado checkpoint→DAG→medición; P0-1 verificable numéricamente → Ronda 5 decide si
  el número justifica más trabajo.

Total Ronda 4: 3 slices, cada uno ≤400L ✅, ~2 sesiones (S1 ~0.5 + S2 ~1 + S3 ~0.5-1) ✅.

## 3. RDD Freeze (re-capturado EN ESTA RAMA, antes de cualquier cambio futuro)

- **Freeze string:** `HEAD-1e071648-e69de29b`
- **Captura (solo lectura — no commit/push/stash/checkout):**
  - `git branch --show-current` → `experimento/mejora-ronda4-lcm-resto` ✅ (fail-closed pasado)
  - `git rev-parse HEAD` → `1e07164815b5e54674d2dc2e283bee45be84afc7` | `--short` → `1e071648` (= cierre R3 PASS global ✅)
  - `git rev-parse main` → `6770702545ef6c39b8fe22ecbec3259033bc65db` | `--short` → `67707025` (intacto ✅, solo lectura)
  - `git status --porcelain` → vacío (0 líneas, clean tree) | `git diff HEAD --stat` → vacío
  - `git diff HEAD | git hash-object --stdin` → `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391` (árbol vacío = limpio) → diff8 `e69de29b`
- **Tier por slice + review plan:**
  - Slice 1 (GC + chain) → **Tier 2** — `Remove-LcmOldCycles` es destructivo (borra `.learnings/lcm-dag.json`
    por ciclo; presunción irreversible no refutada); 4R (`code-review-agent`) BLOCKER-capable
    (retención fail-closed: ante `inter-track.json` ausente → NO borrar, mismo patrón `:52-55`);
    FAIL → `judgment-day`, nunca auto-fix.
  - Slice 2 (migración + resolvers) → **Tier 1** — skill/runtime sin schema/auth/API nuevos (kinds ya
    definidos en schema §2); 4R estándar (resolvers reales, no placeholders; L3 default con hash
    canónico, no bare); FAIL → iterar diseño, nunca auto-fix.
  - Slice 3 (hook + medición) → **Tier 2** — toca `session-checkpoint.ps1` (pipeline con P0 secrets guard
    `Redact-Secrets :64-84`; presunción auth-relevante no refutada) + riesgo de doble-disparo
    checkpoint/DAG; 4R BLOCKER-capable; FAIL → `judgment-day`, nunca auto-fix.
  - Re-freeze + re-review si el freeze queda stale antes de ejecutar un slice.
- **Verify por slice (base vigente R3):** Pester suite MCP **22/22** PASS + generate-config **16/16** PASS +
  jd-verifier **28/28** PASS + lcm-dag **6/6** PASS + gate **28/28** ALL CLEAR + PSSA sin warnings/errors.
  - Slice 1 además: test GC PASS (ciclo actual intacto; ciclo viejo podado; sin `inter-track.json` → no-op)
    + test chain PASS (`edges[]` padre→hijo) + suites 6/6 sin regresión.
  - Slice 2 además: resolvers engram/diff round-trip PASS + L3 default pointer hash-verified PASS +
    cross-ref-check ALL PASSED.
  - Slice 3 además: test no-doble-disparo PASS (1 checkpoint + 1 nodo por escalación) + readout con
    tokens pre/post por nivel + `--validate` sin regresión.

## 4. Receipt templates (preparadas, NO emitir aún)

```json
{
  "receipt_id": "rdd-receipt-ronda4-s<N>",
  "freeze": "HEAD-1e071648-e69de29b",
  "tier": "<1|2>",
  "slice": "<N> — <scope>",
  "files": ["<paths>"],
  "review": { "type": "4R", "verdict": "<PASS|WARN|FAIL|BLOCKER>", "escalation": "<none|judgment-day>" },
  "verify": { "pester_mcp": "22/22", "generate": "16/16", "jd_verifier": "28/28", "lcm_dag": "6/6", "gate": "28/28", "pssa": "clean" }
}
```

## 5. Review Log (vacío — Fase 1)

| Slice | Commit | 4R veredicto | Gate | Estado |
|-------|--------|--------------|------|--------|
| 1 (G-b GC + parent-chain) | `feat(lcm): DAG garbage-collects old cycles and chains parent nodes` (Ronda4 S1) — este commit | self-4R PASS sin BLOCKER (Tier 2: 4R independiente pendiente pre-merge a main; FAIL → `judgment-day`, nunca auto-fix) | gate ALL CLEAR regla exacta, sin FORCE_SHIP ni markers nuevos (verificado pre-commit) | ✅ implementado en esta rama, NO push |
| 2 (G-c migración/resolvers) | `feat(lcm): L1/L2/L3 migration with lossless resolvers` (Ronda4 S2) — este commit | self-4R PASS sin BLOCKER (Tier 1: sin schema/auth/API nuevos — kinds pre-definidos en schema §2; builders L1/L2 puros + `New-LcmL3Pointer` fail-closed + `Resolve-LcmPointer` 3 kinds no-throw con flag `resolvable`; default L3 canónico `file:…#sha256:…`; SKILL.md Verification NO tocado — el contrato ya lo exigía y S2 lo implementa bajo el mismo texto, justificación en commit) | gate regla exacta pre-commit sin FORCE_SHIP ni markers nuevos (verificado pre-commit) | ✅ implementado en esta rama, NO push |
| 3 (G-a+G-d hook+medición) | `feat(lcm): session-checkpoint auto-escalates via watchdog + compression readout` (Ronda4 S3) — este commit | self-4R PASS sin BLOCKER (Tier 2: hook delega switch :118-125 a Invoke-LcmEscalation con fallback legacy fail-closed; Redact-Secrets/mark/full intactos; anti-doble-disparo por discriminador session_id 1 checkpoint ↔ ≤1 nodo; thresholds L1≤0.35/L2≤0.60/L3≤0.15 documentados en medida; 4R independiente pendiente pre-merge a main; FAIL → `judgment-day`, nunca auto-fix) | gate regla exacta pre-commit sin FORCE_SHIP ni markers nuevos (verificado pre-commit) | ✅ implementado en esta rama, NO push |

## 6. Rollback por slice

Cada slice commitea independiente en ESTA rama (nunca main): `git revert <slice-N>` sin tocar los otros
slices ni `1e071648`. Si un slice invalida el freeze de otro pendiente → re-freeze (§3) antes de continuar.
Prohibido: merge a main sin orden explícita (`mejora-log.md:356`).

## 7. Para Ronda 5 (explícito, NO parte de esta ronda)

- **H entero**: P1-1 (Anthropic Agent Skills spec compliance audit, HIGH, 2 sesiones) + R2-1
  (estructura addyosmani, HIGH, 2-3 sesiones) — `research-plan.md:58-64 + :194-197 + :227`.
  Gate propio en R5 (probable H1 = framework de audit + pilot 5 skills; H2+ = barrido 93 skills).
- **I — cola v3 no tocada** (`research-plan.md:228-232`): R2-5 initializer-agent, R2-2 listings,
  P1-2/P1-3, R2-3/R2-6/P2-*. Ningún adelanto trivial justificado: R4 satura ~2 sesiones con G.
- **G se cierra en R4-S3** (DAG completo + medición); si la medición no muestra mejora vs
  YELLOW>40%→RED>80%, R5 decide (ajustar thresholds vs aceptar diseño) — no es resto oculto.
- R3 se cierra en `1e071648` (MCP 22/22 + generate 16/16 + jd 28/28 + lcm 6/6 + gate 28/28); no arrastra resto.
