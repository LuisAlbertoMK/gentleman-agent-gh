# Ronda 7 — Arranque SSoT + boot-budget — ODD Gate + Slice Plan + RDD Freeze (Fase 1: análisis, SIN código)

> Fase 1 — análisis y freeze. NO código, NO commit, NO push (deny), NO checkout, NO merge, NO tocar main.
> Rama: `experimento/mejora-ronda7-arranque` · HEAD `52fc0dd3` (cierre Refactor-AP PASS global) · main `54a53384` intacto (solo lectura).
> Restricción fundamental: `AGENTS.md` en **write-deny** de policy (precedente S4: owner-paste humano, 1 línea). `opencode.json` es **generado** (solo vía sync humano, no a mano).
> Este archivo (`odd/tasks/ronda7-arranque.md`) es el ÚNICO write permitido de la fase.

## 0. Baseline medido EN ESTA RAMA (re-verificado barato, `confidence: high`)

Medición (`wc -c`, esta rama, 2026-09-24):

| Archivo | Bytes medidos | Rol en arranque |
|---|---|---|
| `AGENTS.md` | 4987 | Repo protocol — auto-cargado al arrancar (medible local) |
| `opencode.json` | 23608 | Config generada — parseada al arrancar (medible local, NO editable a mano) |
| `SKILLS-INDEX.md` | 4870 | Índice de skills — referenciado desde AGENTS.md (`:17`), carga con la sesión (medible local) |
| `prompts/gentle-MK.md` | 2292 | Prompt del orquestador default (`defaultAgent: gentle-MK` en `projects.json:8-64`, `opencode.json` agent `gentle-MK`) — carga con el agente (medible local) |
| **Total arranque medido** | **35757** | Suma exacta re-verificada (`35757 total`) |
| **Esencial editable** (sin `opencode.json`) | **12149** (4987+4870+2292) | Lo que los agentes + humano pueden reducir |
| 109 `SKILL.md` (lazy, NO arranque) | 326174 total, frontmatters 109/109 suma 33750 chars | Dato heredado del brief — NO re-medido (fuera del arranque; solo contexto de coste lazy) |

Referencia upstream: `AGENTS.md` 2678B, sin `opencode.json` estático (generado). Objetivo del ataque: **~8KB de arranque esencial, resto lazy**.

Evidencia existente NO re-investigada (citada, no re-medida): plan `refactor-ap` (untracked heredado `odd/tasks/refactor-agentes-permisos-gentle-ai.md`, único `??` en `git status`), ADR-050, `docs/sdd/permissions.md`, skill `lean-context` (compresión), `context-watchdog`/LCM (mide YELLOW>40%), P0-1 cerrado.

## 1. Gate — las 3 preguntas (con evidencia y confidence)

### Q1. ¿Qué carga REALMENTE opencode al arrancar la sesión?

| Claim | Veredicto | Evidencia | Confidence |
|---|---|---|---|
| `AGENTS.md` del repo (4987B) se carga al arrancar | SÍ — medible local | Existe en disco, 4987B verificados; `PROTOCOL.md:3` ("Load this after reading AGENTS.md"); convención opencode AGENTS.md auto-load | **high** |
| Global `~/.config/opencode` (AGENTS.md global + `opencode.json` global con `gentle-orchestrator` bridge) se fusiona al arrancar | SÍ — inferido, no medible en este repo | `AGENTS.md:4-9` bridge ("vive en ~/.config/opencode/opencode.json, mode: primary … se resuelve desde la config global fusionada") | **medium** (ruta fuera del repo, tamaño no medido aquí) |
| `opencode.json` del repo (23608B) se parsea al arrancar | SÍ — medible local | Existe, 23608B verificados; `permission.bash.git push: deny` activo verificado en `opencode.json:1`; `tests/opencode-models.free-availability.Tests.ps1:56` cita regla `edit opencode.json deny` en AGENTS.md | **high** (carga) / **high** (generado, no editar a mano — precedente S4) |
| `SKILLS-INDEX.md` (4870B) + `prompts/gentle-MK.md` (2292B) cargan con la sesión | SÍ — medible local por referencia | `AGENTS.md:17` linka `SKILLS-INDEX.md`; `SKILLS-INDEX.md:53` registra 96 project + 99 global; `prompts/gentle-MK.md:1` rol Orquestador + `projects.json:8-64` `defaultAgent: gentle-MK` + `tests/orchestrator-hooks.Tests.ps1:35-53` fail-closed exige el prompt | **high** (referencia) / **medium** (bytes exactos en contexto del modelo — el harness puede truncar/resumir) |
| System prompts del modelo + skills bajo demanda (109 SKILL.md, 326174B) | Parcial — inferido | Los 109 SKILL.md están en disco pero el `Load Rule` (`SKILLS-INDEX.md:51-55`: `skill` tool → `read` directo → `references/`) es lazy por diseño; frontmatters (33750 chars) alimentan `build-skill-registry`/`skill-resolver-fast.ps1` (precedente `mejora-log.md:516`: descriptions ≤120B preservan routing; `cross-ref-check.ps1:89` parsea el índice) | **low-medium** (el contenido exacto del system prompt no es observable desde el repo) |
| `PROTOCOL.md`, `docs/`, `scripts/`, `tests/` | NO cargan al arranque (lazy) | Nada los referencia desde el arranque; `AGENTS.md:11-19` los lista como navegación bajo demanda | **medium** |

