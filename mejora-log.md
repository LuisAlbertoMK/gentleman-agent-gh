# Mejora Log — Experimentos Autónomos N-ciclos

Fecha inicio: 2026-08-02
Branch: `experimento/mejora-autonoma-2026-08-02` (base: `plan/globalize` HEAD 66558520; main está atrasado en el merge-base 948a61ad — el experimento parte del estado actual del trabajo, no del main desactualizado)
Protocolo: Mejora Autónoma Iterativa (N-ciclos)

## Baseline (setup)

| Métrica | Valor |
|---|---|
| Suite E2E (Pester scripts/tests) | 669 pass / **7 fail** |
| Gate pre-commit | 13/13 |
| Denies bash replicados (auto/semi) | 61/61 / 61/61 |
| write-deny config global | presente (ciclo previo cerrado) |
| opencode.json | 35,535 B / 37 agentes / 1650 líneas |
| Permisos en SSoT | 100% templates (sin inline) |

### Bugs preexistentes conocidos (registrados al setup)
1. `clean-repo.ps1`: sin `-Force` param (usa `-Yes`), `Remove-Item -ErrorAction SilentlyContinue` en destructivas (L105,108,109), sin try/catch — 4 tests failing
2. `engram-compact.ps1`: sin `-Force` param, `Remove-Item -ErrorAction SilentlyContinue` en finally (L198) — 3 tests failing
3. Nota: Pester 669 pasan; los 7 failures NO son causados por el ciclo previo (permissions) — verificados por diff + contexto

---
## Ciclo 1 — 2026-08-02

**Gap**: 7 tests failing preexistentes en `destructive-scripts.Tests.ps1` (clean-repo.ps1 + engram-compact.ps1: sin `-Force` param, `-ErrorAction SilentlyContinue` en destructivas, sin try/catch en clean-repo).

**Enfoques evaluados (3)**:
- A: `[Alias('Yes')]` sobre `[switch]$Force` + try/catch con `-ErrorAction Stop`, eliminar SilentlyContinue — **GANADOR**: pasa test literal `$Force`, 100% backward-compat con callers `-Yes`
- B: Renombrar `-Yes`→`-Force` en todo el repo — rechazado: rompe pre-commit gate, setup-machine, shortcuts
- C: `SupportsShouldProcess` — rechazado: el test exige literal `param(...$Force...)`

**Cambios** (`scripts/clean-repo.ps1`, `scripts/engram-compact.ps1`):
- `[Alias('Yes')][switch]$Force` en ambos (backward-compat total)
- Remove-Item destructivos envueltos en try/catch + `-ErrorAction Stop`, sin SilentlyContinue (fuera de cleanup/finally se reporta warning)
- Docs SYNOPSIS + ejemplos actualizados a `-Force`

**Resultado !breaker (3 ataques)**:
1. Regresión API: `-Yes` legacy y `-Force` nuevo → ambos mode=apply, eliminan junk ✅
2. Dry-run sin flag → preserva archivos ✅ | `-Yes -RemoveUntracked` → limpió ✅
3. Inputs inválidos (path inexistente, DB inexistente) → JSON `ok:false` + exit 2 in-process ✅ (status=1 del proceso externo es quirk de `pwsh -Command "&"`, confirmado con .ps1 puro — no es bug del script)
4. FALLA EXPUESTA (seed incompleto mío): engram-compact con DB sin tabla user_prompts → traceback en JSON — contrato `ok:false` cumplido, mensaje feo documentado como hallazgo menor (no bloquea)

**Resultado E2E**: 215/215 en los 3 archivos de tests (destructive-scripts + clean-repo + engram-compact). Suite completa pendiente de correr en ciclo siguiente (154s).

**Benchmark vs baseline**: 7 failures → 0 failures. MEJORA ✅

**Aprendizaje**: (1) `pwsh -Command "& 'script'"` NO propaga exit code de `exit N` del script — usar `-File` o `&` in-process para verificar exit codes en tests futuros. (2) El alias `[Alias()]` en switch es la forma limpia de compat. (3) Algunos tests de destructive-scripts corren sobre todos los scripts del repo — cualquier script nuevo con Remove-Item sin guard dispara failures.

**Verificación final Ciclo 1**: suite E2E completa 676/676 pass, 0 fail (90.98s) ✅ — 7 failures preexistentes cerrados.

---
## Ciclo 2 — 2026-08-02

**Gap**: Regla `pr` suelta en `agentRecommendations` de `scripts/skill-graph.ps1` (L175 y L181): `(?:commit|pr|pull.request|...)` matcheaba la subcadena "pr" dentro de "improve"/"preview" → recomendaciones falsas de commit/PR. Ej: "improve SEO for the landing page" recomendaba commit-crafter, quality-gate, branch-pr, chained-pr (runtime — oculto por CSV) y emitía 6 warnings en el test (registry parcial).

