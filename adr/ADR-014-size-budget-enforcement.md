# ADR-014: opencode.json size-budget enforcement

- **Status**: Accepted · **Date**: 2026-08-04 · **Type**: infrastructure
- **Context**: opencode.json = 53,556 B = 82% of 65,536 B ADR-007 budget (budget formalizado a 98,304 en ADR-007 amend 2026-08-11; 65,536 era el base-original); regrow +1,350 B since 08-03 audit; NO size guard exists; pre-commit-gate has 16 checks, CI quality-gate.yml runs gate in CI. Gap INFRA-2 from v2 kickoff baseline.
- **Decision**: **A (RECOMMENDED)** — assert ≤98,304 B (= 65,536×1.5 headroom) in pre-commit-gate.ps1 as NEW check [17/17] + mirror in quality-gate.yml (fail). Deterministic single SSoT. Impact 8, Risk 2.
- **Alternatives**: **B** — per-section budget (permissions/agents/mcp %) — rejected: over-engineering early, Impact 5, Risk 3. **C** — warn-only in CI (no fail) — retained as fallback: no stop power, Impact 3, Risk 1.
- **Consequences**: Prevents silent budget breach on every commit+CI push; CI red-flag on regrow; false-positive risk if budget raised legitimately (handled: bump ADR-007 + budget param together in one commit).
- **Refs**: `mejora-log.md` §Ciclo 1 (v2); `ADR-007` (size budget definition 65,536 B); `.githooks/pre-commit-gate.ps1` [16/16]; `scripts/quality-gate.yml`.
