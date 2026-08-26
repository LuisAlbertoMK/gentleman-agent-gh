# ADR-046: Toolchain Freedom — docker/python/pnpm available in every mode

## Status
Accepted - 2026-08-26 (owner directive)

## Context
The permission model blocked the entire toolchain by default:

- `docker`, `docker compose`, `docker-compose` — deny (all modes)
- `python`, `python3`, `pip install`, `pip3` — deny
- `pnpm`, `yarn`, `bun` (all subcommands) — deny
- `node`, `npx`, `npm install/add/i` — ask

This contradicted the standing owner directive recorded in ADR-005
(2026-08-02): *"auto debería ser autónomo — sin push ni delete automático,
lo demás sin problema"*. In practice the orchestrator (`gentleman-vMK`)
could not run containers, Python tooling, or the owner's preferred package
manager without manual approval on every command, and auto-mode agents were
not self-sufficient.

Additionally `pnpm` — the owner's preferred package manager — was treated
*worse* than npm (hard deny vs ask), an inconsistency with no security
justification.

## Decision
Introduce a third rule value, `"allow"`, and reclassify all toolchain
commands as allowed in every mode. Hard `deny` is reserved for genuinely
dangerous operations.

### New classification table

| Command class | Verdict | Modes |
|---|---|---|
| `docker *`, `docker compose *`, `docker-compose *` | **allow** | all |
| `python *`, `python3 *`, `pip install *`, `pip3 *` | **allow** | all |
| `pnpm *`, `yarn *`, `bun *` (installs/runs) | **allow** | all |
| `node *`, `npx *`, `npm install/add/i *` | **allow** | all |
| `npm exec *`, `npm publish/remove/uninstall/update *` | deny | all |
| System/security set (net*, sc, reg, schtasks, certutil, MpPreference, cmd/powershell -enc, iex/iwr/irm, ssh/telnet/nc/wsl, git force-push) | deny | all |
| rm / Remove-Item / git clean/restore/rm | deny manual+semi, **ask** auto | mode-governed |
| `git push`, branch -D, stash drop, reset | ask | all |

### Layer changes
1. **`shared-deny-rules.json`** (SSoT): toolchain values → `"allow"`; loader
   (`permission-gate-lib.ps1`) gains `$script:allowPatterns` bucket; check
   order becomes deny → allow → destructive → mode.
2. **`permission-templates.json`**: same reclassification across `auto`,
   `auto-sub`, `semi`; semi catch-all `npm *` softened deny→ask.
3. **`opencode.json`**: global bash map aligned to ask for toolchain;
   `gentleman-vMK` receives explicit allows (docker/python/pip/pnpm/node/
   npx/npm-installs/go) over its `"*": "ask"` fallback; all 11 `-auto`
   agents upgraded to allow for self-sufficiency (docker stays ask for
   unattended subs — host-escape guardrail; full allow only for vMK).
4. **Package manager preference**: pnpm preferred over npm when available
   (owner directive); npm remains fully usable.

## Consequences
- Auto-mode agents can now provision dependencies (pip/npm/pnpm installs)
  and run Python/Node/Docker workloads without human intervention.
- The human-approval checkpoint for supply-chain risk moves from "blocked"
  to "visible": installs still appear in session logs and can be audited.
- ADR-022's original threat (unattended `npm install evil` with zero
  friction) is accepted as residual risk by owner decision; mitigations:
  trufflehog + SkillSpector + GitGuardian remain active in CI.
- 15 test assertions updated; NBSP-evasion test now asserts normalization
  routes the command into the allow pattern (evasion cannot escalate).

## References
- Supersedes (partially): ADR-022 deny table for toolchain commands
- Owner directives: ADR-005 context (2026-08-02), session 2026-08-26
- SSoT: `scripts/opencode-config/shared-deny-rules.json`
- Enforcement: `scripts/lib/permission-gate-lib.ps1` (allowPatterns),
  `opencode.json` agent permissions
