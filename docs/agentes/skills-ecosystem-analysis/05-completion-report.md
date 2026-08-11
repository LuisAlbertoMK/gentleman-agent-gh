DECISION: Skills ecosystem is well-structured with consistent frontmatter and actionable rules, but 8 SDD skills exceed 3KB size limit, and onboarding docs lack prerequisites.

FILES: SKILLS-INDEX.md, PROTOCOL.md, SHORTCUTS.md, QUICKSTART.md, ARCHITECTURE.md, C:/Users/MK/.config/opencode/skills/sdd-apply/SKILL.md, C:/Users/MK/.config/opencode/skills/metricas/SKILL.md, C:/Users/MK/.config/opencode/skills/execution-mode/SKILL.md

FINDINGS:
| # | Finding | Evidence (file:line) | Confidence | Risk CRITICAL/HIGH/MEDIUM/LOW | Recommendation (1 line) |
|---|---------|----------------------|------------|-------------------------------|--------------------------|
| 1 | 8 SDD skills exceed 3KB size limit (sdd-apply 3.9KB, sdd-archive 4.2KB, etc.) | bash output: 8 files >3KB | high | HIGH | Compress SDD skills to ≤3KB via karpathy-loop. |
| 2 | QUICKSTART.md missing prerequisites (OpenCode installation, PowerShell version) | QUICKSTART.md:22-34 | high | MEDIUM | Add "Prerequisites" section before Step 1. |
| 3 | SHORTCUTS.md references commands/ directory but repo lacks it | SHORTCUTS.md:5 | high | HIGH | Create commands/ dir or update docs to reflect current structure. |
| 4 | Potential overlap: metricas vs auto-metrics (triggers may intersect) | metricas:4-5, auto-metrics not read | medium | MEDIUM | Clarify distinct purposes in skill descriptions. |
| 5 | Potential overlap: vision-analyze vs visual-testing (different tools but similar goals) | vision-analyze:3-4, visual-testing:3-4 | medium | LOW | Add cross-reference in both skills to clarify differentiation. |
| 6 | Potential overlap: execution-mode vs development-mode (different scope) | execution-mode:3-4, development-mode not read | medium | LOW | Ensure triggers don't conflict; document distinct use cases. |
| 7 | SKILLS-INDEX top-20 table missing quality-gate (listed in Quick Groups but not top-20) | SKILLS-INDEX:11-30 | medium | LOW | Add quality-gate to top-20 if daily-use. |
| 8 | ARCHITECTURE.md mentions 91 scripts but QUICKSTART.md doesn't reference script layer | ARCHITECTURE.md:9, QUICKSTART.md:73-78 | medium | LOW | Add brief mention of scripts in QUICKSTART next steps. |
| 9 | Shortcuts overload: 30+ shortcuts may overwhelm new users | SHORTCUTS.md:9-105 | medium | MEDIUM | Group shortcuts by frequency; highlight top-5 in QUICKSTART. |
| 10 | Dead links possible in PROTOCOL.md references to scripts | PROTOCOL.md:17,19 | medium | MEDIUM | Verify all script references exist. |
| 11 | Agent UX routing transparency not documented | N/A | low | LOW | Add routing example in PROTOCOL.md. |
| 12 | Mood/personality system (savePersonality) usefulness unclear | N/A | low | LOW | Evaluate if savePersonality adds value; consider removal if unused. |

NUANCE: Skills ecosystem is mature with consistent frontmatter (name/description/triggers) and actionable rules (decision trees, anti-patterns). Overlaps are mostly complementary (metricas=delta measurement, auto-metrics=self-evaluation). SDD skills are the only size violators. Docs are coherent across AGENTS.md/PROTOCOL.md/SHORTCUTS.md/ARCHITECTURE.md. Onboarding flow is solid but assumes OpenCode already installed. Commands/ directory discrepancy needs resolution.