### Q2. ¿Qué palancas SSoT reducen el arranque sin perder capacidad?

1. **`AGENTS.md` → pointer + detalle en `docs/`** (SOLO owner-paste humano). Estructura actual (`AGENTS.md:1-85`: persona 54L + bridge + rules + personality + env + scripts) admite: conservar bridge + rules mínimas + punteros (`PROTOCOL.md`, `docs/ARCHITECTURE.md`, `docs/sdd/permissions.md`), mover persona/python-scripts a `docs/`. Precedente: upstream 2678B. `confidence: medium` (el número final lo fija el humano).
2. **`SKILLS-INDEX.md` compacto con carga bajo demanda.** Ya es "Compact" (`:1`) con Top-20 + Quick Groups (`:7-49`) + Load Rule (`:51-55`). Palanca: recortar changelog verbose (`:5`, una línea de ~800 chars con historial 4.6→5.9), podar grupos stales (precedente R6-S3), mantener formato parseable por `cross-ref-check.ps1:89` — **NO mergeable** (precedente `mejora-log.md:516`). `confidence: high` en restricción, `medium` en bytes.
3. **`prompts/gentle-MK.md` → pointer.** Actual 41L (2292B): hooks + routing + decomposition + write-scope + verification + return contract. Palanca: conservar rol (1L) + hooks numerados (4L) + routing/delegación en 5-8L, mover detalle a `docs/prompts/gentle-MK/reference.md` (ya referenciado en `:3`). `confidence: medium`.
4. **Test que fije el budget** (`tests/boot-budget.Tests.ps1`, nuevo, lo crean agentes): falla si esencial > N bytes. Es la palanca de no-regresión — sin test, cualquier recorte se revierte en 2 commits. `confidence: high`.
5. **NO palancas**: `opencode.json` a mano (generado — solo sync humano); reescribir 109 SKILL.md en R7 (es barrido R5/R6, fuera de scope); tocar `main`.

### Q3. Budget numérico propuesto y cómo se mide

| Archivo | Hoy (B) | Budget HARD (B) | Recorte |
|---|---|---|---|
| `AGENTS.md` (owner-paste humano) | 4987 | ≤ **2800** (≈ upstream 2678 + overhead de pointer) | −2187 (−44%) |
| `SKILLS-INDEX.md` (agentes) | 4870 | ≤ **3000** (trigger-only + grupos podados, formato parseable intacto) | −1870 (−38%) |
| `prompts/gentle-MK.md` (agentes) | 2292 | ≤ **1200** (rol + hooks + pointer a reference.md) | −1092 (−48%) |
| **Esencial** (suma 3 editables) | **12149** | **≤ 7000 target · ≤ 8192 FAIL** (8KB) | −5149 target (−42%) |
| `opencode.json` (generado, NO budget editable) | 23608 | INFO solo (se mide, no se gatea; cambia solo vía sync humano) | — |
| Total arranque (4 archivos) | 35757 | INFO ≤ ~32000 (derivada, no gate) | — |

