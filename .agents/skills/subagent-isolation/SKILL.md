---
name: subagent-isolation
description: "Maintain clean context boundaries between delegated agents — prevent hallucination cascades, cross-contamination, and enforce error isolation"
triggers: "Subagent isolation, context boundaries"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

Trigger: Delegating tasks, spawning subagents, multi-agent workflows.
## ISOLATION RULES
### 1. Fresh context per delegationEach `delegate` or `task` call starts with a CLEAN context. Do NOT assume prior knowledge.- Include ALL necessary context in the delegation prompt- Reference Engram IDs for past decisions (don't paste full context)- If subagent needs file context â†’ include file paths + what to look for
### 2. No cross-contamination| Rule | Why ||------|-----|| Never share internal state between subagents | Prevents hallucination cascades || Each subagent gets independent tool access | One agent's error shouldn't affect another || Parallel delegations must be truly independent | If B depends on A â†’ serialize, don't parallelize |
### 3. Dependency declarationWhen delegating, declare what the subagent needs:
```delegate(prompt, agent="explore")  # Needs: file paths to read, decision context (Engram IDs)  # Does NOT need: full conversation history, system prompt details```
### 4. Result isolation- Each delegate returns its OWN output â€” don't merge unless orchestrating- If results conflict â†’ raise to orchestrator, don't reconcile in subagent- Subagents NEVER modify global state or shared files without explicit instructions
### 5. Context cleanupAfter delegation completes:- Don't retain subagent's full output in main context â†’ extract only what's needed- Reference results by delegation ID for later retrieval- If output is large â†’ summarize before carrying forward
### 6. Error boundaries| Error | Action ||-------|--------|| Subagent times out | Retry once with cleaner prompt, then escalate || Subagent returns wrong output | Log to Engram, re-delegate with corrected context || Subagent hallucinates | Flag as context contamination â†’ check isolation rules |
