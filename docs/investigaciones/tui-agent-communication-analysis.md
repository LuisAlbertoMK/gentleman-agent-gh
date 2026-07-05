# TUI ↔ Agent Communication Architecture Analysis

**Project**: gentleman-agent-gh  
**Date**: 2026-07-05  
**Scope**: Multi-project, multi-agent communication between a TUI application and recording/agent systems supporting opencode and gentleman-vmk  
**Status**: Comprehensive analysis — 5 parallel research approaches synthesized

---

## Executive Summary

This document analyzes **all viable approaches** for connecting a TUI (Text User Interface) application with an agent/recording system where:
- Multiple projects work together (or independently)
- Each project can have N agents (UI/UX, Security, Optimization, SEO, etc.)
- Agents run in opencode or gentleman-vmk
- Communication must work: same session, different sessions, same project, different projects, local or distributed

**Primary Recommendation**: **Extend the existing Bridge v2 (MCP stdio + JSONL)** as the foundation, with **JSON-RPC 2.0 / LSP-style protocol** as the communication layer, and **tmux + git worktrees** for process isolation.

---

## Table of Contents

1. [Requirements & Constraints](#requirements--constraints)
2. [Approach 1: Local IPC Mechanisms](#approach-1-local-ipc-mechanisms)
3. [Approach 2: MCP & Protocol-Based](#approach-2-mcp--protocol-based)
4. [Approach 3: Database & Storage-Based](#approach-3-database--storage-based)
5. [Approach 4: Distributed/Network & Hybrid](#approach-4-distributednetwork--hybrid)
6. [Approach 5: Web Research Synthesis (2024-2026)](#approach-5-web-research-synthesis-2024-2026)
7. [Comparative Analysis Matrix](#comparative-analysis-matrix)
8. [Recommended Architecture](#recommended-architecture)
9. [Implementation Roadmap](#implementation-roadmap)
10. [Security Considerations](#security-considerations)
11. [Multi-Project/Multi-Agent Patterns](#multi-projectmulti-agent-patterns)
12. [Cross-Agent Compatibility (opencode/gentleman)](#cross-agent-compatibility-opencodegentleman)
13. [Appendix: Key References](#appendix-key-references)

---

## Requirements & Constraints

### Functional Requirements

| Requirement | Priority | Notes |
|-------------|----------|-------|
| TUI ↔ Agent bidirectional communication | P0 | Real-time events, commands, responses |
| Multi-project isolation | P0 | Project A agents don't see Project B messages |
| Multi-agent per project (N agents) | P0 | UI/UX, Security, Optimization, SEO, custom |
| Cross-session communication | P0 | Session A agent → Session B agent |
| opencode / gentleman-vmk support | P0 | Both agent variants |
| Local-first (same machine) | P0 | Primary deployment model |
| Distributed ready (multi-machine) | P1 | Future-proofing |
| Persistent audit trail | P0 | Recording agent requirement |
| Low latency (<10ms local) | P1 | TUI responsiveness |

### Non-Functional Constraints

| Constraint | Detail |
|------------|--------|
| No new heavy dependencies | Prefer stdlib / already-installed |
| Security by default | No network exposure unless explicit |
| Crash-safe | Message durability across restarts |
| Observable | Debugging, tracing, replay |
| Simple operational model | Minimal moving parts |

---

## Approach 1: Local IPC Mechanisms

*Source: Subagent Analysis 1 — IPC mechanisms comparison*

### Mechanisms Evaluated

| Mechanism | Latency | Multi-Project | Multi-Agent | Complexity | Windows Support | Best For |
|-----------|---------|---------------|-------------|------------|-----------------|----------|
| **Unix Domain Sockets** | ~μs | ✅ Socket per project | ✅ Socket per agent | Low | ❌ (WSL only) | Linux/macOS local |
| **Named Pipes** | ~μs | ✅ Pipe per project | ✅ Pipe per agent | Low | ✅ Native | Windows local |
| **Shared Memory + mutex** | ~ns | ✅ Segment per project | ⚠️ Complex sync | High | ✅ | Ultra-high throughput |
| **File-based (JSONL + inotify)** | ~1-100ms | ✅ File per project | ⚠️ Single writer | Lowest | ✅ Universal | Audit trail + simplicity |
| **Message Queues (POSIX/System V)** | ~μs | ✅ Queue per project | ✅ Queue per agent | Medium | ❌ | Legacy systems |
| **gRPC over UDS** | ~μs | ✅ Service per project | ✅ Stream per agent | Medium | ✅ (via UDS) | Typed contracts v2 |
| **HTTP/localhost** | ~1-5ms | ✅ Path routing | ✅ Path routing | Low | ✅ Universal | Simplicity, debugging |
| **WebSockets/localhost** | ~1-5ms | ✅ Room/namespace | ✅ Room/namespace | Low-Med | ✅ Universal | Real-time push |

### Key Findings

**Unix Domain Sockets + JSON-RPC 2.0** emerges as the optimal local transport:
- Namespace isolation: `/tmp/agent-ipc/{project}/{agent}.sock`
- TUI maintains one connection per agent
- Inter-project bridge via dedicated `bridge.sock` per project
- JSON-RPC 2.0 for request/response + notifications (streaming)
- Security via filesystem permissions + optional HMAC tokens

**Named Pipes** are the Windows equivalent with identical API abstraction.

**File-based JSONL** (current `bridge.jsonl`) is mandatory as audit trail regardless of primary transport.

### Implementation Phases

| Phase | Transport | Effort | Value |
|-------|-----------|--------|-------|
| 1 | JSONL + stdio (current bridge) | 0 (done) | ✅ Baseline |
| 2 | UDS/Named Pipes abstraction | 2-4 hrs | 🟡 Lower latency |
| 3 | gRPC over UDS (typed) | 1-2 days | 🟢 v2 upgrade |

### Compatibility

| Agent Variant | Support |
|---------------|---------|
| opencode | Add UDS listener plugin |
| opencode (vmk fork) | Native Named Pipes (Win), UDS (Unix) — removed |
| gentleman-vmk | Full JSON-RPC 2.0 recommended |

---

## Approach 2: MCP & Protocol-Based

*Source: Subagent Analysis 2 — Deep dive on existing Bridge v2 + MCP patterns*

### Executive Summary

The **existing `gentleman-agent-gh` already implements Bridge v2** — a production-ready MCP stdio server with per-project isolation, byte-offset checkpoints, and shared JSONL. This is the **strongest foundation**.

### Approach Comparison

| Approach | Architecture | Latency | Multi-Project | Multi-Agent | Opencode Compat | Complexity |
|----------|--------------|---------|---------------|-------------|-----------------|------------|
| **2A: Bridge v2 (Current)** | JSONL + per-project MCP stdio | ~1-5ms | ✅ Native | ✅ Per-project slug | ✅ Native | ✅ Done |
| 2B: MCP over TCP/WebSocket | Central MCP bridge server | ~1-10ms | ✅ Multi-tenant | ✅ Per-connection | ⚠️ Needs proxy | Medium |
| 2C: MCP over Named Pipes | OS pipes per agent/project | ~0.1-1ms | ✅ Per-project | ✅ Per-pipe | ⚠️ Adapter needed | Low-Med |
| 2D: A2A over MCP | Standardized agent protocol | ~5-20ms | ✅ Protocol-native | ✅ Agent identity | ❌ Not adopted | High |
| 2E: MCP Gateway/Router | Central router → MCP servers | ~5-15ms | ✅ Central discovery | ✅ Route by agent ID | ⚠️ Custom router | High |
| 2F: Engram-backed MCP | Shared Engram memory + MCP | ~1-10ms | ✅ Project-scoped | ✅ Agent-scoped | ✅ Configured | Low |

### Bridge v2 Deep Dive (Current Implementation)

**Architecture:**
```
┌─────────────┐     stdio      ┌─────────────────────┐     JSONL       ┌─────────────┐
│  TUI App    │ ──────────────▶ │ bridge-mcp-server   │ ◀──────────────▶ │  opencode   │
│  (Project A)│                 │ -ProjectId=TUI-A    │  (shared file)   │  (Project B)│
└─────────────┘                 └─────────────────────┘                  └─────────────┘
                                          │
                                          ▼
                              ┌─────────────────────┐
                              │ .bridge-checkpoint. │
                              │ TUI-A (byte offset) │
                              └─────────────────────┘
```

**How it works:**
- Each project runs `bridge-mcp-server.ps1 -ProjectId <slug>` as MCP stdio server
- Tools: `bridge_send`, `bridge_read`, `bridge_status`
- Shared `D:\TEMP\opencode-bridge.jsonl` — append-only JSONL
- Per-project checkpoint `.bridge-checkpoint.<slug>` tracks byte offset
- **Write never updates checkpoint** — only reader advances after processing

**Pros:**
- ✅ Already implemented and working
- ✅ Zero network latency — stdio + local file
- ✅ Per-project isolation — checkpoint per project slug
- ✅ Multi-agent native — opencode agents call `bridge_read`/`bridge_send` via MCP tools
- ✅ Crash-safe — append-only JSONL, byte-offset checkpoints survive crashes
- ✅ Security — file permissions + STDIO isolation (no network)
- ✅ Simple — ~400 lines PowerShell, no deps beyond PS7+

**Cons:**
- ⚠️ File-based polling — `bridge_read` reads new bytes; not push-based
- ⚠️ Single writer contention — JSONL append serialized (fine for <100 msg/s)
- ⚠️ No native pub/sub — agents must poll `bridge_read`
- ⚠️ No message routing — all projects see all messages (filter by `source` field)
- ⚠️ Windows file locking — concurrent read/write needs `FileShare.ReadWrite`

### TUI Integration Path (Recommended)

```json
// TUI project's opencode.json
{
  "mcp": {
    "project-bridge": {
      "enabled": true,
      "type": "local",
      "command": [
        "pwsh", "-NoProfile", "-Command",
        "& \"$env:GENTLEMAN_AGENT_ROOT/scripts/bridge-mcp-server.ps1\" -ProjectId tui-app"
      ],
      "timeout": 10000
    }
  }
}
```

TUI calls `bridge_send`/`bridge_read` via MCP client (any MCP client library).

### Extensions for TUI

1. **Add TUI-specific message types** to bridge schema:
```powershell
[ValidateSet("error","fix","finding","proposal","agreement",
             "tui.event","agent.response","agent.task","agent.heartbeat")]
[string]$Type
```

2. **TUI MCP client integration** (poll `bridge_read` + call `bridge_send`)

3. **Optional: FileSystemWatcher → TUI push notifications** for lower latency

4. **Parallel: Engram memory** for persistent cross-session context sharing

---

## Approach 3: Database & Storage-Based

*Source: Subagent Analysis 3 — Database/storage comparison*

### Comparison Matrix

| Criterion | **SQLite (WAL)** | **PostgreSQL** | **Redis Streams** | **JSONL Files** | **Event Sourcing** | **Embedded KV** | **NATS/Kafka** |
|-----------|------------------|----------------|-------------------|-----------------|-------------------|-----------------|----------------|
| **Latency (local)** | ~0.1-1ms | ~0.5-2ms | **<1ms** | Poll: 100ms/Inotify: ~1ms | Backend-dep | **<0.1ms** | NATS ~0.5ms |
| **Multi-Project** | ✅ File/project | ✅ Schema/RLS | ✅ Prefix/ACL | ✅ File/project | ✅ Stream/project | ✅ Dir/project | ✅ Topic/project |
| **Multi-Agent** | ✅ WAL + locks | ✅ Pool + advisory | ✅ Consumer groups | ⚠️ Single writer | ✅ Projections | ❌ Single-process | ✅ Consumer groups |
| **Real-time Push** | ❌ Poll/triggers | ✅ LISTEN/NOTIFY | ✅ **Native** | ❌ Poll/inotify | ✅ Projections | ❌ No | ✅ **Native** |
| **Durability** | ✅ ACID, WAL | ✅ **Highest** | ⚠️ Config-dep | ⚠️ fsync only | ✅ Immutable | ✅ ACID | ✅ **Highest** |
| **Ops Complexity** | **Lowest** | Medium-High | Medium | **Lowest** | **Highest** | Low | High (Kafka) |
| **Local-First** | **★★★★★** | ★★★☆☆ | ★★★★☆ | **★★★★★** | ★★☆☆☆ | **★★★★★** | ★★☆☆☆ |

### Recommended: Hybrid SQLite + Redis

```
┌─────────────────────────────────────────────────────────────┐
│                        TUI Application                      │
├─────────────────────────────────────────────────────────────┤
│  SQLite (per-project)    │  Redis (Pub/Sub + Streams)       │
│  - Durable message log   │  - Real-time TUI updates         │
│  - Queries, history      │  - Agent coordination            │
│  - Audit/debug           │  - Heartbeats, presence          │
├──────────────────────────┼──────────────────────────────────┤
│           JSONL Bridge (append-only audit log)              │
│           projects/abc/bridge.jsonl                         │
└──────────────────────────┼──────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
   ┌─────────┐        ┌─────────┐        ┌─────────┐
   │ Agent   │        │ Agent   │        │ Agent   │
   │  SEO    │        │ Security│        │   UI/UX │
   └─────────┘        └─────────┘        └─────────┘
```

### Schema Design (SQLite per Project)

```sql
-- One file per project: data/project_abc.db
CREATE TABLE messages (
  id INTEGER PRIMARY KEY,
  agent_id TEXT NOT NULL,           -- seo, security, ui, optimization
  session_id TEXT,                  -- agent session
  type TEXT NOT NULL,               -- command, event, response, log, heartbeat
  payload JSON NOT NULL,            -- flexible payload
  correlation_id TEXT,              -- request/response pairing
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  processed_at TIMESTAMP,           -- null = unprocessed
  metadata JSON                     -- tracing, causation, user_id
);
CREATE INDEX idx_unprocessed ON messages(agent_id, processed_at) WHERE processed_at IS NULL;
CREATE INDEX idx_correlation ON messages(correlation_id);
CREATE INDEX idx_session ON messages(session_id);

-- Agent state table
CREATE TABLE agent_state (
  agent_id TEXT PRIMARY KEY,
  status TEXT,                      -- running, idle, error
  last_seen TIMESTAMP,
  config JSON,
  metrics JSON
);
```

### Redis Real-time Layer

```redis
# Streams for durable command/event log
XADD project:abc:messages * agent_id seo session_id sess_123 type command payload '{"action":"analyze"}' correlation_id corr_456
XGROUP CREATE project:abc:messages seo_agent 0 MKSTREAM
XREADGROUP GROUP seo_agent consumer_1 COUNT 10 BLOCK 5000 STREAMS project:abc:messages >

# Pub/Sub for live TUI updates
PUBLISH project:abc:tui:events '{"type":"agent_progress","agent":"seo","data":{...}}'
SUBSCRIBE project:abc:tui:events

# Agent registry + heartbeats
HSET project:abc:agents:seo status running last_heartbeat 1234567890 capabilities '["analyze","report"]'
EXPIRE project:abc:agents:seo 30
```

---

## Approach 4: Distributed/Network & Hybrid

*Source: Subagent Analysis 4 — Network/distributed architectures*

### Architecture Comparison

| Dimension | HTTP/SSE | WebSocket | gRPC | UDS/Pipes | MQ/PubSub | stdio/Process | **JSON-RPC + Pluggable Transport** |
|-----------|----------|-----------|------|-----------|-----------|---------------|-------------------------------------|
| **TUI↔Agent fit** | Poor (polling) | Excellent | Excellent | Excellent | Good | Excellent | **Excellent (LSP model)** |
| **Multi-project** | Path routing | Namespaces | Metadata | Socket