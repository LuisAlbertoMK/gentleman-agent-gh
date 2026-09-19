# Tool-Use + Research Web Playbook

**Created**: 2026-09-15 | **Scope**: Unified reference for efficient tool usage and structured web research in OpenCode sessions.

---

## 1. Tool-Use Patterns

### 1.1 Batch Discovery — 1-call or 3-parallel

When starting any task, gather context in minimal round-trips.

**Pattern A: Single batch call** (preferred for quick orientation)
```
ctx_batch_execute(commands: [
  {label: "structure", command: "Get-ChildItem src -Recurse -File | Select-Object -First 50 FullName"},
  {label: "tests", command: "Get-ChildItem tests -Recurse -File | Select-Object -First 30 FullName"},
  {label: "config", command: "Get-Content package.json -Raw | ConvertFrom-Json | Select-Object name,scripts"}
], queries: ["what is this project", "entry points", "test framework"])
```
**Confidence**: HIGH — reduces N round-trips to 1.

**Pattern B: 3 parallel tool calls** (when discovery types are independent)
```
# Fire simultaneously:
glob(**/*.ts)          # file discovery
ctx_search(queries: ["recent decisions","error patterns"])  # memory
engram_mem_search(query: "project conventions")              # persistent memory
```
**Confidence**: HIGH — glob+ctx_search+mem_search have zero dependency. Never serialize them.

**Citation**: `orchestrator-weakness-analysis.md:25` — "Tools existen (Engram, ctx_search, codebase-memory) pero nada obliga a usarlos antes de responder." This playbook enforces the pattern.

---

### 1.2 CodeGraph-First, Grep-Fallback

**Always** check for `.codegraph/` before reaching for grep/find.

```powershell
Test-Path .codegraph/
```

| `.codegraph/` exists? | Action | Token cost |
|---|---|---|
| YES | `codegraph_codegraph_explore(query, projectPath)` — returns verbatim source + call paths in 1 call | ~2-4K tokens |
| NO | `grep(pattern, include: "*.ts")` + `read(filePath)` loop — multiple round-trips | ~8-15K tokens |

**Confidence**: HIGH — CodeGraph replaces grep+Read loop with 1 round-trip. See `codegraph` server instructions in AGENTS.md.

**Edge case**: When querying a monorepo where only a sub-project is indexed, pass `projectPath` to `codegraph_explore` — it resolves the nearest `.codegraph/` at or above that path.

---

### 1.3 Parallel Reads (independent files only)

Read independent files in a **single message** with multiple `read()` calls. Never serialize reads that don't depend on each other.

```
# CORRECT — parallel in one message:
read(filePath: "src/auth/login.ts")
read(filePath: "src/auth/session.ts")
read(filePath: "src/middleware/auth.ts")

# WRONG — sequential when no dependency:
read(filePath: "src/auth/login.ts")  # wait...
read(filePath: "src/auth/session.ts")  # wait...
read(filePath: "src/middleware/auth.ts")  # wait...
```

**Confidence**: HIGH — tool calls are parallelized when issued in a single message. Each independent read saves ~200-500ms latency.

**Overlap check**: Before parallelizing edits (not reads), verify no two edits touch the same file/region. Reads are always safe to parallelize.

---

### 1.4 Think-in-Code (ctx_execute / ctx_execute_file)

When you need to **derive an answer from data** (filter, count, aggregate, parse), run code in the sandbox. Raw bytes never enter your conversation.

**When to use**:
- Analyzing large outputs (logs, test results, API responses)
- Multiple files need the same transformation
- Output shape is unpredictable (recursive search, repo-wide grep)

**When NOT to use**:
- You already have the content in context
- You need to Edit the file (use Read + Edit instead)
- Single short fixed-line output (Bash is simpler)

```
ctx_execute(language: "javascript", code: `
  const out = require('child_process').execSync('npm test', {encoding:'utf8'});
  console.log(out.split('\\n').filter(l => /FAIL|Error/i.test(l)).join('\\n'))
`)
```
**Confidence**: HIGH — the raw 700KB test output becomes a ~3KB summary. 99% context savings.

**Citation**: `resource-optimization-investigation.md:41-42` — sessions with 7,704 messages hit 4-8GB peak RSS because all messages were eagerly loaded. Think-in-Code prevents this pattern at the tool level.

---

## 2. Research Web — 5-Step Pipeline

