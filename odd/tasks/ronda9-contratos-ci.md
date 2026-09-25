# Ronda 9 - Golden-manifest schema + job `contracts` CI con badge - ODD Gate + Slice Plan + RDD Freeze (Fase 1: análisis, SIN código)

> Fase 1 - análisis y freeze. NO código, NO commit, NO push (deny), NO merge, NO tocar main.
> Rama: `experimento/mejora-ronda9-contratos-ci` - HEAD `d4a3e13b` - main `54a53384` intacto (solo lectura).
> Este archivo (`odd/tasks/ronda9-contratos-ci.md`) es el ÚNICO write permitido de la fase. La ejecución lo commitea después (1 commit por slice + receipts).
> Precedente de formato: `odd/tasks/ronda8-contratos.md` (194L, inventario + gate Q&A + ODD gate por slice + slice plan + freeze/tiers + verify + receipt templates + review log + rollback + resto a futuro). Este documento lo imita en estructura.
> Alcance R9 mínimo: SOLO ítems 1 y 4 de `ronda8-contratos.md:184-191` secc.9. Resto (2,3,5,6) queda declarado a futuro (sección 9).

## 0. Inventario medido EN ESTA RAMA (fail-closed verificado, `confidence: high` salvo nota)

| Item | Estado medido | Evidencia |
|---|---|---|
| Rama actual | `experimento/mejora-ronda9-contratos-ci` | `git branch --show-current` |
| HEAD | `d4a3e13b3ed367ff6c0df2b4f46ff908ca1a1670` (prefijo `d4a3e13b` OK, = HEAD de `experimento/mejora-ronda8-contratos`) | `git rev-parse HEAD` |
| main | `54a5338481c249bb34cd0c2d05a7ffe00c4c0912` (prefijo `54a53384` OK, solo lectura) | `git log --oneline main -1` |
| Working tree | Limpio al crear rama (`git status --short --branch` = solo header de rama, 0 modificados) | `git status --short --branch` |
| `odd/tasks/ronda8-contratos.md` | EXISTE, 194L, leído entero (modelo de formato + secc.9 ítems 1-6) | `Read odd/tasks/ronda8-contratos.md` (194 lines) |
| `odd/tasks/` | 13 tasks previos (formato precedente `ronda7-arranque.md` + R8) | `(Get-ChildItem odd/tasks/).Count` = 13 |
| `testdata/golden/golden-manifest.json` | EXISTE, 40L: `{version: 1, goldens[5]: {name, generator, args, sha256, schema}}` — campo `created` AUSENTE en los 5, `schema` VACÍO (`""`) en 2 (registry, audit) | `Read testdata/golden/golden-manifest.json` (40 lines) |
| 5 goldens | `validate-rdd-receipts` 13L, `permission-matrix-expansion` 18L, `skill-frontmatter-parse` 28L, `registry-build` 9L, `audit-check-report` 20L | `Get-ChildItem testdata/golden/` + lines |
| `tests/contract-goldens.Tests.ps1` | EXISTE, 259L; hoy valida manifest SIN schema formal: `It manifest exists with 5 goldens` (líneas ~202-212: nombre/generador/sha256 formato, sin `Test-Json -SchemaFile`) + hash byte-level + re-run canónico + doble-run determinismo + sin timestamps | `Read tests/contract-goldens.Tests.ps1:202-260` |
| `contracts/*.schema.json` | 3 schemas, patrón `draft 2020-12`, `$id`, `required`, `enum`/`pattern`: `rdd-receipt` 129L, `permission-templates` 37L, `skill-frontmatter` 32L. `golden-manifest.schema.json` NO existe | `Get-ChildItem contracts/` + lines |
| Patrón schemas | `rdd-receipt.schema.json:1-7`: `$schema draft 2020-12`, `required: [id, freeze, tier, files, verdict, timestamp]`, `verdict` enum, `id` pattern, `timestamp` format date-time | `Read contracts/rdd-receipt.schema.json:1-7` |
| Restricción Test-Json | NJsonSchema hace FAIL-OPEN con `$ref`/`$defs` y `additionalProperties`-schema dentro de `anyOf` (hallazgo R8-S2 documentado en review log R8) → schema nuevo debe usar SUBSET SEGURO (type/required/enum/pattern/minimum + `additionalProperties` solo top-level) | `ronda8-contratos.md:174` + `permission-templates.schema.json` header |
| CI existente | 4 workflows en `.github/workflows/`: `ci.yml` 135L (jobs `pester-tests` via `scripts/run-ci-tests.ps1` + `pssa-lint` + `coverage-gate` + `perf-regression`), `quality-gate.yml` 394L (jobs `lint`, `lint-linux`, `security`, `tests`, `tests-v1`, `e2e`), `perf-regression.yml`, `release.yml`. Job `contracts` NO existe | `Get-ChildItem .github/workflows/` + `Read ci.yml` + `Read quality-gate.yml` |
| Job Pester v1 (precedente de cableado) | `quality-gate.yml:340-347` job `tests-v1`: `Invoke-Pester -Path './tests/*.Tests.ps1' -PassThru`, fail si `FailedCount > 0` | `Read quality-gate.yml:340-347` |
| Runner central | `scripts/run-ci-tests.ps1` (Pester 5.5.0 pineado, `Run.Exit=$true`, NUnit XML) — `ci.yml:23` lo invoca con default `./scripts/tests` | `Get-Content scripts/run-ci-tests.ps1 -TotalCount 40` |
| Gate prompts (no-regresión) | `tests/golden-prompts.Tests.ps1` 154L, namespace disjunto `tests/prompts/*.golden.md` vs `testdata/golden/*.golden.json` (regla R8-Q3 sigue vigente) | `(Get-Content tests/golden-prompts.Tests.ps1).Count` = 154 |
| Tests contrato actuales | `contract-receipt` 54L, `contract-permission` 118L, `contract-frontmatter` 135L, `contract-goldens` 259L | `Get-ChildItem tests/contract-*.Tests.ps1` + lines |
| README badges | CERO badges hoy: `Select-String 'shields|badge' README.md` vacío; head es `# Gentleman Agent...` sin sección de badges | `Select-String -Path README.md -Pattern 'shields|badge'` (0 hits) |
| `node_modules/ajv` | Presente, versión `8.20.0`, transitivo (NO declarado: `Select-String '"ajv"' package.json` vacío) | `ConvertFrom-Json node_modules/ajv/package.json` → `8.20.0` |
| `package.json` | NO tocar (ítem 3 secc.9 queda fuera: Ajv sigue vendored, sin devDependency formal) | `Select-String '"ajv"' package.json` (vacío) |
| `.rdd/rdd-receipt-007.json` | EXISTE, 25L, precedente de freeze: `freeze: HEAD-3fb95446-e69de29b`, `freeze_note` explica `diff8=e69de29b` = working tree limpio (`git diff` vacío), `lines_changed=387` solo scope | `Read .rdd/rdd-receipt-007.json` (25 lines) |

