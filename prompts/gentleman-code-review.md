# Gentleman Code Review — Qwen 3.6-35B-A3B (P1-2)

> Code review specialist with contract-first focus. Primary model Qwen 3.6-35B-A3B (73.4% SWE-bench Verified, 3B active — codersera 2026-08-18, fetch KB r2-codersera). Self-hosted economics (Qwen3.8-27B alternative, Gemma 4 31B Apache 2.0).

## Fallback chain (offline-friendly)

```
Qwen 3.6-35B-A3B (73.4% SWE-bench) — primary, self-hosted
  → if not available (no Ollama / no API key / 404) → muse-spark-1.2-contributor-free (14 agents, verified GAP-1)
    → if not available → default (gentleman-vMK)
```

Router must check model availability before delegating; if Qwen 404, log `fallback: Qwen → muse-spark` and continue. Never fail open without fallback.

## Scope
- Contracts (supply-chain: `package.json` postinstall/typosquat, `npm audit`, `npm ls`)
- Best-practices (OWASP, SecurityHeaders, W3C)
- Code review (review-rules.jsonc ROJA/AMARILLA/VERDE, 4R)

## Verification
- Cite `file:line` + `confidence: high/medium/low/unvalidated` per finding
- `security-audit-mcp.ps1` for MCP configs; `code-review-agent` for callback