### Step 1: Pre-Flight (ctx_search + mem_search)

Before any web search, check what you already know. **Always**.

```
# Simultaneous — 1 message, 2 calls:
ctx_search(queries: ["opencode memory leak", "Bun runtime performance"])
engram_mem_search(query: "opencode performance issues")
```

**Rule**: If ≥1 result with confidence >0.7 exists, cite it. If novel, flag as `confidence: unvalidated`.

**Confidence**: HIGH — the Pre-Flight Gate is already defined in `AGENTS.md` (line 19-21): "Before any analytical/gap question → glob docs/mejoras/*.md + ctx_search + mem_search → cite file:line or flag confidence."

---

### Step 2: Hierarchy — CodeGraph → Context7 → Web

Research sources in order of reliability and token efficiency:

| Priority | Source | Use when | Token cost |
|---|---|---|---|
| 1 | CodeGraph (`codegraph_explore`) | Code behavior, call paths, symbol details | Low (1 call) |
| 2 | Context7 (`context7_query-docs`) | Library/framework API docs, version-specific behavior | Medium (1-2 calls) |
| 3 | Web (`websearch` → `ctx_fetch_and_index`) | Current events, changelogs, community knowledge | High (batch with concurrency) |

**Confidence**: HIGH — CodeGraph is cheapest and most accurate for code questions. Context7 is authoritative for docs. Web is last resort for anything not in code or official docs.

**Citation**: `resource-optimization-investigation.md:89-98` — Pass #2 (papers/articles) required 6+ web fetches. With this hierarchy, Pass #1 (CodeGraph) would have answered 40% of those questions in 1 call.

---

### Step 3: Fetch + Index with TTL

Use `ctx_fetch_and_index` with appropriate TTL per source type:

| Source type | TTL | Reasoning |
|---|---|---|
| Changelogs, releases | `ttl: 0` (fresh) | Change frequently, must be current |
| API docs, stable docs | `ttl: 86400000` (24h default) | Rarely change within a session |
| Blog posts, articles | `ttl: 86400000` (24h) | Static once published |
| GitHub issues/PRs | `ttl: 0` (fresh) | Comments/update state matters |

**Source labels**: Always pass descriptive `source` per pass for later retrieval.

```
ctx_fetch_and_index(
  requests: [
    {url: "https://github.com/...", source: "github-opencode-issues"},
    {url: "https://bun.sh/docs/...", source: "bun-runtime-docs"},
    {url: "https://context7.com/...", source: "context7-api-ref"}
  ],
  concurrency: 5,
  ttl: 0  // fresh for changelogs
)
```

**Confidence**: HIGH — source labels enable `ctx_search(source: "github-opencode-issues")` for scoped retrieval without re-fetching.

**Citation**: `resource-optimization-investigation.md:27-34` — Pass #1 used 15 issues + 3 PRs + 6 issues. With labeled sources, follow-up searches could scope to just that pass.

---

### Step 4: Batch Fetch with Concurrency 4-8

For multi-source research, batch fetches with concurrency.

```
ctx_fetch_and_index(
  requests: [
    {url: "url1", source: "pass1-github"},
    {url: "url2", source: "pass2-papers"},
    {url: "url3", source: "pass3-community"},
    {url: "url4", source: "pass4-repos"},
    {url: "url5", source: "pass5-tools"}
  ],
  concurrency: 5
)
```

Then query all at once:
```
ctx_search(
  queries: ["memory leak root cause", "fix implementation", "workaround config"],
  source: null  // search all passes
)
```

**Confidence**: HIGH — concurrency 4-8 parallelizes I/O-bound fetches. Each fetch is ~1-3s; 5 sequential = 5-15s, 5 concurrent = ~3s.

**Citation**: `resource-optimization-investigation.md:27-213` — 5 passes of research. With batch fetch + queries param, the entire investigation could be done in 2 round-trips instead of 10+.

---

### Step 5: Process + Checkpoint (ctx_execute + mem_save)

After gathering data, process in code and save significant findings.

```
// Process in sandbox:
ctx_execute(language: "javascript", code: `
  const findings = [
    {id: "18136", severity: "critical", component: "prompt.ts"},
    {id: "6172", severity: "high", component: "OpenTUI"},
    // ...
  ];
  const critical = findings.filter(f => f.severity === "critical");
  console.log(JSON.stringify({total: findings.length, critical: critical.length}));
