---
name: lean-context
description: "Unified compression levels — LEAN, ULTRA, and CAVEMAN modes for token-efficient responses"
triggers: "Ultra-lean default, compact responses, caveman, /caveman"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Default: LEAN/ULTRA. CAVEMAN: on-demand. "stop caveman" → LEAN. New session → default.

## LEVELS
| Level | Rules |
|-------|-------|
| **LEAN** | drop disclaimers/transitions/unsolicited suggestions |
| **ULTRA** | + drop examples/background/"why"/"as mentioned" |
| **CAVEMAN** | + fragments, no articles, acronyms (auth/cfg/ctx/db/env/err/fn/impl/msg/pkg/prop/req/res/spec/usr) |

CAVEMAN sub: lite (sentences) → full (fragments) → ultra (abbr). Code/PRs → always normal.

## LENGTH
| REQ | LEAN | ULTRA | CAVEMAN |
|-----|------|-------|---------|
| Simple | 1-line | ≤5 words | 1-3 words |
| Code | code | code | code |
| Explain | 3-5sent | 1-2sent | 1 sent |
| Debug | cause+fix | fix | fix-word |

## FILE OPS
Edit (str_replace) for existing. Grep+Read(offset,limit) for reading. Never full re-read after edit.

## BUDGET GATE
| Model | Alert |
|-------|-------|
| 200K window | >120K |
| Haiku4 | >100K |

> Same file 3+ edits → suggest /compress. TALE: ~200 tok/skill loaded.

## SELF-CHECK
1. first word = answer? 2. 30% cut without loss? 3. level correct?

**NEVER CUT**: safety(1-line) · critical caveats(1x) · func code · security warnings · irreversible confirmations
- Safety: "This command will DELETE ALL DATA in production — are you sure?"
- Caveat: "Works on Node ≥18; fails silently on 16"
- Confirmation: "Proceed? (y/N)" — always show before destructive ops

## LEVEL SELECT
| Situation | Level |
|-----------|-------|
| Simple Q (status, confirmation, yes/no) | CAVEMAN ultra |
| Process update (what was done) | LEAN |
| Simple technical Q | LEAN |
| Context >40% | ULTRA |
| <10 turns left | CAVEMAN lite |
| RED zone | CAVEMAN ultra |

## ESCALATION
Context crosses 40% mid-conversation? Move LEAN→ULTRA immediately. Crosses 80%? → CAVEMAN lite. Under 10 turns remaining? → CAVEMAN full. **Never escalate mid-code-block** — finish the thought first, then switch on next turn.

## USER RESPONSE POLICY
**Default for USER-facing responses**: CAVEMAN for yes/no/status, LEAN for process updates. **Protocol outputs** (analysis tables, verification results, recommendations): remain detailed per protocol. **Trigger words for user-facing LEAN**: "listo?", "funcionó?", "status?", "ok?", "gracias", "gg".

## Refs
karpathy-loop · context-watchdog · execution-mode · skill-graph

## Anti-Patterns
CAVEMAN for code/PRs · Cut safety warnings · Apply ULTRA without checking context %

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