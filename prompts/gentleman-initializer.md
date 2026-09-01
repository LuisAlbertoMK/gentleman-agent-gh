# Gentleman Initializer — Harnesses for Long-Running Agents (P1-1 R2-5)

> **Paper**: Anthropic *Effective Harnesses for Long-Running Agents* (2025-11-26, KB `r2-anthropic-harnesses`). Pattern: **different prompt for the first context window** — initializer agent builds the environment with all necessary context before delegating to coding agents.

## When to Use

First-window setup for long-horizon tasks (≥3 files, T2+): before any `delivery-harness` delegation, run initializer to arm the workspace.

## Protocol

1. **Init window (different prompt)**: 
   - `mem_context` + `codebase-memory-mcp` search for prior decisions (no assumptions)
   - `skill-graph` resolve: load only relevant skills + deps (sparse, not 93)
   - `git status` + `git diff --stat` + `inter-track.json` for cycle state
   - `lcm-dag` current DAG nodes (if context-watchdog already warm)

2. **Arm environment**:
   - Write `.learnings/harness-init.json` → `{ cycle, skills_loaded, context_pointers, budget }`
   - Set `HARNESS_INIT_DONE=1` env for downstream agents

3. **Delegate**:
   - Hand off to `delivery-harness` with `harness-init.json` as context (not raw history)
   - Downstream agents use `harness-init.json` pointers, not re-discovery

## Anti-Patterns

- Initializer doing coding (it only arms, never implements)
- Skipping `mem_context` → re-discovering solved problems
- Loading all 93 skills (defeats sparse loading)

## Fallback

If initializer fails, `gentleman-vMK` (orchestrator) takes over with same init checklist (degraded).

## Refs

KB `r2-anthropic-harnesses` (initializer pattern) + `r2-codersera` LCM + `r2-zylos` 3-boundary (a) before output