**Enfoques evaluados (3)**:
- A: `\bpr\b` (word boundary) en las 2 reglas — **GANADOR**: matchea "PR"/"pr" como palabra, no como subcadena; `pull.request` preserva el wildcard para pull_request/pull-request
- B: Quitar `pr` de la regla — rechazado: pierde "open a PR" como trigger legítimo
- C: Case-sensitive `(?i)` global cambiada — rechazado: rompe todos los otros triggers que dependen de case-insensitive

**Cambios**:
- `scripts/skill-graph.ps1`: L175 `(?:code|security|skill|\bpr\b)`, L181 `(?:commit|\bpr\b|pull.request|merge|ship|push)`
- `scripts/tests/skill-graph.Tests.ps1`: auto-registro de TODAS las skills referenciadas por `agentRecommendations` en el BeforeEach del Describe (elimina la clase de warning completa, no solo el trigger actual) + 2 aserciones de regresión: "improve SEO" NO debe contener commit-crafter ni branch-pr

**Nota**: El análisis previo ("$PSScriptRoot en ~90 scripts" del 08-01) resultó FALSO POSITIVO — los hits eran texto de help/comentarios; `global-setup.ps1` usa paths relativos a propósito y resuelve con `Join-Path $gentlemanRoot` en consumo. Verificado por scan + lectura. No se "arregló" un problema inexistente.

**Resultado E2E**: skill-graph 18/18 ✅ sin warnings (antes 6 warnings en 2 tests). Runtime verificado: "improve SEO" → solo `seo`; "prepare a PR and commit" → 4 skills correctas; "review the preview branch" → sin falso match L181.

**Benchmark vs baseline**: warnings E2E 6 → 0. Recomendaciones falsas eliminadas. MEJORA ✅

**Aprendizaje**: (1) Alternancias con tokens cortos (`pr`) en regex de recomendación deben usar `\b...\b` — el runtime puede ocultar falsos positivos si las skills existen en el registry; el warning del test es el síntoma visible. (2) El test con registry parcial expone gaps que el runtime disimula — auto-registrar desde la tabla elimina la clase completa. (3) Verificar el gap ANTES de implementar: "arreglos" de falsos positivos documentados añaden ruido sin valor.

---
## Ciclo 3 — 2026-08-02

**Gap**: `opencode-model-router` SKILL.md 3741 B / 3626 chars > umbral 3KB del gate [5/13] (run-improvement-cycle: >3072 B; benchmark: >3000 chars). Warning recurrente en CADA commit gate.

**Enfoques evaluados (3)**:
- A: Compresión editorial (prosa → tablas/listas, quitar duplicados) — **GANADOR**: preserva 100% de la autoridad de ruteo, reduce 18%
- B: Mover contenido a archivo auxiliar referenciado — rechazado: rompe el consumo directo del SKILL.md como fuente única
- C: Subir el umbral del gate — rechazado: debilita la guarda de skills infladas para todos

**Cambios** (`.agents/skills/opencode-model-router/SKILL.md`):
- Eliminado "When to Use" (duplicaba la descripción del frontmatter)
- Leyenda de tabla comprimida; prosa de RUNTIME REALITY/STRATEGY convertida a bullets compactos
- Anti-Patterns condensados. Resultado: 3741 B → 3066 B (-18%), 3626 → 2960 chars

**Verificación**: bajo umbral chars (<3000) y bytes (<3072) ✅. Frontmatter válido (run-improvement-cycle [2/9] SKILL.md OK). La tabla de ruteo (13 filas), SECURITY GATE (4 reglas), IMPLEMENTER, CONTEXT→ACTION y Refs intactos — diff verificado sección por sección.

**Hallazgo nuevo expuesto** (no causado por el cambio): `run-dreaming.ps1:134` — `$repeated.Count -gt 0` falla con `ParentContainsErrorRecordException` cuando el scan devuelve UN solo objeto (no array). Bug real preexistente → candidato Ciclo 4.

**Benchmark vs baseline**: skills >3KB en gate 1 → 0 (este archivo). MEJORA ✅

**Aprendizaje**: (1) El gate mide chars (Get-Content .Length) mientras run-improvement-cycle mide bytes — al recortar hay que pasar AMBOS umbrales (chars <3000 Y bytes <3072); un archivo con muchos chars multibyte (emoji ✅⚠️) puede pasar chars pero fallar bytes. (2) Comprimir sin perder autoridad: tablas y bullets compactos > prosa; eliminar secciones que duplican el frontmatter. (3) Correr run-improvement-cycle + benchmark tras el cambio expone problemas colaterales reales (run-dreaming bug).

---

## Ciclo 4 — 2026-08-02

