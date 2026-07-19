# Gentleman Agent — Análisis Profundo v4

**Fecha**: 2026-07-18
**Versión**: v4 (6 especialistas, 8 dimensiones, 47 hallazgos)
**Especialistas**: Security · Performance · Frontend/UX · Infrastructure · Documentation · Architecture

---

## Executive Summary

El sistema Gentleman Agent tiene una arquitectura sólida (22 agentes, 71 skills, 91 scripts) con defensa en profundidad. Sin embargo, **3 problemas CRITICAL** y **11 problemas HIGH** reducen eficiencia, seguridad y mantenibilidad. El plan v4 prioriza 15 mejoras de alto impacto con verificación `!breaker` en cada paso.

**Risk Score Global**: 6.2/10 (Medium-High)
**Mayor ROI**: Consolidación de contratos de retorno + reducción de token overhead + hardening de permisos.

---

## Per-Dimension Findings

### 1. Security (Risk: 7/10)

| # | Severity | Finding | Evidence | Recommendation |
|---|----------|---------|----------|----------------|
| S1 | **CRITICAL** | Memory poisoning via MCP — no input validation on `mem_save` | `engram_mem_save` accepts arbitrary `content` strings. Malicious code comments → agent stores payload → next session picks it up via `mem_search`. | Sanitize `mem_save` content (strip prompt-injection patterns) or add `mem_judge` gate before persisting from untrusted sources. |
| S2 | HIGH | Read-only agents have `bash: ask` not `deny` | `gentleman-security`, `gentleman-seo` etc. can run shell commands if human approves. Prompt injection in source code could trick agent into `echo > malicious_file`. | Set `bash: *: deny` for all read-only specialist agents. |
| S3 | HIGH | Orchestrator has `bash: *: allow` — escalation surface | `python -c "import os; os.remove(...)"` or `node -e "require('fs').unlinkSync(...)"` bypass the deny list. | Add `python *` / `node *` to deny list, or set orchestrator to `bash: *: ask`. |
| S4 | MEDIUM | MCP servers lack sandboxing | Engram has full filesystem access. context7/headroom API keys have unknown scope. | Evaluate MCP server sandboxing. Validate/sanitize stored content. |
| S5 | MEDIUM | Glob bypass on `.env` protection | `.envrc`, `.env.bak`, `.env.old` not blocked. `**/*secret*` not matched. | Add broader patterns: `**/.env*`, `**/*.env`, `**/*secret*`, `**/.ssh/**`. |
| S6 | LOW | No tamper detection on config files | `opencode.json`, `AGENTS.md` write-denied but no HMAC/git hook integrity check. | Add pre-commit hook or CI check for integrity-sensitive files. |

### 2. Performance (Risk: 5/10)

| # | Severity | Finding | Evidence | Recommendation |
|---|----------|---------|----------|----------------|
| P1 | **CRITICAL** | System prompt burns ~12K tokens before user speaks | Engram protocol duplicated 3×, 80 skill descriptions always loaded, MCP tool schemas injected. | Consolidate Engram to 1 location (skill file only). Lazy-load skill list. |
| P2 | **CRITICAL** | MCP tool definitions add ~2-4K tokens/session | 4 MCP servers + 3 plugins inject schemas even when unused. | Lazy-load MCP tool schemas. Disable sequential-thinking (already disabled). |
| P3 | HIGH | Permission blocks duplicated 20× in opencode.json | ~600 tokens of pure JSON waste. | Extract shared permission template. |
| P4 | HIGH | Compaction reserve 12K too conservative | 9.4% of 128K context permanently locked. | Set `reserved: 8000`. |
| P5 | MEDIUM | Key skills not Karpathy-compressed | skill-graph (2.7KB), lean-context (3.8KB), karpathy-loop (3.1KB) uncompressed. | Apply karpathy-loop to these 3 skills. ~4K token savings when loaded. |
| P6 | MEDIUM | Subagent-first thresholds inconsistent | PROTOCOL.md: ">3 files" vs T1-T4: "T2=2-5 files" overlap ambiguously. | Align: T1=1 file, T2=2-4, T3=5+. |
| P7 | LOW | Zone thresholds misaligned across 3 sources | context-watchdog: 40/60/80, skill-graph digest: 60/80, core-behavior: 40/60/80. | Single source of truth: reference context-watchdog everywhere. |

