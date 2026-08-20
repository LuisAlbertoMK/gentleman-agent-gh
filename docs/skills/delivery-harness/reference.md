# delivery-harness — Reference Materials

> **Externalized from** .agents/skills/delivery-harness/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Anti-Patterns
Parallelize dependent units · Share context between subagents · No rollback plan · Skip unit success criteria · Collect without verifying
- **God orchestrator**: Single agent doing all work instead of delegating — defeats isolation, bloats context
- **Implicit coupling**: Units that *look* independent but share hidden state (global config, DB, file system) — always declare shared resources explicitly

## Examples

### Example 1: Feature with 3 Parallel Units
**Goal**: Add user dashboard with metrics, notifications, settings
**Breakdown**:
- Unit A (parallel): Metrics API + components — `task(subagent_type=code-generation, prompt="Build /api/metrics + DashboardMetrics.tsx")`
- Unit B (parallel): Notifications API + components — `task(subagent_type=code-generation, prompt="Build /api/notifications + NotificationBell.tsx")`
- Unit C (parallel): Settings API + components — `task(subagent_type=code-generation, prompt="Build /api/settings + SettingsPanel.tsx")`
**Dependencies**: None — all independent
**Collection**: Verify each compiles, run component tests, merge

### Example 2: Serial Dependency Chain
**Goal**: Migrate auth from sessions → JWT
**Breakdown**:
- Unit 1: Add JWT library, token generation — success: `npm test auth/token.test.ts`
- Unit 2: Replace session middleware with JWT verify — depends on Unit 1
- Unit 3: Update login/logout routes — depends on Unit 2
- Unit 4: Remove session store, cleanup — depends on Unit 3
**Rollback per unit**: `git checkout HEAD~1 -- src/auth/`

### Example 3: Mixed Parallel + Serial
**Goal**: Add payment integration (Stripe)
**Breakdown**:
- Unit A (parallel): Stripe client wrapper + types
- Unit B (parallel): Webhook endpoint skeleton + signature verify
- Unit C (serial, after A+B): Checkout session creation — uses A, called by B
- Unit D (serial, after C): Order confirmation flow — uses C
**Dependency graph**: A∥B → C → D

### Example 4: Failure Recovery
**Goal**: Refactor user service (5 files)
**Breakdown**: 5 units (1 file each, parallel)
**Failure**: Unit 3 returns compilation error
**Action**: 
1. Re-delegate Unit 3 with error context + Engram ID of failure
2. If retry fails → rollback Units 1,2,4,5 via `git stash` + `git stash pop` per unit
3. Report: "3/5 done, Unit 3 BLOCKED — see Engram error-resolution#47"

### Example 5: Large Spec → Work Units (SDD Pipeline)
**Goal**: Implement "Team Workspaces" from spec
**Breakdown** (SDD phases as units):
- Unit 1: `sdd-explore` — clarify requirements, output questions
- Unit 2: `sdd-spec` — write delta spec with scenarios
- Unit 3: `sdd-design` — architecture, data model, API contracts
- Unit 4: `task` work units — break into 4-6 implementation tasks (parallel where possible)
- Unit 5: `sdd-verify` — run tests, match spec scenarios
**Each unit** returns 4-field contract; orchestrator stitches into final report

## Testing Patterns

### Pattern 1: Unit Success Criteria Verification
```bash
# Each delegation includes verifiable command
success_criteria: "pnpm test src/auth/login.test.ts --reporter=line"
# Orchestrator runs after collection:
for unit in "${units[@]}"; do
  eval "$unit.success_criteria" || mark_failed "$unit"
done
```

### Pattern 2: Contract Compliance Check
```bash
# Validate 4-field block present in every subagent output
required_fields=("Decision Taken" "Files Changed" "Key Findings" "Nuance")
for field in "${required_fields[@]}"; do
  grep -q "## $field" "$output_file" || { echo "Missing: $field"; exit 1; }
done
```

### Pattern 3: Dependency Graph Validation
```bash
# Before delegation, verify no cycles in dep graph
# Input: units.json with {id, depends_on: []}
python3 -c "
import json, sys
data = json.load(open('units.json'))
edges = [(u['id'], d) for u in data for d in u['depends_on']]
# Kahn's algorithm
from collections import defaultdict, deque
graph = defaultdict(list)
indeg = defaultdict(int)
for a,b in edges:
  graph[b].append(a)
  indeg[a] += 1
  indeg.setdefault(b, 0)
q = deque([n for n in indeg if indeg[n]==0])
ordered = []
while q:
  n = q.popleft()
  ordered.append(n)
  for m in graph[n]:
    indeg[m] -= 1
    if indeg[m]==0: q.append(m)
if len(ordered) != len(indeg):
  sys.exit('CYCLE DETECTED')
print('Valid DAG:', ' → '.join(ordered))
"
```

## Edge Cases

### Edge Case 1: Subagent Returns Empty/Truncated Output
**Symptom**: Subagent completes but stdout is empty or cut off
**Cause**: Context window limit hit during subagent execution
**Fix**: 
- Require file-based output fallback in delegation prompt: "If output >10KB, write to `docs/agentes/{task}/05-completion-report.md` and echo only the path"
- On collection: check for `.md` report path, read it instead of stdout

### Edge Case 2: Hidden Shared State Between "Independent" Units
**Symptom**: Parallel units pass individually but fail when merged
**Cause**: Both write to same config file / global registry / DB migration
**Fix**: 
- Declare shared resources in unit spec: `shared_resources: ["src/config/app.ts", "db:migrations"]`
- If shared → serialize (make serial) OR add merge step with explicit conflict resolution

### Edge Case 3: Partial Success with Cascade Rollback
**Scenario**: Unit A✓ B✓ C✗ (C depends on B)
**Behavior**: 
- Rollback C (trivial — not applied yet)
- Rollback B (revert its files via `git checkout HEAD -- <files_B>`)
- Unit A stands (no dependents failed)
- Report: "Delivered: A. Rolled back: B,C. Root cause in C: <Engram ID>"

### Edge Case 4: Subagent Hangs / Timeout
**Symptom**: No response after 5 min (default timeout)
**Fix**: 
- Orchestrator tracks start time per unit
- On timeout: kill subagent process, mark BLOCKER
- Retry once with: `prompt + " PREVIOUS ATTEMPT TIMED OUT. Scope: ONLY <specific file/function>. Max 100 lines output."`
- If retry times out → escalate to human with Engram context

## Externalized Sections (ADR-007 compression)
## ERROR HANDLING
| Failure | Action |
|---------|--------|
| Subagent timeout | Retry once with stricter scope, then flag BLOCKER |
| Wrong output | Re-delegate with corrected context + Engram ID of error |
| Dependency fail | Cascade: rollback dependents, report partial delivery |
| Merge conflict | Open conflict file, delegate resolution to human |


## DEPENDENCIES
- subagent-isolation (context boundaries)
- work-unit-commits (commit organization)
- command-wrapper (safe command execution)


