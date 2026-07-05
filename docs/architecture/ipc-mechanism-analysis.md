# Local IPC Mechanism Analysis: TUI ↔ Agent Communication

## Executive Summary

For a multi-project, multi-agent architecture with opencode/gentleman-vmk agents running locally, **Unix Domain Sockets (UDS) + JSON-RPC 2.0** emerges as the optimal primary mechanism, with **Named Pipes (Windows) / FIFOs (Unix)** as fallback, and **File-based (JSONL)** for durability/audit trail.

---

## Comparison Matrix

| Mechanism | Latency | Reliability | Multi-Project | Multi-Agent/Project | Opencode Compat | Security | Complexity | Best For |
|-----------|---------|-------------|---------------|---------------------|-----------------|----------|------------|----------|
| **Unix Domain Sockets** | ⭐⭐⭐⭐⭐ (<1ms) | ⭐⭐⭐⭐⭐ | ✅ Namespace isolation | ✅ Per-agent sockets | ✅ Native support | ⭐⭐⭐⭐ FS perms | Medium | **Primary choice** |
| **Named Pipes (Win) / FIFOs (Unix)** | ⭐⭐⭐⭐ (~1-2ms) | ⭐⭐⭐⭐ | ✅ Path-based isolation | ✅ Per-agent pipes | ⚠️ Partial | ⭐⭐⭐⭐ FS perms | Medium | Windows fallback |
| **gRPC over UDS** | ⭐⭐⭐⭐ (~1-3ms) | ⭐⭐⭐⭐⭐ | ✅ Service names | ✅ Per-service | ✅ Protobuf contracts | ⭐⭐⭐⭐⭐ TLS+mTLS | High | Strong typing needs |
| **HTTP/localhost** | ⭐⭐⭐ (~5-20ms) | ⭐⭐⭐ | ✅ Port isolation | ⚠️ Port mgmt | ✅ Universal | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ Auth/TLS | Low | Web-compatible |
| **WebSockets (localhost)** | ⭐⭐⭐⭐ (~2-5ms) | ⭐⭐⭐⭐ | ✅ Path isolation | ✅ Subprotocols | ✅ ⭐⭐⭐⭐ | ⭐⭐⭐⭐ Origin checks | Medium | Real-time streaming |
| **Message Queues (Redis/RabbitMQ)** | ⭐⭐⭐ (~5-10ms) | ⭐⭐⭐⭐⭐ | ✅ Vhost/topics | ✅ Consumer groups | ⚠️ Extra dep | ⭐⭐⭐⭐ Auth/ACL | High | Durability/Scale |
| **Shared Memory + Semaphores** | ⭐⭐⭐⭐⭐ (<0.5ms) | ⭐⭐⭐ | ⚠️ Manual isolation | ⚠️ Manual mgmt | ❌ Not native | ⭐⭐ OS perms | Very High | Ultra-low latency |
| **File-based (JSONL/Watch)** | ⭐⭐ (~10-100ms) | ⭐⭐⭐⭐⭐ | ✅ Dir isolation | ✅ Per-agent files | ✅ Native | ⭐⭐⭐⭐ FS perms | Low | Audit/Debug/Durability |
| **D-Bus** | ⭐⭐⭐ (~2-5ms) | ⭐⭐⭐⭐ | ✅ Bus names | ✅ Object paths | ⚠️ Linux only | ⭐⭐⭐⭐ Policy kit | Medium | Desktop integration |

---

## Detailed Mechanism Analysis

### 1. Unix Domain Sockets (UDS) — **RECOMMENDED PRIMARY**

```text
┌─────────────────────────────────────────────────────────────┐
│  Project: /tmp/agent-ipc/{project-slug}/                    │
│  ├── tui.sock              ← TUI listener                    │
│  ├── agents/               │                                 │
│  │   ├── ux.sock           ← UX agent                        │
│  │   ├── security.sock     ← Security agent                  │
│  │   ├── optimization.sock ← Optimization agent              │
│  │   └── seo.sock          ← SEO agent                       │
│  └── bridge.sock           ← Inter-project bridge            │
└─────────────────────────────────────────────────────────────┘
```

**Pros:**
- **Latency**: Sub-millisecond (kernel bypass, no TCP overhead)
- **Isolation**: Filesystem permissions per project/agent
- **Multi-project**: Directory namespace (`/tmp/agent-ipc/project-a/`, `project-b/`)
- **Multi-agent**: One socket per agent, TUI connects to all
- **Opencode compat**: Native `net.Dial("unix", path)` in Go, `net.DialUnix` in Node
- **Reliability**: `SO_PASSCRED` for peer credentials, auto-cleanup on close
- **Streaming**: Native bidirectional streaming, no framing needed

**Cons:**
- Unix-only (Windows needs Named Pipes fallback)
- Requires cleanup on crash (use `SO_REUSEADDR` + PID lock files)
- No built-in protocol (layer JSON-RPC 2.0 or MessagePack)

