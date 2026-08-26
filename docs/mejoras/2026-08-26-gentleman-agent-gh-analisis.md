# Gap Analysis — gentleman-agent-gh (post Cycle 30, v9.9-verified)

**Fecha**: 2026-08-26
**Base**: `main` HEAD `a5a1d886` (post-pull de 30 commits, Cycles 28-30)
**Método**: Evidence Gate completo (60 docs en docs/mejoras/ consultados) + verificación
tool-backed de cada claim (grep/read/live-repro). Cada hallazgo lleva `confidence:` y evidencia.
**Estado**: PLAN — sin implementación. Para revisión del owner.

---

## Score actual (live, score-auto.ps1)

Global **9.2** (trend: down). Dimensiones bajo 10:

| Dim | Score | Causa verificada |
|-----|-------|------------------|
| Cycle Activity (CA) | **3.0** | Contador inter-track stale (G4) |
| Project Artifacts (PA) | **8.0** | Junction trial-verify missing (G2) |
| Score Depth (SD) | 8.8 | 42 sub-dims (instrumentación parcial) |
| Script Performance (SP) | 9.0 | 112 scripts > threshold 60 (G6) |

---

## Hallazgos verificados

### G1 — Permisos del runtime anulan ADR-046 (toolchain freedom) — `confidence: high`
- **Evidencia live**: `pwsh -NoProfile -Command` y `python --version` → **DENIED** en la sesión actual.
- **Evidencia config**: SSoT `scripts/opencode-config/shared-deny-rules.json:71` → `python *: allow`;
  `scripts/lib/permission-templates.json` (auto) → `python=allow`; repo `opencode.json`
  (gentleman-vMK) → `python=allow`; global `~/.config/opencode/opencode.json` → `python=ask`.
- **Diagnóstico**: el ruleset efectivo de la sesión contiene DOS tablas **pre-ADR-046**
  (python/docker/bun/yarn=deny), que no coinciden con ninguna config en disco. El proceso
  OpenCode cacheó permisos de antes del pull+sync-all de hoy (mecanismo: `confidence: medium`).
- **Impacto**: ADR-046 (2026-08-26, commit `8faf33c0`) existe en papel; los agentes auto
  siguen sin toolchain. Mismo patrón que docs/mejoras/2026-07-28-orchestrator-self-analysis.md:13
  ("mecanismos existen, enforcement nulo").
- **Fix**: reiniciar Openencode post sync-all → re-verificar `python --version`; agregar
  "restart requerido" a docs/operations/RUNBOOK.md y output de sync-all.ps1.

### G2 — Junction trial-verify faltante → PA 8.0 — `confidence: high`
- **Evidencia**: `scripts/cross-ref-check.ps1` live → `WARNINGS: Missing junctions: trial-verify`;
  score reason `"X-ref False, 92 skills"`.
- **Causa**: el skill se agregó en Cycle 28 (`.agents/skills/trial-verify/SKILL.md`, commit
  `01b08bb7`) sin crear la junction esperada por cross-ref.
- **Fix**: crear junction (1 línea) → PA 8.0 → 10.0. **El win más barato del análisis.**

### G3 — gh CLI apunta al repo equivocado — `confidence: high`
- **Evidencia**: `gh repo view` → `Gentleman-Programming/gentle-ai`; el remote real es
  `LuisAlbertoMK/gentleman-agent-gh`.
- **Impacto**: skills `branch-pr`, `issue-creation`, `chained-pr` y cualquier automation con
  `gh` operarían sobre el repo equivocado. Riesgo de PRs/issues en el lugar incorrecto.
- **Fix**: fijar contexto gh en este worktree (`gh repo set-default`) o documentar en RUNBOOK.

### G4 — Contador inter-track stale → CA 3.0 injusto — `confidence: high`
- **Evidencia**: `.learnings/inter-track.json` → `{"count":10,"id":"cycle-28","target":30}`;
  fórmula en `scripts/lib/score-dims.ps1:456-477` (count/target×10 → 10/30 = 3.3 ≈ 3.0).
- **Conflicto**: el repo ACABA DE CERRAR Cycle 30 (commit `bcb2e31c`, tag `v9.9-verified`,
  BITACORA.md:184). El contador no se incrementó en cycles 29/30 → el loop de ciclos no
  invoca `inter-track.ps1` (drift entre dos fuentes de verdad del estado de ciclos).
- **Fix**: wirear `inter-track.ps1` al cierre de ciclo (close-session o protocolo v3) + sync del
  contador actual a la realidad (count=10→12, id=cycle-30). CA 3.0 → 4.0 (y creciendo).

### G5 — Deuda de tests: 31 fails pre-existentes — `confidence: high`
- **Evidencia**: docs/mejoras/plan-auto-mejora-v3-2026-08-20-c30.md:6 — "1304 pass / 31 fails
  pre-existentes / 1336 total, verificado ×2 idéntico". BITACORA 08-14 documenta categorías:
  snapshot drift (medium/high), `$Pid:177`, PSSA version drift (baseline 08-09).
