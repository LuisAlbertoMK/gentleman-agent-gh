# Network/I/O Optimization for Agent Tool Execution

**Projects:** gentleman-vMK (gentleman-agent-gh) · opencode-vmk | **Date:** 2026-06-23 | **Status:** Research complete
**Sources:** ~22 across benchmarks, RFCs, production reports (2024-2026)

---

## 1. HTTP Protocol: HTTP/1.1 vs HTTP/2 vs HTTP/3 for LLM API Calls

### 1.1 Protocol Overhead per Request

| Protocol | Transport | Connection setup | Head-of-line blocking | Best for |
|----------|-----------|-----------------|----------------------|----------|
| HTTP/1.1 | TCP | 3-way handshake + TLS (2-3 RTT) | Yes (per-connection) | Simple single requests, compatibility |
| HTTP/2 | TCP (1 conn) | Same as H1, multiplexed after | Yes (TCP-level) | Multiple concurrent reqs to same host |
| HTTP/3 | QUIC/UDP | 0-1 RTT (resumed), 1 RTT (new) | No (stream-level) | High-latency/unreliable networks |

### 1.2 Key Benchmarks

- HTTP/3 loads "over 4× faster than HTTP/1.1 in real-world usage" (Perna et al., *Computer Communications* 2022, tested on Cloudflare/Google infra)
- HTTP/3's QUIC eliminates TCP head-of-line blocking that plagues HTTP/2 multiplexing — a lost packet on HTTP/2 stalls **all** streams; on HTTP/3 only the affected stream stalls
- HTTPS DNS resource records (RFC 9460, SVCB/HTTPS RR) allow connecting via HTTP/3 **without** Alt-Svc handshake, saving 1 RTT

### 1.3 Recommendation

| Project | Protocol | Rationale |
|---------|----------|-----------|
| **gentleman-vMK** | HTTP/1.1 + Keep-Alive | Minimal dep surface, single host, connection reuse sufficient |
| **opencode-vmk** | HTTP/2 with HTTP/3 fallback | Multiple concurrent LLM API calls to same host; H2 multiplexing reduces connections. H3 via QUIC for high-latency/metered "toaster" links |

---

## 2. Connection Pooling: undici vs fetch vs Bun native vs agentkeepalive

### 2.1 Undici Benchmarks (Node 24 — 50 conns, pipelining depth 10)

| Client | HTTP/1.1 (req/sec) | HTTP/1.1 over TLS | HTTP/2 |
|--------|-------------------|-------------------|--------|
| node-fetch | 4,712 | — | — |
| undici.fetch | 5,439 | 3,722 | 3,499 |
| Native http keepalive | 9,343 | 5,634 | — |
| undici.request | **16,851** | **6,670** | **6,831** |
| undici.dispatch | **20,786** | **7,362** | **7,791** |

### 2.2 Pool Sizing for Concurrent Tool Calls

**gentleman-vMK** runs PowerShell → OpenCode host → LLM API sequentially per turn. Peak concurrency: **1-2 requests**.

```plaintext
Pool: max 2 connections per origin, keepAliveTimeout: 10s
Library: Node.js built-in http/https with keepAlive (zero deps)
```

**opencode-vmk** runs multiple concurrent tool calls, subagents, and MCP requests. Peak concurrency: **8-16 simultaneous requests** (est. from 8 subagents × 1-2 API calls each).

```plaintext
Pool: max 16 connections per origin, pipelining: 5, keepAliveTimeout: 30s
Library: undici (native) — undici.Agent with:
  - connections: 16
  - pipelining: 5
  - keepAliveMaxTimeout: 60s
  - keepAliveTimeout: 30s
```

### 2.3 Library Choice Matrix

| Feature | Agent (node:http) | undici dispatcher | Bun.fetch | agentkeepalive |
|---------|------------------|-------------------|-----------|----------------|
| Zero deps | ✅ | ✅ (bundled in Node 18+) | ✅ | ❌ |
| HTTP/2 | ❌ | ✅ | ❌ | ❌ |
| Pipelining config | Manual | ✅ (built-in) | ❌ | Manual |
| Retry interceptor | ❌ | ✅ (RetryAgent) | ❌ | ❌ |
| Connection per-origin | Manual | ✅ (Pool/BalancedPool) | Auto | ✅ |
| Proxy/SOCKS | ❌ | ✅ | ❌ | ❌ |
| Bun-native | ❌ | ❌ (N-API cost) | ✅ (zero copy) | ❌ |

### 2.4 Recommendation

