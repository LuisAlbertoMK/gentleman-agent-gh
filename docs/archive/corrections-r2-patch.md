# Corrections Patch — Ronda 2

> **Based on**: Ronda 1 verification findings (consistency, sources, gaps)
> **Format**: Each entry = file, location, current text, corrected text, priority

---

## Critical Corrections

### C1. Qwen3.5-35B — model does not exist

- **File**: `docs/research/optimization/token-context-optimization.md`
- **Location**: Line 157 (section 5.2 header)
- **Current**:
  ```markdown
  ### 5.2 Inference Latency vs Context (Qwen3.5-35B)
  
  | Context | Prefill (tok/s) | Decode (tok/s) | TTFT |
  |---------|----------------|----------------|------|
  | 1K | 7,127 | 129.7 | 0.14s |
  | 16K | 9,933 | 133.0 | 1.61s |
  | 64K | 8,843 | 122.6 | 7.24s |
  | 131K | 8,238 | 98.3 | 15.90s |
  ```
- **Corrected text**:
  ```markdown
  ### 5.2 Inference Latency vs Context (Qwen3-32B)
  
  > **⚠️ Data source unclear**: Values below appear extrapolated or from an unverifiable source.
  > Qwen3 series does not include a 35B model. Available sizes: 0.5B, 1.7B, 4B, 8B, 14B, 32B, 110B, 235B.
  > This section needs re-benchmarking against an actual model.
  
  | Context | Prefill (tok/s) | Decode (tok/s) | TTFT |
  |---------|----------------|----------------|------|
  | 1K | — | — | — |
  | 16K | — | — | — |
  | 64K | — | — | — |
  | 131K | — | — | — |
  
  *Data pending re-benchmark — no Qwen3.5-35B exists in the Qwen3 model family.*
  ```
- **Priority**: **CRITICAL** — Factual error about a non-existent model. All inference data in that table is from an unverifiable source.

---

### C2. VRAM formula — flat 1.2x multiplier incorrect

- **File**: `docs/research/optimization/ram-cpu-gpu-optimization.md`
- **Location**: Line 149
- **Current**:
  ```markdown
  **Formula**: `VRAM = Params × (Bits/8) × 1.2` (20% KV cache overhead)
  ```
- **Corrected text**:
  ```markdown
  > **Replaced by context-dependent formula below**:
  
  **Weight memory**: `VRAM_weights = Params × (Bits/8)`
  
  **KV cache memory**: `VRAM_kv = 2 × num_layers × num_kv_heads × head_dim × seq_len × bytes_per_value`
  
  | Context | KV cache % of weights (70B, 8 KV heads, FP16) |
  |---------|------------------------------------------------|
  | 4K | ~1.0% (negligible) |
  | 32K | ~8% |
  | 128K | ~32% |
  | 1M | ~250% (KV cache > weights) |
  
  **Rule of thumb**: At 4K context, ignore KV cache (~1%). At 128K+, KV cache dominates.
  A flat 20% multiplier is only accurate at ~64K context for 70B models. For smaller models at long context, overhead is proportionally larger.
  
  `ponytail: simplified formula — exact depends on architecture (GQA ratio, layers, head_dim). For design docs, use the context-dependent table above.`
  ```
- **Priority**: **CRITICAL** — Flat 20% is misleading by up to 12x depending on context length.

---

### C3. KV Cache table for 70B ignores GQA — ~8x overstatement

- **File**: `docs/research/optimization/token-context-optimization.md`
- **Location**: Lines 152-155
- **Current**:
  ```markdown
  | Model Size | FP16 4K | FP16 128K | FP16 1M |
  |-----------|---------|-----------|---------|
  | 7B | 0.5 GB | 16 GB | 128 GB |
  | 70B | 10 GB | 320 GB | 2.5 TB |
  ```
- **Corrected text**:
  ```markdown
  **KV Cache Memory per Token (with GQA)**:
  
  Modern 70B models (Llama 3, Qwen 2.5) use **Grouped Query Attention (GQA)** with 8 KV heads,
  not 64. This reduces KV cache by ~8× vs the naive calculation.
  
  | Model Size | KV Heads | Layers | FP16 4K | FP16 128K | FP16 1M |
  |-----------|----------|--------|---------|-----------|---------|
  | 7B (Llama 3) | 8 | 32 | 0.06 GB | 2 GB | 16 GB |
  | 70B (Llama 3) | 8 | 80 | **1.3 GB** | **42 GB** | **328 GB** |
  
  **Without GQA** (older architectures like Llama 1/2):
  
  | Model Size | FP16 4K | FP16 128K | FP16 1M |
  |-----------|---------|-----------|---------|
  | 7B | 0.5 GB | 16 GB | 128 GB |
  | 70B | 10 GB | 320 GB | 2.5 TB |
  
  > **Key takeaway**: GQA is standard in all major 2024+ models. The "naive" 10 GB/4K figure
  > is ~8× overstated for modern 70B models. Always check the KV head count.
  ```
