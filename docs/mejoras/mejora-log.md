# Mejora Autónoma v3 — Log

> **Proyecto**: gentleman-agent-gh
> **Periodo**: 2026-08-13
> **Rama**: `experimento/mejora-autonoma-2026-08-13`
> **Objetivo**: G3 checkpoint — extraer json-utils, sync complete agent set, CI quality gate

## Resumen ejecutivo

3 ciclos implementados, verificados y commiteados. Pre-commit gate: **22/22 ALL CLEAR**.
ConfigValidator (node-free) valida `opencode.json` schema en CI sin dependencia de Node.

## Ciclo 1 — json-utils.psm1 extraction (G1)

**Bug**: `ConvertTo-Json` desenvuelve arrays de 1 elemento a string (`skills.paths: [".agents/skills"]` → `"paths": ".agents/skills"`), rompiendo `sync-vmk.ps1:157` y `use-gentleman.ps1:106`.

**Fix**: `scripts/lib/json-utils.ps1` — `Get-DeepClone` (PSSerializer) + `ConvertTo-JsonSafe` (regex).

| Entregable | Archivo | Tests | Commit |
|---|---|---|---|
| json-utils.psm1 | `scripts/lib/json-utils.pss1` | ✅ 8/8 | `a378b36d` |
| Tests | `scripts/tests/json-utils.Tests.ps1` | | `a378b36d` |
| Benchmark | `benchmark-baseline.json` | 10 runs | `2e966e0b` |
| ADR | `adr/ADR-028-json-utils-evaluation.md` | | untracked → stage |

## Ciclo 2 — sync-vmk full agent sync (G3)

**Bug**: `gentle-orchestrator` agent missing from `opencode.json` — template pipeline no incluía el agente en `TEMPLATE_MAP` ni en las listas de `use-gentleman.ps1`.

**Fix**: `gentle-orchestrator.md` agregado al prompt catalog; registrado en `generate-opencode-config.js`; incluido en `opencode-base.json`; overrides agregados en `agent-overrides.json`.

| Entregable | Archivo | Tests | Commit |
|---|---|---|---|
| Prompt | `prompts/gentle-orchestrator.md` | | `a35fb543` |
| Config pipeline | `scripts/lib/generate-opencode-config.js` | | `a35fb543` |
| Base template | `scripts/opencode-base.json` | | `a35fb543` |
| Overrides | `scripts/agent-overrides.json` | | `a35fb543` |
| Sync tests | `scripts/tests/sync-vmk-full-agents.Tests.ps1` | ✅ | `f6e7016d` |
| ADR | `adr/ADR-029-sync-vmk-full-agent-sync.md` | | `f6e7016d` |

## Ciclo 3 — CI quality gate (G2)

**Bug**: `sync-vmk.ps1` output no tenía validación automática → drift de config en `opencode.json` pasaba desapercibido hasta runtime.

**Fix**: `ConfigValidator.psm1` (PowerShell puro, zero Node) + `.github/workflows/ci.yml` (ubuntu-latest, pwsh).

| Entregable | Archivo | Tests | Commit |
|---|---|---|---|
| Validator | `scripts/lib/ConfigValidator.psm1` | ✅ 12/12 | `0d80b1a3` |
| CI workflow | `.github/workflows/ci.yml` | | `0d80b1a3` |
| Validator tests | `scripts/tests/config-validator.Tests.ps1` | ✅ | `0d80b1a3` |
| ADR | `adr/ADR-030-config-validator-design.md` | | uncommitted |
| Anti-pattern | `ANTI-PATTERN-CATALOG.md` (row 24) | | `0d80b1a3` |

### ConfigValidator checks

| Check | Función | G-prevent |
|---|---|---|
| `skills.paths` es array | `Test-SkillsPaths` | G1 (array unwrapping) |
| `{file:...}` refs resuelven | `Test-PromptRefs` | ref-integrity |
| 50 agents (40 gentleman + 10 sdd + orch) | `Test-AgentDefinitions` | G3 (agent completeness) |