**Cómo se mide** (S1 lo congela en código): `tests/boot-budget.Tests.ps1` — `(Get-Item $p).Length` por archivo + suma esencial; `It "esencial ≤ 8192B"` (FAIL si excede) + `It "cada archivo ≤ sub-budget"` (FAIL con nombre del violador) + `Write-Host` INFO del total con `opencode.json`. Sin dependencias externas, hermético (archivos temporales en `TestDrive` para fixtures PASS/FAIL), ≤80L.

## 2. ODD Gate por slice

Regla (precedente `ronda6-skills-barrido.md:39`): ALL criteria must pass para SMALL (≤50L, 1 file + test compañero, sin schema/auth/API, sin deps externas, ≤2 commits); si alguno falla → SUBSTANTIAL (1 slice = 1 commit ≤400L).

| Criterio (`odd`) | Umbral SMALL | S1 test budget + base | S2 reestructura SSoT | S3 owner-paste + verificación |
|---|---|---|---|---|
| Líneas est. | ≤50L | ~60-80L ❌ | ~200-300L ❌ | ~10-30L (agente verifica) ✅* |
| Files | 1 (+ test) | 1-2 ✅ (test nuevo + opt. docs nota) | 4-6 ❌ (índice + prompts + docs + scripts refs) | 1 ❌ (AGENTS.md, write-deny agente) |
| Schema/auth/API | None | None ✅ | None ✅ | None ✅ |
| Deps externas | None | None ✅ | None ✅ (`cross-ref-check.ps1:89` es gate interno, no dep externa) | None ✅ |
| Commits forecast | ≤2 | 1 ✅ | 1-2 ✅ | 1 (humano) + verify ✅ |
| **Veredicto** | — | **SUBSTANTIAL → R7-S1 (Tier 1)** | **SUBSTANTIAL → R7-S2 (Tier 2)** | **HUMAN → R7-S3 (Tier 1 doc-only, acto humano + verify agente)** |

- **Orden mandatorio: S1 → S2 → S3.** S1 fija el número antes de recortar (sin S1, S2/S3 no tienen contra-qué verificar). S3 último porque requiere el árbol ya recortado para el paste + medición final.
- **R7 total: 3 slices ≈ 1-2 sesiones.** Ningún slice excede 400L → **nada se deriva a R8 por capacidad**; R8 recibe solo endurecimiento futuro (§8).

## 3. Slice Plan (1 slice = 1 conventional commit ≤400L, verificación en mismo commit)

- **R7-S1 — `test(boot): boot-budget gate + medición base`** (Tier 1)
  Scope: crear `tests/boot-budget.Tests.ps1` (~60-80L: 3 Its — esencial ≤8192B, sub-budgets por archivo, fixtures TestDrive PASS/FAIL — + INFO total con `opencode.json`) + correr en esta rama (debe PASS con baseline 12149B > 8192B → **se espera FAIL inicial documentado**; el test fija el objetivo, no el estado actual — el commit registra el gate en rojo con `boot-baseline.md` o salida capturada). Sin tocar `AGENTS.md`/`SKILLS-INDEX.md`/`prompts/`. Est. ~60-80L. `confidence: high`.
  Outcome: número congelado en código; S2/S3 tienen gate automático.
- **R7-S2 — `docs(ssot): SKILLS-INDEX compacto + gentle-MK pointer + detalle en docs/`** (Tier 2)
  Scope (agentes, PROHIBIDO `AGENTS.md` y `opencode.json` a mano): `SKILLS-INDEX.md` 4870B→≤3000B (podar changelog `:5` a 1 línea + versión, grupos stales, preservar formato `cross-ref-check.ps1:89`); `prompts/gentle-MK.md` 2292B→≤1200B (pointer a `docs/prompts/gentle-MK/reference.md`, detalle movido a `docs/`); actualizar refs en `docs/` + `scripts/` que citen rutas movidas; re-correr `cross-ref-check.ps1` + `skill-resolver` spot-check (top-3 sin cambio, precedente `mejora-log.md:516`). Est. ~200-300L. `confidence: medium`.
  Outcome: esencial 12149B → ~7000-7500B sin S3 (el resto lo cierra el paste humano).
