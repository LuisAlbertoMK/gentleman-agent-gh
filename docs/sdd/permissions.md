# SDD Permission Model

Defines which agents can do what and how scope is enforced.
Single-mode convention adopted from Gentle AI (Refactor-AP S1): one mode, no `-auto`/`-semi` variants.

## Mode System

There is exactly **one mode**. Agent names carry **no suffix**:

| Mode | Routing Suffix | Behavior |
|------|---------------|----------|
| `manual` | (no suffix) | Every delegation asks for confirmation before executing destructive operations; reads execute silently |

### Mode Resolution (precedence)

1. `.gentleman-mode` file (project-level, informational in single-mode)
2. If file missing → fallback to `manual`
3. Read-only specialists (security, seo, infra, docs, frontend, performance, datascience) → always execute (read-only by template)

> Historical note: `permissions.md:19` previously stated fallback `semi` (stale since ADR-033 retired `semi`). Correct fallback is `manual`. The `-auto` layer (14 agent variants + `auto`/`auto-sub` templates) was removed in Refactor-AP S1; `default_agent` is `gentle-MK`.

### Deny-Floor Scope (single protection boundary)

There is ONE protection boundary — the deny-floor below. It applies to every agent, no exceptions:

| Pattern | Why |
|---------|-----|
| `git push *` | Destructive remote mutation |
| `git push --force *` | History rewriting on remote |
| `git rebase *` | History rewriting |
| `git reset *` | State destruction |
| `git merge *` | Branch mutation |
| `git branch -D *` | Branch deletion |
| `docker *` / `docker-compose *` | Container escape risk |
| `ssh *` / `wsl *` | Lateral movement |
| `rm *` / `Remove-Item *` | File destruction |
| `curl *` / `wget *` | Network exfiltration |
| `Invoke-Expression *` / `iex *` | Arbitrary code execution |
| `reg *` / `sc *` / `schtasks *` | System mutation |
| `~/.ssh`, `.env`, credentials | Secret exfiltration (deny-list) |

See `opencode.json` → `permission.bash` for the complete allow/deny/ask matrix.
SSoT: `scripts/lib/opencode-base.json` (deny-floor `:8-151`), `scripts/lib/permission-templates.json` (5 templates: `orchestrator`, `readwrite`, `readonly`, `sddorchestrator`, `reviewer`).

## Delegation Permission Model

Inspired by Gentle AI's profile-scoped delegations:

### Orchestrator → Sub-agent

```
Orchestrator (gentle-MK)
  │
  ├── │ gentleman-quick        │ T1 tasks (single file, low risk)
  ├── │ gentleman-deep         │ T2+ tasks (multi-file, root cause)
  ├── │ gentleman-implementer  │ Implementation tasks
  └── │ sdd-*                  │ SDD phase sub-agents
```

### Scope Rules

| Delegation target | Allowed? |
|-------------------|----------|
| Base agent (no suffix) | Yes — the only path |
| Read-only specialist | Yes — always execute |
| `sdd-*` phase agent | Yes — phase-scoped writes |

### Write Scope Enforcement

After EVERY delegation, `scripts/validate-write-scope.ps1` checks:

```
AllowedPaths: [pattern list for the delegation]
BaseRef: HEAD
```

If ANY modified file falls outside AllowedPaths → `VIOLATION` → STOP + report.

The script uses `git diff --name-only HEAD` to detect changed files (tracked files only — untracked files are not checked; see [Known Limitations](#known-limitations)).

## Agent Permission Boundaries

Each agent in `opencode.json` has explicit `allow`/`deny` file patterns:

| Agent | Write scope | Why |
|-------|------------|-----|
| `gentle-MK` | `*` | Needs full access to coordinate |
| `gentleman-quick` | `*` | Quick edits may touch any file |
| `gentleman-deep` | `*` | Root cause analysis needs full access |
| `gentleman-implementer` | `*` | Implementation needs write scope |
| `gentleman-security` | `*` (read-only) | Security audit — no write permission |
| `gentleman-seo` | `*` (read-only) | SEO audit — no write permission |
| `gentleman-infra` | `*` (read-only) | Infra audit — no write permission |
| `sdd-*` sub-agents | `*` | SDD artifact creation |

Write scope is enforced at TWO levels:
1. **Tool level** — `opencode.json` permission rules (deny dangerous commands, ask for destructive ones)
2. **Script level** — `validate-write-scope.ps1` runs post-delegation to verify the sub-agent didn't modify files outside its allowed scope

## Task Complexity → Agent Routing

T-level classification determines which agent handles the task:

| Level | Criteria | Agent | Fallback |
|-------|----------|-------|----------|
| T1 | 1 file, known codebase, no ambiguity | `gentleman-quick` | `gentleman-deep` |
| T2 | 2-5 files, moderate complexity | `gentleman-deep` | — |
| T3 | 5+ files, cross-module change | `gentleman-deep` | SDD pipeline |
| T4 | Architecture change, high risk | SDD pipeline | — |

Security-domain tasks route to `gentleman-security` regardless of T-level.

## SDD Phase Permissions

SDD phases respect the same single-mode system:

| Phase | Permission check |
|-------|-----------------|
| Init | Read-only (scaffold config) |
| Explore | Read-only (codebase analysis) |
| Propose | Write to `docs/sdd/proposals/` |
| Design | Write to `docs/sdd/designs/` |
| Spec | Write to `docs/sdd/specs/` |
| Tasks | Write to `docs/sdd/tasks/` |
| Apply | Write to project source files |
| Verify | Read-only (test runner) |
| Archive | Write to `docs/sdd/registry.yaml` + `docs/sdd/archive/` |

## Mode Gate Protocol

Before every delegation, the orchestrator MUST run:

```powershell
.\scripts\mode-gate.ps1 -TargetAgent "gentleman-{name}"
```

The gate validates the target agent exists (single-mode: every known base agent is ALLOWED, no suffix required).
Retirement of `-auto` enforcement in the gate script itself lands in Refactor-AP S2; until then the gate accepts base names.

## Known Limitations

- `validate-write-scope.ps1` uses `git diff --name-only` which only detects MODIFIED tracked files. Untracked files are not detected as violations.
- Read-only specialists have `*` permission in opencode.json but their prompts instruct them not to write — trust-based enforcement.

## References

- `opencode.json` — tool-level permission matrix (allow/deny/ask)
- `.gentleman-mode` — mode chip (informational in single-mode)
- `scripts/validate-write-scope.ps1` — post-delegation scope enforcement
- `scripts/tests/validate-write-scope.Integration.Tests.ps1` — scope enforcement tests
- `scripts/mode-gate.ps1` — pre-delegation validation gate (single-mode retirement: S2)
- `scripts/tests/mode-gate.Integration.Tests.ps1` — mode gate tests
- Gentle AI upstream — single-mode + human-owned (commit/push/release stay human call) + deny-list convention
