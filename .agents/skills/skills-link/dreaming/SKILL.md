---
name: dreaming
description: "Cross-session pattern extraction via Engram. Run via !dream — not automatic."
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "1.4"
  changelog: "1.4: added auto-pattern-detector + learning-stats. 1.3: opt-in !dream only."
  triggers: "!dream, dreaming, patrones, 'memory review', session end via !close"
---
## TRIGGER
Only on explicit request (`!dream`) or user asking. Recommended weekly or after milestone.
**Auto-pattern trigger**: same error 3x → run `auto-pattern-detector.ps1` → propose anti-pattern to immune-system.

## SCRIPTS
| Script | Purpose | When |
|--------|---------|------|
| `scripts/auto-pattern-detector.ps1` | Scan learnings + errors, propose anti-patterns | `!dream`, error 3x |
| `scripts/learning-stats.ps1` | Pattern counts, trends, health metrics | `!dream`, `!score` |
| `scripts/session-miner.ps1` | Mine session histories for error patterns | `!dream full` |
| `scripts/run-dreaming.ps1` | Full dreaming cycle orchestrator | `!dream` |

## MODES
| Mode | When | Action |
|------|------|--------|
| **Quick scan** | `!dream quick` | `mem_context` + `mem_search(keywords=recent work)` + `auto-pattern-detector.ps1` |
| **Harvest** | `!close` | `mem_session_summary` + extract patterns (error→catalog, workflow→skill) |
| **Full dream** | `!dream` (weekly) | `mem_search(type="error\|bugfix\|pattern\|decision")` + `auto-pattern-detector.ps1` + `learning-stats.ps1`. ≥2→anti-pattern. ≥3→AGENTS.md rule. |
| **Wisdom review** | `!dream full` (monthly) | `wisdom-demote.ps1 -All` → demote stale patterns (90d), remove unused forged skills (14d), archive deprecated (180d). Always run `-DryRun` first, show report, ask for confirmation. |

## WISDOM STORE MAINTENANCE
Wisdom review runs `wisdom-demote.ps1 -All -DryRun` by default (safe).
The flow:
1. Run dry-run: report stale/deprecated/archivable patterns
2. Show user: "X patterns would be demoted, Y unused skills removed. Proceed?"
3. Only on approval: `wisdom-demote.ps1 -All`
4. Save report to engram with `mem_save(topic_key="wisdom/prune-{date}")`

Auto-forge: for patterns that meet promotion threshold, the pipeline
(`wisdom-forge.ps1`) checks severity-based maturity before creating a skill.
Run via `!forge <pattern-id>` — always shows quality gates before writing.

Scripts:
- `scripts/wisdom-store.ps1` — save/migrate patterns
- `scripts/wisdom-loader.ps1` — retrieve by domain/tech/keywords
- `scripts/wisdom-forge.ps1` — promote pattern → skill (9 quality gates)
- `scripts/wisdom-demote.ps1` — periodic maintenance (demote/remove/archive)
- `scripts/forge-rollback.ps1` — revert forge (remove skill, demote pattern)
- `scripts/pattern-guard.ps1` — LAZY detection in pre-flight
- `scripts/wisdom-stats.ps1` — metrics

## RECALL
Extract 3-5 keywords, `mem_search(query="<keywords>", limit=3)` → apply past learnings.

## FINGERPRINT
First interaction per project: detect lang/framework/arch, save to engram.
Subsequent: `mem_search(query="project/{name}", scope=project)` to reload.

## ANTI-PATTERNS
❌ Isolated sessions · fix-only-no-document · every session fresh · no memory scan before work
✅ Cross-session patterns · permanent immunity · curate signal/drop noise · scan memory first

## IMMUNE INTEGRATION
When `auto-pattern-detector.ps1` returns `Status: PATTERNS_FOUND`:
1. For each proposal → invoke immune-system (detect→diagnose→document→immunize)
2. Same error 3+ times → mandatory catalog entry + AGENTS.md rule
3. Cross-ref with `learning-stats.ps1` to validate trend before promotion
4. Flow: `auto-pattern-detector.ps1` → immune-system detect → ANTI-PATTERN-CATALOG.md → AGENTS.md rule