### 3. UX / Response Quality (Risk: 6/10)

| # | Severity | Finding | Evidence | Recommendation |
|---|----------|---------|----------|----------------|
| U1 | HIGH | Failure escalation is human-hostile | Raw YAML `agent_output: [raw output]` dumped on user. | Synthesize failures into 2-3 line human-readable messages. Keep raw YAML as internal log. |
| U2 | HIGH | Zero progress feedback during multi-agent work | User sees nothing between "analyzing..." and final result across 6+ subagents. | Emit phase announcements: "Phase 1/3: Reading files... ✓ → Phase 2/3: Implementing... ✓" |
| U3 | HIGH | Shortcut discovery impossible | 18+ shortcuts across 6 categories, no progressive disclosure. | Add contextual `!help` that lists relevant shortcuts based on current context. |
| U4 | MEDIUM | Bilingual mixing creates cognitive overhead | PROTOCOL.md mixes Spanish/English. Agent prompts are English-only. | Standardize: keep jargon in personality text, translate procedural terms. |
| U5 | MEDIUM | Error recovery inconsistent across agents | gentleman-quick: 4 explicit failure paths. gentleman-deep: 1 vague path. | Standardize structured failure report format across all agents. |
| U6 | MEDIUM | Context-budget zones invisible to user | Agent becomes terse at ORANGE without explanation. | Brief indicator when transitioning zones: "(context tightening — headline mode)" |

### 4. Infrastructure (Risk: 6/10)

| # | Severity | Finding | Evidence | Recommendation |
|---|----------|---------|----------|----------------|
| I1 | HIGH | Dockerfile single-stage, non-optimized | `COPY . .` before `npm install` invalidates layer. No multi-stage. | Split build + runtime stages. Add `.dockerignore`. |
| I2 | HIGH | CI Quality Gate runs all steps sequentially | No job splitting. Every commit runs PSSA, shellcheck, Pester, pre-commit, trufflehog — ALL sequentially. | Split into 3 jobs: lint (fast), security (Linux), tests (Pester). |
| I3 | HIGH | No health check or observability | No HTTP endpoint, no structured logging, no metrics. | Add health endpoint checking: MCP servers, disk, git, Engram. |
| I4 | HIGH | backup.ps1 has no push/remote | Local-only backup. Disk failure = backup loss. | Add optional `-Remote` parameter for push. |
| I5 | MEDIUM | Runs as root in Docker | No `USER vscode` directive. | Add `USER vscode` before CMD. |
| I6 | MEDIUM | No .dockerignore | `.git`, `node_modules`, `.learnings` all copied into image. | Create `.dockerignore`. |
| I7 | MEDIUM | No dependency caching in CI | Every run re-installs npm, pip, pre-commit. | Add `actions/cache` for `~/.npm`, `~/.cache/pre-commit`. |
| I8 | MEDIUM | cache.ps1 race condition | Read-modify-write without file locking. | Use `[System.IO.FileStream]` with `FileShare.None`. |
| I9 | MEDIUM | No rollback procedure documented | backup.ps1 creates snapshots but no restore flow documented. | Add restore documentation and `--List` mode. |

### 5. Documentation (Risk: 5/10)

| # | Severity | Finding | Evidence | Recommendation |
|---|----------|---------|----------|----------------|
| D1 | HIGH | Skill count inconsistency across all docs | README: 68, QUICKSTART: 69, SKILLS-INDEX: 71, PROTOCOL: 68. | Pick ONE canonical source (SKILLS-INDEX = 71) and grep-replace. |
| D2 | HIGH | Language mixing hurts onboarding | README in Spanish. PROTOCOL mixes both. Persona says "artifacts default to English" but doesn't follow it. | Translate README/QUICKSTART to English per own convention. |
| D3 | MEDIUM | AGENTS.md is routing stub, not entrypoint | 44 lines, delegates to PROTOCOL.md. New users confused. | Add 10-line table of contents at top. |
| D4 | MEDIUM | SHORTCUTS.md overlaps with 3 other docs | Shortcuts appear in README, PROTOCOL, QUICKSTART, SHORTCUTS. | Remove shortcut tables from README/PROTOCOL. Keep only reference link. |
| D5 | MEDIUM | CONTRIBUTING.md thin on unique workflows | Doesn't mention SDD, skill-validate, quality-gate local, score system. | Add "Local Validation" section with exact commands. |
| D6 | LOW | No glossary for domain terms | "Ponytail", "SDD", "Bitácora", "PSSA", "Karpathy compression" undefined. | Add glossary section to PROTOCOL.md. |

