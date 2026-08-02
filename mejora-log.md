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
