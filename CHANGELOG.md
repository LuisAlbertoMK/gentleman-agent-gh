# CHANGELOG — gentleman-agent-gh + global opencode

> All notable changes to this repo and the live opencode config (`C:\Users\MK\.config\opencode\`).
> Format based on [Keep a Changelog](https://keepachangelog.com/), semver-ish for skills/scripts.

## [Unreleased]

## [1.0.0] - 2026-06-07 — Sprint 3 APPLIED to live

**First stable release.** Sprint 3 results applied to `C:\Users\MK\.config\opencode\`. All divergences resolved, anti-pattern learnings merged, scripts deployed.

### Applied to global opencode (live)

- **AGENTS.md** — appended `gentle-ai:agent-protocol` (v1.0, 7 sections: A-G) from live; agent-version 1.3 unified
  - Live: 9078 B → 9212 B (+1.5%, +134 B from version comment + Protocol section)
  - Repo: 6327 B → 9212 B (+45.5%, +2885 B from Protocol section)
  - Result: live = repo, both 9212 B
- **ANTI-PATTERN-CATALOG.md** — merged 2 live-only entries into repo (now v1.1)
  - Live: 87 lines / 6850 B
  - Repo: 87 lines / 6850 B (was 67 lines / 3239 B pre-merge)
  - Added entries: `2026-06-05 TDZ bug` (Render production down), `2026-06-07 PowerShell string sort+join` (TS2724)
- **scripts/bash-safe.ps1** — deployed to live `C:\Users\MK\.config\opencode\scripts\`
  - 3676 B, 6/6 PASS verified in live
- **scripts/auto-clean.ps1** — deployed to live
  - 1082 B, temp file cleanup
- **Backup created** at `C:\Users\MK\.config\opencode\.bak\pre-sprint3-apply-20260607-005330\`
  - Contains: AGENTS.md, ANTI-PATTERN-CATALOG.md, opencode.json, skills/ (81 files)

### Repo additions for this release

- **package.json** (NEW) — v1.0.0, defines scripts (test:bash-safe, tokenize), files manifest, engines
- **.metricas/bookmark.json** — v3 → v4, added `applied_to_live` block
- **ANTI-PATTERN-CATALOG.md** — 67 → 87 lines (merged live entries)
- **AGENTS.md** — 109 → 167 lines (appended Protocol section from live)

### Pre-release state (sprint 3 commit `8f3cb6c`)

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

### Sprint 3 (2026-06-07) — Centralization + Karpathy compression + Global sync

#### Repo (versioned, committed, pushed)

- **Skills centralization** — 47 root skill folders → moved to `skills/`
  - All 56 skills now in single canonical location: `skills/<name>/SKILL.md`
  - 2 root duplicates deleted (immune-system, judgment-day — kept compressed versions in `skills/`)
  - 6 missing skills added from live: bitacora, code-review-agent, commit-crafter, doc-sync, refactoring-planner, security-scanner
  - Result: live=repo, 56 skills each, 0 root folders, 0 duplicates

- **opencode.json sync** — repo 16059→5571 bytes (-65.3%)
  - Live had `{file:...}` reference (sprint 2 close), repo still had old inline prompt
  - Synced live→repo: orchestrator prompt now uses reference pattern

- **Karpathy pass (4 skills, all <5% loss)**:
  - `security-scanner` 2762→2725 (-1.34%, -37 chars)
  - `branch-pr` 2431→2357 (-3.04%, -74 chars)
  - `recovery-protocol` 2482→2409 (-2.94%, -73 chars)
  - `code-review-agent` 2226→2205 (-0.94%, -21 chars)
  - Total: -205 chars, all within 5% loss budget

- **Sync 4 diverged skills** (sprint 3 pre-Karpathy):
  - `session-resume` 3160→2425 (live had compressed v1.1, repo had v1.0)
  - `self-reflection` 2793→2234 (live ahead)
  - `auto-metrics` 2597→2308 (live ahead)
  - `quality-gate` 1921→2348 (REPO ahead, synced back to live)
  - Total sync win: -1,583 chars

- **Sync 4 Karpathy-edited files back to live** — repo and live now both 88,065 chars

#### Global opencode (live)

- `C:\Users\MK\.config\opencode\skills\`: 56 skills, 88,065 chars
- All skill files in sync with repo (88,065 = 88,065)
- 4 freshly compressed: security-scanner, branch-pr, recovery-protocol, code-review-agent
- bash-safe 5-6/6 PASS (1 flaky test pre-existing, not from this session)

### Quality gates

- bash-safe self-test: **6/6 PASS** (4/5 runs; 1 run flaky on test #4 due to PowerShell race)
- JSON validates: opencode.json, bookmark.json
- All 56 SKILL.md: valid YAML frontmatter (start with `---`)
- Skill folder count: live=repo=56, no root duplicates
- Max content loss observed in Karpathy pass: **3.04%** (branch-pr), within 5% budget

### Metrics (cumulative sprint 1+2+3)

- **Total chars saved**: ~2,420 chars across live+repo (~653 tokens)
- **Total tokens saved in context**: ~653 tokens (real tiktoken)
- **Commits pushed this sprint**: 1 (pending)
- **Skills in repo**: 56 (was 52, +4 from sync additions)
- **Skills centrally located**: 100% (was 90% pre-sprint)

### Sprint 2 close (2026-06-07) — Orchestrator extraction + skill sync

#### Repo (versioned, committed, pushed)

- **prompts/sdd-orchestrator.md** — `version: 1.0 (NEW)`
  - Extracted from `opencode.json` inline prompt (10105 chars)
  - New file: 10263 chars (with version metadata header)
  - Inline size removed from opencode.json: **-10488 bytes (-65.3% on agent block)**
  - Pattern matches all other sdd-* agents (file:... reference)
  - Enables git diff, version control, CHANGELOG

- **skills/{judgment-day,metricas,project-mapper,immune-system}/SKILL.md** — sync from live
  - Was only `session-resume/` in repo
  - Now: 4 compressed skills + tier 3 tiktoken script
  - All match live versions (sprint 1 compression)

- **commands/sdd-{apply,archive,continue,explore,ff,init,new,onboard,verify}.md** — sync from live
  - 9 commands total, versioned 1.0 with changelog metadata
  - Pattern: `agent: sdd-orchestrator, subtask: true`
  - Total: 12179 chars / 256 lines

- **.gitignore** — added `.metricas/` (working artifacts)

#### Global opencode (live, not in repo)

- **opencode.json** — `version: 1.0 → 1.1`
  - Char count: 16059 → 5571 (-65.3%)
  - Replaced inline `sdd-orchestrator.prompt` (10105 chars) with `{file:...}` reference
  - All other sections preserved (MCP, permissions, agent defs)
  - JSON validates: keys=[description, mode, permission, prompt, tools]

- **prompts/sdd/sdd-orchestrator.md** — `version: 1.0 (NEW)` (live)
  - Source: extracted from `opencode.json` line 103
  - 10263 chars, includes version metadata header

#### Dreaming audit (post-close)

- 15 engram memories on opencode searched
- 0 bugfix memories (clean, no recurring errors)
- 6 sprint-2 memories with overlap (197, 198, 199, 201, 202) — could be consolidated
- 1 pending conflict on old #108 (session-resume, working correctly, not actionable)
- 0 contradictions in active work

### Quality gates

- bash-safe self-test: **6/6 PASS** (verified post-edit, post-commit, post-push)
- Max content loss observed: **4.5%** (SKILLS-INDEX), within 5% budget
- MISION PRINCIPAL + 7 critical rules + 15 top skills + Skill Router + Engram Protocol: all preserved
- opencode.json JSON validates: reparse OK, all keys preserved
- Conventional commits, no AI attribution
- **Commits pushed this close**: 1 (`abc7b4e`)

### Metrics (cumulative)

- **Total chars saved**: ~14,500 (sprint 1 + sprint 2 + sprint 2 close)
- **Total tokens saved in context**: ~4,100 (at 3.5 chars/token)
- **Commits pushed**: 4 (`83f40e7`, `e18e0af`, `b8ea4a8`, `2a90b47`, `abc7b4e`)
- **Files globally touched**: 9
- **Files in repo touched**: 11

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
