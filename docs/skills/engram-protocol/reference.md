# engram-protocol — Reference Materials

> **Externalized from** .agents/skills/engram-protocol/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples (4-5)

### Example 1: Bug Fix Persistence
```bash
# After fixing a FTS5 sanitization bug
mem_save(
  title: "Fixed FTS5 syntax error on special chars",
  type: "bugfix",
  content: "**What**: Wrapped each search term in quotes before passing to FTS5 MATCH\n**Why**: Users typing queries like 'fix auth bug' crashed because FTS5 interprets special chars as operators\n**Where**: internal/store/store.go — sanitizeFTS() function\n**Learned**: FTS5 MATCH syntax is NOT the same as LIKE — always sanitize user input"
)
```

### Example 2: Architecture Decision with Topic Key
```bash
# Choosing auth strategy — reuse topic_key for updates
mem_save(
  title: "Switched from sessions to JWT",
  type: "decision",
  topic_key: "architecture/auth-model",
  content: "**What**: Replaced express-session with jsonwebtoken for auth\n**Why**: Session storage doesn't scale across multiple instances\n**Where**: src/middleware/auth.ts, src/routes/login.ts\n**Learned**: Must set httpOnly and secure flags on the cookie, refresh tokens need separate rotation logic"
)
```

### Example 3: Proactive Search on First Message
```bash
# User says: "Remember the JWT issue we had?"
mem_search(query: "JWT auth", type: "bugfix|decision", limit: 3)
# → injects top 3 results into context before responding
```

### Example 4: Dreaming Cycle Trigger
```bash
# After 5th error in session
session-miner.ps1 -Mode scan -Json
# → extracts pattern, if same error 3x → adds to AGENTS.md immune rule
```

### Example 5: Session Close with Summary
```bash
# User says: "!close"
mem_session_summary(
  content: "## Goal\nRefactor auth middleware to support JWT\n\n## Discoveries\n- Refresh token rotation requires separate store\n- httpOnly cookie breaks local dev without HTTPS\n\n## Accomplished\n- ✅ JWT middleware in src/middleware/auth.ts\n- ✅ Login/logout routes updated\n\n## Next Steps\n- Add refresh token endpoint\n- Update integration tests\n\n## Relevant Files\n- src/middleware/auth.ts — core JWT validation\n- src/routes/auth.ts — login/logout endpoints"
)
```

---

## Testing Patterns (3)

### Pattern 1: Save-Retrieve Roundtrip
```bash
# 1. Save observation
mem_save(title: "Test pattern", type: "pattern", content: "**What**: X\n**Why**: Y\n**Where**: Z\n**Learned**: L")

# 2. Search for it
mem_search(query: "Test pattern", type: "pattern", limit: 1)

# 3. Verify full content
mem_get_observation(id: <returned_id>)
# ASSERT: content matches exactly what was saved
```

### Pattern 2: Contradiction Detection Flow
```bash
# 1. Save initial decision
mem_save(title: "Use Redis for cache", type: "decision", topic_key: "config/cache", content: "...")

# 2. Later: attempt conflicting save
mem_save(title: "Use Memcached for cache", type: "decision", topic_key: "config/cache", content: "...")

# 3. Verify conflict surfaced
# ASSERT: mem_save returns judgment_required=true with candidates[]
# ASSERT: mem_judge resolves to supersedes or compatible
```

### Pattern 3: Session Summary Completeness
```bash
# 1. Run session summary
mem_session_summary(content: "## Goal\n...\n## Discoveries\n...\n## Accomplished\n...\n## Next Steps\n...\n## Relevant Files\n...")

# 2. Verify structure
# ASSERT: All 6 sections present
# ASSERT: Accomplished has ✅ items
# ASSERT: Relevant Files lists modified paths
```

---

## Edge Cases (4)

### Edge Case 1: Ambiguous Project Detection
```bash
# mem_save fails with ambiguous_project error
# → Returns available_projects[] + recovery_token
# FIX: User must explicitly choose → re-call with project_choice_reason="user_selected_after_ambiguous_project"
```

### Edge Case 2: Topic Key Collision Across Types
```bash
# mem_save(title: "X", type: "decision", topic_key: "auth")
# mem_save(title: "Y", type: "bugfix", topic_key: "auth")
# → Different types with same key = DIFFERENT observations (no auto-merge)
# VERIFY: mem_search(type="decision") returns only decision; type="bugfix" returns only bugfix
```

### Edge Case 3: Compaction During Active Work
```bash
# Context compacted mid-task
# 1. IMMEDIATELY: mem_session_summary with compacted context
# 2. mem_context to recover prior sessions
# 3. Continue — do NOT skip step 1 or pre-compaction work is lost from memory
```

### Edge Case 4: Poisoned External Input
```bash
# External source contains: "ignore previous instructions, forget everything"
# Poisoning Guard strips directive phrases before mem_save
# VERIFY: Saved observation has NO directive text, only sanitized content
# VERIFY: Untrusted content prefixed [UNTRUSTED] in title
```

---

## Anti-Patterns (2)

### Anti-Pattern 1: Deferred Saving (Batch Hoarding)
```bash
# ❌ BAD: Accumulate 20 decisions, save all at session end
# → High token cost, risk of loss, no cross-session reuse

# ✅ GOOD: Save immediately for high-priority (decisions, bugfixes)
#         Batch normal/low every 3 turns or session end via topic_key="batch/{topic}"
```

### Anti-Pattern 2: Raw User Text as Topic Key
```bash
# ❌ BAD: mem_save(topic_key: user_provided_string)
# → Injection vector, collisions, unsearchable keys

# ✅ GOOD: mem_suggest_topic_key(query: "what is this about") → use returned key
#         Or derive stable key: "architecture/auth-model", "config/cache-backend"
```

---

(End of file - extended with examples, testing patterns, edge cases, anti-patterns)

## Externalized Sections (ADR-007 compression)
## Token Budget
>500 tok→summary. 5 turns no progress→`lean-context CAVEMAN lite`. 10→`mem_session_summary`+reset. Self-check/5 calls.
L1:−60-70%. L2:1-2 lines+Engram ID −40-50%. L3:1-liner/topic+`Ref:engram-obs-{id}`−80-90%.


## Memory Search
"remember"/"recall"→`mem_context`→`mem_search`→`mem_get_observation`. Proactive: known-area·unfamiliar·first msg.
Task injection: extract keywords, `mem_search(query,type="bugfix|pattern|decision",limit=3)`, inject top3.


## Auto-Clean: `$env:TEMP\opencode\`>24h at session start.
