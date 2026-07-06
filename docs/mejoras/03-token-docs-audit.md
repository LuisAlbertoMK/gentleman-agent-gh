# Token & Documentation Optimization Audit

> Generated: 2026-07-05 | Agent: gentleman-docs (MiMo V2.5 Pro)
> Scope: AGENTS.md, 70 skills, opencode.json (12 agents), ANTI-PATTERN-CATALOG.md, skill-graph.ps1

---

## Executive Summary

| Metric | Current | Target | Savings |
|--------|---------|--------|---------|
| AGENTS.md (global + local) | 7,288 tok | 3,800 tok | **3,488 tok** |
| Agent prompts (opencode.json) | 6,716 tok | 3,800 tok | **2,916 tok** |
| Skills (70 total) | 33,164 tok | 26,000 tok | **7,164 tok** |
| ANTI-PATTERN-CATALOG | 2,244 tok | 600 tok | **1,644 tok** |
| **TOTAL STATIC** | **49,412 tok** | **34,200 tok** | **15,212 tok (31%)** |

Per-session impact (typical session loads AGENTS.md x2 + 4-8 skills + catalog):
- **Current per-session**: ~12,000-16,000 tokens of static overhead
- **After optimization**: ~7,000-9,000 tokens
- **Per-session savings**: ~5,000-7,000 tokens

---

## AGENTS.md Section Analysis

Both global (`~/.config/opencode/AGENTS.md`) and local (`project/AGENTS.md`) are loaded every session. They share **18/18 identical section headers** with near-identical content. This is the #1 source of waste.

### Section-by-Section Breakdown

| # | Section | Tokens | Lazy-load? | Rationale |
|---|---------|--------|------------|-----------|
| 1 | Rules | ~120 | NO | Core behavioral contract — always needed |
| 2 | Personality | ~50 | NO | Identity — 2 lines, negligible |
| 3 | Pre-Flight Gate (Ponytail Ladder) | ~350 | **YES** | 9-step ladder only needed for COMPLEX tasks. Lite mode uses rungs 0-3 only |
| 4 | Ponytail Mode | ~150 | **YES** | Sub-section of Pre-Flight. Only needed when user invokes `!ponytail` |
| 5 | TRIANGULATE | ~180 | **YES** | Already delegated to `triple-verify` skill. AGENTS.md mention is redundant |
| 6 | Workflow Shortcuts (table) | ~350 | **YES** | 15 shortcuts — only relevant ones needed per task. Move to skill-graph resolution |
| 7 | Analysis Mode (`!analisis`) | ~200 | **YES** | Rare trigger — load only when `!analisis` detected |
| 8 | Subagent-First | ~30 | NO | 1 line, critical rule |
| 9 | Learning Loop | ~50 | NO | 2 lines, critical rule |
| 10 | Default-FAIL | ~80 | NO | Core behavioral contract |
| 11 | Python Environment | ~80 | **YES** | Only needed for Python tasks |
| 12 | Global Script Invocation | ~60 | NO | Small, needed for any script call |
| 13 | Bash-Safe (PS 5.1) | ~40 | NO | Small, critical for Windows |
| 14 | Execution & Resource-Adaptive Mode | ~150 | **YES** | Zona table — only needed when context fills. Already in `context-watchdog` skill |
| 15 | Risk-Adaptive Ceremony Zones | ~120 | **YES** | Diff-based detection — only needed at commit time. Already in `quality-gate` skill |
| 16 | Language, Tone & Scope | ~100 | NO | Identity — always needed |
| 17 | Skills (Auto-load) + Skill Router | ~350 | PARTIAL | Top 15 list is useful. Full fallback router (200 tok) → move to skill-graph.ps1 |
| 18 | Project Context | ~80 | NO | Small, always needed |
| 19 | Engram Protocol | ~350 | PARTIAL | Core rules (save/search/close) = NO. Dreaming/Auto-clean details = YES |
| 20 | Agent Protocol (A-L) | ~1,100 | PARTIAL | A (skill combo table) + D (security) + J (health check) = NO. B (token budget) + C (persistence) + E-H (workflow) + I (self-improvement) + K-L = **YES** — already in respective skills |
| 21 | Delegation Rules | ~80 | NO | Small, critical for multi-agent |

### Key Finding: Global/Local Duplication

