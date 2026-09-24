# Ronda 11 - Cierre de deuda técnica detectada en R10 (ODD Gate + Slice Plan + RDD Freeze) (Fase 1: análisis, SIN código)

> Fase 1 - análisis y freeze. NO código, NO commit, NO push, NO merge, NO tocar main.
> Rama: `experimento/mejora-ronda11-deuda` @ HEAD `7297bccb` (= tip R10, linaje ronda8→ronda9→ronda10→ronda11, ramas apiladas) - main intacto (solo lectura).
> Este archivo (`odd/tasks/ronda11-deuda.md`) es el ÚNICO write permitido de la fase. La ejecución lo commitea después (1 commit por slice + receipts).
> Precedente de formato OBLIGATORIO: `odd/tasks/ronda10-recursos.md` (238L): inventario medido + gate Q&A + ODD gate por slice + slice plan + freeze/tiers + verify + receipt templates + review log + rollback + resto a futuro. Este documento lo imita en estructura y rigor.
> Alcance R11: S1–S5 abajo. El owner-paste de `prompts/shared/_permission-templates.md` (item 6 R10§9) NO es slice: solo se referencia (§9.6).

## 0. Inventario medido (evidencia real, `confidence` por claim; lo ya medido en R10 se verifica, no se reinventa)

| # | Item (fuente R10§9) | Estado medido HOY | Evidencia |
|---|---|---|---|
| D1 | laguna-high outlier (item 1/S5) | VIGENTE: `laguna-s-2.1-free` variant `high` = 75 sess × 168,128,206 in (~2.24M/sess), cache_read 1.06B | `dbcheck3.py` sobre `C:/Users/MK/.local/share/opencode/opencode.db` (read-only URI), `confidence: high` |
| D1b | Totales DB facturación | 1,240 sess, 418.1M in / 17.4M out (24:1), cache_read 3.08B, $5.23 (R10: 1,234 / 417M / 17.3M / 3.06B / $5.11 — sigue creciendo) | mismo query, `confidence: high` |
| D1c | Atribución ruta/skill del outlier | NO atribuible con schema actual: `session` no tiene columna skill/ruta; TOP5 in muestra sesiones largas legítimas (8.8M deepseek "sushi", 8.4M laguna "Estado conversación", 8.2M laguna "New session") | `dbcheck2.py` (cols session/part/message) + TOP5, `confidence: low` en atribución / `high` en que el schema no la soporta |
| D2 | Tamaño opencode.db (item 2/S6) | 5.24GB + WAL 29MB, `journal_mode=wal`, `freelist=0` (nada reclaimable sin VACUUM) | `ls` + `pragma page_count=1374350/freelist/journal`, `confidence: high` |
| D2b | Qué lo infla | `event` 698,381 + `part` 182,507 + `message` 42,204 + `session` 1,240 (parts+events dominan; compactions no es tabla, es conteo histórico R10: 104) | `dbcheck.py` counts, `confidence: medium-high` |
| D2c | Retención/VACUUM opencode | Sin retention config de opencode (grep `retention\|VACUUM\|archive.*session` en `scripts/` solo pega en `engram-compact.ps1`, otra DB); VACUUM opencode sin precedente = destructivo sin backup | grep, `confidence: high` en ausencia / `medium` en riesgo |
| D3 | snapshot/compaction (item 3) | `scripts/lib/opencode-base.json:207-214` = `{auto:true,prune:true,reserved:4000,keep:{tokens:8000}}` CERRADO; `snapshot` AUSENTE; `compaction.buffer` AUSENTE | Read directo, `confidence: high` |
| D3b | `compaction.buffer` doc v1 | No verificado contra doc remota en Fase 1; default NO-OP (determinismo/receipts mandan) | sin evidencia remota, `confidence: medium` en "no tocar" |
| D4 | lockfile (item 4) | CORRIGE R10: `package-lock.json` SÍ existe (53,816B, trackeado, log `5dd8e430/e3ac9a87/dec3b6a7`) | `git ls-files` + bytes, `confidence: high` |
| D4b | `npm audit` en gate | CORRIGE parcial R10: SÍ existe pero ADVISORY (`.github/workflows/quality-gate.yml:39-46`, `continue-on-error:true`, warn-only; blocking = "future ADR") | Read, `confidence: high` |
| D4c | `--no-verify` / devDeps | 3 devDeps (`package.json:33-37`); `--no-verify` bypassa 21 checks = política, no slice técnico (cita R10, no recontado) | Read + R10, `confidence: high` devDeps / `medium` 21 checks |
| D7 | Paridad gate (item 7) | VIGENTE: `shared-deny-rules.json` = 83 reglas, `ftp *`/`scp *`/`rsync *`/`git clone *` AUSENTES; runtime `opencode-base.json:18,40,77,80` SÍ los tiene (`ask`/`deny`) | `python json.load` check, `confidence: high` |
| D7b | Test gate | `tests/permission-rules-consistency.Tests.ps1:40-46` solo exige curl/wget/ssh → agregar reglas NO rompe el test | Read, `confidence: high` |
| B0 | Baseline riesgo | Score 10.0 (cycle39) no debe bajar; todo cambio config va al SSoT `scripts/lib/opencode-base.json` + `scripts/regenerate-opencode.ps1 -Yes` (NO editar `opencode.json` directo — es generado; `regenerate` existe: `Test-Path True`) | regla R10 + verificación, `confidence: high` en regla |

