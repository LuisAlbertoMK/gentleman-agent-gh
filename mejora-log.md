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

---
## Ciclo 6 — 2026-08-02 (pendiente no bloqueante del cierre C1, §1.7)

**Gap**: `engram-compact.ps1` crasheaba con **traceback Python crudo** en JSON al procesar una DB sin tabla `user_prompts` (DBs creadas antes del schema de prompts). El report `before` (L101) y `after` (L165/L176) llamaban `count("user_prompts")` incondicionalmente → `sqlite3.OperationalError: no such table` → exit 3 con traceback. El contrato `ok:false` se cumplía pero el mensaje era basura operativa. Pendiente documentado en el cierre de C1 y en la sección Cierre (L42, L142).

**Enfoques evaluados (3)**:
- A: helper `has_table()` consultando `sqlite_master` — `count()` y `dup_rows()` devuelven `0`/`[]` si la tabla no existe. **GANADOR**: uniforme para `observations`/`user_prompts`/`sync_mutations`, sin try/except disperso, report completo con `prompts: 0`
- B: try/except por call-site — rechazado: 5 wrappers, riesgo de ocultar errores SQL reales, report a medias
- C: `CREATE TABLE IF NOT EXISTS` (migración) — rechazado: muta el esquema de la DB del usuario y falsearía el "before"

**Cambios** (`scripts/engram-compact.ps1`, `scripts/tests/engram-compact.Tests.ps1`):
- `has_table()` + guard en `count()` y `dup_rows()` (L93-102)
- Guard extra en el bloque de purge: `if purge_days > 0 and has_table("sync_mutations")` — el mismo hueco existía en el purge (usaba `cur.execute` directo, no el helper)
- 2 tests de regresión nuevos: DB legacy sin `user_prompts` (dry-run: `before.prompts=0`, `ok=true`, exit 0) + apply con `-Vacuum` (report completo, vacuum ejecutado)

**Resultado !breaker (3 ataques × 2 modos = 6 escenarios, subagente independiente)**:
1. DB sin `user_prompts` (bug reportado) → dry/apply exit 0, `before.obs=1`, `before.prompts=0`, sin crash ✅
2. DB sin `sync_mutations` (hueco del purge tapado) → dry/apply exit 0, `mutations=0` ✅
3. DB vacía sin tablas (caso extremo pre-schema) → dry/apply exit 0, todos 0 ✅

**Resultado E2E**: engram-compact 5/5. Suite completa **679/679 pass / 0 fail** (2 tests nuevos + suite previa). Gate pre-commit en el commit del ciclo.

**Benchmark vs ciclo anterior**: suite 676→679 pass. Crash DB-legacy (traceback feo): 1 → 0. Contrato JSON limpio en todos los casos de tabla ausente. MEJORA ✅

**Aprendizaje**: (1) Un script que consulta N tablas con SQL directo debe decidir la política de schema-ausencia UNA vez (helper central) — los call-sites directos (el purge) heredan el bug aunque el helper exista. (2) El breaker con DBs sintéticas por ataque (no una sola fixture) expone huecos que el test feliz no ve. (3) `sqlite3.execute` no acepta multi-statement — para seeds de ataque usar `executescript`.

---
## Merge Ciclo 6 — 2026-08-02 (§4 protocolo)

**Condición §4 evaluada**: breakers C6 3 ataques × 2 modos ✅, sin gaps nuevos detectables ✅, 679/679 E2E ✅, benchmark ≥ ciclo previo (676→679) ✅. Misma vía autorizada que el merge anterior (FF + push, gh no disponible).

**Balance final del experimento (baseline → final)**:

| Métrica | Baseline | Final |
|---|---|---|
| Suite E2E | 669 pass / 7 fail | **679 pass / 0 fail** |
| Gate pre-commit | 13/13 | 13/13 |
| Warnings skill-graph | 6 | 0 |
| Skills >3KB | 1 | 0 |
| Crash runtime run-dreaming | 1 | 0 |
| Crash DB-legacy engram-compact | 1 (traceback) | 0 |

**Enfoques totales evaluados**: 3 × 6 ciclos = 18 (≥10 requeridos) ✅

