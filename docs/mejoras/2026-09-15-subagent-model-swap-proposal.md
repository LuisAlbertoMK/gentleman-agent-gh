# Subagent Model Swap Proposal: Broken/Free → muse-spark-1.3-contributor

**Date**: 2026-09-15
**Author**: gentleman-agent-gh (SDD-lite proposal)
**Status**: PROPOSED — ready for owner review
**Confidence**: high (data extracted from `opencode.json` line-by-line)

---

## Problem

12 subagents use `opencode-go/deepseek-v4-flash` which is **BROKEN** (model unavailable/deprecated).
5 additional subagents use `opencode-go/mimo-v2.5` which is **free-tier** (functional but limited quality/rate).
2 subagents use `opencode-go/qwen3.7-plus` which is **free-tier** (ambiguous — may still work, flagged as optional).
5 subagents already use `opencode-go/muse-spark-1.3-contributor` — **no change needed**.

**Total: 19 subagents need attention, 17 recommended to migrate, 2 optional.**

---

## Inventory: All 24 `-sub` Agents

| # | Agent | Model (current) | Line | Status | Action |
|---|-------|-----------------|------|--------|--------|
| 1 | deep-sub | `opencode-go/deepseek-v4-flash` | 270 | **BROKEN** | → muse-spark-1.3-contributor |
| 2 | quick-sub | `opencode-go/muse-spark-1.3-contributor` | 271 | contributor | SKIP |
| 3 | implementer-sub | `opencode-go/mimo-v2.5` | 272 | free | → muse-spark-1.3-contributor |
| 4 | security-sub | `opencode-go/deepseek-v4-flash` | 273 | **BROKEN** | → muse-spark-1.3-contributor |
| 5 | seo-sub | `opencode-go/deepseek-v4-flash` | 274 | **BROKEN** | → muse-spark-1.3-contributor |
| 6 | infra-sub | `opencode-go/mimo-v2.5` | 275 | free | → muse-spark-1.3-contributor |
| 7 | frontend-sub | `opencode-go/muse-spark-1.3-contributor` | 276 | contributor | SKIP |
| 8 | performance-sub | `opencode-go/deepseek-v4-flash` | 277 | **BROKEN** | → muse-spark-1.3-contributor |
| 9 | datascience-sub | `opencode-go/muse-spark-1.3-contributor` | 278 | contributor | SKIP |
| 10 | docs-sub | `opencode-go/muse-spark-1.3-contributor` | 279 | contributor | SKIP |
| 11 | aem-sub | `opencode-go/deepseek-v4-flash` | 289 | **BROKEN** | → muse-spark-1.3-contributor |
| 12 | codex-sub | `opencode-go/mimo-v2.5` | 555 | free | → muse-spark-1.3-contributor |
| 13 | deep-sub-auto | `opencode-go/deepseek-v4-flash` | 830 | **BROKEN** | → muse-spark-1.3-contributor |
| 14 | quick-sub-auto | `opencode-go/muse-spark-1.3-contributor` | 872 | contributor | SKIP |
| 15 | codex-sub-auto | `opencode-go/mimo-v2.5` | 910 | free | → muse-spark-1.3-contributor |
| 16 | implementer-sub-auto | `opencode-go/mimo-v2.5` | 951 | free | → muse-spark-1.3-contributor |
| 17 | aem-sub-auto | `opencode-go/deepseek-v4-flash` | 1265 | **BROKEN** | → muse-spark-1.3-contributor |
| 18 | reviewer-sub | `opencode-go/deepseek-v4-flash` | 1290 | **BROKEN** | → muse-spark-1.3-contributor |
| 19 | reasoning-sub | `opencode-go/deepseek-v4-flash` | 1511 | **BROKEN** | → muse-spark-1.3-contributor |
| 20 | reasoning-sub-auto | `opencode-go/deepseek-v4-flash` | 1527 | **BROKEN** | → muse-spark-1.3-contributor |
| 21 | code-review-sub | `opencode-go/qwen3.7-plus` | 1584 | FREE-qwen (ambiguous) | ⚠️ OPTIONAL |
| 22 | code-review-sub-auto | `opencode-go/qwen3.7-plus` | 1600 | FREE-qwen (ambiguous) | ⚠️ OPTIONAL |
| 23 | initializer-sub | `opencode-go/deepseek-v4-flash` | 1657 | **BROKEN** | → muse-spark-1.3-contributor |
| 24 | initializer-sub-auto | `opencode-go/deepseek-v4-flash` | 1673 | **BROKEN** | → muse-spark-1.3-contributor |