## 1. Gate: 3 preguntas respondidas

### Q1. ¿Qué oportunidades de mayor ratio ganancia/riesgo (orden = orden de slices)?

| Rank | Oportunidad | Ganancia | Riesgo | Ratio |
|---|---|---|---|---|
| 1 | S1 paridad gate (+`ftp *`/`scp *`/`rsync *` deny, `git clone *` ask al SSoT del gate) | Cierra drift gate-vs-runtime; 0 cambio runtime | Casi 0 (test no lo exige; mecanismos distintos, no urgente) | Muy alto |
| 2 | S2 supply chain (pinear `^` + verificar lockfile; audit ya advisory) | Reproducibilidad real (lockfile existe pero `^1.63.0` deriva) | Bajo (solo devDeps; pin puede fijar vuln transitiva → auditar) | Alto |
| 3 | S3 snapshot/compaction: NO-OP documentado + test invariante | Determinismo/receipts intactos; cierra item sin riesgo | ~0 (no toca runtime) | Alto (por no hacer) |
| 4 | S4 cap/routeo laguna-high: política (alerta + guía small_model), SIN enforcement | Visibilidad del 40% del gasto in (168M/418M) sin romper sesiones largas legítimas | Medio (cualquier cap rompe casos legítimos TOP5) → OWNER facturación | Medio-alto con aprobación |
| 5 | S5 higiene db (script backup+retención+VACUUM + runbook, SIN ejecutar) | Script listo para ventana de mantenimiento; 0 bytes reclamables hoy (freelist 0) | Alto si se ejecuta (destructivo) → script merged, ejecución OWNER Tier 3 | Medio (solo como script) |

### Q2. ¿Qué es config-level (sin código) vs código?

- **Config-level SSoT (base.json + regenerate — OWNER si toca runtime compartido):** S3 (decisión: no tocar), S4 (si exige routeo/small_model), S5 (retención = política destructiva).
- **Código/scripts/docs (autónomo dentro de su scope):** S1 (solo `scripts/opencode-config/shared-deny-rules.json` + Its nuevas), S2 (`package.json` pin + doc; audit blocking queda como ADR futuro, no en el slice), S3 (test invariante), S5 (script + runbook, ejecución excluida).
- **Regla:** `opencode.json`/`prompts/**`/db destructivo/facturación = OWNER-DECISION (§4). SSoT del gate y `package.json` dev-only = autónomo.

### Q3. ¿Cómo evitar degradar seguridad o determinismo (receipts/gates)?

- **Baseline 10.0 no baja:** cada slice re-corre `tests/permission-rules-consistency.Tests.ps1` donde aplique + `security-audit-mcp.ps1`; si baja → FAIL + rollback + STOP.
- **Determinismo:** `Test-Json` tras cada edit JSON; `git diff` acotado al scope; sin `--no-verify`; receipts 016+ con freeze `HEAD-<base7>-<diff8>`.
- **Receipt honesto:** atribución skill/ruta (D1c) y facturación futura se declaran `pendiente`/`n/a`, nunca PASS maquillado.

## 2. ODD Gate por slice (1 slice = 1 conventional commit ≤400L)

