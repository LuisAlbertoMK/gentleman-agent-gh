---
name: llm-security
description: "Trigger: LLM, AI, prompt injection, RAG, OpenAI, Anthropic, Ollama, LangChain, agent, tool use, data exfiltration."
triggers: "LLM, AI, prompt injection, RAG, OpenAI, Anthropic, Ollama, LangChain, agent, tool use, data exfiltration, model"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2240
---

## When to Use
Review LLM integrations, RAG pipelines, AI features — "is this secure?"

## CHECKLIST
| Check | Sev | Pattern |
|-------|-----|---------|
| User input in system prompt | CRIT | Concatenated without delimiters |
| Output via innerHTML | HIGH | Unsanitized LLM response |
| RAG: no per-user filter | HIGH | Vector search returns all docs |
| Tool: no privilege boundary | HIGH | LLM calls admin tools from user ctx |
| System prompt leaked | HIGH | Full prompt in error/response |
| PII in LLM logs | HIGH | Prompt/response logged w/ user data |
| No token budget | MED | Unbounded max_tokens = cost DoS |
| Model not pinned | MED | Behavioral drift |
| No rate limiting | MED | Cost exhaustion |
| Multi-tenancy leak | MED | Shared vector DB without namespace |

## OUTPUT
```
## LLM Security: {scope}
### Summary - Chat:{N} RAG:{N} Tools:{N} Output:{N} Config:{N}
### Issues # CRITICAL: {type} in {file:line} - Pattern: `{found}` → Fix: `{fix}`
```

## Rules
1. Prompt injection FIRST.
2. RAG per-user.
3. Tool privilege boundaries.
4. Output sanitization.
5. "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "No secrets in this repo" | Skipping secrets scan | grep -rn process.env + npm audit before commit |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Skipping secrets scan → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- grep -rn process.env + npm audit before commit
- cross-ref-check.ps1 → SKILL.md OK
## Refs
security-scanner · best-practices · quality-gate

---

> See [reference.md](docs/skills/llm-security/reference.md) for extended details, examples, and detailed patterns.

