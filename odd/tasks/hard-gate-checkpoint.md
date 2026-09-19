# hard-gate-checkpoint-enforcement — Slice Plan

## Status 2026-09-18 (decisión b)

- Slice 1 DONE (commit 72a8bb1a, JD APPROVED×2, Pester 23/23, gate 28/28).
- Slice 4 DONE (commit 0e1b21b9, JD APPROVED×2, Pester 21/21, gate 28/28).
- Slice 2 PARKED: JD dual-blind unánime — poll infuncionable en flujo sincrónico (ningún actor borra pending-engram.json; delete-on-read diferido), tests contaminan estado real sin PESTER_TEST, [bool]$Checkpoint rompe -Checkpoint bare, -SkipCheckpoint reporta passed. Requiere rediseño two-phase (close-emit → orchestrator mem_save+delete → close-verify). NO reintentar como patch.
- Slice 3 BLOCKED (depende forma final Slice 2). Slice 5 BLOCKED (docs deben reflejar comportamiento final).
- Push pendiente de !ship (main ahead 2 de origin/main).
- Breaches sesión: migrate_subagent_models.py (revertido), checkout rogue a experimento/perfiles-zen-go (reconducido con ff-merge a main 0e1b21b9).

## Gate Result

**SUBSTANTIAL** — 9 files, >50L, >1 file, >2 commits forecast.
Source: ODD gate evaluation (prior session, not re-evaluated here).

---

## Slice Plan

### Slice 1 — session-checkpoint: flag fidelity + JSON exposure

**Scope**: `scripts/session-checkpoint.ps1`, `tests/session-checkpoint.Tests.ps1`

| Item | Detail |
|------|--------|
| Files | `scripts/session-checkpoint.ps1` (~12L changed), `tests/session-checkpoint.Tests.ps1` (~40L new) |
| Est lines | ~55L |
| Conv commit | `fix(checkpoint): move memSaved flag after real write, expose persisted/pending_file in JSON` |

**Behavior**:
- Move `$memSaved = $true` from :308 to after the write block (:310-316) so the flag only reflects a successful persist.
- Add `persisted` (bool) and `pending_file` (string) fields to the JSON output.
- Unit tests assert flag is `false` when write fails, `true` when write succeeds; JSON shape includes new fields.

**Dependencies**: None (foundational slice).

---

### Slice 2 — close-session: checkpoint enforcement + timeout

**Scope**: `scripts/close-session.ps1`, `tests/close-session.Tests.ps1`

| Item | Detail |
|------|--------|
| Files | `scripts/close-session.ps1` (~35L changed), `tests/close-session.Tests.ps1` (~60L new) |
| Est lines | ~95L |
| Conv commit | `feat(close-session): enforce checkpoint with timeout, exit codes, and -SkipCheckpoint escape` |

**Behavior**:
- Default: checkpoint runs before close (ON by default).
- `-SkipCheckpoint` switch: bypasses checkpoint entirely (escape hatch).
- `-CheckpointTimeoutSec` parameter, default 30s. Wait-loop polls for absence of `.opencode/session-checkpoints/pending-engram.json`.
- If timeout expires with pending file still present → exit 2.
- Explicit `exit 0` at end of successful path.
- Unit tests: timeout path (exit 2), skip path (exit 0), success path (exit 0), missing checkpoint script (exit 2).

**Dependencies**: Slice 1 (session-checkpoint must expose `pending_file` for poll target).

---

### Slice 3 — close-session integration tests

**Scope**: `tests/close-session.Integration.Tests.ps1`

| Item | Detail |
|------|--------|
| Files | `tests/close-session.Integration.Tests.ps1` (~70L new) |
| Est lines | ~70L |
| Conv commit | `test(close-session): add integration tests for checkpoint enforcement flow` |

**Behavior**:
- Integration tests that exercise the full close-session → session-checkpoint pipeline.
- Scenarios: checkpoint writes pending → close-session polls → pending removed → exit 0; checkpoint stalls → timeout → exit 2; `-SkipCheckpoint` skips poll entirely.
- Uses mock filesystem for pending-engram.json lifecycle.

**Dependencies**: Slices 1 + 2 (needs both scripts working end-to-end).

---

### Slice 4 — inter-track: engram-saved kind

**Scope**: `scripts/inter-track.ps1`, `tests/inter-track.Tests.ps1`