Both files contain the same 3 blocks (`gentle-ai:persona`, `gentle-ai:engram-protocol`, `gentle-ai:agent-protocol`). The global file is the **superset** — the local file adds project-specific context only.

**Recommendation**: Local AGENTS.md should contain ONLY project-specific overrides (Project Context section). All shared content should live in global AGENTS.md only.

**Savings**: ~3,400 tokens per session (eliminating duplicate local load).

### Lazy-Load Candidates Summary

| Section | Tokens | Trigger for Loading |
|---------|--------|-------------------|
| Pre-Flight Gate (full) | ~350 | COMPLEX task detected |
| Ponytail Mode | ~150 | `!ponytail` invoked |
| TRIANGULATE | ~180 | `!ship`/`!check`/`!fast` |
| Workflow Shortcuts | ~350 | On-demand (resolve via skill-graph) |
| Analysis Mode | ~200 | `!analisis` as first token |
| Python Environment | ~80 | Python file detected |
| Execution Zones table | ~150 | Context >40% |
| Risk Ceremony Zones | ~120 | Commit/PR operation |
| Skill Router (full) | ~200 | Already in skill-graph.ps1 |
| Agent Protocol B-L | ~700 | Already in respective skills |
| **Total lazy-loadable** | **~2,480** | |

---

## Skill Token Inventory

### All 70 Skills by Size

| # | Skill | Bytes | Tokens | Category | Compression Potential |
|---|-------|-------|--------|----------|---------------------|
| 1 | opencode-model-router | 9,981 | 2,495 | coordination | **HIGH** — tables can be compressed 60% |
| 2 | branch-pr | 3,060 | 765 | coordination | MEDIUM |
| 3 | issue-creation | 2,857 | 714 | coordination | MEDIUM |
| 4 | triple-verify | 2,695 | 674 | quality | LOW (dense) |
| 5 | external-improvement | 2,587 | 647 | meta | MEDIUM |
| 6 | chained-pr | 2,522 | 630 | coordination | MEDIUM — merge with branch-pr |
| 7 | comment-writer | 2,488 | 622 | specialized | LOW |
| 8 | cognitive-doc-design | 2,462 | 616 | specialized | LOW |
| 9 | lean-context | 2,434 | 608 | compression | LOW (core skill) |
| 10 | best-practices | 2,400 | 600 | web-quality | MEDIUM — merge into web-quality-audit |
| 11 | sdd-onboard | 2,397 | 599 | SDD | LOW (one-time use) |
| 12 | delivery-harness | 2,373 | 593 | coordination | MEDIUM |
| 13 | gap-analysis | 2,344 | 586 | meta | LOW |
| 14 | development-mode | 2,338 | 584 | web-quality | LOW |
| 15 | performance-tracker | 2,301 | 575 | code-ops | MEDIUM |
| 16 | performance | 2,298 | 574 | web-quality | MEDIUM — merge into web-quality-audit |
| 17 | work-unit-commits | 2,274 | 568 | specialized | LOW |
| 18 | baseline-ui | 2,259 | 565 | web-quality | MEDIUM |
| 19 | seo | 2,244 | 561 | web-quality | MEDIUM — merge into web-quality-audit |
| 20 | web-quality-audit | 2,243 | 561 | web-quality | LOW (orchestrator) |
| 21 | skill-graph | 2,164 | 541 | meta | LOW |
| 22 | context-watchdog | 2,144 | 536 | specialized | LOW |
| 23 | decision-capture | 2,144 | 536 | memory | LOW |
| 24 | auto-metrics | 2,130 | 532 | quality | LOW |
| 25 | metricas | 2,127 | 532 | memory | MEDIUM — similar to auto-metrics |
| 26 | project-mapper | 2,072 | 518 | code-ops | LOW |
| 27 | skill-improver | 2,050 | 512 | meta | LOW |
| 28 | recovery-protocol | 2,020 | 505 | specialized | LOW |
| 29 | accessibility | 2,000 | 500 | web-quality | MEDIUM — merge into web-quality-audit |
| 30 | python-async | 1,995 | 499 | specialized | LOW |
| 31 | self-improvement | 1,992 | 498 | specialized | LOW |
| 32 | judgment-day | 1,987 | 497 | quality | LOW |
| 33 | go-testing | 1,965 | 491 | specialized | LOW |
| 34 | security-scanner | 1,894 | 474 | code-ops | LOW |
| 35 | command-wrapper | 1,893 | 473 | coordination | LOW |
| 36 | skill-testing | 1,885 | 471 | quality | LOW |
| 37 | external-auditor | 1,884 | 471 | quality | LOW |
| 38 | skill-creator | 1,860 | 465 | meta | LOW |
| 39 | immune-system | 1,858 | 464 | quality | LOW |
| 40 | quality-gate | 1,855 | 464 | quality | LOW |
| 41 | code-review-agent | 1,852 | 463 | quality | LOW |
| 42 | execution-mode | 1,839 | 460 | compression | LOW |
| 43 | session-resume | 1,837 | 459 | memory | LOW |
| 44 | karpathy-loop | 1,826 | 456 | compression | LOW |
| 45 | refactoring-planner | 1,761 | 440 | code-ops | LOW |
| 46 | subagent-isolation | 1,758 | 440 | coordination | LOW |
| 47 | bitacora | 1,685 | 421 | memory | LOW |
| 48 | skill-digestion | 1,685 | 421 | compression | LOW |
| 49 | ci-cd | 1,679 | 420 | specialized | LOW |
| 50 | research | 1,576 | 394 | research | LOW |
| 51 | dreaming | 1,537 | 384 | memory | LOW |
| 52 | skill-registry | 1,531 | 383 | meta | LOW |
| 53 | senior-engineer | 1,503 | 376 | specialized | LOW |
| 54 | commit-crafter | 1,431 | 358 | code-ops | LOW |
| 55 | code-memory | 1,415 | 354 | memory | LOW |
| 56 | sdd | 1,345 | 336 | SDD | LOW |
| 57 | prompt-engineering | 1,213 | 303 | specialized | LOW |
| 58 | doc-sync | 1,194 | 298 | code-ops | LOW |
| 59 | bias-calibration | 1,057 | 264 | quality | LOW |
| 60 | caveman | 801 | 200 | compression | **DELETE** — deprecated, use lean-context |
| 61-70 | SDD sub-skills (8) + _shared | ~4,400 | ~1,100 | SDD | Merge into parent |