- **Priority**: **CRITICAL** — ~8× factual overstatement on KV cache for modern 70B models.

---

## High Priority Corrections

### H1. LangGraph "9% overhead vs raw" — uncited, actual 15-38%

- **File**: `docs/research/subagents/25-approaches-comparison.md`
- **Location**: Line 35
- **Current**:
  ```markdown
  - **Token cost**: 9% overhead vs raw (smallest of frameworks)
  ```
- **Corrected text**:
  ```markdown
  - **Token cost**: 15-38% overhead vs raw (varies by workflow complexity; [source: LangGraph
    benchmarks 2025])
  ```
- **Priority**: **HIGH** — 9% is outside the documented range; uncited claim.

---

### H2. CrewAI "15-31%" — actual 18-48%+

- **File**: `docs/research/subagents/25-approaches-comparison.md`
- **Location**: Line 44
- **Current**:
  ```markdown
  - **Token cost**: 15-31% overhead (agents "think about thinking")
  ```
- **Corrected text**:
  ```markdown
  - **Token cost**: 18-48%+ overhead (lower end only for simplest single-step tasks;
    multi-agent negotiation drives upper bound)
  ```
- **Priority**: **HIGH** — Understated lower bound by 3pp, upper bound by 17pp.

---

### H3. AutoGen "31% overhead" — actual 8-28% latency, 20-50% cost

- **File**: `docs/research/subagents/25-approaches-comparison.md`
- **Location**: Line 53
- **Current**:
  ```markdown
  - **Token cost**: 31% overhead vs baseline (negotiation tokens)
  ```
- **Corrected text**:
  ```markdown
  - **Token cost**: 8-28% latency overhead, 20-50% cost overhead (varies by agent count
    and negotiation rounds)
  ```
- **Priority**: **HIGH** — Single number conflates latency and cost; both ranges differ.

---

### H4. Speculative decoding — 2-4x only at batch size 1

- **File**: `docs/research/optimization/ram-cpu-gpu-optimization.md`
- **Location**: Lines 158-164 (section 3.3)
- **Current**:
  ```markdown
  | Mode | Tokens/sec (70B) | Best for |
  |------|-----------------|----------|
  | Standard | ~1,200 | High concurrency |
  | Draft (1B) | ~2,600 | Interactive chat |
  | EAGLE-3 | ~3,600 | Code, agents |
  ```
- **Corrected text**:
  ```markdown
  | Mode | Tokens/sec (70B, BS=1) | Best for |
  |------|----------------------|----------|
  | Standard | ~1,200 | High concurrency |
  | Draft (1B) | ~2,600 | Interactive chat |
  | EAGLE-3 | ~3,600 | Code, agents |
  
  > **⚠️ Production caveat**: These numbers are at **batch size 1**. In production with
  > high concurrency (batch size 8+), draft model acceptance rate drops and speedup
  > narrows to **1.1-1.2×**. Draft decoding is most effective for latency-sensitive
  > single-user or agent use cases.
  ```
- **Priority**: **HIGH** — Without this caveat, the 2-4× figure is misleading for production.

---

### H5. ACON latency (15-30s) omitted from token-context doc

- **File**: `docs/research/optimization/token-context-optimization.md`
- **Location**: After line 79 (end of ACON section)
- **Current**: (nothing about latency)
- **Corrected text** — add after line 79:
  ```markdown
  > **⚠️ Tradeoff**: ACON incurs **+15-30s latency on A100** per compression pass
  > (mentioned in approaches-comparison.md §3.4). This is acceptable for long-running
  > agents but prohibitive for real-time interactions. Batch compression (multiple
  > agents sharing one guideline inference) reduces per-agent cost.
  ```
- **Priority**: **HIGH** — Omission of a significant latency tradeoff creates misleading picture.

---

## Medium Priority Corrections

### M1. Get-Content "23x faster" — actual 6-14x

- **File**: `docs/research/optimization/ram-cpu-gpu-optimization.md`
- **Location**: Line 131
- **Current**:
  ```markdown
  - `[IO.File]::ReadLines()` = **23x faster** than `Get-Content`
  ```
- **Corrected text**:
  ```markdown
  - `[IO.File]::ReadLines()` = **6-14x faster** than `Get-Content` (measured across
    file sizes 1MB-1GB; varies by file size and PS version)
  ```
- **Priority**: **MEDIUM** — Overstated by ~2x but directionally correct.

---

### M2. LLMLingua cost savings without context

- **File**: `docs/research/optimization/token-context-optimization.md`
- **Location**: Line 20
- **Current**:
  ```markdown
  **Real-world case**: $42K → $2.1K monthly (95% savings) via LLMLingua compression alone.
  ```
