---
name: skill-refresher
description: "Detect skill drift and auto-heal — monitor health signals, regenerate stale skills, and track usage patterns"
triggers: "Skill refresher, drift detection, auto-heal"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.1"
---

Trigger: Repeated bug, skill unused 5+ sessions, user repeats correction, Karpathy loss >5%.
## HEALTH SIGNALS| Signal | Action ||--------|--------|| Same bug 2+ times | Skill missed pattern → update || Not loaded 5+ sessions | Unused → flag or merge || User corrects same thing 2+ | Skill vague → clarify || Karpathy loss >5% | Revert, rewrite denser |
## REGENERATION1. **Audit**: skill content vs Engram usage (last 10 sessions)2. **Drift**: triggers still match? Too broad/narrow?3. **Update**: fix gaps, tighten triggers, add patterns4. **Compress**: re-Karpathy if >5% new content5. **Bump**: major=structural, minor=content fix6. **Log**: changelog + commit
## HEALINGLoaded but didn't help → Engram log (skill, session, why not, suggested fix) → next health check.
## SELF-TESTVerify loads (`skill name: skill-refresher`), YAML valid, triggers fire.
## EXAMPLE
```markdown
## Health Check: context-watchdog
- Last loaded: 3 sessions ago
- Effective: Yes | Action: None — healthy
```
## REGENERATION FLOW
1. Audit current SKILL.md + Engram usage (last 10 sessions)
2. Check drift: triggers still match? Too broad/narrow?
3. Update: fix gaps, tighten triggers, add patterns
4. Compress: re-Karpathy if >5% new content
5. Bump version: major=structural, minor=content
6. Log changelog + commit
