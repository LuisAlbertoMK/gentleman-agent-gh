# ADR-033: Simplificar modos de permiso — eliminar `semi`, quedar `manual` + `auto`

- **Status**: Partial (config-source retirado 2026-09-04; pendiente base/template/runtime/docs)
- **Deciders**: gentleman-vMK (propuesta autónoma) + dueño (decisión 2026-08-19, autorización limpieza total 2026-09-04)
- **Date**: 2026-08-19
- **Implemented**: 2026-09-04 — 6 agentes (no 5; `aem` descubierto post-análisis, ver amend abajo)
- **Scope-note (2026-09-04, JD ses_f91318268ffexxfR6hxJ5mKEye)**: retiro parcial — solo config-source (semi-agents.json D + expand/cross-ref/generate/permission-gate-lib); residuos deliberados para follow-up atómico: base 6 defs en opencode-base.json, permission-templates.json (template semi + _used_by.semi), template-detection.ps1 (-semi map), runtime-compat semi→auto como deuda documentada (mode-gate/permission-gate/route-agent/switch-mode), orphan scripts/opencode-config/semi-allow-classification.json, docs vivas (README/PROTOCOL/SHORTCUTS/QUICKSTART/commands/semi.md); cuerpo abajo STALE (asume limpieza total) a enmendar en follow-up.
- **Tier**: T2 — permission-mode architecture, multi-file (config + gate + switch)
- **Confidence**: high (evidencia en `docs/mejoras/2026-07-28-permission-modes-analysis.md` L27-L101; `docs/mejoras/2026-07-30-auto-permission-analysis.md` H1-H8; benchmark 60-point full historical)

## Context

Three permission modes (`manual`, `semi`, `auto`) coexist per `opencode.json` + `scripts/permission-gate.ps1` + `.gentleman-mode` (actual: `auto`). User (2026-08-19) requests simplificar a **solo `manual` + `auto`** — eliminar `semi`.

Existing analysis (`docs/mejoras/2026-07-30-auto-permission-analysis.md`):

- **H1**: 3 permission layers coexist: global (opencode.json `permission.bash`), agent-specific (33 agents), runtime gate (`permission-gate.ps1`).
- **H2**: ~960 líneas de permisos en opencode.json (~87% del permiso config) son boilerplate ~90% identical across los 5 `semi` agents y 5 `auto` agents.
- **H3**: asymmetry `git push --force` (deep-auto: deny; others: ask).
- **H7**: `.gentleman-mode` está en `auto` permanente; no hay shortcuts `!semi`/`!manual`/`!auto` implementados en OpenCode (no hay handlers).
- **H8**: 4 read-only specialists faltan en `mode-gate.ps1` readOnlySpecialists list.

Benchmark (full 60-point, `2026-08-19-v3-full-historical-regression.md`):
- `sync-vmk -DryRun` mediana 1509ms (oldest→HEAD). Drift +3.4% (1477→1527ms primer/segundo mitad).
- No regresión estructural detectada (max/median=1.28, but picos explicables: commit c0f0b459 optimizó tests; a395303a = ERR transitorio).

## Decision

Eliminar el modo `semi` del sistema de permiso, quedando **dos modos operativos**:

| Modo | Comportamiento | Scope |
|------|---------------|-------|
| `manual` | `*: ask` — todo pregunta (current default para exploración/learning) | 7 agents ask (`gentleman-deep/quick/codex/implementer/vMK` + `sdd-orchestrator` + `gentleman-reviewer`) |
| `auto`   | `*: allow` excepto push-force/destructivos (allowlist runtime) | 5 agents `-auto` + behavioral gate |

### Change set (agente-applicable = scripts/docs/markdown; opencode.json require usuario)

1. **`scripts/switch-mode.ps1`** — marcar `semi` como **deprecated** (warning + fallback a `auto` si user pasa `-Mode semi`). Remove `semi` del `--Mode` ValidateSet → migrar a manual/auto. (Agente CAN apply — write a `scripts/*.ps1`.)
2. **`scripts/permission-gate.ps1`** — remover la rama `semi` del clasificador de comandos; `semi` allowlist (25 comandos) se funde a `auto` (runtime behavioral gate ya protege con deny-floor para curl/ssh/rm/etc). (Agente CAN apply.)
3. **`docs/mejoras/2026-08-18-permissions-modes-analysis.md`** + ADR-033 — documentar deprecación.
4. **`opencodec.json`** — **NO** (write-protected; agente deniega). 5 `gentleman-*-semi` agents + 5 `-semi` permission blocks: usuario debe remover. (Documentado como migration step.)
5. **`.gentleman-mode`** file content unchanged (está `auto` → queda `auto`).