### Frontmatter Overhead

| Metric | Value |
|--------|-------|
| Total frontmatter bytes | 24,274 |
| Total frontmatter tokens | **6,068** |
| Average per skill | 87 tokens |
| % of total skill tokens | **18.3%** |

Frontmatter includes: name, description, triggers, license, metadata (tags, author, version, changelog). The `changelog` and `license` fields are pure overhead at runtime.

### opencode-model-router Deep Dive (2,495 tokens — largest skill)

| Section | Tokens | Compression |
|---------|--------|-------------|
| Frontmatter | ~100 | Keep |
| Security Gate | ~60 | Keep (critical) |
| Specialized Agents table | ~200 | **Compress** — merge with routing table |
| Implementer section | ~180 | **Compress** — merge model notes into routing table |
| Routing Table v2 | ~400 | Keep but deduplicate with agent table |
| Delegation Pattern v2 | ~200 | **Remove** — duplicates routing table logic |
| Model Risk & Cost v2 | ~250 | **Compress** — combine with agent table |
| Fallback Chains v2 | ~150 | **Compress** — inline into routing table |
| Context → Action | ~50 | Keep |
| Available Models list | ~150 | **Remove** — stale data, belongs in docs/ |
| 90/10 Strategy | ~80 | Keep |
| **Current total** | **~2,495** | |
| **Compressed estimate** | **~1,000** | **Save ~1,500 tokens** |

---

## Agent Prompt Deduplication

### The Problem

`opencode.json` defines 12 primary agents + 11 SDD subagents. The primary agents contain massive duplicated boilerplate.

### Shared Fragments Analysis

#### Fragment A: "CRITICAL RULE — ANALYZE ONLY" (7 agents)

Used by: security, seo, infra, frontend, performance, datascience, docs

```
CRITICAL RULE — ANALYZE ONLY, DO NOT IMPLEMENT:
- You MUST NOT modify any files...
- You MUST save your plan in docs/agentes/{agent}-{task-name}/...
  - 00-resumen-ejecutivo.md...
  - 01-analisis-detallado/...
  - 02-plan-implementacion.md...
  - 03-evidencia/...
  - 04-metricas.md...
- Your plan must be detailed enough...
```

