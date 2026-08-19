# Mini-Orchestrator Async Delegation — Analysis Report

**Date**: 2026-08-19
**Scope**: Improve async delegation (post-delegation-check.ps1 -Async + monitor-subagent.ps1 polling) → reduce polling overhead via async-completion webhook/callback push notifications.

---

## Summary

The mini-orchestrator implements async fire-and-forget delegation via `post-delegation-check.ps1 -Async` which spawns `monitor-subagent.ps1` as a hidden background process. The monitor polls git status every 15s (max 300s) until 2 consecutive identical snapshots ("stable"), then writes `{BaseRef}.async-result.json`. **Critical finding**: BabyAGI loop (`babyagi-loop.ps1`) implements **double polling** — it waits for the async result file with its own 15s/300s polling loop *after* the monitor already polled for git stability. This wastes ~2x CPU/IO and adds minimum 15s latency. No push notification mechanism exists.

---

## P1: Analyze — Evidence from Source

| Component | Key Behavior | File:Line |
|-----------|--------------|-----------|
| `post-delegation-check.ps1 -Async` | Launches monitor via `Start-Process -WindowStyle Hidden`, exits 0 immediately | 112-137, 155-167 |
| `monitor-subagent.ps1` poll loop | 15s interval, 300s cap, stability = 2 identical git snapshots | 176-204 |
| `monitor-subagent.ps1` checks per poll | Runs `check-subagent-output.ps1` + `validate-write-scope.ps1` each iteration | 88-172 |
| `babyagi-loop.ps1 Invoke-TaskAsync` | **Double polling**: waits for `.async-result.json` every 15s up to 300s | 170-173 |
| Result file naming | `{BaseRef}.async-result.json` (sanitized) in RepoRoot | 84-85, 164 |
| Security guardrail | `-Async` without `-AllowedPaths` → FAIL-CLOSED (v3 Perm-4) | 156-162 |
| Budget enforcement | `subagent-budget-guard.ps1` enforces 300s timeout, 25 tool calls | 55-56, 180-181 |
| Contract validation | C4d wiring: `Validate-AgentReturnContract` in `check-subagent-output.ps1` | 46-85 |

---

## P2: Validate — 8 Dimensions

### Security — HIGH RISK
| Finding | Evidence | Risk |
|---------|----------|------|
| **TOCTOU on result file** — Any process can write `{BaseRef}.async-result.json` between monitor completion and orchestrator read | `monitor-subagent.ps1:220` writes JSON; `babyagi-loop.ps1:180` reads it — no integrity check | HIGH |
| **No authentication on background process** — `Start-Process -WindowStyle Hidden` launches detached `pwsh` with full user context | `post-delegation-check.ps1:136` | HIGH |
| **Orphaned monitor processes** — No PID tracking, no cleanup on orchestrator crash | `Launch-AsyncMonitor` returns immediately, no process handle stored | MEDIUM |
| **Result file world-writable** — Written to repo root with default permissions | `monitor-subagent.ps1:84-85, 220` | MEDIUM |
| **Command injection surface** — `ConvertTo-SqlLiteral` escapes single quotes but `Start-Process` argument construction is complex | `post-delegation-check.ps1:81-84, 124-136` | LOW |

### UX — MEDIUM RISK
| Finding | Evidence | Risk |
|---------|----------|------|
| **Minimum 15s latency** — Even instant completions wait for next poll cycle | `PollIntervalSec = 15` default | MEDIUM |
| **No progress visibility** — Only stderr logs (`[monitor] poll N...`) | `monitor-subagent.ps1:176, 193, 196` | LOW |
| **Double polling confusion** — Developer sees two 15s loops with no clear distinction | `babyagi-loop.ps1:170-173` + `monitor-subagent.ps1:186-203` | MEDIUM |

