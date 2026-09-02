---
name: metricas
description: "Before/after delta + % comparison — git diff or bookmark mode, tokenization-aware, multi-language"
changelog: "2026-08-31 — SD 9.9→10 fix"
triggers:
  - "!metricas"
  - "!metrics"
  - "before after"
  - "delta"
  - "compare"
  - "token count"
  - "size change"
token_budget: 2446
---

# metricas — Before/After Delta + % Comparison

Measure codebase changes quantitatively — tokenization-aware diff analysis (git diff or bookmark modes), multi-language, percentage deltas.

**Trigger**: `!metricas`, `!metrics`, "before after", "delta", "compare", "token count", "size change"

## Two Modes
| Mode | Use Case | How It Works |
|---|---|---|
| git diff | Compare two commits/branches | `git diff <base>..<head> -- <paths>` → tokenize → delta |
| bookmark | Working tree vs saved snapshot | Save baseline → work → compare → tokenize → delta |

## Tokenization
| Language | Tokenizer | Fallback |
|---|---|---|
| Python | `ast` nodes → `tokenize` | whitespace split |
| TS/JS | `acorn`/`babel` | regex `[A-Za-z_$][A-Za-z0-9_$]*` |
| Go | `go/token` | regex `\b\w+\b` |
| Rust | `syn` | regex `[a-zA-Z_][a-zA-Z0-9_]*` |
| Generic | whitespace + punctuation | N/A |

AST nodes for structural langs, lexical tokens otherwise. Whitespace/comments excluded.

## CLI
```
metricas [mode] [options]
Modes: git-diff (default) | bookmark
--base <ref> (git-diff) or bookmark name | --head <ref> (default HEAD)
--paths <glob> | --lang <py|ts|js|go|rs|auto> | --tokenizer <ast|lexical|whitespace>
--format <table|json|csv|markdown> | --threshold <pct> (default 10)
--save-baseline <name> | --compare-baseline <name> | --list-baselines | --delete-baseline <name>
```

## Reference
Worked examples, testing patterns, edge cases, anti-patterns → docs/skills/metricas/reference.md
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: auto-metrics | performance-tracker

