# SDD Permission Model

Defines which agents can do what, under which mode, and how scope is enforced.
Replicates the Gentle AI permission convention adapted for gentleman-agent-gh.

## Mode System

The `.gentleman-mode` file at project root sets the current mode:

| Mode | Routing Suffix | Behavior |
|------|---------------|----------|
| `auto` | `-auto` | All commands auto-approved except `deny` list (push, deletes, docker, network, destructive) |
| `semi` | `-semi` | Write operations prompt for approval; reads execute silently |
| `manual` | (no suffix) | Every delegation asks for confirmation before executing |

### Mode Resolution (precedence)

1. `.gentleman-mode` file (project-level)
2. If file missing → fallback to `semi`
3. Read-only specialists (security, seo, infra) → NO suffix (always execute)

### Auto Mode Scope

In `auto` mode, the following are STILL protected (require explicit ask):

| Pattern | Why |
|---------|-----|
| `git push *` | Destructive remote mutation |
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

See `opencode.json` → `permission.bash` for the complete allow/deny/ask matrix.

## Delegation Permission Model

Inspired by Gentle AI's profile-scoped delegations:

### Orchestrator → Sub-agent

```
Orchestrator (gentleman-orchestrator)
  │
  ├── │ gentleman-quick        │ T1 tasks (single file, low risk)
  ├── │ gentleman-deep         │ T2+ tasks (multi-file, root cause)
  ├── │ gentleman-apply        │ Implementation tasks
  ├── │ *-auto                 │ Auto mode variant (appends -auto suffix)
  └── │ sdd-*                  │ SDD phase sub-agents
```

### Scope Rules

| If orchestrator mode is | Sub-agent suffix | Allowed? |
|------------------------|-----------------|----------|
| auto | (no suffix) | Yes — but preferred path is `-auto` |
| auto | `-auto` | Yes — optimal, no ask |
| auto | (read-only specialist) | Yes — NO suffix, always execute |
| semi | (any) | Yes — but writes prompt user |
| manual | (any) | Yes — always prompt user first |

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
| `gentleman-orchestrator` | `*` | Needs full access to coordinate |
| `gentleman-quick` / `gentleman-quick-auto` | `*` | Quick edits may touch any file |
| `gentleman-deep` / `gentleman-deep-auto` | `*` | Root cause analysis needs full access |
| `gentleman-apply` / `gentleman-apply-auto` | `*` | Implementation needs write scope |
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

SDD phases respect the same mode system:

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
.\scripts\mode-gate.ps1 -TargetAgent "gentleman-{name}" [-Mode auto|semi|manual]
```

The gate validates that the agent suffix matches the current mode:

| Mode | Required Agent Suffix | Example |
|------|----------------------|---------|
| `auto` | `-auto` | `gentleman-quick-auto` |
| `semi` | `-semi` | `gentleman-quick-semi` |
| `manual` | (none) | `gentleman-quick` |

**If the gate blocks (exit code 1)**, the orchestrator re-routes to the correct agent.
**Exceptions**: read-only specialists (security, seo, infra) and SDD sub-agents always pass without suffix.

## Known Limitations

- `validate-write-scope.ps1` uses `git diff --name-only` which only detects MODIFIED tracked files. Untracked files are not detected as violations.
- Mode check reads `.gentleman-mode` at session start; changing the file mid-session requires a reset.
- Read-only specialists have `*` permission in opencode.json but their prompts instruct them not to write — trust-based enforcement.

## References

- `opencode.json` — tool-level permission matrix (allow/deny/ask)
- `.gentleman-mode` — current mode chip
- `scripts/validate-write-scope.ps1` — post-delegation scope enforcement
- `scripts/tests/validate-write-scope.Integration.Tests.ps1` — scope enforcement tests
- `scripts/mode-gate.ps1` — pre-delegation mode validation gate
- `scripts/tests/mode-gate.Integration.Tests.ps1` — mode gate tests
- Gentle AI `docs/opencode-profiles.md` — upstream profile permission convention
