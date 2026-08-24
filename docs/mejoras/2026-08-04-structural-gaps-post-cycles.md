# Análisis gentleman-agent-gh — 2026-08-04

**Pipeline**: analysis-mode 4-phase (4 audits read-only en paralelo: sec, infra, perf, docs) + validación P2 local.
**Disparador**: condición de parada §5 del experimento cumplida → búsqueda de gaps estructurales nuevos (post-Ciclo 9-10).
**Estado**: análisis completo — sin implementar, plan propuesto.

---

## Veredictos por audit

| Audit | Veredicto | Hallazgos |
|-------|-----------|-----------|
| Security (sec) | **PASS-WITH-NOTES** | SEC-5 incompleto en capa runtime, baseline global débil, 4 divergencias |
| Infraestructura (infra) | **PASS-WITH-NOTES** | 3 HIGH: pre-push neutralizado, write-scope sin cablear, e2e traga exit codes |
| Performance (perf) | **PASS-WITH-NOTES** | tokenize-all roto en runtime, benchmark mide existencia no validez |
| Docs/DX (docs) | **PASS-WITH-NOTES** | 7 HIGH "numbers that lie" en docs raíz; deliverables nuevos verificados exactos |
| UX / Frontend | **SKIPPED-frontend** | Sin UI (repo PowerShell/config/docs) |
| Data / Datascience | **SKIPPED-datascience** | Sin pipeline de datos |
| Arquitectura (main) | **PASS** | ADR-009 hybrid junction model verificado contra código (88 entradas = 78 junctions + 10 dirs reales, 0 dead) |
| Negocio (main) | **PASS-WITH-NOTES** | Parada §5 cumplida con valores medidos reales; pero la infraestructura de medición tiene agujeros de enforcement |

---

## Hallazgos por dimensión (evidencia file:line + confidence)

### Security

- **SEC-F1 (HIGH)** — SEC-5 incompleto en la capa que ENFORCEA: `git clean`/`git rm` solo en `permission-gate-lib.ps1:46`; **cero matches** en `permission-templates.json`, `shared-deny-rules.json` y `opencode.json`. En auto mode (`.gentleman-mode` = auto hoy), `git clean -fdx` / `git rm -r` caen en `"*": "allow"` → auto-aprueban sin ask, contradiciendo ADR-005 ("destructive → ask en auto"). Además `git checkout -- .` / `git restore` no listados en NINGUNA capa. `confidence: high`
- **SEC-F2 (HIGH artifact / medium impact)** — `sync-global.ps1:62` genera el baseline global `~/.config/opencode/opencode.jsonc` con `git push --force *` = **ask** (no deny) y SIN piso icm/iex/wsl/curl/node/python, con read-deny reducido (sin `.ssh`, `*.key`, `.kube`, `.config/gh`). Las fixes SEC-1/2 nunca se propagaron al deploy global. Ningún gate lo detecta (pre-commit [14/14] solo regenera el `opencode.json` del proyecto). Mitigado parcialmente por `Assert-SecurityFloor` en `use-gentleman.ps1` (restaura solo el piso shared, no force-push/`git clean`). `confidence: high`
- **SEC-F3 (MEDIUM)** — `git push -f` (flag corto) solo **ask** en la capa opencode: el lib lo deniega (`permission-gate-lib.ps1:40`) pero templates deniegan solo `"git push --force *"` → `git push -f` matchea `"git push *"` = ask en auto/semi (`opencode.json:12`, `permission-templates.json:69-71`). "Force-push siempre deny" solo vale para la forma larga. `confidence: high`
- **SEC-F4 (MEDIUM)** — Semi allowlist sobre-permisiva vs gate: `npm *` / `pip *` permitidos en templates (`permission-templates.json:162-163`); el lib restringe a `^npm (test|run|ci)` y `^pip (freeze|list|show|install --user)` (`permission-gate-lib.ps1:64-66`). `npm exec --yes <pkg>`, `npm install`, `pip install -e git+…` corren en semi sin ask. `confidence: high`
- **SEC-F5 (MEDIUM-LOW)** — Divergencia engram: `check-mcp-security.ps1:39` estima 18 (ADR-010 verificado) pero `opencode-base.json:224`, `sync-global.ps1:62`, `global-setup.ps1:127` pasan `--tools=` con exactamente **8** nombres. El check nunca parsea `--tools=` (tabla estática, `Get-EstimatedToolCount` :130-138). O la restricción es inefectiva (18 tools vivas, config muerta) o el check/ADR-010 sobreestiman. Requiere enumeración live para resolver. `confidence: medium`
- **SEC-F6 (LOW)** — `audit-log.ps1:73-75` strip CR/LF/comas de `Detail` pero no `=`, `+`, `-`, `@` iniciales → inyección de fórmula CSV si se abre en Excel. "Append-only" es convención (Add-Content sin tamper-evidence/ACL). `confidence: high` (mecánica) / `medium` (impacto)
- **Nuance**: SEC-1 (orden deny-after-ask en `opencode.json:12-13`) y SEC-2 (icm/iex/wsl en los 3 artefactos SSoT + config generada) verificados OK. `leak-guard.ps1` decoupled (solo self-reference) pero el scan live está en pre-commit-gate [10/13] (`pre-commit-gate.ps1:125-145`) — más fuerte, sin gap. Scripts del experimento limpios (benchmark solo lee + snapshot; e2e pasa argv sin interpolación; validate-write-scope bloquea `BaseRef` con espacios; health-check valida `LinkType` antes de `Remove-Item`; `-DryRun` es no-op silencioso — cosmético). Blind spot arquitectónico por diseño: deny-by-prefix no clasifica llamadas internas de un wrapper (p.ej. `e2e-test.ps1` invoca `node` internamente).

