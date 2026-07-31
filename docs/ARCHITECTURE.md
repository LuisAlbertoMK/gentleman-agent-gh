# Architecture — Gentleman Agent

**System design, module boundaries, and data flow.**

---

## System Overview

Gentleman Agent is a **multi-agent AI development team** for OpenCode. It provides 24 specialized agents, 79 skills, and 123 PowerShell scripts that work together to deliver verified, high-quality code changes.

### Core Principles

1. **Builder ≠ Evaluator** — the agent that writes code never verifies it
2. **Subagent-First** — main context = synthesis only, never reads >3 files raw
3. **Zone-Based Risk** — ceremony scales with diff risk (trivial → full pipeline)
4. **Persistent Memory** — Engram survives across sessions and compactions
5. **Self-Improvement** — capture → extract → evaluate → apply loop

---

## Component Map

```
┌─────────────────────────────────────────────────────────────────────┐
│                         OpenCode Runtime                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ gentleman-vMK│  │ 12 Specialist│  │ 9 SDD Pipeline│             │
│  │  (Orchestr.) │  │   Agents     │  │   Agents      │             │
│  └──────┬───────┘  └──────┬───────┘  └──────┬────────┘             │
│         │                 │                  │                      │
│  ┌──────▼─────────────────▼──────────────────▼────────┐            │
│  │              opencode.json (Permissions)            │            │
│  │   bash: deny[17] | edit: allow | write: allow      │            │
│  └─────────────────────┬──────────────────────────────┘            │
│                        │                                            │
│  ┌─────────────────────▼──────────────────────────────┐            │
│  │              AGENTS.md + PROTOCOL.md                │            │
│  │   Persona | Rules | Workflow | Subagent-First       │            │
│  └─────────────────────┬──────────────────────────────┘            │
└────────────────────────┼────────────────────────────────────────────┘
                         │
    ┌────────────────────┼────────────────────┐
    │                    │                    │
    ▼                    ▼                    ▼
┌─────────┐      ┌─────────────┐      ┌───────────┐
│ Skills   │      │   Scripts   │      │  Memory   │
│ (79 +    │      │  (91+ PS1)  │      │  (Engram) │
│  _shared)│      │             │      │           │
└────┬─────┘      └──────┬──────┘      └─────┬─────┘
     │                   │                   │
     │    ┌──────────────┼──────────────┐    │
     │    │              │              │    │
     ▼    ▼              ▼              ▼    ▼
┌────────────────┐ ┌──────────┐ ┌────────────────┐
│  Skill Graph   │ │ Scoring  │ │   Session      │
│  (Resolution)  │ │ (13 dim) │ │   Lifecycle    │
└────────────────┘ └──────────┘ └────────────────┘
```

---

## Module Map

### 1. Agent Layer (`opencode.json`)

| Module | Count | Purpose |
|--------|-------|---------|
| Orchestrator | 1 | `gentleman-vMK` — Senior Architect mentor |
| Specialists | 12 | Security, SEO, Infra, Frontend, Performance, DataScience, Docs, Implementer, Deep, Codex, Quick |
| SDD Pipeline | 9 | Init → Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive |

**Permissions**: Global bash deny (17 dangerous commands), edit/write allow for specialists, granular per-agent overrides.

### 2. Skill Layer (`.agents/skills/`)

79 skills + `_shared` references. Organized by domain:

| Domain | Skills | Examples |
|--------|--------|----------|
| Verification | 6 | triple-verify, adversarial-breaker, judgment-day, external-auditor |
| Analysis | 4 | analysis-mode, gap-analysis, research, project-mapper |
| Code Quality | 8 | code-review-agent, best-practices, security-scanner, quality-gate |
| UI/Frontend | 5 | baseline-ui, ui-engine, accessibility, visual-testing, performance |
| SDD Pipeline | 10 | sdd-init through sdd-archive, sdd-quick |
| Workflow | 8 | ralph-loop, delivery-harness, session-resume, commit-crafter |
| Memory | 3 | engram-protocol, dreaming, cross-project-wisdom |
| Meta | 6 | opencode-skill-creator, skill-improver, skill-graph, skill-testing |

**Resolution**: `skill-graph.ps1` (full BFS) or `skill-resolver-fast.ps1` (keyword scoring).

### 3. Script Layer (`scripts/`)

123 PowerShell scripts organized by function:

| Category | Scripts | Key Files |
|----------|---------|-----------|
| Scoring | 3 | `score-auto.ps1`, `lib/score-dims.ps1`, `restore-project-score.ps1` |
| Quality Gate | 5 | `quality-gate`, `pssa-gate`, `cross-ref-check`, `capture-errors`, `verify` |
| Session | 4 | `close-session`, `inter-track`, `session-miner`, `health-check` |
| Skills | 8 | `skill-graph`, `skill-resolver-fast`, `skill-validate`, `check-skill-drift` |
| Sync | 5 | `sync-all`, `sync-vmk`, `pull-upstream`, `backup`, `restore` |
| Learning | 6 | `wisdom-store`, `wisdom-loader`, `wisdom-forge`, `run-dreaming` |
| Setup | 3 | `setup-machine.ps1/.sh`, `setup-install.ps1`/`install.sh`, `global-setup` |
| Analysis | 5 | `pipeline-analyze`, `project-profile`, `trend`, `token-count` |

### 4. Memory Layer (Engram)

| Component | Purpose |
|-----------|---------|
| `mem_save` | Persist decisions, bugs, discoveries |
| `mem_search` | Full-text search across sessions |
| `mem_context` | Recent session history |
| `mem_session_summary` | End-of-session snapshot |
| `mem_review` | Lifecycle management (active → needs_review) |

