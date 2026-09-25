# Ronda 2 — WARN + SSoT + Judges — ODD Task Plan (Fase 1: análisis y freeze)

> Fase 1 — análisis y freeze. NO implementar código en esta fase. NO commit, NO push, NO checkout.
> Rama: `experimento/mejora-ronda2-warn-ssot-judges` · cierre R1 = `74ad0988` · main `67707025` intacto.
> Cola Ronda 2 (en orden A → B → C). Evidencia existente (no re-investigada):
> `odd/tasks/p0-2-mcp-hardening.md` (Review Log R1) · `docs/mejoras/mejora-log.md:356`
> (protocolo experimento/PR: "esperar orden explícita; no mergear") ·
> `docs/mejoras/2026-09-01-agent-improvement-research-plan.md:208-211` (R2-4) + `:222-232` (cola v3).

## 1. ODD Gate por ítem

Regla: ALL criteria must pass para SMALL (directo, ≤50L/1 file); si alguno falla → SUBSTANTIAL (task plan).

| Criterio (skill `odd`) | Umbral SMALL | A. WARN fix | B. SSoT consumer | C. R2-4 judges |
|------------------------|--------------|-------------|------------------|----------------|
| Líneas est. | ≤50L code | ~1-3L ✅ | ~40-90L ❌ (supera con tests) | ~200-350L solo parte 1 ❌ |
| Files | 1 file | 1 ✅ (`.githooks/pre-commit-gate.ps1`) | 1-2 (generator + wiring sync) ⚠️ | 2+ (SKILL.md + references) ❌ |
| Schema/auth/API | None | None ✅ (guard fail-closed, sin superficie nueva) | Auth-relevante ❌ (MCP: SSRF allowlist, secret scan — precedente P0-2 Tier 2) | None ✅ (skill-only, sin runtime) |
| Deps externas | None | None ✅ | None ✅ | KB Engram 855 (lectura, no dep runtime) ✅ |
| Commits forecast | ≤2 | 1 ✅ | 1-2 ✅ | 1 (parte 1) ✅ |
| **Veredicto** | — | **SMALL** → directo | **SUBSTANTIAL** → este plan | **SUBSTANTIAL** → este plan (partido; resto → Ronda 3) |

Evidencia por ítem (medición directa en HEAD `74ad0988`, `confidence: high` salvo nota):

- **A**: `.githooks/pre-commit-gate.ps1:149-151` — `$mcpOut = & "...security-audit-mcp.ps1" -CI *>&1 | Out-String`
  seguido SOLO de `if ($mcpOut -match '\[FAIL\]')`; sin check de `$LASTEXITCODE`. Contraste estructural:
  los checks hermanos SÍ lo chequean (`:79` cross-ref, `:300` opencode.json sync, `:315` write-scope,
  `:351` backlog, `:435` adversarial, `:527` e2e). Si el audit crashea sin emitir `[FAIL]`
  (exit ≠ 0, output vacío/inesperado), el gate hace `Pass` = fail-open. Fix 1 línea tras `$mcpOut = ...`:
  `if ($LASTEXITCODE -ne 0) { Fail "MCP audit exit $LASTEXITCODE ..." }`.
- **B**: el generador real es `scripts/lib/generate-opencode-config.js` (340L; citado como SSoT-generator
  en `scripts/opencode-config/expand-config.ps1:80-85` — el path `scripts/generate-opencode-config.js`
  del enunciado NO existe, equivalente determinado por lectura). Consume `opencode-base.json` +
  `permission-templates.json` + `agent-overrides.json` (header `:1-20`) pero grep `mcp-policy` en repo
  solo matchea gate `:141-147` (validación), el propio `mcp-policy.json:2` (`$schema`) y el task P0-2:
  **ningún consumer genera/enlaza la policy** — gap confirmado. `mcp-policy.json:1-37` existe como SSoT
  pero huérfana del pipeline `sync-all.ps1` → generator. Alcance: cablear consumo vía sync-all
  SIN editar `opencode.json` directo (sale como output del generator, igual que P0-2 S2 mandató).
  `confidence: high` en el gap; `medium` en estimación (diseño de emisión MCP no investigado por mandato).