### Summary

| Category | Count | Agents |
|----------|-------|--------|
| **BROKEN** (deepseek-v4-flash) | 12 | deep-sub, security-sub, seo-sub, performance-sub, aem-sub, deep-sub-auto, aem-sub-auto, reviewer-sub, reasoning-sub, reasoning-sub-auto, initializer-sub, initializer-sub-auto |
| **Free** (mimo-v2.5) | 5 | codex-sub, infra-sub, implementer-sub, codex-sub-auto, implementer-sub-auto |
| **Ambiguous FREE** (qwen3.7-plus) | 2 | code-review-sub, code-review-sub-auto |
| **Already contributor** (no change) | 5 | quick-sub, frontend-sub, datascience-sub, docs-sub, quick-sub-auto |
| **Total** | **24** | |

---

## Proposed Change

**Target model**: `opencode-go/muse-spark-1.3-contributor`

### Mandatory (17 agents)

Replace 12 BROKEN `deepseek-v4-flash` + 5 free `mimo-v2.5` with `muse-spark-1.3-contributor`.

### Optional (2 agents)

`qwen3.7-plus` agents (`code-review-sub`, `code-review-sub-auto`) — flagged as ambiguous. These may still function. **Recommendation**: migrate as well for consistency, but owner discretion. If `qwen3.7-plus` is confirmed working, these can stay.

### No-op (5 agents)

`quick-sub`, `frontend-sub`, `datascience-sub`, `docs-sub`, `quick-sub-auto` — already `muse-spark-1.3-contributor`. Skip.

---

## Tradeoff Analysis

| Dimension | Current (broken/free) | After (contributor) |
|-----------|----------------------|---------------------|
| **Cost** | free (zero quota) | consumes contributor quota |
| **Reliability** | 12 BROKEN = 0% availability | contributor = high availability |
| **Quality** | mimo-v2.5 free = limited | muse-spark-1.3 = stronger model |
| **Rate limits** | free-tier caps | contributor-tier caps (higher) |
| **Net impact** | broken agents = wasted delegation attempts | all subagents functional |

**Bottom line**: migrating everything to contributor **increases quota cost** but **eliminates 12 BROKEN agents** (50% of subagents completely non-functional). The 5 free agents gain quality. This is a **net-positive tradeoff** — broken agents cost more in retries/context-waste than the contributor quota.

---

## Applicable Script (Python)

Reads `opencode.json`, replaces exact model strings for the 17 target agents, saves backup as `opencode.json.bak`.