| Criterio (`odd`) | Umbral SMALL | R11-S1 paridad gate (Tier 1) | R11-S2 supply chain (Tier 1) | R11-S3 compaction NO-OP (Tier 1) | R11-S4 cap laguna (Tier 2 OWNER) | R11-S5 higiene db script (Tier 3 OWNER) |
|---|---|---|---|---|---|---|
| Líneas est. | ≤50L | ~10-25L → PASS | ~15-30L → PASS | ~20-40L → PASS | ~60-120L → FAIL | ~40-90L → FAIL borde |
| Files | 1 (+ test) | 1-2 (gate json + test ext) → FAIL borde | 1-2 (package.json + nota) → FAIL borde | 1-2 (test + nota) → FAIL borde | 2-3 (docs + policy + test) → FAIL | 2-3 (script + test + runbook) → FAIL |
| Schema/auth/API | None | Gate SSoT (no runtime) → PASS | DevDeps pin → PASS | Invariante solo lectura → PASS | Facturación/política → FAIL | Destructivo potencial → FAIL |
| Deps externas | None | None → PASS | npm registry (audit read-only) → PASS | None → PASS | None → PASS | sqlite3 local → PASS |
| **Veredicto** | - | **SUBSTANTIAL → Tier 1 AUTÓNOMO** | **SUBSTANTIAL → Tier 1 AUTÓNOMO** | **SUBSTANTIAL → Tier 1 AUTÓNOMO** | **SUBSTANTIAL → Tier 2 OWNER** | **SUBSTANTIAL → Tier 3 OWNER** |

- **Orden mandatorio: S1 → S2 → S3 → S4 → S5.** S1 primero (autónomo, riesgo ~0, cierra drift). S2 segundo (fija reproducibilidad antes de medir nada más). S3 tercero (congela invariante determinista antes de política de gasto). S4 cuarto (requiere S3 estable; owner facturación). S5 último (el único con potencial destructivo; script sin ejecución, ventana aparte).
- **R11 total: 5 slices, 5 commits, ~145-305L agregadas.** Ningún slice excede 400L.
- **OWNER vs autónomo:** S1+S2+S3 autónomos; S4+S5 OWNER-DECISION. Sin "sí" del owner → S4/S5 quedan en `SKIP` honesto.

## 3. Slice Plan (scope / est. lines / outcome / orden)

- **R11-S1 - `fix(security): paridad gate ftp/scp/rsync/clone`** (Tier 1, AUTÓNOMO) - PRIMERO
  Scope: `scripts/opencode-config/shared-deny-rules.json` (+4: `ftp *`/`scp *`/`rsync *`=deny, `git clone *`=ask) + Its en `tests/permission-rules-consistency.Tests.ps1` (paridad gate-vs-runtime). NO tocar runtime, NO tocar prompts. Est. ~10-25L, 1 commit. `confidence: high`.
  Outcome: gate=runtime en esos 4 patrones; Pester PASS (incl. :40-46 intacto).
- **R11-S2 - `chore(deps): pin exacto + lockfile verify`** (Tier 1, AUTÓNOMO) - SEGUNDO (requiere S1)
  Scope: `package.json:35` quitar `^` (`@playwright/test` → pin exacto) + nota ADR/bloqueo futuro del audit (advisory sigue; blocking = ADR, NO en el slice). NO tocar CI a blocking. Est. ~15-30L, 1 commit. `confidence: high`.
  Outcome: `npm ci` reproducible; `npm audit --audit-level=high` reportado (advisory, sin gate roto).
- **R11-S3 - `docs(config): compaction/snapshot NO-OP + invariante`** (Tier 1, AUTÓNOMO) - TERCERO (requiere S2)
  Scope: test que fija invariante (compaction cerrado `prune:true,reserved:4000,keep:8000`, `snapshot` ausente, sin `buffer`) + nota en docs. NO tocar `base.json`. Est. ~20-40L, 1 commit. `confidence: medium-high`.
  Outcome: cambio futuro de compaction exige romper el test a propósito (determinismo protegido).
- **R11-S4 - `policy(cost): cap/routeo laguna-high sin enforcement`** (Tier 2, OWNER facturación) - CUARTO (requiere S3)
  Scope: política (umbral alerta/sesión + guía routeo a `small_model` ya definido en `base.json:3`) + doc de por qué NO hay cap duro (TOP5 legítimo, D1c `low`). Si el owner aprueba routeo → vía SSoT + regenerate. Est. ~60-120L, 1 commit. `confidence: medium`.
  Outcome: visibilidad del outlier sin romper sesiones largas; enforcement diferido con diseño.
- **R11-S5 - `feat(db): script higiene opencode.db SIN ejecutar`** (Tier 3, OWNER destructivo) - QUINTO (requiere S4)
  Scope: script backup+`VACUUM`/retención por edad + runbook + test en DB copia (nunca el original). La EJECUCIÓN queda fuera del slice (ventana owner). Est. ~40-90L, 1 commit. `confidence: medium`.
  Outcome: script mergeado y testeado en copia; `freelist=0` documenta que hoy no hay ganancia gratis.

