# Golden Prompt Suite — tests/prompts/

Golden prompts for regression-testing skill behavior. One file per skill in the UI/UIX/SEO cluster. Each prompt is a **realistic, trigger-activating user message** — the kind that should route to that skill — plus the expected skill `## Output` shape.

## Purpose (skill-testing Pattern 1)

Protect against silent quality regression during future compressions:
- SEO went 146 → 49 lines with NO regression gate (F5, analysis 2026-08-16)
- Golden prompts make compression changes **verifiable**: run the prompt → assert output shape matches the skill's `## Output` contract

## How it works (runtime harness — requires opencode runtime)

```
for each prompt in tests/prompts/*.md:
  1. LOAD   — inject prompt into session (matches skill trigger)
  2. APPLY  — skill executes (read-only mode: extract Output-shaped line)
  3. VERIFY — assert output matches <skill>/SKILL.md ## Output pattern
```

The static gate (`tests/golden-prompts.Tests.ps1`) verifies suite completeness + trigger coverage **without runtime**. The runtime harness is deferred (R3 infra, see report §Remaining).

## File format

```markdown
# <skill-name> — golden prompt

**Trigger**: <the user message that must activate this skill>

<full user message — realistic, complete task>

**Expected**: <skill Output contract, copied verbatim from SKILL.md>
```

## Suite inventory (10 skills)

| Skill | File | Trigger sample |
|-------|------|----------------|
| baseline-ui | tests/prompts/baseline-ui.md | "this card looks like ui slop, polish it" |
| ui-engine | tests/prompts/ui-engine.md | "build a responsive card grid with CQ" |
| seo | tests/prompts/seo.md | "my page dropped in rankings after the core update" |
| web-quality-audit | tests/prompts/web-quality-audit.md | "audit https://staging.example.com" |
| performance | tests/prompts/performance.md | "my INP is 300ms, speed up the page" |
| performance-tracker | tests/prompts/performance-tracker.md | "score the mobile app and track the trend" |
| accessibility | tests/prompts/accessibility.md | "my form fails WCAG, fix the contrast and keyboard nav" |
| visual-testing | tests/prompts/visual-testing.md | "the header overflows at 375px, run a visual check" |
| vision-analyze | tests/prompts/vision-analyze.md | "capture the page and analyze the ui" |
| image-pipeline | tests/prompts/image-pipeline.md | "convert these images to webp q80" |

## Refs

- Skills: `.agents/skills/{name}/SKILL.md` — `## Output` contract is the verification target
- skill-testing: Pattern 1 (Golden Prompt Suite), Pattern 4 (Token Budget)
- Analysis: `docs/mejoras/2026-08-16-ui-seo-skills-cluster-analisis.md` (F4: 0 suites golden prompts)
