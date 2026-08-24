# ADR-031: Mini-Orchestrator — Async Fire-and-Forget Delegation

- **Status**: Accepted (implemented on `experimento/mini-orchestrator-async`)
- **Deciders**: gentleman-vMK
- **Date**: 2026-08-15
- **Tier**: T2 — Medium complexity, new skill + script modification
- **Context**: Analysis `docs/mejoras/2026-08-08-auto-agent-autonomy-delegation.md` identified the gap: autonomous agents exist (`auto-sub` with deny floor) but delegation is synchronous (blocks conversation) and there is no self-improvement loop trigger. Feature request: "mini agente autónomo para tareas mecánicas/repetitivas, en forma controlada."

## Decision

Implement **async fire-and-forget delegation** as the foundational building block for the mini-orchestrator. When `post-delegation-check.ps1 -Async` is invoked, the orchestrator launches `monitor-subagent.ps1` as a hidden background process and returns immediately. The monitor polls for subagent completion (stability = 2 consecutive identical git-status snapshots) and writes `{BaseRef}.async-result.json` with the final verdict.

The mini-orchestrator skill (`mini-orchestrator/SKILL.md`) documents the BabyAGI-style loop (Execution → Task Creation → Prioritization) that will consume this async handoff once Phases 2-3 are implemented.

**Rejected alternatives**:
- Approach B-only (async without the BabyAGI loop) — insufficient for multi-step mechanical work.
- Approach C (dynamic instruction modification at runtime) — high prompt-injection risk (per Aug 8 analysis).

## Consequences

- **Positive**: Orchestrator no longer blocks on subagent delegation (~30s → ~0s return); enables parallel work-unit execution via `delivery-harness`.
- **Positive**: Reuses existing `auto-sub` deny floor (network, git push --force, supply chain) — no new security surface.
- **Negative**: Introduces a background process lifecycle — caller must poll `{BaseRef}.async-result.json` before trusting the delegation. Documented in the skill's "Consume the result" section.
- **Negative**: `validate-write-scope.ps1` depends on CWD (no `-RepoRoot` param) — monitor inherits CWD from launcher. Documented as a known limitation; same assumption as the existing synchronous path.

## Technical Details

### Async path contract
```
post-delegation-check.ps1 -BaseRef HEAD -AllowedPaths "src/*" -Async
→ Launch-AsyncMonitor() spawns monitor-subagent.ps1 via Start-Process -WindowStyle Hidden
→ exit 0 immediately, prints: "Async monitor started — result file: <path>"
→ Monitor writes {BaseRef}.async-result.json: {status, passed, checks, changed_files, reason, poll_count, waited_sec}
```

### Guardrails inherited from `auto-sub` deny floor
| Category | Denied patterns |
|---|---|
| Network | curl, wget, ssh, telnet, nc, nmap, dig, nslookup, ping, git clone/fetch upstream |
| git push --force | git push --force, --force-with-lease, --delete |
| Supply chain | npm install/i/exec, pip install, yarn add, bun install |
| Destructive | rm -rf /, shred, git clean -fdx (evasion) |
| Zero-width | U+200B, tabs múltiples, triple space |

### Fail-closed behavior
`-Async` without `-AllowedPaths` → exit 1, write_scope check FAIL (v3 Perm-4).

## E2E Verification
- 5/5 Pester tests pass (`tests/post-delegation-async.Tests.ps1`)
- Regression: synchronous path unchanged (0 parse errors, all params present)
- Real E2E: monitor spawned → 3 polls → convergence `reason=stable` → JSON written with `status=OK, passed=True`