## 4. Freeze EN ESTA RAMA + Tier + review plan + OWNER-DECISIONS

- **Freeze point:** rama `experimento/mejora-ronda11-deuda` @ HEAD `7297bccb` (= tip R10). Cada slice congela `git rev-parse HEAD` + `git diff | git hash-object --stdin` en su receipt (precedente `.rdd/rdd-receipt-007.json`). `main` nunca se toca.
- **OWNER-DECISIONS:** S4 (política facturación; routeo/small_model vía SSoT+regenerate), S5 (retención/ejecución VACUUM; backup + ventana). Sin "sí" → `SKIP` honesto, no se aplican.
- **Autónomo:** S1, S2, S3 (scopes §3; S1 toca SSoT del gate pero NO runtime — por eso es Tier 1).
- **Tiers y review (RDD rule 4):** S1/S2/S3 Tier 1: `code-review-agent` 4R simple, sin auto-fix en FAIL (max 2 intentos; al 3ro STOP). S4 Tier 2: 4R BLOCKER-capable + `judgment-day` en FAIL. S5 Tier 3: igual que Tier 2 + ejecución PROHIBIDA en el slice (solo en copia) + backup verificado antes de cualquier run futuro.
- **Write-scope por slice:** solo paths §3 + receipt `.rdd/rdd-receipt-01{6,7,8,9}.json` y `.rdd/rdd-receipt-020.json`. Fuera de scope → STOP + nuevo slice.

## 5. Verify por slice (comandos esperados, mismo commit)

- **S1:** `Invoke-Pester tests/permission-rules-consistency.Tests.ps1` (PASS, incluye Its nuevas ftp/scp/rsync/clone) + `Test-Json` del gate json. Esperado: 0 drift gate-vs-runtime en esos 4.
- **S2:** `npm ci --dry-run` o `npm ls` sin deriva + `npm audit --audit-level=high` (reporte, advisory) + `Test-Json package.json`. Esperado: pin exacto, lockfile en sync.
- **S3:** Pester invariante PASS + `Select-String 'compaction|snapshot' scripts/lib/opencode-base.json` (=207-214, sin buffer/snapshot). Esperado: invariante verde, runtime intacto.
- **S4:** doc política presente + `Select-String 'small_model' scripts/lib/opencode-base.json` (=`base.json:3`) + score seguridad ≥10.0. Esperado: alerta definida, 0 enforcement.
- **S5:** script `-WhatIf`/dry-run en COPIA + Pester del script PASS + `Test-Path` backup. Esperado: 0 toques a `opencode.db` real (timestamp intacto).

## 6. Receipt templates (se rellenan al ejecutar; numeración 016+)

```json
// .rdd/rdd-receipt-016.json (R11-S1, Tier 1 autónomo)
{"id":"rdd-receipt-016","freeze":"HEAD-<base7>-<diff8>","tier":1,"files":["scripts/opencode-config/shared-deny-rules.json","tests/permission-rules-consistency.Tests.ps1"],"verdict":"PASS|FAIL|SKIP","verdict_note":"Pester PASS + paridad ftp/scp/rsync/clone gate=runtime.","review":{"status":"<4R>","method":"code-review-agent 4R"},"next":["R11-S2"],"auto_fix":false}
```

```json
// .rdd/rdd-receipt-017.json (R11-S2, Tier 1 autónomo)
{"id":"rdd-receipt-017","freeze":"HEAD-<base7>-<diff8>","tier":1,"files":["package.json"],"verdict":"PASS|FAIL|SKIP","verdict_note":"Pin exacto + lockfile sync + audit advisory reportado. Blocking=ADR futuro, fuera.","review":{"status":"<4R>","method":"code-review-agent 4R"},"next":["R11-S3"],"auto_fix":false}
```

```json
// .rdd/rdd-receipt-018.json (R11-S3, Tier 1 autónomo)
{"id":"rdd-receipt-018","freeze":"HEAD-<base7>-<diff8>","tier":1,"files":["<test-invariante>"],"verdict":"PASS|FAIL|SKIP","verdict_note":"Invariante compaction cerrado/snapshot ausente verde; runtime intacto.","review":{"status":"<4R>","method":"code-review-agent 4R"},"next":["R11-S4 (OWNER)"],"auto_fix":false}
```