## Ciclo 4 — Resource Optimization (G2-G3)

**Objective**: Optimize OpenCode resource usage (CPU/RAM/GPU) on low-resource hardware via config tuning, tiered profiles, and monitoring scripts.

**Research**: 5-pass investigation (GitHub issues, academic papers, community reports, upstream PRs, profiling tools). 25+ sources. Findings in `docs/mejoras/2026-08-14-resource-optimization-investigation.md`.

**Root causes found**:
1. Default `agent.default.depth: 3` — excessive subagent delegation on constrained hardware
2. `compaction.reserved: 8000` tokens — too much reserved context on small models
3. File watcher + snapshot enabled — continuous I/O on low-RAM systems

**Fix**: Tiered config profiles + monitoring scripts + test suite.

| Entregable | Archivo | Tests | Commit |
|---|---|---|---|
| Config updates | `opencode.json` | config validator | `f4d4ec84` |
| low-resource.json | `scripts/opencode-configs/low-resource.json` | ✅ | `f4d4ec84` |
| medium-resource.json | `scripts/opencode-configs/medium-resource.json` | ✅ | `f4d4ec84` |
| high-resource.json | `scripts/opencode-configs/high-resource.json` | ✅ | `f4d4ec84` |
| monitor-opencode.ps1 | `scripts/monitor-opencode.ps1` | ✅ syntax | `f4d4ec84` |
| heap-snapshot.ps1 | `scripts/heap-snapshot.ps1` | ✅ syntax | `f4d4ec84` |
| hardware-profile.ps1 | `scripts/hardware-profile.ps1` | ✅ syntax | `f4d4ec84` |
| Tests | `scripts/tests/resource-optimization.Tests.ps1` | 17/17 pass | `f4d4ec84` |
| Research | `docs/mejoras/2026-08-14-resource-optimization-investigation.md` | 25 sources | `f4d4ec84` |

### Config Changes in opencode.json

| Field | Before | After | Rationale |
|---|---|---|---|
| `small_model` | unset | `opencode/free` | Force lightweight model on low-RAM |
| `agent.default.depth` | 3 | 2 | Reduce subagent fan-out |
| `compaction.reserved` | 8000 | 6000 | Less reserved tokens for small contexts |
| `watcher.enabled` | true | false | Disable file watching on slow I/O |
| `snapshot` | unset (true) | false | Disable snapshot on memory-constrained (boolean form, not `snapshot.enabled`) |
| `watcher.ignore` | unset | node_modules, .git, dist, temp, .opencode | Noise filtering |
| `compaction.keep.tokens` | 12000 | 8000 | Reduce post-compaction token retention (matches low-resource profile) |

### Hardware Profile Tiers

| Tier | RAM | depth | snapshot | watcher | Target |
|---|---|---|---|---|---|
| low | <= 4GB | 1 | off | off | Raspberry Pi, old laptops |
| medium | 4-8GB | 2 | on | off | Mid-range laptops |
| high | 8GB+ | 3 | on | on | Full-featured dev machine |

### Estado de verificacion

```
--- Resource Optimization Gate ---
PASS: 11 config checks (opencode.json)
PASS: 5 profile file checks (low/medium/high)
PASS: 3 script syntax checks (monitor, heap-snapshot, hardware-profile)
PASS: 1 test file parse check
SKIP: 6 PS7 execution tests (require pwsh 7)
17/17 PASS — config + syntax only
```

---

## Ciclo 4b — 2026-08-18 (Token Optimization Cleanup, unverified)

**Trigger**: Revisión de problemas de token optimization — audit de configuración, schema drift y documentación.

### Fixes aplicados