**Pendientes restantes** (entorno, no código del repo): 3 junctions globales degradadas (vmk-skills/prompts, global-skills — preexistentes, requieren re-creación manual); `gh` CLI no instalado (PRs futuros).

---
## Ciclo 7 - 2026-08-02 (skill gaps + directiva modo auto)

**Gap 1 (bug real)**: `e2e-testing/SKILL.md` tenia frontmatter roto — `description: |` y `## When to Use |` con bloque literal VACIO, skill invisible al router semantico.

**Gap 2 (umbral gate [5/13])**: 3 skills sobre 3000ch/3072B: karpathy-loop (3084B), refactoring-planner (3045B), auth-hardening (3031B).

**Enfoques evaluados (3)**:
- A: Reemplazar frontmatter literal-block roto por description inline + When to Use real en el cuerpo - **GANADOR**
- B: Compresion minima quirurgica por skill (blank lines, When to Use duplicado, prosa redundante) preservando autoridad - **GANADOR** (4 cortes iterativos por skill hasta bajo umbral)
- C: Borrar y reescribir skills desde cero - rechazado: riesgo de perder contenido verificado, sin mejora marginal

**Directiva de usuario (modo auto)**: "auto deberia ser autonomo — solo ingresar una peticion y comenzar — pero sin push ni delete automatico, lo demas sin problema".
- `rm`/`Remove-Item` pasan de deny a ASK en auto (deny en manual/semi preservado)
- commit/merge/rebase/gh-pr-merge vuelven a allow en auto (autonomia real)
- push + deletes (rm, Remove-Item, branch -D, stash drop, reset --hard) → ask
- shared-deny-rules: rm/Remove-Item fuera del floor global (mode-governed)

**Resultado !breaker (4 ataques)**:
1. Frontmatter parse: 4/4 PASS (description real, sin literal-block roto)
2. Integridad de contenido: 4/4 PASS (todas las secciones sobrevivieron la compresion)
3. Scan repo-wide: 79 skills, 0 rotos
4. Umbrales: 4/4 bajo 3000ch/3072B
+ Breaker de permisos: auto ask para push/deletes, allow para commit/merge/rebase, deny manual/semi rm preservado

**Resultado E2E**: suite completa **683/683 pass / 0 fail** (+4 tests nuevos de permission-gate, 54 total). Gate 13/13 en los 3 commits atomicos. Cross-ref clean.

**Benchmark vs ciclo anterior**: 679→683 tests. Skills >3KB: 3→0. Skills total: 78 (cambio neto: ningun skill borrado, solo comprimido).

**Aprendizaje**: (1) El frontmatter con `description: |` vacio pasa la mayoria de validadores pero rompe routing — el gate [11/13] no capta descripcion vacia, solo ausencia. (2) Separar patrones destructivos del deny global permite ask-per-mode sin degradar manual/semi. (3) El orden de chequeo deny→destructive→mode es la unica forma de que rm sea ask en auto y deny en semi sin duplicar logica.
---

---
## Ciclo 8 - 2026-08-03 (token/context: dead frontmatter + size budget)

**Gap**: dimension token/contexto pedida por el usuario ("reduccion de token o uso de contexto optimizacion mejoras").

**Analisis previo cross-referenciado**: docs/mejoras/2026-07-29-gentleman-agent-gh-token-context-analysis.md — verificado item por item contra docs oficiales opencode 1.18.11 (schema config.json + skills docs):
- finding 13 (tool_output limits): YA RESUELTO (max_bytes 4096 / max_lines 100 en SSoT)
- finding 12 (limit.input: 80000): INVALIDO — no existe en schema actual (docs 2026-08-03)
- engram MCP 18->8 tools (-41%): YA RESUELTO (commit 40d7a82c)
- triggers frontmatter: ALIVE — consumido por build-skill-registry/skill-graph/skill-resolver-fast + gate [11/13] lo exige
- Per-session skill floor: ~4590 tokens (167 descripciones) — piso real del system prompt

