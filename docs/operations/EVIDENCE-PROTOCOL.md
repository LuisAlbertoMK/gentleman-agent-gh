# Evidence Protocol — Anti-Fabrication + GH Vigilance

> Status: **PENDING-RATIFICATION**. Adopted behaviorally; constitutional ratification into protected files requires improvement/judgment cycle. See §5.
> Scope: all agent delegations producing HIGH/MEDIUM findings. Language: artifacts in English by default.

## Why this exists

Two HIGH claims with precise file:line were fabricated and stopped by orchestrator spot-check before action:

1. `score-dims` `@()` + `.Add()` L175-183 — refuted: L179 is `New-Object ...List[string]`.
2. `platform.ps1` Join-PathSafe L56-70 — refuted: grep 0 hits, symbol does not exist.

Gates that bite well (keep): breaker (6 real/by-design), JD dual + external auditor, secrets-scan.
Known false positives (do not escalate): ampersand immediately followed by a dollar-variable (call operator with variable command) and the confirmation-suppression wording (PS-BND-01 trigger word) in markers, classic PAT prefix (letters g-h-p plus underscore) / long-form PAT prefix (github + _pat_) documentary (safe placeholder: `REDACTED_PAT_PREFIX`).

Note: this doc avoids the literals themselves because the pre-commit secrets/adversarial scans match substrings (self-referential gate).

## 1. Evidence Quoting (adopted NOW, behavioral)

Every HIGH finding MUST carry a verbatim quote (≤5 lines) in a fence with file:line + reproduce command. No quote → auto-degrade to MEDIUM.

Required shape per HIGH:

```md
**[HIGH] Title** — `path/to/file.ext:LINE-LINE`

```ext
<verbatim lines, max 5>
```

Reproduce: `<exact grep/read command>`
```

Copy-paste reproduce commands:

```powershell
# Re-read exact range (PowerShell 5.1-safe, no &&/||)
Get-Content -LiteralPath "path/to/file.ext" | Select-Object -Skip 174 -First 10
# Literal pattern search
rg -n --no-heading -F "PATTERN" "path/to/file.ext"
# Regex search
rg -n --no-heading "PATTERN" "path/to/file.ext"
```

Rule: without the fence + file:line + reproduce command, the orchestrator treats the claim as MEDIUM, no action authorized.

## 2. Spot-Check (adopted NOW, behavioral)

- Orchestrator re-reads 100% of HIGH file:line citations before authorizing fixes.
- Minimum 1 re-read per MEDIUM batch.
- Refuted claim → recorded in Nuance, no action taken.
- Fabricated HIGH (quote does not match file) → finding discarded, incident logged here inPR/retro notes.

```powershell
# Spot-check a HIGH citation
Get-Content -LiteralPath "path/to/file.ext" | Select-Object -Skip 178 -First 5
rg -n --no-heading -F "claimed-symbol" "path/to/file.ext"
```

## 3. Pre-Push Baseline (record, do not block by default)

Red CI pre-push is recorded, not blocking by default. Capture remote CI baseline + divergence before every push:

```powershell
gh run list --limit 10
git rev-list --count HEAD...origin/main
git status --short
```

Log format (paste into PR body or bitacora):

```text
Baseline <YYYY-MM-DD>: CI=<red/green + failing job names>, divergence=<N fwd>/<M back>, main sync=<x/y>
```

## 4. GH Vigilance Checklist

Run before push and after merge. Exact commands:

```powershell
gh pr list --state open --limit 20
gh issue list --state open --limit 20
gh run list --limit 10
git fetch origin; git rev-list --count HEAD...origin/main
git branch -r --sort=-committerdate | Select-Object -First 10
```

| Signal | Normal | Alert |
|---|---|---|
| Open PRs | 0 or known tracked PRs | Unknown PR, foreign branch to main |
| Open issues | 0 or triaged | New untriaged issue, secret-leak report |
| `gh run list` | Green on last push, or known pre-existing red (see baseline) | New failing job not in baseline |
| `rev-list --count` | `0` (in sync) | Non-zero divergence unexplained |
| Stale remote branches | Release/bot branches with recent date | Unknown branch, old feature branch resurrected |

Baseline 2026-09-15: 0 PRs, 0 issues, CI red pre-existing (Pester 1524 passed; failures: wisdom-store EXISTS/parses + `-Force` params — not from this push), main sync 0/0.

## 5. PENDING-RATIFICATION (protected files — DO NOT circumvent)

Edits to `prompts/shared/_return-contract.md` and `AGENTS.md` are DENY by `opencode.json` (constitutional protection binding the orchestrator too — do NOT circumvent). The exact blocks below enter protected files only via improvement/judgment cycle.

### Proposed block for `prompts/shared/_return-contract.md` (new section `## Evidence Quoting`)

```md
## Evidence Quoting
Every HIGH finding MUST include a verbatim quote (<=5 lines) in a fence with file:line plus a reproduce command. Missing quote auto-degrades the finding to MEDIUM.
```

### Proposed block for `AGENTS.md` (Delegation Rules +1 line)

```md
- HIGH findings require verbatim quote + file:line + reproduce command; orchestrator spot-checks 100% of HIGH citations before authorizing fixes.
```

Ratification path: improvement cycle → judgment → merge into protected files. Until then this document is the binding behavioral reference and lives in allowed territory (`docs/operations/`).
