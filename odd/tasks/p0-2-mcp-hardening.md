# P0-2 MCP Hardening — ODD Task Plan (Ronda 1 / Fase 1)

> Fase 1 — análisis y freeze. NO implementar código en esta fase.
> Cola v3: `docs/mejoras/2026-09-01-agent-improvement-research-plan.md:222-232` (Ronda 1 = P0-2).
> KB: r2-mcp-security-bestpractices, Engram 857 (`research-plan.md:240`).

## 1. P0-2 — ¿Resuelto en HEAD? NO (parcial)

Core implementado, residual pendiente:

| Pieza | Estado en HEAD `67707025` | Evidencia |
|-------|---------------------------|-----------|
| Audit script vs spec oficial (11 secciones KB) | ✅ Existe | `scripts/security-audit-mcp.ps1:1-20` (header cita P0-2 id:857 + vectores: Confused Deputy, prompt injection, SSRF allowlist, secret scan, version pin, CBM_ALLOWED_ROOT) — commit `feb0a4f8` |
| Higiene MCP (2 disabled servers removidos) | ✅ Existe | `docs/mejoras/mejora-log.md:384-386` + `benchmarks.md:168` |
| Pester tests dedicados | ❌ Faltan | `tests/` — 23 suites, ninguna `*mcp*` (verificado por listado `Get-ChildItem tests/`) |
| Wiring al gate pre-commit/CI | ❌ Falta | `Select-String scripts/*.ps1 "security-audit-mcp"` → 0 referencias |
| Fragmento SSoT MCP | ❌ Falta | `scripts/opencode-config/` solo tiene `expand-config.ps1` + 2 json (deny-rules, semi-allow); sin fragmento MCP |

Veredicto: NO saltar a R2-4. Fase 2 = residual (tests + enforcement), no re-auditoría.

## 2. ODD Gate → SUBSTANTIAL (residual)

| Criterio (skill `odd`) | Umbral SMALL | Residual P0-2 | Pasa |
|------------------------|--------------|---------------|------|
| Líneas | ≤50L code | ~180-240L est. (tests ~120L + wiring/SSoT ~60-120L) | ❌ |
| Files | 1 file | 2-3 files | ❌ |
| Schema/auth/API | None | MCP = auth-relevante (SSRF allowlist, secret scan) | ❌ |
| Deps externas | None | None | ✅ |
| Commits forecast | ≤2 | 2 | ✅ |

**Gate: SUBSTANTIAL** → requiere este task plan. `confidence: high` (medición directa en HEAD).

## 3. Slice Plan (1 slice = 1 conventional commit, ≤400L, tests en mismo commit)

- **Slice 1 — `test(security): Pester suite for security-audit-mcp`** (~120L est., 1 file nuevo: `tests/security-audit-mcp.Tests.ps1`) — Outcome: comportamiento del audit pineado (allowlist SSRF, secret scan, version pin, PESTER_TEST no-mutación) + PASS en suite nueva.
- **Slice 2 — `feat(security): enforce MCP audit in gate + SSoT policy fragment`** (~60-120L est., 2 files: wiring en gate pre-commit/CI + fragmento `scripts/opencode-config/mcp-policy.json` o equivalente vía `sync-all`) — Outcome: audit corre en cada commit/CI; política MCP sale de `opencode.json` directo al SSoT. NO editar `opencode.json` directo.

Total residual ~180-240L → 2 slices (cada uno ≤400L ✅). `confidence: medium` en estimaciones (sin re-investigar, por mandato).

## 4. RDD Freeze (capturado ANTES de cualquier cambio futuro)

- **Freeze string:** `HEAD-67707025-e69de29b`
- **Captura (sin side effects — no commit/push/stash):**
  - `git rev-parse HEAD` → `6770702545ef6c39b8fe22ecbec3259033bc65db` | `--short` → `67707025`
  - `git status --porcelain` → vacío (clean tree) | `git diff --stat HEAD` → vacío
  - `git diff HEAD | git hash-object --stdin` → `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391` (hash de árbol vacío = limpio) → diff8 `e69de29b`
  - `git rev-list --count origin/main..HEAD` → `2` (ahead 2, NO push por mandato)
- **Tier propuesto: 2** — presunción auth-relevante NO refutada (SSRF allowlist + env secret scan tocan superficie auth; residual >50L multi-file). `confidence: medium`.
- **Review plan:** Tier 2 → 4R (`code-review-agent`) BLOCKER-capable por slice; FAIL → escalar a `judgment-day`, nunca auto-fix. Re-freeze + re-review si el freeze queda stale.
- **Verify por slice:** Pester suite nueva PASS + gate **25/25 ALL CLEAR** (estándar vigente post GAP-2: `docs/mejoras/2026-09-01-gap-scan-repo.md:79`).

## 5. Receipt template (preparada, NO emitir aún)

```json
{
  "receipt_id": "rdd-receipt-p0-2-s<N>",
  "freeze": "HEAD-67707025-e69de29b",
  "tier": 2,
  "slice": "<N> — <scope>",
  "files": ["<paths>"],
  "review": { "type": "4R", "verdict": "<PASS|WARN|FAIL|BLOCKER>", "escalation": "<none|judgment-day>" },
  "verify": { "pester": "<PASS>", "gate": "25/25" }
}
```

## 6. Review Log

| Slice | Commit | 4R veredicto | Gate | Estado |
|-------|--------|--------------|------|--------|
| 1 | `ee7a96d3` | — (pendiente Verify 4R) | — | ✅ commiteado fase 2 |
| 2 | `40159179` → amend (HEAD final, ver git log) | — (pendiente Verify 4R) | 28/28 ALL CLEAR | ✅ commiteado fase 2 |

## 7. Rollback

Cada slice commitea independiente: `git revert <slice-N>` sin tocar el otro slice ni `feb0a4f8`.