**Gap**: `run-dreaming.ps1:134` — `ParentContainsErrorRecordException: The property 'Count' cannot be found` al correr el scan de errores. Reproducible en runtime (benchmark + llamada directa). Causa raíz clásica de PowerShell: `Get-RepeatedPattern` retorna un array de 1 elemento que PowerShell DESENVUELVE a objeto único (hashtable) → `.Count` semántica rota.

**Enfoques evaluados (3)**:
- A: Wrapper `@(...)` en los call-sites — **GANADOR**: garantiza array en TODOS los modos; patrón idempotente seguro
- B: `return ,` (unary comma) en la función — rechazado: protege solo 1 caller, el resto quedan expuestos
- C: Cast `[array]` en la variable — rechazado: más ruido que el wrapper, misma efectividad

**Cambios** (`scripts/run-dreaming.ps1`): wrapper `@(...)` en 4 call-sites de `Get-RepeatedPattern` (bloques quick/report L132 y feed L193/195).

**Hallazgo de semántica (más profundo que el crash)**: pre-fix, con 1 patrón repetido `.Count` devolvía **3** (contaba las keys del hashtable, no los patrones) → severidad/conteos falsos. Post-fix: `Count=1` correcto. Verificado en sandbox (0/1/2/3 patrones: Count correcto, severidad WARNING/CRITICAL correcta, foreach itera bien).

**Resultado E2E**: sin tests dedicados a dreaming; runtime verificado: `run-dreaming.ps1 -Mode report` exit 0 sin crash (antes: crash reproducible en cada corrida).

**Benchmark vs baseline**: crash runtime 1 → 0. Conteo de patrones semánticamente correcto. MEJORA ✅

**Aprendizaje**: (1) Funciones PowerShell que retornan arrays de 1 elemento se desenvuelven — SIEMPRE envolver con `@(...)` en el caller al usar `.Count`/`.Length`/foreach. (2) Un hashtable también tiene `.Count` (keys) — el bug puede ser silencioso: funciona pero devuelve el valor equivocado; el error real se manifiesta como bug de lógica, no excepción. (3) `@(...)` es idempotente y es la convención defensiva estándar.

---
## Cierre — 2026-08-02

**Decisión de parada**: condición cumplida — 12 enfoques evaluados (3 por ciclo × 4 ciclos) ≥ 10. `confidence: high` (los 12 enfoques están documentados arriba con su resultado A/B/C).

**Integración**: `experimento/mejora-autonoma-2026-08-02` → merge fast-forward → `plan/globalize` (4b339517). 7 archivos: +171/-37.

**Verificación final post-merge** (rama `plan/globalize` @ 4b339517):
- Suite E2E completa: **675 pass / 0 fail / 0 skipped** (1 NotRun = fixture de instalación manual, esperado) ✅
- Gate pre-commit 13/13 en el último commit del experimento ✅
- Benchmarks por ciclo: 7 failures → 0; warnings skill-graph 6 → 0; skills >3KB 1 → 0; crash runtime run-dreaming 1 → 0

**Balance del experimento (baseline → final)**:

| Métrica | Baseline | Final |
|---|---|---|
| Suite E2E | 669 pass / 7 fail | **675 pass / 0 fail** |
| Gate pre-commit | 13/13 | 13/13 |
| Warnings skill-graph | 6 | 0 |
| Skills >3KB | 1 | 0 |
| Crash runtime run-dreaming | 1 | 0 |

**Archivos tocados**: `scripts/clean-repo.ps1`, `scripts/engram-compact.ps1`, `scripts/skill-graph.ps1`, `scripts/tests/skill-graph.Tests.ps1`, `.agents/skills/opencode-model-router/SKILL.md`, `scripts/run-dreaming.ps1`, `mejora-log.md` (nuevo).

**Pendientes no bloqueantes** (candidatos a futuros ciclos): engram-compact con DB sin tabla `user_prompts` muestra traceback feo en JSON (contrato `ok:false` cumplido); 3 junctions globales degradadas (vmk-skills/prompts, global-skills — preexistente, no causada por el experimento); `gh` CLI no instalado localmente (PRs requieren instalación o push directo).

---
## Ciclo 5 — 2026-08-02 (breakers C2/C3/C4, condición de parada §3)

**Gap**: El cierre previo (commit 52a053bc) declaró la condición de parada cumplida SOLO por conteo de enfoques (12 ≥ 10). La revisión contra el protocolo formal expuso que §3 exige ADEMÁS breaker ≥3 ataques por ciclo y "no quedan gaps" — C2/C3/C4 no tenían breaker. Reabierta la parada.

