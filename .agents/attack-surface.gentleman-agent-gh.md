# Attack Surface: gentleman-agent-gh

**Profile**: PowerShell + Node.js toolchain, dev-ops automation, permission template orchestration.

## Primary Attack Vectors

| Vector | Scope | Risk | Mitigation |
|--------|-------|------|------------|
| `scripts/*.ps1` (100+ files) | All PS scripts execute `git`, `node`, `gh` subprocesses | 🔴 High — command injection via git args, node script execution | PSSA `PSAvoidUsingWriteHost` (766 tracked), pre-commit gate [2/13] AST parse check, [12/13] Pester tests |
| `scripts/lib/generate-opencode-config.js` | Merges permission templates → writes `opencode.json` | 🔴 High — privilege escalation via template merge | Fail-closed `detectTemplate()`, `validate-merge.js` (R7), `--validate` idempotent check |
| `review-rules.jsonc` | Defines ROZA zones, JD profiles, verify thresholds | 🟠 High — changing zones can bypass verify | ADR-021, pre-commit gate [7/13] integrity check, JD review for `*.jsonc` |
| `opencode.json` | SSoT permission policy for ALL agents | 🔴 Critical — direct permission grant/revocation | Config sync check [14/14], SSoT sync [7/14], size budget [17/17] |
| `.githooks/pre-commit-gate.ps1` | 21-check quality gate (PSSA, tests, secrets, config) | 🔴 Critical — bypass = no quality enforcement | PSSA parse check [2/13], secrets scan [10/13], write-scope check [15/15] |
| `.agents/skills/*/SKILL.md` | Agent behavior definitions (triggers, rules, protocols) | 🟠 High — skill override = agent behavior hijack | Taste invariant [11/13] frontmatter check, skill drift [4/13] |

## Secondary Vectors

| Vector | Scope | Risk | Mitigation |
|--------|-------|------|------------|
| `.project.json` | Score dimensions, improvement cycle state | 🟡 Medium — score manipulation hides quality decay | .project.json integrity [6/13], benchmark check [8/13] |
| `adr/*.md` | Architecture decisions | 🟡 Medium — decision drift | ADR drift check [6/13], cross-ref check |
| `scripts/lib/permission-templates.json` | Permission template definitions | 🟠 High — template content = agent capability surface | Pre-commit gate [9/13] ROZA blocking, template-detection SSoT parity |
| `docs/mejoras/*.md` | Improvement backlog | 🟢 Low — documentation only | Backlog integrity [18/18] |

## Trust Boundaries

1. **Template merge boundary** — `generate-opencode-config.js` is the ONLY writer of `opencode.json`. All template inputs flow through `detectTemplate()` (fail-closed) and the validation layer (R7 `validate-merge.js`).
2. **Subprocess boundary** — 68 PS1 scripts invoke `git`, `node`, or `gh` via `Invoke-Expression` / `&` operator. Review `bash-safe.ps1` for sanitization pattern.
3. **Skill boundary** — `.agents/skills/` overrides global skills. Local skills take precedence.
4. **Config boundary** — `.project.json` is the project-local config. `review-rules.jsonc` is the declarative quality policy.

## Breaker Focus Areas (from PS attack profile)

1. **Command Injection** — `bash-safe.ps1` uses `&` call operator (18 call sites). `Invoke-Bash` wrapper. Check for unsanitized input propagation.
2. **Path Manipulation** — `Join-Path` with `$RepoRoot` is safe, but `Expand-String` and template expansion paths may be user-controlled.
3. **Code Execution** — `Add-Type` usage? `[ScriptBlock]::Create()`? `New-Object -ComObject`? (Verify via PSSA.)
4. **Data Leakage** — 766 `Write-Host` violations tracked. Verbose/Debug streams in PS scripts?
5. **SSRF** — `Invoke-WebRequest` / `Invoke-RestMethod` usage? Check `mcp-resilience.ps1`, `ctx-fetch-and-index`.
6. **Concurrency** — `ForEach-Object -Parallel` usage? `Start-Job`? Check `skill-graph.ps1` parallel expansion.

## File Categories by Risk

| Risk | Files |
|------|-------|
| 🔴 Critical | `scripts/lib/generate-opencode-config.js`, `.githooks/pre-commit-gate.ps1`, `opencode.json` |
| 🟠 High | `scripts/delegation-registry.ps1`, `scripts/route-agent.ps1`, `scripts/check-subagent-output.ps1`, `review-rules.jsonc` |
| 🟡 Medium | `scripts/skill-*.ps1`, `scripts/use-gentleman.ps1`, `.project.json` |
| 🟢 Low | `*.md` (docs, ADRs, skill SKILL.md) |

## Breaker Scope: Per-Commit

Breaker should focus on staged files matching ROZA patterns:
- `*.ps1` (all scripts)
- `scripts/` (entire scripts dir)
- `*.js` with logic (generate-opencode-config.js)
- `*.json` config (opencode.json, .project.json)
- `.githooks/*.ps1`

Non-code changes (markdown, lock files) → Phase 7 regression only.
