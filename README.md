# Gentleman Agent — OpenCode AI Agent Skills & Scripts

## What is this?

**Gentleman Agent** is an **AI software development team** for OpenCode. Instead of a single chatbot, you get 22 specialized agents working together:

- 🏗️ **Lead Architect** — Senior Architect mentor solving complex tasks
- 🔒 **Specialists** — Security, performance, frontend, etc. consultants (FREE TIER)
- 🧠 **Persistent memory** — the agent remembers across sessions
- ✅ **Auto-verification** — triple check before any change

**In one line**: You ask for a task → the agent resolves it with its team → verifies it works → documents what it learned.

**Start here**: [QUICKSTART.md](QUICKSTART.md) (5 steps, 5 minutes)

---

Suite of **79 skills** (+ `_shared`) + **91 PowerShell scripts** for [OpenCode](https://github.com/sst/opencode). Designed for software development with clean architecture, TDD, and multi-layer verification.

> **Repo**: `LuisAlbertoMK/gentleman-agent-gh`
> **Score**: 9.1/10 (13 dimensions)
> **Skills**: 79 (+ `_shared`)
> **Cycle**: 27 completed (Audit Cleanup & Enrichment)

---

## Features

### Multi-Agent Architecture
22 agents total: main orchestrator (`gentleman-vMK`) + 12 specialists + 9 SDD pipeline agents:

| Agent | Model | Specialty |
|-------|-------|-----------|
| `gentleman-vMK` | default | Senior Architect mentor — main orchestrator |
| `gentleman-deep` | nemotron-3-ultra-free | Architecture, design, complex code |
| `gentleman-codex` | deepseek-v4-flash-free | Code generation, boilerplate |
| `gentleman-quick` | mimo-v2.5-free | Fast tasks, review, simple edits |
| `gentleman-security` | nemotron-3-ultra-free | Vulnerability analysis, secure code (FREE TIER) |
| `gentleman-seo` | nemotron-3-super-free | SEO, GEO, keyword analysis (FREE TIER) |
| `gentleman-infra` | deepseek-v4-flash-free | IaC, Kubernetes, CI/CD (FREE TIER) |
| `gentleman-frontend` | kimi-k2.5-free | React, Tailwind, accessibility (FREE TIER) |
| `gentleman-performance` | nemotron-3-ultra-free | Code optimization, bottlenecks (FREE TIER) |
| `gentleman-datascience` | mimo-v2.5-free | Pandas, SQL, stats (FREE TIER) |
| `gentleman-docs` | big-pickle | Technical writing, docs (FREE TIER) |
| `gentleman-implementer` | deepseek-v4-flash-free | Plan executor (FREE TIER) |
| `sdd-orchestrator` | claude-sonnet-4-6 | SDD pipeline orchestration |

#### SDD Pipeline Agents (subagents)
9 agents executing SDD pipeline phases. **Inherit orchestrator model** (`claude-sonnet-4-6`, paid) unless they have explicit `model` in `opencode.json`. All have full permissions (`bash: allow, edit: allow, write: allow`).

| Agent | Phase | Model | Description |
|-------|-------|-------|-------------|
| `sdd-init` | Init | inherits orchestrator | Bootstrap SDD context and project configuration |
| `sdd-explore` | Explore | inherits orchestrator | Investigate codebase and think through ideas |
| `sdd-propose` | Propose | inherits orchestrator | Create change proposals from explorations |
| `sdd-spec` | Spec | inherits orchestrator | Write detailed specifications from proposals |
| `sdd-design` | Design | inherits orchestrator | Create technical design from proposals |
| `sdd-tasks` | Tasks | inherits orchestrator | Break down specs and designs into implementation tasks |
| `sdd-apply` | Apply | inherits orchestrator | Implement code changes from task definitions |
| `sdd-verify` | Verify | inherits orchestrator | Validate implementation against specs |
| `sdd-archive` | Archive | inherits orchestrator | Archive completed change artifacts |

> **Cost**: `sdd-orchestrator` + 9 sub-agents = 10 agents using `claude-sonnet-4-6`. This is intentional — SDD pipeline is high-risk and benefits from a capable model. To reduce cost, add `"model": "opencode/nemotron-3-ultra-free"` to individual SDD agents in `opencode.json`.

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
8 complete phases: `init → propose → spec → design → tasks → apply → verify → archive`

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

| Category | Skills |
|----------|--------|
| **Compression** | karpathy-loop, lean-context |
| **Quality** | quality-gate, auto-metrics, external-auditor, immune-system, triple-verify |
| **Code Review** | code-review-agent, judgment-day |
| **Memory** | session-resume, dreaming, bitacora |
| **Skills Meta** | opencode-skill-creator, skill-registry, skill-improver, skill-graph |
| **SDD** | sdd (unified pipeline — phases consolidated) |
| **Engineering** | senior-engineer, refactoring-planner, project-mapper |
| **Security** | security-scanner, auth-hardening, container-security, llm-security |
| **UI/Web** | baseline-ui, accessibility, performance, seo, web-quality-audit, best-practices, ui-engine |
| **PR/Workflow** | commit-crafter, work-unit-commits, branch-pr, chained-pr |
| **Orchestration** | delivery-harness, subagent-isolation, command-wrapper, opencode-model-router |
| **Decisions** | cognitive-doc-design |
| **Docs** | bitacora, comment-writer |
| **Research** | research, prompt-engineering |
| **Self-Improvement** | self-improvement (merged self-reflection) |
| **DevOps** | ci-cd |
| **Testing** | skill-testing, e2e-testing, visual-testing |
| **Others** | recovery-protocol, context-watchdog, performance-tracker, metricas, issue-creation, development-mode, execution-mode |

**Total: 79 skills + `_shared`** — all with SKILL.md, YAML frontmatter, versioning, changelog, and Apache-2.0 license.

---

## Scripts (91+ in scripts/)

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

---

## Architecture

```
gentleman-agent-gh/
├── .agents/skills/          # 79 skills + _shared (canonical, git-tracked)
│   ├── quality-gate/
│   ├── code-review-agent/
│   └── .../
├── skills/                  # Junctions workspace (git-ignored)
├── scripts/                 # 91+ PowerShell scripts
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
