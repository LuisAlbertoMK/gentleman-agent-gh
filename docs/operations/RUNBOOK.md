# Infrastructure Runbook

Quick-reference troubleshooting for gentleman-agent-gh operations.

## MCP Server Issues

| Symptom | Diagnosis | Fix | Prevention |
|---------|-----------|-----|------------|
| MCP tool returns timeout | Server overloaded or network issue | Check circuit breaker state in `.learnings/mcp-circuit-state.json`. If OPEN, wait 60s for HALF_OPEN. If persistent, run `scripts/health-check-system.ps1` | Use retry/backoff via `scripts/lib/mcp-resilience.ps1` |
| MCP tool returns "connection refused" | Server not running or wrong config | Verify `opencode.json` mcp section. For local servers: check command exists (`Get-Command <cmd>`). For remote: check URL and port | Enable health probes in session start |
| Circuit breaker stuck OPEN | Repeated failures locked the circuit | Dot-source `scripts/lib/mcp-resilience.ps1`, then: `Reset-McpCircuit -Server "server-name"`. If file `.learnings/mcp-circuit-state.json` doesn't exist, circuit is effectively CLOSED (no failures recorded) | Monitor failure count; investigate root cause before resetting |
| MCP returns unexpected data | Schema mismatch or version drift | Check MCP server version. Re-index with `codebase-memory-mcp_index_repository` if knowledge graph stale | Pin MCP server versions in opencode.json |

## Context Window Issues

| Symptom | Diagnosis | Fix | Prevention |
|---------|-----------|-----|------------|
| Responses become incoherent | Context window >80% full (RED zone) | Trigger manual compaction: `/compact`. Or call `mem_session_summary` + start fresh context | Monitor with context-watchdog skill; compress at YELLOW (40%) |
| Agent forgets earlier instructions | Compaction happened, context lost | Call `engram_mem_context` to recover session history. Check `mem_search` for prior decisions | Always call `mem_session_summary` before compaction |
| Token count spikes unexpectedly | Large tool output entered context | Use `ctx_execute` for data processing (sandbox keeps bytes out of conversation). Use `ctx_batch_execute` for multi-command batches | Follow Think-in-Code: process in sandbox, surface only answers |

## Agent Delegation Failures

| Symptom | Diagnosis | Fix | Prevention |
|---------|-----------|-----|------------|
| Subagent returns empty/wrong output | Agent hit context limit or misunderstood scope | Check agent's `_return-contract.md` output. Retry with narrower scope | Use `subagent-isolation` skill; keep delegation contracts precise |
| **Subagent "completed" but no output** | (a) Free-tier model hit output truncation, (b) stdout truncated by verbose verification, (c) model fell back to `general` due to `mode: primary` not being delegable | Run `git diff --name-only HEAD` — if empty, treat as silent failure. Retry with narrower scope (max 2 files). If still empty → escalate | Post-delegation git verification is MANDATORY. Never trust "completed" without diff proof. See `gentleman-vMK.md` post-delegation gate |
| Write-scope violation detected | Subagent wrote outside declared allowed_paths | Report to user. Use `git checkout -- <file>` to revert violations | Declare precise allowed_paths in delegation contract |
| Agent fails 2x consecutively | Root cause unclear or task too complex | STOP delegation. Report to user in natural language. Consider: (a) broader search, (b) different agent, (c) manual intervention | Follow Failure Escalation protocol in orchestrator prompt |

### Post-Delegation Output Verification Protocol

**MANDATORY for ALL subagent delegations** — enforced by `gentleman-vMK.md`:

1. **Git diff check**: `git diff --name-only HEAD` — if EMPTY → subagent produced NO changes
2. **Git status check**: `git status --short` — verify expected files appear
3. **Empty output protocol**: If diff is empty AND subagent said "completed" → **SILENT FAILURE**
4. **Retry**: Narrower scope (max 2 files). If still empty → escalate to human
5. **File-based fallback**: If stdout may truncate (verbose output, multi-file), instruct subagent to write 4-field report to `docs/agentes/{task}/05-completion-report.md` and echo only the file path

## Memory System Issues

| Symptom | Diagnosis | Fix | Prevention |
|---------|-----------|-----|------------|
| mem_save returns conflict | New memory contradicts existing | See engram-protocol skill: Memory Contradiction Detection section | Use topic_key consistently; search before save |
| Memory search returns stale results | Source file changed after indexing | Re-index: `codebase-memory-mcp_index_repository` | Check content hash in search results for staleness |
| Session summary missing | Session ended without close protocol | Manually create summary from git log + context | Always call `mem_session_summary` before session end |

## PowerShell Issues

| Symptom | Diagnosis | Fix | Prevention |
|---------|-----------|-----|------------|
| Script fails with parse error | Unicode chars (em-dash, arrows) in PS file | Replace with ASCII: `--` instead of `—`, `->` instead of `→` | Use only ASCII in .ps1 files |
| `#requires -Version 7` blocks execution | Running on PowerShell 5.1 | Install PS7+ (`winget install Microsoft.PowerShell`) or invoke the CMD wrapper (`scripts\sync-all.bat`) which forwards to pwsh | Target PS7+ for all new scripts; declare `#requires -Version (5.1|7)` in every .ps1 |
| Script declares 5.1 but dot-sources a PS7 lib | PS 5.1 rejects the lib's `#requires -Version 7` | Keep 5.1-declared scripts fully self-contained (no PS7-only libs) — see `scripts/sync-global-ps5.ps1`, the only PS5.1-compatible script | Test `scripts/tests/powershell-compat.Tests.ps1` enforces declaration=reality |
| DateTime round-trip fails through JSON | Culture-dependent serialization | Use `Get-IsoTimestamp` / `ConvertFrom-IsoTimestamp` helpers from `scripts/lib/mcp-resilience.ps1` | Never pass raw DateTime through ConvertTo-Json/ConvertFrom-Json |

## Permission & Runtime Issues

| Symptom | Diagnosis | Fix | Prevention |
|---------|-----------|-----|------------|
| `python`, `pwsh`, `docker`, etc. commands are DENIED at runtime | Permission ruleset is stale — cached before `sync-all` applied ADR-046 toolchain freedom | **Restart OpenCode** after running `scripts/sync-all.ps1`, then verify: `python --version` | Document in `scripts/sync-all.ps1` output: "⚠ RESTART OpenCode required for permission changes to take effect". Add to post-sync checklist. |
| `pwsh -NoProfile -Command` subprocess spawn is DENIED | Subprocess spawn (`pwsh *`) is intentionally denied by security policy; in-process PowerShell (7.6.5) works fine | Use `& "$env:GENTLEMAN_AGENT_ROOT\scripts/xxx.ps1"` or `. "$env:GENTLEMAN_AGENT_ROOT\scripts/bash-safe.ps1"; & "..."` pattern — this runs in-process, not as a subprocess spawn | See `bash-safe.ps1` for the approved invocation wrapper |
| Ollama (127.0.0.1:11434) unreachable | Vision-UX bridge degraded (offline-first mode active) | Start Ollama: `ollama serve` in a background terminal. If not installed → `winget install Ollama.Ollama` | Document in RUNBOOK: Ollama required for vision-analyze/UX modes; auto-fallback to offline-first documented in `docs/architecture.md` |
