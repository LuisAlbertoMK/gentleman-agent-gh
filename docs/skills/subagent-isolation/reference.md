# Subagent Isolation — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/subagent-isolation/SKILL.md) for the core isolation rules and preservation contract.

---

## Examples (5)

### Example 1: Clean Delegation — Code Review
```yaml
delegate:
  to: code-review-agent
  context:
    files: ["src/auth/middleware.ts:1-80"]
    engram_ids: ["decision:jwt-rotation-2026"]
    task: "Review JWT rotation logic for timing attacks"
  expected_output: 4-field contract only
```

### Example 2: Sequential Dependency — Spec → Implement
```yaml
# Step 1
delegate:
  to: sdd-spec
  context:
    files: ["docs/specs/auth-api.md"]
    task: "Write delta spec for refresh-token endpoint"
  output_id: spec-auth-refresh

# Step 2 (depends on Step 1)
delegate:
  to: code-generation
  context:
    files: ["src/routes/auth.ts"]
    engram_ids: [spec-auth-refresh]
    task: "Implement refresh-token endpoint per spec"
```

### Example 3: Parallel Independent Work — UI + API
```yaml
# Both can run in parallel — no shared state
delegate:
  to: ui-engine
  context:
    files: ["src/components/LoginForm.tsx"]
    task: "Add loading state to login button"

delegate:
  to: code-generation
  context:
    files: ["src/api/auth.ts"]
    task: "Add /logout endpoint"
```

### Example 4: Error Isolation — Retry with Clean Context
```yaml
# First attempt fails with hallucinated import
delegate:
  to: code-generation
  context:
    files: ["src/utils/date.ts"]
    task: "Add formatISO helper"
  result: hallucinated "date-fns" import

# Retry with corrected context (explicit no-external-deps)
delegate:
  to: code-generation
  context:
    files: ["src/utils/date.ts"]
    task: "Add formatISO helper — NO external deps, use native Intl"
  result: clean implementation
```

### Example 5: Context Cleanup — Large Output Handling
```yaml
delegate:
  to: deep-debugging
  context:
    files: ["src/services/payment.ts"]
    task: "Trace N+1 query in chargeCustomer"
  output: 200-line trace

# Main agent extracts only:
# - Root cause: PaymentService:chargeCustomer:42 calls getCustomer in loop
# - Fix: batch load customers before loop
# References delegation ID in Engram, discards full trace
```

---

## Testing Patterns (3)

### Pattern 1: Contract Compliance Test
```bash
# Verify every delegation output contains the 4 required fields
grep -E "## Decision Taken|## Files Changed|## Key Findings|## Nuance" delegation-output.md
# Must return 4 matches minimum
```

### Pattern 2: Isolation Violation Detection
```bash
# Search for forbidden patterns in delegation prompts
grep -E "previous (output|result|context|agent|subagent)" delegation-prompt.md && echo "VIOLATION: cross-contamination"
grep -E "global|shared|state" delegation-prompt.md && echo "VIOLATION: shared state reference"
```

### Pattern 3: Context Freshness Verification
```bash
# Ensure each delegation references only declared deps
python -c "
import yaml, sys, re
prompt = yaml.safe_load(open('delegation-prompt.yaml'))
declared = set(prompt.get('context', {}).get('files', []))
referenced = set(re.findall(r'src/\S+', prompt.get('task', '')))
undeclared = referenced - declared
if undeclared: print(f'UNDECLARED REFS: {undeclared}'); sys.exit(1)
"
```

---

## Edge Cases (4)

### Edge Case 1: Implicit Dependency via File System
**Scenario**: Subagent A writes `config.json`, Subagent B reads it.  
**Fix**: Declare `config.json` as output of A → input of B. Never parallelize.

### Edge Case 2: Engram ID Drift
**Scenario**: Delegation references `engram_ids: ["bugfix:auth-2026"]` but that observation was superseded.  
**Fix**: Always verify Engram ID freshness via `mem_search` before delegating. Use `topic_key` for evolving decisions.

### Edge Case 3: Cascading Timeout Recovery
**Scenario**: Delegation times out → retry with cleaner prompt → still times out.  
**Fix**: After 2 timeouts, escalate to human with "stuck delegation" label. Do NOT retry a third time.

### Edge Case 4: Partial Output Corruption
**Scenario**: Subagent returns valid 4-field contract but `Key Findings` contains hallucinated file paths.  
**Fix**: Post-delegation validation: verify every file path in `Files Changed` and `Key Findings` exists via `glob`/`read` before accepting.

---

## Anti-Patterns (2 Additional)

### Anti-Pattern 1: "Context Accumulation" — Keeping full subagent output in main context
**Why it fails**: Blows context window, introduces noise, next delegation inherits garbage.  
**Correct**: Extract only `Decision Taken` + `Files Changed` + 1-line summary. Store full output in Engram with delegation ID.

### Anti-Pattern 2: "Implicit Parallelization" — Running dependent delegations in parallel
**Why it fails**: Race conditions, stale reads, corrupted state.  
**Correct**: Explicit `depends_on: [delegation-id]` in orchestration. Sequential by default; parallel only when declared independent.