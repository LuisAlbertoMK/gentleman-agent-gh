---
name: karpathy-prompt
description: >
  Karpathy method: minimal high-quality prompts.
  Trigger: Short/efficient prompts, "método Karpathy", "menos tokens", "LLM Wiki", "context compilation".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## Fundamento
"Write a prompt like explaining to a smart junior dev sitting next to you."
More context ≠ better. Less is more.

## 5 Golden Rules
1. **Identity + Task = Enough** — "Eres [role] specialized in [domain]. Task: [specific]."
2. **Minimal structure** — NO 10+ instruction lists. NO unnecessary paragraphs. YES 1-2 concrete examples. YES expected output format.
3. **Format IS instructions** — "Respond ONLY in JSON: {"key": "value"}"
4. **Constraints = Format** — Max X chars · Code only, no comments · Ignore all except [X]
5. **Implicit Chain of Thought** — NO "think step by step". If reasoning needed: "Reason ONLY if ambiguous."

## LLM Wiki Pattern (v1.1)
3-layer structure:
- Layer 1: Raw sources (notes, docs, code)
- Layer 2: LLM-compiled wiki pages (structured markdown)
- Layer 3: index.md (lightweight map, ~200 tokens)

### Pre-Compiled Context
1. Identify relevant files (paths, components, deps)
2. Generate structured context map (~3-5K tokens)
3. Use as input instead of exploring code

### Context Map Template
```
# Project Context (~3-5K tokens)
## Routes/API | ## Components | ## Dependencies
## Hot Files | ## Env/Middleware | ## Schema
```

## Templates
| Type | Tokens | Format |
|------|--------|--------|
| Micro | 20-50 | `Traducí al [lang]: [text]` |
| Simple | 50-100 | `Eres [role]. [clear task].` |
| With Output | 100-200 | `[min context] Output: [exact format]` |
| With Example | 150-300 | `[context] Example: [brief] Generate: [request]` |
| With Constraints | 100-200 | `[context] Constraints: [1-2 max] Output: [format]` |

## Anti-Patterns
| NO | YES |
|----|-----|
| "Be very detailed and precise" | "Be precise" |
| "Think step by step" | Omit — already does it |
| 10+ rule lists | 2-3 constraints max |
| "You're an expert in..." × 3 | One clear identity |
| Full context each query | Pre-compiled wiki |

## Token Budget
| Component | Approx tokens |
|-----------|--------------|
| Identity + Task | ~20-50 |
| + 1 example | +100-200 |
| + constraints | +50-100 |
| + output format | +30-50 |
| **Optimal TOTAL** | **50-300** |

## Decision Tree
```
START
├─ Needs role? → Yes: "Eres X." | No: skip
├─ Needs format? → Yes: "Output: [format]" | No: skip
├─ Needs example? → Yes: 1 max | No: skip
└─ Constraints? → Yes: 2-3 max | No: done
```