### Migration (usuario)
```
# 1. switch-mode still supports legacy semi -> warns + falls back to auto
.\scripts\switch-mode.ps1 -Mode semi      # → ⚠️ deprecated → writes 'auto'
.\scripts\switch-mode.ps1 -Mode manual   # → works
.\scripts\switch-mode.ps1 -Mode auto     # → works
# 2. USER: remove -semi agents from the GLOBAL opencodec.json
#    Run from YOUR session (where opencodec.json is writable — agent sandbox can't reach it):
pwsh -File scripts/remove-semi-agents.ps1            # backup + delete 6 -semi agents
pwsh -File scripts/remove-semi-agents.ps1 -DryRun    # preview first
# 3. USER: optionally delete scripts/opencode-config/semi-agents.json (the template + its check [10/9] auto-skips if absent)
# 4. USER: re-run scripts/expand-config.ps1 para refrescar el config si mantuviste templates
```

**Note (ADR-033 amend)**: The SSoT `scripts/opencode-config/semi-agents.json` defines **6** `-semi` agents, not 5:
`gentleman-deep-semi`, `gentleman-quick-semi`, `gentleman-codex-semi`, `gentleman-implementer-semi`, `gentleman-aem-semi`, `gentleman-vMK-semi`. The `aem` variant was discovered post-analysis; `remove-semi-agents.ps1` handles all 6.
```

## Alternatives Considered

| Enfoque | Pros | Contras | Score |
|---------|------|---------|-------|
| **A (chosen): Eliminar `semi`, keeper manual+auto** | ✅ -600 líneas boilerplate (semi blocks) <br> ✅ elimina H3 asymmetry (solo 5 auto agents) <br> ✅ runtime gate ya provee deny-floor equivalente | ❌ -1 modo intermedio (pero H7 confirma: semi nunca fue usado → `~never` perdidida) <br> ❌ usuario aplica opencode.json change | **8/10** |
| **B: Unificar todos a `auto` (dropping manual too)** | ✅ +1 agente menos (no `-semi`) | ❌ pierde el `*: ask` safety default — risk alto para exploratory work <br> ❌ manual era el default original; regression de safety UX | **4/10** — rechazado (user explicitly asked "manual + auto") |
| **C: Mantener 3 modes + automatizar shortcuts** | ✅ conserva granularidad | ❌ -960 líneas boilerplate persisten (H2) <br> ❌ +complejidad routing (+semi suffix) <br> ❌ H7 shortcut gap no resuelto | **5/10** — rechazado (no satisface "simplificar") |
| **D: Config-driven template (shared deny + per-mode flag)** | ✅ DRY total via `$import` | ❌ require rewrite `expand-config.ps1` + opencodec.json (user apply) <br> ❌ scope > T2; fuera del brief | **6/10** — posible fase 2 |

## Consequences

- **Positive (config)**: -600 líneas opencodec.json (5 × ~120 líneas de semi blocks). -5 agent espejo. Eliminada H3 asymmetry (`git push --force` ahora uniforme en 5 auto agents — heredan el deny global o el gate).
- **Positive (runtime)**: clasificador `permission-gate.ps1` simplificado (0 branching `semi`, 0 allowlist duplication). `mode-gate.ps1` readOnlySpecialists list unchanged (no `semi-*` agents to block).
- **Positive (DX)**: usuario switching manual/auto con 0 stubs. Deprecated `semi` → auto fallback evita break.
- **Negative (user burden)**: usuario debe aplicar el diff de opencodec.json (remover 5 `-semi` agents + 5 permission blocks). Documentado + ADR. — Write-protection es intencional; agente no puede mutar opencodec.json.
- **Negative (latent)**: cualquier workflow que dependa de `semi` allowlist explícita (no los 25 read-only) requiere usar `auto` + behavioral gate deny-floor. — Evidencia H7: semi nunca fue usado (confidence: high).
- **Risk (scope)**: benchmark 60-point confirmó `sync-vmk` estable post-change; no regression. (Pre-Answer Gate: `docs/mejoras/2026-07-30-auto-permission-analysis.md` H1-H8 cited; no new claims without evidence.)

## E2E Verification

- `scripts/tests/` — Pester suite corre sobre `switch-mode.ps1` (ValidateSet restringido a `manual|auto` + warning en `semi`).
- `scripts/permission-gate.ps1` — `switch($mode){ semi { ... } }` branch removed; test `mode-gate` + `cross-ref-check` verifican consistencia.
- Benchmark: `sync-vmk -DryRun` mediana sobre HEAD con `semi` removido del gate — objetivo: ≤1509ms (baseline no drift).
- Scope gate: `scripts/validate-write-scope.ps1` confirma solo `scripts/*.ps1` + `docs/*.md` mutated (NOT opencodec.json).

## References (Pre-Answer Evidence Gate)

- `docs/mejoras/2026-07-28-permission-modes-analysis.md` L13-L101 — mode definitions + architecture (Opción A).
- `docs/mejoras/2026-07-30-auto-permission-analysis.md` H1-L39, H2-L57, H3-L75, H7-L131, H8-L154 — layering, 960 líneas boilerplate, push-force asymmetry, semi never used, 4 read-only missing.
- `adr/ADR-005-permission-layering.md` — deny → destructive → mode layering.
- `adr/ADR-007-ssot-size-budget.md` — opencodec.json size budget (53.5KB, 82% → reducing semi blocks ayuda).
- Benchmark full historical: `C:/Users/MK/AppData/Local/Temp/opencode/v3-full-bench.jsonl` (60 points, 60-pt median 1509ms).