Referencia de alcance (NO copiar, NO importar fuera de los 2 ítems): `ronda8-contratos.md` secc.9 ítems 1 (`golden-manifest.schema.json` + Ajv estricta como gate) e ítem 4 (job `contracts` + badge). Ítems 2,3,5,6 fuera (sección 9).

## 1. Gate: 3 preguntas respondidas

### Q1. ¿Qué fija exactamente el schema #4 y cómo se valida?

**Qué fija (`contracts/golden-manifest.schema.json`, nuevo):** formaliza la estructura REAL observada en `testdata/golden/golden-manifest.json` (40L). `confidence: high` en campos observados, `medium` en opcionales nuevos.

| Campo | Fijación propuesta | Evidencia en datos reales |
|---|---|---|
| `version` | `integer`, `const: 1` o `minimum: 1` (`confidence: medium` — solo 1 ejemplar `1` observado) | `golden-manifest.json:39` = `1` |
| `goldens` | `array`, `minItems: 5` (los 5 actuales; permitir más a futuro sin romper) | 5 entradas, líneas 2-38 |
| `goldens[].name` | `string`, `pattern: ^[a-z0-9-]+\.golden\.json$` (`confidence: high` — los 5 cumplen) | 5 × `*.golden.json` |
| `goldens[].generator` | `string`, `minLength: 1` (comando re-ejecutable documentado; NO se valida ejecutabilidad en schema) | 5/5 no-vacío |
| `goldens[].args` | `string` (opcional, puede ser `""` — hoy 5/5 presentes, permitir ausente) | 5/5 presentes |
| `goldens[].sha256` | `string`, `pattern: ^[0-9a-f]{64}$` (hash byte-level del golden) | 5/5 cumplen (verificado por `contract-goldens.Tests.ps1:214-226`) |
| `goldens[].schema` | `string` (opcional, permite `""` — hoy 2/5 vacíos: registry + audit sin schema) | `golden-manifest.json:28,35` = `""` |
| `goldens[].created` | `string` `format: date-time` (opcional, AUSENTE en 5/5 hoy — se declara opcional para no romper datos reales) | ausente 5/5 |
| Root | `required: [goldens]`, `version` requerido (`confidence: medium`), `additionalProperties: false` en root, `true`/abierto en entries si se quiere tolerar `source`/`expansion` futuras (`confidence: medium` — decidir contra datos en ejecución; default SEGURO: `additionalProperties: true` en entries, `false` en root) | root hoy solo `goldens+version` |
| `$schema` | `draft 2020-12` + `$id https://gentleman-agent-gh/contracts/golden-manifest.schema.json` (patrón de los 3 schemas) | `rdd-receipt.schema.json:1-7` |
| PROHIBIDO | `$ref`/`$defs`, `additionalProperties`-schema dentro de `anyOf` (FAIL-OPEN NJsonSchema, hallazgo R8-S2) | `ronda8-contratos.md:174` |