**Size**: ~244 tokens × 7 copies = **1,708 tokens** (waste: 1,464 tokens)

#### Fragment B: "CORE BEHAVIOR" — Analyze variant (7 agents)

```
CORE BEHAVIOR:
- 1 question -> STOP, exceptions: (a)...
- Autonomy zones — GREEN/YELLOW/ORANGE/RED...
- Pre-session: git status, check-skill-drift...
```

**Size**: ~100 tokens × 7 copies = **700 tokens** (waste: 600 tokens)

#### Fragment C: "CORE BEHAVIOR" — Exec variant (3 agents)

Used by: deep, quick, codex

```
CORE BEHAVIOR:
- 1 question -> STOP, exceptions: (a)...
- MEDIUM (1-file refactor): decompose -> parallel subagents -> merge.
- Autonomy zones — GREEN/YELLOW/ORANGE/RED...
- Post-task: auto-metrics >=9 + obvious improvement...
- Code changes -> auto external-auditor...
- Pre-session: git status, check-skill-drift...
```

**Size**: ~167 tokens × 3 copies = **501 tokens** (waste: 334 tokens)

#### Fragment D: Autonomy zones (ALL 10 agents)

```
Autonomy zones — GREEN: auto-execute safe actions. YELLOW: ask human (ctx>40%). ORANGE: escalate (ctx>60%). RED: inform only (ctx>80%).
```

Present in every agent prompt. Already defined in AGENTS.md §Execution & Resource-Adaptive Mode.

**Size**: ~35 tokens × 10 copies = **350 tokens** (waste: 315 tokens)

### Deduplication Summary

| Fragment | Tokens/Copy | Copies | Total | Waste |
|----------|-------------|--------|-------|-------|
| A: Analyze-only rule | 244 | 7 | 1,708 | 1,464 |
| B: Core behavior (analyze) | 100 | 7 | 700 | 600 |
| C: Core behavior (exec) | 167 | 3 | 501 | 334 |
| D: Autonomy zones | 35 | 10 | 350 | 315 |
| **TOTAL** | | | **3,259** | **2,713** |

### Recommended Solution

Create shared prompt fragments referenced by `{file:prompts/shared/...}`:

1. `prompts/shared/analyze-only.md` (~244 tokens) — referenced by 7 agents
2. `prompts/shared/core-behavior.md` (~100 tokens) — referenced by all 10 agents
3. Each agent keeps ONLY its unique intro (50-80 tokens) + `{file:...}` references

**Result**: 6,716 → ~3,800 tokens. **Savings: ~2,900 tokens**

---

## Skill Merge Candidates

### Cluster 1: Compression (5 → 2 skills)

| Current Skill | Tokens | Proposal |
|--------------|--------|----------|
| karpathy-loop | 456 | Keep as `compression` |
| lean-context | 608 | Keep as `compression` (merge karpathy into it) |
| caveman | 200 | **DELETE** (deprecated, use lean-context CAVEMAN level) |
| context-watchdog | 536 | Keep standalone (different trigger) |
| skill-digestion | 421 | Merge into lean-context as "on-load" section |

**Savings**: ~850 tokens (delete caveman + merge skill-digestion)

### Cluster 2: Web Quality (5 → 2 skills)

| Current Skill | Tokens | Proposal |
|--------------|--------|----------|
| web-quality-audit | 561 | Keep as orchestrator |
| accessibility | 500 | Move to `references/a11y.md`, load on-demand |
| performance | 574 | Move to `references/perf.md`, load on-demand |
| seo | 561 | Move to `references/seo.md`, load on-demand |
| best-practices | 600 | Move to `references/best-practices.md`, load on-demand |

**Savings**: ~1,600 tokens (4 sub-skills become reference files)

### Cluster 3: SDD Sub-skills (11 → 3 skills)

| Current | Tokens | Proposal |
|---------|--------|----------|
| sdd (parent) | 336 | Keep |
| sdd-init | 146 | Merge into sdd as "Phase 1" section |
| sdd-explore | 149 | Merge into sdd as "Phase 2" section |
| sdd-propose | 145 | Merge into sdd as "Phase 3" section |
| sdd-spec | 144 | Merge into sdd as "Phase 4" section |
| sdd-design | 147 | Merge into sdd as "Phase 5" section |
| sdd-tasks | 147 | Merge into sdd as "Phase 6" section |
| sdd-apply | 136 | Merge into sdd as "Phase 7" section |
| sdd-verify | 130 | Merge into sdd as "Phase 8" section |
| sdd-archive | 150 | Merge into sdd as "Phase 9" section |
| sdd-onboard | 599 | Keep standalone (one-time use, different audience) |

