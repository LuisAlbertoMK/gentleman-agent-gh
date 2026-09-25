# ADR-050: single-mode gentle-MK — drop `-auto` agents, rename gentleman-vMK → gentle-MK (Mapeo A)

## Status
Accepted - 2026-09-24

## Context
Upstream `gentle-ai` runs a single mode: RDD on by default, "commit, push and release stay your call" (human-owned), and a security deny-list blocking `~/.ssh`, `.env` and credentials — with NO `-auto` variants. Locally, three modes grew (`auto`/`semi`/`manual`) with 14 generated `-auto` agent twins plus mode-gate suffix routing, adding friction (gate BLOCKED states, `-auto` drift between SSoT/generated/global) without adding safety — the deny-floor (`opencode-base.json:8-151`: `git push*` deny, `commit/rebase/reset/merge` ask, `.env/.ssh/credentials` deny) already covers what `-auto` claimed to. ADR-033 closed `semi`; this ADR closes `auto` and the stale `gentleman-vMK` twin name. Evidence: `odd/tasks/refactor-agentes-permisos-gentle-ai.md` §§0-1 (freeze `HEAD-d1a3fbe7-e69de29b`, 58 agents / 14 `-auto`, 153 `gentleman-vmk` hits classified A-E).

## Decision
1. **Single mode.** Delete the 14 `-auto` defs (`gentle-MK-auto`, 5 primary `-auto`, 8 `-sub-auto`); `default_agent` + `fallback_default` → `gentle-MK`. Delete templates `auto`/`auto-sub`/`semi` + `_used_by`. Mode-gate/route-agent: every known agent → ALLOWED, `-auto`/`-semi` accepted as compat aliases with warning, `.gentleman-mode` is a no-op (effective `manual`). The deny-floor stays byte-identical.
2. **Mapeo A only.** `prompts/gentleman-vMK.md` merged into `prompts/gentle-MK.md` (query `analysis:gentle-MK`) and deleted; `docs/prompts/gentleman-vMK/` → `docs/prompts/gentle-MK/`; ghost map entries (`gentleman-vMK`, `gentleman-vMK-auto`, `gentle-MK-semi`, `gentleman-initializer-auto`) and `ROLE_KEYWORDS.vMK` purged; `scripts/gentleman-vmk.bat` kept as legacy forwarder (untouched). Live doc refs updated (S4); historical log entries intentionally intact. The `gentleman-*` family rename (Mapeo B) is explicitly OUT — optional slice S6 only with explicit order.

## Consequences
- 58 → 44 agents, 0 `-auto`/`-semi`; one orchestrator (`gentle-MK`), one routing table, no suffix logic. Delegation targets use base names.
- Historical traceability preserved: ~90 Clase-A hits (BITACORA, `docs/mejoras/*`, `.archive/*`, ADRs incl. ADR-039) never rewritten; `mejoras-index-check` stays green.
- Global `~/.config/opencode/opencode.json` sync remains a human act (§9.2 of the plan); agents never write it.
- Protected files (`prompts/**`, `AGENTS.md`) are deny-listed for agent edits — their one-line S4 updates are applied via owner-paste (precedent: 2026-09-02 execution-mode-gate hook line).

## Verification
- V1: `generate --validate` merge OK (44 agents, 0 auto/sub/semi) + deny-floor byte-identical + `permission-rules-consistency` 14/14.
- V2: `mode-gate.Integration` 15/15 (`gentle-MK` ALLOWED, `gentle-MK-auto` ALLOWED+warning) + `route-agent` manual expectations.
- V3: `git grep -i gentleman-vmk` = 0 live hits (historical + S5-test/shim hits triaged, not rewritten).
- V4 (this slice): `cross-ref-check` ALL PASSED + `mejoras-index-check` PASS + pre-commit gate 28/28, no `--no-verify`, no `FORCE_SHIP`.
- V5 (S5): full Pester suite vs baseline + real `gentle-MK` boot delegating to base agents.

## Rollback
Per-slice revert on the experimento branch, never main: `git revert <slice-N>` (S1a/S1b/S2a/S2b/S2b-regen/S3/S4 independent commits). If a slice breaks the pending freeze → re-freeze before continuing. Merge to main only with explicit order after all 5 slices PASS + Tier-2 receipts without BLOCKER.

## References
- `odd/tasks/refactor-agentes-permisos-gentle-ai.md` §§0-9 (inventory, Mapeo A/B, slice plan, freeze, rollback)
- ADR-033 (closed `semi`; this ADR closes `auto`) · ADR-039 (PS5/7 compat, historical context for the `.bat` shim)
- `docs/sdd/permissions.md` (rewritten single-mode in S1) · `opencode.json` (regenerated 44-agent in S2b-regen)