- **C**: `research-plan.md:208-211` — 6 patrones zylos (offline eval, online runtime verifier 76-162ms,
  self-consistency, Reflexion, constitutional, IRM), esfuerzo 1-2 sesiones, `confidence: high`,
  "nuestro judgment-day implementa 1 patrón de 6". `judgment-day/SKILL.md` = 48L (comprimida, refs
  externalizadas) + `references/jd-patterns-wiring.md`; adoptar 6 patrones supera un slice útil →
  **partir**: Ronda 2 = parte 1 (3 patrones más concretos), resto explícito para Ronda 3 (ver §5 Nuance).
  KB: `r2-zylos-llm-judge` (Engram 855; `research-plan.md:238`).

## 2. Slice Plan (1 slice = 1 conventional commit ≤400L, tests en mismo commit)

Orden mandatorio: **A primero** (1 línea fail-closed, desbloquea enforcement real) → B → C-parte-1.

- **Slice 1 — `fix(security): gate fails closed on MCP audit exit code`** (A · SMALL)
  Scope: 1 línea en `.githooks/pre-commit-gate.ps1:149-151` + Pester que fuerza audit con exit ≠ 0
  sin `[FAIL]` en output y aserta gate FAIL. Est. ~15-30L (1L fix + ~15-30L test). Outcome: gate
  fail-closed real; ningún crash silencioso del audit pasa como `Pass`.
- **Slice 2 — `feat(config): generator consumes mcp-policy.json SSoT via sync-all`** (B · SUBSTANTIAL)
  Scope: `scripts/lib/generate-opencode-config.js` lee `scripts/opencode-config/mcp-policy.json:1-37`
  y emite la sección MCP correspondiente; `opencode.json` solo como output (NO edición directa);
  wiring vía `scripts/sync-all.ps1` (o `regenerate-opencode.ps1` si es el entry real — determinar en
  ejecución). Est. ~40-90L + tests. Outcome: policy deja de ser huérfana; drift policy↔generado
  detectable por `--validate`/gate `[9/26]`.
- **Slice 3 — `feat(skills): judgment-day adopts judge patterns part 1 (3/6)`** (C-parte-1 · SUBSTANTIAL)
  Scope: offline eval + online runtime verifier (budget 76-162ms) + self-consistency sobre
  `judgment-day/SKILL.md` + `references/jd-patterns-wiring.md`. Est. ~200-350L (≤400L ✅).
  Outcome: 3/6 patrones operativos con budget medido; resto (Reflexion, constitutional, IRM) → Ronda 3.

Total Ronda 2: 3 slices, cada uno ≤400L ✅. `confidence: medium` en estimaciones B/C (sin re-investigar, por mandato).

## 3. RDD Freeze (re-capturado EN ESTA RAMA, antes de cualquier cambio futuro)

- **Freeze string:** `HEAD-74ad0988-e69de29b`
- **Captura (solo lectura — no commit/push/stash/checkout):**
  - `git branch --show-current` → `experimento/mejora-ronda2-warn-ssot-judges` ✅ (fail-closed pasado)
  - `git rev-parse HEAD` → `74ad0988ff1f8f5f16932cd397220f1fea4e9b30` | `--short` → `74ad0988` (= cierre R1 ✅)
  - `git rev-parse main` → `6770702545ef6c39b8fe22ecbec3259033bc65db` | `--short` → `67707025` (intacto ✅, solo lectura)
  - `git status --porcelain` → vacío (clean tree) | `git diff --stat HEAD` → vacío
  - `git diff HEAD | git hash-object --stdin` → `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391` (árbol vacío = limpio) → diff8 `e69de29b`
- **Tier por slice + review plan:**
  - Slice 1 (A) → **Tier 1** — 1 línea fail-closed, sin superficie nueva; 4R (`code-review-agent`) ligero, veredicto WARN-tolerante; FAIL → `judgment-day`, nunca auto-fix.
  - Slice 2 (B) → **Tier 2** — presunción auth-relevante NO refutada (policy MCP: SSRF allowlist + secret scan; el generator produce `opencode.json` = blast radius amplio); 4R BLOCKER-capable; FAIL → `judgment-day`, nunca auto-fix.
  - Slice 3 (C1) → **Tier 1** — skill-only, sin schema/auth/API ni runtime; 4R estándar (coherencia de patrones + budget 76-162ms verificado); FAIL → iterar diseño, nunca auto-fix.
  - Re-freeze + re-review si el freeze queda stale antes de ejecutar un slice.
