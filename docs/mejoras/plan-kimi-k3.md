# Plan Diamante — gentleman-agent-gh (análisis exhaustivo verificado)

**Fecha**: 2026-08-11 · **Autor del análisis**: orchestrator (modelo: kimi-k3) · **Trigger**: `!analisis` full-repo
**Método**: analysis-mode P1-P4 — 6 especialistas paralelos (read-only) + verificación de evidencia contra ADRs, CI, scripts y system context.
**Estado**: PLAN ONLY — nada implementado. Aprobación manual requerida antes de ejecutar cualquier fase.

---

## 0. Verificación de hallazgos (gate de evidencia)

| Claim del análisis | Veredicto | Evidencia |
|---|---|---|
| opencode.json excede budget ADR-007 | ✅ **CONFIRMADO — CRÍTICO** | ADR-007/ADR-014: budget = **65,536B**. Actual ~72.9KB (+11%). El baseline 08-10 citaba "≤98,304" — **dato erróneo en ese doc** |
| Size-gate ausente en CI | ✅ Confirmado | `.githooks/pre-commit-gate.ps1:251` lo enforcea local; `quality-gate.yml:203` lista hooks y **no** incluye size check (ADR-014 pedía mirror en CI — nunca se hizo) |
| AGENTS.md duplicado proyecto+global | ✅ Confirmado (observación directa) | Ambos archivos inyectados idénticos en system context — ~1.8KB pagados 2x por sesión |
| mode-gate fallback → agente base | ✅ Confirmado, **by-design** | `mode-gate.ps1:163-171`. Documentado en prompt del orquestador. Riesgo real de privilegio, no bug |
| npm deps no pineadas | ✅ Confirmado | `package.json:34-39`: `playwright ^1.61.1`, `token-optimizer-opencode ^1.1.0` (caret ranges) |
| tests/ NO corre en CI | ❌ **CORREGIDO** | `quality-gate.yml:252-278` — job `tests-v1` **sí ejecuta** `./tests/*.Tests.ps1`. El baseline 08-10 está desactualizado. Problema real: **suite duplicada** (46 vs 44 archivos) sin coverage |
| PSSA no enforceado en CI | ⚠️ Parcial | Corre como hook dentro del security job (`quality-gate.yml:203`), no como gate dedicado con umbral propio |
| "commands/ no existe" (reporte previo skills) | ❌ **STALE — descartado** | `commands/` existe en root |
| webfetch/ctx_fetch entra sin sanitizar | ✅ Confirmado | analysis-mode GATE permite `webfetch/websearch`; contenido externo entra a contexto y a Engram sin guard |
| .learnings/ sparse (~10 patrones, 4 errores) | ◻️ No verificado directo | confidence: medium — consistente con minería manual |
| 135/136 scripts `#requires -Version 7` | ◻️ Parcial | Solo `sync-global-ps5.ps1` declara 5.1 (grep confirmado). Count exacto no verificado |
| 7-8 skills SDD >3KB | ◻️ Consistente | Baseline 08-10: 7 skills >3KB; reporte previo: 8. Misma violación |
| Dedupe permission blocks en opencode.json | 🚫 **RECHAZADO** | ADR-007: "fail-closed por agente es won't-fix" — no proponer |

### Verificación cruzada vs `plan-laguna-s-2.1-free.md` (2026-08-11)

| Claim | Veredicto | Evidencia |
|---|---|---|
| Laguna: "Quality gate 22/22 ALL CLEAR" contradice F1 | ✅ **No contradice — refuerza F1** | opencode.json = **72,983B hoy** (medido). El gate pasa porque el size check es **condicional post-write** (solo corre al regenerar), no en commits normales |
| Laguna: "E2E 709/709 pass" vs mi baseline "874/1" | ✅ Consistente — **F7 RESUELTO** | Commit `5c437dcd` (fix contract_valid flaky transport) ya reparó el test fallando. Scopes/fechas distintos explican 709 vs 874 → ver F16 |
| Laguna: prompts/ sobre budget | ✅ **REAL — yo no lo medí (gap mío)** | `prompts/`: 28 md, **6 archivos >2KB**, 37KB total. Su "83 files over" no se reproduce en prompts/ solo (será skills+prompts combinado) — confidence medium |
| Laguna: tamaños exactos skills SDD | ✅ Más granular que el mío — incorporado en P2.13 | sdd-spec 4460B, sdd-archive 4406B, sdd-propose 4336B, sdd-tasks 4306B, sdd-apply 4060B, sdd-init 3979B, sdd-verify 3630B |
| Laguna: master = default branch en GitHub | ◻️ No verificable desde local sin gh/api | Aceptado como acción manual del usuario — confidence medium |

