# ADR-042: Async delegation contract validation (C4d) via file transport

**Status**: Accepted
**Date**: 2026-08-20
**Cycle**: 30 (plan: `docs/mejoras/plan-auto-mejora-v3-2026-08-20-c30.md`)
**Branch**: `experimento/mejora-autonoma-2026-08-20-c30`

## Context

`docs/mejoras/2026-08-15-subagent-result-quality.md` specified that async
delegations expose `contract_valid` / `contract_detail` in `async-result.json`,
but grep showed zero matches for `SubagentOutputFile|contract_valid` in
`scripts/monitor-subagent.ps1`: the doc described behavior that did not exist
(doc/code drift). The sync path (`post-delegation-check.ps1`) validated the
4-field contract inline; the async path (monitor) did not validate at all.

Constraint: the monitor invokes check-subagent-output as a subprocess whose
command line is a single string; passing multiline agent output inline is
unsafe (argument-passing modes truncate at newlines — observed under the
pre-commit gate).

## Decision

1. **File transport**: new `-AgentOutputFile <path>` param on
   `check-subagent-output.ps1`; loads output via `[IO.File]::ReadAllText`,
   fails closed (exit 1) if unreadable. File wins over inline `-AgentOutput`.
2. **Monitor wiring**: new `-SubagentOutputFile` param on
   `monitor-subagent.ps1`; passes the escaped path to the cso subprocess,
   appends a `contract_validation` check entry, and exposes
   `contract_ran` / `contract_valid` / `contract_detail` at the top level of
   `async-result.json`.
3. **Not-evaluated semantics**: when validation did not run (param absent or
   file missing), emit `contract_valid=true`, `contract_detail="not evaluated"`,
   `contract_ran=false` — matching the sync-path convention that an absent
   contract property is not a violation, while making the state explicit.
4. **Gate hardening**: `[12/13]` of `.githooks/pre-commit-gate.ps1` strips
   hook-exported `GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE/GIT_OBJECT_DIRECTORY`
   before running staged Pester suites.

## Incident (root cause of gate-context test failures)

During this cycle, commits were blocked by a Pester failure that only occurred
inside the pre-commit gate. Diagnosis chain:

1. git exports `GIT_DIR`/`GIT_INDEX_FILE` into hook processes; Pester runs
   in-process, so hermetic-repo fixtures inherited them and silently operated
   on THIS repo.
2. Consequence observed: a fixture's `git init` rewrote this repo's
   `core.worktree` to a deleted Temp path → every git command failed with
   `fatal: Invalid path 'C:/Users/MK/AppData/Local/Temp/Pester_...'`;
   fixture commits landed on the feature branch; local identity was
   overwritten by fixture values.
3. Recovery: removed the bogus `worktree` line from `.git/config`, restored
   identity from reflog, `git read-tree HEAD` to rebuild the index, and
   `git reset 85176d54` to drop two fixture commits ("init"/"second") that had
   swept real changes into the branch tip.
4. Residual flake after env strip: `$TestDrive` persists across Its within a
   run; a fixed fixture name let test N+1's `git add .` silently commit test
   N's leftover untracked files, producing an empty-status fixture and a bogus
   `empty-output` early exit from cso (JSON without contract fields →
   PropertyNotFoundException under the gate's `Set-StrictMode -Version Latest`).
   Fix: unique fixture path per test (GUID suffix) + loud base-commit check.

## Alternatives considered

- **Inline `-AgentOutput` pass-through** (rejected): multiline arguments are
  host-dependent; truncation produced binding failures under the gate.
- **Monitor validates the contract itself** (rejected): duplicates the
  validator; drift risk with the sync path.
- **contract_valid=false when not evaluated** (rejected): contradicts sync
  path; "unknown" must not read as "violated".

## Consequences

- Async consumers can rely on `contract_valid` in `async-result.json`
  (spec 2026-08-15 now actually implemented).
- All test suites running under the gate are immune to hook-exported git env;
  suites additionally sanitize their own env (defense in depth).
- Test fixtures across the repo should use unique per-test paths; fixed names
  are a latent cross-test pollution vector.

## Breaker findings (adversarial review)

- [HIGH] **ExpectedFiles array binding** (pre-existing, both paths):
  `-ExpectedFiles 'a' 'b'` in a `-Command` string binds only the first value;
  the second falls through to positional binding. Deferred to Ciclo 31 with
  fix recipe: repeat the parameter (`-ExpectedFiles 'a' -ExpectedFiles 'b'`),
  which accumulates for `[string[]]`.
- [MEDIUM] timeout masks contract signal → addressed by exposing
  `contract_ran` (commit `013e4577`).
- [LOW] gate strip only covers check [12/13]; other checks target the main
  repo and do not create fixtures — accepted residual risk, revisit if any
  future check creates nested repos.

## Verification

- Targeted: post-delegation-async 8/8, cso suites 12/12 (incl. under gate).
- Full suite ×2 identical: 1308 pass / 31 pre-existing fail / 1340 total
  (baseline main: 1304/31/1336; delta = +4 new green tests, 0 regressions).
- Quality gate 22/22 ALL CLEAR on every code commit.
