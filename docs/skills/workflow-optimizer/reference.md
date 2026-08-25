# Workflow Optimizer — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/workflow-optimizer/SKILL.md) for the core principles and speed patterns.

---

## Examples (5)

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

---

## Testing Patterns (3)

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

---

## Edge Cases (4)

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

---

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

## Externalized Sections (ADR-007 compression)
## Token Budget Management
Self-check every 5 calls: repeating?→compress · unused skills loaded?→unload · over-explaining?→shorten. Checkpoint every 25 calls: `mem_save(topic_key="checkpoint/session-state")`; verify alignment with user goals; adjust.


## Metrics to Track
Token usage/task (reduce 20%) · Time to first output (-30%) · Repeat error rate (target 0) · Skill load accuracy (target 100%).