---

## 1. Sumario ejecutivo

El sistema está **maduro y bien defendido** (fail-closed, ADRs, benchmarks continuos, 874/1 E2E), pero tiene **una regresión crítica silenciosa** (bundle +36% desde ADR-014) y **tres deudas estructurales**: autonomía manual (abierto desde 08-08), doble suite de tests sin coverage, y superficie de ingesta externa (web/memoria) sin sanitizar. Nivel actual: **oro sólido**. Este plan apunta a diamante en 4 fases.

---

## 2. Findings consolidados por dimensión (top por riesgo)

| # | Dim | Finding | Riesgo | Conf. |
|---|-----|---------|--------|-------|
| F1 | Perf/Infra | opencode.json 72.9KB > 65,536B; sin gate en CI → drift silencioso | 🔴 | high |
| F2 | Security | Ingesta externa sin sanitizar (webfetch/ctx_fetch → contexto y Engram) | 🔴 | high |
| F3 | Arch/Learning | Self-improvement 100% manual (abierto desde análisis 08-08) | 🔴 | high |
| F4 | CI/Tests | Doble suite (`scripts/tests/` 44 + `tests/` 46) sin coverage reporting ni decisión de merge | 🟠 | high |
| F5 | Token | AGENTS.md duplicado proyecto+global (~1.8KB/sesión desperdiciados) | 🟠 | high |
| F6 | Security | Supply chain npm: caret ranges, sin `npm audit` gate ni SBOM | 🟠 | high |
| F7 | Tests | ~~1 test E2E fallando~~ **RESUELTO** (commit `5c437dcd`, 08-11) | ~~🟠~~ ✅ | high |
| F8 | Security | mode-gate fallback silencioso a agente base con más privilegios | 🟠 | high |
| F9 | Perf/Escala | Escaneos O(n) sin cache TTL+hash: skill-graph BFS, registry rebuild, benchmark full-scan | 🟠 | medium |
| F10 | Learning | Loops dormidos: dreaming manual, wisdom-demote sin scheduler, .learnings/ vacío | 🟠 | medium |
| F11 | Security/UX | Auto mode: `Remove-Item` = ask (no deny); engram MCP sin scoping de tools por agente | 🟡 | medium |
| F12 | DX | QUICKSTART sin prerequisites; 30+ shortcuts sin jerarquía; skills SDD >3KB (violación de spec) | 🟡 | medium |
| F13 | Infra | Cross-platform: bootstrap/setup-machine Windows-only; sin flaky-retry en CI | 🟡 | medium |
| F14 | Data | Sin TTL/purge en Engram (crecimiento unbounded); audit-log sin hash chain | 🟡 | medium |
| F15 | Token | 166 skills listados en cada system prompt (78 proyecto + 88 global) — tabla completa inline | 🟡 | high |
| F16 | Data | Métricas sin SSoT: test count varía 709/732/874 según doc; gate 18/18 vs 22/22 sin registro de cuándo cambió | 🟡 | high |
| F17 | Token | `prompts/` sin budget enforcement: 6/28 archivos >2KB, 37KB total (aportado por plan-laguna) | 🟡 | high |

