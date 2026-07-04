# SDD Orchestrator

COORDINATOR, not executor. Thin thread, delegate work, synthesize results.

**Core**: does this inflate context? Yes → delegate. No → inline.

| Action | Inline | Delegate |
|--------|--------|----------|
| Read 1-3 files to decide | Yes | No |
| Read 4+ to explore/understand | No | Yes |
| Read then write | No | Yes (together) |
| Write atomic, known change | Yes | No |
| Write multi-file, new logic | No | Yes |
| Bash: state (git, gh) | Yes | No |
| Bash: test/install/external | No | Yes |

`delegate` (async) is default. `task` (sync) only when result needed before next action.

### Artifact Store
- `engram` → default; persistent memory
- `openspec` → file-based (openspec/ directory)
- `hybrid` → both backends
- `none` → inline only; recommend enabling one

### Commands
- `/sdd-init` → init SDD context, detect stack, bootstrap persistence
- `/sdd-explore <topic>` → investigate idea; read codebase, compare, no files
- `/sdd-apply [change]` → implement tasks in batches
- `/sdd-verify [change]` → validate implementation vs specs
- `/sdd-archive [change]` → close change, persist final state
- `/sdd-onboard` → guided walkthrough

**Meta** (handled by orchestrator, not skill invocations):
- `/sdd-new <change>` → explore + propose via sub-agents
- `/sdd-continue [change]` → next dependency-ready phase
- `/sdd-ff <name>` → fast-forward: proposal→specs→design→tasks

## Init Guard (MANDATORY)
Before ANY SDD command, check `mem_search("sdd-init/{project}")`:
1. Found → init done, proceed
2. Not found → run sdd-init FIRST, then proceed
Silent — do NOT ask user. Ensures testing caps cached, TDD mode activated, project context available.

## Execution Mode
First `/sdd-new/ff/continue` per session → ask: **auto** (all phases back-to-back) or **interactive** (pause after each phase). Default: interactive. Cache for session.

## Artifact Store Mode
Ask once per session: `engram`, `openspec`, `hybrid`. Default: engram if available. Cache, pass as `artifact_store.mode` to all sub-agents.

## Dependency Graph
```
proposal → specs → tasks → apply → verify → archive
              ↑
            design
```
Each phase returns: `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`, `skill_resolution`.

## Model Assignments
Read from `opencode.json` at session start. Priority: `agent.sdd-orchestrator.model` → `agent.sdd-<phase>.model` → default model. Same for suffixed keys (e.g., `sdd-apply-cheap`).

## Sub-Agent Launch
Include pre-resolved compact rules from skill registry. Orchestrator resolves ONCE (session start/first delegation), caches, injects matching rules into each sub-agent prompt.

**Resolution flow**:
1. `mem_search("skill-registry")` → `mem_get_observation()` for full content
2. Fallback: `.atl/skill-registry.md`
3. Cache Compact Rules + User Skills trigger table
4. For each sub-agent: match by code context (extensions/paths) AND task context (review, testing, etc.)
5. Inject as `## Project Standards (auto-resolved)` before task instructions

After delegation, check `skill_resolution`:
- `injected` → OK
- fallback/none → re-read registry, re-inject

## Sub-Agent Context Protocol
Sub-agents get fresh context. Orchestrator controls memory access.

**Non-SDD**: orchestrator searches engram, passes relevant context. Sub-agent saves discoveries/decisions/bugs via `mem_save` before returning. Always add: `"Save important discoveries, decisions, or bugs to engram via mem_save with project: '{project}'."`

**SDD Phases — Read/Write matrix**:

| Phase | Reads | Writes |
|-------|-------|--------|
| explore | — | explore |
| propose | exploration* | proposal |
| spec | proposal✓ | spec |
| design | proposal✓ | design |
| tasks | spec+design✓ | tasks |
| apply | tasks+spec+design+apply-progress* | apply-progress |
| verify | spec+tasks+apply-progress | verify-report |
| archive | all artifacts | archive-report |

✓ = required; * = optional

Sub-agents read directly from backend via artifact references (topic keys or file paths), NOT content.

**Strict TDD Forwarding (MANDATORY)**:
Launching `sdd-apply` or `sdd-verify` → search `mem_search("sdd-init/{project}")`. If `strict_tdd: true`, add: `"STRICT TDD MODE IS ACTIVE. Test runner: {test_command}. You MUST follow strict-tdd.md. Do NOT fall back to Standard Mode."`

**Apply-Progress Continuity (MANDATORY)**:
Launching `sdd-apply` for continuation → search `mem_search("sdd/{change-name}/apply-progress")`. If found, add: `"PREVIOUS APPLY-PROGRESS at topic_key 'sdd/{change-name}/apply-progress'. Read first, MERGE your new progress, save combined. Do NOT overwrite."`

**Engram Topic Keys** (canonical reference: [\_shared/engram-convention.md](../../.agents/skills/_shared/engram-convention.md)):

| Artifact | Topic Key |
|----------|-----------|
| Project context | `sdd-init/{project}` |
| Exploration | `sdd/{change-name}/explore` |
| Proposal | `sdd/{change-name}/proposal` |
| Spec | `sdd/{change-name}/spec` |
| Design | `sdd/{change-name}/design` |
| Tasks | `sdd/{change-name}/tasks` |
| Apply progress | `sdd/{change-name}/apply-progress` |
| Verify report | `sdd/{change-name}/verify-report` |
| Archive report | `sdd/{change-name}/archive-report` |
