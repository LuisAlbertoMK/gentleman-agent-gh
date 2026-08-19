---
name: llm-security
description: "Trigger: LLM, AI, prompt injection, RAG, OpenAI, Anthropic, Ollama, LangChain, agent, tool use, data exfiltration."
triggers: "LLM, AI, prompt injection, RAG, OpenAI, Anthropic, Ollama, LangChain, agent, tool use, data exfiltration, model"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Review LLM integrations, RAG pipelines, AI features — "is this secure?"

## SCAN DIMENSIONS
### Chat/Completion
- `grep -rn "openai\|anthropic\|ollama\|ChatOpenAI\|generateText" --include="*.{ts,js,py,go}"`
- `grep -rn "messages\.push\|role.*user" --include="*.{ts,js,py,go}"` → input sanitized?
- `grep -rn "system.*message\|systemPrompt\|system_prompt" --include="*.{ts,js,py,go}"` → leakage in errors?

### RAG Pipeline
- `grep -rn "retrieval\|embedding\|vector.*search\|similarity\|chunk" --include="*.{ts,js,py,go}"` → per-user ACL?
- `grep -rn "pinecone\|weaviate\|chroma\|qdrant\|pgvector" --include="*.{ts,js,py,go}"` → namespace isolation?

### Tool Use / Agents
- `grep -rn "tool.*call\|function.*call\|tools.*=" --include="*.{ts,js,py,go}"` → privilege boundaries?
- `grep -rn "execute.*command\|invoke.*tool" --include="*.{ts,js,py,go}"` → sandboxing/rate limit?

### Output Handling
- `grep -rn "innerHTML\|dangerouslySetInnerHTML" --include="*.{ts,js,jsx,tsx,vue}"` → XSS via LLM output
- `grep -rn "console\.log.*prompt\|logger.*prompt" --include="*.{ts,js,py,go}"` → PII in logs

### Config
- `grep -rn "temperature\|max_tokens\|model.*=" --include="*.{ts,js,py,yaml,yml}"` → bounds/pinning

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

## Refs
security-scanner · best-practices · quality-gate

---

> See [reference.md](docs/skills/llm-security/reference.md) for extended details, examples, and detailed patterns.