| Project | Library | Why |
|---------|---------|-----|
| **gentleman-vMK** | `node:https` with `agent: new https.Agent({ keepAlive: true, maxSockets: 2 })` | Zero deps, simple sequential model. Keep-alive avoids connection re-establishment. |
| **opencode-vmk** | **undici** with `Agent({ connections: 16, pipelining: 5 })` | 3-4× faster than node-fetch, native HTTP/2, built-in retry, connection pooling. On Bun: use `Bun.fetch` with fallback to undici if HTTP/2 needed. |

---

## 3. Request Batching: JSON-RPC Batch vs GraphQL Batching vs Custom Multiplexing

### 3.1 Comparison

| Approach | Overhead | Latency reduction | Complexity | LLM API support |
|----------|----------|------------------|------------|-----------------|
| **JSON-RPC batch** | ~50 bytes wrapper | High (N requests → 1 round-trip) | Low | OpenAI/Anthropic: NO |
| **GraphQL batching** | Variable (query size) | Medium | High | No native support |
| **Custom multiplexing** | ~100-200 bytes/msg | Medium | High | Requires proxy layer |
| **Concurrent single requests** | ~1KB TCP per req | None (baseline) | None | Universal |

### 3.2 Reality Check

Most LLM providers (OpenAI, Anthropic, Google) do **not** support JSON-RPC batch or GraphQL. Each request is independent.

- **OpenAI batch API**: Separate endpoint, 50% discount, 24h turnaround — good for async/non-blocking work
- **OpenAI /v1/chat/completions**: No batching — concurrent requests are the only option
- **Anthropic Messages API**: No batching

### 3.3 What Actually Works

```plaintext
For synchronous LLM calls (current model):
  → Concurrent Promise.all() with connection pooling
  → Rate limiting via undici RetryAgent with backoff

For async/non-blocking (batch inference, embeddings):
  → OpenAI Batch API (50% cost reduction, 24h TAT)
  → Queue-based submission with periodic status polling
```

### 3.4 Recommendation

| Project | Approach | Rationale |
|---------|----------|-----------|
| **gentleman-vMK** | Concurrent fetch via `Promise.all` (max 2) | Sequential per turn, no batching needed |
| **opencode-vmk** | Concurrent `undici.request` via dispatcher pool + OpenAI Batch for non-urgent work | Pool handles queuing; batch for cost optimization |

---

## 4. Compression: Brotli vs Gzip vs Zstd

### 4.1 Benchmark (Silesia Corpus — Core i7-9700K @ 4.9GHz)

| Compressor | Ratio | Compress speed | Decompress speed |
|------------|-------|---------------|------------------|
| **zstd 1.5.7 -1** | 2.896 | **510 MB/s** | **1,550 MB/s** |
| **zstd 1.5.7 --fast=3** | 2.241 | 635 MB/s | 1,980 MB/s |
| brotli 1.1.0 -0 | 2.702 | 400 MB/s | 425 MB/s |
| zlib 1.3.1 -1 (gzip) | 2.743 | 105 MB/s | 390 MB/s |
| lz4 1.10.0 | 2.101 | 675 MB/s | **3,850 MB/s** |

### 4.2 Web Compression Savings (Brotli vs Gzip)

| File type | Brotli improvement over gzip |
|-----------|------------------------------|
| JavaScript | ~15% smaller |
| HTML | ~20% smaller |
| CSS | ~16% smaller |

### 4.3 For API Request/Response Bodies

**LLM API payloads are mostly text (JSON)**:

| Scenario | Best choice | Why |
|----------|-------------|-----|
| **Request** (small: <10KB JSON) | None/brotli | Gzip overhead negates savings. Brotli level 1-4 for larger payloads |
| **Response** (streaming tokens) | None | Chunked transfer encoding — content-length unknown, compression breaks streaming |
| **Response** (non-streaming, full) | Brotli (Accept-Encoding: br) | ~20% smaller than gzip, ~15% faster decompress than gzip in Node.js native |
| **Cached responses** | Zstd | 4× faster decompress than brotli, near-identical ratio. Use for embeddings cache |

### 4.4 Recommendation

| Project | For LLM API | For local cache/file |
|---------|-------------|----------------------|
| **gentleman-vMK** | No compression (small payloads, streaming) | Zstd for skill cache if implemented |
| **opencode-vmk** | `Accept-Encoding: br` for non-streaming, none for streaming | Zstd for embedding cache, result cache |

> **Note**: Zstd decompress is 3.6× faster than brotli and 4× faster than gzip. For any cached response >10KB, Zstd is optimal. Only lz4 beats it in decompress speed (3,850 MB/s) but at lower ratio (2.10 vs 2.90).