### Data — MEDIUM RISK
| Finding | Evidence | Risk |
|---------|----------|------|
| **Result JSON schema unversioned** — No `version` field, breaking changes undetectable | `monitor-subagent.ps1:208-219` | MEDIUM |
| **No correlation ID** — Cannot trace result back to specific delegation in concurrent scenarios | `base_ref` only, no unique delegation ID | LOW |

### DX — MEDIUM RISK
| Finding | Evidence | Risk |
|---------|----------|------|
| **No cancellation API** — Cannot abort in-flight async delegation | `Launch-AsyncMonitor` fire-and-forget, no handle returned | MEDIUM |
| **Hardcoded paths/intervals** — No config file, env vars only for `PollIntervalSec`/`MaxWaitSec` | `monitor-subagent.ps1:46-47` | LOW |
| **CWD dependency** — `validate-write-scope.ps1` uses CWD (known limitation per ADR-031) | ADR-031 line 24 | LOW |

### Perf — HIGH RISK
| Finding | Evidence | Risk |
|---------|----------|------|
| **Double polling = 2x overhead** — Monitor polls git + BabyAGI polls file | `monitor-subagent.ps1:186-203` + `babyagi-loop.ps1:170-173` | HIGH |
| **Fixed 15s interval** — No exponential backoff, no adaptive polling | `PollIntervalSec = 15` constant | MEDIUM |
| **300s hard cap** — Long-running tasks forced to timeout even if progressing | `MaxWaitSec = 300` | LOW |

### Infra — MEDIUM RISK
| Finding | Evidence | Risk |
|---------|----------|------|
| **Background process lifecycle unmanaged** — `Start-Process` creates detached process, no job control | `post-delegation-check.ps1:136` | MEDIUM |
| **Git as stability signal** — Fragile: external commits break convergence detection | `monitor-subagent.ps1:154-166` | MEDIUM |
| **File-based IPC fragile** — Race conditions, no locking on `.async-result.json` | `monitor-subagent.ps1:220` write vs `babyagi-loop.ps1:180` read | MEDIUM |

### Arch — HIGH RISK
| Finding | Evidence | Risk |
|---------|----------|------|
| **Monitor does too much** — Polling + check execution + convergence + file write (violates SRP) | `monitor-subagent.ps1:88-223` | HIGH |
| **BabyAGI couples to file polling** — `Invoke-TaskAsync` assumes file-based result, not callback | `babyagi-loop.ps1:134-182` | HIGH |
| **Registry + Monitor overlap** — Both track delegation state independently | `delegation-registry.ps1` + `monitor-subagent.ps1` | MEDIUM |
| **No abstraction for completion notification** — Push vs pull not parameterized | All scripts assume polling | HIGH |

### Biz — LOW RISK
| Finding | Evidence | Risk |
|---------|----------|------|
| **Works for current scale** — Single delegation at a time | Tests pass (5/5 async, 9/9 BabyAGI) | LOW |
| **No horizontal scaling** — Concurrent delegations share repo root result files | `{BaseRef}.async-result.json` collision risk | LOW |

---

## P3: Synthesize — Findings Table

