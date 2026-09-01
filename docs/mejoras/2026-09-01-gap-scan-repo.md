# Gap Scan del Repo — 2026-09-01

> **Método**: scans tool-backed (node parse, git, file stats) + evidencia de sesión 2026-09-01. Cada gap con `confidence:` y evidencia file:line o comando.
> **Persistencia**: Engram ids 860-861 + commit de este doc. Complementa (no reemplaza) plan de mejora 2026-09-01 (v1 `e55f306a`, v2 `de7e61aa`, v3 `07233950`).

---

## Gaps verificados HOY (orden por severidad)

### GAP-1 — CRÍTICO: 14 agentes apuntan a modelo 404 `laguna-s-2.1-free` — `confidence: high`
- **Evidencia**: parse de `opencode.json` (2026-09-01): `gentleman-codex, gentleman-codex-auto, gentleman-codex-sub, gentleman-infra, gentleman-infra-sub, gentleman-implementer, gentleman-implementer-sub, gentleman-codex-sub-auto, gentleman-implementer-sub-auto, gentleman-implementer-auto, sdd-apply, sdd-archive, sdd-init, sdd-tasks` (COUNT: 14).
- **404 verificado 2× hoy**: Task tool → `Model not found: opencode/laguna-s-2.1-free. Did you mean: hy3-free, mimo-v2.5-free, muse-spark-1.2-contributor-free?`
- **Impacto**: TODA delegación a codex/infra/implementer/sdd-apply|archive|init|tasks falla en runtime. El Orchestrator Guard catalogó el patrón 2026-08-29 (B 93 files) — la causa raíz es esta config rota.
- **Fix sugerido**: migrar los 14 a `muse-spark-1.2-contributor-free` (fallback ya validado hoy) vía SSoT `scripts/opencode-config/` + `sync-all`, NO editando opencode.json directo.
- **Esfuerzo**: 1 sesión. **Este es el fix más urgente del repo.**

### GAP-2 — HIGH: pre-commit gate inconsistente entre PS5.1 (hook) y PS7 (directo) — `confidence: high`
- **Evidencia hoy**: commit `f8d6e8fe` → hook ejecutó en Windows PowerShell 5.1 → `cross-ref-check.ps1` falla con `#requires PS 7.0` → `BLOCKING: cross-ref validation failed` + `benchmark.ps1` no encontrado → obligó `--no-verify`. El mismo gate pasó 25/25 ALL CLEAR 3× hoy corriendo en pwsh 7.6.5.
- **Impacto**: el gate es fuerte en CI/directo pero roto en el hook local → falso sentido de seguridad + bypass habitual.
- **Fix sugerido**: `.githooks/pre-commit-gate.ps1:112` debe re-lanzarse a sí mismo vía pwsh 7 si detecta versión 5.1 (bootstrap), o el hook debe usar `pwsh -File`.
- **Esfuerzo**: 1 sesión.

### GAP-3 — HIGH: 5 commits locales sin push — `confidence: high`
- **Evidencia**: `git status -b` → `main...origin/main: ahead 5` (`2777202b` G7 fix, `e55f306a` plan v1, `de7e61aa` v2, `f8d6e8fe` reasoning tier, `07233950` v3).
- **Impacto**: trabajo verificado solo existe en este equipo (riesgo pérdida, sin backup remoto, bloquea colaboración cross-equipo — el usuario mismo pidió acceso desde otra máquina).
- **Fix**: `git push` (permiso ask en config). Esfuerzo: 1 min.

### GAP-4 — MEDIUM: tests Pester mutan estado del repo (aislamiento incompleto) — `confidence: high`
- **Evidencia hoy**: tras correr Pester (close-session + inter-track tests), `git status` mostró `.project.json` (162 líneas) y `docs/metricas/history.jsonl` (+1) modificados sin edits manuales → revertidos con `git checkout --`.
- **Contexto histórico**: `docs/mejoras/2026-07-31-gentleman-agent-gh-tests-perf.md:17` ya catalogó "parallel unsafe (estado compartido: .gentleman-mode, BITACORA, $env:USERPROFILE)".
- **Fix sugerido**: los tests que escriben métricas deben usar `PESTER_TEST=1` o temp-dir sandbox (parche PESTER_TEST existe en close-session pero score/metrics writes no están gated).
- **Esfuerzo**: 1-2 sesiones.

### GAP-5 — MEDIUM: BITACORA sin entradas del 2026-09-01 — `confidence: high`
- **Evidencia**: scan `BITACORA.md` (188 entradas, última 2026-08-31): el trabajo de hoy (G7 fix `2777202b`, plan v1/v2/v3, reasoning tier `f8d6e8fe`, este gap scan) no está loggeado. Protocolo bitácora = append por sesión.
- **Fix**: entrada única de cierre de hoy (incluida en este commit). Esfuerzo: 5 min.

