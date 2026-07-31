---
name: llm-security
description: "Trigger: LLM, AI, prompt injection, RAG, OpenAI, Anthropic, Ollama, LangChain, agent, tool use, data exfiltration. Audit LLM integration security."
triggers: "LLM, AI, prompt injection, RAG, OpenAI, Anthropic, Ollama, LangChain, agent, tool use, data exfiltration, model"
---
## When to Use
Reviewing LLM integrations, AI features, RAG pipelines, or "is this LLM integration secure"

## SCAN DIMENSIONS (by integration type)

### Chat/Completion
- `grep -rn "openai\|anthropic\|ollama\|ChatOpenAI\|generateText" --include="*.{ts,js,py,go}"` → entry points
- `grep -rn "messages\.push\|role.*user" --include="*.{ts,js,py,go}"` → prompt construction (user input sanitized before injection?)
- `grep -rn "system.*message\|systemPrompt\|system_prompt" --include="*.{ts,js,py,go}"` → leakage in errors/responses?

### RAG Pipeline
- `grep -rn "retrieval\|embedding\|vector.*search\|similarity\|chunk" --include="*.{ts,js,py,go}"` → per-user access controls?
- `grep -rn "pinecone\|weaviate\|chroma\|qdrant\|pgvector" --include="*.{ts,js,py,go}"` → namespace/collection isolation?

### Tool Use / Agents
- `grep -rn "tool.*call\|function.*call\|tools.*=" --include="*.{ts,js,py,go}"` → privilege boundaries?
- `grep -rn "execute.*command\|invoke.*tool" --include="*.{ts,js,py,go}"` → sandboxing, rate limiting?

### Output Handling
- `grep -rn "innerHTML\|dangerouslySetInnerHTML" --include="*.{ts,js,jsx,tsx,vue}"` → XSS via LLM output
- `grep -rn "console\.log.*prompt\|logger.*prompt" --include="*.{ts,js,py,go}"` → PII in logs

### Config
- `grep -rn "temperature\|max_tokens\|model.*=" --include="*.{ts,js,py,yaml,yml}"` → bounds, pinning

## CHECKLIST

| Check | Sev | Pattern |
|-------|-----|---------|
| User input in system prompt | CRIT | Concatenated without delimiters |
| Output via innerHTML | HIGH | LLM response rendered unsanitized |
| RAG: no per-user filter | HIGH | Vector search returns all docs |
| Tool: no privilege boundary | HIGH | LLM calls admin tools from user ctx |
| System prompt leaked | HIGH | Full prompt in error/response |
| PII in LLM logs | HIGH | Prompt/response logged with user data |
| No token budget | MED | Unbounded max_tokens = cost DoS |
| Model not pinned | MED | Behavioral drift |
| No rate limiting | MED | Cost exhaustion |
| Multi-tenancy leak | MED | Shared vector DB without namespace |

## OUTPUT
```
## LLM Security: {scope}
### Summary
- Chat: {N} | RAG: {N} | Tools: {N} | Output: {N} | Config: {N}
### Issues
# CRITICAL: {type} in {file:line}
- Pattern: `{found}` → Fix: `{fix}`
```

## Rules
1. Prompt injection FIRST. 2. RAG per-user. 3. Tool privilege boundaries. 4. Output sanitization. 5. End: "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Refs
security-scanner · best-practices · quality-gate

## Anti-Patterns
Assume output safe because "just text" · Skip RAG access control · Ignore token budget · Miss system prompt leakage · Treat all LLM types same (chat≠RAG≠tool-use) · Miss output XSS