**Savings**: ~800 tokens (9 tiny skills → 1 skill with sections)

### Cluster 4: Git Workflow (3 → 1 skill)

| Current Skill | Tokens | Proposal |
|--------------|--------|----------|
| branch-pr | 765 | Merge into `git-workflow` |
| chained-pr | 630 | Merge into `git-workflow` |
| issue-creation | 714 | Merge into `git-workflow` |

**Savings**: ~800 tokens (3 skills → 1 with sections)

### Cluster 5: Skill Meta (4 → 1 skill)

| Current Skill | Tokens | Proposal |
|--------------|--------|----------|
| skill-creator | 465 | Merge into `skill-lifecycle` |
| skill-registry | 383 | Merge into `skill-lifecycle` |
| skill-improver | 512 | Merge into `skill-lifecycle` |
| skill-testing | 471 | Merge into `skill-lifecycle` |

**Savings**: ~700 tokens

### Cluster 6: Memory (4 → 2 skills)

| Current Skill | Tokens | Proposal |
|--------------|--------|----------|
| session-resume | 459 | Keep |
| code-memory | 354 | Merge into session-resume |
| dreaming | 384 | Keep |
| bitacora | 421 | Merge into dreaming (both are Engram-based) |

**Savings**: ~500 tokens

### Merge Summary

| Cluster | Before | After | Savings |
|---------|--------|-------|---------|
| Compression | 2,221 tok (5) | 1,370 tok (2) | 851 |
| Web Quality | 2,796 tok (5) | 1,200 tok (2) | 1,596 |
| SDD Sub-skills | 2,228 tok (11) | 1,400 tok (3) | 828 |
| Git Workflow | 2,109 tok (3) | 1,300 tok (1) | 809 |
| Skill Meta | 1,831 tok (4) | 1,100 tok (1) | 731 |
| Memory | 1,618 tok (4) | 1,100 tok (2) | 518 |
| **TOTAL** | **12,803 tok (32)** | **7,470 tok (11)** | **5,333** |

Plus opencode-model-router compression: **~1,500 tokens**

**Grand total skill savings: ~6,833 tokens**

---

## ANTI-PATTERN-CATALOG Optimization

### Current State

- **Size**: 8,976 bytes = 2,244 tokens
- **Load trigger**: Every session start (referenced as `{file:ANTI-PATTERN-CATALOG.md}`)
- **Content**: 23 entries in markdown table + 16-item prevention cheat sheet

### Problem

Most entries are domain-specific (PowerShell, SVG, regex) and irrelevant to any given session. Loading all 23 entries + cheat sheet costs 2,244 tokens every session.

### Lazy-Load Strategy

| Layer | Content | Tokens | When Loaded |
|-------|---------|--------|-------------|
| **L0: Always loaded** | Prevention cheat sheet (16 rules, 1-line each) | ~500 | Session start |
| **L1: On trigger** | Full table entries matching current task category | ~200-400 | immune-system skill triggers |
| **L2: On demand** | Full detail docs in `docs/anti-patterns/` | Variable | Explicit lookup |

### Implementation

1. Split ANTI-PATTERN-CATALOG.md into:
   - `ANTI-PATTERN-CATALOG.md` — prevention cheat sheet only (~500 tokens)
   - `docs/anti-patterns/catalog-full.md` — complete table (loaded on demand)

2. Update immune-system skill to load full catalog when DETECT phase triggers

3. Add category tags to each entry (powershell, regex, svg, process, etc.) for targeted loading

**Savings**: ~1,644 tokens per session (73% reduction)

---

## Self-Learning Improvements

### Current immune-system Flow

```
DETECT → DIAGNOSE → DOCUMENT → IMMUNIZE → VERIFY
```

### Issues Identified