```json
// .rdd/rdd-receipt-019.json (R11-S4, Tier 2 OWNER)
{"id":"rdd-receipt-019","freeze":"HEAD-<base7>-<diff8>","tier":2,"files":["<policy-doc>"],"verdict":"PASS|FAIL|SKIP","verdict_note":"OWNER facturación <sí/no>. Sin approval => SKIP. 0 enforcement.","review":{"status":"<4R BLOCKER>","method":"code-review-agent 4R BLOCKER-capable"},"escalation":"judgment-day","next":["R11-S5 (OWNER)"],"auto_fix":false}
```

```json
// .rdd/rdd-receipt-020.json (R11-S5, Tier 3 OWNER)
{"id":"rdd-receipt-020","freeze":"HEAD-<base7>-<diff8>","tier":3,"files":["<script>","<runbook>"],"verdict":"PASS|FAIL|SKIP","verdict_note":"Script testeado en COPIA. Ejecución real FUERA del slice. Sin approval => SKIP.","review":{"status":"<4R BLOCKER>","method":"code-review-agent 4R BLOCKER-capable"},"escalation":"judgment-day","next":[],"auto_fix":false}
```

## 7. Review Log (vacío en Fase 1, se rellena al ejecutar)

| Slice | Reviewer/método | Veredicto | Fecha | Notas |
|---|---|---|---|---|
| R11-S1 | code-review-agent 4R simple (Tier 1) | PASS | 2026-09-24 | Pester 19/19 (17 previas intactas + 2 nuevas paridad); gate 83→87 reglas; Test-Json True |
| R11-S2 | code-review-agent 4R simple (Tier 1) | PASS | 2026-09-24 | Pin @playwright/test ^1.63.0→1.63.0 (=lockfile); npm ls sin deriva; audit advisory (fast-uri high transitivo, sin blocking); npm ci --dry-run up-to-date |
| R11-S3 | — | - | - | - |
| R11-S4 | — | - | - | (OWNER facturación pendiente) |
| R11-S5 | — | - | - | (OWNER destructivo pendiente; ejecución fuera) |

## 8. Rollback (por slice, orden inverso)

- S5: `git revert <commit-S5>`; si algún run tocó copia, borrar copia; el original nunca se toca (verificar timestamp `opencode.db`).
- S4: `git revert <commit-S4>` (solo docs/policy; si hubo routeo SSoT → revert en `base.json` + regenerate + `Test-Json`).
- S3: `git revert <commit-S3>` (test invariante fuera; runtime nunca cambió).
- S2: `git revert <commit-S2>` (reponer `^`; `npm ci` de nuevo).
- S1: `git revert <commit-S1>` (quitar 4 reglas del gate json; Pester vuelve a baseline).
- Nunca `git reset --hard` sobre trabajo ajeno; nunca tocar `main`; R8/R9/R10 no se tocan.

## 9. Resto a futuro / NO entra en R11 (explícito)

1. **Atribución skill/ruta del outlier (D1c `low`):** requiere minar `message`/`part.data` (42K/182K filas) — diseño R12+, no R11.
2. **Cap duro / enforcement:** descartado en R11 (TOP5 muestra sesiones legítimas de 8M; romper = peor que el gasto).
3. **`npm audit` blocking en CI:** ADR futuro (el gate lo declara: `quality-gate.yml:43`); R11 solo pin + advisory.
4. **`--no-verify` (21 checks):** política, no slice técnico; fuera.
5. **`compaction.buffer` / abrir compaction:** NO-OP en R11 (S3 lo congela); re-evaluar solo con datos S4/S5.
6. **Owner-paste `prompts/shared/_permission-templates.md:53-55` (R10§9.6):** NO es slice (runtime deniega `edit prompts/**` a agentes; drift DOCUMENTAL verificado, ningún test lo lee). Acción de owner: borrar esas 3 líneas (+ opcional alinear `ftp`/`scp`/`rsync`=deny, `git clone`=ask). Solo se referencia aquí.
7. **Ejecución VACUUM/retención real + `mcp_timeout` S2 + iGPU shared + chrome-devtools pin:** fuera (ventana owner / diferido R10-S2 / nota permanente / seguir pineado @1.6.0).

---
*Fase 1 completa: plan + freeze en `experimento/mejora-ronda11-deuda` @ `7297bccb`. Ejecución S1→S2→S3→S4→S5 en siguientes sesiones, 1 commit por slice, receipts 016-020. Sin commit en Fase 1.*