- **R7-S3 — `docs(boot): owner-paste AGENTS.md pointer + verificación final`** (Tier 1 doc-only, **acto humano**)
  Scope: humano pega `AGENTS.md` 4987B→≤2800B (plantilla en §7, preparada por agentes en S2 sin escribirla en el archivo); agente verifica: `boot-budget.Tests.ps1` PASS (esencial ≤8192B), `git diff --stat`, `cross-ref-check.ps1` PASS, medición final en este task file. Est. agente ~10-30L (verify + log). `confidence: medium` (bytes finales dependen del paste).
  Outcome: esencial ≤7000B target; arranque total ~30000B (con `opencode.json` generado intacto).

## 4. RDD Freeze (re-capturado EN ESTA RAMA, antes de cualquier cambio futuro)

- **Freeze string:** `HEAD-52fc0dd3-dirty1`
- **Captura (solo lectura — no commit/push/stash/checkout/merge):**
  - `git branch --show-current` → `experimento/mejora-ronda7-arranque` ✅ (fail-closed pasado: es la rama exigida)
  - `git rev-parse HEAD` → `52fc0dd37c4060a6c30f67eaa20c8d13bd107ed1` | short `52fc0dd3` (= cierre Refactor-AP PASS global ✅)
  - `git rev-parse main` → `54a5338481c249bb34cd0c2d05a7ffe00c4c0912` | short `54a53384` (intacto ✅, solo lectura — ningún write a main en esta fase)
  - `git status --porcelain=v1` → `?? odd/tasks/refactor-agentes-permisos-gentle-ai.md` (untracked heredado del plan refactor-ap, NO tocado) + este task file como nuevo untracked al escribirse
  - `wc -c` → `AGENTS.md 4987 · opencode.json 23608 · SKILLS-INDEX.md 4870 · prompts/gentle-MK.md 2292 · total 35757` ✅ (baseline §0)
  - `git log --oneline -1` → `52fc0dd3 fix(config): ConfigValidator expects 44 agents single-mode (Refactor-AP S5b)`

## 5. Tier por slice + review plan

- R7-S1 (test nuevo, sin tocar arranque) → **Tier 1** — 4R (`code-review-agent`) estándar; fixtures herméticas; FAIL → `judgment-day`, nunca auto-fix.
- R7-S2 (índice parseado por `cross-ref-check.ps1:89` + resolver scoring por descriptions) → **Tier 2** — toca superficie con wiring a gate/CI (presunción no refutada, como R5-S1/R6-S0); 4R BLOCKER-capable (formato índice intacto; top-3 resolver sin cambio; ningún write a `AGENTS.md`/`opencode.json` — `validate-write-scope.ps1` en post-delegación); FAIL → `judgment-day`.
- R7-S3 (paste humano en archivo write-deny) → **Tier 1 doc-only + acto humano** — agente SOLO verifica (lee + corre tests); si el paste excede budget o rompe refs → el humano re-pega, el agente no edita `AGENTS.md` bajo ningún concepto.

## 6. Verify por slice

- S1: `Invoke-Pester tests/boot-budget.Tests.ps1` (3 Its; se documenta FAIL-inicial-consciente con baseline 12149B) + `git status --porcelain` (solo test nuevo).
- S2: `boot-budget.Tests.ps1` (sub-budgets índice/prompts PASS, esencial aún >8192B sin S3 — esperado) + `scripts/cross-ref-check.ps1` PASS + resolver spot-check top-3 + `git diff --stat` (≤400L, 0L en `AGENTS.md`/`opencode.json`).
- S3: `boot-budget.Tests.ps1` ALL PASS (esencial ≤8192B) + `cross-ref-check.ps1` PASS + `orchestrator-hooks.Tests.ps1` (prompt fail-closed) PASS + medición final `wc -c` asentada en §4-bis del Review Log.

## 7. Receipt templates (copiar/pegar al ejecutar)

```text
[R7-S1 receipt] test(boot): boot-budget.Tests.ps1 creado (XL) · Its 3/3 (estado: FAIL-inicial documentado, baseline esencial 12149B>8192B) · files: tests/boot-budget.Tests.ps1 · verify: Invoke-Pester … · rollback: git revert <sha>
[R7-S2 receipt] docs(ssot): SKILLS-INDEX 4870→≤3000B + gentle-MK 2292→≤1200B · cross-ref-check PASS · resolver top-3 sin cambio · files: SKILLS-INDEX.md, prompts/gentle-MK.md, docs/… · AGENTS.md/opencode.json 0L ✅ · verify: … · rollback: git revert <sha>
[R7-S3 receipt] docs(boot): owner-paste AGENTS.md 4987→≤2800B (HUMANO) · boot-budget ALL PASS (esencial ≤8192B) · files: AGENTS.md (humano) · agente: verify-only · rollback: humano re-pega versión previa (sha <previo> en Review Log)
```