| Issue | Impact | Fix |
|-------|--------|-----|
| **No automatic trigger** | Agent must "notice" a pattern — often doesn't | Add trigger: every `mem_save(type=bugfix)` auto-checks catalog for similar entries |
| **No severity ranking** | All 23 patterns weighted equally | Add severity column: CRITICAL/HIGH/MEDIUM/LOW. Load CRITICAL+HIGH always, MEDIUM+LOW on-demand |
| **No expiry mechanism** | Catalog grows forever (23 entries, 2,244 tokens) | Add `review_after` date. Entries not triggered in 90 days → archive |
| **No cross-session validation** | Doesn't verify prevention actually works | Add `last_triggered` + `prevention_worked` fields. Track hit rate |
| **Learning Loop is vague** | "Capture→Extract→Evaluate→Apply" — no concrete steps | Define: (1) mem_search for similar errors (2) If match → auto-load prevention (3) Post-task: check if prevention was applied |
| **Dreaming is manual** | `!dream` must be invoked explicitly | Auto-trigger every 10th session via session-miner.ps1 |

### Proposed Enhancements

#### 1. Auto-Trigger on mem_save

```
mem_save(type=bugfix) → auto-search catalog → if similar entry exists:
  → "⚠️ Anti-pattern #N matches: {prevention}. Apply before continuing."
```

**Impact**: Catches repeated errors before they happen, not after.

#### 2. Severity-Based Loading

| Severity | Entries | Load Strategy |
|----------|---------|---------------|
| CRITICAL | #22, #23 (destructive ops, factibilidad) | Always loaded |
| HIGH | #8, #10, #16, #19 (encoding, PS quirks) | Loaded when .ps1/.svg files detected |
| MEDIUM | #1-7, #11-15 | Loaded on immune-system trigger |
| LOW | #17-18, #20-21 | Loaded on explicit request |

#### 3. Learning Loop Concrete Steps

Current: `Capture→Extract→Evaluate→Apply` (vague)

Proposed:
```
1. CAPTURE: Every error/correction → mem_save(type=bugfix)
2. SEARCH: mem_search(query=error_description) → find similar
3. CATALOG: If 2+ similar → create anti-pattern entry
4. IMMUNIZE: Add prevention to AGENTS.md + catalog
5. VALIDATE: Next 3 sessions → check if prevention was applied
6. PRUNE: 90-day review → archive unused entries
```

#### 4. Engram-Integrated Dreaming

Current: Manual `!dream` invocation.

Proposed: Auto-dream every N sessions:
```
session-miner.ps1 -Mode scan → extract patterns from last 10 sessions
→ if new pattern found → propose catalog entry
→ if pattern matches existing → update hit count
```

---

## Quick Wins (< 1 hour each)

| # | Action | Savings | Effort | Priority |
|---|--------|---------|--------|----------|
| 1 | **Delete caveman skill** (deprecated) | 200 tok | 5 min | P0 |
| 2 | **Strip frontmatter bloat** — remove `license`, `changelog` from all 70 skills | ~1,200 tok | 30 min | P0 |
| 3 | **Deduplicate agent prompts** — extract shared fragments to `prompts/shared/` | 2,900 tok | 45 min | P0 |
| 4 | **Compress opencode-model-router** — merge redundant tables, remove model list | 1,500 tok | 30 min | P1 |
| 5 | **Split ANTI-PATTERN-CATALOG** — cheat sheet only at session start | 1,644 tok/session | 20 min | P1 |
| 6 | **Local AGENTS.md → project overrides only** — remove duplicated global content | 3,400 tok/session | 30 min | P0 |
| 7 | **Merge SDD sub-skills into parent** — 9 skills → 1 with sections | 800 tok | 45 min | P2 |
| **TOTAL** | | **~11,644 tok** | **~3.5 hrs** | |

---

## Strategic Improvements (architectural changes)

### 1. Section-Level Lazy Loading for AGENTS.md

**Concept**: Split AGENTS.md into labeled sections with load triggers.

```
AGENTS.md (always loaded): Rules + Personality + Default-FAIL + Language/Tone + Project Context (~800 tok)
AGENTS.md.pre-flight (COMPLEX tasks): Ponytail Ladder + TRIANGULATE (~530 tok)
AGENTS.md.protocol (always loaded): condensed A+D+J (~400 tok)
AGENTS.md.protocol-detail (on demand): B+C+E-H+I+K+L (~700 tok)
AGENTS.md.engram (always loaded): core rules (~200 tok)
AGENTS.md.engram-detail (on demand): dreaming/autoclean details (~150 tok)
```