---

## 5. Streaming: SSE vs WebSocket vs fetch ReadableStream

### 5.1 Protocol Comparison

| Feature | SSE | WebSocket | fetch ReadableStream |
|---------|-----|-----------|---------------------|
| Direction | Server → Client | Bidirectional | Client → Server |
| Transport | HTTP (long-lived) | Upgraded TCP | HTTP (chunked) |
| Reconnection | Built-in (EventSource) | Manual | Manual |
| Backpressure | Client buffer limits | Built-in (TCP flow control) | Built-in (stream backpressure) |
| LLM token streaming | ✅ Most common | ❌ (overkill, bidirectional not needed) | ✅ (OpenAI/Anthropic use this) |
| Complexity | Low | Medium | Low |
| Browser support | 96%+ | 97% | 97% |

### 5.2 LLM API Reality

All major LLM providers use **fetch ReadableStream** (server-sent events over chunked HTTP):

- **OpenAI**: `GET /v1/chat/completions?stream=true` → `Response.body` as ReadableStream of SSE-formatted chunks
- **Anthropic**: Same pattern, SSE over HTTP
- **Google Gemini**: Same pattern

### 5.3 Performance Considerations

| Aspect | SSE via fetch | WebSocket | Impact |
|--------|--------------|-----------|--------|
| Connection overhead | 1 HTTP req | Upgrade handshake + HTTP req | Negligible for agent use |
| First token latency | ~same | ~same | Protocol doesn't matter — model TTFB dominates |
| Backpressure handling | Browser buffers ~256KB | TCP flow control | SSE may drop events on saturated client (rare for LLM) |
| Proxy traversal | Works everywhere | May block on corporate proxies | SSE wins for "toaster" environments |
| Multiplexing | One stream per connection | Single connection, multiple streams | WebSocket advantage for >3 concurrent streams |

### 5.4 Recommendation

| Project | Approach | Rationale |
|---------|----------|-----------|
| **gentleman-vMK** | fetch ReadableStream (SSE) | Native to LLM APIs, simpler, works over HTTP/1.1 |
| **opencode-vmk** | fetch ReadableStream with WebSocket fallback for multi-model streaming | SSE for OpenAI/Anthropic; WS if implementing custom streaming proxy for local models |

---

## 6. DNS Optimization: Cache, Prefetch, HTTP/3 QUIC

### 6.1 DNS Resolution Cost

| Scenario | DNS lookup | Impact on LLM API call |
|----------|-----------|----------------------|
| Cold cache (first call) | 20-120ms | Adds to first-token latency |
| Warm cache | 0-1ms | Negligible |
| DNSSEC validation | +50-200ms | Avoid unless required |
| CNAME chain | ×2-3 lookups | Worse for CDN-backed APIs |

### 6.2 DNS Cache Configuration

```plaintext
Node.js default: dns.lookup() uses c-ares, cache TTL respected (no custom cache)
Undici default: Resolves per connection, no cache
Node 20+: dns.setDefaultResultOrder('ipv4first') — avoid IPv6 timeout penalties
```

### 6.3 Optimizations

| Technique | Effect | Effort |
|-----------|--------|--------|
| `dns.setServers()` | Use specific resolvers (Cloudflare 1.1.1.1, Google 8.8.8.8) | Low |
| DNS prefetch at startup | Resolve api.openai.com, api.anthropic.com once on init | Low |
| Custom DNS cache (Map) | Cache resolves with TTL, avoid repeated lookups | Low |
| Happy Eyeballs (autoSelectFamily) | Avoid IPv6 timeout fallback | Low (Node 18.3+) |
| HTTPS DNS RR (RFC 9460) | Skip HTTP/3 Alt-Svc round-trip | Requires DNS config |

### 6.4 Recommendation

| Project | DNS strategy |
|---------|-------------|
| **gentleman-vMK** | Simple: `dns.setDefaultResultOrder('ipv4first')` + custom cache Map with 5-min TTL. 1-2 hosts, trivially cached. |
| **opencode-vmk** | Full: undici `autoSelectFamily: true` + DNS prefetch at startup (`dns.promises.resolve4()` for each API host) + custom TTL cache via Map or `quick-lru`. QUIC 0-RTT for repeat connections. |

---

## 7. File I/O: bun:fs vs node:fs vs @ff-labs/fff-bun

### 7.1 Benchmark Data

Based on existing research (`build-optimization.md`, ram-cpu-gpu-optimization.md):

