# Ronda 8 - Contratos formales + goldens de outputs - ODD Gate + Slice Plan + RDD Freeze (Fase 1: analisis, SIN codigo)

> Fase 1 - analisis y freeze. NO codigo, NO commit, NO push (deny), NO checkout, NO merge, NO tocar main.
> Rama: `experimento/mejora-ronda8-contratos` - HEAD `04d1c151` - main `54a53384` intacto (solo lectura).
> Este archivo (`odd/tasks/ronda8-contratos.md`) es el UNICO write permitido de la fase. Si existe parcial de intento cancelado, este documento lo completa/reescribe (artefacto propio de fase, no trabajo ajeno).

## 0. Inventario medido EN ESTA RAMA (fail-closed verificado, `confidence: high`)

| Item | Estado medido | Evidencia |
|---|---|---|
| Rama actual | `experimento/mejora-ronda8-contratos` | `git branch --show-current` |
| HEAD | `04d1c151937ae51c2e673959fb12d667162c4439` (prefijo `04d1c151` OK) | `git rev-parse HEAD` |
| main | `54a5338481c249bb34cd0c2d05a7ffe00c4c0912` (prefijo `54a53384` OK, solo lectura) | `git rev-parse main` |
| `odd/tasks/ronda8-contratos.md` | EXISTE parcial de intento cancelado (194L) -> ESTE documento lo completa/reescribe (unico write de la fase, artefacto propio) | `Read odd/tasks/ronda8-contratos.md` |
| `contracts/` | NO existe | `Test-Path` = False |
| `testdata/` | NO existe | `Test-Path` = False |
| `.rdd/rdd-receipt-001..004.json` | Existen, 4 receipts (3841/2539/3216/2831 B), SIN schema formal | `Get-ChildItem .rdd/rdd-receipt-*.json` |
| `scripts/lib/permission-templates.json` | Existe, 5 templates (`orchestrator, readonly, readwrite, reviewer, sddorchestrator` + keys meta `_doc,_generated,_used_by`), SIN schema formal | `ConvertFrom-Json \| Get-Member` |
| Frontmatter YAML en skills | Convencion SIN schema (ej. `.agents/skills/odd/SKILL.md:1-7`: `name, description, triggers, changelog, token_budget`) | `Read .agents/skills/odd/SKILL.md:1-7` |
| `tests/prompts/` goldens | 10 pares `*.md` + `*.golden.md` (accessibility, baseline-ui, image-pipeline, performance, performance-tracker, seo, ui-engine, vision-analyze, visual-testing, web-quality-audit) + `README.md`; validados por gates estaticos de integridad de prompts, NO son fixtures de contrato | `Get-ChildItem tests/prompts/` |
| `node_modules/ajv` | Presente, version `8.20.0`, transitivo (NO declarado en `package.json`: `Select-String '"ajv"' package.json` vacio) | `node_modules/ajv/package.json` version |
| `odd/tasks/` existentes | 13 tasks previos (ronda2..ronda7, ci-green, hard-gate-checkpoint, mejora-security, mejora-skills, p0-2, refactor-agentes-permisos, repo-verification); formato precedente `ronda7-arranque.md` | `Get-ChildItem odd/tasks/` |
| Untracked ajeno | `odd/tasks/refactor-agentes-permisos-gentle-ai.md` (??) - NO tocar, fuera de scope R8 | `git status --porcelain` |

Referencia upstream solo-concepto (NO copiar, NO importar): `contracts/telemetry|review-integration` + `testdata/golden/` como IDEA de separar schemas formales de fixtures de outputs. R8 define sus propios schemas desde convenciones locales.

## 1. Gate: 3 preguntas respondidas

### Q1. Que 3-4 schemas formalizar? Que validador usar? Harness reutilizable en skill `api-testing`?

**Schemas (4, priorizados 3 + 1 manifest):**

