# C28 (Security dimension 8.0→10.0) — Implementation Completed

- **Protocol**: v3, security subset C28 (weak_crypto trace & fix)
- **Agent**: gentleman-implementer-sub
- **Date**: 2026-08-15
- **Task**: Trace why `score-auto.ps1` reports `weak_crypto: true`, find the ACTUAL weak crypto usage, fix it (MD5/SHA1/DES/RC4 → SHA-256+ or remove). Do NOT modify scorer detection logic unless it has a bug.

## What was found

The scorer (`scripts/lib/score-dims.ps1:80-98`) scans `$scriptFiles` = `scripts\*.ps1` (top-level only, per `score-auto.ps1:53`), line by line, flagging lines that match `MD5|SHA1\b` (case-insensitive) UNLESS the line also contains a mitigation marker (`SHA1ToSHA256|SHA256|#deprecat|#legacy|SHA1SHA256|Select-String.*MD5`). Each hit costs the Sec dimension 2 points.

Exactly **one** real weak crypto usage was flagged:

| Path | Line | Weak usage |
|---|---|---|
| `scripts/delegation-registry.ps1` | 104 | `[System.Security.Cryptography.MD5]::Create().ComputeHash(...)` — MD5 hash of `$RepoRoot` used to build the named-mutex name `Global\GentlemanDelegationRegistry-$repoId` (line 105) |

`$repoId` is used **only** for the mutex name (grep: 2 occurrences, lines 104-105) — it is never persisted, so swapping the algorithm requires no migration and no cache invalidation.

## Fix applied (1 line)

`scripts/delegation-registry.ps1:104` — MD5 → SHA256 (drop-in: same `Create()`/`ComputeHash(byte[])` API on `System.Security.Cryptography.SHA256`):

```powershell
# before
$repoId = ([System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($RepoRoot)) | ForEach-Object { $_.ToString("x2") }) -join ''
# after
$repoId = ([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($RepoRoot)) | ForEach-Object { $_.ToString("x2") }) -join ''
```

Output is 64-hex chars instead of 32 — named-mutex length limit (260 chars) is not approached. The mutex name change is harmless for a concurrency lock (ephemeral per-process object, no cross-version compatibility needed).

## DoD verification (binary)

| DoD item | Result |
|---|---|
| `weak_crypto: true` eliminated by actual code fix (not scorer tampering) | PASS — real MD5 replaced with SHA256 |
| Scorer detection logic untouched | PASS — `score-dims.ps1` not modified |
| Syntax valid | PASS — `[Parser]::ParseFile` on `delegation-registry.ps1` → 0 errors |
| Scorer exact-logic replication over `scripts\*.ps1` → 0 weak-crypto matches | PASS — 0 hits |
| Refined repo-wide scan (all `.ps1`/`.js`, excl. `.learnings`/`.git`/`node_modules`; word-boundary `md5|sha1|des|rc4` + `Get-FileHash.*MD5|SHA1` + `createHash('md5'|'sha1')`) | PASS — 0 weak uses; only hit = scorer's own detection pattern string at `score-dims.ps1:88` (self-excludes via `SHA256` literal in its exclusion regex; forbidden to modify) |
| Live scorer run (`scripts/score-auto.ps1 -Quiet`) | PASS — `"Sec": {"r": "Weak crypto: False, secrets: False", "s": 10.0, "e": {"weak_crypto": false, "secrets": false}}` → Security dimension **10.0** |
| `.project.json` before/after | Before: `Security: 8.0`, `weak_crypto: true`, `"Weak crypto: True"` → After: `weak_crypto: false`, `"Weak crypto: False"` |

## Return Contract

## Decision Taken
Replaced the only real weak-crypto usage (MD5 repo-ID hash in delegation-registry.ps1:104) with SHA256; Sec dimension verified 10.0, weak_crypto false.

## Files Changed
- `scripts/delegation-registry.ps1` — MD5 → SHA256 for `$repoId` (named-mutex identifier), 1 line
- `.project.json` — regenerated metrics by the scorer run itself (Sec 10.0, weak_crypto false); no hand edits

## Key Findings
1. [HIGH] Real MD5 found at `scripts/delegation-registry.ps1:104` — repo-root hash for the `Global\GentlemanDelegationRegistry-$repoId` named mutex — replaced with `System.Security.Cryptography.SHA256` (identical API, 64-hex output). — Evidence: grep `MD5|SHA1` in scripts → 2 hits; scorer scan of `scripts\*.ps1` → 0 hits after fix; live scorer run → `weak_crypto: false`, Sec 10.0.
2. [LOW] Not a scorer bug / not a false positive — the detection was correct and precise: `score-dims.ps1:88` (`MD5|SHA1\b` minus SHA256/legacy markers) flagged exactly the one real usage and self-excludes its own pattern string correctly.
3. [INFO] The task's literal verification grep `(md5|sha1|DES|RC4|...)` matches `.DESCRIPTION` comment tags in nearly every documented script ("DES" substring) — the naive grep alone would never reach 0 on this repo; verification must use word boundaries / algorithm context. `.DESCRIPTION` tags are not crypto.
4. [INFO] No DES/RC4/Get-FileHash-MD5|SHA1 weak uses anywhere in repo scripts; all `Get-FileHash` calls use SHA256 or the default (SHA256).

## Nuance
- The named mutex key changes from an MD5-derived to a SHA256-derived string — safe for an ephemeral concurrency lock; a fresh name also avoids any stale-lock ambiguity.
- `.project.json` shows 110/110 line churn: score deltas (Sec 8.0→10.0, weak_crypto true→false) plus re-serialization by the scorer's own write path — not hand-edited, consistent with prior cycles' behavior.
- Scope respected: `score-dims.ps1` detection logic untouched, `.learnings/*` untouched (cache regenerated by the scorer run itself as designed).
