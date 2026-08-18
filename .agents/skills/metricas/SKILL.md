---
name: metricas
description: Before/after delta + % comparison — git diff or bookmark mode, tokenization-aware, multi-language
triggers:
  - "!metricas"
  - "!metrics"
  - "before after"
  - "delta"
  - "compare"
  - "token count"
  - "size change"
---

# metricas — Before/After Delta + % Comparison

**Purpose**: Measure codebase changes quantitatively — tokenization-aware diff analysis with git diff or bookmark modes, multi-language support, percentage deltas.

**Trigger**: `!metricas`, `!metrics`, "before after", "delta", "compare", "token count", "size change"

---

## Core Concepts

### Two Modes

| Mode | Use Case | How It Works |
|------|----------|--------------|
| **git diff** | Compare two commits/branches | `git diff <base>..<head> -- <paths>` → tokenize → delta |
| **bookmark** | Compare working tree to saved snapshot | Save baseline → work → compare → tokenize → delta |

### Tokenization Strategies

| Language | Tokenizer | Fallback |
|----------|-----------|----------|
| Python | `ast` (nodes) → `tokenize` (tokens) | whitespace split |
| TypeScript/JS | `acorn` / `babel` | regex `/[A-Za-z_$][A-Za-z0-9_$]*/` |
| Go | `go/token` | regex `/\b\w+\b/` |
| Rust | `syn` | regex `/[a-zA-Z_][a-zA-Z0-9_]*/` |
| Generic | whitespace + punctuation split | N/A |

**Token definition**: AST nodes for structural languages, lexical tokens for others. Whitespace/comments excluded.

---

## CLI Interface

```bash
metricas [mode] [options]

Modes:
  git-diff    Compare two git refs (default)
  bookmark    Save/compare against baseline

Options:
  --base <ref>          Base commit (git-diff) or bookmark name (bookmark)
  --head <ref>          Head commit (default: HEAD)
  --paths <glob>        File glob(s) to include (default: all tracked)
  --lang <lang>         Force language tokenizer (py, ts, js, go, rs, auto)
  --tokenizer <name>    Override: ast, lexical, whitespace
  --format <fmt>        Output: table, json, csv, markdown (default: table)
  --threshold <pct>     Flag changes exceeding % (default: 10)
  --save-baseline <name>  Bookmark mode: save current state as baseline
  --compare-baseline <name> Bookmark mode: compare against saved baseline
  --list-baselines       List saved bookmarks
  --delete-baseline <name> Delete a bookmark
```

---

## Output Schema

```json
{
  "mode": "git-diff|bookmark",
  "base": "abc1234",
  "head": "def5678",
  "summary": {
    "files_changed": 12,
    "tokens_before": 45230,
    "tokens_after": 47891,
    "delta_tokens": 2661,
    "delta_pct": 5.88,
    "lines_added": 342,
    "lines_removed": 198,
    "delta_lines": 144
  },
  "by_file": [
    {
      "path": "src/auth.ts",
      "lang": "typescript",
      "tokens_before": 1240,
      "tokens_after": 1456,
      "delta_tokens": 216,
      "delta_pct": 17.42,
      "lines_added": 45,
      "lines_removed": 12,
      "status": "modified"
    }
  ],
  "by_language": {
    "typescript": { "before": 28400, "after": 30100, "delta_pct": 5.99 },
    "python": { "before": 16830, "after": 17791, "delta_pct": 5.71 }
  },
  "flagged": ["src/auth.ts:17.42%"]
}
```
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/metricas/reference.md

---
