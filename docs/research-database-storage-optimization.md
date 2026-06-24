# Database/Storage Optimization: SQLite + Effect/Drizzle for Agent Workloads

> Research synthesis for **opencode-vmk** (TypeScript/Bun, `@effect/sql-sqlite-bun`, `drizzle-orm`) and **gentleman-vMK** (PowerShell/embedded).  
> 35+ sources consulted across 8 domains. June 2026.

---

## Table of Contents

1. [SQLite PRAGMA Tuning](#1-sqlite-pragma-tuning)
2. [Effect SQL Patterns (`@effect/sql-sqlite-bun`)](#2-effect-sql-patterns)
3. [Drizzle ORM Query Optimization](#3-drizzle-orm-query-optimization)
4. [SQLite Driver Comparison](#4-sqlite-driver-comparison)
5. [Embedded vs Client-Server (libSQL/Turso/cr-sqlite)](#5-embedded-vs-client-server)
6. [Migration Performance (drizzle-kit)](#6-migration-performance)
7. [Flash/SSD Wear & Atomic Writes ("Toaster" Constraints)](#7-flash-constraints)
8. [Agent Memory: FTS5, Vector Search, Semantic Indexes](#8-agent-memory-search)
9. [Consolidated Recommendation for opencode-vmk](#9-consolidated-recommendations)

---

## 1. SQLite PRAGMA Tuning

### Current State in opencode-vmk (`packages/core/src/database/database.ts`)

```typescript
PRAGMA journal_mode = WAL
PRAGMA synchronous = NORMAL       // already optimal
PRAGMA busy_timeout = 5000
PRAGMA cache_size = -64000         // 64 MB
PRAGMA foreign_keys = ON
PRAGMA wal_checkpoint(PASSIVE)
```

**Assessment**: Good baseline. Missing `mmap_size`, `temp_store`, `journal_size_limit`, `wal_autocheckpoint`, `page_size` (set at DB creation).

### Benchmark Data (WAL vs DELETE Journal)

| Config | Inserts/sec | Reads/sec | p90 Latency | p99 Latency |
|--------|------------|-----------|-------------|-------------|
| DELETE + synchronous=FULL | 279 | 73,800 | 14 µs | ~50 µs |
| WAL + synchronous=FULL | 442 | 332,225 | 4 µs | ~20 µs |
| **WAL + synchronous=NORMAL** | **33,135** | **483,558** | **3 µs** | **~8 µs** |
| WAL + synchronous=OFF | 61,994 | — | — | — |

*Source: marending.dev, travishorn.com, botmonster.com benchmarks*

**Key finding**: WAL + synchronous=NORMAL is **119× faster for writes** than the default rollback journal config. The p90 drops from 14 µs to 3 µs primarily because NORMAL defers fsync to checkpoint time instead of per-commit.

### Synchronicity Tradeoffs in WAL Mode

| synchronous | Durability | Writes/sec | Use Case |
|-------------|-----------|-----------|----------|
| FULL (default in WAL) | Full — durable across power loss | ~442 | Banking, payments |
| **NORMAL** | **Atomic across crash; last txn may rollback on power loss** | **~33,135** | **Agent sessions, caches, event logs** |
| OFF | Corruptible on crash | ~61,994 | Temp/cache data only |

**Verdict**: synchronous=NORMAL is correct for agent workloads. Per SQLite docs: "the database remains consistent after crashes, but the most recent transactions may be lost during power failure." Acceptable for session state and chat history.

### Optimal PRAGMA Set for Agent Workloads

```sql
PRAGMA journal_mode = WAL;                    -- set once, persistent
PRAGMA synchronous = NORMAL;                  -- per connection
PRAGMA cache_size = -64000;                   -- 64 MB per connection
PRAGMA mmap_size = 268435456;                 -- 256 MB (desktop); 64 MB for constrained
PRAGMA busy_timeout = 5000;                   -- 5s spin-wait before SQLITE_BUSY
PRAGMA foreign_keys = ON;
PRAGMA temp_store = MEMORY;                   -- temp tables in RAM
PRAGMA journal_size_limit = 67108864;         -- 64 MB cap on WAL file
PRAGMA wal_autocheckpoint = 4000;             -- checkpoint at ~16 MB (vs default 4 MB)
PRAGMA wal_checkpoint(PASSIVE);               -- initial cleanup
PRAGMA optimize;                              -- run at connection close or daily
```

### mmap_size Guidelines

| RAM Available | Recommended mmap_size | Notes |
|--------------|----------------------|-------|
| ≤512 MB | 64 MB (67108864) | Match to cache_size; avoid OOM |
| 1-2 GB | 256 MB (268435456) | Good for most agent use |
| 4+ GB | 1 GB (1073741824) | Server/desktop deployments |
| 32-bit systems | ≤1 GB | Address space limited |

> **Why mmap**: Eliminates `read()` syscalls for hot pages. The OS manages cache via virtual memory. On NVMe, hybrid cache_size+mmap yields 10-100× faster cache-hit queries vs cache misses.  
> **Pitfall**: Don't set both cache_size AND mmap_size aggressively — you get duplicate caching. Prefer cache_size for write-heavy, mmap for read-heavy. Agent workloads are read-moderate, so moderate mmap (256 MB) + moderate cache (64 MB) is correct.

### page_size

- Default since SQLite 3.12 (2016): **4096 bytes** ← already correct
- 4096 is optimal for mixed agent workloads (session data rows are typically 200-2000 bytes each)
- 8192 may help for very large JSON blobs in `data` columns (>4 KB per row)
- Cannot change after DB creation without dump+reload + VACUUM

### cache_size Leveling

| DB Size | cache_size | Rationale |
|---------|-----------|-----------|
| <100 MB | -32000 (32 MB) | Sufficient for hot set |
| 100 MB-1 GB | -64000 (64 MB) | Good for active agent sessions |
| 1-10 GB | -262144 (256 MB) | Large conversation stores |

> **IMPORTANT**: `cache_size` is PER CONNECTION. With Semaphore(1) in opencode-vmk, only one connection active → 64 MB is fine. If multiple DBs or connections, multiply.

---

## 2. Effect SQL Patterns (`@effect/sql-sqlite-bun`)

### Current Architecture (opencode-vmk)

**File**: `packages/core/src/database/sqlite.bun.ts` (200 lines), also `packages/effect-sqlite-node/src/index.ts` (184 lines)

```typescript
// Core pattern: Semaphore(1) serializes all DB access
const semaphore = yield* Semaphore.make(1)
const acquirer = semaphore.withPermits(1)(Effect.succeed(connection))
const transactionAcquirer = Effect.uninterruptibleMask((restore) => {
  const fiber = Fiber.getCurrent()!
  const scope = Context.getUnsafe(fiber.context, Scope.Scope)
  return Effect.as(
    Effect.tap(restore(semaphore.take(1)), () => Scope.addFinalizer(scope, semaphore.release(1))),
    connection,
  )
})
```

**Key observations**:
- Single connection, serialized via Semaphore(1) — correct for SQLite
- Statement cache: LRU Map with 64 entries — adequate for hot queries
- `executeStream` not implemented — returns `Stream.die("not implemented")`
- WAL enabled by default unless `disableWAL: true`
- Drizzle ORM layered on top via `drizzle({ client: native })`

### Connection Pooling: SQLite CANNOT Pool

Unlike PostgreSQL, SQLite has **no connection pooling** — each instance is a file handle. The Effect `@effect/sql` pool config (`min`, `max`, `timeToLive`) applies only to server-based adapters (pg, mysql). For SQLite:

- `@effect/sql-sqlite-bun`: no pool, single `bun:sqlite` connection
- `@effect/sql-sqlite-node`: uses `better-sqlite3` or `node:sqlite` — also single connection
- Effect `Pool` generic: `Pool.makeWithTTL({acquire, min, max})` — could be used to pool SQLite **files** (e.g., one per agent), but NOT connections to the same file

**For agent workloads with per-agent databases**, Effect `Pool` over SQLite files makes sense:
```typescript
const agentDbPool = Pool.makeWithTTL({
  acquire: Effect.acquireRelease(
    SqliteClient.make({ filename: `agents/${agentId}.db` }),
    (client) => Effect.sync(() => {}), // cleanup
  ),
  min: 0,
  max: 10, // max concurrent agent DBs
  timeToLive: Duration.minutes(30),
})
```

### Transaction Batching via Effect

**Current pattern** (opencode-vmk uses `sql.withTransaction`):

```typescript
yield* sql.withTransaction(
  Effect.gen(function* () {
    yield* sql`INSERT INTO session (...) VALUES (...)`
    yield* sql`INSERT INTO message (...) VALUES (...)`
  })
)
```

**Performance**: Individual INSERTs outside a transaction → ~1,000/sec. Wrapping 100 INSERTs in one transaction → ~50,000+/sec (50× improvement).

**Agent-specific batching strategy**: Batch session message writes into transactions of 10-50 messages:
```typescript
const batchMessages = (messages: Message[]) =>
  sql.withTransaction(
    Effect.forEach(messages, (msg) =>
      sql`INSERT INTO session_message ${sql.insert(msg)}`
    , { concurrency: 1 })
  )
```

### Effect Resource/Scope Patterns

**Three levels of resource management visible in the codebase**:

| Pattern | Where | Purpose |
|---------|-------|---------|
| `Effect.acquireRelease` + `Effect.scoped` | sqlite.bun.ts:180-184 | Native DB lifecycle (open → close) |
| `Layer.scoped` | sqlite.bun.ts:195-200 | Wiring DB into Effect Context |
| `Semaphore(1)` + `Scope.addFinalizer` | sqlite.bun.ts:138-147 | Transaction serialization |

**Recommended additions**:
- **`Effect.Service` pattern** for the Database service (currently uses raw Layer)
- **`Pool.makeWithTTL`** if pooling per-agent database files
- **`sql.onDialect`** for multi-runtime (bun vs node) — already partially done via `#sqlite` import alias

### executeStream Gap

`executeStream` returns `Stream.die("not implemented")` in both bun and node implementations. For agent workloads that stream tool outputs or long responses, this means **no backpressure support**. If streaming queries become needed, implement via:
- `Stream.async` + `statement.iterate()` (node:sqlite has `iterate` since v23.4)
- `Stream.fromAsyncIterable` wrapping bun's query generator

---

## 3. Drizzle ORM Query Optimization

### Prepared Statements (Highest Impact)

```typescript
// ❌ Without prepared (full SQL planning every call)
const user = await db.select().from(users).where(eq(users.id, id))

// ✅ With prepared (30-60% faster for repeated queries)
const getUser = db.select()
  .from(users)
  .where(eq(users.id, sql.placeholder('id')))
  .prepare('get_user')
const user = await getUser.execute({ id: 123 })
```

**Benchmark**: Prepared statements reduce query planning overhead by **30-60%**. For hot-path queries like session lookups (called every agent turn), this is material.

### `select()` vs `db.query.findMany()` (Relational Queries)

| Aspect | `select()` | `db.query.findMany()` |
|--------|-----------|----------------------|
| **Type inference** | Full column types | Same (v1.0+) |
| **Relations** | Manual JOINs | Automatic via `with` |
| **SQL generated** | Explicit SELECT columns | JSON aggregation (json_group_array for SQLite) |
| **Performance** | ~same for simple queries | ~20% slower for deep nesting due to subqueries |
| **Use case** | Filter/aggregate/computed fields | Nested relations, session + messages |

**Rule**: Use `select()` when you need WHERE, GROUP BY, computed columns. Use `.query.findMany()` when loading session+message+part hierarchies.

### Relational Query Performance Pitfalls (SQLite)

Drizzle's relational query builder uses `json_group_array()` for SQLite. For nested relations:

```sql
-- Generated for db.query.sessions.findMany({ with: { messages: true } })
SELECT sessions.*, coalesce(
  json_group_array(json_array(messages.id, messages.data)) FILTER (WHERE messages.id IS NOT NULL),
  '[]'
) as messages
FROM sessions
LEFT JOIN messages ON sessions.id = messages.session_id
GROUP BY sessions.id
```

**Issues**:
- `json_group_array` with large message bodies (JSON text columns) serializes/deserializes
- Without `limit` on nested relations, a session with 10K messages generates a giant JSON array
- `ORDER BY` inside subqueries requires a window function (`row_number()`) unless `limit` is present

**Mitigation**: Always specify `limit` on one-to-many relations:
```typescript
db.query.sessions.findMany({
  with: {
    messages: {
      limit: 50,        // ← prevents giant arrays
      orderBy: [desc(messages.timeCreated)],
    }
  }
})
```

### N+1 Prevention

```typescript
// ❌ N+1: 1 query for sessions + N queries for messages
const sessions = await db.select().from(sessions)
for (const s of sessions) {
  s.messages = await db.select().from(messages).where(eq(messages.sessionId, s.id))
}

// ✅ O(1): single query with relation
const sessions = await db.query.sessions.findMany({
  with: { messages: true }
})
// OR with explicit JOIN + manual grouping (lower overhead):
const rows = await db.select()
  .from(sessions)
  .leftJoin(messages, eq(sessions.id, messages.sessionId))
```

### Partial Column Select

```typescript
// ❌ Selects ALL columns including large JSON data fields
db.select().from(users)

// ✅ Selects only needed columns — less memory, less I/O
db.select({ id: users.id, name: users.name }).from(users)
```

For agent session queries where you only need metadata (not full message bodies), explicit column selection cuts I/O by 5-50× depending on blob size.

### Index Strategy from Schema Analysis

Current indexes in `session.sql.ts`:

| Table | Indexes | Coverage |
|-------|---------|----------|
| session | project_id, workspace_id, parent_id | Adequate for lookups |
| message | (session_id, time_created, id) | Good for timeline queries |
| part | (message_id, id), session_id | Good |
| session_message | Unique on (session_id, seq) + 3 others | **Gaps for full-text search** |
| event | (aggregate_id, seq), (aggregate_id, type, seq) | Good for event sourcing |

**Missing**: FTS5 indexes for message/part data columns (see Section 8).

---

## 4. SQLite Driver Comparison

### Benchmarks (Node.js v25, Linux, i9-12900K)

| Operation | better-sqlite3 | node:sqlite | bun:sqlite | libSQL |
|-----------|---------------|-------------|------------|--------|
| getUserById (single row) | 1,223,260 ops/s | 1,073,001 ops/s | ~1,500,000* | 61,093 ops/s |
| countPostsByUser (pluck) | 1,151,783 ops/s | 689,478 ops/s | ~1,400,000* | 111,824 ops/s |
| insertUser | 53,693 ops/s | 41,291 ops/s | ~50,000* | 28,385 ops/s |
| insertUser (WAL+NORMAL) | ~51080 ops/s | — | **957*** | — |
| Point query (cached stmt) | 476,190 ops/s | 188,679 ops/s | ~500,000* | — |

*Sources: sqg.dev, takymt/node-builtin-sqlite-bench, oven-sh/bun benchmarks*

**\* bun:sqlite caveat**: bun:sqlite's write performance has been inconsistent. Bun v1.0.29 showed only 957 writes/sec vs better-sqlite3's 51,080 writes/sec on SSD. This was a `PRAGMA synchronous` default issue (bun defaults to FULL). With `PRAGMA synchronous = NORMAL`, bun:sqlite matches or exceeds better-sqlite3. **Current Bun v1.3.x has largely resolved this — but verify in your specific Bun version.**

### Driver Decision Matrix

| Dimension | bun:sqlite | node:sqlite | better-sqlite3 | libSQL |
|-----------|-----------|-------------|----------------|--------|
| **Runtime** | Bun-only | Node 22.5+ | Both (native addon) | Both |
| **Setup** | Built-in | Built-in (experimental) | npm install w/ prebuild | npm install |
| **API** | Synchronous | Synchronous | Synchronous | Async |
| **Speed (reads)** | ★★★★★ | ★★★★ | ★★★★★ | ★★★ |
| **Speed (writes)** | ★★★★ | ★★★★ | ★★★★★ | ★★★ |
| **Cross-runtime** | No | No | Yes (via addon) | Yes |
| **Memory** | ~15 MB RSS | ~20 MB RSS | ~25 MB RSS (prebuild) | ~30 MB RSS |
| **FTS5** | Full | Full | Full | Limited |
| **sqlite-vec** | Via extension | Via extension | Via extension | Built-in vector |
| **Maintenance** | Bun team | Node.js team | Maintenance mode | Active |

### Recommendation for opencode-vmk

**Current choice** (dual runtime via `#sqlite` alias): **Correct**.

- Bun → uses `bun:sqlite` (fastest on Bun)
- Node → uses `node:sqlite` (zero-dependency, built-in)
- Drizzle layers on top → driver-agnostic queries

This is the right architecture. The one gap: add **better-sqlite3 as fallback** for environments where neither built-in is available.

### Cross-Runtime Compatibility (2026 Status)

- `bun:sqlite` — only in Bun
- `node:sqlite` — stable since Node 22.13 (no flag needed)
- `better-sqlite3` — maintenance mode, prebuild download at install
- **Practical approach**: runtime detection with `createRequire` (not top-level `import`), normalizing `query()` vs `prepare()` APIs

---

## 5. Embedded vs Client-Server

### Options for Agent Database Sync

| Solution | Architecture | Read Latency | Write Latency | Sync Model | Status |
|----------|-------------|-------------|--------------|------------|--------|
| **Vanilla SQLite** | Single file | <1 ms | <1 ms | None | Production |
| **libSQL Embedded Replicas** | Local replica + remote primary | <1 ms (local) | 150-300 ms (HTTP) | Async page-level | Production (legacy) |
| **Turso Sync** | Local DB + cloud CDC | <1 ms (local) | 80-120 ms (HTTP) | Async logical CDC | Beta (recommended) |
| **Turso Database (Rust rewrite)** | MVCC engine | <1 ms (local) | <1 ms (local + async flush) | CDC + push/pull | Beta |
| **cr-sqlite** | CRDT-based multi-writer | <1 ms | <1 ms (local) | CRDT merge | Experimental |
| **LiteFS** (Fly.io) | FUSE-based replication | <1 ms (local) | <5 ms (local) | Page-level snapshot | Production |
| **Cloudflare D1** | Managed SQLite (edge) | ~5 ms (edge) | 100-200 ms | HTTP API | Production |

### Key Architectural Insight

For agent workloads (opencode-vmk, gentleman-vMK), **embedded SQLite with per-agent files** is the right default. Network round-trips for every query are antithetical to agent latency requirements. However, for multi-machine coordination (e.g., agent memory across devices):

**Turso Sync** (CDC-based, logical changes) is the recommended upgrade path:
- Local-first: reads are sub-ms file I/O
- Writes go to local DB immediately, sync to cloud async
- `push()` / `pull()` protocol — explicit control over sync timing
- 5,000 rows written to cloud + pulled fresh: ~2-3 seconds (vs libSQL ER: ~8-10s)

**When to NOT use embedded sync**: If you need strong consistency across machines, or if write volume exceeds ~1,000 writes/sec per agent.

### Turso/libSQL SDK Compatibility with Effect

```typescript
// Turso embedded replica pattern (async SDK)
import { createClient } from "@turso/database"

const db = createClient({
  path: "./agent.db",
  url: "libsql://your-db.turso.io",
  authToken: process.env.TURSO_TOKEN,
  syncInterval: 60, // seconds
})
```

**Integration with Effect**: Requires wrapping the async SDK in `Effect.promise` + `Effect.acquireRelease`:

```typescript
const tursoLayer = Layer.scoped(
  SqlClient.SqlClient,
  Effect.acquireRelease(
    Effect.promise(() => createClient(config)),
    (client) => Effect.sync(() => client.close()),
  )
)
```

---

## 6. Migration Performance (drizzle-kit)

### Current State

opencode-vmk has **35+ SQLite migrations** in `packages/core/src/database/migration/` (e.g., `20260612174303_project_dir_strategy.ts`). Each uses `Effect.gen` with `tx.run(...)`.

### drizzle-kit Performance Metrics

| Metric | Small (~10 migrations) | Medium (~35 migrations) | Large (~70 migrations) |
|--------|----------------------|------------------------|------------------------|
| **`generate` cold** | ~2 s | ~8 s | ~30 s |
| **`migrate` check** | ~1 s | ~5 s | **~115 s*** |
| **`migrate` apply (1 pending)** | ~0.5 s | ~2 s | ~5 s |
| **Snapshot JSON size** | ~2 MB | ~7 MB | ~28 MB |
| **Commutativity check** | ~0.5 s | ~3 s | ~83-115 s |

*\* Known issue: drizzle-kit#5777 — commutativity check does full Zod parse of every snapshot JSON twice + pairwise diffSnapshots at branch points. The check runs unconditionally even when no migrations are pending.*

### Migration Performance Killers

1. **`drizzle-kit check` commutativity validation**: Each `migration.sql` snapshot (~500 KB) is Zod-parsed twice + diffed pairwise at branch points. For 70 migrations with 5 branch points, this is 83 seconds of single-threaded CPU.
2. **Snapshot `.strict()` validation**: Deeply nested Zod schemas for tables, columns, indexes, FKs, etc. — the most expensive line item.
3. **SQLite ALTER TABLE limitations**: SQLite doesn't support `DROP COLUMN` or `ALTER COLUMN` natively. drizzle-kit handles this via table recreation + data copy, which is slow for large tables.

### Mitigation Strategies

**Strategy A**: Disable commutativity check (if you manage migration ordering manually):
```bash
drizzle-kit migrate --ignore-conflicts
```

**Strategy B**: Split migration snapshots — one per schema domain (session, event, project, etc.).

**Strategy C**: Use the programmatic `migrate()` function from `drizzle-orm/bun-sqlite` directly at startup (bypasses CLI overhead):

```typescript
import { migrate } from "drizzle-orm/bun-sqlite/migrator"
import { drizzle } from "drizzle-orm/bun-sqlite"
import Database from "bun:sqlite"

const sqlite = new Database("opencode.db")
const db = drizzle(sqlite)
migrate(db, { migrationsFolder: "./drizzle" })  // ~2s for 35 migrations
```

**Strategy D**: Use Effect's `DatabaseMigration` (already in opencode-vmk at `packages/core/src/database/migration/`) — written in Effect.gen, bypasses drizzle-kit entirely. **This is already done and is the right approach for the project.**

### Current Effect-based Migration Pattern (Recommended)

```typescript
// packages/core/src/database/migration/20260612174303_project_dir_strategy.ts
export default Effect.fn("migrate-20260612174303")(function* () {
  const db = yield* Database.Service
  yield* db.run("PRAGMA foreign_keys=OFF")
  // ... schema changes ...
  yield* db.run("PRAGMA foreign_keys=ON")
})
```

**This pattern is correct** — it avoids all drizzle-kit overhead. Recommendation: continue using Effect-based migrations, only use drizzle-kit for initial schema generation.

---

## 7. Flash/SSD Wear & Atomic Writes ("Toaster" Constraints)

### Write Amplification Factor (WAF) by Configuration

| Config | WAF (ext4) | WAF (F2FS) | Lifespan (32 GB eMMC) |
|--------|-----------|-----------|----------------------|
| **DELETE journal + FULL sync** | 80-150 | 20-40 | **10-15 months** |
| WAL + FULL sync | 20-40 | 5-10 | 3-5 years |
| **WAL + NORMAL sync** | **15-30** | **3-7** | **4-6 years** |
| WAL + NORMAL + tmpfs | 0.8-1.5 | — | 35+ years |

*Source: smarthometroubleshoot.com research on eMMC wear*

### SQLite Atomic Commit Protocol

SQLite's atomic commit requires **9 precise steps** in rollback journal mode, with fsync barriers at specific points. WAL mode reduces this to **2-3 fsyncs**:

| Step | Rollback Journal | WAL (NORMAL) | WAL (FULL) |
|------|-----------------|-------------|------------|
| 1. Create journal/WAL | yes | yes (append) | yes (append) |
| 2. Write pages to journal | yes | yes (append) | yes (append) |
| 3. **fsync journal/WAL** | **yes** | **no** | **yes** |
| 4. Write pages to DB | yes | deferred to checkpoint | deferred to checkpoint |
| 5. **fsync DB** | **yes** | deferred to checkpoint | deferred to checkpoint |
| 6. Delete/truncate journal | yes | checkpoint only | checkpoint only |
| **Total fsync per commit** | **3-4** | **0** (at commit) | **1** |
| **Total fsync at checkpoint** | — | **1-2** | **1-2** |

### Batch-Atomic Write Support

Modern NVMe SSDs and F2FS support `SQLITE_IOCAP_BATCH_ATOMIC` — allowing SQLite to skip the rollback journal entirely for transactions up to the device's atomic write limit (typically 1-2 MB). When available:
- Journal is kept **in-memory only** (no disk I/O for journal)
- Single `fcntl(BEGIN_ATOMIC_WRITE)` + writes + `fcntl(COMMIT_ATOMIC_WRITE)`
- Zero write amplification for small transactions

**Check support**:
```sql
-- Returns the sector size (4096 = 4K advanced format)
PRAGMA page_size;

-- Linux: check device atomic write limits
cat /sys/block/nvme0n1/queue/atomic_write_unit_max
```

### Minimizing Flash Wear for Agent Workloads

| Technique | WAF Reduction | Effort | Notes |
|-----------|--------------|--------|-------|
| WAL + synchronous=NORMAL | 5-10× vs DELETE | Low | Already done |
| Batch transactions | 10-50× fewer fsyncs | Low | Batch message inserts |
| Use F2FS instead of ext4 | 2-5× additional | Medium | Requires reformat |
| `journal_size_limit` | Prevents unbounded WAL | Low | Set 64 MB cap |
| Periodic checkpoint | Reduces WAL read overhead | Low | Schedule via cron |
| `temp_store=MEMORY` | Eliminates temp file I/O | Low | Already recommended |

### Agent Workload Write Profile

Typical agent session (~1 hour):
- Session metadata: 1 INSERT
- Messages: 10-50 INSERTs
- Message parts: 20-100 INSERTs
- Events: 5-20 INSERTs
- **Total: ~100 writes per session-hour**

At this rate, with WAL+NORMAL on ext4 (WAF ~20):
- Per session: ~2,000 pages of flash writes (8 MB)
- Per year (1,000 sessions): ~8 GB → negligible wear on a 256 GB SSD

**Conclusion**: Flash wear is not a concern for agent workloads on modern SSDs. Only relevant for constrained eMMC (Raspberry Pi, thin clients) where WAF mitigation matters.

---

## 8. Agent Memory: FTS5, Vector Search, Semantic Indexes

### Current State in opencode-vmk

**No FTS5 or vector search implemented.** The `session_message` table stores `data` as JSON text with no search index. Agent memory retrieval is limited to exact ID lookups.

### FTS5 Performance for Agent Memory

| Metric | 1,000 entries | 10,000 entries | 100,000 entries |
|--------|--------------|---------------|-----------------|
| **FTS5 search (BM25)** | 0.07 ms | 0.12 ms | 0.20 ms |
| **LIKE '%term%'** | 50 ms | 500 ms | 5,000 ms |
| **FTS5 index size** | ~1 MB | ~10 MB | ~100 MB |
| **DB file size** | 3.2 MB | 32 MB | 320 MB |
| **FTS5 speedup vs LIKE** | 714× | 4,166× | 25,000× |

*Sources: simple-memory-mcp benchmarks, agent-memory-store docs*

**Key insight**: FTS5 scales **sub-linearly** — doubling memories does NOT double search time. The `porter unicode61` tokenizer handles stemming and Unicode.

### Hybrid Search Architecture (FTS5 + Vector)

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  User Query  │────▶│  FTS5 (BM25)  │────▶│             │
└─────────────┘     └──────────────┘     │   RRF Merge  │
                    ┌──────────────┐     │  (Reciprocal │
                    │  sqlite-vec   │────▶│  Rank Fusion)│
                    │  (KNN/cosine) │     └──────┬──────┘
                    └──────────────┘            │
                                         ┌──────▼──────┐
                                         │  Top-K to   │
                                         │  Agent Ctx  │
                                         └─────────────┘
```

### sqlite-vec Extension

| Feature | Status | Details |
|---------|--------|---------|
| **Extension type** | C (no dependencies) | Works on all platforms |
| **Vector types** | float[ ], int8[ ], binary[ ] | Up to 65K dimensions |
| **Index** | Brute force (exact) | No HNSW yet (planned) |
| **Metadata** | Up to 16 metadata columns | WHERE constraints during KNN |
| **Partition keys** | Yes | Shard indices per agent/user |
| **Auxiliary columns** | Yes | Store raw text alongside vectors |
| **npm package** | `sqlite-vec` | Prebuilt binaries for Node/Bun |
| **Load in bun** | `db.loadExtension("vec0")` | Requires `.dll`/`.so`/`.dylib` |

### Implementation for Agent Memory (Recommended)

**FTS5 on session_message.data**:
```sql
-- FTS5 external content table
CREATE VIRTUAL TABLE message_fts USING fts5(
  content,
  session_id UNINDEXED,
  message_id UNINDEXED,
  tokenize='porter unicode61',
  content='session_message',
  content_rowid='rowid'
);

-- Sync trigger
CREATE TRIGGER message_fts_insert AFTER INSERT ON session_message BEGIN
  INSERT INTO message_fts(rowid, content, session_id, message_id)
  VALUES (new.rowid, new.data, new.session_id, new.id);
END;
```

**Vector search on embedded memories** (for Engram):
```sql
CREATE VIRTUAL TABLE memory_vectors USING vec0(
  memory_id INTEGER PRIMARY KEY,
  embedding FLOAT[384],  -- MiniLM-L6-v2
  memory_type TEXT,
  agent_id TEXT PARTITION KEY
);

-- KNN query
SELECT memory_id, distance
FROM memory_vectors
WHERE embedding MATCH ?
  AND k = 20
  AND agent_id = ?
  AND memory_type = 'decision'
ORDER BY distance;
```

### Hybrid Search Query (RRF)

```sql
WITH vec_matches AS (
  SELECT memory_id, row_number() OVER (ORDER BY distance) AS rank
  FROM memory_vectors
  WHERE embedding MATCH ? AND k = 20
),
fts_matches AS (
  SELECT memory_id, row_number() OVER (ORDER BY rank) AS rank
  FROM message_fts
  WHERE content MATCH ?
  LIMIT 20
),
rrf AS (
  SELECT
    COALESCE(v.memory_id, f.memory_id) AS id,
    COALESCE(1.0 / (60 + v.rank), 0.0) * 0.6 +
    COALESCE(1.0 / (60 + f.rank), 0.0) * 0.4 AS score
  FROM vec_matches v
  FULL OUTER JOIN fts_matches f ON v.memory_id = f.memory_id
)
SELECT * FROM rrf ORDER BY score DESC LIMIT 10;
```

**RRF constant `k=60`** — standard value from literature. Weighting: 60% FTS5, 40% vector (ZeroClaw default).

### Agent Memory Performance Benchmarks

| System | Retrieval | Setup | Infrastructure |
|--------|-----------|-------|---------------|
| **SQLite+FTS5** | **<1 ms** | **0 min** | **$0** |
| sqlite-vec (hybrid) | 1.2 ms | 5 min | $0 |
| ChromaDB (local) | 2.1 ms | 15 min | ~$0 |
| Weaviate (local) | 4.8 ms | 30 min | ~$0 |
| Pinecone (cloud) | 15-50 ms | 15 min | $70-700/mo |

**agent-memory-store Recall@5**: 92.1% (no LLM calls). Compares to Mastra with GPT-4o-mini at 94.87% (with API costs).

### Engram Integration Points

| Engram Feature | Storage | Search | Recommendation |
|---------------|---------|--------|---------------|
| FTS5 full-text | `message_fts` virtual table | BM25 ranking | Add now (no deps) |
| Vector semantic | `memory_vectors vec0` table | Cosine KNN | Add when sqlite-vec stable |
| Recent/pinned | `session_context_epoch` table | time_created DESC | Already done |
| Session summary | `session_message` (type=summary) | metadata filter | Already done |
| Cross-session (dreaming) | Hybrid FTS5 + vec | RRF merge | Phased: FTS5 first, vectors later |

---

## 9. Consolidated Recommendations

### Immediate (No Dependencies)

| # | Change | File | Impact |
|---|--------|------|--------|
| 1 | Add `PRAGMA mmap_size = 268435456` | `database.ts:27-32` | Reduces read syscalls, faster hot queries |
| 2 | Add `PRAGMA temp_store = MEMORY` | `database.ts:27-32` | Eliminates temp file I/O |
| 3 | Add `PRAGMA journal_size_limit = 67108864` | `database.ts:27-32` | Caps WAL at 64 MB |
| 4 | Add `PRAGMA wal_autocheckpoint = 4000` | `database.ts:27-32` | Reduces checkpoint frequency |
| 5 | Prepare hot queries (session lookup, message fetch) | Drizzle queries | 30-60% faster repeated queries |

### Short-Term (Medium Effort)

| # | Change | Details |
|---|--------|---------|
| 6 | FTS5 virtual table for `session_message.data` | `CREATE VIRTUAL TABLE message_fts USING fts5(...)` with INSERT/UPDATE/DELETE triggers |
| 7 | Agent-side memory tool using FTS5 | Add MCP tool `search_memories(keyword)` for Engram retrieval |
| 8 | `executeStream` implementation | Wrap `statement.iterate()` for streaming large result sets |
| 9 | Cross-runtime driver normalization | Normalize `query()` vs `prepare()` API between bun:sqlite and node:sqlite |

### Medium-Term (Requires Deps)

| # | Change | Details |
|---|--------|---------|
| 10 | sqlite-vec extension | Load `vec0` extension, add embedding column to Engram memory table |
| 11 | Hybrid search (RRF) | FTS5 BM25 + vector cosine with Reciprocal Rank Fusion |
| 12 | Per-agent database pooling | `Pool.makeWithTTL` if agent isolation is needed |
| 13 | Turso sync for multi-machine | Evaluate Turso Sync if cross-device agent memory becomes needed |

### Effect Resource/Scope Pattern to Add

```typescript
// Recommended: Service-based DB access with scoped lifecycle
class DatabaseService extends Effect.Service<DatabaseService>()("DatabaseService", {
  scoped: Effect.gen(function* () {
    const sql = yield* Client.SqlClient
    yield* Effect.addFinalizer(() => Effect.log("Database layer shutting down"))
    return {
      query: (strings: TemplateStringsArray, ...params: unknown[]) =>
        sql`${sql(strings, ...params)}`,
      transaction: <A>(effect: Effect.Effect<A>) =>
        sql.withTransaction(effect),
      search: (query: string) =>
        sql`SELECT * FROM message_fts WHERE content MATCH ${query} ORDER BY rank LIMIT 10`,
    }
  }),
}) {}
```

### PRAGMA Config Diff (Current → Proposed)

```diff
  PRAGMA journal_mode = WAL;
  PRAGMA synchronous = NORMAL;
  PRAGMA busy_timeout = 5000;
  PRAGMA cache_size = -64000;
+ PRAGMA mmap_size = 268435456;
+ PRAGMA temp_store = MEMORY;
+ PRAGMA journal_size_limit = 67108864;
+ PRAGMA wal_autocheckpoint = 4000;
  PRAGMA foreign_keys = ON;
  PRAGMA wal_checkpoint(PASSIVE);
```

---

## Sources

1. SQLite WAL docs — sqlite.org/wal.html
2. SQLite mmap docs — sqlite.org/mmap.html
3. SQLite PRAGMA docs — sqlite.org/pragma.html
4. SQLite Atomic Commit — sqlite.org/atomiccommit.html
5. SQLite page size change — sqlite.org/pgszchng2016.html
6. marending.dev SQLite benchmarks — "How fast is SQLite?"
7. travishorn.com — "Hands-on Exploration of SQLite for Production"
8. botmonster.com — "SQLite Scales to Production: 10K TPS, WAL Mode"
9. shivekkhurana.com — "SQLite in Production: A Real-World Benchmark"
10. cronfeed.work — "SQLite WAL in 2026: checkpoint starvation"
11. fly.io — "How SQLite Scales Read Concurrency"
12. sqg.dev — "SQLite Driver Benchmark: better-sqlite3 vs node:sqlite vs libSQL vs Turso"
13. photostructure/node-sqlite — library comparison
14. oven-sh/bun — bun:sqlite docs
15. Effect-TS/effect — @effect/sql-sqlite-bun source
16. Effect-TS/deepwiki — Data Persistence docs
17. Drizzle ORM docs — Relational Queries, Performance Optimization
18. drizzle-team/drizzle-orm - performance blog
19. productionhardening.org — cache_size, mmap tuning
20. toolbox365.net — "6 PRAGMAs every production SQLite needs"
21. smarthometroubleshoot.com — SQLite write amplification on eMMC
22. mdpi.com — "ALEX: Adaptive Log-Embedded Extent Layer for Flash"
23. autokaam.com — "I Gave My AI Agents a Memory With SQLite FTS5"
24. agencodex.com — "Production Agent Memory: SQLite Hybrid for Long Context"
25. zeroclaws.io — "How SQLite + FTS5 + Vectors Beat Dedicated Vector DBs"
26. dev.to — "Why SQLite+FTS5 beats Vector DBs for AI Agent Memory"
27. sqlite-memory (sqliteai) — markdown-based agent memory
28. agent-memory-store (vbfs) — MCP memory with hybrid search
29. agentmem (oxgeneral) — lightweight persistent memory
30. simple-memory-mcp (chrisribe) — performance docs
31. Effect-TS Pattern Library — Pool, Scope, Resource Management
32. PaulJPhilp/EffectPatterns — resource management patterns
33. zylos.ai — "SQLite WAL Mode: Patterns and Pitfalls for AI Agent Systems"
34. adhdecode.com — SQLite page size tuning, Turso/libSQL
35. turso.tech — Embedded Replicas, Sync Benchmark
