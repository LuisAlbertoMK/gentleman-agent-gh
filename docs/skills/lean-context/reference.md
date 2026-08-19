# Lean Context — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/lean-context/SKILL.md) for the core compression levels and budget gates.

---

## C28 Depth — Examples

### LEAN (drop disclaimers/transitions/unsolicited suggestions)
**Before**: "I understand you want to fix the login issue. Let me check the auth middleware first, and then I'll look at the session handling. Here's what I found..."
**After**: "Auth middleware at `src/middleware/auth.ts:42` has a race condition on token refresh. Fix: add mutex."

### ULTRA (LEAN + drop examples/background/"why"/"as mentioned")
**Before**: "The issue is in the database connection pool. For example, when 100 concurrent requests hit the pool, it exhausts connections. As mentioned earlier, the pool size is 10. The fix is to increase it to 50."
**After**: "DB pool exhausted at 100 concurrent reqs. Pool size 10 → 50. File: `src/db/pool.ts:15`."

### CAVEMAN lite (sentences, no fluff)
**Before**: "The test failed because the mock wasn't configured correctly."
**After**: "Test failed: mock misconfigured. Fix: add `jest.mock('axios')` before import."

### CAVEMAN full (fragments, acronyms)
**Before**: "The authentication module needs to be updated to support the new OAuth2 flow."
**After**: "auth mod → OAuth2 flow. `src/auth/oauth.ts`."

### CAVEMAN ultra (abbreviations only)
**Before**: "Status: all tests passing, build successful, deployment ready."
**After**: "✅ tests pass | build ok | deploy rdy"

---

## C28 Depth — Testing Patterns

### 1. Compression Ratio Test
```bash
# Measure token reduction per level
echo "Original: $(cat response.md | wc -w) words"
echo "LEAN:     $(./compress lean response.md | wc -w) words"
echo "ULTRA:    $(./compress ultra response.md | wc -w) words"
echo "CAVEMAN:  $(./compress caveman response.md | wc -w) words"
```
**Pass**: LEAN ≥30% cut, ULTRA ≥50%, CAVEMAN ≥70%

### 2. Safety Preservation Test
```bash
# Verify NEVER CUT rules survive compression
./compress ultra "This command will DELETE ALL DATA in production — are you sure?" \
  | grep -q "DELETE ALL DATA" && echo "PASS" || echo "FAIL"
```
**Pass**: Safety warnings, critical caveats, confirmations preserved verbatim

### 3. Code Block Integrity Test
```bash
# Code/PRs must remain uncompressed at any level
./compress caveman '```ts\nfunction add(a,b){return a+b}\n```' \
  | diff - expected_output.ts && echo "PASS" || echo "FAIL"
```
**Pass**: Code blocks, PR diffs, function signatures unchanged

---

## C28 Depth — Edge Cases

### 1. Mixed Content (prose + code + safety)
**Input**: Explanation with code snippet and safety warning  
**Rule**: Prose compressed per level, code block untouched, safety warning verbatim  
**LEAN**: Prose trimmed, code intact, warning intact

### 2. Mid-Conversation Escalation
**Scenario**: Context at 35% → user asks complex question → context jumps to 45%  
**Rule**: Complete current response at LEAN, next response at ULTRA. Never switch mid-block.

### 3. User Trigger Override
**Input**: User says "status?" at context 20%  
**Rule**: Respond CAVEMAN ultra regardless of context level. Trigger word wins.

### 4. Protocol Output Exemption
**Input**: Analysis table, verification result, recommendation  
**Rule**: Remain detailed per protocol. Compression levels apply ONLY to user-facing responses.

---

## C28 Depth — Anti-Patterns (Additional)

### 1. Recursive Compression
**Bad**: Compress response, then compress again because "still too long"  
**Fix**: Choose correct level upfront using LEVEL SELECT table. If ULTRA not enough → CAVEMAN lite, not re-compress.

### 2. Context % Guessing
**Bad**: "Feels like we're at 60%" → apply ULTRA without checking  
**Fix**: Use `ctx_stats` tool or context-watchdog for actual %. Apply LEVEL SELECT table strictly.