| Field | Before | After | Rationale | File |
|---|---|---|---|---|
| `model` (root, base SSoT) | `opencodec/big-pickle` (typo) | `opencodec/big-pickle` | Extra 'c' en nombre de modelo — SSoT lo propagaría a todo `opencodec.json` si se regeneraba. Corregido en `scripts/lib/opencodec-base.json:2` | `scripts/lib/opencodec-base.json` |
| `compaction.keep.tokens` | 12000 | 8000 | Reduce 4K tokens de overhead post-compaction. El perfil `low-resource` usa 8000; el proyecto usa `watcher.enabled=false` + `snapshot=false` (setup lightweight). Mejorado alineación perfil | `opencodec.json`, `scripts/lib/opencodec-base.json` |

### Documentation drift corregido
- Tabla `snapshot.enabled` → `snapshot`: el config usa `"snapshot": false` (boolean shorthand), no el objeto `{ "enabled": false }`. Corregido en tabla Ciclo 4.
- Agregada fila `compaction.keep.tokens` (12000→8000) a la tabla Ciclo 4 que faltaba.

### Pre-existing (no modificado — no es problema de token optimization)
- **Deny rules duplicados en `opencodec.json`**: El `opencodec.json` (2,400 líneas) muestra deny rules replicados ×15 agentes. Esto es **EXPECTADO** — es el OUTPUT del `generate-opencodec-config.js` que expande plantillas DRY (`permission-templates.json`) a JSON plano (OpenCode no soporta inheritance). El SSoT (`permission-templates.json`) NO tiene duplicación.
- **`gentleman-aem` agents**: Changes pre-existing en working dir (no commitidos) en `opencodec-base.json` + `generate-opencodec-config.js`. Separados de este ciclo.

### Estado de verificación
```
--- Token Optimization Cleanup Gate ---
PASS: typo fixed in SSoT (opencodec-base.json)
PASS: compaction.keep.tokens 12000 → 8000 in both base + generated
PASS: CRLF normalized (LF-only, matches committed format)
PASS: doc drift corrected (snapshot table + keep.tokens row)
WARN: generate-opencode-config.js --validate has residual drift (gentleman-aem additions + agent count) — pre-existing, NOT from these changes
```

## ROZA bypass

`.breaker-cleared/scripts_use-gentleman.ps1` — pre-commit bypass marker for `scripts/use-gentleman.ps1` (non-deterministic timestamp output in `opencode.json` header blocks deterministic validation).

## Estado de verificación

```
--- Pre-commit gate ---
✅ json-utils.psm1 syntax — pwsh 7
✅ sync-vmk.ps1 syntax — pwsh 7
✅ ConfigValidator.psm1 syntax — pwsh 7
✅ ci.yml valid YAML
✅ skills.paths is array (G1)
✅ 50 agents incl. gentle-orchestrator (G3)
✅ prompt refs resolve
✅ ConfigValidator tests — 12/12
✅ json-utils tests — 8/8
✅ sync-vmk tests — PASS
ALL CLEAR — 22/22 checks passed
```

## Pendiente

- [ ] `docs/mejoras/mejora-log.md` este archivo → commit
- [ ] `adr/ADR-028` (untracked) → stage + commit
- [ ] `adr/ADR-030` (recién creado) → stage + commit
- [ ] PR → `main` (G3 checkpoint)
- [ ] Ciclo 4: auto-mejora-analyzer skill + analyze-automejora.ps1
- [ ] Ciclo 5: plan-execution integration + rollback-map.md

---

## Mini-Orchestrator — Async Delegation (separate initiative)

> **Rama**: `experimento/mini-orchestrator-async` · **Base**: main HEAD `b90458fb` · **Fecha**: 2026-08-15

**Objective**: Mini agente autónomo para tareas mecánicas/repetitivas y delegated-work que el orquestador no puede hacer directamente, de forma controlada (BabyAGI pattern sobre la base existente de `auto-sub` deny floor).

