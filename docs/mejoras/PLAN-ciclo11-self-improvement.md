# Plan Consolidado — Cycle 11: Self-Improvement, Token Compression & Quality Hardening

> **Date**: 2026-07-06
> **Origin**: `!analisis` multi-agent (upstream diff + overhead audit + code quality + MCP research)
> **Score atual**: 9.2/10 | **Target**: 9.8/10 | **Budget tokens ahorrados**: ~6,500/sessão garantizado

---

## Executive Summary

Cinco subagentes paralelos auditaron el repositorio: divergencia con `upstream gentle-ai` (CLI Go, con skills overlap 18/20), overhead de contexto (duplicaciones AGENTS.md), calidad scripts (Mixtura de estilos prolijo vs golfed) y MCP gaps (GitHub/Brave/Jina costo-cero sin adoptar). El plan convergió en 3 ejes: **(1) Tokens** (−3,776/sesión por AGENTS local duplicado), **(2) Seguridad** (Fix bypass `bash:allow`+`edit:deny` en 7 ANALYZE-ONLY), **(3) Modernidad** (shared prompts DRY, catch logging, LinkType guard).

---

## Cycle 11 Backlog

| # | Item | Impact | Risk | I/R | Tokens/Effecto | Estado |
|---|------|--------|------|-----|----------------|--------|
| 1 | Eliminar `AGENTS.md` local (100% duplicado del global, MD5 idéntico) | 3 | 1 | 3.0 | −3,776/sessão | 🟢 |
| 2 | Fix AGENTS L107: `ANTI-PATTERN-CATALOG` → `ANTI-PATTERN-CHEATSHEET` (local + global) | 3 | 1 | 3.0 | −1,982/task | 🟢 |
| 3 | Security: 7 ANALYZE-ONLY agents `bash:allow`+`edit:deny` → `bash:ask` | 3 | 1 | 3.0 | bloqueia bypass vía Set-Content | 🟢 |
| 4 | Extraer boilerplate de prompts a `prompts/shared/{_core-behavior,_analyze-only-protocol}.md` | 3 | 2 | 1.5 | −2,400 en fan-out 8 subagentes | 🟢 |
| 5 | `score-auto.ps1:28` `Set-Location` → `Split-Path` (forbidden per AGENTS.md) | 3 | 1 | 3.0 | preserva CWD del caller | 🟢 |
| 6 | `catch {}` vacíos (score-auto×3 + lib/cache×2 + skillspector-gate×1) → `Write-Debug` | 3 | 1 | 3.0 | falhas no más silentes | 🟢 |
| 7 | `health-check.ps1 Repair-Junction`: validar `LinkType -eq Junction` antes de remove | 3 | 1 | 3.0 | evita borrar dir real | 🟢 |
| 8 | Adoptar GitHub MCP + Brave MCP + Jina MCP (Fase 1 research) | 2 | 2 | 1.0 | web research costo-cero | 🔲 Cycle 12 |
| 9 | Skill style guide v2 (180-450 tokens budget, 7 secciones) portar do upstream | 3 | 1 | 3.0 | standardized budget | 🔲 Cycle 12 |
| 10 | hermes-ephemeral-delegation skill (output contract formal) | 3 | 1 | 3.0 | subagent isolation mais forte | 🔲 Cycle 12 |
| 11 | Trigger Rules declarativas (6 eventos + binding schema) | 3 | 2 | 1.5 | substituye checklist ad-hoc | 🔲 Cycle 12 |
| 12 | Permissions deny-list overlay (OpenCode bash/read ask/deny) | 3 | 1 | 3.0 | já coberto por #3 | 🔲 done via #3 |
| 13 | Skill registry index-first (paths, no summaries) — portar spec | 3 | 2 | 1.5 | preserva autor intent | 🔲 Cycle 12 |
| 14 | Golden snapshots para skills críticas (CI regression) | 3 | 2 | 1.5 | para drift de prompts | 🔲 Cycle 12 |
| 15 | Branch-pr v2.0 (issue-first + type label) | 3 | 2 | 1.5 | none-flow break local | 🔲 Cycle 12 |

> Items 1-7 = this cycle (this commit). Items 8-15 = referenciados para Cycle 12.

---

## Discoveries