- **Verify por slice (estándar vigente R1):** Pester suite MCP **19/19** PASS + gate **28/28** ALL CLEAR + PSSA sin warnings/errors.
  - Slice 1 además: test fail-closed nuevo PASS (audit exit≠0 sin `[FAIL]` → gate FAIL).
  - Slice 2 además: `--validate` sin diff tras regen + gate `[9/26]` PASS.
  - Slice 3 además: budget online verifier medido dentro de 76-162ms (evidencia en commit).

## 4. Receipt templates (preparadas, NO emitir aún)

```json
{
  "receipt_id": "rdd-receipt-ronda2-s<N>",
  "freeze": "HEAD-74ad0988-e69de29b",
  "tier": "<1|2>",
  "slice": "<N> — <scope>",
  "files": ["<paths>"],
  "review": { "type": "4R", "verdict": "<PASS|WARN|FAIL|BLOCKER>", "escalation": "<none|judgment-day>" },
  "verify": { "pester_mcp": "19/19", "gate": "28/28", "pssa": "clean" }
}
```

## 5. Review Log (vacío — Fase 1)

| Slice | Commit | 4R veredicto | Gate | Estado |
|-------|--------|--------------|------|--------|
| 1 (A WARN fix) | fix(security): gate fails closed on MCP audit exit code (Ronda2 S1) — este commit | Tier 1 ligero en Verify (implementer: Pester 22/22 PASS, PSSA 0 errores, diff 37L ≤50L) | [9/26] fail-closed: exit≠0 sin [FAIL] → BLOCKING | ✅ implementado en esta rama, NO push |
| 2 (B SSoT consumer) | feat(config): generator consumes mcp-policy.json SSoT via sync-all (Ronda2 S2) — este commit | Tier 2 en Verify (implementer: MCP 22/22 + generate-config 14/14 con 5 nuevos policy→output, regen 23/23 OK, PSSA 0 errores/0 warnings nuevos, diff 208L ≤400L) | [9/26] OK + --validate VALID con enforcement MCP activo (5 servers compliant); regen real = caso (b): diff tocaba model/agent/watcher (profile-injected), mcp idéntico → opencode.json revertido byte-exacto, NO commiteado | ✅ implementado en esta rama, NO push |
| 3 (C1 judges 3/6) | feat(skills): judgment-day adopts judge patterns part 1 (Ronda2 S3) — este commit | Tier 1 en Verify (implementer: cross-ref-check ALL PASSED, Pester MCP 22/22 + jd-verifier 18/18 PASS sin regresión, budget medido n=12 mediana ~136ms, diff 142L ≤400L, taxonomy filas 4-6 intactas) | budget medido 100–178ms, 10/12 ≤162ms (83%); over-budget → ESCALATE fail-closed verificado live (151ms→VERIFY-OK exit 0, 166ms→ESCALATE exit 1) | ✅ implementado en esta rama, NO push |

## 6. Rollback por slice

Cada slice commitea independiente en ESTA rama (nunca main): `git revert <slice-N>` sin tocar los otros
slices ni `74ad0988`. Si un slice invalida el freeze de otro pendiente → re-freeze (§3) antes de continuar.
Prohibido: merge a main sin orden explícita (`mejora-log.md:356`).

## 7. Para Ronda 3 (explícito, NO parte de esta ronda)

- **C-parte-2**: Reflexion + constitutional + IRM sobre judgment-day (3/6 restantes) — nuevo slice plan en R3.
- Re-evaluar si C-parte-2 excede 400L o 2 sesiones → partir de nuevo (un patrón por slice si hace falta).
- Candidatos de cola v3 no tocados (`research-plan.md:222-232`): P0-1 LCM DAG → context-watchdog,
  P1-1 + R2-1 skills audit, R2-5 initializer-agent, R2-2 listings, P1-2/P1-3, R2-3/R2-6/P2-*.