**Implementation Pattern:**
```go
// Agent side (listener)
l, _ := net.Listen("unix", "/tmp/agent-ipc/myproj/agents/ux.sock")
defer os.Remove(l.Addr().String())

// TUI side (dialer)
conn, _ := net.Dial("unix", "/tmp/agent-ipc/myproj/agents/ux.sock")
```

---

### 2. Named Pipes (Windows) / FIFOs (Unix) — **WINDOWS FALLBACK**

```text
Windows: \\.\pipe\agent-ipc\{project}\{agent}
Unix:    /tmp/agent-ipc/{project}/{agent}.fifo
```

**Pros:**
- Native Windows IPC, works identically to UDS
- Same namespace isolation via path
- Kernel-managed buffering (64KB default)

**Cons:**
- Windows: Max 255 instances per pipe name (use unique names)
- Unix FIFOs: Unidirectional (need pair for bidirectional)
- No `SO_PASSCRED` equivalent on Windows (use ACLs)
- Blocking semantics differ from sockets

**Compatibility**: The Windows agent runner uses Named Pipes natively.

---

### 3. gRPC over Unix Domain Sockets — **TYPED CONTRACTS**

```protobuf
// agent.proto
service Agent {
  rpc Execute(Task) returns (stream Result);
  rpc Subscribe(Filter) returns (stream Event);
  rpc HealthCheck(Ping) returns (Pong);
}
```

**Pros:**
- **Schema-first**: Protobuf contracts prevent drift
- **Code generation**: Go, TypeScript, Python, Rust clients
- **Built-in**: Streaming, deadlines, cancellation, retries
- **Security**: mTLS, token auth interceptors
- **Observability**: OpenTelemetry integration

**Cons:**
- Higher complexity (proto files, codegen, build step)
- ~2-3x latency vs raw UDS (serialization overhead)
- Overkill for simple request/response

**Best for**: Agent↔Agent communication where contracts matter.

---

### 4. HTTP/localhost — **WEB COMPATIBLE**

```text
Project A: http://localhost:38471/  (TUI)
           http://localhost:38472/  (UX Agent)
           http://localhost:38473/  (Security Agent)
Project B: http://localhost:38571/  (TUI)
           ...
```

**Pros:**
- Universal: every language, curl, browser, Postman
- REST/JSON or GraphQL
- Easy debugging, logging, middleware
- Works over SSH tunnels, VPNs

**Cons:**
- Port allocation conflicts (use ephemeral range 49152-65535)
- Higher latency (TCP handshake, HTTP parsing)
- No native streaming (need SSE/WebSocket upgrade)
- TUI must manage multiple HTTP clients

**Opencode compat**: Native HTTP client, but agents would need HTTP servers.

---

### 5. WebSockets (localhost) — **REAL-TIME STREAMING**

```text
ws://localhost:38471/agent/ux
ws://localhost:38471/agent/security
```

**Pros:**
- True bidirectional streaming over single connection
- Binary frames (MessagePack/Protobuf) or text (JSON)
- HTTP upgrade compatible (proxies, load balancers)
- Native in browsers (if TUI ever web-based)

**Cons:**
- Requires HTTP server + upgrade handler
- More complex than raw UDS
- Heartbeat/ping-pong needed for reliability

---

### 6. Message Queues (Redis Streams / RabbitMQ) — **DURABILITY & SCALE**

```text
Redis Streams:
  project:{slug}:tui:commands    ← TUI publishes
  project:{slug}:agent:ux:cmds   ← UX consumes
  project:{slug}:agent:ux:events ← UX publishes
  project:{slug}:bridge          ← Inter-project
```

**Pros:**
- **Durability**: Messages persist across restarts
- **Replay**: Consumer groups, `XREADGROUP`, `XCLAIM`
- **Multi-project**: Redis DBs or key prefixes
- **Multi-agent**: Consumer groups per agent type
- **Scaling**: Horizontal consumers, priority queues

**Cons:**
- Extra infrastructure dependency (Redis/RabbitMQ)
- Higher latency (network hop, serialization)
- Overkill for local-only, low-volume
- Operational complexity

**Best for**: Audit trail, cross-machine, high-volume event sourcing.

---

### 7. Shared Memory + Semaphores — **ULTRA-LOW LATENCY**

```c
// mmap + futex / Windows CreateFileMapping + WaitForSingleObject
struct RingBuffer { 
  atomic_uint head, tail; 
  char data[64KB]; 
};
```

**Pros:**
- Fastest possible (<0.5μs)
- Zero-copy (direct memory access)
- No syscalls in hot path

**Cons:**
- **Extreme complexity**: Manual synchronization, crash recovery
- No isolation (same memory space = security risk)
- Platform-specific (mmap vs MapViewOfFile)
- No built-in protocol, framing, or discovery
- Debugging nightmare

**Verdict**: Only for HFT-style latency requirements. Not recommended here.

---

### 8. File-based (JSONL + fsnotify) — **AUDIT & DEBUG**

```text
/tmp/agent-ipc/{project}/
├── tui-commands.jsonl      ← TUI writes commands
├── agents/
│   ├── ux-events.jsonl     ← UX agent writes events
│   ├── security-events.jsonl
│   └── ...
└── bridge.jsonl            ← Inter-project
```