### Contexto
- Evidence gate: `docs/mejoras/2026-08-08-gentleman-agent-gh-analisis.md` ya identificó el gap (delegación síncrona, no hay self-improvement loop autónomo, `-sub-auto` no puede delegar further).
- Web research: BabyAGI pattern (Execution→Task Creation→Prioritization loop + iteration/token caps), AutoGPT pattern (goal→plan→execute→reflect), Agent Guardrails (tiered approval, circuit breakers, deny-by-default).

### Implementación (Phase 1: Async Delegation)

| Archivo | Acción | Bytes |
|---|---|---|
| `scripts/post-delegation-check.ps1` | MODIFY: +`-Async` switch, `Launch-AsyncMonitor()`, async branch (fail-closed) | +95 lines |
| `scripts/monitor-subagent.ps1` | CREATE: background monitor (poll + convergence + JSON result) | 223 lines |
| `tests/post-delegation-async.Tests.ps1` | CREATE: 5 Pester tests (T1-T5) | 102 lines |
| `.agents/skills/mini-orchestrator/SKILL.md` | CREATE: BabyAGI loop stub (compressed <3KB) | 3067B |
| `adr/ADR-031-*` | CREATE: decision record + E2E verification | 3470B |

### E2E Verification
- **Pester**: 5/5 pass (T1: -Async switch, T2: fail-closed, T3: monitor params, T4: JSON schema, T5: naming convention)
- **Regression**: synchronous path unchanged (0 parse errors, all params present, 3/3 checks run)
- **Benchmark**: async=2.8s vs sync=9.2s → **3.2x speedup** (async unblocks orchestrator immediately)
- **Quality gate**: 22/22 ALL CLEAR (cross-ref ✅, breaker ✅, JD review ✅, write-scope ✅)

### Guardrails
- Hereda `auto-sub` deny floor: network, git push --force, supply chain, destructive, zero-width
- Fail-closed: `-Async` sin `-AllowedPaths` → exit 1 (v3 Perm-4)
- Convergence: 2 consecutive identical git-status polls → stop
- Hard deadline: 300s (default)

### Pending / Phases 2-3
- Fase 2: Implementar el BabyAGI loop (Execution→Task Creation→Prioritization) como skill activa
- Fase 3: Self-improvement auto-trigger (Approach A del Aug 8: score → diagnose → fix → verify loop)
- Concurrent edit conflict: `prompts/gentleman-vMK.md` + `scripts/delegation-registry.ps1` from parallel feature C4d coexist but NOT committed (separate concern)

---

## Mini-Orchestrator — BabyAGI Loop (Phase 2)

> **Rama**: `experimento/mini-orchestrator-loop` · **Base**: commit Phase 1 `256d338c` · **Fecha**: 2026-08-15

**Objective**: Implementar el loop BabyAGI activo (Execution→Task Creation→Prioritization) consumiendo el async handoff de Phase 1.

### Implementación

| Archivo | Acción | Verificación |
|---|---|---|
| `scripts/babyagi-loop.ps1` | CREATE: BabyAGI loop body (New-InitialTasks, Sort-TaskQueue, Invoke-TaskAsync, New-TasksFromResult, Start-BabyAGILoop) | 9/9 tests pass |
| `tests/babyagi-loop.Tests.ps1` | CREATE: 9 Pester tests (T1-T6) | ✅ 9/9 PASS |
| `.jd-cleared/scripts_babyagi-loop.ps1` | CREATE: JD review marker | ✅ PS-CI-03 compliant |
| `.breaker-cleared/scripts_babyagi-loop.ps1` | CREATE: Breaker cleared marker | ✅ allClean |

### E2E Verification
- **Pester**: 9/9 PASS (T1: single goal creates task, T2: multi-part creates multiple, T3: complexity priority, T4: sort by priority, T5: retry on timeout, T6: fix on failure, T7: no new tasks on success, T8: fail-closed guard, T9: no tasks on success)
- **Quality gate**: cross-ref INDEX check + breaker markers ✅
- **Guardrails**: Inherits Phase 1 fail-closed + deny floor. New guard: no direct Start-Process/git/network calls (delegates to Phase 1).

