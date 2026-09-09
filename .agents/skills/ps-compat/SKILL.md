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

1. Declare runtime: `#requires -Version 7.0` if PS7-only; PS5.1-compat → avoid ternary `? :`, `&&`/`||`, `??`.
2. PS5.1 rejects `&&`/`||` — use `if`/`then` or Invoke-Bash (`scripts/bash-safe.ps1`).
3. Join-Path: named params only (`-Path`/`-ChildPath`), never >2 positional (anti-pattern #10).
4. Init accumulators before `+=`: `$errors = @()` (#13).
5. `-match` is case-INSENSITIVE; use `-cmatch` when casing matters (#14).
6. Write `.ps1` ASCII-only when possible; Unicode → UTF-8 with BOM; always `-Encoding UTF8` on `Get/Set-Content`/`Out-File` (#16).
7. Windows files: `\r?\n` not `\n`; multiline `(?m)^` — CRLF breaks `^key:` scans (P1-1: ~10 FPs, doc:31-46).
8. Regex alternation: `[|]` not `\|` — gates raw-scan `||` as FP (#20).
9. Mojibake may be console codepage, NOT file corruption — verify bytes (hex/UTF8) before "fixing".

## Verification
1. PSSA clean or documented baseline before commit.
2. AST parse passes (`[Parser]::ParseFile` or `pwsh -c "Parse"`).
3. Encoding edits: re-read `-Encoding UTF8`, no U+FFFD.
4. Regex: test LF + CRLF samples.
## Anti-Rationalization
| Rationalization | Red Flag | Check |
|---|---|---|
| "PS7-only, 5.1 rules legacy" | Skip chain/encoding rules | Hooks/CI may run PS5.1 (GAP-2 2026-09-01) |
| "`\\n` works locally" | LF-only scans | Windows = CRLF (P1-1 audit:46) |
| "Small script, skip #requires" | Missing version decl | Gate + cross-ref flag it |
## Red Flags
- No `#requires` header; `Get-Content` w/o `-Encoding` on non-ASCII; `\n`-only scans on Windows files; `&&` for PS5.1; empty `catch` on encoding ops.
## Refs: quality-gate | command-wrapper | bash-safe (scripts/bash-safe.ps1) | ANTI-PATTERN-CATALOG.md:21,24,25,27,31 | docs/mejoras/2026-09-01-gap-scan-repo.md:17-21 | docs/mejoras/2026-09-01-p1-1-spec-audit.md:31-46