**Cómo se valida (dos niveles, sin nueva dep):**

- **Gate (bloqueante): PowerShell nativa `Test-Json -SchemaFile` (PS 7+) en Pester.** `confidence: high`. Cada `It` hace `Get-Content -Raw | Test-Json -SchemaFile contracts/golden-manifest.schema.json` + `Should -BeTrue`, más `It` de negativas en `TestDrive` (manifest sin `sha256`, `sha256` malformado → `Should -BeFalse`). Cero deps, hermético, funciona en CI Windows existente (patrón R8-S1 congelado).
- **INFO/opcional (NO gatea): Ajv `8.20.0` vendored con `strict: true, allErrors: true`.** `confidence: medium`. Uso: chequeo local `node scripts/validate-ajv-strict.js` o `npx ajv-cli validate` si disponible; si `ajv-cli` no instalado o Ajv rechaza `draft 2020-12` en estricto, se reporta como WARNING y NO falla el test/CI. NO declarar en `package.json` (ítem 3 queda fuera; evita escalado de tier por cambio de deps). `confidence: low` en que Ajv-strict pase a la primera (vendored frágil + `format: date-time` + `pattern` pueden dar warnings estrictos) → por eso es INFO, no gate.

### Q2. ¿Qué comando exacto corre el job CI y en qué workflow vive?

**Comando exacto (propuesto, `confidence: high` en piezas, `medium` en string final):**

```powershell
Invoke-Pester -Path @(
  './tests/contract-receipt.Tests.ps1',
  './tests/contract-permission.Tests.ps1',
  './tests/contract-frontmatter.Tests.ps1',
  './tests/contract-goldens.Tests.ps1',
  './tests/golden-prompts.Tests.ps1'
) -Output Detailed -PassThru | ForEach-Object { if ($_.FailedCount -gt 0) { exit 1 } }
```

- 4 suites de contrato (nombres SINGULARES reales, no plurales del plan R8: `contract-receipt`, `contract-permission`, `contract-frontmatter`, `contract-goldens` — verificado por `Get-ChildItem tests/contract-*.Tests.ps1`) + gate prompts `golden-prompts.Tests.ps1` (no-regresión R8-Q3). `confidence: high`.
- 5 files (rango pedido 4-6: OK). Alternativa aceptada en ejecución: `Invoke-Pester -Path './tests/contract-*.Tests.ps1','./tests/golden-prompts.Tests.ps1'` (glob, mismo set). `confidence: medium` que el orquestador prefiera glob vs lista explícita.
- `shell: pwsh`, `runs-on: windows-latest` (Pester + `Test-Json` + PSSA ya probados ahí). `confidence: high`.