### Infraestructura

- **INFRA-I1 (HIGH, verificado)** — INFRA-1 SSoT gate **funciona**: `core.hooksPath=.githooks` → `.githooks/pre-commit:12` → `pre-commit-gate.ps1`; check 14/14 (`pre-commit-gate.ps1:192-198`) dispara en staged `scripts/lib/*` u `opencode.json`, corre `regenerate-opencode.ps1 -Quiet` (validate-only, `:78-83`) → `generate-opencode-config.js --validate` (byte-exact tras normalización BOM/CRLF/trailing-newline, exit 1 en diff, `:201-250`). Test live: exit 0 "in sync". Los 3 inputs SSoT viven en `scripts/lib/` → cubiertos. `confidence: high`
- **INFRA-I2 (MEDIUM)** — El modelo junction matchea ADR-009 (88 = 78 + 10 reales), pero el junction de prompts (Check 2, `health-check.ps1:211-215`) devuelve **WARN con exit 0** (exists-but-not-junction / target-mismatch), mientras `Repair-Junction`/`Test-Junction` (`:66-92,129-138`) escalan FAIL→exit 2. Además el cache de 1h (`:40-57`) sirve "ALL OK" durante una hora. Un junction degradado de prompts es invisible a `check.ps1`/exit codes. `confidence: high`
- **INFRA-I3 (MEDIUM)** — Benchmark 78/78 real (contado contra disco: repo=78, junctions=78, dead=0), pero CI corre `benchmark.ps1 -Snapshot` **sin `-Gate`** (`quality-gate.yml:186-187`) → nunca falla por regresión; gate mode solo local (pre-commit [8/13]). `LATEST_benchmark.json` es baseline móvil sobrescrito por cada snapshot (`benchmark.ps1:24`); `bench-compare.ps1:7` es one-shot estático vs backup fechado 2026-06-07, no herramienta de tendencia. Sin agregación time-series de snapshots timestamped. `confidence: high`
- **INFRA-I4 (HIGH)** — `validate-write-scope.ps1` funciona (spot-check `-AllowedPaths "scripts/*"` → CLEAN, exit 0; tests unit+integración existen) pero **cero invocaciones** en `.githooks/`, `.github/`, `check.ps1` — solo sus propios tests lo referencian. Enforcement de write-scope es manual-only; nada lo llama post-delegación. `confidence: high`
- **INFRA-I5 (HIGH)** — `.githooks/pre-push:23-26` early-exit cuando `git diff --cached --quiet` — que es **siempre true justo después de un commit** (index==HEAD), **incluyendo commits `--no-verify`**. Su propósito declarado ("catch issues que `--no-verify` bypasseó", `:44`) queda derrotado: la segunda línea de defensa nunca corre en el flujo normal. Single gate (pre-commit) es el único enforcement; bypass `--no-verify` → push limpio. `confidence: high`
- **INFRA-I6 (HIGH)** — `e2e-test.ps1:102-107` usa `& node @nodeArgs` en try/catch **sin `exit $LASTEXITCODE`** (PS no lanza en exit code nativo ≠ 0; `$PSNativeCommandUseErrorActionPreference` no seteado). Cualquier fallo de Playwright **sale con exit 0** → el script no puede fallar un gate/CI. (Distinto del suite `_e2e_pipeline.Tests.ps1`, que es assertions estáticas de presencia — verifica que el gate *contenga* [14/14], no que bloquee.) `confidence: high`
- **Nuance**: INFRA-2 **persiste (HIGH)**: `-MaxBytes 65536` solo se chequea en write mode (`regenerate-opencode.ps1:108`); CI validate + pre-commit 14/14 nunca chequean tamaño; solo `check-added-large-files --maxkb=500`. `opencode.json` ya es **52,206 B = 80% del budget**. Dual gate systems: `.pre-commit-config.yaml` overrideado localmente por `core.hooksPath=.githooks`; el framework corre en CI como subset explícito (`quality-gate.yml:144`) — duplicación de mantenimiento, drift risk bajo. Pasos CI vacuos: `check-skill-drift.ps1:30-36` SKIP (exit 0) sin config global; `verify.ps1:95-101` pasa "Global Junctions" silenciosamente y chequea existencia, no `LinkType` (más débil que health-check). INFRA-3 consistente (engram=18, ADR-010). `check-config-drift.ps1` y `check-backlog-integrity.ps1` manual-only; config-drift usa hashes JSON order-sensitive (`:44-49`) vs generator determinista → posible DRIFT falso si el global se edita a mano.