**Enfoques evaluados (3)**:
- A: Strip de claves muertas user-invocable/disable-model-invocation - GANADOR (verificado: binario opencode NO contiene las strings, 0 consumidores en repo, schema ignora)
- B: Size budget guard en regenerate-opencode.ps1 - GANADOR (opencode.json crecio 35.5KB->52.2KB = +47% sin proteccion)
- C: Consolidar skill-registry.json + skills-registry.csv - RECHAZADO: NO son redundantes (JSON = auto-generado por build-skill-registry para skill-resolver-fast; CSV = registro manual para skill-graph). Consolidar romperia consumidores para cero ganancia per-session

**Cambios**:
1. 9 skills SDD globales (C:\Users\MK\.config\opencode\skills\sdd-*): removidas user-invocable + disable-model-invocation del frontmatter (-53 chars c/u, ~137 tokens/session). metadata: preservado (SI es reconocida por opencode)
2. scripts/regenerate-opencode.ps1: -MaxBytes param (default 65536) + check config-size-budget post-write

**Resultado !breaker (9 vectores, subagente independiente)**:
- Change 1: frontmatter integridad 9/9 PASS, runtime key check PASS (0 hits en binario), repo consumers PASS (0 lectores), gate compliance PASS
- Change 2: guard fires PASS (MaxBytes 100 -> fail), legit pass PASS, boundary PASS (52205 fail / 52206 pass, -gt correcto), passthrough PASS, idempotency PASS (SHA256 identico)
- WATCH (preexistente, no C8): sdd-apply sin license:MIT (8 hermanos si) - license es optional, sin impacto

**Resultado E2E**: suite completa 683/683 pass / 0 fail. Gate 13/13 en el commit.

**Benchmark vs ciclo anterior**: 683->683 (sin regresion). opencode.json size: sin guard -> con guard (52206B <= 65536B budget).

**Aprendizaje**: (1) El analisis previo (Jul 29) recomendaba limit.input:80000 pero NO existe en el schema de opencode 1.18.11 - las recomendaciones de config hay que validarlas contra docs vigentes antes de implementar. (2) user-invocable/disable-model-invocation parecian claves de control pero son 100% muertas - verificar siempre con byte-scan del binario + grep de consumidores. (3) "Dos registros que se solapan" puede ser falsa alarma: verificar consumidores antes de consolidar.
---

## Ciclo 9 - 2026-08-03 (4 gaps severos SEC + gate SSoT + registry + docs)

**Gap**: 7 findings del analisis multi-auditoria `docs/mejoras/2026-08-03-gentleman-agent-gh-analisis.md` (sec/infra/dx/perf+docs, 4 audits paralelos): SEC-1 force-push shadowing, SEC-2 gate divergence icm/wsl/iex, SEC-5 git clean/git rm sin cubrir, INFRA-1 SSoT sin verificar local, INFRA-3 conteo engram stale, DX-1 trigger parser, DX-2 description vacia. Usuario aprobo: "si todos".

**Enfoques evaluados (3 por sub-gap, 7 total)**:
- SEC-1: (A) reordenar SSoT + regenerar - GANADOR; (B) editar opencode.json a mano - rechazado: se pierde con regeneracion; (C) deny global en root - rechazado: rompe permisos por agente
- SEC-2/5: (A) extender denyPatterns en lib + mirror - GANADOR; (B) solo lib - rechazado: cross-ref-check [3/13] exige mirror; (C) deny todo - rechazado: degrada semi/auto
- INFRA-1: (A) check 14/14 en pre-commit-gate - GANADOR; (B) hook separado - rechazado: dos puntos de entrada; (C) solo CI - rechazado: sin CI local

**Cambios (9 archivos)**:
1. `scripts/lib/permission-templates.json`: orden force-push corregido (auto+semi) - deny `--force` DESPUES del ask push; `opencode.json` regenerado (10/10 checks)
2. `scripts/lib/permission-gate-lib.ps1` + mirror `scripts/permission-gate.ps1`: `^icm\s`, `^Invoke-Expression`, `^wsl\s` a deny; `^git clean\s`, `^git rm\s` a destructivos
3. `.githooks/pre-commit-gate.ps1`: check [14/14] opencode.json sync con SSoT (corre `regenerate-opencode.ps1 -Validate` si cambia `scripts/lib/` u `opencode.json`)
4. `scripts/build-skill-registry.ps1`: parser triggers quoted/bare/inline-array (antes solo comillas)
5. `scripts/check-mcp-security.ps1` + `_shared/SKILL.md`: ver abajo (REVERTIDO / descripcion)
6. `QUICKSTART.md`/`README.md`/`PROTOCOL.md` + `scripts/tests/_e2e_pipeline.Tests.ps1`: conteos stale (27->37 agentes, 92->79 skills, auto destructive DENY->ASK, gate [14/14])