| # | Schema propuesto | Formaliza (convencion actual sin schema) | Campos nucleo a fijar |
|---|---|---|---|
| 1 | `contracts/rdd-receipt.schema.json` | `.rdd/rdd-receipt-001..004.json` (estructura observada en receipt-001: `id, freeze, freeze_note, tier, tier_justification, files, file_statuses{deleted,modified}, lines_changed, lines_deleted, verdict, verdict_note, review{status,method,duration_ms,gate_output,process_breach,gaps}, 4r{run,risk,read,rel,res}, fixes_applied, blockers, process_blockers, escalation, next, auto_fix, retroactive, retroactive_note, timestamp`) | `id` pattern `^rdd-receipt-\d{3}$`; `tier` 0-3 integer; `verdict` enum [PASS, FAIL, SKIP, VERIFY_OK_FASTPATH? -> normalizar]; `timestamp` date-time; `files` minItems 1; `required: [id, freeze, tier, files, verdict, timestamp]` |
| 2 | `contracts/permission-matrix.schema.json` | `scripts/lib/permission-templates.json` (5 templates + `_doc/_generated/_used_by`) | `type: object`; `properties` por template con `permissions[]`, `scopes[]`, `deny[]`; `additionalProperties: false` en cada template; `required` = los 5 nombres; keys `_`-prefijo via `patternProperties: {"^_": {}}` solo lectura/doc |
| 3 | `contracts/skill-frontmatter.schema.json` | Frontmatter YAML de `*.md` skills (ej. `odd/SKILL.md:1-7`) parseado a JSON antes de validar | `name` slug pattern `^[a-z0-9-]+$`; `description` minLength 10; `triggers` string-or-array; `token_budget` integer >= 0; `changelog` string opcional; `required: [name, description]`; `additionalProperties: true` (skills tienen keys propias, no cerrar de golpe) |
| 4 | `contracts/golden-manifest.schema.json` | `testdata/golden/` nuevo (manifiesto que indexa cada golden: comando que lo genera, hash, schema que obedece) | `goldens[]: {name, generator, args, sha256, schema, created}`; `required: [name, generator, sha256]` |

Si R8 se queda sin capacidad, el #4 se declara a R9 (ver seccion 8). Minimo viable R8 = schemas 1-3.

**Validador:**

- **Primario: PowerShell nativa `Test-Json -SchemaFile` (PS 7+, SIN deps nuevas).** `confidence: high`. Motivo: repo ya es Pester-first (`tests/*.Tests.ps1`, `scripts/tests/*.Tests.ps1`); `Test-Json` viene en el runtime, hermetico, sin `npm install`, funciona en CI Windows existente. Cada test Pester hace `Get-Content -Raw | Test-Json -SchemaFile <schema>` + `Should -BeTrue`.
- **Secundario: Ajv `8.20.0` ya vendored en `node_modules/` (transitivo, usable sin declarar dep nueva).** `confidence: medium`. Uso: validacion estricta opcional (`strict: true`, `allErrors: true`) en CI node o chequeo local `npx ajv-cli validate -s <schema> -d <json>`. NO agregar a `package.json` en R8 (evita cambio de deps = evita escalado de tier); documentar como herramienta disponible, no como dependencia formal.
- **Frontmatter YAML:** pre-paso `ConvertFrom-Yaml`/parser existente a JSON y luego `Test-Json` contra schema #3. El schema es JSON Schema aunque la fuente sea YAML (patron estandar).

**Harness reutilizable en skill `api-testing`? NO.** `confidence: medium`. `api-testing` es para endpoints REST/GraphQL (contratos request/response, mocks, auth flows), no para schemas de archivos locales + goldens de CLI. El harness R8 va donde ya viven los gates: `tests/contract-*.Tests.ps1` (Pester) + helper `scripts/tests/contract-helpers.ps1` (comparador goldens). Si `api-testing` quiere consumir los schemas como ejemplos de JSON Schema, puede referenciarlos, pero NO se reutiliza su harness ni se modifica ese skill en R8.