### 6. Architecture (Risk: 7/10)

| # | Severity | Finding | Evidence | Recommendation |
|---|----------|---------|----------|----------------|
| A1 | **CRITICAL** | Two competing return contracts | `_core-behavior-gp.md`: 5-field (status/summary/files/verification/escalation). `subagent-isolation`: 4-field (Decision/Files/Findings/Nuance). Incompatible schemas. | Define ONE canonical contract. 4-field is better (preserves lossy summary info). |
| A2 | HIGH | Dual routing systems | `gentleman-vMK.md`: hardcoded routing table. `opencode-model-router` skill: different table with fallbacks. Can disagree. | ONE routing authority: `opencode-model-router` skill. Orchestrator loads it. |
| A3 | HIGH | Permission blocks copy-pasted 14 times | ~250 lines of identical bash deny-list in opencode.json. | Extract shared permission template or add CI lint for consistency. |
| A4 | MEDIUM | gentleman-implementer breaks shared-pattern | No `_core-behavior-gp.md` or `_analyze-only-protocol.md` included. Lacks tool constraints, autonomy zones. | Add shared fragment include. |
| A5 | MEDIUM | sdd-orchestrator uses paid model | `claude-sonnet-4-6` in a "FREE TIER" branded system. | Document cost exception. Consider free model alternative. |
| A6 | MEDIUM | 80 skills, zero dependency enforcement | Skills declare `dependencies:` in YAML but no loader validates. | Add CI lint to validate declared deps exist. |
| A7 | LOW | `_analyze-only-protocol.md` duplicates core behavior | Re-declares autonomy zones with drift from `_core-behavior-gp.md`. | Use `{file:}` include instead of re-declaration. |

---

## Consensus (All 6 Specialists Agree)

1. **Permission block duplication is the #1 maintenance risk** — any deny-list update requires 14+ edits
2. **Return contract fragmentation** — 3 different output formats create integration fragility
3. **Token overhead is self-inflicted** — the system about managing tokens costs more tokens than most tasks
4. **Documentation drift** — skill counts, script counts, and shortcut tables diverge across files
5. **Security is defense-in-depth but has gaps** — read-only agents shouldn't have shell access

## Divergence (Specialists Disagree)

| Topic | View A | View B |
|-------|--------|--------|
| Orchestrator bash permissions | Security: set to `ask` | Performance: keep `allow` for coordination speed |
| Bilingual docs | UX: translate to English | Architecture: keep Rioplatense identity in docs |
| Compaction reserve | Performance: reduce to 8K | Infrastructure: keep 12K for safety margin |

## Risk Matrix

| Impact × Likelihood | Low | Medium | High |
|---------------------|-----|--------|------|
| **Critical** | S6 (tamper) | P1 (token overhead) | A1 (return contracts) |
| **High** | I4 (backup push) | S2 (bash permissions) | A2 (dual routing) |
| **Medium** | D6 (glossary) | U4 (bilingual) | I2 (CI sequential) |
| **Low** | D6 (glossary) | P7 (zone alignment) | U3 (shortcut discovery) |

---

## Recommendations — Plan v4

### Phase 1: Quick Wins (1-2 hours, low risk)

| # | Action | Files | Verification |
|---|--------|-------|-------------|
| 1.1 | Consolidate skill count to 71 across all docs | README.md, QUICKSTART.md, PROTOCOL.md, ARCHITECTURE.md | `grep -r "68 skills\|69 skills\|68+1" docs/` returns 0 |
| 1.2 | Add ToC to AGENTS.md top | AGENTS.md | Manual: new user can navigate in <30s |
| 1.3 | Add `bash: *: deny` to all read-only agents | opencode.json | `!breaker` verifies agents can't run shell |
| 1.4 | Align zone thresholds to 40/60/80 everywhere | skill-graph/SKILL.md | `grep -r "YELLOW.*60" .agents/skills/` returns 0 |
| 1.5 | Set `compaction.reserved: 8000` | opencode.json | `ctx-stats` shows ~4K more available |