| # | Finding | Consensus | Risk | Files | Recommendation |
|---|---------|-----------|------|-------|----------------|
| 1 | Double polling (monitor + BabyAGI both poll 15s/300s) | UNANIMOUS | HIGH | `monitor-subagent.ps1`, `babyagi-loop.ps1` | Remove BabyAGI file polling; have monitor invoke callback/webhook on completion |
| 2 | No push notification mechanism (webhook/callback) | UNANIMOUS | HIGH | `post-delegation-check.ps1`, `monitor-subagent.ps1` | Add `-CompletionCallback` parameter (scriptblock/URL); invoke on stability |
| 3 | TOCTOU on `.async-result.json` — no integrity/auth | UNANIMOUS | HIGH | `monitor-subagent.ps1`, `babyagi-loop.ps1` | Write to temp + atomic rename; include HMAC/signature; verify on read |
| 4 | Orphaned background processes — no PID tracking/cleanup | UNANIMOUS | HIGH | `post-delegation-check.ps1` | Return PID; store in registry; add `cancel` action to registry |
| 4 | Monitor violates SRP — polling + checks + convergence + write | UNANIMOUS | HIGH | `monitor-subagent.ps1` | Split: `poll-git-stability.ps1`, `run-checks.ps1`, `write-result.ps1` |
| 5 | Git stability detection fragile (external commits break it) | MAJORITY | MEDIUM | `monitor-subagent.ps1:154-166` | Track only files matching `AllowedPaths`; ignore unrelated changes |
| 6 | Result JSON schema unversioned | MAJORITY | MEDIUM | `monitor-subagent.ps1:208-219` | Add `schema_version` field; document migration path |
| 7 | No cancellation API for in-flight delegations | MAJORITY | MEDIUM | `delegation-registry.ps1`, `post-delegation-check.ps1` | Add `cancel` action; kill monitor PID; write `status=cancelled` |
| 8 | Fixed 15s interval, no backoff | MAJORITY | MEDIUM | `monitor-subagent.ps1:46, 186-203` | Exponential backoff (15s→30s→60s→120s cap); configurable via env |
| 9 | CWD dependency in `validate-write-scope.ps1` | MAJORITY | LOW | `monitor-subagent.ps1:123-129`, ADR-031:24 | Pass `-RepoRoot` to all check scripts (already done in monitor) |
| 10 | No correlation ID for concurrent delegations | SPLIT | LOW | `monitor-subagent.ps1`, `delegation-registry.ps1` | Use `TaskId` from registry as correlation ID in result file name |
| 11 | Test gaps: concurrent delegations, monitor crash, false stability | SPLIT | MEDIUM | `tests/post-delegation-async.Tests.ps1` | Add integration tests for: concurrent, crash/restart, external git changes |
| 12 | Command injection surface in `Start-Process` arg construction | OUTLIER | LOW | `post-delegation-check.ps1:124-136` | Use `-ArgumentList` array form instead of string command |

---

## P4: Persist — Risk Matrix (Top 15 by Risk)

| Rank | Finding | Risk | Effort | Impact |
|------|---------|------|--------|--------|
| 1 | Double polling | HIGH | LOW | Eliminates 2x overhead, removes 15s min latency |
| 2 | No push notification (webhook/callback) | HIGH | MEDIUM | Enables true async, removes polling entirely |
| 3 | TOCTOU on result file | HIGH | LOW | Security hardening |
| 4 | Orphaned processes | HIGH | LOW | Resource leak prevention |
| 5 | Monitor SRP violation | HIGH | MEDIUM | Maintainability, testability |
| 6 | Git stability fragility | MEDIUM | LOW | Reliability |
| 7 | No cancellation API | MEDIUM | MEDIUM | Operational control |
| 8 | Unversioned result schema | MEDIUM | LOW | Future-proofing |
| 9 | Fixed interval/no backoff | MEDIUM | LOW | Perf under load |
| 10 | Test gaps (concurrent, crash) | MEDIUM | MEDIUM | Confidence |
| 11 | CWD dependency | LOW | LOW | Known limitation fix |
| 12 | No correlation ID | LOW | LOW | Observability |
| 13 | Command injection surface | LOW | LOW | Defense in depth |
| 14 | Registry/Monitor overlap | MEDIUM | MEDIUM | Architecture clarity |
| 15 | File-based IPC fragility | MEDIUM | MEDIUM | Reliability |

---

## Recommendations (Prioritized)

### Phase 1: Quick Wins (Low Effort, High Impact)
1. **Remove double polling** — `babyagi-loop.ps1 Invoke-TaskAsync` should wait on a synchronization primitive (event, named pipe, file watcher) instead of polling the result file. The monitor already knows when done.
2. **Add result file atomic write + HMAC** — Write to `.async-result.json.tmp`, compute HMAC with delegation-scoped key, atomic rename. Verify on read.
3. **Track monitor PID** — `Launch-AsyncMonitor` returns PID; store in `delegation-registry`; add `cancel` action that kills PID.

