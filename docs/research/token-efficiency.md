# Token Efficiency Techniques — 2026

> **Goal**: Reduce token consumption WITHOUT quality loss.  
> **Current state**: AGENTS.md 14KB, lean-context L1/L2/L3, engram memory, Karpathy compression.

## Priority Stack (by ROI)

### 1. RTK (Rust Token Killer) ⭐⭐⭐ — INSTALL NOW
- **What**: CLI proxy intercepting Bash tool output → 60-90% compression via smart filtering/grouping
- **Savings**: 60-90% on shell output (40-70% of total tokens)
- **Effort**: Medium — Windows install requires manual binary download
- **Risk**: Zero semantic loss (deletion-based, no rewriting)
- **Status**: Windows binary available, BUT auto-rewrite hook is WSL-only. On native Windows, falls back to CLAUDE.md instruction hints (lower savings).
- **Install**:
  - Windows: Download `.zip` from [github.com/rtk-ai/rtk/releases](https://github.com/rtk-ai/rtk/releases), extract to PATH
  - Then: `rtk init -g --opencode`
- **⚠️ Windows caveat**: Native Windows lacks the auto-rewrite hook that gives 60-90% on Linux. Expect lower savings (~30-50%) until RTK adds native Windows hook support.

### 2. Headroom MCP ⭐⭐⭐ — INSTALL NOW
- **What**: Compresses ALL agent I/O (tool outputs, logs, files, conversation) via 6 algorithms
- **Savings**: 60-95% depending on content
- **Effort**: Medium — requires `pip install headroom-ai[proxy]` first, then `headroom wrap opencode` or MCP mode
- **Risk**: Reversible (CCR) — originals cached, LLM can retrieve on demand
- **Install**:
  ```powershell
  pip install headroom-ai[proxy]
  headroom wrap opencode    
  # Or MCP mode: add to opencode.json
  ```
- **Note**: Platform-agnostic (works on Windows). Complementary to RTK (broader scope). The ML compressor needs a model download (~500MB).

### 3. Provider Prompt Caching ⭐⭐ — ENABLE
- **What**: Cache KV state of stable prompt prefixes server-side (Anthropic/OpenAI)
- **Savings**: 50-90% off cached input tokens
- **Effort**: Trivial — add `cache_control: {"type": "ephemeral"}` to system prompt
- **Risk**: Zero quality loss. Cache TTL 5-60 min.

### 4. Output Limits ⭐⭐ — ADD TO AGENTS.md
- **What**: `max_tokens` ceilings + explicit length constraints
- **Savings**: 30-60% on output (output costs 3-10× input)
- **Effort**: Easy — add to AGENTS.md as instruction

### 5. Fresh Sessions Per Task ⭐ — PROCESS CHANGE
- **What**: Fresh sessions per task to avoid quadratic context growth
- **Savings**: 50-70% on compound session growth
- **Effort**: Medium (behavioral change)

### 6. Codebase Graph First ⭐ — REINFORCE
- **What**: Prefer `codebase-memory_*` queries over file reads for structural questions
- **Savings**: 70-90% on navigation tokens
- **Effort**: Already partially done — reinforce in AGENTS.md

## Recommendation

```
Install NOW:    Headroom MCP (pip + wrap) — works on Windows, 60-95% savings
Try/assess:     RTK (manual install) — 30-50% on Windows, 60-90% on WSL
Enable NOW:     Prompt caching + output limits
Reinforce:      Graph-first queries
Process change: Fresh sessions per task
```

Headroom is the highest-ROI option for native Windows. RTK on WSL would be transformative but on native Windows the savings are lower without the hook. **Priority**: Headroom first, then assess RTK.
