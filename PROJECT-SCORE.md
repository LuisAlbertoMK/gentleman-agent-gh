# Project Score: gentleman-agent-gh

**Current**: 9.4/10
**Last updated**: 2026-06-17
**Trend**: stable (auto-scored)

> **Scoring Protocol**: `SCORING-PROTOCOL.md` — 10 dimensions with evidence commands.
> **Auto-Scorer**: `scripts\score-auto.ps1` — reproducible from 0, no memory required.
> ```bash
> git clone <repo> && cd gentleman-agent-gh
> powershell ./scripts/score-auto.ps1
> ```

## Dimensions

| Dimensión | Score | Evidence |
|-----------|:-----:|----------|
| Project Artifacts | 10/10 | 63 skills (excl _shared), cross-ref OK, README, CHANGELOG, .project.json |
| Security | 7/10 | weak_crypto detected (MD5/SHA1 refs not fully excluded), no secrets |
| Dead Code | 9/10 | 0 orphans, 0 dead junctions, 1 commented-out pattern |
| Clean Code | 8.8/10 | 17/25 scripts with help, 24/25 with params, 25/25 with StrictMode |
| Best Practices | 9.6/10 | 24/25 scripts with params, 14/25 with try/catch |
| Orthography | 10/10 | 0 encoding corruption files (byte-level scan) |
| Bitácora | 10/10 | 30 lines, consistently maintained |
| Metrics | 10/10 | docs/metricas/, LATEST_error.json, reports present |
| Script Performance | 10/10 | 25 scripts, avg 7.5KB, none >50KB |
| Skill Effectiveness | 10/10 | 63 skills, 1 >3KB (chained-pr), avg 2KB |

## How Score is Computed

1. Any agent with zero session history runs: `powershell ./scripts/score-auto.ps1`
2. The script scans the repo for objective evidence (file counts, sizes, regex patterns)
3. Each dimension scored 0-10 using defined criteria
4. Final = average of all 10 dimensions, rounded to 1 decimal

## Changes from Previous

- **New**: Autonomous scoring system (SCORING-PROTOCOL.md + score-auto.ps1)
- **Security 9→7**: Auto-detected weak crypto references (more thorough than previous manual check)
- **Clean Code 9→8.8**: 8 scripts missing help headers (previously unmeasured)
- **Metrics 9→10**: Full metrics directory structure detected
- **Script Performance 9→10**: All 25 scripts lean, none oversized

## To Update

```powershell
powershell ./scripts/score-auto.ps1 -Json | Set-Content .project.json -Encoding UTF8
```