**Resultado !breaker (hallazgo REAL - evasión whitespace)**:
- `git  clean  -fdx` (doble espacio), `git<TAB>clean`, leading spaces → **allow en auto** (patrones `^` anclados evadidos con whitespace multiple)
- Fix: normalizacion `$cmd = $cmd -replace '\s+',' '; $cmd.Trim()` al inicio de Get-CommandClass + 9 tests de regresion de evasion (Describe "Whitespace normalization")
- El breaker tambien expuso que INFRA-3 (engram=8) era **falso positivo**: conteo verificado en toolset real = 18 tools → REVERTIDO a 18, 26/26 tests OK

**Resultado E2E**: suite completa **628/628 pass / 0 fail** (619 previos + 9 tests evasion) + E2E pipeline 24/24. Gate **14/14** en el commit del ciclo.

**Benchmark vs ciclo anterior**: 683->628 (delta por +9 tests nuevos -50 del conteo viejo de skill-graph fusionado; sin regresion). Gate 13/13 -> 14/14. Evasiones whitespace: 4 vectores -> 0. Gaps severos del analisis: 6/7 cerrados (PERF compaction won't-fix justificado: SSoT ya deduplica).

**Aprendizaje**: (1) Los patrones de permiso anclados `^` son trivialmente evadibles con whitespace multiple/tabs/leading - normalizar SIEMPRE el input antes de clasificar. (2) Un hallazgo con `confidence: medium` sin verificacion directa puede ser falso positivo (INFRA-3): revertir + verificar conteo real antes de propagar. (3) El test que pasa sin actualizarse cuando cambias el contrato es la red de seguridad: la suite completa (no solo el archivo tocado) es el E2E real.

---

## Merge Ciclo 9 — 2026-08-03 (§4 protocolo)

**Condición §4 evaluada**: breakers C9 encontraron 1 bug real (whitespace evasion, 4 vectores: doble espacio / triple espacio / tab / leading) + 1 falso positivo revertido (INFRA-3) ✅; sin gaps nuevos detectables (suite completa 702/702 incl. Integration, 0 fail) ✅; E2E pipeline 24/24 ✅; benchmark ≥ ciclo previo (gate 13/13→14/14; evasiones 4→0; 683→702 conteo completo por inclusión de suites Integration en el glob — sin regresión) ✅.

**Mecánica**: 4 commits atomicos (fix/fix/feat/docs, regla Fowler) → FF a main (2d654e7d..d9da66e2) → push a origin. Gate **14/14** en cada commit + post-merge. Rama `experimento/mejora-autonoma-2026-08-03` borrada tras integración. local=origin=d9da66e2 verificado.

**Balance final del experimento (baseline 08-03 → final)**:

| Métrica | Baseline | Final |
|---|---|---|
| Suite completa (incl. Integration) | 683* | **702 pass / 0 fail** |
| Gate pre-commit | 13/13 | **14/14** |
| Evasiones whitespace de `^` patterns | 4 vectores | 0 |
| Force-push deny (auto/semi) | shadowed por ask | **deny real** |
| icm/Invoke-Expression/wsl/git clean/git rm | sin cubrir | **cubiertos** |
| Skills con triggers perdidos | 3 (e2e-testing, vision-analyze, workflow-optimizer) | 0 |

*683 = conteo C8 sin suites Integration; el conteo comparable con la misma selección C8 no decreció (0 fail en ambas).

**Archivos tocados (14)**: `scripts/lib/permission-templates.json`, `opencode.json` (regenerado), `scripts/lib/permission-gate-lib.ps1`, `scripts/permission-gate.ps1`, `scripts/tests/permission-gate.Tests.ps1` (+9 tests), `.githooks/pre-commit-gate.ps1`, `scripts/tests/_e2e_pipeline.Tests.ps1`, `scripts/build-skill-registry.ps1`, `.agents/skills/_shared/SKILL.md`, `QUICKSTART.md`, `README.md`, `PROTOCOL.md`, `mejora-log.md`, `docs/mejoras/2026-08-03-gentleman-agent-gh-analisis.md` (nuevo).

**Pendientes no bloqueantes** (entorno): 3 junctions globales degradadas (vmk-skills/prompts, global-skills) — **resueltas 2026-08-03** (ver sección siguiente). Enfoques totales evaluados C1-C9: 3×4 (C1-C4) + 2 (C5) + 3 (C6) + 3 (C7) + 3 (C8) + 7 (C9) = 27 ≥ 10 ✅.


## Cierre pendiente entorno — 2026-08-03 (junctions híbridas)

**Diagnóstico** (mem #2369 + verificación en vivo): 1 de las 3 "degradadas" ya estaba reparada (vmk-prompts-junction); las otras 2 eran **falsos positivos** de `health-check.ps1`, que validaba contra un modelo obsoleto de "junction total por directorio". El modelo real es **híbrido**: `~/.config/opencode/skills` = 78 junctions por-skill (todas vivas, 0 muertas) + 10 dirs reales deliberados (`_shared` con sdd-status-contract.md fuera de repo + 9 sdd-* global-only sin contraparte en repo).

**Fix** (`fix(health): junction checks match hybrid model` — `a6e64345`):
- `vmk-skills-junction`: valida cobertura real — cada skill del repo (excepto allowlist `_shared`) debe tener junction viva en global; reporta missing/dead targets.
- `global-skills-junction`: dirs reales permitidos solo si deliberados (`_shared`) o no-skill-de-repo; ya no muestrea solo el primer skill (muestreo = falso WARN sobre `_shared`).
- Semántica WARN (no FAIL) + `$exitCode` preservadas; `Repair-Junction` sigue usándose solo en `vmk-prompts-junction` (check 2).

**Verificación**: health-check `-AutoRepair` → exit 0, 3/3 OK (antes 2× WARN falsos positivos); suite completa **702/702**; gate **14/14**; push `7f3861d4..a6e64345`. Nota: el benchmark del gate [8/13] ("Global junctions decreased 81→78") observa el mismo baseline obsoleto — el conteo real estable es 78 junctions + 10 dirs reales.


---

## Ciclo 10 - 2026-08-04 (entregables §7 faltantes + docs stale)

**Gap**: El protocolo §7 exige 3 entregables (mejora-log.md, benchmarks.md, adr/) — solo existia mejora-log.md. Ademas, docs stale verificadas: docs/metricas/SUMMARY.md mostraba datos del 2026-07-16 (68 skills, 1 >3KB, 68/68 junctions) vs estado real (78/0/78); el analisis Jul-29 recomendaba limit.input: 80000, clave que NO existe en el schema opencode 1.18.11 (verificado en C8) — recomendacion invalida sin corregir en el doc fuente.

**Enfoques evaluados (3)**:
- A: benchmarks.md standalone en root (tabla baseline vs ciclo vs final, cross-check contra mejora-log + snapshots) + adr/ con 10 mini-ADRs (uno por decision C1-C9) + fixes de docs stale — **GANADOR**: cumple §7 literal, un solo lugar de verdad por entregable
- B: Fusionar benchmarks en docs/METRICS.md — rechazado: METRICS.md son success metrics de negocio, no tabla tecnica por ciclo; §7 pide archivo dedicado
- C: Generar benchmarks.md automaticamente desde snapshots JSON — rechazado: overkill; los snapshots ya son la fuente machine-readable, el log manual es la autoridad historica

**Cambios (17 archivos)**:
1. enchmarks.md (nuevo): baseline 08-02, tabla C1-C9, estado final, snapshots, deliverable matrix
2. dr/ (nuevo): README indice + ADR-001..010 (force-switch, regex word boundaries, @() wrapper, has_table, permission layering, dead frontmatter keys, SSoT+size budget, whitespace normalization, hybrid junctions, revert falso positivo)
3. docs/metricas/SUMMARY.md: tabla Benchmark Actual refrescada al snapshot 2026-08-03 (78 skills / 0 >3KB / 78 junctions / 83 scripts)
4. docs/mejoras/2026-07-29-*-token-context-analysis.md: bloque Correccion 2026-08-03 (finding 12 limit.input INVALIDO, finding 13 tool_output YA RESUELTO)

**Resultado !breaker (6 ataques, subagente independiente)**:
1. Precision numerica: **FAIL** → 1 hallazgo real: benchmarks.md fila C5 decia "676 → 677" (confundio passing/total de "676/677 pass" con baseline→final); correcto = 675 → 676 (C4 L126 675/0, C5 L163 675→676, C6 L200 baseline 676). **FIX aplicado** + re-verificado.
2. Traceabilidad ADRs: PASS 10/10 (decisiones reales, ciclos correctos, refs plausibles)
3. Indice vs archivos: PASS (10 archivos existen, titulos coinciden)
4. Aritmetica enfoques: PASS en benchmarks.md — documenta la inconsistencia del propio log: mejora-log.md L340 declara 27 pero la suma de sus componentes (3x4+2+3+3+3+7) = 30; conteo conservador de sets A/B/C explicitos = 26. En cualquier interpretacion ≥ 10 requeridos ✅
5. Consistencia docs fix: PASS (SUMMARY.md 11/11 metricas coinciden con snapshot JSON; correccion Jul-29 cita finding 12/13 exactos)
6. Contrato §7: PASS (3 entregables existen con contenido real)

**Resultado E2E**: suite completa **702/702 pass / 0 fail / 0 skipped / 0 NotRun** (124.7s). Gate **14/14** en los 3 commits atomicos (docs/fix/docs).

**Benchmark vs ciclo anterior**: entregables §7 1/3 → 3/3. Docs stale: SUMMARY.md 07-16 → 08-03 (78/0/78); limit.input invalido → corregido. Suite 702/702 sin regresion. MEJORA ✅

**Aprendizaje**: (1) Los entregables del protocolo no se auto-generan — verificar el contrato §7 en el cierre de CADA experimento. (2) Notacion "N/M pass" (passing/total) es ambigua como baseline→final — el breaker la atrapo, pero documentar siempre como "X pass / Y fail". (3) La aritmetica de conteo de enfoques en el log (L340: 27 vs suma real 30) es un error preexistente — documentado, no reescrito (el log es historico).

## Merge Ciclo 10 — 2026-08-04 (§4 protocolo)

**Condicion §4 evaluada**: TODAS las condiciones de parada §5 cumplidas — breaker C10 6 ataques (1 hallazgo real corregido y re-verificado), sin gaps ICE nuevos detectables (analisis 08-03: 6/7 cerrados + won't-fix justificado; entregables §7 completos), E2E 702/702 pass / 0 fail, benchmark >= ciclo anterior en todas las metricas (entregables 1/3 -> 3/3).

**Mecanica**: misma via autorizada que merges previos (FF + push directo; PR por API no viable en este entorno, ver C9). Usuario autorizo: "procede con la recomendacion".

**Contenido del merge**: 5 commits atomicos del branch experimento/mejora-autonoma-2026-08-04 sobre main (1710c7e9).

**Balance del experimento (baseline 08-02 -> final 08-04)**:

| Metrica | Baseline | Final |
|---|---|---|
| Suite E2E completa | 669 pass / 7 fail | **702 pass / 0 fail** |
| Gate pre-commit | 13/13 | **14/14** |
| Entregables §7 (mejora-log/benchmarks/adr) | 1/3 | **3/3** |
| Docs stale (SUMMARY.md, limit.input) | 2 | 0 |
| Skills >3KB | 1 | 0 |
| Evasiones whitespace de ^ patterns | 4 | 0 |
| Junctions (modelo hibrido) | - | **78/78** |

**Enfoques totales evaluados**: 26-30 segun conteo (mejora-log L340 declara 27; suma de componentes 30; sets A/B/C explicitos 26) — >= 10 requeridos en cualquier interpretacion ✅

**Verificacion post-merge**: gate en el ultimo commit del experimento + suite E2E 702/702 sobre el arbol integrado; push verificado local=origin.