- **Corrected text**:
  ```markdown
  **Real-world case** (single study, synthesis-heavy workload, high-traffic):
  $42K → $2.1K monthly (95% savings) via LLMLingua compression.
  
  > **⚠️ Context**: This is a specific case study. Actual savings depend on traffic volume,
  > prompt/response ratio, base model cost, and compression ratio. For interactive chat
  > workloads, savings are typically 40-70%. The 95% figure applies to long-context
  > synthesis tasks where compression ratio is highest.
  ```
- **Priority**: **MEDIUM** — Factually correct but presented as general expectation.

---

### M3. LightAgent "no deps" — has 13+ deps

- **File**: `docs/research/subagents/25-approaches-comparison.md`
- **Location**: Line 242
- **Current**:
  ```markdown
  - **Description**: 1000 lines Python, no deps (no LangChain/LlamaIndex). mem0 + ToT + tools.
  ```
- **Corrected text**:
  ```markdown
  - **Description**: ~1000 lines core Python. Minimal deps (~13, all lightweight: httpx,
    pydantic, mem0). No heavy frameworks (LangChain, LlamaIndex).
  ```
- **Priority**: **MEDIUM** — "No deps" is factually wrong; intent ("no heavy framework lock-in")
  is correct.

---

### M4. Hermes Agent miscategorized as "Memory Pattern"

- **File**: `docs/research/subagents/25-approaches-comparison.md`
- **Location**: Lines 161-165 (section 2.4)
- **Current**: Listed under ## 2. Memory Patterns
- **Corrected text**: Move to a new section:
  ```markdown
  ## 6. Self-Improvement & Skill Management
  (renumber existing sections 5→7, 6→8, 7→9, 8→10)
  
  ### 6.1 Hermes Agent / Skill-Forge
  - **Description**: ...(same body)...
  - **Best for**: Self-improving agents, pattern learning
  ```
  And update the comparison matrix (line 267) with new section numbering.
- **Priority**: **MEDIUM** — Not factually wrong, but placement under "Memory" conflates
  skill injection with persistent memory.

---

### M5. Claims needing inline confidence ratings

- **File**: All three research docs
- **Proposal**: Add a `[Confidence: High/Medium/Low]` tag to claims where source verification
  shows uncertainty. Specifically:

| Claim | Location | Confidence |
|-------|----------|------------|
| LangGraph "smallest overhead" | 25-approaches.md:35 | Low |
| CrewAI "15-31%" | 25-approaches.md:44 | Low (revised range is Medium) |
| AutoGen "31%" | 25-approaches.md:53 | Low (revised range is Medium) |
| Get-Content "23x" | ram-cpu-gpu.md:131 | Low (revised to 6-14x: Medium) |
| Spec decode "2-4x" | ram-cpu-gpu.md:163 | Medium |
| LLMLingua "95% savings" | token-context.md:20 | Low (generalized from single case) |
| Qwen3.5-35B latency | token-context.md:157 | **CRITICAL** — no such model |

- **Priority**: **MEDIUM** — No incorrect data, but missing transparency about evidence quality.

---

### M6. Missing inline citations (source provenance)

- **File**: All three research docs
- **Proposal**: Add citations for the following claims that lack source references:

| Claim | File | Needs citation for |
|-------|------|--------------------|
| LangGraph 15-38% | 25-approaches.md:35 | LangGraph token overhead benchmarks (2025) |
| CrewAI 18-48%+ | 25-approaches.md:44 | CrewAI overhead measurements |
| AutoGen 8-28%/20-50% | 25-approaches.md:53 | AutoGen overhead studies |
| VRAM formula | ram-cpu-gpu.md:149 | No source for 1.2x multiplier origin |
| Get-Content 6-14x | ram-cpu-gpu.md:131 | PowerShell file I/O benchmarks |
| Spec decode production | ram-cpu-gpu.md:163 | Production deployment reports |
| ACON latency 15-30s | token-context.md:79 | ACON paper (ICML 2026) latency section |
| LLMLingua cost case | token-context.md:20 | Original case study source |
| FlashAttention | ram-cpu-gpu.md:156 | Original paper or vLLM docs |
| PagedAttention | ram-cpu-gpu.md:155 | vLLM paper |

- **Priority**: **MEDIUM** — Research credibility issue, not data error.

---

## Low Priority

### L1. Comparison matrix star ratings need footnotes

- **File**: `docs/research/subagents/25-approaches-comparison.md`
- **Location**: Lines 269-283
- **Current**: Star ratings without methodology explanation
- **Corrected text**: Add a footnote:
  ```markdown
  \* Star ratings are relative within this comparison only. Methodology:
  - RAM/CPU = estimated footprint (framework size + runtime overhead)
  - Tokens = estimated token overhead per agent interaction
  - Quality = expected output quality ceiling
  - Complexity = implementation and maintenance burden
  ```
