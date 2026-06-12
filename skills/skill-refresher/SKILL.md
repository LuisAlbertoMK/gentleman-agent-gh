---
name: skill-refresher
description: >
  skill-refresher skill
triggers: "Skill refresher, drift detection, auto-heal"
  Trigger: Repeated bug, skill unused 5+ sessions, user repeats correction, Karpathy loss >5%.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

## HEALTH SIGNALS
| Signal | Action |
|--------|--------|
| Same bug 2+ times | Skill missed pattern → update |
| Not loaded 5+ sessions | Unused → flag or merge |
| User corrects same thing 2+ | Skill vague → clarify |
| Karpathy loss >5% | Revert, rewrite denser |

## REGENERATION
1. **Audit**: skill content vs Engram usage (last 10 sessions)
2. **Drift**: triggers still match? Too broad/narrow?
3. **Update**: fix gaps, tighten triggers, add patterns
4. **Compress**: re-Karpathy if >5% new content
5. **Bump**: major=structural, minor=content fix
6. **Log**: changelog + commit

## HEALING
Loaded but didn't help → Engram log (skill, session, why not, suggested fix) → next health check.

## SELF-TEST
Verify loads (`skill name: skill-refresher`), YAML valid, triggers fire.

