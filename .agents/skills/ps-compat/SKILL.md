---
name: ps-compat
description: "PowerShell 5.1/7 compatibility + encoding pre-write checklist - consolidates anti-patterns #10/#13/#14/#16/#20, GAP-2 hook incident, P1-1 CRLF false positives"
triggers: "powershell 5.1, ps5, ps7, ps compatibility, encoding, CRLF, BOM, PSSA, Join-Path, cmatch, requires, bash-safe"
changelog: "2026-09-02 — created: consolidates ANTI-PATTERN-CATALOG #10/#13/#14/#16/#20 + GAP-2 + P1-1 CRLF trap"
token_budget: 3000
---

## When to Use

- Before writing or modifying any `.ps1` file.
- Before writing regex that scans Windows-authored files (frontmatter, docs, logs).
- When a script must run in both PS5.1 hook context and PS7.
- When output shows mojibake or garbled text (encoding suspect).

## Rules

1. Declare runtime: `#requires -Version 7.0` if PS7-only;
   for PS5.1 compat avoid PS7-only syntax
   (ternary `? :`, `&&`/`||`, `??`).
2. PS5.1 rejects `&&`/`||` as pipeline chain operators -
   use `if`/`then` or Invoke-Bash (`scripts/bash-safe.ps1`).
3. Join-Path: named params only (`-Path`/`-ChildPath`),
   never >2 positional args (anti-pattern #10).
4. Initialize accumulators before first `+=`:
   `$errors = @()` (anti-pattern #13).
5. `-match` is case-INSENSITIVE in PS;
   use `-cmatch` when casing matters (anti-pattern #14).
6. Encoding: write `.ps1` ASCII-only when possible;
   Unicode → UTF-8 with BOM; always pass `-Encoding UTF8` to
   `Get-Content`/`Set-Content`/`Out-File` (anti-pattern #16).
7. Regex vs Windows files: use `\r?\n` not `\n`;
   multiline `(?m)^` — CRLF breaks `^key:` anchored scans
   (P1-1: ~10 false positives, doc:31-46).
8. In regex alternation write `[|]` not escaped `\|` -
   quality gates raw-scan for `||` and false-positive
   (anti-pattern #20).
9. Mojibake in tool output may be console codepage
   display, NOT file corruption — verify file bytes
   (hex/UTF8) before claiming corruption;
   do not "fix" clean files.

## Verification

1. PSSA clean or documented baseline -
   run `Invoke-ScriptAnalyzer` before commit.
2. Parse test: AST parse of the file passes
   (`[Parser]::ParseFile` or `pwsh -c "Parse"`).
3. For encoding-sensitive edits, re-read with
   `-Encoding UTF8` and confirm no U+FFFD.
4. If regex, test against both LF and CRLF samples.

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|---|---|---|
| "This repo runs PS7, PS5.1 rules are legacy" | Skipping chain-operator/encoding rules | git hooks and CI may execute PS5.1 - GAP-2 incident 2026-09-01 |
| "One regex \\n works fine locally" | Unanchored LF-only scans | Windows files are CRLF - P1-1 audit:46 documents the cost |
| "Small script, skip #requires" | Missing version declaration | Gate + cross-ref check flag it; consistency beats size |

## Red Flags

- Scripts with no `#requires` header.
- `Get-Content` without `-Encoding` on non-ASCII files.
- `\n`-only regex in scans targeting Windows files.
- `&&` inside strings destined for PS5.1 execution.
- Empty `catch` blocks around encoding operations.

## Refs

Cross-Refs: quality-gate | command-wrapper | bash-safe (scripts/bash-safe.ps1) | ANTI-PATTERN-CATALOG.md:21,24,25,27,31 | docs/mejoras/2026-09-01-gap-scan-repo.md:17-21 | docs/mejoras/2026-09-01-p1-1-spec-audit.md:31-46
---

docs/skills/ps-compat/reference.md
---