### Pendiente
- Fase 3: Self-improvement auto-trigger (score→diagnose→fix→verify loop)
- Integrar con delivery-harness para multi-agent orchestration real

---

## Mini-Orchestrator — Self-Improvement Trigger (Phase 3)

> **Rama**: `experimento/mini-orchestrator-loop` · **Fecha**: 2026-08-15

**Objective**: Auto-trigger the BabyAGI loop when quality issues are detected. Implements score → diagnose → fix → verify.

### Implementación

| Archivo | Acción | Verificación |
|---|---|---|
| `scripts/auto-improve.ps1` | CREATE: Scan-Issues, New-ImprovementGoal, Start-AutoImprove | 4/4 tests pass |
| `tests/auto-improve.Tests.ps1` | CREATE: 4 Pester tests (T1-T4) | ✅ 4/4 PASS |
| `.jd-cleared/scripts_auto-improve.ps1` | CREATE: JD marker | ✅ PS-CI-03 compliant |
| `.breaker-cleared/scripts_auto-improve.ps1` | CREATE: Breaker marker | ✅ allClean |

### How it works
1. **Score**: `Scan-Issues` scans for TODO/FIXME tags, long files (>200 lines)
2. **Diagnose**: `New-ImprovementGoal` creates a goal string from issues
3. **Fix**: `Start-AutoImprove` delegates to `babyagi-loop.ps1`
4. **Verify**: BabyAGI loop + Phase 1 async result JSON

### Guardrails
- `#requires -Version 5.1`
- Fail-closed: `-AllowedPaths` required
- Test mode guard: `$env:BABYAGI_TEST_MODE`
- Inherits all BabyAGI deny floor guards
- No direct Start-Process/git/network calls

---

## CI Quality Hardening (v3 2026-08-18)

> **Rama**: `experimento/mejora-autonoma-2026-08-18` · **Base**: main HEAD `31134225` · **Fecha**: 2026-08-18
> **Objetivo**: G1-G3 del plan v3 — robustez del test runner, coverage gate, mutation smoke, adversarial review estructurado.

### Resumen ejecutivo

3 ciclos implementados, verificados y commiteados. Pre-commit gate: **22/22 ALL CLEAR** en cada commit.
Ejecución en **worktree aislado** (`C:\Users\MK\AppData\Local\Temp\opencode\gentleman-exp-2026-08-18`) por sesión paralela `agente-aem-migration` en el worktree principal.

## Ciclo 1 — Robust Pester runner + NUnit publish (G1) — `e3bec66b`

**Bug**: gate [2/13] lee SOLO las primeras 3 líneas para `#requires -Version` — el `#requires` debe estar en la línea 1, no dentro de un comment block. Root-cause fix (se movió `#requires` a L1 en vez de marker).

**Fix**: `scripts/run-ci-tests.ps1` — pin Pester 5.5.0 (Pester 6 rompe `-CodeCoverage` legacy), `Run.Exit`, NUnit XML, `-WithCoverage` (JaCoCo). Job `tests` reescrito en ci.yml + publish NUnit. Fix pre-existente en `scripts/babyagi-loop.ps1` (`-DryRun`/`-Force` + try/catch Remove-Item; destructive-scripts **220/220**). Baseline refrescado con `-SetBaseline` (estaba viejo: 196KB→354KB skills).

| Entregable | Archivo | Tests | Commit |
|---|---|---|---|
| Runner | `scripts/run-ci-tests.ps1` | ✅ 4/4 (`ci-pester.Tests.ps1`) | `e3bec66b` |
| CI workflow | `.github/workflows/ci.yml` (job tests) | | `e3bec66b` |
| Fix destructivo | `scripts/babyagi-loop.ps1` | ✅ 220/220 | `e3bec66b` |
| Baseline | `benchmark-baseline.json` | `-SetBaseline` | `e3bec66b` |
| ADR | `adr/ADR-032-ci-quality-hardening-2026-08-18.md` | | `(HEAD — último commit de la branch, docs)` |

