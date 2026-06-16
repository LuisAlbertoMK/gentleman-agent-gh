# Optimization Plan — Global Self-Improvement Cycle

> Baseline: 9.0/10 avg score · 22.9KB AGENTS.md · 126.8KB skills · 57 SKILL.md files
> Target: Verified measurable improvement across all dimensions

## Current Gaps Identified

| Gap | Impact | Fix |
|-----|--------|-----|
| No .learnings/ infrastructure | Knowledge lost between improvements | Created LEARNINGS.md, ERRORS.md, FEATURE_REQUESTS.md |
| No SOUL.md / IDENTITY.md | No persistent identity | Created |
| No USER.local.md | User preferences not tracked | Created |
| Token waste in responses | ~30% overhead possible | Apply Karpathy + LeanContext |
| Context not compressed proactively | Extra ~8K messages in window | Schedule L1 every 8 msgs |
| Skill files: 126.8KB total | Bigger context load | Compress verbose skills |
| Batch ops not institutionalized | Extra round trips | Codify batch-first rule |

## Optimization Vectors

### 1. Token Efficiency (Target: -50% per task)
- Karpathy-prompt for ALL subagent prompts
- Lean-context LEAN mode as default
- Context-watchdog L1 compression every 8 messages
- No echoing, no restating, no filler

### 2. Execution Speed (Target: -40% tool calls)
- Batch independent operations in single message
- Subagent-first for reads >3 files
- ctx_batch_execute for parallel commands
- ctx_execute for data processing (keep bytes out of context)

### 3. Error Prevention (Target: 0 repeated errors)
- Anti-Pattern Catalog scan before every task
- Engram search before starting familiar work
- Immune system for every error (document→immunize→prevent)
- .learnings/ auto-log corrections

### 4. Context Management (Target: -60% waste)
- Recursive Summary Compression L1 at 8 messages
- L2 at 20 messages or 3 L1 blocks
- L3 at YELLOW zone
- Always compress cold path first

### 5. Memory Persistence (Target: zero context loss)
- mem_save after every decision/bugfix/pattern
- mem_session_summary at session end (mandatory)
- dreaming periodic pattern extraction
- topic_key updates instead of new saves

## Improvement Cycle

```
1. Measure → baseline metrics
2. Plan → identify highest-impact optimizations
3. Execute → implement with batch ops
4. Verify → measure delta, save evidence
5. Learn → log to .learnings/, immunize patterns
6. Repeat → next optimization target
```

## Metrics Tracked

| Metric | Baseline | Target | How to Measure |
|--------|----------|--------|----------------|
| Tool calls per task | ~8 avg | ≤5 | Count in session |
| Token waste per response | ~30% | ≤10% | chars/4 estimation |
| Error rate per session | ~2 | 0 | ERRORS.md count |
| Avg auto-metrics score | 9.0 | 9.5+ | Score after each task |
| Session completion speed | variable | -40% iterations | Task steps count |
| Context compression rate | 0% | -60% stale bytes | ctx_stats |
| Knowledge retention | session-only | cross-session | engram recall success |
