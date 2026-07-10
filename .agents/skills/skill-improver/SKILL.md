---
name: skill-improver
description: "Audit and improve skills — preserve author intent, fix frontmatter, convert tutorial prose to actionable rules, track usage"
triggers: "Skill improvement, audit skills, refactor skills, skill refresher, drift detection, auto-heal"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "2.2"
  changelog: "2.1->2.2: Added code examples, anti-patterns table, cross-refs section, clarified audit output contract"
---
<!-- karpathy-compressed: 2026-07-09 -->

# Skill Improver

Detect, diagnose, and repair skill degradation — drift, stale content, tutorial prose.

## Rules

1. **Preserve**: author intent, critical rules, activation semantics, output contract
2. **Default**: audit-only — modify only when asked
3. **Never delete**: content → move to `references/` instead
4. **Don't invent**: triggers/policies — mark ambiguous for human
5. **Boundaries**: don't touch `opencode.json` or AGENTS.md — skills only

## Decision Gates

| Input Signal | Action |
|-------------|--------|
| Missing/invalid frontmatter | Fix metadata |
| Tutorial prose | Convert to runtime rules, background → `references/` |
| Over token budget | Preserve rules, move examples to `references/` |
| Branching prose | Replace with decision table |
| Conflicting rules | Report both, don't rewrite — escalate |

## Audit Steps

```
1. Read all SKILL.md files in target
2. Audit each: metadata · trigger clarity · section order · body budget · actionability · decision gates · output contract
3. Check usage: mem_search(last 50 loads)
4. Flag 90d+ untouched as deprecated
5. Return grouped-by-skill report with severity
6. Edit safe issues, create supporting files
```

## Drift Detection

Trigger: same bug 2x · unused 5+ sessions · user correction 2x · Karpathy loss >5%

| Signal | Action |
|--------|--------|
| Same bug 2+ times | Skill missed pattern → update |
| Not loaded 5+ sessions | Flag or merge into broader skill |
| User corrects same thing 2+ | Skill too vague → clarify rules |
| Karpathy loss >5% | Revert change, rewrite denser |

**Healing**: Engram log `(skill, session, why not, suggested fix)`. Self-test returns `{healthy: bool, issues: []}`.

## Regeneration Flow

```
1. Audit SKILL.md + Engram usage (last 10 sessions)
2. Check drift: do triggers still match usage?
3. Update: fix gaps, tighten triggers, add patterns
4. Compress if >5% new content (karpathy-loop)
5. Bump version (major=structural, minor=content)
6. Log changelog + commit
```

## Example

```bash
# Audit a skill — last 50 loads
mem_search('skill.*' (scope: tag))
# Returns: [{name: "commit-crafter", loads: 12, last: "2026-06-01"}]
# → 90d untouched? Flag deprecated.

# Self-test output
{healthy: false, issues: [
  "missing output contract",
  "triggers don't match recent usage",
  "anti-patterns section missing"
]}
```

## Anti-Patterns

| Anti-Pattern | Why | Do Instead |
|---|---|---|
| Rewriting entire skill at once | Loses author intent | Audit → fix specific gaps → repeat |
| Adding unintended triggers | Skill fires incorrectly | Mark ambiguous — let human decide |
| Deleting content instead of archiving | Data loss, no audit trail | Move to `references/` |
| Bumping major for trivial changes | Version inflation | major=structural, minor=content |
| Ignoring Engram usage | Flying blind | Always check `mem_search` before changes |
| Merging active+deprecated skills silently | User confusion | Flag deprecated, don't silently merge |
| Over-compressing losing actionable content | Skill becomes useless | Preserve rules, compress examples |

## Output Contract

```json
{
  "audited": ["skill-a", "skill-b"],
  "issues": [
    {"skill": "skill-a", "severity": "high", "description": "missing output contract"}
  ],
  "drifted": ["skill-b"],
  "deprecated": ["skill-c"],
  "edits_made": ["skill-a: added output contract"]
}
```

## Refs

- [karpathy-loop](../karpathy-loop/SKILL.md) — compression when skills exceed budget
- [skill-creator](../skill-creator/SKILL.md) — creating new skills from scratch
- [skill-testing](../skill-testing/SKILL.md) — verify skill quality before production
- [immune-system](../immune-system/SKILL.md) — permanent fixes for repeated issues
- [drift](../dreaming/SKILL.md) — cross-session pattern extraction