### Performance

- **PERF-P1 (HIGH)** — `tokenize-all.ps1:48` usa `ForEach-Object { … } -ThrottleLimit 5` **sin `-Parallel`** → error live *"A positional parameter cannot be found"* antes de emitir filas. `.SYNOPSIS` afirma "parallel python subprocess" pero ningún skill se tokeniza jamás; el fallback chars/3.5 es inalcanzable. Es el único contador tiktoken-accurate y **nunca corrió** (intacto desde 2026-07-31). Fix: `-Parallel` + scoping `$using:`. `confidence: high`
- **PERF-P2 (HIGH mecánica / medium impacto)** — La métrica junction del benchmark prueba **existencia, no validez**: `benchmark.ps1:11` incrementa `$jo` solo con `LinkType -in @("Junction","SymbolicLink")`; nunca verifica que `Target` exista/matche (health-check.ps1:76-85,170 hace ambos). Un junction con target borrado → 78/78 PASS en benchmark mientras health-check lo flaggea. Recomendación: `-Gate` debe comparar contra `$jo` con validación de target, o surface dead-junction count. `confidence: high` (mecánica)
- **PERF-P3 (HIGH / impacto bajo)** — `health-check.ps1:151-156` (Check 1) enumera global+repo y arma `$globalByName`; `:192-195` (Check 3) **re-enumera ambos** y llama `Get-Item $e.FullName -Force` (líneas 154, 195) aunque `Get-ChildItem -Force -Directory` ya popula `LinkType`/`Target`. No O(n²) (lookups O(1)) pero ~2× IO en ~88+79 entradas ≈ ms. Reusar `$globalByName`/`$repoSkills` en ambos checks. `confidence: high`
- **PERF-P4 (MEDIUM)** — El benchmark no tiene baseline de timing ni tokens: `benchmark.ps1:15` `system` = bytes/lines/junctions; `benchmarks.md:28-39` filas C1-C9 sin columna de timing → la dimensión perf del experimento no está medida (702 tests: runtime no registrado en ningún lado). Peor: `benchmark.ps1:24` sobrescribe `LATEST_benchmark.json` en cada `-Snapshot` y `-Gate` (:29) compara contra ese LATEST — un snapshot post-spike re-baselinea el gate silenciosamente. `confidence: medium`
- **PERF-P5 (HIGH patrón / low impacto)** — `token-count.ps1:59-65` `$results += [PSCustomObject]` reasigna el array por iteración (cuadrático en `-Recurse`; negligible en 78 archivos / 0.32s). Y los dos tools token divergen en heurística: chars/4 (`token-count.ps1:31`) vs chars/3.5 (`tokenize-all.ps1:35`) → el mismo archivo da estimaciones distintas según tool. Fix: `[List[object]]::new()`; reconciliar divisor. `confidence: high`
- **Nuance**: PERF-1 **no re-reportado**: `opencode.json` = 52,206 B hoy, byte-idéntico al audit 08-03 y a `benchmarks.md:37,59` + ADR-007 (budget 65,536 B) — duplicación NO creció, won't-fix sostiene. Hybrid junction: **sin riesgo perf** (modelo 78+10, scan O(n) n≈88, ms). `benchmark.ps1 -Gate` estable 2.08s; metodología sólida (métricas deterministas byte/line/regex, pin git HEAD). `run-tests.ps1` bien formado (Pester 5/6 `Run.Parallel` :79, module discovery filtrado :50); solo falta wall-time del suite (PERF-P4). `build-skill-registry.ps1` eficiente (78 files, 1 raw read + regex, hashtables O(1); `$triggerIndex[$trigger] += $name` :107 micro-append). `skill-graph.ps1` trivial en 80 nodos. `cache.ps1` full-file RMW por set (:34-41) OK para 1 key; TTL 1h correcto.