**Pros:**
- **Trivial implementation**: `echo '{"cmd":"x"}' >> file`
- **Perfect audit trail**: Complete history, grep-able
- **Crash-proof**: Survives any process death
- **Debugging**: `tail -f` live inspection
- **Language agnostic**: Any tool can read/write

**Cons:**
- Latency: fsnotify ~10-100ms (inotify/kqueue/ReadDirectoryChangesW)
- Polling fallback on network FS
- No built-in request/response correlation
- File rotation needed for long runs

**Best as**: **Supplemental** mechanism for logging/debugging alongside primary IPC.

---

### 9. D-Bus — **LINUX DESKTOP INTEGRATION**

```text
Bus: session
Name: com.gentleman.ProjectName
Path: /com/gentleman/ProjectName/Agent/UX
Interface: com.gentleman.Agent
```

**Pros:**
- System/service activation (auto-start agents)
- Introspection, monitoring (`dbus-monitor`, `bustle`)
- PolicyKit integration for auth
- Language bindings everywhere

**Cons:**
- Linux only (no Windows/macOS native)
- Daemon dependency (`dbus-daemon`)
- Higher latency than UDS
- Complex API for simple needs

---

## Recommended Architecture: Hybrid Approach

```
┌─────────────────────────────────────────────────────────────────┐
│                        TUI APPLICATION                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  IPC Router (per project)                                │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        │   │
│  │  │ UX Agent│ │Security │ │Optimize │ │ SEO     │ ...    │   │
│  │  │  (UDS)  │ │  (UDS)  │ │  (UDS)  │ │  (UDS)  │        │   │
│  │  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘        │   │
│  └───────┼───────────┼───────────┼───────────┼──────────────┘   │
│          │           │           │           │                  │
│          ▼           ▼           ▼           ▼                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  File-based Audit Logger (JSONL) — ALL TRAFFIC          │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    INTER-PROJECT BRIDGE                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Project A   │  │ Project B   │  │ Project C   │  (UDS)      │
│  │  bridge.sock│  │  bridge.sock│  │  bridge.sock│             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

### Protocol: JSON-RPC 2.0 over UDS

```json
// Request (TUI → Agent)
{"jsonrpc":"2.0","id":1,"method":"agent.execute","params":{"task":"analyze","payload":{}}}

// Response (Agent → TUI)
{"jsonrpc":"2.0","id":1,"result":{"status":"ok","data":{}}}

// Notification (Agent → TUI, streaming)
{"jsonrpc":"2.0","method":"agent.event","params":{"type":"progress","data":{}}}
```

---

## Opencode / Gentleman-VMK Integration

| Agent Variant | IPC Support | Notes |
|---------------|-------------|-------|
| **opencode** | HTTP (default), stdin/stdout | Add UDS listener via plugin |
| **gentleman-vmk** | UDS + JSON-RPC 2.0 (recommended) | Full protocol support |

**Integration pattern:**
```yaml
# .opencode/agent-config.yaml
ipc:
  transport: "unix"
  socket: "/tmp/agent-ipc/{project}/{agent}.sock"
  protocol: "jsonrpc2"
  audit:
    enabled: true
    path: "/tmp/agent-ipc/{project}/audit.jsonl"
```

---

## Security Model

```
Filesystem Permissions (Unix):
/tmp/agent-ipc/
├── project-a/          0750 (owner: user, group: agent-group)
│   ├── tui.sock        0660
│   ├── agents/
│   │   ├── ux.sock     0660
│   │   └── security.sock 0660
│   └── audit.jsonl     0640
└── project-b/          0750 (different group or same)

Windows ACLs:
\\.\pipe\agent-ipc\project-a\*
  - User: RW
  - Agent Group: RW
  - Everyone: None
```

**Additional hardening:**
- `SO_PEERCRED` validation on accept (Unix)
- Token-based auth in JSON-RPC params (HMAC)
- mTLS for gRPC variant
- Rate limiting per socket

---

## Implementation Priority

| Phase | Mechanism | Effort | Value |
|-------|-----------|--------|-------|
| 1 | **UDS + JSON-RPC 2.0** | Medium | Core communication |
| 2 | **Named Pipes (Windows)** | Low | Cross-platform parity |
| 3 | **File-based Audit (JSONL)** | Trivial | Debugging, compliance |
| 4 | **gRPC over UDS** | High | Typed agent contracts (v2) |
| 5 | **Bridge Protocol** | Medium | Inter-project communication |

---

## Decision Checklist

- [ ] **Primary**: Unix Domain Sockets + JSON-RPC 2.0
- [ ] **Windows**: Named Pipes fallback (same API abstraction)
- [ ] **Audit**: JSONL file logging for all traffic
- [ ] **Discovery**: Socket directory scanning for agent detection
- [ ] **Health**: Periodic ping/pong on each socket
- [ ] **Reconnect**: Exponential backoff + circuit breaker
- [ ] **Security**: FS perms + optional HMAC tokens
- [ ] **Observability**: Structured logging + metrics per connection