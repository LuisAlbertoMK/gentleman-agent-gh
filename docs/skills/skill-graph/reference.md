# Skill Graph — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, anti-patterns, troubleshooting, digest, feedback, and auto-improvement details externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/skill-graph/SKILL.md) for the core resolve logic and BFS expansion.

---

## Examples (5)

### 1. Security Audit Task
```powershell
.\scripts\skill-graph.ps1 -Task "security audit JWT authentication"
```
Output: `["auth-hardening", "security-scanner", "llm-security"]` + deps `["lean-context", "best-practices"]`

### 2. New Feature Implementation
```powershell
.\scripts\skill-graph.ps1 -Task "implement user dashboard with realtime updates"
```
Output: `["sdd-design", "sdd-spec", "sdd-tasks", "code-generation"]` + deps `["lean-context", "execution-mode"]`

### 3. Performance Investigation
```powershell
.\scripts\skill-graph.ps1 -Task "slow database queries N+1 problem" -Expand 2
```
Output: `["perf-profiling", "testing-strategy", "data-quality"]` + deps `["command-wrapper", "lean-context", "best-practices"]`

### 4. Documentation Audit
```powershell
.\scripts\skill-graph.ps1 -Task "documentation audit README onboarding"
```
Output: `["docs-audit", "gap-analysis"]` + deps `["project-mapper", "lean-context"]`

### 5. CI/CD Pipeline Setup
```powershell
.\scripts\skill-graph.ps1 -Task "setup GitHub Actions pipeline with tests"
```
Output: `["ci-cd", "quality-gate", "testing-strategy"]` + deps `["command-wrapper", "lean-context", "sdd-verify"]`

---

## Testing Patterns (3)

### 1. Trigger Coverage Test
```powershell
# Verify all skills in registry have at least one trigger matched
$skills = Get-ChildItem .agents/skills -Directory | ForEach-Object { $_.Name }
foreach ($skill in $skills) {
    $md = Get-Content ".agents/skills/$skill/SKILL.md" -Raw
    if ($md -notmatch 'triggers:') { Write-Warning "Missing triggers: $skill" }
}
```

### 2. Dependency Resolution Integrity
```powershell
# Verify BFS expansion doesn't exceed max unique skills (10) and no circular deps
$testTasks = @("security audit", "implement feature", "performance profiling", "documentation audit")
foreach ($task in $testTasks) {
    $result = & .\scripts\skill-graph.ps1 -Task $task -Expand 3 -Format Json | ConvertFrom-Json
    $allSkills = $result.matched + $result.deps
    if ($allSkills.Count -gt 10) { Write-Error "Expansion exceeds 10: $task" }
    # Check for circular refs in expand_chain
    $chain = $result.expand_chain -join '>'
    if ($chain -match '(.+?)>.*\1') { Write-Error "Circular dep detected: $chain" }
}
```

### 3. Digest Budget Compliance
```powershell
# Verify digest output respects token budgets per context zone
$testCases = @(
    @{ Context = 30; Zone = "GREEN"; MaxTokens = 9999 },
    @{ Context = 50; Zone = "YELLOW"; MaxTokens = 300 },
    @{ Context = 85; Zone = "RED"; MaxTokens = 100 }
)
foreach ($tc in $testCases) {
    $digest = Get-SkillDigest -Skills @("perf-profiling","command-wrapper","lean-context") -ContextPercent $tc.Context
    $tokens = Measure-Tokens $digest
    if ($tokens -gt $tc.MaxTokens) { Write-Error "Zone $($tc.Zone) exceeded: $tokens > $($tc.MaxTokens)" }
}
```

---

## Edge Cases (8)

| Scenario | Behavior | Handling |
|----------|----------|----------|
| Empty task string `-Task ""` | Defaults to `"task"` scan | Always pass explicit task; warn in script |
| No skill matches keywords | Returns empty matched array | Suggest broader terms in output |
| Circular dependency chain | BFS capped at 10 unique skills | Log warning, continue with unique set |
| Skill missing `dependencies` field | Treated as no deps | `skill-registry` validates on load |
| Multiple skills match same trigger | All included in matched | Use `-Expand 0` to see only direct matches |
| Context budget unknown (first load) | Assumes GREEN (<40%) | Full skill loaded; no truncation |
| Skill file missing or corrupted | Script errors with path | Validate registry before resolution |

---

## Anti-Patterns (4)

1. **Resolve every task** — Running skill-graph for single-step Q&A or when you already know the exact skill adds overhead without value.
2. **Load full skill in RED zone** — Ignoring digest and loading full skill at >80% context burns tokens; always digest first.
3. **Ignore feedback loop** — Not logging Applied/Effective to Engram means trigger drift goes undetected.
4. **Never update stale triggers** — Triggers that haven't matched in 10+ resolutions should be narrowed or removed.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|------|
| "No skills matched" | Task too vague | Use 2-3 specific terms: "security audit JWT" not "check stuff" |
| Empty deps | No `dependencies` field | Check skill metadata frontmatter |
| Wrong match | Trigger overlap | Narrow task: "python async" vs "python django" disambiguates |
| Same item in loop | Circular dep | Report to skill-registry; BFS capped at 10 unique |
| Empty task (`-Task ""`) | No input | Defaults to `"task"` scan — rarely useful; always pass a real task |

---

## DIGEST

| Context | Strategy | Target |
|---------|----------|--------|
| <40% / first load | Full skill | No limit |
| 40-60% (YELLOW) | Rules + decision tree | ~300 tok |
| >80% (RED) | 1-line + critical rules | ~100 tok |

Always check context % before loading. YELLOW/RED → truncate output.

---

## FEEDBACK
Post-task log to Engram: `title: "Skill resolution: {name}" | Applied: Y/N | Effective: Y/P/N`

---

## AUTO-IMPROVEMENT

| Signal | Action |
|--------|--------|
| Loaded NOT applied | Trigger too broad → narrow |
| Applied NOT effective | Update patterns |
| Same skill 3+ times | Flag heavy → digest more |

---

## When
- Task start (before `skill` call) · Unfamiliar task · Token tight
- NOT: single-step Q&A · already know exact skill

## Refs
session-resume · execution-mode · skill-registry · lean-context