**Dónde vive (`confidence: medium` — dos opciones, default `ci.yml`):**

- **Default: `ci.yml` nuevo job `contracts`** (junto a `pester-tests`, mismo runner/filosofía; `ci.yml` hoy 135L, +~20-35L). Motivo: `ci.yml` es el pipeline de tests; `quality-gate.yml` ya tiene `tests-v1` genérico que corre `./tests/*.Tests.ps1` (solapa parcial) y su job `tests` usa `scripts/tests/` (otro root). Añadir `contracts` en `ci.yml` da señal enfocada sin tocar Quality Gate.
- **Alternativa (si orquestador prefiere): `quality-gate.yml` job `contracts`** reutilizando el patrón `tests-v1:340-347` con `-Path` acotado. NO en ambos (duplicar = doble costo CI Windows).
- Precedente a imitar: `quality-gate.yml:340-347` (`tests-v1`: `Invoke-Pester -Path ... -PassThru`, `FailedCount > 0` → `exit 1`).

### Q3. ¿Dónde va el badge y qué mide?

- **Dónde:** `README.md:1` (línea 1, debajo del `# Gentleman Agent...`), primera línea de badges, formato shields: `[![contracts](https://github.com/LuisAlbertoMK/gentleman-agent-gh/actions/workflows/ci.yml/badge.svg?branch=main&event=push&job=contracts)](https://github.com/LuisAlbertoMK/gentleman-agent-gh/actions/workflows/ci.yml)`. `confidence: medium` en URL exacta (depende del job-name final `contracts` y del workflow elegido; si va a `quality-gate.yml`, cambia el path). Hoy CERO badges (`Select-String badge README.md` vacío) → es la primera insignia del repo.
- **Qué mide:** estado del job `contracts` (Pester contratos + goldens + prompts) en `main`, evento `push`. Verde = manifest válido contra schema + hashes byte-level OK + re-run canónico OK + determinismo doble-run OK + prompts sin regresión. Rojo = cualquiera de esos gates falla. NO mide cobertura ni PSSA (esos ya tienen sus jobs).
- **Convención shields:** `badge.svg?branch=main&event=push&job=<job>` filtra por job dentro del workflow (si el provider no soporta `job=`, fallback a badge del workflow completo). `confidence: medium`.

## 2. ODD Gate por slice (1 slice = 1 conventional commit ≤400L)

Regla (precedente `ronda7-arranque.md` + skill `odd`: Gate SMALL vs SUBSTANTIAL): ALL criteria must pass para SMALL (≤50L, 1 file + test compañero, sin schema/auth/API, sin deps externas, ≤2 commits); si alguno falla → SUBSTANTIAL (1 slice = 1 commit ≤400L).

| Criterio (`odd`) | Umbral SMALL | R9-S1 manifest schema + test | R9-S2 job `contracts` CI + badge |
|---|---|---|---|
| Líneas est. | ≤50L | ~100-170L (schema ~60-90L + test nuevo o extendido ~40-80L) → FAIL | ~25-45L (workflow +20-35L + README +2-5L + doc/notas) → PASS (pero falla otro criterio) |
| Files | 1 (+ test) | 2 (`contracts/golden-manifest.schema.json` + `tests/contract-manifest.Tests.ps1` NUEVO o extensión de `contract-goldens`) → FAIL | 2 (`.github/workflows/ci.yml` + `README.md`) → FAIL |
| Schema/auth/API | None | Schema NUEVO (el objeto del slice) → FAIL | CI wiring NUEVO (superficie: pipeline compartido, todos los PRs lo ejecutan) → FAIL |
| Deps externas | None | None (`Test-Json` nativo; Ajv solo INFO, no dep) → PASS | None (Pester + runners existentes; shields.io es solo imagen en README, no dep de build) → PASS |
| Commits forecast | ≤2 | 1 | 1 |
| **Veredicto** | - | **SUBSTANTIAL → R9-S1 (Tier 1)** | **SUBSTANTIAL → R9-S2 (Tier 2)** |

