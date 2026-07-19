---
name: llm-security
description: "Trigger: LLM, AI, prompt injection, RAG, OpenAI, Anthropic, Ollama, LangChain, agent, tool use, data exfiltration. Audit LLM integration security."
license: Apache-2.0
metadata:
  tags: [security, ai]
  author: gentleman-vMK
  version: "1.2"
  changelog: "1.2: aggressive compression — 741→~560 tokens · 1.1: Karpathy · 1.0: initial"
---
## WHEN: Reviewing LLM integrations, AI features, RAG pipelines, or "is this LLM integration secure"

## SCAN DIMENSIONS

**Prompt Injection**: `grep -rn "user.*input\|prompt.*=\|system.*message\|messages\.push" --include="*.{ts,js,py,go}"` → user input in prompts without sanitization, system prompt leakage
**Data Exfiltration**: `grep -rn "output.*channel\|response.*send\|return.*data" --include="*.{ts,js,py,go}"` → LLM output leaking PII/secrets via response/logging/webhook
**RAG Pipeline**: `grep -rn "retrieval\|embedding\|vector\|similarity\|chunk" --include="*.{ts,js,py,go}"` → per-user doc access controls, chunk sanitization, index poisoning
**Tool Use**: `grep -rn "tool.*call\|function.*call\|execute.*command\|run.*tool" --include="*.{ts,js,py,go}"` → privilege escalation, sandboxing, rate limiting on tool calls
**Model Config**: `grep -rn "temperature\|top_p\|max_tokens\|model" --include="*.{ts,js,py,yaml,yml}"` → version pinning, temperature bounds, token limits (cost/DoS)

## VULNERABILITY CHECKLIST

| Check | Sev | Pattern |
|-------|-----|---------|
| User input in system prompt | CRIT | User text concatenated into system msg without delimiters |
| No output sanitization | HIGH | LLM response sent directly to client |
| RAG: no per-user filtering | HIGH | Vector search returns all docs regardless of permissions |
| Tool: no privilege boundary | HIGH | LLM can call admin tools from user context |
| System prompt leaked | HIGH | Full prompt in error/response payload |
| No token budget | MED | Unbounded `max_tokens` = cost DoS |
| Model not pinned | MED | `gpt-4` instead of `gpt-4o-2024-08-06` = drift |
| No rate limiting | MED | Unlimited LLM calls = cost exhaustion |

## OUTPUT FORMAT

```
## LLM Security: {scope}
### Summary
- Prompt Injection: {N} | Data Exfil: {N} | RAG: {N} | Tool Use: {N} | Config: {N}
### Issues (CRITICAL/HIGH/MEDIUM/LOW)
# CRITICAL: {type} in {file:line}
- Pattern: `{found}` → Fix: `{fix}`
```

## RULES
1. Prompt injection FIRST — LLM equivalent of SQL injection. 2. RAG access controls per-user. 3. Tool privilege boundaries. 4. Set max_tokens + temperature bounds. 5. End: "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Refs
security-scanner · best-practices · quality-gate

## Anti-Patterns
Assume LLM output is safe because "just text" · Skip RAG access control · Ignore token budget · Miss system prompt leakage · Treat all LLM integrations the same (chat≠RAG≠tool-use)