| Operation | node:fs | bun:fs | @ff-labs/fff-bun | Win |
|-----------|---------|--------|------------------|-----|
| Read 1MB file | ~250μs | ~80μs | ~75μs | bun:fs (3×) |
| Write 1MB file | ~300μs | ~100μs | ~95μs | bun:fs (3×) |
| Read 1000 small files | ~450ms | ~120ms | ~110ms | bun:fs (3.7×) |
| JSON parse 100KB | ~120μs | ~90μs (Bun.file) | ~90μs | Bun.file |
| Directory listing 10K entries | ~8ms | ~2ms | ~2ms | bun:fs (4×) |
| Memory per open handle | ~4KB | ~1KB | ~1KB | bun:fs (4×) |

### 7.2 Bun Fast Paths

```javascript
// Bun fast paths (from bun.sh/docs):
const file = Bun.file('data.json');           // Zero-copy read
const text = await file.text();               // ~3× faster than fs.readFile
const json = await file.json();               // Parse while reading

const writer = Bun.file('out.json').writer(); // Streaming write
await writer.write(JSON.stringify(data));
await writer.end();
```

### 7.3 Recommendation

| Project | File I/O approach | Rationale |
|---------|------------------|-----------|
| **gentleman-vMK** | PowerShell `Get-Content` / `Set-Content` | PS-native. For large files: `StreamReader`/`StreamWriter` (6-14× faster than `Get-Content` into var) |
| **opencode-vmk** | **Bun.file()** for reads, `Bun.write()` for writes | 3× faster than node:fs, zero-copy JSON parsing. Avoid `fs.readFileSync` entirely. |

> **Note on @ff-labs/fff-bun**: Marginal gain over `Bun.file()` (~5-10%). Only adopt if profiling shows file I/O as bottleneck. **YAGNI for now**.

---

## 8. "Toaster" Constraints: High Latency, Low Bandwidth, Metered Connections

### 8.1 Constraint Summary

| Constraint | Typical value | Impact on agent tool execution |
|------------|--------------|-------------------------------|
| High latency | 100-500ms RTT | +200-1000ms per LLM API round trip |
| Low bandwidth | 0.5-5 Mbps | Slower response downloads, no streaming benefit |
| Metered connection | Per-GB cost, throttled after cap | Minimize total bytes transferred |
| Packet loss | 1-5% | HTTP/2 head-of-line blocking severe → prefer HTTP/1.1 or HTTP/3 |
| Proxy/corporate firewall | Blocks WS, HTTP/3, non-443 ports | SSE over HTTP/1.1 works universally |

### 8.2 Adaptation Strategies

| Technique | Latency | Bandwidth | Metered | Implementation |
|-----------|---------|-----------|---------|----------------|
| Connection keep-alive | ✅ | ✅ | ✅ | Already covered |
| Request deduplication | ✅ | ✅ | ✅ | Cache identical requests (Map<req_sig, Promise>) |
| Response caching | ❌ (no benefit) | ✅ | ✅ | TTL cache for embeddings, completions |
| Compression (Accept-Encoding: br) | ❌ (decompress cost) | ✅ | ✅ | Only non-streaming responses |
| Batch API (24h) | ❌ (slower) | ✅ | ✅ | OpenAI Batch for non-urgent |
| Retry with backoff | ✅ (handles drops) | ✅ | ❌ (extra bytes) | Exponential backoff + jitter |
| DNS prefetch | ✅ | ❌ (negligible) | ❌ (negligible) | Resolve at startup |
| WebSocket downgrade to SSE | ❌ | ✅ | ✅ | SSE proxies through corporate firewalls |
| Token streaming (even on slow links) | ✅ (perceived faster) | ✅ | N/A | First token visible before full response |

### 8.3 Recommended "Toaster" Stack

```plaintext
When detecting high latency or metered connection:
  1. Keep-Alive (avoid reconnection)
  2. Accept-Encoding: br (for non-streaming)
  3. OpenAI Batch API for queued work (50% cost, 24h)
  4. RetryAgent with exponential backoff (undici)
  5. DNS prefetch + cache (avoid cold lookups)
  6. Polling-based fallback if streaming unreliable
  7. Log bandwidth usage per session
```

### 8.4 Recommendation

| Project | "Toaster" adaptation |
|---------|----------------------|
| **gentleman-vMK** | Simple: keep-alive + retry. PS script runs against OpenCode API, which handles connection management. |
| **opencode-vmk** | Full stack as above. Proxy detection at startup, auto-downgrade to HTTP/1.1 if HTTP/3 blocked. Bandwidth metering via results size tracking. |

---

## 9. Consolidated Recommendations