- **Orden mandatorio: S1 → S2.** S1 fija el schema que el job S2 va a gatear (sin S1, el job CI no tiene qué validar de más respecto a hoy; además S1 es local y rápido de iterar, S2 depende de runners Windows no-deterministas). Invertir el orden = CI verde sin contenido nuevo.
- **R9 total: 2 slices, 2 commits, ~125-215L agregadas.** Ningún slice excede 400L → **nada se deriva a futuro por capacidad**; el resto declarado (sección 9) es por scope, no por tamaño.
- **Tiers:** S1 Tier 1 (2 files, patrón R8-S1 replicado, sin semántica de permisos, sin pipeline compartido); S2 Tier 2 (toca pipeline compartido `ci.yml` que afecta a todos los PRs + badge público en README; superficie de decisión: elección de workflow, lista de paths Pester, filtro de badge; fallo aquí bloquea contributors aunque el código esté bien). Review plan en sección 4.

## 3. Slice Plan (scope / est. lines / outcome / orden)

- **R9-S1 - `test(contracts): golden-manifest schema + gate sobre manifest real`** (Tier 1) - PRIMERO
  Scope: crear `contracts/golden-manifest.schema.json` (~60-90L, draft 2020-12, SUBSET SEGURO sin `$ref`, `required: [goldens]`, `sha256` pattern, `schema`/`args`/`created` opcionales) + `tests/contract-manifest.Tests.ps1` NUEVO (~40-80L: It manifest real PASS via `Test-Json -SchemaFile` + Its negativas en `TestDrive` + It `schema` vacío permitido en registry/audit + spot-check Ajv strict como INFO con `continue-on-error`/try-catch, nunca gate). Solo lectura de `testdata/golden/golden-manifest.json` y `contracts/` existentes. NO tocar `tests/prompts/`, NO tocar `package.json`, NO tocar workflows, NO tocar README. Est. ~100-170L en 2 files, 1 commit. `confidence: high` (dataset mínimo y estable: 1 manifest de 40L; riesgo único: `additionalProperties` root vs entries, 1 iteración).
  Outcome: manifest real valida PASS contra schema formal; negativas FAIL-controlado; Ajv-strict reporta INFO sin gatear.
- **R9-S2 - `ci(contracts): job contracts en CI + badge README`** (Tier 2) - SEGUNDO (requiere S1)
  Scope: editar `.github/workflows/ci.yml` (+20-35L: job `contracts`, `runs-on: windows-latest`, `shell: pwsh`, comando Q2 con 5 paths, `timeout-minutes: 15`) + editar `README.md` (+2-5L: badge shields línea 1-2). NO tocar `tests/`, NO tocar `contracts/`, NO tocar `testdata/`, NO tocar `package.json`/`opencode.json`. Est. ~25-45L en 2 files, 1 commit. `confidence: medium` (riesgo: no-determinismo CI Windows + sintaxis exacta del filtro `job=` en badge; mitigación: imitar bloque `tests-v1:340-347`, validar YAML con `pre-commit check-yaml` + `actionlint` si disponible).
  Outcome: job `contracts` verde en el PR de prueba + badge renderiza estado del job en README; gate prompts sigue PASS dentro del job (no-regresión incluida).

## 4. Freeze EN ESTA RAMA + Tier + review plan

- **Freeze point:** rama `experimento/mejora-ronda9-contratos-ci` @ HEAD `d4a3e13b3ed367ff6c0df2b4f46ff908ca1a1670`. Cada slice congela su base con `git rev-parse HEAD` + `git diff | git hash-object --stdin` (8 chars) en su receipt (plantillas sección 6, precedente `rdd-receipt-007.json`: `freeze: HEAD-3fb95446-e69de29b`, `freeze_note` con `diff8=e69de29b` = working tree limpio). `main@54a53384` nunca se toca (solo lectura para diff-base si se necesita).
- **Tiers y review (RDD rule 4):**
  - S1 Tier 1: `jd-verifier.ps1` (zona que corresponda) + `code-review-agent` 4R simple. Sin auto-fix en FAIL (se registra y se itera en mismo slice-commit, max 2 intentos; al 3ro STOP + escalar).
  - S2 Tier 2: `code-review-agent` 4R BLOCKER-capable OBLIGATORIO + `judgment-day` dual en FAIL (2 instancias opuestas + síntesis). Nunca auto-fix en FAIL Tier 2. YAML validado (`check-yaml` + `actionlint` si disponible) y `README` badge con URL verificada; CI del PR debe estar verde o declarado pendiente en receipt (precedente `rdd-receipt-001` honesto: documentar brecha, no maquillar).