### Docs / DX

- **DOCS-D1 (HIGH)** — `QUICKSTART.md:118`: "Explore skills … (92 available)". Real = **79** (79 SKILL.md − `_shared`). El commit d9da66e2 corrigió la intro (L11: 92→79) pero **se le escapó esta línea**. `confidence: high`
- **DOCS-D2 (HIGH)** — `README.md:18,151,190`: "123 PowerShell scripts". Real = **83 top-level** (per `benchmark.ps1:9`; snapshot `ScriptsCount: 83`) o 131 recursivo — ninguno es 123. Contradice el SSoT del propio repo. `confidence: high`
- **DOCS-D3 (HIGH)** — `CYCLE.md:43`: "current: avg 1.8KB, 0 >3KB ✓". Real avg = **2,516B/2.5KB** (`benchmarks.md:53`, `SUMMARY.md:15`, snapshot `AvgSkillBytes: 2516`). Además `CYCLE.md:21` backlog item 5 marcado "🔴 Pending" aunque su criterio de done ("0 skills >3KB") ya se cumple (`SkillsOver3kb: 0`) → Backlog Integrity drift. `confidence: high`
- **DOCS-D4 (HIGH)** — `CYCLE.md:167-168`: `docs/ciclos/cycle-archive-6-17.md` **no existe** (dead link); la línea 168 asigna "Cycles 18-26" al mismo filename 6-17 (copy-paste). `confidence: high`
- **DOCS-D5 (HIGH)** — `docs/mejoras/README.md:20` referencia `archived/` que **no existe** (0 dirs archivados); L18,27 afirman PERFORMANCE-PLAN "partial (2/9 done)" vs L39 "9/9 complete" vs `PERFORMANCE-PLAN.md:79` "Todos los items completados (P0-1..3, P1-1..3, P2-1..3)" — contradicción interna. TOC indexa 9 de 18 .md presentes (omite el análisis 08-03, token-context, cycle28, 07-30×3, 08-01×2). `confidence: high`
- **DOCS-D6 (HIGH)** — `BITACORA.md`: DOCS-1 item 4 **NO arreglado**: L153-160 cola out-of-order con near-duplicados (L2/L4 "Cierre experimento"; L23/L24 limit-key) y **fila de tabla suelta en L159** (`| 2026-07-30 | orchestrated analysis | … |`). Mojibake (UTF-8 doble-encodificado) en L57,60,66,77,82,87,91,97,98,111,131,132,142,148. `confidence: high` (dupes) / `medium` (mojibake)
- **DOCS-D7 (HIGH)** — `README.md:113`: "SDD Pipeline … **8 complete phases**: init → propose → spec → design → …". Real = **9 fases** (`.agents/skills/sdd/phases/` 00-init…08-archive, incl. explore; orden design→spec) y la propia tabla de 9 agentes del README (L66-78) lista `sdd-explore`. `confidence: high`
- **Nuance**: DOCS-1 ~4/5 resuelto — PROTOCOL auto row **fixed** (d9da66e2; `PROTOCOL.md:15` "deletes (ASK)", mode-governed desde C7); README index **fixed** (37 agentes, L30/66-78); QUICKSTART count **fixed** (L9); `limit.input` **fixed** (bloque de corrección en `docs/mejoras/2026-07-29-gentleman-agent-gh-token-context-analysis.md:9`, commit 598746e2). **Solo BITACORA queda**. Deliverables nuevos **verificados exactos**: benchmarks.md matchea el snapshot JSON byte a byte (78 skills, 196,262 B, 4,576 líneas, 2,516B avg, Junctions 78/78, Scripts 83, commit 535a87f7) — sin contradicciones benchmark-vs-scripts. ADR index (11 files) matchea disco. RUNBOOK: 4 refs de scripts existen. DX-4 **resuelto**: SKILLS-INDEX v5.2 (78 project = 79−_shared ✓; 87 global = 88 dirs−_shared ✓; "165 discoverable" ✓) — el formato compacto ya no enumera cada skill, el viejo gap 9-dead/13-missing es moot. Menores: score drift — README:21 & CYCLE:9 dicen "9.1/10" pero `.project.json` (2026-08-03) = **9.3**; `SUMMARY.md:24-29` "Quality Gate (2026-06-26) 9/9" stale vs 14/14 (`SUMMARY.md:20`, `benchmarks.md:52`).

