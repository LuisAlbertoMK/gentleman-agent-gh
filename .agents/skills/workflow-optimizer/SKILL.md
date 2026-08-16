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

## Examples

### Example 1: Pre-flight Check for Bug Fix
```
Task: Fix "N+1 query in user list"
1. mem_search("N+1 query user list", limit=3) → found fix from 2 weeks ago
2. skill-graph → immune-system + recovery-protocol relevant
3. immune-system check → pattern already catalogued as anti-pattern #7
Result: Applied existing fix in 2 min vs 20 min discovery
```

### Example 2: Lazy Skill Loading for Code Review
```
Task: Review PR #234 (auth middleware changes)
1. Intent: code review → load code-review-agent + judgment-day
2. Skip: sdd-propose, sdd-design, sdd-verify (not a new feature)
3. Result: 8K tokens vs 25K if full SDD pipeline loaded
```

### Example 3: Context Compression at YELLOW Zone
```
Context at 55% → trigger L1 compression
Before: 120 messages, full history in context
After: 30 messages + 15-line summary + engram refs
Tokens freed: ~45K, retained decision traceability
```

### Example 4: Parallel Research for Architecture Decision
```
Task: Choose between Redis vs PostgreSQL for caching layer
1. Delegate explore agent A: Redis patterns in codebase
2. Delegate explore agent B: PostgreSQL patterns in codebase
3. Delegate explore agent C: Benchmarks from prior decisions
4. Merge findings → decision in 5 min vs 25 min sequential
```

### Example 5: Auto-Learning from Repeat Correction
```
User corrects: "Use 'const' not 'let' for config objects" (3rd time)
1. Detection: user_correction_2x threshold met
2. Action: Add rule to AGENTS.md: "Config objects → const"
3. Result: Future sessions auto-apply, zero repeat corrections
```

## Testing Patterns

### Pattern 1: Token Budget Regression Test
```
Input: Standard task (bug fix, code review, new feature)
Measure: tokens used vs baseline
Assert: tokens ≤ baseline * 0.8 (20% reduction target)
Run: Weekly via CI on sample task suite
```

### Pattern 2: Skill Load Accuracy Test
```
Input: Task + expected skill set
Measure: Skills actually loaded vs expected
Assert: 100% match (no missing, no extra)
Run: On every skill-graph change
```

### Pattern 3: Pre-flight Check Efficacy Test
```
Input: Known issue with documented fix in mem
Measure: Time to resolution with vs without pre-flight
Assert: With pre-flight ≤ 30% of without
Run: Monthly on 10 historical issues
```

## Edge Cases

### Edge Case 1: Cold Start (No Prior Memory)
```
Scenario: New project, empty engram, no mem_search hits
Handling: Fallback to defaults — load core skills (code-review-agent, immune-system, recovery-protocol)
Signal: mem_search returns empty → trigger baseline skill set
```

### Edge Case 2: Context Window Exhaustion Mid-Task
```
Scenario: Task at 85% context, L3 compression already applied
Handling: Force checkpoint (mem_save), offload to file, restart with compressed context
Rule: If >90% after L3 → hard stop, save state, new session
```

### Edge Case 3: Conflicting Auto-Learning Signals
```
Scenario: Pattern detected for skill creation BUT user_correction_2x says "don't create skill"
Handling: user_correction_2x wins (explicit > implicit), log conflict to immune-system
Rule: Explicit user preference > auto-detected pattern
```

### Edge Case 4: Cross-Project Pattern Leakage
```
Scenario: Pattern from Project A applied to Project B incorrectly
Handling: mem_search with project filter mandatory, scope="project" on mem_save
Rule: Never apply cross-project pattern without explicit validation
```

## Anti-Patterns

### Anti-Pattern 1: Premature Skill Creation
```
❌ Creating skill after 1-2 occurrences
✅ Wait for repeat_workflow_3x threshold
Rationale: Skill maintenance cost > ad-hoc cost for rare patterns
```

### Anti-Pattern 2: Over-Compression Losing Decisions
```
❌ L3 compression dropping decision rationale
✅ Always preserve: decision + file + engram ID (min 3 lines/topic)
Rationale: Lost context = repeated mistakes = more tokens long-term
```