### Q2. Que goldens crear? (outputs canonicos re-ejecutables)

En `testdata/golden/` (NUEVO namespace, ver Q3), cada golden = output capturado de un comando re-ejecutable + entrada en `golden-manifest.json`:

| Golden | Generador canonico (re-ejecutable) | Que fija |
|---|---|---|
| `validate-rdd-receipts.golden.json` | `Test-Json -SchemaFile contracts/rdd-receipt.schema.json` sobre las 4 receipts (resultado PASS/FAIL por receipt + conteo) | Contrato receipts verde contra datos reales |
| `permission-matrix-expansion.golden.json` | Expansion/resolucion de `scripts/lib/permission-templates.json` (rol -> permisos efectivos, p. ej. `readonly`/`reviewer`) | Semantica de la matriz, no solo sintaxis |
| `skill-frontmatter-parse.golden.json` | Parseo de N skills muestra (minimo `odd`, `engram-protocol`, `ps-compat`) a JSON normalizado | Frontmatter real obedece schema #3 |
| `registry-build.golden.json` | Build de registry/indice existente (el que genere el repo: skill registry o dashboard-data) en modo determinista (sort + sin timestamps) | Output de build estable y diffable |
| `audit-check-report.golden.json` | Reporte de `audit-check`/`jd-verifier -FastPath` en modo `--validate`/report (segun gating local) | Formato de reporte de auditoria fijado |
| `golden-manifest.json` | Indice de los anteriores (`generator`, `args`, `sha256`) validado por schema #4 | Trazabilidad golden<->generador |

Regla golden: determinismo obligatorio (ordenar keys/arrays, `sha256` en manifest, sin timestamps volatiles o normalizados). Comparador: `Compare-Object` / hash en Pester, NO string-diff fragil.

### Q3. Como conviven con los goldens de prompts existentes (no romperlos)?

- **Namespaces disjuntos, cero colision:** existentes viven en `tests/prompts/*.golden.md` (pares `.md`/`.golden.md`, gates estaticos de integridad de prompts); nuevos viven en `testdata/golden/*.golden.json` (+ `golden-manifest.json`). Distinto directorio + distinta extension (`.md` vs `.json`) + distinto comparador. `confidence: high`.
- **Prohibiciones R8:** NO renombrar/mover/editar nada en `tests/prompts/`; NO reutilizar sus asserts para JSON; NO agregar `testdata/` al glob de los gates de prompts y viceversa. El test nuevo filtra por path propio (`testdata/golden/*`), el viejo sigue filtrando `tests/prompts/*`.
- **Verificacion de no-regresion por slice:** cada slice corre el gate de prompts existente (debe seguir PASS) + el nuevo gate de contratos; si el viejo falla, el slice falla aunque el nuevo pase.

## 2. ODD Gate por slice (1 slice = 1 conventional commit <=400L)

Regla (precedente `ronda7-arranque.md` + skill `odd`: Gate SMALL vs SUBSTANTIAL): ALL criteria must pass para SMALL (<=50L, 1 file + test companero, sin schema/auth/API, sin deps externas, <=2 commits); si alguno falla -> SUBSTANTIAL (1 slice = 1 commit <=400L).