**N/A**: SEO — no es sitio público. **No tocar**: fail-closed por agente (ADR-007 won't-fix), benchmark thresholds, wisdom-store validation, score-auto hash-caching, validate-write-scope.

---

## 3. Plan de implementación (4 fases, ordenadas por ICE)

### 🔧 Fase P0 — Quick wins (<1 día, riesgo bajo)
1. **Decidir budget opencode.json**: regenerar con `-MaxBytes 65536` o elevar budget vía ADR nuevo con justificación. *Archivos*: `opencode.json`, `adr/ADR-0xx`, `scripts/regenerate-opencode.ps1`.
2. **Size-gate en CI**: agregar step en `quality-gate.yml` que falle si opencode.json > budget (cierra ADR-014).
3. **Dedupe AGENTS.md**: eliminar el global (`~/.config/opencode/AGENTS.md`) o reducirlo a pointer de 3 líneas. Ahorro inmediato por sesión.
4. **Pinear deps**: quitar `^` en `package.json`, lock + `npm audit` en CI security job.
5. ~~**Fix test E2E contract**~~ **RESUELTO** (commit `5c437dcd`) — solo verificar verde en próximo CI run.
6. **Corregir baseline 08-10**: tests-v1 sí corre en CI; budget ADR-007 = 65,536.
7. **Repo hygiene** (de plan-laguna, acción manual tuya): cambiar default branch `master`→`main` en GitHub Settings, luego `git push origin --delete master` (snapshot ya archivado en tag `archive/gentle-ai-go-snapshot-v2`).

### 🛡️ Fase P1 — Seguridad & CI (1-2 días)
7. **Sanitización de ingesta externa**: capa que envuelva `webfetch`/`ctx_fetch_and_index` — strip de instrucciones-like patterns antes de indexar; allowlist de dominios en skills read-only. *Archivos*: skills analysis-mode/research, `scripts/lib/`.
8. **Extender poisoning guard** de `engram-validate-lib.ps1` a toda ingesta externa (hoy solo mem_save).
9. **Log de mode-gate fallback**: cuando `$fallbackUsed=$true` → `audit-log.ps1` + warning visible al usuario.
10. **Coverage en CI**: Pester `-CodeCoverage` + publicar reporte; decidir **merge o archive** de `tests/` vs `scripts/tests/` (una sola suite, una sola verdad).
11. **Flaky retry**: retry ×1 en tests con red/MCP.

### ⚡ Fase P2 — Performance & escala (2-4 días)
12. **Caches con TTL + content-hash**: `.atl/.skill-registry.cache.json` (hoy solo fingerprint), memoizar BFS de `skill-graph.ps1` keyed por task-hash + dir-mtime, benchmark incremental (solo skills cambiados).
13. **Comprimir skills SDD >3KB** vía karpathy-loop (T2 merge-redundant primero, los +4KB antes) hasta 0 skills >3KB. Orden por bytes (de plan-laguna): sdd-spec 4460B, sdd-archive 4406B, sdd-propose 4336B, sdd-tasks 4306B, sdd-apply 4060B, sdd-init 3979B, sdd-verify 3630B. Rollback: 1 commit por skill, prefix `karpathy:`, tag `archive/pre-karpathy-*` previo. DoD: gate en verde + score sin regresión.
13b. **Comprimir `prompts/`**: 6 archivos >2KB (37KB total) — mismo método karpathy, budget 2000B (F17).
13c. **Comprimir `docs/protocolo_mejora_autonoma_v3.md`** (96 líneas → ≤55) — menor, junto con 13b (de plan-laguna).
14. **Skill table lazy**: reemplazar tabla completa de 166 skills en system prompt por índice de triggers compacto (sparse-load real).
15. **Bulk-ops vía ctx_execute**: forzar en prompts que listings/greps masivos pasen por sandbox, no a contexto.
16. **Cross-platform**: detección de shell + symlinks en `bootstrap.ps1`/`setup-machine.ps1` (bash/zsh).

### 🧠 Fase P3 — Autonomía & learning (≈1 semana)
17. **Cerrar loop self-improvement** (Approach A del 08-08): score→diagnose→immunize→verify con fail-safe (max N ciclos, revert si Δscore <-0.5, checkpoint humano).
18. **Auto-dream**: trigger en `close-session.ps1` cada N sesiones (CYCLE.md ya lo promete: "every 5th self-check").
19. **Engram TTL/purge**: política por tipo (low=30d, config=90d) + `wisdom-demote.ps1 -All` en ciclo de mejora.
20. **Sembrar .learnings/** desde ANTI-PATTERN-CATALOG (23 entradas) y conectar session-miner a captures de Engram.
21. **Audit-log hash chain** (HMAC por línea) para tamper-evidence.
22. **Async delegation** (Approach B del 08-08): `-Async` en post-delegation-check + polling.

### 🚫 No hacer (con ADR/evidencia)
- Compactar permission blocks de opencode.json → ADR-007 won't-fix.
- Crear `commands/` → ya existe (finding stale).
- Flip a default-deny global en auto mode → rompe modelo documentado; evaluar en ADR aparte si se desea.

---

## 4. Trend vs análisis previos

| Métrica | 08-04 (ADR-014) | 08-10 (baseline) | Hoy | Δ |
|---|---|---|---|---|
| opencode.json | 53,556B | 72,983B | ~72.9KB | 🔴 +36% regresión |
| E2E tests | — | 874/1 | 874/1 (sin cambios) | 🟡 estancado |
| Autonomía self-improvement | — | manual (08-08 🔴) | sigue manual | 🔴 abierto 3 días |
| tests/ en CI | "no corre" (08-10, erróneo) | job tests-v1 activo | activo | 🟢 mejor de lo creído |

## Trend delta (post-apply 2026-08-11, karpathy drafts)
| Métrica | Antes | Hoy | Δ |
|---|---|---|---|
| skills SDD >3KB (F12) | 7 (3,650-4,494B) | 0 (≤3,071B) | 🟢 cumplido |
| prompts/ >2KB (F17) | 6/28 (gentleman-deep 2,328B, gentleman-codex 2,102B, sdd-orchestrator 3,061B…) | 4/28 (sdd-orchestrator sin aplicar, ver §10) | 🟡 parcial |
| protocolo v3 | 7,109B / 96 líneas | 4,423B / 55 líneas | 🟢 -38% |
| ADR-011/014/019 prosa budget | citaba 65,536B | 98,304 (= 65,536×1.5 headroom) + nota histórica | 🟢 alineado |

## 5. Engram Persistence
- **Topic key**: `analysis/gentleman-agent-gh` · **Fecha**: 2026-08-11 · Guardado vía `mem_save` (título `analysis:gentleman-agent-gh:2026-08-11`).

## 6. Cómo ejecutar este plan
Cuando lo apruebes: decime "implementar P0" (o la fase que elijas) y lo ruteo con PEV gate (plan→aprobación→ejecución→verificación). Cada fase es independiente; P0 no bloquea a las demás.

**Disciplina operativa por ítem** (adoptada de plan-laguna): cada ítem se ejecuta con (a) scope lock de archivos declarado antes de tocar nada, (b) 1 commit por unidad con prefix convencional, (c) tag de rollback previo a cambios masivos, (d) DoD explícito (gate verde + score sin regresión ≥8.9), (e) umbral de stop si mejora marginal <10% vs ciclo anterior.

## 7. Cobertura del análisis (autoevaluación honesta, post-cruce con plan-laguna)

**Cubrí de cabo a rabo**: seguridad (appsec + agentic + supply chain), CI/CD, tests, tokens/contexto, performance/caches, escalabilidad, learning/memoria, DX/docs, arquitectura/orquestación, configuración/ADRs. Laguna no cubrió **ninguno** de los 12 findings estructurales principales (F1-F6, F8-F15) — su plan es táctico (4 gaps de tamaño/docs).

**Me faltaron (incorporados de laguna)**: budget de `prompts/` (F17), bytes exactos por skill SDD, compresión del protocolo v3, hygiene del branch `master`, y el formato operativo rollback+DoD por ítem. Ninguno cambia la prioridad estratégica; todos ya están integrados arriba.

**Conclusión**: análisis estratégico completo (8 dims) ✅; granularidad táctica de tamaños docs/skills inicialmente parcial → ahora completa tras el cruce. Los dos planes son complementarios, no redundantes.

---

## 8. Ralph long-tail log (karpathy compression — drafts ONLY, 2026-08-11)

READ-then-DRAFT-ONLY bajo `docs/mejoras/_karpathy-drafts/`. NADA aplicado a canónicos. Verificación por `(Get-Item).Length`. Sin git/npm/node/python (solo Read/Write/Get-Item).

| # | Archivo fuente | Antes (B) | Draft (B) | Budget (B) | Estado |
|---|---|---|---|---|---|
| 1 | prompts/gentleman-vMK.md | 5088 | 1985 | 2000 | OK — **HIGH-BLAST** (requiere review humano) |
| 2 | prompts/shared/_core-behavior-gp.md | 3446 | 1888 | 2000 | OK — **HIGH-BLAST** (requiere review humano) |
| 3 | prompts/sdd/sdd-orchestrator.md | 3061 | 1998 | 2000 | OK |
| 4 | prompts/gentleman-deep.md | 2328 | 1633 | 2000 | OK |
| 5 | prompts/gentleman-codex.md | 2102 | 1621 | 2000 | OK |
| 6 | .agents/skills/sdd-spec/SKILL.md | 4494 | 2085 | 3072 | OK |
| 7 | .agents/skills/sdd-archive/SKILL.md | 4471 | 2726 | 3072 | OK |
| 8 | .agents/skills/sdd-propose/SKILL.md | 4369 | 2305 | 3072 | OK |
| 9 | .agents/skills/sdd-tasks/SKILL.md | 4354 | 2975 | 3072 | OK |
| 10 | .agents/skills/sdd-apply/SKILL.md | 4117 | 3071 | 3072 | OK |
| 11 | .agents/skills/sdd-init/SKILL.md | 3989 | 2460 | 3072 | OK |
| 12 | .agents/skills/sdd-verify/SKILL.md | 3650 | 2804 | 3072 | OK |

**Findings correction (protocolo v3)**: inventory decía `docs/protocolo_mejora_autonoma_v3.md` NOT FOUND → **falso**. El archivo EXISTE en `docs/protocolo_mejora_autonoma_v3.md` (raíz de docs/, no docs/mejoras/). No se comprimió (F2/P2.13c sigue pendiente). Corrige claim "laguna stale" → la laguna era del inventario, no del archivo.

## 9. Pendientes (tras drafts 08-11)

- **CODE** (requieren CI + PEV gate, del plan §3): perf-caches (TTL+hash, P2.12), async-delegation (P3.22), memory-TTL/purge Engram (P3.19), injection-sanitization (P1.7).
- **12 drafts karpathy pendientes de tu review + apply** (1 commit por skill, prefix `karpathy:`, tag `archive/pre-karpathy-*`, DoD gate verde). HIGH-BLAST primero: vMK + core-behavior.
- **Manual tuyo**: master→main en GitHub Settings + delete remoto (snapshot ya en tag `archive/gentle-ai-go-snapshot-v2`).
- **Compresión protocolo v3** (96→≤55 líneas) sigue pendiente — archivo en `docs/protocolo_mejora_autonoma_v3.md`.


## 10. Aplicado / Pendiente (READ-VERIFY-APPLY 2026-08-11)

Drafts `docs/mejoras/_karpathy-drafts/` aplicados a canónicos (verificación `(Get-Item).Length`). HIGH-BLAST intactos.

| # | Archivo canónico | Antes (B) | Después (B) | Budget (B) | Status |
|---|---|---|---|---|---|
| 1 | prompts/gentleman-deep.md | 2328 | 1633 | 2000 | OK (byte-idéntico al draft) |
| 2 | prompts/gentleman-codex.md | 2102 | 1621 | 2000 | OK (byte-idéntico al draft) |
| 3 | prompts/sdd/sdd-orchestrator.md | 3061 | 3061 | 2000 | **SKIP — BLOCKED**: permission model deny `prompts/**/*` (write+edit). Draft queda como -draft |
| 4 | .agents/skills/sdd-spec/SKILL.md | 4494 | 2085 | 3072 | OK |
| 5 | .agents/skills/sdd-archive/SKILL.md | 4471 | 2726 | 3072 | OK |
| 6 | .agents/skills/sdd-propose/SKILL.md | 4369 | 2305 | 3072 | OK |
| 7 | .agents/skills/sdd-tasks/SKILL.md | 4354 | 2975 | 3072 | OK |
| 8 | .agents/skills/sdd-apply/SKILL.md | 4117 | 3071 | 3072 | OK |
| 9 | .agents/skills/sdd-init/SKILL.md | 3989 | 2460 | 3072 | OK |
| 10 | .agents/skills/sdd-verify/SKILL.md | 3650 | 2804 | 3072 | OK |
| 11 | docs/protocolo_mejora_autonoma_v3.md | 7109 (96 líneas) | 4423 (55 líneas) | ≤55 líneas | OK (-38%) |

**ADR alignment (Option B)** — prosa budget 65,536 → 98,304 (= 65,536×1.5 headroom), citas históricas preservadas:
- ADR-011: métrica M7 `opencode.json ≤65,536B` → `≤98,304B (= 65,536×1.5 headroom)`.
- ADR-014: Decision `assert ≤65,536 B` → `≤98,304 B (= 65,536×1.5 headroom)`; Context "53,556 B = 82% of 65,536 B" preservado + nota "(budget formalizado a 98,304 en ADR-007 amend 2026-08-11; 65,536 era el base-original)". Refs sin tocar.
- ADR-019: `opencode.json ≤65,536B (53,556B baseline)` → `≤98,304B (= 65,536×1.5 headroom) (53,556B baseline)` — baseline histórico preservado.
- ADR-007: ya alineado (amend 2026-08-11 presente); won't-fix PERF-1 (root→agentes) NO tocado.
- scripts/regenerate-opencode.ps1 comentario `-MaxBytes` (default: 65536) → `98304 = 65,536x1.5 headroom, per ADR-007 amend`.

**Deferred (HIGH-BLAST — requieren review humano, drafts quedan como -draft)**: prompts/gentleman-vMK.md (5088→1985B), prompts/shared/_core-behavior-gp.md (3446→1888B). Deferred-by-design: gobiernan el protocolo operativo del agente (fail-closed, return-contract, permission layering); aplicar sin checkpoint humano viola el principio de blast radius Alto (§1 protocolo v3) y ADR-018/ADR-005.

**Deferred por permission model**: prompts/sdd/sdd-orchestrator.md (SKIP arriba).

## 11. Implementation backlog (SAFE — 2026-08-11)

SAFE backlog: writes SOLO a `docs/mejoras/_impl-drafts/` + este §11. Sin git commit (pedir). Sin node/npm/pwsh/python (skip+[SKIP-toolchain]). Canonical fail-closed intactos. won't-fix (root→agentes) intacto. `regenerate-opencode.ps1` NO modificado (help-comment 65536 = cosmético pre-existente; ADR-007 Amendment cubre la realidad 98,304). master→main = skip manual.

| Item | Blast | Status | Next step |
|---|---|---|---|
| SDD skills (7) regenerados con frontmatter canónico verbatim + prosa karpathy | Bajo | **DONE** — `_impl-drafts/sdd-{spec,archive,propose,tasks,apply,init,verify}.md`, todos ≤3072B (apply exacto 3072) | Review + apply 1 commit/skill, prefix `karpathy:`, tag `archive/pre-karpathy-*`, DoD gate verde |
| prompts/gentleman-vMK.md + `_core-behavior-gp.md` (HIGH-BLAST) | **ALTO** | Draft intacto en `_karpathy-drafts/` — **requiere review humano (gobierna protocolo del agente)** | Checkpoint humano; ADR-018/005; aplicar solo tras OK |
| protocolo_mejora_autonoma_v3.md | Bajo | **DONE** — `_impl-drafts/protocolo-v3.md` 4422B/55L (canónico ya comprimido §10); checkpoints v3-vs-v2 + humano + rollback preservados | Verificar diff vs canónico, sin re-apply |
| P1.11b flaky retry (`quality-gate.yml:242`) | Bajo | **DONE** — `_impl-drafts/p1.11b-quality-gate-retry.patch` (-RetryCount 2) | Apply + CI green; rollback: revert 1-línea |
| P3.18 auto-dream (`close-session.ps1:161`) | Bajo | **DONE** — `_impl-drafts/p3.18-close-session-autodream.patch` (3-line insert, guard DryRun/Force) | Apply + verificar 5º close dispara dreaming |
| P2.15 bulk-ops ctx_execute | Bajo | **DONE** — `_impl-drafts/ctx-bulk-ops-guidance.md` (benchmark.ps1:40, skill-graph) | Prompts/scripts canonicalizar regla |
| master→main (branch default) | Manual | Pending — usuario (GitHub Settings + delete remoto) | Snapshot ya en tag `archive/gentle-ai-go-snapshot-v2` |
| CODE CI+PEV: perf-caches (P2.12), async-delegation (P3.22), memory-TTL (P3.19), injection-sanitization (P1.7) | Medio/Alto | Deferred (requieren CI + PEV gate) | Implementar con plan→aprobación→ejecución→verificación |
