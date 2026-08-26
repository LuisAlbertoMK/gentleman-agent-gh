# sdd-archive — Detailed Reference

## Hard Gates (detailed)

1. **SDD Session Preflight** must already be complete for this session. It must include execution mode, artifact store, chained PR strategy, and review budget. If missing, ask the exact orchestrator preflight prompt and STOP. Do not run archive in the same turn.

2. **sdd-init** must already exist or be run after preflight, per the orchestrator init guard.

3. **Change resolution**: Resolve the active change using the status contract. If `$ARGUMENTS` is missing or ambiguous, ask the user to choose and STOP. Do not guess.

4. **Structured status**: Produce structured status before acting. Use the resolved artifact store from session preflight; do not hardcode Engram.

5. **Artifact completeness**: The active change must have tasks, verify-report, transaction, frozen ledger, approved terminal receipt, and gate-context artifacts at the exact selected-store references. Native `reviewGate.result` must be exactly `allow`; missing, pending, scope-changed, invalidated, or escalated review state blocks archive and never auto-launches a reviewer. Proposal/spec/design are expected for full spec-driven archive; if missing, report the exact missing artifacts and require an explicit user override before archiving.

6. **actionContext**: Must allow archive operations. If status reports `workspace-planning`, STOP and explain that workspace archive is not supported in this slice.

7. **Task completion**: The persisted tasks artifact must reflect completion before the archive is considered successful. Internal todos do not count, and `sdd-apply` is responsible for marking completed tasks.

## Dependency Check (detailed)

- If the verification report is missing or does not say the change is ready, do NOT archive.
- If tasks still contains unchecked implementation items (`- [ ]`), do NOT archive by default. Send the change back to `sdd-apply` to correct the persisted tasks artifact. Only allow archive-time mechanical reconciliation when apply-progress / verify-report prove every unchecked task is complete; record the reconciliation in the archive report.
- If verify-report contains CRITICAL issues, do NOT archive. There is no CRITICAL override.
- Tell the user what is missing and suggest `/sdd-verify <change>` or `/sdd-continue <change>`.

## Sub-Agent Launch

If all gates pass, launch the hidden `sdd-archive` sub-agent with the structured status, exact transaction/ledger/receipt/gate-context references, all required artifacts, the resolved artifact store, and any explicit non-critical partial-archive or stale-checkbox reconciliation text.

Tell it to enforce both native receipt and task completion gates before syncing specs or moving the archive folder, and to treat checkbox fixes as exceptional reconciliation rather than normal archive work.

Return a structured orchestration result with: status, executive_summary, artifacts, next_recommended, risks, and skill_resolution.
