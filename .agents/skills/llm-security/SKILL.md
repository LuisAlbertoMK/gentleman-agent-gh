---
name: llm-security
description: "Trigger: LLM, AI, prompt injection, RAG, OpenAI, Anthropic, Ollama, LangChain, agent, tool use, data exfiltration. Audit LLM integration security."
license: Apache-2.0
metadata:
  tags: [security, ai]
  author: gentleman-vMK
  version: "1.0"
  changelog: "1.0: initial version — prompt injection, data exfil, RAG poisoning, tool privilege"
---
## WHEN: Reviewing LLM integrations, AI features, RAG pipelines, or user asks "is this LLM integration secure"

## SCAN DIMENSIONS

**Prompt Injection**: `grep -rn "user.*input\|prompt.*=\|system.*message\|messages\.push" --include="*.{ts,js,py,go}"` → check user input injected into prompts without sanitization, system prompt leakage, instruction override
**Data Exfiltration**: `grep -rn "output.*channel\|response.*send\|return.*data" --include="*.{ts,js,py,go}"` → check if LLM output can leak PII, secrets, or internal data via response/logging/webhook
**RAG Pipeline**: `grep -rn "retrieval\|embedding\|vector\|similarity\|chunk" --include="*.{ts,js,py,go}"` → check document access controls (can user A retrieve user B's docs?), chunk sanitization, index poisoning
**Tool Use**: `grep -rn "tool.*call\|function.*call\|execute.*command\|run.*tool" --include="*.{ts,js,py,go}"` → check privilege escalation (LLM calling tools the user shouldn't access), sandboxing, rate limiting on tool calls
**Model Config**: `grep -rn "temperature\|top_p\|max_tokens\|model" --include="*.{ts,js,py,yaml,yml}"` → check model version pinning, temperature bounds (high temp = unpredictable), token limits (cost/DoS)

## QUICK PATTERNS

**JS/TS**: `grep -rn "openai\|anthropic\|ollama\|langchain\|llamaindex\|ai\.chat\|generateText" --include="*.{js,ts}"` · `grep -rn "system.*prompt\|instructions.*=" --include="*.{js,ts}"`
**Python**: `grep -rn "openai\|anthropic\|ollama\|langchain\|llama.index\|ChatOpenAI" --include="*.py"` · `grep -rn "system_message\|prompt_template\|PromptTemplate" --include="*.py"`
**Go**: `grep -rn "openai-go\|anthropic-go\|ollama" --include="*.go"`

## VULNERABILITY CHECKLIST

| Check | Severity | Pattern |
|-------|----------|---------|
| User input in system prompt | CRITICAL | User text concatenated into system message without delimiters |
| No output sanitization | HIGH | LLM response sent directly to client without filtering |
| RAG: no per-user doc filtering | HIGH | Vector search returns all docs regardless of user permissions |
| Tool use: no privilege boundary | HIGH | LLM can call admin tools from user context |
| System prompt in API response | HIGH | Full system prompt leaked in error/response payload |
| No token budget on LLM calls | MEDIUM | Unbounded `max_tokens` = cost DoS |
| Model not version-pinned | MEDIUM | Using `gpt-4` instead of `gpt-4o-2024-08-06` = behavioral drift |
| No rate limiting on LLM endpoint | MEDIUM | Unlimited LLM calls = cost exhaustion |
| Logging full prompts/responses | MEDIUM | PII/secrets in LLM logs |

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
1. Check prompt injection FIRST — it's the LLM equivalent of SQL injection. 2. Verify RAG document access controls are per-user, not global. 3. Tool use must have privilege boundaries (LLM can't escalate beyond user's permissions). 4. Always set max_tokens and temperature bounds. 5. End with: "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Refs
security-scanner · best-practices · quality-gate

## Anti-Patterns
Assume LLM output is safe because it's "just text" · Skip RAG access control check · Ignore token budget (cost risk) · Miss system prompt leakage · Treat all LLM integrations the same (chat vs RAG vs tool-use are different threat models)