| Criterio (`odd`) | Umbral SMALL | S1 receipt schema + test 4 receipts | S2 permission + frontmatter schemas + tests | S3 goldens + comparador + manifest |
|---|---|---|---|---|
| Lineas est. | <=50L | ~120-180L (schema ~80-110L + test ~40-70L) -> FAIL | ~180-280L (2 schemas ~140-190L + tests ~40-90L) -> FAIL | ~150-250L (5-6 goldens pequenios + manifest + helper/comparador ~60-90L + test ~50-70L) -> FAIL |
| Files | 1 (+ test) | 2 (`contracts/rdd-receipt.schema.json` + `tests/contract-receipts.Tests.ps1`) -> FAIL | 3-4 (`contracts/permission-matrix.schema.json`, `contracts/skill-frontmatter.schema.json` + `tests/contract-permissions.Tests.ps1` [+ ext. frontmatter en mismo test]) -> FAIL | 6-9 (`testdata/golden/*.golden.json` x5-6 + `golden-manifest.json` + `scripts/tests/contract-helpers.ps1` + `tests/contract-goldens.Tests.ps1`) -> FAIL |
| Schema/auth/API | None | Schema NUEVO (el objeto del slice) -> FAIL | Schema NUEVO -> FAIL | Schema consumidor (usa S1/S2) + formato golden NUEVO -> FAIL |
| Deps externas | None | None (Test-Json nativo; Ajv solo doc, no dep) -> PASS | None (idem) -> PASS | None (idem) -> PASS |
| Commits forecast | <=2 | 1 | 1 | 1 |
| **Veredicto** | - | **SUBSTANTIAL -> R8-S1 (Tier 1)** | **SUBSTANTIAL -> R8-S2 (Tier 2)** | **SUBSTANTIAL -> R8-S3 (Tier 1)** |

- **Orden mandatorio: S1 -> S2 -> S3.** S1 fija el schema mas observado (4 receipts reales como dataset) y el patron de test Pester+Test-Json; S2 replica el patron en 2 schemas; S3 consume S1/S2 (goldens validables contra schemas + manifest). Sin S1, S2/S3 no tienen patron contra que verificar.
- **R8 total: 3 slices, 3 commits, ~450-710L agregadas (~150-240L/slice).** Ningun slice excede 400L -> **nada se deriva a R9 por capacidad**; R9 recibe solo endurecimiento futuro (seccion 8).
- **Tiers:** S1 Tier 1 (2 files, patron nuevo pero acotado); S2 Tier 2 (>3 files y 2 schemas + semantica de permisos = superficie de decision); S3 Tier 1 (archivos de datos + helper determinista, sin semantica de permisos). Review plan en seccion 4.

## 3. Slice Plan (scope / est. lines / outcome / orden)

- **R8-S1 - `test(contracts): rdd-receipt schema + gate sobre 4 receipts`** (Tier 1) - PRIMERO
  Scope: crear `contracts/rdd-receipt.schema.json` (~80-110L, draft 2020-12, `required` + `enum` verdict + `pattern` id + `format` timestamp) + `tests/contract-receipts.Tests.ps1` (~40-70L: 4 Its una por receipt + 1 It conteo/estructura; `Test-Json -SchemaFile`; fixtures negativas en `TestDrive` para FAIL hermetico). NO tocar `tests/prompts/`, NO tocar `permission-templates.json`, NO tocar skills. Solo lectura de `.rdd/`. Est. ~120-180L en 2 files, 1 commit. `confidence: high`.
  Outcome: las 4 receipts validan PASS contra schema formal; patron Pester+Test-Json congelado para S2/S3.
- **R8-S2 - `feat(contracts): permission-matrix + skill-frontmatter schemas + tests`** (Tier 2) - SEGUNDO (requiere patron S1)
  Scope: crear `contracts/permission-matrix.schema.json` (~70-100L: 5 templates + `patternProperties: {"^_": {}}` + `additionalProperties: false`) + `contracts/skill-frontmatter.schema.json` (~70-90L: `name/description/triggers/token_budget/changelog`) + extender/crear `tests/contract-permissions.Tests.ps1` (~40-90L: It matriz real PASS + It expansion semantica minima + Its frontmatter sobre muestra `odd/engram-protocol/ps-compat` + fixtures negativas TestDrive). Solo lectura de `scripts/lib/permission-templates.json` y `*.md` skills. NO tocar `tests/prompts/`. Est. ~180-280L en 3-4 files, 1 commit. `confidence: medium` (riesgo: `additionalProperties` en frontmatter y keys `_` en matriz requieren 1 iteracion de ajuste contra datos reales).
  Outcome: matriz de 5 templates y frontmatter de muestra validan PASS; reglas de cierre (`additionalProperties`) fijadas sin falsos positivos.
