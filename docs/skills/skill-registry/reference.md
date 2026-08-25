# Skill Registry — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/skill-registry/SKILL.md) for the core workflow and rules.

---

## Examples (5)

### Example 1: Basic Registry Build (Fresh Project)
```bash
# Trigger: "update skills" on new project
# Scans 3 directories, finds 12 skills, deduplicates 3 conflicts
# Output: .atl/skill-registry.md with 9 skills
```
**Input dirs:**
- `~/.config/opencode/skills/` → 8 skills (code-review-agent, commit-crafter, quick-executor, etc.)
- `~/.claude/skills/` → 3 skills (custom-audit, legacy-helper)
- `.agent/skills/` → 4 skills (project-specific: auth-hardening, infra-audit, perf-profiling, sdd-init)

**Deduplication:**
- `code-review-agent` appears in both global + project → project version wins
- `quick-executor` only in global → kept
- `auth-hardening` only in project → kept

**Registry output:**
```
## Skills
| Trigger | Skill | Path |
| code review, 4R | code-review-agent | .agent/skills/code-review-agent/SKILL.md |
| commit | commit-crafter | ~/.config/opencode/skills/commit-crafter/SKILL.md |
| quick edit | quick-executor | ~/.config/opencode/skills/quick-executor/SKILL.md |
| auth, JWT | auth-hardening | .agent/skills/auth-hardening/SKILL.md |
| infra audit | infra-audit | .agent/skills/infra-audit/SKILL.md |
| performance | perf-profiling | .agent/skills/perf-profiling/SKILL.md |
| sdd init | sdd-init | .agent/skills/sdd-init/SKILL.md |
| custom audit | custom-audit | ~/.claude/skills/custom-audit/SKILL.md |
| legacy helper | legacy-helper | ~/.claude/skills/legacy-helper/SKILL.md |

## Compact Rules
| code-review-agent | 4R: Risk/Readability/Reliability/Resilience; evidence gates; actionable fixes |
| commit-crafter | Conventional commits from diff analysis; scopes: feat/fix/chore/refactor |
| quick-executor | Single-file, low-risk, atomic; max 15 lines change |
| auth-hardening | JWT/OAuth/RBAC/CSRF/session; audit + harden flows |
```

### Example 2: Incremental Update (Skill Added)
```bash
# Trigger: installed new skill "container-security" globally
# Registry exists with 9 skills; adds 1, no conflicts
```
**Before:** 9 skills in registry
**After:** 10 skills (container-security added)
**mem_save called:** "Added container-security to registry"

### Example 3: Incremental Update (Skill Removed)
```bash
# Trigger: removed deprecated skill "legacy-helper" from ~/.claude/skills/
# Registry removes entry, compacts rules
```
**Before:** 10 skills including legacy-helper
**After:** 9 skills, legacy-helper removed
**mem_save called:** "Removed legacy-helper from registry"

### Example 4: Cross-Source Deduplication (Project Override)
```bash
# Both global and project have "code-generation" skill
# Global: generic boilerplate generator
# Project: project-tailored with TypeScript + React patterns
```
**Resolution:** Project version wins (more specific)
**Compact rule updated:** From generic to "TypeScript + React scaffolds; follows project conventions"

### Example 5: Empty Registry (No Skills Found)
```bash
# Fresh project, no skills in any scanned directory
# Output: .atl/skill-registry.md with empty tables
```
**Output:**
```
## Skills
| Trigger | Skill | Path |

## Compact Rules
| |

## Conventions
| File | Path |
```

---

## Testing (3)

### Test 1: Scan + Dedupe Happy Path
```bash
# Setup: Create temp dirs with known skills
mkdir -p /tmp/test-global/skill-a /tmp/test-project/skill-a /tmp/test-project/skill-b
echo "trigger: a" > /tmp/test-global/skill-a/SKILL.md
echo "trigger: a" > /tmp/test-project/skill-a/SKILL.md
echo "trigger: b" > /tmp/test-project/skill-b/SKILL.md

# Run registry builder
# Assert: registry has 2 skills (skill-a from project, skill-b)
# Assert: skill-a path points to project version
```

### Test 2: Compact Rules Length Enforcement
```bash
# Input: skill with 50-line verbose rules
# Run: compact-rules function
# Assert: output 5-15 lines
# Assert: no markdown fluff ("## Overview", "### Details" removed)
# Assert: actionable verbs preserved (scan, dedupe, write, persist)
```

### Test 3: Persistence Round-trip
```bash
# Run full registry build
# Assert: .atl/skill-registry.md exists
# Assert: mem_save called with title "Skill registry updated"
# Assert: mem_search("skill registry") returns the observation
# Assert: re-read registry matches memory content
```

---

## Edge Cases (4)

### Edge Case 1: Symlinked Skill Directories
```bash
# ~/.config/opencode/skills/my-skill -> /real/path/skill
# Scanner must resolve symlinks to avoid duplicate entries
# Use fs.realpathSync or equivalent
```

### Edge Case 2: Malformed SKILL.md (Missing Frontmatter)
```bash
# Skill dir exists but SKILL.md has no --- frontmatter
# Behavior: skip with warning, log to mem_save as "discovery"
# Do NOT crash the registry build
```

### Edge Case 3: Circular Symlink in Skill Tree
```bash
# skills/a -> skills/b, skills/b -> skills/a
# Detect via visited set during walk; break cycle; log warning
# Continue scanning other branches
```

### Edge Case 4: Concurrent Registry Writes
```bash
# Two agents call "update skills" simultaneously
# Use file lock (flock, lockfile) or atomic write + rename
# Loser reads winner's registry instead of rebuilding
```

---

## Anti-Patterns
- Include sdd-* sub-skills in registry (they are internal, not invokable)
- Dedupe to global when project has override (project ALWAYS wins)
- Keep stale entries (rebuild on every trigger, don't cache)
- Skip mem_save after update (breaks cross-session recall)
- Compact rules to <5 lines (loses actionable detail)
- Compact rules to >15 lines (becomes noise, not reference)
- Treat _shared as invokable skill (it's internal reference only)

## Refs
skill-graph · skill-testing · skill-improver · opencode-skill-creator · dreaming