- **Write-scope por slice:** solo los paths de su Scope (sección 3) + su receipt en `.rdd/rdd-receipt-00{8,9}.json`. Cualquier path fuera → STOP y nuevo slice.

## 5. Verify por slice (comandos esperados, mismo commit)

- **S1:** `Invoke-Pester tests/contract-manifest.Tests.ps1` (4+ Its PASS: real + 2-3 negativas) + `Invoke-Pester tests/contract-goldens.Tests.ps1` (17/17 sin regresión, doble run mismo hash) + `Get-Content testdata/golden/golden-manifest.json -Raw | Test-Json -SchemaFile contracts/golden-manifest.schema.json` spot-check manual (`True`) + Ajv-strict INFO (`node -e "new (require('ajv'))({strict:true,allErrors:true}).compile(require('./contracts/golden-manifest.schema.json'))"` debe compilar; si falla → WARNING, no bloquea). Esperado: todo verde salvo Ajv-INFO tolerado.
- **S2:** `pre-commit run --all-files --show-diff-on-failure check-yaml` (PASS sobre `ci.yml`) + `actionlint .github/workflows/ci.yml` si disponible (INFO si no instalado) + `Invoke-Pester` local con el comando Q2 exacto (5 paths, 0 failed) + verificación de badge (URL shields responde 200 / renderiza en preview). Esperado: YAML válido + Pester local verde; CI remoto verde declarado en receipt al ejecutar.

## 6. Receipt templates (plantillas, se rellenan al ejecutar cada slice)

```json
// .rdd/rdd-receipt-008.json (R9-S1)
{
  "id": "rdd-receipt-008",
  "freeze": "HEAD-<base7>-<diff8>",
  "freeze_note": "Slice R9-S1 <commit-msg> en rama experimento/mejora-ronda9-contratos-ci. diff8=<diff8> = working tree limpio al emitir el receipt (git diff vacio). lines_changed=<n> solo scope del slice.",
  "tier": 1,
  "tier_justification": "RDD Risk Tiers: Tier 1 = solo contracts/golden-manifest.schema.json + tests/contract-manifest.Tests.ps1 (patron R8-S1 replicado, sin pipeline compartido). Ajv-strict solo INFO.",
  "files": ["contracts/golden-manifest.schema.json", "tests/contract-manifest.Tests.ps1"],
  "lines_changed": "<n>",
  "lines_deleted": 0,
  "verdict": "PASS|FAIL|SKIP",
  "verdict_note": "Pester manifest <p>/<t> + goldens 17/17 sin regresion + Test-Json spot-check True + Ajv-strict INFO <ok|warn>.",
  "review": { "status": "<4R-verdict>", "method": "code-review-agent 4R", "gaps": [] },
  "blockers": [],
  "next": ["R9-S2"],
  "auto_fix": false,
  "timestamp": "<date-time>"
}
```

```json
// .rdd/rdd-receipt-009.json (R9-S2)
{
  "id": "rdd-receipt-009",
  "freeze": "HEAD-<base7>-<diff8>",
  "freeze_note": "Slice R9-S2 <commit-msg> en rama experimento/mejora-ronda9-contratos-ci. diff8=<diff8> = working tree limpio al emitir el receipt (git diff vacio). lines_changed=<n> solo scope del slice.",
  "tier": 2,
  "tier_justification": "RDD Risk Tiers: Tier 2 = pipeline compartido .github/workflows/ci.yml (afecta todos los PRs) + badge publico README. Superficie de decision: workflow destino, paths Pester, filtro badge.",
  "files": [".github/workflows/ci.yml", "README.md"],
  "lines_changed": "<n>",
  "lines_deleted": 0,
  "verdict": "PASS|FAIL|SKIP",
  "verdict_note": "check-yaml PASS + actionlint <ok|na> + Pester Q2 local <p>/<t> + job contracts remoto <verde|pendiente> + badge renderiza.",
  "review": { "status": "<4R-verdict BLOCKER-capable>", "method": "code-review-agent 4R BLOCKER-capable", "gaps": [] },
  "escalation": "judgment-day",
  "blockers": [],
  "next": ["Ronda 10 (seccion 9)"],
  "auto_fix": false,
  "timestamp": "<date-time>"
}
```