---

## Síntesis P3

| # | Finding | Consensus | Risk | Files | Recomendación |
|---|---------|-----------|------|-------|---------------|
| 1 | SEC-5 incompleto en capa runtime: `git clean`/`git rm` (y `git checkout -- .`/`git restore`) auto-aprueban en auto | OUTLIER (sec) | **CRÍTICO** | permission-templates.json, shared-deny-rules.json, opencode.json | Añadir al SSoT + shared-deny-rules + regenerar opencode.json |
| 2 | pre-push hook self-neutraliza: early-exit siempre true post-commit → `--no-verify` bypassea sin detección | OUTLIER (infra) | **ALTO** | .githooks/pre-push:23-26 | Comparar contra remote (no `--cached`) o mover enforcement a pre-commit + CI |
| 3 | validate-write-scope funciona pero **unwired** — cero invocaciones | OUTLIER (infra) | **ALTO** | scripts/validate-write-scope.ps1, .githooks/, .github/ | Cablear en pre-commit gate con allowed_paths del contrato de delegación |
| 4 | e2e-test.ps1 traga exit codes → la suite no puede fallar un gate | OUTLIER (infra) | **ALTO** | scripts/e2e-test.ps1:102-107 | `exit $LASTEXITCODE` / `$PSNativeCommandUseErrorActionPreference=$true` |
| 5 | sync-global.ps1 despliega baseline de seguridad más débil (force-push=ask, sin piso icm/iex/wsl, read-deny reducido) | OUTLIER (sec) | **ALTO** | scripts/sync-global.ps1:62 | Propagar fixes SEC-1/2 al deploy global; cablear check-config-drift |
| 6 | 7 docs "numbers that lie" (92→79, 123→83, 1.8KB→2.5KB, 8→9 fases, dead links, BITACORA dups+mojibake, mejoras TOC 9/18) | OUTLIER (docs) | **ALTO** (trust) | QUICKSTART.md:118, README.md:18,151,190,113, CYCLE.md:21,43,167-168, BITACORA.md, docs/mejoras/README.md | Corregir contra SSoT benchmark/.project.json; wire check-backlog-integrity al gate |
| 7 | tokenize-all.ps1 roto en runtime (sin `-Parallel`) — único contador tiktoken-accurate nunca corrió | OUTLIER (perf) | **MEDIO** | scripts/tokenize-all.ps1:48 | `-Parallel` + `$using:` |
| 8 | Benchmark: baseline móvil (LATEST sobrescrito), -Gate ausente en CI, sin trend ni timing/tokens | **MAJORITY** (infra+perf) | **MEDIO** | benchmark.ps1:24,29, bench-compare.ps1:7, quality-gate.yml:186-187 | Pinear gate a snapshot fechado; -Gate en CI; agregación time-series; métricas timing+tokens |
| 9 | Métrica junction del benchmark = existencia, no validez → dangling junction da 78/78 | OUTLIER (perf, corroborado infra) | **MEDIO** | benchmark.ps1:11 | Validar Target en `-Gate` o surface dead-junctions |
| 10 | `git push -f` corto solo ask; semi `npm *`/`pip *` sobre-permisivos vs lib | OUTLIER (sec) | **MEDIO** | permission-templates.json:69-71,162-163 | Deny template para `-f`; estrechar semi al set del lib |
| 11 | Junction de prompts WARN con exit 0 + cache 1h "ALL OK" | OUTLIER (infra) | **MEDIO** | health-check.ps1:211-215,40-57 | WARN→exit 1; invalidar cache en cambio de junction |
| 12 | engram tool-count: check=18 vs config `--tools=`=8 — una de las dos miente | OUTLIER (sec) | **MEDIO** | check-mcp-security.ps1:39, opencode-base.json:224 | Enumeración live de tools para resolver |
| 13 | INFRA-2 persiste: size budget 80% usado (52,206/65,536 B), solo chequeado en write mode | OUTLIER (infra) | **MEDIO** | regenerate-opencode.ps1:108 | Chequear tamaño en CI validate + pre-commit |
| 14 | audit-log CSV formula injection + append-only convención; `-DryRun` no-op | OUTLIER (sec) | **BAJO** | audit-log.ps1:73-75, health-check.ps1 | Sanitizar `=+-@`; hardening mínimo |
| 15 | health-check 2× enumeración; token-count O(n²) + chars/4 vs 3.5 | OUTLIER (perf) | **BAJO** | health-check.ps1:151-195, token-count.ps1:59-65 | Reusar hashtables; `[List[object]]`; reconciliar divisor |

