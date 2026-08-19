---
name: workflow-optimizer
description: "Optimize workflow patterns — faster info access, reduced token waste, smarter caching, auto-learning triggers."
triggers: [optimize-workflow, faster-access, token-optimization, workflow-pattern, information-access, fluidez]
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Optimize workflow — faster info access, token economy, caching, auto-learning triggers.

## Core Principles
1. **Info Access**: Right info, right time
2. **Token Economy**: Every token earns its place
3. **Auto-Learning**: Patterns → rules → habits → instinct
4. **Cache Aggressively**: Compute once, reuse everywhere

## Speed Patterns

### 1. Pre-flight Check (Before Every Task)
```
1. mem_search("<task-keywords>", limit=3) → inject top 3
2. Check skill-graph for relevant skills
3. Verify no recent error on same pattern (immune-system)
```
**Savings**: 2-5K tokens/task

### 2. Lazy Loading (Never Load What You Won't Use)
```
- Q&A only → karpathy-loop + lean-context (skip sdd-*, judgment-day)
- Bug fix → recovery-protocol + immune-system (skip sdd-propose)
- Review → code-review-agent + judgment-day (skip sdd-*)
```
**Savings**: 5-15K tokens/session

### 3. Context Compression Levels
```
L1 (every 8 msgs/15 calls): Full summary, -60-70%
L2 (every 20 msgs/>3 L1): 1-2 line decisions + engram ID, -40-50%
L3 (ORANGE>60%): 1-liner/topic + ref, -80-90%
```

### 4. Parallel Information Gathering
```
- Read-heavy (>3 files) → delegate explore agent
- Independent research → delegate in parallel
- Batch file reads → single tool call with multiple reads
```

## Auto-Learning Triggers

### Pattern Detection
```
IF same_fix_2x → save to ANTI-PATTERN-CATALOG
IF same_error_3x → add to immune-system
IF user_correction_2x → add to AGENTS.md rules
IF repeat_workflow_3x → create skill
```

### Learning Pipeline
```
1. Capture: mem_save after every decision/bugfix/discovery
2. Extract: dreaming skill on 5th error/bugfix
3. Evaluate: score changes delta
4. Apply: inject into next session context
```

## Token Budget Management

### Self-Check (Every 5 Calls)
```
- Am I repeating myself? → compress
- Am I loading unused skills? → unload
- Am I over-explaining? → shorten
```

### Checkpoint (Every 25 Calls)
```
- mem_save(topic_key="checkpoint/session-state")
- Verify alignment with user goals
- Adjust approach if needed
```

## Information Access Optimization

### Fast Recall
```
1. mem_context (recent history, fast)
2. mem_search (full-text, thorough)
3. mem_get_observation (full)
```

### Proactive Loading
```
- User mentions project → mem_search(project="<name>")
- User mentions feature → mem_search(query="<feature>")
- User mentions error → mem_search(type="bugfix", query="<error>")
```

## Metrics to Track
```
- Token usage/task (reduce 20%)
- Time to first output (-30%)
- Repeat error rate (target: 0)
- Skill load accuracy (target 100%)
```

---

> See [reference.md](docs/skills/workflow-optimizer/reference.md) for extended details, examples, and detailed patterns.