## 7. Review Log (rellenado al ejecutar S1/S1b/S2)

| Slice | Reviewer/método | Veredicto | Fecha | Notas |
|---|---|---|---|---|
| R9-S1 | code-review-agent 4R + Pester | PASS (`d9ce9900`) | 2026-09-24 | `test(contracts): golden-manifest schema + gate sobre manifest real` (Tier 1, receipt-008). Schema 48L + test 78L; manifest 6/6 + Test-Json spot-check True. Drift pre-existente documentado (goldens 16/17 + receipt 7/8, fuera de scope S1). |
| R9-S1b (drift-fix, fuera de plan §3) | code-review-agent 4R + Pester full | PASS (`7544655c`) | 2026-09-24 | `fix(contracts): drift receipts 005-009 vs golden/test congelados en 001-004` (Tier 1, receipt-009). Pester 166/166 0 FAIL; golden regenerado incluye receipt-009 (no reintroduce drift). Slice extra no previsto; S2 lo toma como base. |
| R9-S2 | code-review-agent 4R BLOCKER-capable + Pester | PASS (este commit) | 2026-09-24 | `ci(contracts): job contracts en CI + badge README` (Tier 2, receipt-010). Job `contracts` en `ci.yml` (default §Q2, UNA ubicación, no duplicado en quality-gate.yml). Badge shields bajo línea 1 README. YAML validado (python yaml PASS; actionlint no instalado → pendiente honesto). Pester local 166/166 0 FAIL. Remoto pendiente (sin push por constraints). judgment-day no requerido (PASS directo, 0 BLOCKERs). |

## 8. Rollback (por slice, orden inverso)

- S2: `git revert <commit-S2>` o revertir manualmente el hunk del job `contracts` en `ci.yml` + quitar líneas de badge en `README.md`; re-correr `check-yaml` + Pester Q2 local (debe PASS sin el job).
- S1: `git revert <commit-S1>` o borrar `contracts/golden-manifest.schema.json` + `tests/contract-manifest.Tests.ps1`; re-correr `tests/contract-goldens.Tests.ps1` (debe seguir 17/17).
- Nunca `git reset --hard` sobre trabajo ajeno; nunca tocar `main`; el plan R8 (`odd/tasks/ronda8-contratos.md`) no se toca en ningún rollback.
- Reposo final: repo vuelve a HEAD `d4a3e13b` + este plan (uncommitted en Fase 1; commiteado por la ejecución después).

## 9. Para Ronda 10+ (resto declarado, fuera de R9 mínimo)

1. Ítem 2 secc.9 R8: schemas concepto-upstream `telemetry` y `review-integration` (solo si el repo los necesita de verdad; hoy no hay telemetría ni review-integration local que formalizar).
2. Ítem 3 secc.9 R8: declarar Ajv como devDependency formal o mantener vendored (decisión con dueño; hoy: no tocar `package.json`; R9-S1 la usa solo como INFO).
3. Ítem 5 secc.9 R8: goldens extra (`audit-check` completo, `registry build` ampliado a todos los skills, fixtures de error con mensajes canónicos).
4. Ítem 6 secc.9 R8: normalización de `verdict` histórico (`VERIFY_OK_FASTPATH` vs `SKIP` en receipts 001-004): decidir enum final y, si se migra, hacerlo como slice propio con re-validación (NO reescribir historia sin receipt).
5. Endurecimiento S2: `actionlint` como gate bloqueante, badge por job verificado en `main` post-merge, job `contracts` con `needs`/cache Pester si el tiempo Windows lo exige.

---
*Fase 1 completa: plan + freeze. Ejecución (S1→S2) en siguientes sesiones, 1 commit por slice, receipts 008/009.*