### Phase 2: Push Notification (Core Request)
4. **Add `-CompletionCallback` parameter** to `post-delegation-check.ps1 -Async`:
   - Accepts scriptblock (local) or HTTP webhook URL (remote)
   - Monitor invokes on convergence with result JSON as payload
   - BabyAGI registers callback that signals completion (e.g., `Set-Event`, writes to named pipe)
5. **Abstract notification transport** — Interface: `Invoke-CompletionCallback -Result $result -Callback $callback`

### Phase 3: Architecture Hardening
6. **Split monitor responsibilities** — Separate: `poll-git-stability.ps1` (convergence), `run-delegation-checks.ps1` (check-subagent-output + validate-write-scope), `emit-result.ps1` (write + callback).
7. **Version result schema** — Add `schema_version: 1` to JSON; document in ADR.
8. **Exponential backoff** — 15s → 30s → 60s → 120s (cap); respect `MaxWaitSec`.
9. **Filter git changes by `AllowedPaths`** — Stability only on relevant paths.

### Phase 4: Observability & Testing
10. **Correlation ID** — Use `TaskId` from registry in result filename: `{TaskId}.async-result.json`.
11. **Integration tests** — Concurrent delegations, monitor crash/restart, external git changes during monitoring.
12. **Cancellation test** — Verify `cancel` action kills monitor and writes cancelled status.

---

## Engram Persistence

```
mem_save:
  title: "analysis:gentleman-agent-gh:2026-08-19"
  type: architecture
  topic_key: "analysis/gentleman-agent-gh"
  content: |
    **What**: Analyzed mini-orchestrator async delegation (post-delegation-check -Async + monitor-subagent polling) for webhook/callback push notification replacement.
    **Why**: User wants to reduce polling overhead; current double-polling (monitor 15s + BabyAGI 15s) wastes resources and adds latency.
    **Where**: scripts/post-delegation-check.ps1, scripts/monitor-subagent.ps1, scripts/babyagi-loop.ps1, scripts/delegation-registry.ps1, scripts/subagent-budget-guard.ps1, adr/ADR-031-mini-orchestrator-async-delegation.md
    **Key Findings**:
      1. Double polling = 2x overhead, 15s min latency (HIGH)
      2. No push notification mechanism — pure polling only (HIGH)
      3. TOCTOU on .async-result.json, no integrity/auth (HIGH)
      4. Orphaned background processes, no PID tracking (HIGH)
      5. Monitor violates SRP (polling+checks+convergence+write) (HIGH)
      6. Git stability detection fragile to external commits (MEDIUM)
      7. No cancellation API (MEDIUM)
      8. Unversioned result schema (MEDIUM)
      9. Fixed interval, no exponential backoff (MEDIUM)
      10. Test gaps: concurrent, crash/restart, false stability (MEDIUM)
    **Learned**: BabyAGI loop's Invoke-TaskAsync duplicates monitor's polling work — the monitor already detects convergence; BabyAGI just needs a completion signal. The delegation-registry already exists for state tracking but isn't integrated with monitor lifecycle.
```

---

## Trend Analysis

**Previous analysis**: `docs/mejoras/2026-08-15-subagent-result-quality.md` (Subagent Result Quality Improvements)
- Focused on: C4d contract validation wiring, C7 budget enforcement, G5 registry extensions, async monitor contract validation integration
- **Delta vs previous**:
  - **Improvements**: Contract validation now wired in monitor (line 49-50 of 2026-08-15 doc); quality scoring implemented
  - **Regressions**: None detected
  - **New findings**: Double polling, TOCTOU, orphaned processes, no push mechanism, SRP violation — these are architectural gaps not covered in prior quality-focused analysis
  - **Stale**: Prior analysis assumed polling architecture was acceptable; current requirement explicitly requests push notifications

**Baseline established** — This is the first analysis specifically targeting the async delegation *architecture* (vs result quality). Future analyses should track: push notification adoption, polling overhead reduction, security hardening completion.
