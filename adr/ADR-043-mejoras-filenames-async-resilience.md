# ADR-043: Analysis filename disambiguation + async stability scope filter

- **Status**: Accepted (experiment branch — NOT merged to main)
- **Date**: 2026-08-24
- **Branch**: `experimento/mejora-autonoma-2026-08-24` (base: main @ `da90e1b0`)
- **Protocol**: docs/protocolos/protocolo_mejora_autonoma_v3.md
- **Context**: Two evidence-backed gaps from prior analyses: (1) finding #8 of
  `docs/mejoras/2026-07-28-orchestrator-self-analysis.md` — 9 files in
  `docs/mejoras/` share the indistinguishable pattern
  `YYYY-MM-DD-gentleman-agent-gh-analisis.md`; (2) findings #5/#11 of
  `docs/mejoras/2026-08-19-async-delegation-analysis.md` — monitor stability
  signal not scoped by AllowedPaths, and zero tests for concurrent/crash/
  false-stability scenarios.

## Decision

1. **Rename 9 analysis files with domain keywords** (blast radius: Bajo).
   Chosen approach A (rename + update references) over B (index-only mapping —
   leaves glob discovery broken) and C (per-domain subdirectories — larger
   blast radius, no extra benefit). All 21 referencing files updated; 7
   additional pre-existing broken refs to nonexistent targets repaired where
   the mapping was unambiguous; 5 unresolvable stale refs documented as open
   findings instead of guessed.
2. **Scope-filter the monitor stability signal** (blast radius: Medio).
   When `-AllowedPaths` is provided, changes outside the delegation scope are
   excluded from convergence detection, so external commits by other agents or
   the user cannot reset or pollute stability. Guarded block: without
   AllowedPaths behavior is byte-for-byte unchanged.
3. **Add async-resilience.Tests.ps1** (13 tests) closing test-gap finding #11:
   concurrent isolation (per-taskRef result naming, TaskId-scoped PID files),
   orphan lifecycle (PID write-before-poll, cleanup-after-callback ordering,
   stale warning, identity-checked cancel), false stability (behavioral e2e in
   a throwaway git repo).

## Consequences

- Discovery via glob/filename now works without opening files.
- Long-running delegations no longer spuriously time out when unrelated
  activity happens elsewhere in the repo during monitoring.
- Write-scope violations remain independently detected by
  validate-write-scope.ps1 (orthogonal check — unchanged).
- Rollback: see `docs/mejoras/rollback-map.md` §Ciclo 2026-08-24.

## Verification

- Pester: async-resilience 13/13, monitor-callback 17/17,
  babyagi-async-push 12/12 (all green with the fix applied).
- Link-check: 0 broken refs to renamed targets (131 references checked).
