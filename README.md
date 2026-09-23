# Gentleman Agent — OpenCode AI Agent Skills & Scripts

## What is this?

**Gentleman Agent** is an **AI software development team** for OpenCode. Instead of a single chatbot, you get 58 specialized agents working together:

- 🏗️ **Lead Architect** — Senior Architect mentor solving complex tasks
- 🔒 **Specialists** — Security, performance, frontend, etc. consultants (FREE TIER)
- 🧠 **Persistent memory** — the agent remembers across sessions
- ✅ **Auto-verification** — triple check before any change

**In one line**: You ask for a task → the agent resolves it with its team → verifies it works → documents what it learned.

**Start here**: [QUICKSTART.md](QUICKSTART.md) (5 steps, 5 minutes)

---

Suite of **96 skills** (+ `_shared`) + **136 top-level scripts** (129 PowerShell + 7 shell) for [OpenCode](https://github.com/sst/opencode). Designed for software development with clean architecture, TDD, and multi-layer verification.

> **Repo**: `LuisAlbertoMK/gentleman-agent-gh`
> **Score**: 9.6/10 (14 dimensions) — tracking in .project.json.
> **Skills**: 96 (+ `_shared`)
> **Cycle**: 31 (active) — CA fidelity + G4-G8 remediation

---

## Prerequisites

- **OpenCode** (latest) — [github.com/sst/opencode](https://github.com/sst/opencode)
- **PowerShell 7+** (Windows) / **bash** (Linux/macOS) — required for scripts & tests
- **PowerShell 5.1** (Windows) — orchestrator host shell; scripts declare `#requires -Version (5.1|7)` (see [docs/operations/RUNBOOK.md](docs/operations/RUNBOOK.md))
- **Node.js** — for npm-based tools
- **Go** (optional) — rebuilds `bin/fast.exe` (fast gate: cross-ref + token-budget). Without it, the pre-commit gate falls back to PowerShell automatically.

## Quick Start

1. **Clone & install**: `git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git && cd gentleman-agent-gh && ./scripts/install.sh`
2. **Open**: `opencode` in the project folder — `gentle-MK` loads automatically
3. **Ask**: "Analyze my project" · "Review this file" · "Create a test"
4. **Shortcuts**: `!score` · `!health` · `!analisis`
5. **Close**: `!close`

> Full walkthrough: [QUICKSTART.md](QUICKSTART.md)

## Configuration

The `.gentleman-mode` file at project root controls permission level:

| Mode | Content | Behavior |
|------|---------|----------|
| `manual` | `manual` | Agent asks before every tool call |
| `semi` | `semi` | Safe commands auto-approved, rest asks |
| `auto` | `auto` | Most things auto-approved (except push=deny, delete=ask) |

Switch modes:

```powershell
.\scripts\switch-mode.ps1 -Mode semi   # change mode
.\scripts\switch-mode.ps1 -Status      # check current mode
```

> Default is `manual`. See [PROTOCOL.md](PROTOCOL.md) for full mode behavior.

---

## Features

### Multi-Agent Architecture
58 agents total: main orchestrator (`gentle-MK`) + 12 specialists + 12 subagent twins + 10 SDD pipeline agents + 14 auto-mode variants + 1 global orchestrator bridge (`gentle-orchestrator`):

| Agent | Model | Specialty |
|-------|-------|-----------|
| `gentle-MK` | default | Senior Architect mentor — main orchestrator |
| `gentleman-deep` | deepseek-v4-flash | Architecture, design, complex code |
| `gentleman-reasoning` | deepseek-v4-flash | Deep chain-of-thought debugging, multi-step synthesis |
| `gentleman-code-review` | qwen3.7-plus | Code review 73.4% SWE-bench → fallback muse-spark → default |
| `gentleman-initializer` | deepseek-v4-flash | Harness initializer — different prompt first window |
| `gentleman-codex` | mimo-v2.5 | Code generation, boilerplate |
| `gentleman-quick` | muse-spark-1.3-contributor | Fast tasks, review, simple edits |
| `gentleman-security` | deepseek-v4-flash | Vulnerability analysis, secure code (FREE TIER) |
| `gentleman-seo` | deepseek-v4-flash | SEO, GEO, keyword analysis (FREE TIER) |
| `gentleman-infra` | mimo-v2.5 | IaC, Kubernetes, CI/CD (FREE TIER) |
| `gentleman-frontend` | muse-spark-1.3-contributor | React, Tailwind, accessibility (FREE TIER) |
| `gentleman-performance` | deepseek-v4-flash | Code optimization, bottlenecks (FREE TIER) |
| `gentleman-datascience` | muse-spark-1.3-contributor | Pandas, SQL, stats (FREE TIER) |
| `gentleman-docs` | muse-spark-1.3-contributor | Technical writing, docs (FREE TIER) |
| `gentleman-implementer` | mimo-v2.5 | Plan executor (FREE TIER) |
| `gentleman-reviewer` | deepseek-v4-flash | Code review — 4R (Risk/Readability/Reliability/Resilience) |
| `gentleman-aem` | deepseek-v4-flash | Adobe Experience Manager migration specialist |
| `gentleman-deep-sub` | deepseek-v4-flash | Deep reasoning subagent — delegable via Task tool |
| `gentleman-codex-sub` | mimo-v2.5 | Code generation subagent — delegable via Task tool |
| `gentleman-quick-sub` | muse-spark-1.3-contributor-free | Fast executor subagent — delegable via Task tool |
| `gentleman-implementer-sub` | mimo-v2.5 | Plan executor subagent — delegable via Task tool |
| `gentleman-security-sub` | deepseek-v4-flash | Security audit subagent (read-only) — delegable via Task tool |
| `gentleman-seo-sub` | deepseek-v4-flash | SEO/content audit subagent (read-only) — delegable via Task tool |
| `gentleman-infra-sub` | mimo-v2.5 | Infrastructure subagent (read-only) — delegable via Task tool |
| `gentleman-frontend-sub` | muse-spark-1.3-contributor-free | Frontend/UI subagent (read-only) — delegable via Task tool |
| `gentleman-performance-sub` | deepseek-v4-flash | Performance subagent (read-only) — delegable via Task tool |
| `gentleman-datascience-sub` | muse-spark-1.3-contributor-free | Data science subagent (read-only) — delegable via Task tool |
| `gentleman-docs-sub` | muse-spark-1.3-contributor-free | Documentation subagent (read-only) — delegable via Task tool |
| `gentleman-reviewer-sub` | deepseek-v4-flash | Code review subagent — 4R (Risk/Readability/Reliability/Resilience) |
| `gentleman-aem-sub` | deepseek-v4-flash | AEM migration subagent — delegable via Task tool |
| `gentleman-reasoning-sub` | deepseek-v4-flash | Reasoning subagent — delegable via Task tool |
| `gentleman-code-review-sub` | qwen3.7-plus | Code review subagent — delegable via Task tool |
| `gentleman-initializer-sub` | deepseek-v4-flash | Initializer subagent — delegable via Task tool |
| `gentle-orchestrator` | muse-spark-1.3-contributor | Bridge to global gentle-orchestrator for native review + SDD native |
| `gentleman-deep-auto` | deepseek-v4-flash | — AUTO mode (same model, `*: allow`) |
| `gentleman-quick-auto` | muse-spark-1.3-contributor | — AUTO mode (same model, `*: allow`) |
| `gentleman-codex-auto` | mimo-v2.5 | — AUTO mode (same model, `*: allow`) |
| `gentleman-implementer-auto` | mimo-v2.5 | — AUTO mode (same model, `*: allow`) |
| `gentle-MK-auto` | muse-spark-1.3-contributor | — AUTO mode (orchestrator, `*: allow`) |
| `gentleman-aem-auto` | deepseek-v4-flash | — AUTO mode (Adobe Experience Manager migration) |
| `gentleman-deep-sub-auto` | deepseek-v4-flash | — AUTO sub agent (same model, `*: allow`) |
| `gentleman-reasoning-sub-auto` | deepseek-v4-flash | — AUTO reasoning sub agent (same model, `*: allow`) |
| `gentleman-code-review-sub-auto` | qwen3.7-plus | — AUTO code review sub agent (`*: allow`) |
| `gentleman-initializer-sub-auto` | deepseek-v4-flash | — AUTO initializer sub agent (`*: allow`) |
| `gentleman-quick-sub-auto` | muse-spark-1.3-contributor-free | — AUTO sub agent (same model, `*: allow`) |
| `gentleman-codex-sub-auto` | mimo-v2.5 | — AUTO sub agent (same model, `*: allow`) |
| `gentleman-implementer-sub-auto` | mimo-v2.5 | — AUTO sub agent (same model, `*: allow`) |
| `gentleman-aem-sub-auto` | deepseek-v4-flash | — AUTO sub agent (Adobe Experience Manager migration) |

> **Auto/Semi modes**: Activated when `.gentleman-mode` is `auto` or `semi`. See [PROTOCOL.md](PROTOCOL.md) for mode behavior. Read-only specialists have no `-auto` or `-semi` variant.

#### SDD Pipeline Agents (subagents)
10 agents executing SDD pipeline phases. Each has an explicit `model` in `opencode.json`. All have full permissions (`bash: allow, edit: allow, write: allow`).

| Agent | Phase | Model | Description |
|-------|-------|-------|-------------|
| `sdd-init` | Init | mimo-v2.5 | Bootstrap SDD context and project configuration |
| `sdd-explore` | Explore | deepseek-v4-flash | Investigate codebase and think through ideas |
| `sdd-propose` | Propose | deepseek-v4-flash | Create change proposals from explorations |
| `sdd-spec` | Spec | deepseek-v4-flash | Write detailed specifications from proposals |
| `sdd-design` | Design | deepseek-v4-flash | Create technical design from proposals |
| `sdd-tasks` | Tasks | mimo-v2.5 | Break down specs and designs into implementation tasks |
| `sdd-apply` | Apply | mimo-v2.5 | Implement code changes from task definitions |
| `sdd-verify` | Verify | muse-spark-1.3-contributor | Validate implementation against specs |
| `sdd-archive` | Archive | mimo-v2.5 | Archive completed change artifacts |
| `sdd-orchestrator` | Orchestrator | deepseek-v4-flash | SDD pipeline orchestration |

> **Cost**: All SDD agents use explicit models in `opencode.json` (deepseek-v4-flash, mimo-v2.5, muse-spark-1.3-contributor).

### Self-Improvement Cycle
The project runs continuous improvement cycles (CYCLE.md):

- **Prioritized backlog** by Impact/Risk
- **inter(30) metric**: minimum 30 meaningful interactions per cycle
- **Triple verification** (E1/E2/E3) by difficulty
- **Auto-updated score** after each significant change
- **Bias calibration** via external auditor subagent

### Verification Pipeline

| Mode | Verify | Gate | Commit |
|------|--------|------|--------|
| `!ship` | Triple verify | Quality gate + PSSA | ✅ auto |
| `!check` | Verify profiles | Quality gate | ❌ |
| `!fast` | Skip | Quality gate | ✅ auto |
| `!draft` | Skip | Skip | ❌ |
| `!close` | — | — | Session close |

### Workflow Shortcuts

> **Full shortcut reference**: [SHORTCUTS.md](SHORTCUTS.md)

| Keyword | Action |
|---------|--------|
| `!score` | Score auto-update + docs/operations/project-score.md sync |
| `!health` | Full diagnostics (git, drift, cross-ref, score, inter) |
| `!close` | Session close pipeline (bitacora + inter-track + git status) |
| `!analisis` | Multi-agent analysis (6 specialists, 8 dimensions) |

### SDD Pipeline (Spec-Driven Development)
9 complete phases: `init → explore → propose → design → spec → tasks → apply → verify → archive`

---

## Installation

### Windows (PowerShell 7+)
```powershell
# Clone and install
git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git
cd gentleman-agent-gh
.\scripts\setup-install.ps1
```

### Linux/macOS
```bash
# Clone and install
git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git
cd gentleman-agent-gh
./scripts/install.sh
```

### MCP Setup (recommended)
The project uses two MCPs for cross-session memory:

- **[Engram](https://engram.mentat.ai)**: Persistent memory. Install with `opencode mcp add engram`
- **Context7**: Updated library documentation. Install with `opencode mcp add context7`

---

## Included Skills

| Scope | Count | Reference |
|-------|-------|-----------|
| Skills | 96 specialized skills for analysis, security, testing, docs, and more | See [SKILLS-INDEX.md](SKILLS-INDEX.md) for full trigger table |

---

## Scripts (91 top-level in scripts/)

| Script | Purpose |
|--------|---------|
| `score-auto.ps1` | Auto-scoring in 13 dimensions + 32 sub-dims |
| `skill-graph.ps1` | BFS skill resolution (sparse loading, −85-92%) |
| `verify.ps1` | Triple verification E1/E2/E3 |
| `pssa-gate.ps1` | PSScriptAnalyzer with BOM auto-fix |
| `inter-track.ps1` | Interaction tracking per cycle |
| `cross-ref-check.ps1` | Skills ↔ SKILLS-INDEX consistency |
| `check-skill-drift.ps1` | Drift detection between canonical and global |
| `check-backlog-integrity.ps1` | Backlog vs reality verification |
| `check-upstream.ps1` | External repo monitoring |
| `batch.ps1` | Auto-incremental batch with bitacora |
| `close-session.ps1` | Unified session close pipeline |
| `restore-project-score.ps1` | Restores .project.json if vMK overwrites it |
| `run.ps1` | Universal runner from global junction |
| `ensure-tools.ps1` | Verifies rg/sg/gh in PATH |
| `token-count.ps1` | Approximate token counting |
| `session-miner.ps1` | Cross-session pattern mining |
| `run-dreaming.ps1` | Auto-dreaming trigger |
| `skill-validate.ps1` | Multi-trial skill validation |
| `smoke/smoke-all.ps1` | Smoke tests for automation claims |
| `benchmark.ps1` | Skills and scripts benchmarking |
| `trend.ps1` | Scoring trend analysis |
| `health-check-system.ps1` | System health check (MCP, disk, git, permissions) |
| `setup-install.ps1` / `install.sh` | Multi-platform installer (Windows/Linux/macOS) |

### Fast gate binary (`bin/fast.exe`)

`bin/fast.exe` is a **build artifact, not committed**. All consumers degrade gracefully without it (PS fallback / `WARN` + escalate). To rebuild from source after cloning or after changing `cmd/fast/main.go`:

```sh
go build -o bin/fast.exe ./cmd/fast
```

Source: [`cmd/fast/main.go`](cmd/fast/main.go) — hot-path checks: `--cross-ref` (<300ms), `--token-budget` (<80ms), `--gate` combined (<150ms).

### Sync binary (`bin/sync.exe`)

`bin/sync.exe` is a **build artifact, not committed**. It generates and updates `opencode.json` configs from the SSoT chain (`opencode-base.json` + `permission-templates.json` + `agent-overrides.json`), applying the security deny floor and CBM_ALLOWED_ROOT scoping.

```sh
go build -o bin/sync.exe ./cmd/sync
```

Commands:

| Command | Flags | Purpose |
|---------|-------|---------|
| `sync install` | `--target <dir>` `--default-agent` `--chain-root` `--force` `--dry-run` `--json` | Install bootstrap — generate initial config in target dir |
| `sync update` | `--project <dir>` `--chain-root` `--mode chain-wins\|project-wins` `--dry-run` `--json` | Update re-sync — reconcile one project against current chain |
| `sync update-all` | `--manifest <projects.json>` `--chain-root` `--mode` `--parallel` `--dry-run` `--json` | Batch update — process all projects in a manifest |

Exit codes: `0` = ok, `1` = failure.

Source: [`cmd/sync/main.go`](cmd/sync/main.go).

### Sync PowerShell wrapper (`scripts/sync-n-projects.ps1`)

Syncs 1..N projects via a manifest file. If `bin/sync.exe` exists, delegates to `sync update-all --manifest`; otherwise falls back to `scripts/use-gentleman.ps1` per project (slower but functional).

```powershell
.\scripts\sync-n-projects.ps1 -Manifest ./projects.json -Mode chain-wins
```

Parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-Manifest` | `./projects.json` | Path to manifest file |
| `-Mode` | `chain-wins` | Conflict resolution: `chain-wins` or `project-wins` |
| `-DryRun` | off | Show what would change without writing |
| `-Json` | off | Output structured JSON instead of human-readable table |
| `-AddProject` | — | Add a project path to the manifest before syncing |

Exit codes: `0` = ok, `1` = failure, `2` = drift (some projects failed or drifted).

### Manifest (`projects.json`)

Minimal example:

```json
{
  "version": 1,
  "chainRoot": ".",
  "defaultMode": "chain-wins",
  "projects": [
    {
      "path": "../mi-api",
      "defaultAgent": "gentle-MK"
    }
  ]
}
```

Typical workflow — dry run first, then real sync:

```sh
# 1. Preview changes
.\scripts\sync-n-projects.ps1 -DryRun

# 2. Apply
.\scripts\sync-n-projects.ps1
```

---

## Architecture

```
gentleman-agent-gh/
├── .agents/skills/          # 96 skills + _shared (canonical, git-tracked)
│   ├── quality-gate/
│   ├── code-review-agent/
│   └── .../
├── skills/                  # Junctions workspace (git-ignored)
├── scripts/                 # 136 top-level scripts (129 PowerShell + 7 shell)
│   └── smoke/               # Smoke tests
├── docs/                    # Documentation
│   ├── metricas/            # Session metrics
│   ├── ciclos/              # Self-improvement cycle reports
│   ├── audits/              # External audit reports
│   ├── errors/              # Error analysis reports
│   ├── architecture/        # Architecture decisions & analysis
│   ├── operations/          # Quality standard, runbooks
│   ├── CHANGELOG.md         # Release history
│   ├── CONTRIBUTING.md      # How to contribute
│   └── ...
├── .learnings/              # Session mining + bias calibration
├── .project.json            # Auto-scored project state
├── AGENTS.md                # Full agent protocol (~350 lines)
├── CYCLE.md                 # Self-improvement cycle manifest
├── ANTI-PATTERN-CATALOG.md  # 23 immunized patterns
├── SKILLS-INDEX.md          # Skill registry with triggers
└── review-rules.jsonc       # Zone-based verification policy
```

---

## Conventions

- **Commits**: Conventional Commits (`fix(scripts):`, `feat(cycle7):`, `docs(readme):`, etc.)
- **TDD**: Test-first, code-after
- **Memory**: Engram persistent memory with MCP protocol
- **Verification**: Triple verify (E1/E2/E3) before `!ship`
- **Anti-patterns**: Catalog with 23 immunized patterns
- **Auto-metrics**: Post-task self-evaluation in 7 dimensions with bias calibration

---

## Quick Reference

### Typical flow

```
1. gentleman-vmk               ← open agent
2. "do X"                      ← ask for task
3. agent resolves alone        ← trivial changes = no ceremony
4. !score                      ← optional: measure result
5. !close                      ← close session
```

### Tips

- **Ponytail `lite`** = default. Only checks if something is necessary before coding.
- **Ponytail `full`** = for complex changes. Activates more quality gates.
- **You don't need** to remember everything — the agent knows when to apply each thing.
- **Questions**: `!health` for diagnostics, `!manifest` to see current cycle.

### Main shortcuts

> **Full reference**: [SHORTCUTS.md](SHORTCUTS.md)

| Shortcut | Action |
|----------|--------|
| `!score` | Score-auto + docs update + cross-ref |
| `!health` | Git status, drift, cross-ref, score |
| `!close` | Unified close pipeline |
| `!analisis` | Deep multi-agent analysis |

---

## Based on

- Karpathy Method (minimal prompts, recursive compression)
- SPEAR Framework (prompt engineering)
- Staff+ Engineer Competencies (2026)
- SkillsBench Benchmark
- Engram Persistent Memory (Go + SQLite + FTS5)
- Hermes Agent (SkillForge + Curator + SkillInjector)