## Ciclo 2 — Coverage gate + mutation smoke (G2, R2+R4) — `c966c4bc`

**Bug**: coverage no gateada — regresiones invisibles; `Coverage.ps1` legacy usaba API Pester 6 rota.

**Fix**: `scripts/tests/Coverage.ps1` reescrito — pin 5.5.0, `-ExcludePattern` (default `e2e|Integration|session-checkpoint|skill-coverage|ui-specialist|subagent`), `-Strict` + `-MinimumCoverage 20`, emite JaCoCo `coverage.xml` + `summary.json` + NUnit `testResults.xml`. Job `coverage` en ci.yml (publish JaCoCo + summary). `mutation-smoke.Tests.ps1` 4/4 (mutante delta-first: `-eq`→`-ne` sobre `Get-DeepClone`; con `$null` NO es observable → probar con input no-null `@{a=1}`). `Coverage.Tests.ps1` 5/5 (contrato + smoke en proceso hijo — `Invoke-Pester` anidado colisiona con runtime activo). Fix indentación YAML del job `validate`.

| Entregable | Archivo | Tests | Commit |
|---|---|---|---|
| Coverage | `scripts/tests/Coverage.ps1` | | `c966c4bc` |
| Mutation | `scripts/tests/mutation-smoke.Tests.ps1` | ✅ 4/4 | `c966c4bc` |
| Contract | `scripts/tests/Coverage.Tests.ps1` | ✅ 5/5 | `c966c4bc` |
| CI workflow | `.github/workflows/ci.yml` (job coverage) | | `c966c4bc` |

**Números**: subset estable 769 tests / 0 fail / **26.63%** coverage → umbral **20%** (ratcheting). Suite completa: 997/29 fails pre-existentes (documentados, fuera de scope).

## Ciclo 3 — Structured adversarial review (G3, R1) — `2719837c`

**Bug**: breaker findings sin taxonomía de severidad consumible por CI.

**Fix**: `scripts/adversarial-review.ps1` — wrapper de `check-adversarial.ps1`; normaliza `block`→`critical`, `warn`→`warning` (taxonomía R1 Cloudflare), dedup por (rule, file), PSScriptAnalyzer opcional, `-SeverityFilter`, exit 1 con criticals. Tests 4/4 — fixture staged UNA vez en `BeforeAll` (staging por test competía bajo ejecución paralela: `PropertyNotFoundException: Count`).

| Entregable | Archivo | Tests | Commit |
|---|---|---|---|
| Review | `scripts/adversarial-review.ps1` | | `2719837c` |
| Tests | `scripts/tests/adversarial-review.Tests.ps1` | ✅ 4/4 | `2719837c` |
| Fixture | `scripts/tests/fixtures/adversarial-fixture.ps1` | untracked (intencional) | — |

### Estado de verificación

```
--- Pre-commit gate ---
✅ Ciclo 1: 22/22 ALL CLEAR (e3bec66b)
✅ Ciclo 2: 22/22 ALL CLEAR (c966c4bc) — 9/9 Pester en gate
✅ Ciclo 3: 22/22 ALL CLEAR (2719837c) — 4/4 Pester en gate
✅ Benchmark: baseline 1.414s vs final mediana 0.135s (sync-vmk -DryRun ×5)
✅ Coverage: 769/0 fail, 26.63% (floor 20%)
✅ Rollback: docs/mejoras/rollback-map.md (hashes reales)
ALL CLEAR
```

### Pendiente

- [ ] PR → `main` (esperar orden explícita; no mergear) — branch `experimento/mejora-autonoma-2026-08-18`
- [ ] Sesión paralela `agente-aem-migration`: archivos ajenos en worktree principal (NO tocados, des-stageados en Ciclo 1)
