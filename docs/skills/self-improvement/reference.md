# self-improvement — Reference Materials

> **Externalized from** .agents/skills/self-improvement/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.

## Examples (2)

### Example 1: Macro Cycle Trigger
```powershell
& .\scripts\run-improvement-cycle.ps1    # 1st: READ CYCLE.md
# → Pre-Flight → Diagnose → SkillOpt Gate (per fix) → Verify → Learn → Propagate → Epoch Review
# → exit: inter>=30 + no dim<9.0 → "SUCCESS" | 7d → "STOP" | score -0.5 → revert
```

### Example 2: Per-Task Micro-Loop (after fixing empty catch blocks)
1. **Observe**: Write-Debug added to 3 catch blocks
2. **Reflect**: Why empty? Copied from template without thinking
3. **Optimize**: Add immune-system rule: "empty catch → Write-Debug with context"
4. **Apply**: Template now includes Write-Debug by default
5. **Score**: Run `!score` — delta = +0.2 (caught earlier in review)
→ Same error 2x → catalog entry. 3x → AGENTS.md rule.

---

## Testing Patterns (3)

1. `& .\scripts\score-auto.ps1 -Json` → composite BEFORE/AFTER: target delta ≥ +0.1, no dim ≤ -0.3
2. SkillOpt gate per fix: SKILL.md lines ≤20% / size <3KB; `.ps1` parse via `[System.Management.Automation.Language.Parser]::ParseFile()` → 0 errors
3. Protected-file touch (security-scanner/quality-gate/auto-metrics/external-auditor/immune-system/ANTI-PATTERN-CATALOG/.project.json)? → `!audit` MUST pass BEFORE commit — NOT optional

---

## Anti-Patterns (4)

| Pattern | Why It Fails | Correct Approach |
|---------|--------------|------------------|
| Skip learning extraction | Loses institutional knowledge | Capture root cause + pattern every task |
| Bump score without data | Metrics become meaningless | Only delta from verified measurements |
| Ignore CYCLE.md guardrails | Violates budget/exit rules | Read CYCLE.md FIRST every cycle |
| Never prune unused skills | Bloats registry, wastes tokens | Archive unused skills per epoch review |
| Same fix fails 3x without abort | Definition of insanity | 3rd failure → escalate to human |

---

## Quick Reference: Protected Files (Require `!audit` Before Commit)

- `security-scanner` skill
- `quality-gate` skill
- `auto-metrics` skill
- `external-auditor` skill
- `immune-system` skill
- `ANTI-PATTERN-CATALOG.md`
- `.project.json`

---

## Quick Reference: Micro-Loop Triggers

| Trigger | Action |
|---------|--------|
| After every task (≥3 tools) | Observe→Reflect→Optimize→Apply |
| Session end | Flush learning buffers |
| Error recovery | Run `recovery-protocol` skill |
| Frustration signals detected | Run `recovery-protocol` skill |

---

## Quick Reference: Escalation Thresholds

| Repetition | Action |
|------------|--------|
| 2x same error | Catalog in immune-system |
| 3x same error | Add AGENTS.md rule |
| Complex workflow pattern | Create skill via `opencode-skill-creator` |
| Gotcha discovered | Document in relevant skill |

(End of file)
