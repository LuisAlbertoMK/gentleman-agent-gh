# ADR-045: Supply-Chain Commands Downgraded from Deny to Ask (C3b+Option-A)

## Status
Accepted - 2026-08-14 (policy), 2026-08-25 (documented retroactively)

## Context
ADR-022 established a hard **deny** floor for package-manager operations
(`npm install`, `npm i`, `npm add`, `node`, `npx`) across all modes, after
`auto-sub` agents were found able to run `npm install evil` unrestricted.

Post-ADR-022 operation showed the deny floor was too blunt:

1. **Legitimate installs were unworkable in practice.** Dependency
   reconciliation (`npm install` to sync a drifted lockfile) is a normal,
   frequent dev task — mejora-log.md:606 documents a session where `npm
   install` was the verified fix for both a lockfile desync and an outdated
   transitive dep. Under deny, every such task required manual out-of-band
   execution.
2. **Deny provided no additional safety over ask when a human is present.**
   In `manual` and `semi` modes every command already surfaces for approval.
   In `auto` mode, `ask` routes the command through `autoAskPatterns`
   (permission-gate-lib.ps1 C4b block), which halts the run pending explicit
   human approval — the same checkpoint deny provided, minus permanent
   lockout of legitimate work.

## Decision (C3b+Option-A)
Downgrade the *resolution* vectors from `deny` to `ask`; keep true
arbitrary-execution and destructive vectors at hard `deny`.

| Command | Before | After | Rationale |
|---|---|---|---|
| `npm install *` / `npm i *` / `npm add *` | deny | **ask** | Human still gates execution; legitimate dep-sync unblocked |
| `node *` | deny | **ask** | Running local scripts is routine; human approves |
| `npx *` | ask→(see note) | **ask** | Same class as npm install |
| `npm exec *` | deny | **deny** | Arbitrary remote package execution — unchanged |
| `npm publish *` / `remove` / `uninstall` / `update` | deny | **deny** | Destructive/public-facing — unchanged |
| `pip *`, `pip3 *`, `pnpm *`, `yarn *`, `bun *` installs | deny | **deny** | Unchanged (ADR-022 floor intact for non-npm managers) |

Note: `shared-deny-rules.json` lines are the single source of truth (SSoT);
the runtime gate loads them dynamically per C4b consolidation.

## Consequences
- Auto-mode runs halt for approval on npm resolution commands instead of
  failing hard — visible in `autoAskPatterns` behavior.
- `tests/permission-gate-lib.Tests.ps1` and
  `scripts/tests/permission-gate.Tests.ps1` must agree with this table.
  A divergence existed between 2026-08-14 (config change) and 2026-08-25
  (test alignment, commit `19259bc8`): the stale root-suite assertion
  expected deny and never executed in ci.yml, masking the contradiction.
- ADR-022's threat model (unattended auto-sub running `npm install evil`)
  remains mitigated: `ask` in unattended contexts blocks until approval.

## References
- Supersedes (partially): ADR-022 deny table for npm resolution commands only
- Implementation: `scripts/opencode-config/shared-deny-rules.json` (SSoT)
- Enforcement tests: `scripts/tests/permission-gate.Tests.ps1` (~10 ASK assertions)