### 9.1 gentleman-vMK (PowerShell · sequential calls · ~1-2 req/turn)

| Area | Choice | Rationale |
|------|--------|-----------|
| HTTP | HTTP/1.1 + KeepAlive | Single host, sequential per turn, no multiplexing need |
| Connection pool | `node:https.Agent({ keepAlive: true, maxSockets: 2 })` | Zero deps, sufficient |
| Batching | None | Sequential per turn |
| Compression | None for streaming, brotli for cached | Small payloads, streaming dominant |
| Streaming | fetch ReadableStream (SSE) | Native to all LLM APIs |
| DNS | `ipv4first` + simple Map cache, 5-min TTL | 1-2 hosts, trivial |
| File I/O | PS `StreamReader`/`StreamWriter` for large; `Get-Content` for <100KB | 6-14× speedup for large files |
| "Toaster" | Keep-alive + retry | Handled by OpenCode host |

### 9.2 opencode-vmk (Bun/Node · concurrent calls · ~8-16 req/turn)

| Area | Choice | Rationale |
|------|--------|-----------|
| HTTP | HTTP/2 with HTTP/3 fallback | Multiplexed streams, 8-16 concurrent API calls to same host |
| Connection pool | **undici**: `Agent({ connections: 16, pipelining: 5, keepAliveMaxTimeout: 60s })` | 3-4× faster than fetch, built-in retry, HTTP/2 |
| Batching | `Promise.all` for sync; OpenAI Batch for async | No native batch API from providers |
| Compression | `Accept-Encoding: br` for non-streaming; Zstd for cache | Brotli: -20% size, native Node support. Zstd: 4× faster decompress for cache |
| Streaming | fetch ReadableStream (SSE) + WebSocket fallback | SSE for all providers; WS for custom proxy |
| DNS | `autoSelectFamily: true` + DNS prefetch at init + `quick-lru` cache | Prefetch api.openai.com, api.anthropic.com; avoid IPv6 timeout |
| File I/O | **Bun.file()** / **Bun.write()** | 3× faster than node:fs, zero-copy JSON parsing |
| "Toaster" | Full adaptation stack | Proxy detection, auto-downgrade, bandwidth metering |

### 9.3 Connection Pool Sizing Summary

```
gentleman-vMK:
  maxSockets: 2 per origin
  keepAlive: true
  keepAliveMsecs: 5000
  scheduling: 'fifo'

opencode-vmk:
  connections: 16 per origin (Pool or BalancedPool)
  pipelining: 5
  keepAliveTimeout: 30000
  keepAliveMaxTimeout: 60000
  autoSelectFamily: true
  retryOnTimeout: true
  retry: 3 (exponential backoff, RetryAgent)
```

---

## Sources

1. RFC 9114 — HTTP/3 (IETF, 2022)
2. RFC 9000 — QUIC: UDP-Based Multiplexed and Secure Transport (IETF, 2021)
3. RFC 7932 — Brotli Compressed Data Format (IETF, 2016)
4. RFC 8878 — Zstandard Compression Algorithm (IETF, 2021)
5. RFC 9460 — SVCB and HTTPS DNS Resource Records (IETF, 2023)
6. Perna et al., "A first look at HTTP/3 adoption and performance", *Computer Communications* 2022
7. Undici v8.5 documentation — Benchmarks (HTTP/1.1, HTTPS, HTTP/2), Node 24.14.1
8. Zstandard official benchmarks — lzbench, Silesia corpus, Core i7-9700K
9. Brotli Wikipedia — browser support, compression ratios vs gzip
10. SSE spec — WHATWG HTML Living Standard
11. Bun.sh — Bun.file(), Bun.write() benchmarks
12. Cloudflare — "What is HTTP/3?", QUIC performance analysis
13. Can I Use — HTTP/3 browser support (95%+ as of Sept 2024)
14. Request Metrics — "HTTP/3 is Fast"
15. Paul Calvano — "Choosing Between gzip, Brotli and zStandard Compression" (2024)
16. SiteGround — "Brotli Compression: ~20% smaller than gzip" (2021)
17. gentleman-agent-gh — `docs/optimization-consolidado/ram-cpu-gpu-optimization.md` (2026-06-23)
18. gentleman-agent-gh — `build-optimization.md` (2026-06-23)
19. gentleman-agent-gh — `docs/optimization-consolidado/ronda3-synthesis.md` (2026-06-23)
20. HTTP Toolkit — Brotli vs Gzip benchmark
21. Wikipedia — HTTP/3 protocol comparison
22. Node.js docs — `dns.setDefaultResultOrder`, `autoSelectFamily`
