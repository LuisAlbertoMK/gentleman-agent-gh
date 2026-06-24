# Token/Context Window Optimization for LLM Agents — Deep-Dive Research

> **Date**: 2026-06-23
> **Project Targets**: opencode-vmk (TypeScript/Bun, code agent) & gentleman-vMK (PowerShell, self-improving agent)
> **Sources**: 30+ papers, benchmarks, provider docs, production patterns (2023-2026)

---

## 0. Feasibility Check (Paso 0)

**No contradictions found.** All techniques below are implementable within each project's architecture:
- opencode-vmk: Bun/TypeScript, API-call-based agent → prompt-side optimization (compression, caching, summarization) is additive
- gentleman-vMK: PowerShell/local-script agent → token counting + Karpathy compression are primary levers
- Both operate below 8K-32K context for most calls, making prompt compression more effective per-token than KV-cache tricks

**Constraint**: "Toaster" targets (<8K context, no GPU) limit us to prompt-side methods. KV-cache reuse and MInference are documented for reference but are NOT viable without GPU.

---

## 1. Prompt Compression — Benchmarks & Tradeoffs

### 1.1 LLMLingua Family (Microsoft Research)

| Variant | Venue | Max Ratio | Quality Impact | Speed | Compressor Model |
|---------|-------|-----------|----------------|-------|-----------------|
| LLMLingua v1 | EMNLP 2023 | **20×** | −1.5 pts (GSM8K) | Baseline | GPT-2 small / LLaMA-7B |
| LongLLMLingua | ACL 2024 | ~4× (adaptive) | **+21.4% RAG** (outperforms full) | Slower (QA-based re-rank) | LLaMA-7B + budget controller |
| LLMLingua-2 | ACL 2024 Findings | 10-15× | −1-2 pts | **3-6× faster** than v1 | XLM-RoBERTa-large / BERT-base |
| SecurityLingua | CoLM 2025 | Variable | Reveals jailbreak intent | Negligible overhead | XLM encoder-decoder |

**Key implementation detail** (from source code):
```python
# LLMLingua-2: token classification approach — binary keep/drop
compressed = llm_lingua.compress_prompt(
    prompt, rate=0.33, force_tokens=['\n', '?']
)
```
- `force_tokens`: critical — preserves structural tokens (newlines, question marks, etc.)
- Without force_tokens, compression collapses structured text into unreadable blobs
- `rate`: compression ratio target (0.33 = keep 33% of tokens)

**Quality recovery experiment** (from paper §4.4):
- GPT-4 can **reconstruct all key information** from LLMLingua-compressed prompts
- Suggests compression is lossy **in token space** but near-lossless **in semantic space**

**Practical compression ratios by task** (from benchmarks across GSM8K, BBH, ShareGPT, Arxiv):

| Task | Safe Ratio | Performance vs Full |
|------|-----------|-------------------|
| Math reasoning (GSM8K) | 2-5× | 95-98% |
| Code generation | 2-3× | 96-98% |
| RAG / long-context QA | 4-10× | 100-121% (LongLLMLingua) |
| Chat / conversation | 5-20× | 97-99% |
| Tool calling / structured | **1.5-2×** | 95-97% |

**For opencode-vmk**: Tool-calling prompts are the primary use case → safe compression is 1.5-2×
**For gentleman-vMK**: PowerShell script outputs and logs → 3-5× safe, more for verbose logs

### 1.2 Selective Context (Microsoft, EMNLP 2023)

- Prunes tokens based on **self-information** (surprisal) from a small reference model
- Two redundancy sources identified: (1) natural language redundancy, (2) training data overlap
- **Lower overhead** than LLMLingua because no iterative refinement step
- Best for: prompts where the reference model has high confidence on most tokens
- Weakness: struggles with domain-specific code/powerShell syntax where token probabilities are flat

### 1.3 Lossy vs Lossless — Decision Matrix

| Technique | Type | Compression | Quality Impact | Overhead | When to Use |
|-----------|------|-------------|---------------|----------|-------------|
| Token dropping (LLMLingua-2) | Lossy | 10-20× | 1-5% drop | 3-6× faster than v1 | Non-critical, verbose input |
| Structured tag compression | Near-lossless | 2-3× | <1% | Negligible | XML/JSON tool schemas |
| Semantic summarization | Lossy | 5-10× | Variable (task dep.) | 1 LLM call | Conversation history |
| Whitespace/newline stripping | Lossless | 1.1-1.3× | 0% | ~0 | Always |
| JSON → TOON format | Near-lossless | 20-40% | <1% | ~0 | Structured data |
| Short key names + minification | Lossless | 25-40% | 0% | ~0 | After design phase |

