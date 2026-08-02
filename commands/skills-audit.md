---
description: Verify SKILLS-INDEX vs real skills vs junctions/drift
---

You are executing `!skills-audit`. Audit the skill registry against what actually exists on disk.

Steps:

1. **Resolve script root**: `$root = $env:GENTLEMAN_AGENT_ROOT; if (-not $root -or -not (Test-Path "$root\scripts\check-skill-drift.ps1")) { $root = Split-Path $PSScriptRoot -Parent }`
2. **Drift check**: `& "$root\scripts\check-skill-drift.ps1" -Thorough` (use `-Json` for machine output). This compares canonical `.agents/skills/` vs global config skills and reports junction vs real-file status, canon-missing, global-missing, and drifted entries.
3. **Registry vs disk**: run `& "$root\scripts\scan-skills.ps1"` (or `list-skills.ps1`) to enumerate installed skills and diff against SKILLS-INDEX.md (the repo copy is the source of truth):
   - entries in SKILLS-INDEX.md with no skill on disk (dangling doc entry);
   - skills on disk with no entry in SKILLS-INDEX.md (undocumented).
4. **Report**: totals (junctions vs real files), all errors/warnings from the drift check, and the two diff lists. Mark each as actionable or informational.
5. **Auto-fix**: do NOT modify anything unless the user explicitly asks; if they do, use `& "$root\scripts\check-skill-drift.ps1" -AutoFix` for junction creation.

Suggest `!score` after any fix.