| Item | Detail |
|------|--------|
| Files | `scripts/inter-track.ps1` (~10L changed), `tests/inter-track.Tests.ps1` (~45L new) |
| Est lines | ~55L |
| Conv commit | `feat(inter-track): accept engram-saved kind after verification, keep pending-consumed as audit trail` |

**Behavior**:
- Add `engram-saved` as valid `kind` value (accepted only after checkpoint verification confirms persistence).
- `pending-consumed` kind remains as-is (audit trail for pre-gate behavior).
- Unit tests: `engram-saved` kind accepted with valid verification, rejected without; `pending-consumed` still works; invalid kinds rejected.

**Dependencies**: None (independent of Slices 1-3, but logically ordered after enforcement is in place).

---

### Slice 5 — Documentation: core-behavior + delivery-harness

**Scope**: `prompts/shared/_core-behavior-gp.md`, `docs/skills/delivery-harness/reference.md`

| Item | Detail |
|------|--------|
| Files | `prompts/shared/_core-behavior-gp.md` (~8L changed), `docs/skills/delivery-harness/reference.md` (~15L changed) |
| Est lines | ~25L (docs-only, well under 800L limit) |
| Conv commit | `docs: clarify hard gate at close-session, add receipt contract to delivery-harness` |

**Behavior**:
- `_core-behavior-gp.md`: Clarify lines :4-5 as advisory-during-session, hard-gate-at-close (checkpoint is mandatory before session end, not optional mid-session).
- `delivery-harness/reference.md`: Add receipt contract section (B — partial doc-only scope: what constitutes a valid receipt for checkpoint enforcement).

**Dependencies**: Slices 1-4 (docs reflect implemented behavior).

---

## Presets

| Slice | P3 (standard) | P4 (strict) | P5 (paranoid) |
|-------|---------------|-------------|---------------|
| 1 | Unit tests pass, JSON shape correct | + edge case: write failure mid-stream | + fuzz: concurrent checkpoint writes |
| 2 | Unit tests pass, exit codes correct | + timeout boundary: exactly 30s | + stress: rapid open/close cycles |
| 3 | Integration tests pass | + mock filesystem corruption | + real filesystem: temp directory race |
| 4 | Unit tests pass, kind validation correct | + edge: verification token expired | + adversarial: malformed kind strings |
| 5 | Docs render, no broken links | + cross-reference all code paths | + review: docs match actual exit codes |

---

## Review Log

| Slice | Reviewer | Date | Status | Notes |
|-------|----------|------|--------|-------|
| — | — | — | pending | — |

---

## Rollback

Each slice is independently revertable via `git revert <commit-hash>`.

| Slice | Revert impact | Pre-revert check |
|-------|---------------|------------------|
| 1 | session-checkpoint reverts to flag-before-write, JSON loses `persisted`/`pending_file` | Verify no downstream code depends on new JSON fields |
| 2 | close-session reverts to no checkpoint enforcement | Verify `-SkipCheckpoint` references removed cleanly |
| 3 | Integration tests removed, no behavior change | N/A |
| 4 | inter-track reverts to not accepting `engram-saved` kind | Verify no inter-track calls use the new kind yet |
| 5 | Docs revert to prior text | N/A |

**Cross-slice rollback notes**:
- Reverting Slice 1 while keeping Slice 2 → Slice 2's poll target (`pending_file`) disappears. Revert Slice 2 first, or revert both.
- Reverting Slice 4 is safe regardless of other slices (independent kind addition).
- Slice 5 reverts are always safe (doc-only).

---

## Deferred Security Hardening

**Assigned**: Slices 2/4 or future iteration (not blocking Slice 1 delivery).

| Item | Description | Slice | Rationale |
|------|-------------|-------|-----------|
| Allowlist topic_key | Restrict `topic_key` to known patterns (e.g. `checkpoint/*`, `decision/*`) — reject unknowns at checkpoint boundary | Slice 2/4 | Prevents arbitrary topic injection via checkpoint pipeline |
| Schema-validate checkpoint JSON | Validate checkpoint structure against a JSON schema before mem_save | Future | Ensures checkpoint data integrity at persistence boundary |
| delete-on-read | Remove pending-engram.json after successful process-pending read, not just quarantine on failure | Slice 4 | Prevents double-processing; complements stale quarantine |
| mtime-based expiry | Auto-quarantine pending files older than N minutes (e.g. 30min) | Future | Handles orphaned files from crashed sessions without manual cleanup |