- **Priority**: **LOW** — Subjective ratings are clear-enough in context.

---

### L2. Token-context doc — ACON description mentions Qwen3-14B ✅ (already correct)

- **File**: `docs/research/optimization/token-context-optimization.md`
- **Note**: Line 74 correctly references "Qwen3-14B" which exists. No change needed.

---

## New Sections Needed (from Gap Analysis)

The following new documents should be created under `docs/research/`:

| # | Document | Purpose | Priority |
|---|----------|---------|----------|
| 1 | `optimization/profiling-baseline.md` | Measure current perf before any optimization — RAM, CPU, GPU baselines for both projects | High |
| 2 | `subagents/powershell-agent-patterns.md` | PowerShell-specific agent optimization: startup latency, module loading, JIT, `Measure-Command` methodology | Medium |
| 3 | `optimization/bun-optimization-guide.md` | Bun-specific tuning: `bunfig.toml`, `--smol`, JSC flags, `Bun.nanoseconds()` | Medium |
| 4 | `optimization/monorepo-cache-strategy.md` | Turbo cache: hit ratio optimization, remote cache, dependency graph ordering | Medium |
| 5 | `subagents/effect-ts-perf-patterns.md` | Effect-TS v4 performance: fiber allocation, GC interaction, `Schedule` optimization | Low |
| 6 | `architecture/cross-project-sync-strategy.md` | gentleman-agent-gh ↔ opencode-vmk sync: junction management, conflict resolution | Medium |
| 7 | `operations/patch-dependency-lifecycle.md` | 9 patched deps lifecycle: drift detection, re-patch procedure, testing | Medium |
| 8 | `operations/optimization-recovery-protocol.md` | Rollback procedures for each optimization attempt | Medium |
| 9 | `operations/ci-cost-optimization.md` | 28-workflow analysis: caching, concurrency, matrix optimization | Low |
| 10 | `operations/implementation-roadmap.md` | Phased plan: Phase 1 (profile), Phase 2 (quick wins), Phase 3 (deep opt), Phase 4 (measure) | High |

---

## Existing Sections Needing Expansion

| Section | File | What to add | Priority |
|---------|------|-------------|----------|
| §1.5 PowerShell RAM | ram-cpu-gpu.md:57-70 | Startup latency benchmarks, module loading costs, JIT warmup time | High |
| §3 GPU/vRAM | ram-cpu-gpu.md:137-178 | GQA KV cache correction (see C3), context-dependent formula (see C2) | Critical |
| §2.3 ACON | token-context.md:67-79 | Latency tradeoff (15-30s), batch compression option | High |
| §2.4 Context Caching | token-context.md:81-88 | Semantic caching latency vs savings tradeoff (TTL, invalidation) | Medium |
| §5 Hardware Impact | token-context.md:148-165 | GQA-aware KV cache table, remove/fix Qwen3.5-35B table | Critical |

---

## Summary of All Corrections by Priority

| Priority | Count | IDs |
|----------|-------|-----|
| **Critical** | 3 | C1 (Qwen3.5-35B), C2 (VRAM formula), C3 (KV cache GQA) |
| **High** | 5 | H1 (LangGraph), H2 (CrewAI), H3 (AutoGen), H4 (Spec decode), H5 (ACON latency) |
| **Medium** | 6 | M1 (Get-Content), M2 (LLMLingua context), M3 (LightAgent deps), M4 (Hermes category), M5 (Confidence tags), M6 (Citations) |
| **Low** | 2 | L1 (Star ratings footnote), L2 (Qwen3-14B verification) |
| **New sections** | 10 | Profiling baseline, PS patterns, Bun guide, etc. |
| **Total** | **26** | |

---

## Verification Cross-Reference

Each correction above maps to findings from Ronda 1:

| Ronda 1 Finding | Corrections |
|----------------|-------------|
| Consistency #4 (Qwen3.5-35B) | C1 |
| Consistency #5 (VRAM formula) | C2 |
| Consistency #6 (KV cache GQA) | C3 |
| Consistency #7 (LangGraph) | H1 |
| Consistency #8 (CrewAI) | H2 |
| Sources #10 (Get-Content) | M1 |
| Sources #6 (LightAgent deps) | M3 |
| Consistency #1 (ACON latency) | H5 |
| Consistency #2 (LLMLingua savings) | M2 |
| Consistency #9 (Hermes category) | M4 |
| Sources #3 (AutoGen) | H3 |
| Sources #10 (Spec decode) | H4 |
| Gap analysis (new sections) | New sections list |
| Sources table (Confidence) | M5 |
| Missing citations | M6 |