### Upstream diff (gentle-ai)
- Upstream mutou para **CLI Go distribuído** (`gentle-ai` binary via Scoop/`go install`), com TUI Bubbletea e adapters para 15 agentes (Claude/OpenCode/Kilo/etc.). El fork es PS-only.
- Skills overlap: 18/20. Solo `hermes-ephemeral-delegation` é nova.
- Upstream não inyecta persona vía AGENTS.md — lo hace vía `internal/components/persona/inject.go`.
- Upstream tiene **trigger rules declarativas** (no checklists ad-hoc), **skill-registry index-first** (paths, no summaries), **permissions deny-list overlay**, **golden snapshots** en CI.

### Overhead de contexto
- `AGENTS.md` local = `~/.config/opencode/AGENTS.md` (MD5 `DB5309B4D244539C30F8877732320E05` idéntico — duplicação 100%).
- AGENTS L103 declara CATALOG como lazy pero L107 lo carga primero en Load order — contradicción.
- 8 agentes especializados inlinean ~1,200b de boilerplate cada uno (CORE BEHAVIOR + ANALYZE ONLY + Autonomy zones). DRY win = 2,400 tok en fan-out.
- `lean-context` TALE dice "~200 tok/skill" — real es 600 tok/skill (3x descalibrado).

### Calidade de scripts
- Score 6.4/10 — dos estilos antagónicos: prolijos (health-check, dev-server) vs golfed (score-auto, skill-graph).
- `score-auto.ps1:28` `Set-Location "$PSScriptRoot\.."` viola AGENTS.md y rompe paths relativos del caller.
- `health-check.ps1 Repair-Junction` ejecuta `Remove-Item -Force -Recurse` sin validar que el target sea junction (borrar dir real).
- 7 `catch {}` vacíos silencian cache misses sin telemetry.
- `opencode.json`: ANALYZE-ONLY agents con `edit:deny` + `bash:allow` — **bypass de seguridad** vía `bash -c 'Set-Content ...'`.

### MCP audit
- Costo-cero útiles faltantes: GitHub MCP (PAT), Brave Search MCP (Brave API), Jina AI MCP (Reader).
- Redundantes: `codebase-memory-mcp` (solapa con codebase tools natives — candidate desabilitar en próximo ciclo si hits<5), `headroom` (proxy opaco — auditar uso).
- **EVITAR**: Filesystem MCP, Memory MCP, Fetch+ripgrep+Time bundle (todos duplican tools natives).

---

## Decisions (arch + tradeoffs)

1. **No borrar `codebase-memory-mcp`** ainda — medir hits reales 3 sessões → Cycle 12 verdict.
2. **No portar bits Go del upstream** (filemerge/persona/backup) — costo ALTO en PS, valor MEDIO; manter soluções atuais.
3. **No adoptar SDD Profiles** (Tab switch N orchestrators) — complejidad > valor para single-user.
4. **Mantener `git-tracked AGENTS.md` global** — sincronizado via `!setup`; el local se elimina porque OpenCode ya inyecta el global.

---

## Verification (triple-verify)
- E1 (**testing**): `scripts/smoke/smoke-all.ps1` end-to-end debe pasar 5/5.
- E2 (**estatic**): `pssa-gate.ps1 -Mode Check` — sin nuevas warnings; `skillspector-gate.ps1` — sin drift.
- E3 (**build/runtime**): `health-check.ps1 -Json` exit 0; `score-auto.ps1 -Json` — score estável ou subiu.
- Quality: solo estamos tocando scripts PS + 1 JSON (opencode.json) + docs.

---

## Relevant Files
- `AGENTS.md` (local) — eliminado (duplicado del global)
- `~/.config/opencode/AGENTS.md` — fix L107 (CATALOG → CHEATSHEET) depois de sync manual se preciso
- `CYCLE.md` — abertura Cycle 11 + pillars
- `scripts/score-auto.ps1` — Set-Location → Split-Path; 3 catch vacíos → Write-Debug
- `scripts/lib/cache.ps1` — 2 catch vacíos → Write-Debug
- `scripts/skillspector-gate.ps1` — 1 catch vacío → Write-Debug
- `scripts/health-check.ps1` — Repair-Junction validar LinkType antes de remove
- `prompts/shared/_core-behavior.md` — extraer boilerplate Común (CORE BEHAVIOR + Autonomy zones)
- `prompts/shared/_analyze-only-protocol.md` — extraer CRITICAL RULE ANALYZE ONLY
- `opencode.json` — refactor prompts 11 agentes + bash:allow→ask para ANALYZE-ONLY