**Breakers ejecutados (subagentes independientes, builder≠evaluator)**:
- **C2 (skill-graph `\bpr\b`)**: **FIX** — el boundary rompe el plural legítimo "PRs": `review the PRs` pierde commit-crafter/branch-pr (caía al fallback fuzzy con ruido: sdd-spec, baseline-ui, judgment-day). 33 inputs / 36 aserciones → 35 PASS / 1 FAIL. Fix: `\bprs?\b` en L175/L181 + test de regresión plural. Re-verificado: PRs plural→True, PR singular→True, improve/preview→False (falsos muertos).
- **C3 (SKILL.md compresión)**: **APPROVED** — 13/13 filas de ruteo byte-idénticas tras normalización, SECURITY GATE 4/4, IMPLEMENTER 6/6, CONTEXT→ACTION 6/6, Refs 4/4, STRATEGY 6/6. Pérdidas solo prosa operativa (ruta permission-templates.json, conteo 1643 líneas, flag --validate) + sección "When to Use" (ya truncada en original, duplicada por frontmatter). Gate: chars 2960 <3000 ✓ bytes 3066 <3072 ✓.
- **C4 (run-dreaming `@()` en call-sites)**: **FIX** — el fix de C4 fue INCOMPLETO: feed mode aún crasheaba en L207 (`$keywords.Count` con 1 keyword scalar → ParentContainsErrorRecordException bajo Set-StrictMode) y L224 (`$null.Count` con 0 keywords). Además el diagnóstico original era impreciso: el entry tiene key literal `Count`, así que `.Count` en elemento desenvuelto devuelve el conteo de ocurrencias (2, 3…) no "3 keys" — el crash pre-fix real era con 0 patrones (`$null.Count`). Fix: wrapper `@(...)` en las 2 asignaciones de `$keywords` (L207/L224). Re-verificado en lab hermético: feed 1 keyword / 0 keywords / multi keyword → exit 0, sin crash (antes 2 crashes distintos).

**Enfoques evaluados para los fixes (2)**:
- A: `\bprs?\b` (plural opcional) + `@(...)` en `$keywords` — **GANADOR**: 1-char extend por línea, mantiene todos los casos previos, ataca la raíz (singular+plural, scalar+null)
- B: `\b(?:prs?|pr)\b` explícito — rechazado: redundante, `s?` ya cubre
- (el fix C4 de @() call-sites se mantiene; la alternativa `return ,$result` en la función queda descartada — protegería solo 1 caller)

**Resultado breaker**: C2 FIX→re-verificado PASS (4/4 ataques), C3 APPROVED (3/3 ángulos), C4 FIX→re-verificado PASS (3/3 casos). **2 bugs reales encontrados por el breaker post-cierre** — el protocolo §3 tenía razón en exigirlo.

**Resultado E2E**: suite completa 676/677 pass (1 NotRun fixture manual, esperado) + 1 test nuevo (plural PRs). skill-graph 19/19.

**Benchmark vs ciclo anterior**: suite 675→676 pass. Falsos positivos PR: 0 (se mantiene) + plural restaurado. Crash feed: 2 → 0. MEJORA ✅

**Aprendizaje**: (1) `\b\b` de regex rompe plurales — siempre probar singular+plural+puntuación en breakers de regex. (2) Los fixes PowerShell de unwrap deben atacar TODOS los call-sites de `.Count`/`.Length`, no solo el sintomático — el mismo patrón se repetía 2 niveles más abajo (L207/L224). (3) El diagnóstico del crash original era impreciso: con key literal `Count` el `.Count` "funciona" pero devuelve el valor equivocado (silencioso) — el crash duro era 0 patrones. (4) Cerrar por conteo de enfoques sin breaker es prematuro — la condición de parada §3 es AND, no OR.

---
## Merge a main — 2026-08-02 (§4 protocolo)

**Condición §4 evaluada**: TODAS las condiciones de parada §3 cumplidas — breakers ≥3 ataques por ciclo (C1 3 ataques, C2 re-verificado 4/4, C3 3/3 APPROVED, C4 re-verificado 3/3), sin gaps nuevos detectables, 676/677 tests E2E (1 NotRun fixture manual esperado), benchmark ≥ ciclo previo en todas las métricas.

**Mecánica**: gh CLI no disponible y curl/Invoke-RestMethod denegados en el entorno → PR por API/CLI imposible. Usuario autorizó vía explícita ("procede") la alternativa B: fast-forward main ← plan/globalize + push directo. Desviación documentada del §4 ("vía PR").

**Contenido del merge**: 17 commits sobre main (948a61ad): trabajo acumulado de plan/globalize (shortcuts SSoT, permissions layering, session-miner schema) + 5 commits del experimento N-ciclos (C1-C4 + breaker C2/C3/C4).

**Verificación post-merge**: suite E2E completa 676/677 pass / 0 fail (corrida sobre el árbol ya integrado), gate 13/13 en el último commit, push verificado local=origin.