**UNANIMOUS**: ninguno. **MAJORITY**: benchmark baseline (#8, infra+perf). **OUTLIER**: resto por dimensión.

---

## Risk Matrix (top)

| Severity | Count | Items |
|----------|-------|-------|
| CRÍTICO | 1 | #1 (destructivos auto-aprueban en auto mode) |
| ALTO | 5 | #2 #3 #4 #5 #6 |
| MEDIO | 7 | #7 #8 #9 #10 #11 #12 #13 |
| BAJO | 2 | #14 #15 |

---

## Recomendaciones priorizadas (P4 → plan)

**Fase 1 — Enforcement (cubre los 4 HIGH de gates, R1-R5):**
1. R1: SSoT `permission-templates.json` + `shared-deny-rules.json` += `git clean`, `git rm`, `git checkout --`, `git restore` como destructivos (deny manual/semi, ask auto) → `regenerate-opencode.ps1 -Yes`. Tests Pester.
2. R2: `.githooks/pre-push:23-26` — reemplazar condición `git diff --cached --quiet` por comparación contra el remote (p.ej. `git rev-list --count HEAD..@{u}` + verificar commit no firmado/verificado), o eliminar el gate pre-push y consolidar en pre-commit + CI (evitar doble sistema, infra nuance).
3. R3: cablear `validate-write-scope.ps1` en el pre-commit gate (allowed_paths desde el contrato de delegación; fallback repo-wide).
4. R4: `e2e-test.ps1` — `$PSNativeCommandUseErrorActionPreference = $true` o `exit $LASTEXITCODE` tras `& node`; verificar con un test que fuerza fallo.
5. R5: `sync-global.ps1:62` — portar el piso deny completo (force-push deny, icm/iex/wsl, read-deny `.ssh`/`*.key`/`.kube`/`.config/gh`); cablear `check-config-drift.ps1` en CI.

**Fase 2 — Medición honesta (R6-R9):**
6. R6 (MAJORITY): benchmark gate pineado a snapshot fechado (no LATEST móvil); `-Gate` en CI; `bench-compare` → agregación time-series; añadir suite wall-time + token totals como métricas de tendencia.
7. R7: `tokenize-all.ps1` `-Parallel` + `$using:`; reconciliar divisor chars/4 vs 3.5.
8. R8: benchmark junction metric — validar `Target` en `-Gate` o reportar dead-junction count.
9. R9: `health-check.ps1` Check 2 (prompts) WARN→exit 1; invalidar cache 1h ante cambio de junction.

**Fase 3 — Higiene docs (R10, manual-friendly):**
10. R10: corregir D1-D7 contra SSoT (benchmark snapshot, `.project.json` 9.3, 83 scripts, 79 skills, 9 fases SDD); limpiar BITACORA (dups, fila suelta L159, mojibake 14 líneas); TOC mejoras completo; wire `check-backlog-integrity.ps1` (habría capturado el drift de CYCLE.md:21).

---

## Estado de parada §5 — nota del experimento

La condición de parada se **cumplió con valores medidos reales** (78/78 verificado contra disco, e2e 100%, benchmark estable 2.08s, breaker ≥3 ataques). Los hallazgos I4/I5/I6 no invalidan el verde del experimento — los números medidos son ciertos — pero **degradan la confianza en la medición de ciclos futuros**: la suite E2E no puede fallar un gate (I6), el write-scope no se enforcea post-delegación (I4) y el pre-push es muerto (I5). R2-R4 son prerequisito antes de que el próximo experimento confíe en E2E/benchmark como gates.

---

## Engram Persistence

- **mem_save**: title=`analysis:gentleman-agent-gh:2026-08-04`, type=architecture, topic_key=`analysis/gentleman-agent-gh`
- **Previo en topic**: #2252 (2026-07-31 tests perf), #2014 (2026-08-01 globalización)

## Trend Analysis (vs 2026-08-03)

**Arreglado (verificado)**: SEC-1 (orden deny-after-ask) · SEC-2 (piso icm/iex/wsl en los 3 artefactos) · SEC-5 capa lib · INFRA-1 (SSoT gate 14/14 live exit 0) · INFRA-3 (engram=18 consistente con ADR-010) · DX-1 (trigger parser quoted/bare/inline) · DX-2 (`_shared` description) · DX-3 (sin mojibake en skills) · DX-4 (SKILLS-INDEX v5.2 exacto) · DOCS-1 4/5 (PROTOCOL auto row, README index, QUICKSTART count, `limit.input`).
**Regresión**: pre-push hook (I5) — su propósito (detectar bypass `--no-verify`) ahora derrotado por su propio early-exit.
**Pendiente arrastrado**: DOCS-1 item 4 (BITACORA dups + mojibake) · INFRA-2 (size budget, 80% usado).
**Nuevo**: 15 findings (5 crítico/alto enforcement, benchmark gate, tokenize-all roto, 7 docs "numbers that lie").

---

**Gate**: análisis read-only completo. Sin código modificado. Sin commit (decisión del usuario).

---

## Fase 1 — Estado de implementación (R1-R5)

**Estado: COMPLETADO** — commit `92f848aa` (gate 16/16 ALL CLEAR, suite 705/706, 0 failed).

| # | Hallazgo | Implementación | Verificación |
|---|----------|----------------|--------------|
| R1 | SEC-F1 destructive-git | `permission-templates.json` + `shared-deny-rules.json` += `git checkout --`/`git clean`/`git restore`/`git rm` (deny manual/semi, ask auto); `permission-gate-lib.ps1` destructivePatterns; `regenerate-opencode.ps1 -Yes` | grep 3 artefactos OK; permission-gate.Tests 77/77 (4 nuevos casos) |
| R2 | INFRA-I5 pre-push muerto | Early-exit `git diff --cached --quiet` → comparación `HEAD..@{u}` fail-safe (sin early-exit cuando hay commits nuevos o no hay upstream) | hook ejecutado: "New commits vs upstream — running quality gate" |
| R3 | INFRA-I6 write-scope | Check [15/15] opt-in vía `.gentleman/write-scope.json` (ausente = pass); `validate-write-scope.ps1 -Staged` | Violación → exit 1 BLOCKING; allow → exit 0; ausente → pass |
| R4 | INFRA-I4 e2e exit | `$PSNativeCommandUseErrorActionPreference = $true` + `exit $LASTEXITCODE` | node fail → script exit 1 |
| R5 | SEC-F2 piso deny global | `sync-global.ps1:62` porta shared-deny-rules completo (61 reglas) + read-deny `.ssh`/`*.key`/`.env`/`secrets` | DryRun OK; merge lógico verificado |

**Desviaciones documentadas (según plan: "pick the safe option and document it")**:
1. **R5 wiring check-config-drift**: NO en CI (runner sin config global → falso drift en cada run, estructuralmente inseguro). En su lugar: check [16/16] en pre-commit gate, solo cuando existe config global (`$env:USERPROFILE\.config\opencode\opencode.json(c)`). CI runners saltan.
2. **R2**: se eligió la opción "reemplazar condición" del plan (comparación vs upstream) en lugar de eliminar el gate pre-push — se mantiene como segunda línea de defensa.
3. **R3**: `allowed_paths` desde `.gentleman/write-scope.json` (ausente = no restricción, baseline 14/14 intacto); fallback repo-wide NO implementado (requiere contrato de delegación, Fase 2).

**Prerequisito no cerrado**: ejecutar `scripts/sync-global.ps1` (con `-Force`) para propagar el piso deny a la config global — el gate [16/16] seguirá advirtiendo drift hasta hacerlo.