**Savings**: ~1,200 tokens per session (loading only what's needed).

### 2. Skill Resolution via skill-graph.ps1 (already partially done)

The skill-graph.ps1 already resolves 4-8 relevant skills per task. The issue is that **all 70 skills are still available for full loading**. The optimization is:

- Move skill content to `references/` subdirectories
- SKILL.md becomes a ~100 token "header" with trigger + summary
- Full content loaded only when skill is actually resolved AND selected

**Savings**: ~15,000 tokens of unneeded skill content per session.

### 3. Web Quality Cluster Refactoring

```
web-quality-audit/SKILL.md (orchestrator, ~400 tok)
web-quality-audit/references/a11y.md (loaded when a11y audit triggered)
web-quality-audit/references/perf.md (loaded when perf audit triggered)
web-quality-audit/references/seo.md (loaded when SEO audit triggered)
web-quality-audit/references/best-practices.md (loaded when best-practices triggered)
```

Delete standalone skills: accessibility, performance, seo, best-practices.
Update skill-graph.ps1 triggers to point to web-quality-audit with section parameter.

**Savings**: ~1,600 tokens (4 skills eliminated).

### 4. Agent Prompt Template System

Replace per-agent boilerplate with a template engine:

```json
{
  "agent": {
    "gentleman-security": {
      "prompt": "{file:prompts/shared/analyze-only.md}\n{file:prompts/shared/core-behavior.md}\nYou are a security specialist...",
    }
  }
}
```

Each agent prompt = shared fragments (loaded once, cached) + unique intro (~50-80 tokens).

**Savings**: ~2,900 tokens across all agent definitions.

### 5. Immune-System + Engram Integration

Current: immune-system and Engram are separate systems that overlap.

Proposed: Unified learning loop:
```
Error detected → mem_save(type=bugfix) → auto-search anti-patterns
  → match found: "⚠️ Prevention for #N: {rule}" (from Engram, not file)
  → no match: create new entry → auto-update catalog + AGENTS.md
  → validation: track prevention application rate across sessions
```

**Impact**: Eliminates file-based catalog loading, moves to Engram-query-based loading (0 tokens at session start, on-demand only).

---

## Implementation Priority Matrix

```
                    HIGH SAVINGS
                        │
     ┌──────────────────┼──────────────────┐
     │                  │                  │
     │  ★ Quick Win 6   │  ★ Quick Win 3   │
     │  (AGENTS.md dedup)│  (agent prompts) │
     │                  │                  │
     │  ★ Quick Win 5   │  ★ Strategic 2   │
LOW  │  (catalog split) │  (skill refs)    │  HIGH
EFFORT│                 │                  │ EFFORT
     │  ★ Quick Win 1   │  ★ Strategic 4   │
     │  (del caveman)   │  (template system)│
     │                  │                  │
     │  ★ Quick Win 2   │  ★ Strategic 5   │
     │  (frontmatter)   │  (immune+engram) │
     │                  │                  │
     └──────────────────┼──────────────────┘
                        │
                    LOW SAVINGS
```

### Recommended Order

1. **Quick Win 6** — Local AGENTS.md dedup (3,400 tok, 30 min)
2. **Quick Win 3** — Agent prompt dedup (2,900 tok, 45 min)
3. **Quick Win 5** — Catalog split (1,644 tok, 20 min)
4. **Quick Win 4** — Model router compression (1,500 tok, 30 min)
5. **Quick Win 2** — Frontmatter strip (1,200 tok, 30 min)
6. **Quick Win 1** — Delete caveman (200 tok, 5 min)
7. **Quick Win 7** — SDD merge (800 tok, 45 min)

**Total effort**: ~3.5 hours for ~11,644 token savings.

---

## Appendix: Token Measurement Methodology

- Token estimation: `bytes / 4` (standard approximation for English/mixed content)
- Verified against: AGENTS.md (14,641 bytes → 3,660 tokens estimated; actual tokenization ~3,500-3,800 depending on model)
- Skill sizes: actual file sizes from disk via `Get-ChildItem`
- Agent prompts: extracted from `opencode.json` prompt fields
- Shared fragment analysis: manual comparison of agent prompt text in `opencode.json`