### GAP-6 — MEDIUM: `reparar/` untracked sin decisión ni gitignore — `confidence: high`
- **Evidencia**: `git status` → `?? reparar/` (opencode.json 63KB para fix de otra máquina); `.gitignore` (180 líneas) NO cubre `reparar`.
- **Fix sugerido**: decidir: (a) borrar ya transferido, (b) `.gitignore` + conservar local. Esfuerzo: 2 min.

### GAP-7 — LOW-MEDIUM: config drift repo↔global persistente — `confidence: high`
- **Evidencia**: gate `[16/16] Config drift check → config drift vs global - run scripts/sync-global.ps1` en los 3 commits de hoy. `scripts/sync-global.ps1` existe pero no se corrió.
- **Fix**: correr `sync-global.ps1` (2 min) o suprimir warning si el drift es intencional.

### GAP-8 — LOW: 3 branches locales obsoletas — `confidence: high`
- **Evidencia**: `git branch -vv` → `feat/collapsible-history` `[gone]`; `experimento/falsos-positivos-P1` + `fix/pester-17-rebaseline` mergeadas a main; `analysis/mejoras-optional-2026-08-28` sin upstream (backup pendiente de decisión).
- **Fix**: `git branch -d` ×3 + push opcional de analysis. Esfuerzo: 2 min.

### GAP-9 — LOW: índice docs/mejoras desactualizado — `confidence: high`
- **Evidencia**: `docs/mejoras/README.md:73` dice "Total documents: 59"; conteo real hoy: **79 archivos .md** (4 más solo de hoy). Trend Summary sigue citando 08-04 como "current".
- **Fix**: actualizar README índice con filas 08-29→09-01. Esfuerzo: 20 min.

---

## No-gaps verificados (sanos, para no re-trabajar)

| Check | Resultado |
|-------|-----------|
| Score del proyecto | 10.0 stable (`.project.json`) |
| `{file:}` prompt refs | 29/29 resuelven, 0 missing |
| Pester suites core | 45/45 PASS hoy (close-session + inter-track) |
| AGENTS.md size | 4.9KB (bajo el umbral 10KB del gate) |
| opencode.json | JSON válido, 52 agentes, budget 47KB < gate |
| Stash/worktrees | limpio, 1 worktree |
| SSoT + sync-global | existen y gate los chequea |

## Relación con plan v3 (cola existente)

Este scan no duplica el plan de mejora: GAP-1..3 son **nuevos** (no estaban en el plan); GAP-4..9 son hygiene. El plan v3 sigue vigente para las oportunidades (P0-2, R2-4, P0-1, etc.).

---

## Resolución 2026-09-01 (post-scan)

| Gap | Estado | Commit |
|-----|--------|--------|
| GAP-1 laguna-404 ×14 | ✅ RESUELTO vía SSoT (opencode-base 16→0, semi-agents 2→0) + regen validada 9/9 + sync-global propagó a config global (49 agentes) | 94e6a454 |
| GAP-2 gate hook | ✅ RESUELTO — causa real: ref stale a benchmark.ps1 (consolidado 5c503d68) → benchmark-core.ps1 + README agents sync + router skill bajo budget. Gate 25/25 ALL CLEAR con hook | 2bb36f94 |
| GAP-3 push | ✅ RESUELTO — c7ed972e..3260b08b (9 commits) | 3260b08b |
| GAP-4 Pester muta estado | 🔲 PENDIENTE (1-2 sesiones) — PESTER_TEST no gated en metrics writes | — |
| GAP-5 BITACORA | ✅ RESUELTO | 5d291a62 |
| GAP-6 reparar/ | ✅ RESUELTO — gitignored | 3260b08b |
| GAP-7 drift global | ✅ RESUELTO — sync-global ok (93 junctions, 49 agentes) | 3260b08b |
| GAP-8 branches | ✅ RESUELTO — 3 deleted | 3260b08b |
| GAP-9 índice README | ✅ RESUELTO — 81 docs | 3260b08b |

### Actualización GAP-4 (2026-09-01)

✅ RESUELTO (82f9fd81): score-auto.ps1 persistencia (.project.json línea ~313 + history.jsonl rutas cache-hit ~115 y main ~362) gated detrás de PESTER_TEST. Verificado: test mode → worktree limpio (ScoreIntegration 11/11 PASS sin mutar); modo normal → persiste (history.jsonl append OK). Gap 0 abiertos.