### 5. Prompt Layer (`prompts/`)

| Directory | Purpose |
|-----------|---------|
| `shared/` | `_core-behavior.md`, `_analyze-only-protocol.md` |
| `sdd/` | 10 SDD phase prompts (init through archive) |
| `gentleman-implementer.md` | Plan executor prompt |

---

## Data Flow

### Task Execution Flow

```
User Request
    │
    ▼
┌─────────────────┐
│ Pre-Flight Gate  │ ← PROTOCOL.md (YAGNI, stdlib, native, dep)
│ (Ponytail Ladder)│
└────────┬────────┘
         │
    ┌────▼────┐
    │ Router  │ ← opencode-model-router skill
    └────┬────┘
         │
    ┌────▼────────────────────────────┐
    │ Delegate to Specialist Agent    │
    │ (or main context if SIMPLE)     │
    └────┬────────────────────────────┘
         │
    ┌────▼────────┐
    │ Execute     │ ← quality-gate + triple-verify
    └────┬────────┘
         │
    ┌────▼────────┐
    │ Verify      │ ← Builder ≠ Evaluator
    └────┬────────┘
         │
    ┌────▼────────┐
    │ Commit      │ ← commit-crafter + secrets scan
    └────┬────────┘
         │
    ┌────▼────────┐
    │ Learn       │ ← Engram mem_save
    └─────────────┘
```

### Scoring Flow

```
score-auto.ps1
    │
    ├─→ .learnings/score-cache.json (git-HEAD based hash)
    │
    ├─→ lib/score-dims.ps1 (13 dimensions, 42 sub-dims)
    │       ├─→ PA: Project Artifacts
    │       ├─→ Sec: Security
    │       ├─→ DC: Dead Code
    │       ├─→ CC: Clean Code
    │       ├─→ BP: Best Practices
    │       ├─→ Or: Orthography
    │       ├─→ Bi: Bitacora
    │       ├─→ Me: Metrics
    │       ├─→ SP: Script Performance
    │       ├─→ SE: Skill Effectiveness
    │       ├─→ CA: Cycle Activity
    │       ├─→ BI2: Backlog Integrity
    │       └─→ SD: Score Depth (42 sub-dims)
    │
    ├─→ .project.json (single source of truth, skip-worktree)
    │
    └─→ .learnings/bias-calibration.json (self-assessment correction)
```

### Quality Gate Flow

```
quality-gate.yml (CI)
    │
    ├─→ PSSA (PowerShell static analysis)
    ├─→ Cross-ref check (docs ↔ code consistency)
    ├─→ Backlog integrity (CYCLE.md validation)
    ├─→ Secrets scan (gitleaks)
    └─→ Test execution (Pester)
```

---

## Risk Zones

Defined in `review-rules.jsonc`. Auto-detected from diff:

| Zone | Pattern | Ceremony |
|------|---------|----------|
| **ROJA** | src/, scripts/, auth, storage, API, schema | Full triple-verify (E1+E2+E3) |
| **AMARILLA** | 3-8 files, config changes | Quality gate + security |
| **VERDE** | 1-2 files, docs, comments | Minimal (commit + secrets scan) |

---

## Key Patterns

### Subagent-First

```
Main Context: "I need to analyze 10 files"
    │
    ├─→ Delegate: explore agent (reads 10 files)
    │       │
    │       └─→ Returns: summary (2-3K tokens)
    │
    └─→ Main: synthesize, decide, instruct
```

**Savings**: 5-15K tokens per delegation.

### Builder ≠ Evaluator

```
Agent A: writes code → claims "done"
    │
    └─→ Agent B (breaker): adversarial verification
            │
            └─→ Verdict: APPROVED / FIX / BLOCK
```

### Learning Loop

```
Fix applied
    │
    ├─→ Engram: mem_save (decision, bugfix, discovery)
    │
    ├─→ Anti-Pattern Catalog: check for repeats
    │
    └─→ Cross-Project Wisdom: share patterns across repos
```

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Runtime | OpenCode (AI agent framework) |
| Language | PowerShell 7.6+ (scripts), JavaScript/Node.js (analysis) |
| Memory | Engram MCP (persistent across sessions) |
| CI/CD | GitHub Actions (quality-gate.yml, release.yml) |
| Version Control | Git with skip-worktree for computed files |
| Testing | Pester (PowerShell), custom verification scripts |
| Analysis | BM25/FTS5 (context-mode), keyword scoring |

---

## File Structure

```
gentleman-agent-gh/
├── .agents/skills/          # 79 skills + _shared
├── .github/workflows/       # CI/CD (quality-gate, release)
├── docs/
│   ├── ARCHITECTURE.md      # This file
│   ├── CHANGELOG.md         # Release notes
│   ├── ciclos/              # Cycle archives
│   ├── metricas/            # Metrics and errors
│   └── operations/          # Quality standards
├── prompts/
│   ├── shared/              # Shared prompt components
│   ├── sdd/                 # SDD phase prompts
│   └── gentleman-implementer.md
├── scripts/
│   ├── lib/                 # Shared libraries (score-dims.ps1)
│   ├── tests/               # Pester tests
│   └── *.ps1                # 123 operational scripts
├── AGENTS.md                # Persona + project rules
├── PROTOCOL.md              # Operational workflows
├── opencode.json            # Agent definitions + permissions
├── review-rules.jsonc       # Zone configuration
└── .project.json            # Computed scores (skip-worktree)
```

---

*Architecture version: 1.0 — Project: gentleman-agent-gh*