- **R8-S3 - `test(contracts): testdata golden outputs + comparador determinista`** (Tier 1) - TERCERO (requiere S1+S2)
  Scope: crear `testdata/golden/` con 5-6 `*.golden.json` (seccion 1-Q2, cada uno <=40L, keys ordenadas, sin timestamps volatiles) + `testdata/golden/golden-manifest.json` (indice con `generator/args/sha256`) + `scripts/tests/contract-helpers.ps1` (~60-90L: `New-Golden`, `Compare-Golden` con hash + `Compare-Object`, normalizacion de orden) + `tests/contract-goldens.Tests.ps1` (~50-70L: re-ejecuta generadores y compara contra goldens + valida manifest contra schema #4 si cabe en budget, si no lo declara a R9). NO tocar `tests/prompts/`. Est. ~150-250L en 6-9 files pequenos, 1 commit. `confidence: medium` (riesgo: no-determinismo de generadores; mitigacion: sort + sha en manifest).
  Outcome: outputs canonicos re-ejecutables fijados; `Compare-Golden` PASS en re-run limpio; gate de prompts existente sigue PASS (no-regresion probada).

## 4. Freeze EN ESTA RAMA + Tier + review plan

- **Freeze point:** rama `experimento/mejora-ronda8-contratos` @ HEAD `04d1c151937ae51c2e673959fb12d667162c4439`. Cada slice congela su base con `git rev-parse HEAD` + `git diff | git hash-object --stdin` (8 chars) en su receipt (plantillas seccion 6). `main@54a53384` nunca se toca (solo lectura para diff-base si se necesita).
- **Tiers y review (RDD rule 4):**
  - S1 Tier 1: `jd-verifier.ps1` (zona que corresponda) + `code-review-agent` 4R simple. Sin auto-fix en FAIL (se registra y se itera en mismo slice-commit, max 2 intentos; al 3ro STOP + escalar).
  - S2 Tier 2: `code-review-agent` 4R BLOCKER-capable OBLIGATORIO + `judgment-day` dual en FAIL (2 instancias opuestas + sintesis). Nunca auto-fix en FAIL Tier 2. CI GitHub (e2e/tests/pester/security/pssa-lint) debe estar verde o declarado pendiente en receipt (precedente `rdd-receipt-001` honesto: documentar brecha, no maquillar).
  - S3 Tier 1: igual que S1 + verificacion de determinismo (doble re-run del comparador debe dar mismo hash).
- **Write-scope por slice:** solo los paths de su Scope (seccion 3) + su receipt en `.rdd/rdd-receipt-00{5,6,7}.json`. Cualquier path fuera -> STOP y nuevo slice.

## 5. Verify por slice (comandos esperados, mismo commit)

- **S1:** `Invoke-Pester tests/contract-receipts.Tests.ps1` (5+ Its PASS) + `Invoke-Pester tests/prompts/` o gate de prompts vigente (PASS sin cambios) + `Test-Json -SchemaFile contracts/rdd-receipt.schema.json` manual spot-check sobre 1 receipt. Esperado: todo verde.
- **S2:** `Invoke-Pester tests/contract-permissions.Tests.ps1` (matriz + frontmatter PASS, negativas FAIL-controlado en TestDrive) + gate prompts PASS + `npx ajv-cli validate -s contracts/permission-matrix.schema.json -d scripts/lib/permission-templates.json` (opcional, INFO; no gatea si `ajv-cli` no instalado).
- **S3:** `Invoke-Pester tests/contract-goldens.Tests.ps1` (comparador PASS en doble re-run, hashes iguales) + `Test-Json` del manifest + gate prompts PASS. Esperado: determinismo probado (2 runs consecutivos, mismo sha256).

## 6. Receipt templates (plantillas, se rellenan al ejecutar cada slice)

```json
// .rdd/rdd-receipt-005.json (R8-S1)
{
  "id": "rdd-receipt-005",
  "freeze": "HEAD-<base7>-<diff8>",
  "tier": 1,
  "files": ["contracts/rdd-receipt.schema.json", "tests/contract-receipts.Tests.ps1"],
  "lines_changed": "<n>",
  "verdict": "PASS|FAIL|SKIP",
  "review": { "status": "<4R-verdict>", "method": "code-review-agent 4R", "gaps": [] },
  "blockers": [],
  "next": ["R8-S2"],
  "auto_fix": false,
  "timestamp": "<date-time>"
}
```

```json
// .rdd/rdd-receipt-006.json (R8-S2)
{
  "id": "rdd-receipt-006",
  "freeze": "HEAD-<base7>-<diff8>",
  "tier": 2,
  "files": ["contracts/permission-matrix.schema.json", "contracts/skill-frontmatter.schema.json", "tests/contract-permissions.Tests.ps1"],
  "lines_changed": "<n>",
  "verdict": "PASS|FAIL|SKIP",
  "review": { "status": "<4R-verdict>", "method": "code-review-agent 4R BLOCKER-capable", "gaps": [] },
  "escalation": "judgment-day",
  "blockers": [],
  "next": ["R8-S3"],
  "auto_fix": false,
  "timestamp": "<date-time>"
}
```

```json
// .rdd/rdd-receipt-007.json (R8-S3)
{
  "id": "rdd-receipt-007",
  "freeze": "HEAD-<base7>-<diff8>",
  "tier": 1,
  "files": ["testdata/golden/*.golden.json", "testdata/golden/golden-manifest.json", "scripts/tests/contract-helpers.ps1", "tests/contract-goldens.Tests.ps1"],
  "lines_changed": "<n>",
  "verdict": "PASS|FAIL|SKIP",
  "review": { "status": "<4R-verdict + determinism double-run>", "method": "code-review-agent 4R + Compare-Golden re-run", "gaps": [] },
  "blockers": [],
  "next": ["Ronda 9 (seccion 8)"],
  "auto_fix": false,
  "timestamp": "<date-time>"
}
```

## 7. Review Log (vacio en Fase 1, se rellena al ejecutar)

| Slice | Reviewer/metodo | Veredicto | Fecha | Notas |
|---|---|---|---|---|
| R8-S1 | implementer self-verify: Pester 8/8 + Test-Json 4/4 + golden-fixtures 4/4 | PASS (4R formal pendiente de orquestador) | 2026-09-24 | Schema draft 2020-12 (Test-Json PS7 lo acepta; draft-07 fallback) + tests/contract-receipt.Tests.ps1 (singular: AllowedPaths manda sobre plural del plan) ; helper NO creado (sin reuso interno S1; evita superficie ROZA scripts/) ; commit+gate hook: 2 intentos SIN bypasses (NO --no-verify, NO FORCE_SHIP). Intento 1: 26/28 ([13] 2 negativas caen por $ErrorActionPreference=Stop en hook + [16]). Fix: -ErrorAction SilentlyContinue en las 2 negativas (mismo archivo, verificado 8/8 bajo Stop). Intento 2: 27/28, UNICO bloqueo [16] write-scope (contracts/* fuera de allowlist de .gentleman/write-scope.json; sin mecanismo de marker para [16]). STOP fail-closed: commit abortado por hook, CERO writes a historial. Desbloqueo requiere chore(scope) previo con contracts/* (+testdata/* para S3), fuera de AllowedPaths S1: decision de orquestador/usuario |
| R8-S2 | implementer self-verify: Pester permission 12/12 + frontmatter 107/107 (97 sweep) + S1 8/8 + E1 10/10, sin regresion | PASS (4R formal pendiente de orquestador) | 2026-09-24 | Nombres resueltos por delegacion: `permission-templates` (= fuente, no `permission-matrix` del plan) + tests singulares separados (`contract-permission/frontmatter`, no plural unico). Test-Json/NJsonSchema NO soporta $ref/$defs ni additionalProperties-schema en anyOf (probes: fail-open True) -> schema fija estructura, semantica de valores en Pester (leaf-scan allow/deny/ask). Hallazgo Pester 5: -ForEach se evalua en discovery (sweep daba 0 tests en silencio) + top-level NO visible en Its -> Get-ChildItem INLINE en -ForEach, helper en BeforeAll. E1 verificado: valida presencia/unicidad/cobertura, sin tipos -> sin contradiccion. CERO divergencias realidad-schema; NUNCA se toco fuente. Commit+gate hook SIN bypasses (ver receipt del slice) |
| R8-S3 | implementer self-verify: Pester goldens 17/17 (doble run mismo resultado) + receipt 8/8 + permission 12/12 + frontmatter 107/107 + golden-prompts 7/7 + golden-fixtures 4/4, sin regresion | PASS (4R formal pendiente de orquestador) | 2026-09-24 | Staged heredado de intento previo cancelado (anti-wipe: 7 files intactos, verificados byte-level). Comparador inline en BeforeAll (helper scripts/tests/contract-helpers.ps1 NO creado: sin reuso interno, evita superficie ROZA scripts/). 5 goldens re-ejecutables: receipts 4/4, permission leaf-scan 5 templates, frontmatter 3 samples, registry 97 skills (drop .generated volatil), audit odd 10/10. Manifest sha256 byte-level 5/5 + canonico re-run 5/5 + determinismo doble-run 5/5 + sin timestamps. Commit+gate hook SIN bypasses (ver receipt del slice) |

## 8. Rollback (por slice, orden inverso)

- S3: `git revert <commit-S3>` o borrar `testdata/golden/` + `scripts/tests/contract-helpers.ps1` + `tests/contract-goldens.Tests.ps1`; re-correr gate prompts (debe PASS).
- S2: `git revert <commit-S2>` o borrar los 2 schemas + test; re-correr S1 (debe PASS).
- S1: `git revert <commit-S1>` o borrar `contracts/` (si vacio, borrar dir) + test; repo vuelve a HEAD `04d1c151`.
- Nunca `git reset --hard` sobre trabajo ajeno; nunca tocar `main`; el untracked `refactor-agentes-permisos-gentle-ai.md` no se toca en ningun rollback.

## 9. Para Ronda 9 (resto declarado, fuera de R8)

1. `contracts/golden-manifest.schema.json` si no cupo en S3 + validacion estricta Ajv (`strict:true, allErrors:true`) como gate CI.
2. Schemas concepto-upstream `telemetry` y `review-integration` (solo si el repo los necesita de verdad; hoy no hay telemetria ni review-integration local que formalizar).
3. Declarar Ajv como devDependency formal o mantener vendored (decision con dueno; hoy: no tocar `package.json`).
4. Cableado CI: job `contracts` en GitHub Actions (Pester contratos + goldens + prompts) con badge.
5. Goldens extra: `audit-check` completo, `registry build` ampliado a todos los skills, fixtures de error con mensajes canonicos.
6. Normalizacion de `verdict` historico (`VERIFY_OK_FASTPATH` vs `SKIP` en receipts 001-004): decidir enum final y, si se migra, hacerlo como slice propio con re-validacion de las 4 receipts (NO reescribir historia sin receipt).

---
*Fase 1 completa: plan + freeze. Ejecucion (S1->S2->S3) en siguientes sesiones, 1 commit por slice, receipts 005/006/007.*