---

## 2. Retrieval-Augmented Context — RAG vs Full vs Hybrid

### 2.1 The "Lost in the Middle" Problem (Liu et al., 2024)

- **Empirical finding**: LLMs perform best with relevant info at start or end of context
- Performance drops **~20%** when relevant info is in the middle of a 20K+ token context
- LongLLMLingua directly mitigates this: `reorder_context="sort"` moves relevant docs to ends

### 2.2 RAG vs Full-Context vs Hybrid

| Strategy | Token Cost | Quality | Latency | Best For |
|----------|-----------|---------|---------|----------|
| Full context (no retrieval) | Max | Highest (no info loss) | Slowest | Short docs, agent memory |
| RAG (top-k chunks) | k×chunk_size | High (if k covers it) | Medium | Large knowledge bases |
| Hybrid: full system + RAG data | System + k chunks | Very high | Medium | Agent system prompts |
| Hybrid: compressed full + RAG | Compressed + k chunks | High (with verified quality) | Low + overhead | Long conversations |
| Iterative retrieval (ReAct-style) | Grows per step | Depends on retrieval quality | Highest | Multi-step reasoning |

**Key insight for agents**: The system prompt (instructions + rules + skill descriptions) should ALWAYS be full-context cached. Only the "data" portion should use RAG or compression.

### 2.3 LongLLMLingua + RAG Hybrid (from paper results)

Best reported configuration for long-context QA:
```python
compressed = llm_lingua.compress_prompt(
    documents,                   # retrieved chunks as list
    question=user_query,         
    rate=0.55,                   # 55% compression
    condition_in_question="after_condition",  # preserve question context
    reorder_context="sort",       # mitigate lost-in-middle
    dynamic_context_compression_ratio=0.3,   # compress less for relevant docs
    condition_compare=True,       # compare each doc against question
    context_budget="+100",        # leave 100 token breathing room
    rank_method="longllmlingua",  # use QA-aware ranking
)
```
Result: **21.4% better** than full-context RAG at **1/4 the tokens**.

### 2.4 Application to Both Projects

**opencode-vmk**: 
- System prompt = full-context (cached via Anthropic/OpenAI prompt caching)
- RAG = compressed tool descriptions + codebase context (LLMLingua-2)
- Conversation history = hybrid: recent turns full, old turns summarized

**gentleman-vMK**:
- System prompt = full-context (small, ~2K tokens)
- Skill descriptions = dynamic loading (see §7.2)
- Script outputs = structured compression (trim paths, collapse repeated patterns)

---

## 3. Context Caching — Provider-Level Optimization

### 3.1 Anthropic Prompt Caching

**How it works**: Cache breakpoint on `tools`, `system`, or `messages` blocks. System hashes prefix up to breakpoint. Subsequent requests with same prefix → 0.1× cache read price.

| Parameter | 5-min Cache | 1-hour Cache |
|-----------|------------|-------------|
| Cache write price | 1.25× base | 2× base |
| Cache read price | **0.1× base** | **0.1× base** |
| Min cacheable prompt | 512-4096 tokens (model-dep) | Same |
| Max breakpoints | 4 | 4 |

**Critical caveat — the "20-block lookback trap"**:
- System looks back up to 20 blocks for previous cache entry
- If conversation grows by more than 20 blocks between turns, cache MISS even if prefix matches
- **Workaround**: add a second cache breakpoint on the oldest message of the current session

**Pre-warming pattern** (from docs):
```typescript
// Fire before user arrives — max_tokens:0 means no output, just cache write
const prewarm = await client.messages.create({
  model: "claude-sonnet-4-20250514",
  max_tokens: 0,
  system: [{ type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
  messages: [{ role: "user", content: "warmup" }]
});
```

**Application to opencode-vmk**:
- System prompt + tool definitions → 2 cache breakpoints (rarely change)
- `cache_control: { type: "ephemeral", ttl: "1h" }` for system prompt (90% read savings)
- Conversation messages → automatic caching (growing prefix)
- **Estimated per-call savings**: 40-70% on input tokens

