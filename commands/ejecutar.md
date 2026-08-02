---
description: Execute analysis findings with parallel subagents (run after !analisis)
---

You are executing `!ejecutar`. Execute the actionable findings from the most recent `!analisis` report using parallel subagents.

Steps:

1. **Locate the source**: `glob docs/mejoras/*-analisis.md` → pick the latest. If a resume state exists (`docs/mejoras/<project>-execution-state.json`), load it and continue where the previous run stopped instead of restarting.
2. **Extract findings**: pull the Recommendations table. Exclude items already marked done or explicitly plan-only.
3. **Scope guard**: if >15 findings, execute top-15 by risk; rest go to an appendix.
4. **Delegate in parallel**: one subagent per finding (specialists matching each finding's dimension). Each subagent receives:
   - the finding, its consensus class, risk level, and affected files;
   - strict isolation: one finding per subagent, no cross-conversation;
   - verification requirement: must run the relevant tests/lint for its change before reporting.
5. **Collect results**: for each finding record status (done / skipped / failed), files changed, tests run, and any new risk it introduced.
6. **Write the report**: `docs/mejoras/<project>-execution-report.md` with table `|Finding|Status|Files|Verification|Notes|`. Persist the execution-state JSON so a later `!ejecutar` can resume.
7. **Close**: suggest `!score` to measure the impact. Do NOT commit unless the user asks.

If no recent analysis exists, tell the user to run `!analisis` first and STOP.