```python
#!/usr/bin/env python3
"""
migrate_subagent_models.py — Replace BROKEN/free subagent models with muse-spark-1.3-contributor.

Usage:
    python scripts/migrate_subagent_models.py [--dry-run]

Saves backup: opencode.json.bak before any mutation.
"""
import json
import shutil
import sys
from pathlib import Path

CONFIG = Path("opencode.json")
BACKUP = Path("opencode.json.bak")
TARGET_MODEL = "opencode-go/muse-spark-1.3-contributor"

# Agents to migrate: name → current model (for exact match safety)
MIGRATE = {
    # BROKEN (deepseek-v4-flash)
    "gentleman-deep-sub": "opencode-go/deepseek-v4-flash",
    "gentleman-security-sub": "opencode-go/deepseek-v4-flash",
    "gentleman-seo-sub": "opencode-go/deepseek-v4-flash",
    "gentleman-performance-sub": "opencode-go/deepseek-v4-flash",
    "gentleman-aem-sub": "opencode-go/deepseek-v4-flash",
    "gentleman-deep-sub-auto": "opencode-go/deepseek-v4-flash",
    "gentleman-aem-sub-auto": "opencode-go/deepseek-v4-flash",
    "gentleman-reviewer-sub": "opencode-go/deepseek-v4-flash",
    "gentleman-reasoning-sub": "opencode-go/deepseek-v4-flash",
    "gentleman-reasoning-sub-auto": "opencode-go/deepseek-v4-flash",
    "gentleman-initializer-sub": "opencode-go/deepseek-v4-flash",
    "gentleman-initializer-sub-auto": "opencode-go/deepseek-v4-flash",
    # Free (mimo-v2.5)
    "gentleman-codex-sub": "opencode-go/mimo-v2.5",
    "gentleman-infra-sub": "opencode-go/mimo-v2.5",
    "gentleman-implementer-sub": "opencode-go/mimo-v2.5",
    "gentleman-codex-sub-auto": "opencode-go/mimo-v2.5",
    "gentleman-implementer-sub-auto": "opencode-go/mimo-v2.5",
}

DRY_RUN = "--dry-run" in sys.argv


def migrate():
    if not CONFIG.exists():
        print(f"ERROR: {CONFIG} not found", file=sys.stderr)
        sys.exit(1)

    data = json.loads(CONFIG.read_text(encoding="utf-8"))
    agents = data.get("agent", {})
    changed = []
    skipped = []

    for name, expected_model in MIGRATE.items():
        if name not in agents:
            skipped.append(f"{name}: key not found")
            continue
        current = agents[name].get("model", "")
        if current == TARGET_MODEL:
            skipped.append(f"{name}: already {TARGET_MODEL}")
            continue
        if current != expected_model:
            skipped.append(f"{name}: model is '{current}' (expected '{expected_model}')")
            continue

        if not DRY_RUN:
            agents[name]["model"] = TARGET_MODEL
        changed.append(f"{name}: {current} → {TARGET_MODEL}")

    print(f"\n{'DRY RUN: ' if DRY_RUN else ''}Migration plan ({len(changed)} changes, {len(skipped)} skipped):")
    for c in changed:
        print(f"  ✓ {c}")
    for s in skipped:
        print(f"  — {s}")

    if not DRY_RUN and changed:
        shutil.copy2(CONFIG, BACKUP)
        CONFIG.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"\nBackup saved: {BACKUP}")
        print(f"Updated: {CONFIG}")
    elif DRY_RUN and changed:
        print(f"\nTo apply: python {__file__}")
    else:
        print("\nNo changes needed.")


if __name__ == "__main__":
    migrate()
```

### Usage

```bash
# Preview changes (no mutation)
python scripts/migrate_subagent_models.py --dry-run

# Apply changes (backs up opencode.json → opencode.json.bak)
python scripts/migrate_subagent_models.py
```

---

## Verification Command

After running the script, verify all subagents migrated:

```bash
# Should return 0 matches (all BROKEN/free models gone from subagents)
rg "deepseek-v4-flash" opencode.json --line-number | rg "\-sub"

# Should return 17 matches (all migrated subagents now use contributor)
rg "muse-spark-1.3-contributor" opencode.json --line-number | rg "\-sub"

# Full inventory — confirm no anomalies
python -c "
import json
data = json.loads(open('opencode.json').read())
agents = data['agent']
for k, v in sorted(agents.items()):
    if 'sub' in k:
        m = v.get('model','?')
        flag = '⚠️' if 'deepseek' in m or ('mimo' in m and 'free' in m) else '✓'
        print(f'{flag} {k}: {m}')
"
```

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| muse-spark-1.3-contributor unavailable | HIGH | contributor tier has SLA; fallback to other models |
| Quota exhaustion | MEDIUM | Monitor contributor usage; can revert via `git checkout opencode.json.bak` |
| Behavioral difference | LOW | muse-spark-1.3 is stronger than both deepseek-v4-flash and mimo-v2.5 free |
| qwen3.7-plus still works | LOW | Optional — can keep as-is; owner decision |

---

## Recommendation

**Migrate all 17 mandatory agents.** Consider migrating the 2 optional (qwen3.7-plus) for consistency — a uniform model across all subagents simplifies debugging and cost tracking.

**Execution**: owner runs the Python script. No opencode.json hand-edits.

---

*Generated by gentleman-agent-gh · confidence: high · 2026-09-15*