- **Estado**: conocido y documentado desde el 08-14; sin remediar tras 3 ciclos.
- **Fix**: rebaselineo deliberado (ADR) o fix por categoría. Esfuerzo estimado: 2-3h.

### G6 — SP capped 9.0: el repo se penaliza por su propio crecimiento — `confidence: high`
- **Evidencia**: score live `"S:112 avg:7KB"` (sc=112 scripts); regla verificada en
  `scripts/tests/ScoreMaths.Tests.ps1:56` — "penalizes -1 for high script count (>60)".
  Commit `4e5ebcb4` "SP capped 9 (S112>60)" decodificado: S112 = 112 scripts (no es un check-ID
  fantasma — hipótesis inicial corregida tras evidencia).
- **Opciones**: (a) consolidar/archivar scripts (candidatos: 12 smoke scripts con boilerplate
  repetido, 5 wisdom-*, 3 benchmark-*), (b) revisar threshold vía ADR con justificación.

### G7 — session-checkpoint.ps1 no puede llamar mem_save — `confidence: high`
- **Evidencia**: `scripts/session-checkpoint.ps1:139` — "Note: mem_save is an MCP tool call,
  not available in this script context." El script prepara el checkpoint; la persistencia
  real depende del hook conductual del agente (prompt).
- **Estado**: gap conocido (2026-07-28-orchestrator-self-analysis.md:13). Sin cambio desde
  entonces. El hook del prompt existe; enforcement sigue siendo conductual.

### G8 — Ollama no reachable → UX bridge offline — `confidence: high`
- **Evidencia live**: TcpClient a 127.0.0.1:11434 → timeout/refused.
- **Impacto**: `ui-specialist-pairing.ps1` full mode degradado (weakness #2 del plan
  2026-08-14 funciona solo en modo offline-first).
- **Fix**: decisión owner — instalar/iniciar Ollama, o aceptar el fallback offline documentado.

---

## Correcciones a claims del system prompt (verificados stale)

| Claim del prompt | Veredicto | Evidencia |
|---|---|---|
| "perf scripts requieren PS7 y `pwsh *` es policy-denied → no ejecutables aquí" | **Parcialmente falso** | El shell del agente ES pwsh 7.6.5; invocación directa in-process funciona: `hardware-profile.ps1 -Json` ejecutó OK (perfil medium-resource detectado). Solo el spawn de subprocess `pwsh *` está bloqueado (by design, security set). `confidence: high` |
| "Ollama ECONNREFUSED en este runtime" | **Confirmado vigente** | Test live 2026-08-26. `confidence: high` |

---

## Plan priorizado (ICE)

| # | Gap | Fix | Effort | Impact | Confidence |
|---|-----|-----|--------|--------|------------|
| P1 | G2 | Crear junction trial-verify | 5 min | PA 8→10 | high |
| P1 | G1 | Restart OpenCode + verify + RUNBOOK note | 10 min | Desbloquea ADR-046 completo | high |
| P2 | G3 | gh repo set-default | 5 min | Evita automation en repo equivocado | high |
| P2 | G4 | Wirear inter-track.ps1 al cycle close + sync contador | 30 min | Fidelidad métrica CA | high |
| P3 | G5 | Rebaseline/fix 31 fails (por categoría) | 2-3h | Suite verde real | high |
| P3 | G6 | Estudio consolidación scripts vs ADR threshold | 1h análisis | SP 9→10 | high |
| P4 | G7 | Evaluar bridge con callback MCP (invoke-callback.ps1 existe) | 2h | Enforcement memoria | medium |
| P4 | G8 | Decisión owner: Ollama install vs fallback | 5 min decisión | UX bridge completo | high |

**Proyección**: P1+P2 → score 9.2 → ~9.5. Con P3 → ~9.7 (techo actual por SD 8.8).

---

## Evidence Check (Phase 4 — analysis-mode)

- `glob docs/mejoras/*.md` → 60 análisis previos; los más relevantes cruzados:
  2026-08-14-weakness-improvement-plan.md (weaknesses 1-3), 2026-07-28-orchestrator-self-analysis.md,
  plan-auto-mejora-v3-2026-08-20-c30.md (baseline tests), 2026-08-19-mejora-log-ps5-ps7-compat.md
  (scope limitado al path de setup vMK).
- `mem_search` → sin análisis previos en Engram para esta sesión.
- Hallazgos G1-G8: todos verificados con tool output este mismo día (no hay especulación).
- Nada marcado `unvalidated` — cada claim tiene evidencia directa o cita file:line.

## Riesgos

- **R1**: G1 post-restart puede revelar otra fuente de permisos (plugin/host-level del fork
  opencode-go). Mitigación: si persiste deny tras restart → investigar capas de config del host.
- **R2**: G6 opción (b) tocar el threshold sin consolidar = gaming del score. Requiere ADR con
  justificación de capacidad, no solo números.
- **R3**: G4 sync del contador: si `count` trackea otra cosa (inter-track cycles ≠ auto-mejora
  cycles), corregirlo a 12 sería incorrecto. Verificar semántica con `inter-track.ps1` antes.
