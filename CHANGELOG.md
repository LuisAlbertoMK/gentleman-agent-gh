# CHANGELOG — gentleman-agent-gh + global opencode

> All notable changes to this repo and the live opencode config (`C:\Users\MK\.config\opencode\`).
> Format based on [Keep a Changelog](https://keepachangelog.com/), semver-ish for skills/scripts.

## [Unreleased]

### Sprint 2 (2026-06-07) — Global opencode optimization

#### Global opencode (live, not in repo)

- **AGENTS.md** — `agent-version: 1.1 → 1.3`
  - Char count: 10227 → 6106 (-40.3%)
  - Line count: 207 → 91 (-56.0%)
  - Content lost: ~3-5% (within 5% budget)
  - Added: `Subagent-First` rule, `Bash-Safe` rule
  - Preserved: MISION PRINCIPAL, 7 critical rules, 15 top skills, full Skill Router, Engram Protocol

- **commands/sdd-apply.md** — `version: 1.0 (NEW)`
  - Char count: 2571 → 2081 (-19.1%)
  - Line count: 45 → 32 (-28.9%)
  - Combined STEP A + STEP A2 redundancy (apply-progress search unified)
  - Condensed STEP B with pipe syntax (3 mem_get_observation on 1 line)

- **skills/judgment-day/SKILL.md** — `version: 1.6 → 1.7`
  - Line count: 101 → 66 (-34.7%)
  - Char count: 4084 → 2818 (-31.0%)
  - Removed redundant Decision Tree (overlap with P1-P5)
  - Condensed Rules section

- **skills/metricas/SKILL.md** — `version: 1.1 → 1.2`
  - Line count: 85 → 57 (-32.9%)
  - Char count: 3213 → 2761 (-14.1%)
  - Removed duplicate Anti-patterns table (overlap with Rules)

- **skills/project-mapper/SKILL.md** — `version: 1.0 → 1.1`
  - Line count: 79 → 50 (-36.7%)
  - Char count: 2406 → 2043 (-15.1%)
  - Condensed Output format example to template

- **skills/immune-system/SKILL.md** — `version: 1.0 → 1.1`
  - Line count: 72 → 55 (-23.6%)
  - Char count: 2567 → 2293 (-10.7%)
  - Inlined Immunity Levels table
  - Removed duplicate Anti-patterns section

#### Repo (versioned, committed, pushed)

- **AGENTS.md** — `agent-version: 1.2 → 1.3`
  - Aligned "auto-score 4 dims" → "6 dims" (matches auto-metrics skill)
  - Added MISIÓN PRINCIPAL rule
  - Added Subagent-First + Bash-Safe sections
  - Char count: 5655 → 6230 (+10.2%, NEW content valuable)

- **SKILLS-INDEX.md** — `version: 1.0 (NEW)`
  - Char count: 4281 → 4089 (-4.5%)
  - Line count: 82 → 75 (-8.5%)
  - Removed redundant Quick reference section
  - Compressed Load rule

- **scripts/bash-safe.ps1** — `version: 1.0.0 (NEW)`
  - Bash executor for PowerShell 5.1 environments
  - Invoke-Bash function with CaptureOutput switch
  - Test-BashSafe: 6/6 PASS (and-or, or, at-u, redirect, pipeline+grep, git)
  - Locates Git Bash at `C:\Program Files\Git\bin\bash.exe` (WSL bash is broken stub)

- **.metricas/bookmark.json** — `version: 1 (NEW)`
  - Tracks pre/post state of optimization sprints
  - Pre: global AGENTS 10227, ANTI-PATTERN 4682, SKILLS-INDEX 4281
  - Post: global AGENTS 6106 (-40%), ANTI-PATTERN 4682 (preserved), SKILLS-INDEX 4089 (-4.5%)

- **BITACORA.md** — chronological log updated with sprint 2 entry

#### Preserved (intentionally not modified)

- `ANTI-PATTERN-CATALOG.md` (4682 chars, 77 lines) — Each entry is permanent immunity. 5% loss budget = 234 chars, below useful compression threshold.
- `opencode.json` (16059 chars, 203 lines) — Permissions, MCP config, agent defs are load-bearing. Inline sdd-orchestrator prompt (6K+ chars) not safely compressible in scope.
- 5 skills 52-78 lines (security-scanner, skill-creator, session-resume, quality-gate, auto-metrics) — Already at 5% loss floor. SKIP was the right call.
- `tui.json`, `package.json`, `.gitignore` (in global) — Already minimal.

### Quality gates

- bash-safe self-test: **6/6 PASS** (verified post-edit, post-commit, post-push)
- Max content loss observed: **4.5%** (SKILLS-INDEX), within 5% budget
- MISION PRINCIPAL + 7 critical rules + 15 top skills + Skill Router + Engram Protocol: all preserved
- Conventional commits, no AI attribution

### Metrics (cumulative)

- **Total chars saved**: ~7,000 (sprint 1 + sprint 2)
- **Total tokens saved in context**: ~2,000 (at 3.5 chars/token)
- **Commits pushed**: 3 (`83f40e7`, `e18e0af`, `b8ea4a8`)
- **Files globally touched**: 7
- **Files in repo touched**: 6

---

## [Earlier] (2026-05-26 to 2026-06-06)

See `BITACORA.md` for chronological history. Major prior milestones:
- 2026-05-26: Karpathy compression + anti-patterns framework
- 2026-05-28: Quality gate + pre-commit + security
- 2026-05-30: SDD cycle completo con subagentes
- 2026-06-03: Karpathy loop 60 iteraciones + automejora agente
- 2026-06-06: Skill metricas + tokenización + 6 tools nuevas
- 2026-06-06: Misión principal registrada + bitacora + autoscore 9.2/10
- 2026-06-06: session-resume comprimido (97→69 lines, -30%) + auto-clean.ps1