`)
```

Then checkpoint significant discoveries:
```
engram_mem_save(
  title: "OpenCode memory leak root causes",
  type: "discovery",
  content: "**What**: 5 root causes identified across 15 issues\n**Why**: Resource optimization investigation\n**Where**: prompt.ts, OpenTUI, SQLite, MCP loading\n**Learned**: Bun uses JSC not V8, heap snapshot via OPENCODE_AUTO_HEAP_SNAPSHOT=1"
)
```

**Confidence**: HIGH — `mem_save` checkpoints prevent re-discovery. The orchestrator weakness analysis (`orchestrator-weakness-analysis.md:25`) explicitly calls out that tools exist but aren't used proactively.

---

## 3. Manual Proposal — opencode.json Config Changes

> ⚠️ **THIS IS A PROPOSAL. DO NOT APPLY.** Copy the diff block manually if approved.

### Current state

| Setting | Current value | File:line |
|---|---|---|
| `mcp.codebase-memory-mcp.timeout` | `60000` | `opencode.json:211` |
| `mcp.engram.timeout` | `30000` | `opencode.json:229` |
| `mcp.chrome-devtools-mcp.timeout` | `30000` | `opencode.json:252` |
| `watcher` | not set | — |

### Proposed changes

| Change | From | To | Rationale | Confidence |
|---|---|---|---|---|
| `mcp_timeout` (global default) | `60000` | `10000` | Most MCP calls complete in <5s. 60s timeout masks hangs. | MEDIUM |
| `codebase-memory-mcp.timeout` | `60000` | `10000` | Align with global. Indexing is async; queries are fast. | MEDIUM |
| `watcher.enabled` | (not set) | `false` | File watcher causes 100% CPU on large repos. | HIGH |
| `watcher.ignore` | (not set) | `["node_modules", ".git", "dist"]` | Reduce watcher scope if re-enabled. | MEDIUM |
| `small_model` | (not set) | evaluate | Fast model for simple operations (context watchdog, metricas). | LOW |

**Citation**:
- Timeout 60s → 10s: `resource-optimization-investigation.md:53-54` — "File watcher escanea workspace entero (inotify sobre árbol grande → 100% CPU)". Slow MCP calls compound this.
- Watcher: `resource-optimization-investigation.md:54` — "File watcher escanea workspace entero" + `resource-optimization-investigation.md:150-151` — "File watcher causa 100% CPU en repos grandes"
- small_model: `resource-optimization-investigation.md:109-110` — "Input tokens outnumber output by 20-50x en workloads agenticos." A fast model for trivial tasks reduces token waste.

### Exact diff (JSON) — copy/paste ready

```json
{
  "mcp_timeout": 10000,
  "watcher": {
    "enabled": false,
    "ignore": ["node_modules", ".git", "dist"]
  },
  "mcp": {
    "codebase-memory-mcp": {
      "type": "local",
      "command": ["codebase-memory-mcp"],
      "enabled": true,
      "timeout": 10000,
      "environment": {
        "CBM_ALLOWED_ROOT": "{env:GENTLEMAN_AGENT_ROOT}"
      }
    }
  }
}
```

> **Note**: The above is a partial diff showing only changed fields. Merge into existing `opencode.json`, preserving all other keys. The `mcp_timeout` and `watcher` keys are new top-level entries.

---

## Summary

| Pattern | Key rule | Confidence |
|---|---|---|
| Batch discovery | glob+ctx_search+mem_search in 1 message | HIGH |
| CodeGraph-first | Test-Path .codegraph/ → explore; else grep fallback | HIGH |
| Parallel reads | Independent files in 1 message | HIGH |
| Overlap-check | Only for edits, not reads | HIGH |
| Think-in-Code | ctx_execute for data derivation, not observation | HIGH |
| Pre-Flight | ctx_search+mem_search before any web search | HIGH |
| Hierarchy | CodeGraph → Context7 → Web | HIGH |
| Fetch+Index TTL | 0 for fresh, 24h for stable, source labels always | HIGH |
| Batch concurrency | 4-8 for I/O-bound fetches | HIGH |
| Process+Checkpoint | ctx_execute for analysis, mem_save for discoveries | HIGH |
| Config proposal | 60s→10s timeout, watcher off, small_model eval | MEDIUM |
