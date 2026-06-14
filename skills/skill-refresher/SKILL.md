---
name: skill-refresher
description: >  skill-refresher skill
triggers: "Skill refresher, drift detection, auto-heal"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

Trigger: Repeated bug, skill unused 5+ sessions, user repeats correction, Karpathy loss >5%.
## HEALTH SIGNALS| Signal | Action ||--------|--------|| Same bug 2+ times | Skill missed pattern â†’ update || Not loaded 5+ sessions | Unused â†’ flag or merge || User corrects same thing 2+ | Skill vague â†’ clarify || Karpathy loss >5% | Revert, rewrite denser |
## REGENERATION1. **Audit**: skill content vs Engram usage (last 10 sessions)2. **Drift**: triggers still match? Too broad/narrow?3. **Update**: fix gaps, tighten triggers, add patterns4. **Compress**: re-Karpathy if >5% new content5. **Bump**: major=structural, minor=content fix6. **Log**: changelog + commit
## HEALINGLoaded but didn't help â†’ Engram log (skill, session, why not, suggested fix) â†’ next health check.
## SELF-TESTVerify loads (`skill name: skill-refresher`), YAML valid, triggers fire.