## 8. Review Log (vacío — lo llena la ejecución)

| Slice | Commit | Reviewer/Tier | Resultado | Fecha |
|---|---|---|---|---|
| S1 | f869d56b (gate 28/28) | Tier 1 (auto) | GREEN: boot-budget 7/7 ALL PASS (esencial 6758B≤8192B; AGENTS 2731≤2800 ✅, INDEX 2847≤3000 ✅, gentle-MK 1180≤1200 ✅); PSSA 0 errores (6 warnings no-bloqueantes: WriteHost-INFO + BeforeAll-scope + ShouldProcess); test 72L. Previo 2026-09-24: commit bloqueado 27/28 en rojo (baseline esencial 12149B>8192B, hook `[13/26] Pester` exit 1) — desbloqueado por paste S3 verificado | 2026-09-24 |
| S2 | 318e7aea (gate 5/5 ALL CLEAR, sin bypass) | Tier 2 (auto) | GREEN: esencial 12149→6758B (INDEX 4870→2847 ≤3000 ✅, gentle-MK 2292→1180 ≤1200 ✅, AGENTS.md 2731 paste-S3 verificado, 0L agente); cross-ref-check ALL PASSED (9/9 + semi SKIP); orchestrator-hooks 16/16; boot-budget 7/7; AGENTS.md/opencode.json 0L agente ✅ | 2026-09-24 |
| S3 (humano) | ESTE-COMMIT (paste humano verificado por agente) | Tier 1 doc-only + acto humano (agente verify-only, 0L edit en AGENTS.md) | GREEN: AGENTS.md 4987→2731B (≤2800 ✅); fidelidad OK (bridge+rules+Pre-Flight+Subagent-First+Default-FAIL+Skills+nav agent-context presentes; 7 headers movidos ausentes; gentleman-vMK 0, gentle-MK presente); esencial final 6758B (target ≤7000 ✅, FAIL ≤8192 ✅); boot-budget 7/7; cross-ref ALL PASSED; orchestrator-hooks 16/16; PSSA 0 errores | 2026-09-24 |

## 9. Rollback

- S1: `git revert <sha-S1>` (test aislado, sin dependientes).
- S2: `git revert <sha-S2>` + re-correr `cross-ref-check.ps1` (el índice es parseado — verificar que el revert restaura el parse).
- S3: el agente NO revierte `AGENTS.md`; el humano re-pega el contenido del `sha` anotado en Review Log (guardar `git show <sha>:AGENTS.md` antes del paste).
- Global: ningún slice toca `main`; `git checkout main -- <file>` PROHIBIDO como atajo (usar `revert` en la rama experimento).

## 10. Para Ronda 8 (NO parte de R7)

1. Endurecer budget: esencial 8192B→7000B HARD tras 2 semanas sin fricción + gate en CI (pre-push) del `boot-budget`.
2. `opencode.json` generado: estudiar `sync` que emittinga config mínima por modo (solo `gentle-MK` + permisos) — acto humano, fuera de R7.
3. Lazy-loading real de skills: `skill-graph`/resolver con budgets por skill (C3 ≤6144B ya existe en R6) + auditoría de frontmatters (33750 chars) como próxima superficie.
4. Medir global `~/.config/opencode` + system prompts (hoy `medium`/`low`) con harness instrumentado — convertir Q1-inferido en medido.

## 11. Actos humanos (todo lo que los agentes NO pueden tocar)

1. **Owner-paste `AGENTS.md`** (R7-S3): pegar versión pointer ≤2800B (1 acto, precedente S4). Agente prepara plantilla en `docs/` durante S2 pero NO la escribe en `AGENTS.md`.
2. **Sync `opencode.json`** (solo si aplica en S3): regenerar vía sync canónico si el pointer cambia referencias; NUNCA edición manual (policy `edit opencode.json deny`).
3. **Merge final**: solo humano decide merge a `main` tras Review Log completo + receipts R7-S1..S3.
