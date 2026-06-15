# ANTI-PATTERN CATALOG

> Every documented failure = permanent immunity.
> Loaded at start of every session. Updated after every corrected mistake.
> Compact format: Symptom (1L) | Root cause (1L) | Fix (1L) | Prevention (1L)
> Details → `docs/anti-patterns/{date}-{name}.md`

---

| # | Date | Pattern | Symptom | Root cause | Fix | Prevention |
|---|------|---------|---------|------------|-----|------------|
| 1 | 2026-05-26 | Premature solution | Coded before understanding requirement | Didn't ask clarifying questions | STOP → re-read → confirm before code | "No code before user confirms intent" gate |
| 2 | 2026-05-26 | Over-explaining tool output | Re-ran tool, re-explained output in text | Not trusting tool output | Tool output = sufficient. Add value or silence. | "Don't echo the tool" |
| 3 | 2026-05-26 | Context restatement | "You asked about X... well..." before answering | Over-politeness | Zero restatement. Answer assumes context. | "User knows what they asked" |
| 4 | 2026-05-26 | Filler words | "Sure!", "Great question!", "I think" — zero signal | Conversational style leaking | Zero pleasantries. Direct only. | "If no info → delete" |
| 5 | 2026-05-28 | Redundant examples | 2-3 examples when 1 suffices | Not trusting generalization | 1 example per concept. Amplify on demand. | "One example. Max." |
| 6 | 2026-05-28 | No-evidence self-assessment | "Done" without verification | Overconfidence | Always produce evidence (test, log). Default-FAIL. | "If not verified, not done" |
| 7 | 2026-06-03 | Pre-Flight Gate order | Engram check after skill creation | Gate design flaw | Check Engram BEFORE creation. | "Checks before decisions, not after" |
| 8 | 2026-06-05 | TDZ from misplaced require | `require()` below first use → `ReferenceError` in production | `const` not hoisted in CJS | ALL `require()` at top of file. | Imports→schema→constants→code. Never reverse. |
| 9 | 2026-06-07 | PS sort+join concatenates names | Import members glued without comma in 5 files | `-split`/`-join` loses comma boundaries on single tokens | Use `Edit` tool per file for TS imports, never PS string munge. | Build incrementally after 2-3 files. |
| 10 | 2026-06-11 | Join-Path positional limit | `Join-Path $a 'b' 'c'` crashes in PS5.1 | PS5.1 only accepts 2 positional params | Use named params: `-Path`/`-ChildPath`. | Never >2 positional args without verification. |
| 11 | 2026-06-11 | Trigger regex assumes quote after colon | Regex `Trigger:\s*"` fails on `Trigger: Task, "score"` | `\s*` only matches whitespace, not intervening text | `Trigger:[^"]*"\w` — colon then non-quote chars then quote. | After `Key:`, use `.*?` or `[^"]*` to bridge text. |
| 12 | 2026-06-13 | Verbose inline examples waste context | +67% tokens on web-quality skills, 70% redundant | Skills designed as tutorials, not runtime agent skills | Move examples to `references/`. Keep 1 snippet per criterion max. | Compact before adding: ≤150L knowledge, ≤80L utility. |
| 13 | 2026-06-14 | Uninitialized $warnings | `$warnings += ...` null error in drift script | Missing `$warnings = @()` before append | Always init all accumulators before first +=. | Lint PS5.1 with PSScriptAnalyzer before commit. |

## Prevention cheat sheet
1. **No code before user confirms understanding** — "¿Entendí bien?" gate
2. **Tool output = sufficient** — don't echo, add value or silence
3. **User knows what they asked** — zero restatement, jump to answer
4. **One example per concept** — amplify only on demand
5. **If not verified, it's not done** — always produce evidence
6. **Checks before decisions, not after** — order matters
7. **Imports → schema → constants → code** — never reverse
8. **Build incrementally** after 2-3 files, not after 19
9. **Name all positional args** — never >2 without verification
10. **Init all accumulators** before first `+=`