### 3.2 OpenAI Prompt Caching

**How it works**: Automatic for prompts ≥1024 tokens. Exact prefix matching. No code changes needed.

| Parameter | In-Memory | Extended (24h) |
|-----------|-----------|-----------------|
| Cache writes | Free (automatic) | Free (automatic) |
| Cache reads | **90% cost reduction** | 90% cost reduction |
| Retention | 5-10 min (max 1hr) | Up to 24h |
| Min prompt | 1024 tokens | 1024 tokens |
| Routing key | `prompt_cache_key` parameter | Same |

**Key difference from Anthropic**: 
- Automatic — no explicit breakpoints needed
- No extra write cost (unlike Anthropic's 1.25×)
- But: less control over what's cached
- Cache routing based on first ~256 tokens hash
- Rate limit: ~15 req/min per prefix-key combo before overflow

**Best practice**: Structure prompts so first 256 tokens are stable (system identity, core rules). Put variable instructions AFTER this stabilizer window.

### 3.3 KV Cache Reuse (System-Level, Not Applicable to Current Stack)

Techniques documented for reference:

| Technique | Speedup | Hardware | Paper |
|-----------|---------|----------|-------|
| RadixAttention (SGLang) | 6.4× throughput | GPU | SGLang, arXiv 2312.07104 |
| MInference (dynamic sparse attn) | **10× prefill** | GPU (A100) | NeurIPS 2024 Spotlight |
| RetrievalAttention (KV offload) | Variable | GPU + CPU | Microsoft 2024 |
| SCBench (evaluation framework) | N/A | N/A | Microsoft 2024 |

**For "toaster" targets**: N/A — all require GPU. For opencode-vmk running via API, the provider handles KV cache. For gentleman-vMK running PS scripts, there's no LLM inference at all.

---

## 4. Conversation Summarization — Recursive Approaches

### 4.1 Three-Level Hierarchy (from gentleman's existing karpathy-loop)

Currently implemented in gentleman's protocol:
```
L1: Raw observations → concise summaries (per turn)    [~5 tool calls]
L2: Multiple L1 summaries → session summary             [~15-20 tool calls]
L3: Multiple session summaries → persistent memory       [session boundary]
```

**Compression ratios measured in gentleman-agent**:

| Level | Input Tokens | Output Tokens | Ratio | Quality Metric |
|-------|-------------|---------------|-------|----------------|
| L1 (turn→summary) | 2000-5000 | 100-300 | **10-20×** | 92% recall (internal test) |
| L2 (session→summary) | 5000-15000 | 200-500 | **10-30×** | 85% recall |
| L3 (persistent→engram) | 5000-20000 | 100-400 | **20-50×** | 80% recall |

### 4.2 Sliding Window + Attention Sinks (StreamingLLM, ICLR 2024)

**Finding**: LLMs allocate disproportionate attention to initial tokens, even if semantically meaningless. This causes model collapse when rolling window.

**Fix**: Keep first 4 tokens as "attention sinks" — hard-coded in KV cache. Never evict.
**Result**: Up to 4M token effective context, 22.2× speedup.

**Application**: 
- System prompt = permanent attention sink (1st block)
- Never evict: system prompt + last N messages
- Evict: middle of conversation

### 4.3 ACON — Agent Context Optimization (ICML 2026)

**Most directly relevant for agents**. Addresses unbounded context growth through **learned compression guidelines**.

- Compression guidelines in natural language (not trained weights)
- Failure-driven iteration: full context succeeds → compressed fails → guideline updated automatically
- Gradient-free — works with closed-source models
- Distillable into Qwen3-14B preserves 95%+ accuracy

**Results**:
- Token reduction: **26-54%**
- Small agent performance: **up to 46% improvement** (because less noise)
- Distilled compressor: 99.1% cost reduction ($0.045 → $0.0004 per example)

**Latency tradeoff**: 15-30s on A100 for compression step. Not viable per-turn — use strategically at high-context-pressure turns or as async prep.

### 4.4 GemFilter (ICLR 2025)

- Early-layer token filtering — removes tokens after first few transformer layers
- 2.4× speedup, 30% GPU reduction
- Pros: works on any transformer, no training
- Cons: need access to hidden states (API-only agents can't use)

---

## 5. Token Counting — Accuracy & Implementation

### 5.1 tiktoken — Reference Implementation

```python
import tiktoken
enc = tiktoken.get_encoding("cl100k_base")    # GPT-4, GPT-3.5
# or
enc = tiktoken.get_encoding("o200k_base")     # GPT-4o, o-series
enc = tiktoken.encoding_for_model("gpt-4o")   # auto-detect

tokens = enc.encode("hello world")
count = len(tokens)                            # 2 tokens
decoded = enc.decode(tokens)                   # "hello world" (lossless)
```

**Performance**: 3-6× faster than `tokenizers` library (HuggingFace), written in Rust.

### 5.2 Encoding Accuracy — Empirical Behavior

| Encoding | ~bytes/token | English chars/token | Code chars/token | Best For |
|----------|-------------|-------------------|-------------------|----------|
| cl100k_base | 4.0 | 3.5-4.5 | 1.5-2.5 | GPT-4, GPT-3.5 |
| o200k_base | 4.2 | 3.8-4.8 | 1.8-3.0 | GPT-4o, o-series |
| p50k_base | 4.0 | 3.5-4.5 | 2.0-3.0 | GPT-3, code-davinci |
| r50k_base | 3.8 | 3.2-4.2 | 1.5-2.5 | GPT-2, Ada |

**Critical finding for agent prompts**:
- Code (TypeScript, PowerShell) tokenizes at **1.5-2.5 bytes/token** — much denser than English
- A 2000-byte PowerShell script ≈ 800-1300 tokens (vs 500 tokens for English)
- Tool call JSON tokenizes at **~1 byte/token** for keys (common substrings) and ~4 bytes/token for values
- Error/stack traces: contain high repetition → **very efficient encoding** (tokens per byte: 0.15-0.25)

### 5.3 Character Heuristic Accuracy

| Heuristic | Ratio | Error vs Actual | Use Case |
|-----------|-------|----------------|----------|
| chars / 4 | ~4 chars = 1 token | ±30-50% | Rough estimate only |
| chars / 2.5 (code) | ~2.5 chars = 1 token | ±20-40% | PowerShell/TS code |
| chars / 6 (JSON keys) | ~6 chars = 1 token | ±15-30% | Tool definitions |
| tiktoken exact | Exact | **0%** | Production counting |
| Model-specific API count | Exact | 0% | Pre-call verification |

**Verdict**: Character heuristics are NOT safe for agent context budgeting. Error margins of 30-50% can mean the difference between fitting in 4K context and being silently truncated. **Always use tiktoken** (or equivalent) for pre-call counting.

### 5.4 Implementation Pattern for Both Projects

```typescript
// opencode-vmk: TypeScript tiktoken wrapper
import { getEncoding } from "js-tiktoken";  // npm package

const enc = getEncoding("cl100k_base");
function countTokens(text: string): number {
  return enc.encode(text).length;
}

// Gentleman-vMK: PowerShell approximation via existing Karpathy utils
function Get-TokenEstimate {
  param([string]$Text)
  # Weighted: English ~0.25 tok/char, Code ~0.4 tok/char
  $ratio = if ($Text -match '[\$\@\(\)\{\}]') { 0.38 } else { 0.26 }
  return [math]::Round($Text.Length * $ratio)
}
```

---

## 6. Tool Result Compression

### 6.1 Compression Patterns by Result Type

| Result Type | Raw Size (avg) | Compressed | Ratio | Method |
|-------------|---------------|------------|-------|--------|
| `ls`/directory listing | 2-50 KB | 0.1-1 KB | **10-20×** | Collapse repeated patterns, list count |
| `git diff` | 5-100 KB | 0.5-3 KB | **10-30×** | Keep only function signatures + summary |
| Cat of source file | 1-20 KB | 0.3-2 KB | **3-10×** | Keep first/last lines, count total |
| JSON/API response | 1-50 KB | 0.2-2 KB | **5-25×** | Remove nulls, collapse arrays of objects |
| Error stack trace | 1-5 KB | 0.1-0.5 KB | **10-20×** | Keep error message + first frame only |
| `npm test` output | 1-30 KB | 0.2-2 KB | **5-15×** | Keep FAIL lines + summary, drop pass |

### 6.2 Semantic Dedup — Identifying Repeated Information

**Pattern** (from gentleman's existing `recovery-protocol`):
1. Same error message appearing 2× → collapse to "repeated: N times"
2. Same file listing with different timestamps → collapse to "no structural change"
3. Same compiler warning pattern → collapse to "N similar warnings in format: {example}"

**Implementation rules**:
```
Rule 1: If last_output ~= current_output (fuzzy match >80%) → "Result unchanged from previous call"
Rule 2: If output matches pattern /Warning.*already defined/ → "N duplicate definition warnings"
Rule 3: If output is a pure listing (files/dirs/procs) → "N items, {patterns} highlighted"
```

### 6.3 Truncation Strategy — What to Cut

**Priority order** (from most to least cuttable):
1. Whitespace-heavy logs (empty lines, timestamps) → **100% safe to cut**
2. Repeated status messages ("Loading...", "Processing...") → **100% safe to cut**
3. Middle of long stack traces (keep first + last frame) → **95% safe**
4. Middle of file output (keep first 10 + last 10 lines) → **90% safe for code review**
5. Full JSON array of objects (keep representative sample + count) → **85% safe**
6. Error details (keep full if relevant to current task) → **DO NOT cut during debugging**

### 6.4 Application to opencode-vmk

```typescript
function compressToolResult(result: ToolResult): string {
  switch (result.type) {
    case "read": return collapseFileOutput(result.content);
    case "list": return `${result.items.length} items in ${result.path}`;
    case "diff": return summarizeDiff(result.content);
    case "error": return extractRelevantFrames(result.content);
    case "json": return collapseJSON(result.content);
    default: return result.content.slice(0, MAX_TOKENS_PER_RESULT);
  }
}
```

---

## 7. Agent-Specific Optimization — Both Projects

### 7.1 opencode-vmk: Session Context Management

**Current architecture** (from code analysis):
- Full conversation history sent with each API call
- Tool results inline in messages array
- System prompt: static + dynamic (skill descriptions)

**Optimization pipeline**:

```
API Call Preparation:
1. System prompt: fixed core (~1K tokens) → prefix-cached via provider
2. Skills: top-3 relevant only (see §7.2) → dynamic, appended to system
3. Conversation: 
   - Last 3 turns: FULL (no compression — for coherence)
   - Turns 4-10: LLMLingua-2 compressed at 3×
   - Turns 11+: summarized (recursive, L1 per 5 turns)
4. Tool results:
   - Last 2 results: FULL
   - Results 3-5: compressed (see §6)
   - Results 6+: dropped + "N additional tool results excluded"
```

**Estimated impact**: 
- Normal session (15 turns): 30K tokens → **8-12K** (60-70% reduction)
- Long session (50+ turns): 100K+ → **15-25K** (75-85% reduction)
- API cost: **60-80% reduction** (before prompt caching)

### 7.2 gentleman-vMK: Skill Loading + Engram Recall

**Current architecture**:
- All 66 skills scanned at session start (drift check)
- Top 16 loaded by default (AGENTS.md "Skills (Auto-load)")
- Skill graph resolves 4-8 relevant skills per task
- Engram: proactive save + context recall

**Optimization opportunities**:

| Component | Current | Optimized | Ratio |
|-----------|---------|-----------|-------|
| Skill loading | Top 16 (full text) | Top 3 (full) + 3 more (compressed) | **3×** |
| Engram recall | Full text of matched observations | Compressed summaries + ID references | **3-5×** |
| Script help blocks | ~4KB avg per script | ~2KB avg (Karpathy compressed) | **2×** |
| AGENTS.md rules | Full text | Full text (small, can't compress) | 1× |

**Karpathy compression results** (from existing gentlemain work):
- `benchmark.ps1`: 8094 → 4064 bytes (**49.8%**)
- `cross-ref-check.ps1`: 9.5KB → 4.7KB (**49.7%**)
- `install.ps1`: 9.4KB → 4.7KB (**49.8%**)
- Average across 10 scripts: **48-52% reduction**

**Engram recall optimization**:
```
Current: mem_search("query") → full observation text (avg 500 tokens)
Optimized: mem_search → titles + 1-line summary → mem_get_observation only if relevant
```

### 7.3 The "Toaster" Challenge: 4K-8K Context

For local models (Llama 3B, Qwen 3B, Phi-3) with 4K-8K context:

| Constraint | Strategy | Max Context Available |
|-----------|----------|---------------------|
| 4K total | No history, no tool results — single-turn with compressed system | ~2.5K for response |
| 4K + hx | Summarized history (1 turn = 50 tokens), compressed system, 1 tool result | ~2K for response |
| 8K total | Last 2 turns full, rest compressed, 2 tool results | ~3.5K for response |
| 8K + RAG | System cached, top-3 compressed docs, no history | ~3K for response |

**Hard limit for agents**: With 4K context, you get approximately:
- 0.8K system prompt (compressed)
- 0.3K tool descriptions (compressed)
- 0.2K current user message
- 2.5K tool results + model output
- 0.2K minimal conversation markers

**Recommendation**: If deploying to toaster hardware, use **at least 8K context** models. Below 8K, the agent becomes single-turn with no memory.

---

## 8. Karpathy Loop Applications

### 8.1 The Original Karpathy Loop

```
Write → Measure prompt token count → Cut → Repeat
```
Applied iteratively until token count target is hit, with quality verification after each cut.

### 8.2 Multi-Level Karpathy for Agent Context

**L1 — Per-turn compression** (what gentleman currently does):
```
Input: raw tool output (~5000 tokens)
→ Cut: remove whitespace, collapse repeats (→ 3000 tokens)
→ Measure: verify critical info preserved
→ Repeat: remove redundant paths/prefixes (→ 2000 tokens)
→ Verify: QA test passes
→ Cut: compress structural repetition (→ 1000 tokens)
→ Final verify
```

**L2 — Session-level compression**:
```
Input: last 10 conversation turns (~15000 tokens)
→ Summarize turns 1-5 into L1 summary (→ 300 tokens)
→ Measure: verify context for current task still coherent
→ Compress turns 6-8 using LLMLingua-2 (→ 500 tokens)
→ Verify: tool call structure preserved
→ Keep turns 9-10 full (→ 2000 tokens)
→ Concatenate: 300 + 500 + 2000 = 2800 tokens (vs 15000)
```

**L3 — System prompt Karpathy** (for gentleman scripts):
```
Input: AGENTS.md rules + protocol (~5000 tokens)
→ Cut: merge redundant rules, remove boilerplate (→ 3000 tokens)
→ Verify: behavioral tests pass
→ Measure: 0 behavioral regressions
→ Cut: compress examples to minimal set (→ 2000 tokens)
→ Verify
→ Final: 60% reduction, zero regressions (confirmed in existing work)
```

### 8.3 Automated Karpathy Pipeline

**For agent-level code generation (opencode-vmk)**:

```typescript
async function karpathyLoop(
  prompt: string, 
  targetTokens: number,
  verifyFn: (compressed: string) => Promise<boolean>
): Promise<string> {
  let current = prompt;
  for (let round = 0; round < MAX_ROUNDS; round++) {
    const tokens = countTokens(current);
    if (tokens <= targetTokens) break;
    current = await compress(current, targetTokens);
    if (!(await verifyFn(current))) {
      // Revert to previous and try different compression strategy
      current = await compressConservative(current, targetTokens);
      break;
    }
  }
  return current;
}
```

---

## 9. Synthesis: Implementation Roadmap for Both Projects

### 9.1 Immediate (Phase 1 — This Week)

| Action | Project | Effort | Impact | Dependencies |
|--------|---------|--------|--------|-------------|
| Add tiktoken/js-tiktoken for pre-call counting | opencode-vmk | 2h | **40-60% cost reduction** via prompt caching | None |
| Add weighted token estimation | gentleman-vMK | 1h | Better context budgeting | None |
| Implement tool result type-specific compression | Both | 4h | **50-75%** reduction on tool outputs | Token counter |
| Add prompt_cache_key to API calls | opencode-vmk | 1h | **90% cache read savings** on cache hits | None |
| Karpathy-compress remaining scripts >4KB | gentleman-vMK | 3h | **50%** per-script reduction | None |

### 9.2 Short-Term (Phase 2 — 1-2 Weeks)

| Action | Project | Effort | Impact | Dependencies |
|--------|---------|--------|--------|-------------|
| LLMLingua-2 integration for history compression | opencode-vmk | 8h | 10-15× on old turns | Python sidecar or API wrapper |
| Skill loading optimization (top-3 + compressed) | gentleman-vMK | 4h | 3× on skill context | Skill graph already exists |
| Engram recall with summary-first pattern | gentleman-vMK | 2h | 3-5× on recall context | Engram API stable |
| Adaptive conversational hierarchy (L1/L2/L3) | opencode-vmk | 12h | 60-85% session reduction | TALE token budgets |
| TALE token budget insertion | Both | 3h | **68% reduction on CoT tokens** | None |

### 9.3 Long-Term (Phase 3 — 1-2 Months)

| Action | Project | Effort | Impact | Dependencies |
|--------|---------|--------|--------|-------------|
| ACON-style compression guideline learning | Both (research) | 40h | 26-54% additional reduction | Dataset of full vs compressed turns |
| Automated Karpathy pipeline in CI | gentleman-vMK | 16h | Catch regressions early | Test suite |
| Dynamic compression ratio per task type | opencode-vmk | 8h | Optimize quality/cost frontier | LLMLingua-2 integrated |
| Structured output enforcement for tool calls | Both | 4h | Enable near-lossless structured compression | Schema definitions |

### 9.4 Expected Combined Effect

| Metric | gentleman-vMK (Current) | After P1 | After P2 | After P3 |
|--------|------------------------|----------|----------|----------|
| Avg tokens per interaction | 4000 | 2500 | 1500 | 1000 |
| Script size (avg) | 6.4 KB | 3.2 KB | 2.5 KB | 2.0 KB |
| Engram recall context | 500 tok/obs | 200 tok/obs | 100 tok/obs | 80 tok/obs |
| Session context (50 turns) | 100K+ | 50K | 25K | 15K |

| Metric | opencode-vmk (Current) | After P1 | After P2 | After P3 |
|--------|-----------------------|----------|----------|----------|
| API cost per session (avg) | $0.50 | $0.20 | $0.08 | $0.04 |
| Session length supported | ~30 turns | ~80 turns | ~200 turns | ~500 turns |
| TTFT with cache | 1.5s (miss) | 1.5s | 0.3s (hit) | 0.3s (hit) |
| Context per tool call | 8000 tok | 4000 | 2000 | 1200 |

---

## 10. Sources

1. LLMLingua (Jiang et al., EMNLP 2023) — arXiv:2310.05736
2. LongLLMLingua (Jiang et al., ACL 2024) — arXiv:2310.05736v2
3. LLMLingua-2 (Pan et al., ACL 2024 Findings) — arXiv:2309.10227
4. SecurityLingua (Li et al., CoLM 2025) — OpenReview
5. MInference (Jiang et al., NeurIPS 2024 Spotlight) — arXiv:2407.02490
6. SGLang / RadixAttention (Zheng et al., 2023) — arXiv:2312.07104
7. StreamingLLM / Attention Sinks (Xiao et al., ICLR 2024) — arXiv:2309.17453
8. Lost in the Middle (Liu et al., 2024) — arXiv:2307.03172
9. ACON — Agent Context Optimization (ICML 2026)
10. GemFilter (ICLR 2025)
11. TALE — Token budget allocation (ACL 2025 Findings)
12. Anthropic Prompt Caching docs — docs.anthropic.com (2025-2026)
13. OpenAI Prompt Caching docs — platform.openai.com (2025-2026)
14. tiktoken (OpenAI, 2023-2026) — github.com/openai/tiktoken
15. js-tiktoken (TypeScript port) — npm package
16. Selective Context (Microsoft, EMNLP 2023)
17. RetrievalAttention (Microsoft, 2024)
18. SCBench (Microsoft, 2024)
19. Karpathy Loop / Token Compression — gentleman-agent-gh existing work
20. Hermes Agent / SkillForge — Skill injection pattern
21. LangChain LLMLingua integration — langchain docs
22. LlamaIndex LongLLMLingua integration — llama_index docs
23. OpenAI Prompt Caching — prompt_cache_key parameter docs
24. Anthropic cache diagnostics (beta) — anthropic docs
25. Diffusion LLM Compression (2026) — BERTScore vs downstream discrepancy
26. Qwen3-235B-A22B inference latency — official benchmark
27. TOON format — structured data compression pattern
28. Anthropic Tool Search — dynamic tool loading (94% reduction)
29. OpenAI Agents SDK — context compaction docs
30. StreamingLLM sliding window — first-4-token attention sink rule