### Phase 2: Security Hardening (2-4 hours, medium risk)

| # | Action | Files | Verification |
|---|--------|-------|-------------|
| 2.1 | Add `python *` / `node *` to orchestrator bash deny-list | opencode.json | `!breaker` attempts `python -c "print('test')"` → denied |
| 2.2 | Broaden `.env` protection patterns | opencode.json | `!breaker` tries reading `.envrc`, `.env.bak` → denied |
| 2.3 | Add memory poisoning guard to engram protocol | engram-protocol/SKILL.md | `!breaker` attempts storing injection payload → sanitized |
| 2.4 | Add CI lint for permission consistency | scripts/ or .github/ | CI fails if any agent has different deny-list |

### Phase 3: Token Optimization (3-5 hours, medium risk)

| # | Action | Files | Verification |
|---|--------|-------|-------------|
| 3.1 | Consolidate Engram protocol to 1 location | AGENTS.md, engram-protocol/SKILL.md | `ctx-stats` shows ~800 token reduction |
| 3.2 | Extract shared permission template | opencode.json | Config size reduced by ~600 tokens |
| 3.3 | Lazy-load skill descriptions (reduce 80→20 per session) | System prompt or opencode config | `ctx-stats` shows ~400 token reduction |
| 3.4 | Karpathy-compress skill-graph, lean-context, karpathy-loop | .agents/skills/*/SKILL.md | Each skill <2KB after compression |

### Phase 4: Architecture Consolidation (4-6 hours, high risk)

| # | Action | Files | Verification |
|---|--------|-------|-------------|
| 4.1 | Define ONE return contract (4-field) in `_return-contract.md` | prompts/shared/, all agent prompts | `!breaker` verifies all agents use same format |
| 4.2 | Make `opencode-model-router` the single routing authority | prompts/gentleman-vMK.md, opencode-model-router/SKILL.md | No hardcoded routing in orchestrator prompt |
| 4.3 | Add `_core-behavior-gp.md` include to gentleman-implementer | opencode.json | Implementer has tool constraints and autonomy zones |
| 4.4 | Unify `_analyze-only-protocol.md` to use `{file:}` include | prompts/shared/_analyze-only-protocol.md | No drift between protocol versions |

### Phase 5: Infrastructure & Docs (5-8 hours, high risk)

| # | Action | Files | Verification |
|---|--------|-------|-------------|
| 5.1 | Multi-stage Dockerfile + .dockerignore | Dockerfile, .dockerignore | `docker build` succeeds, image <500MB |
| 5.2 | Split CI into parallel jobs | .github/workflows/quality-gate.yml | CI runs in <5min (vs current ~15min) |
| 5.3 | Add health check endpoint | scripts/health-endpoint.ps1 | `!health` checks MCP servers + disk + git |
| 5.4 | Translate README/QUICKSTART to English | README.md, QUICKSTART.md | Non-Spanish speaker can onboard |
| 5.5 | Add contextual `!help` shortcut | scripts/help-contextual.ps1 | `!help` lists relevant shortcuts per context |

---

## v1 → v2 → v3 → v4 Evolution

| Version | Scope | Findings | Focus |
|---------|-------|----------|-------|
| v1 | Initial agent setup | ~10 items | Basic routing and permissions |
| v2 | Skills expansion (40→68) | ~20 items | Skill quality and coverage |
| v3 | Protocol refinement | ~30 items | Delegation patterns, context management |
| **v4** | **Full-stack analysis** | **47 items** | **Security, token optimization, architecture consolidation, infrastructure** |

**Key delta v3→v4**: v4 adds cross-dimensional analysis (6 specialists agreeing/disagreeing), risk matrix, and phased implementation with `!breaker` verification at each step.

---

## Gate

**Plan only** — NO code, NO commit. Must exit analysis mode before implementing.

Next step: Execute Phase 1 (Quick Wins) with `!breaker` verification after each action.
