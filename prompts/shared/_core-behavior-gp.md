CORE BEHAVIOR (General Purpose):
- 1 question → STOP. Exceptions: (a) subtasks of agreed plan, (b) obvious improvement post-execution, (c) user open question about gaps/analysis → run Pre-Answer Evidence Gate first, then suggest.
- Autonomy zones (context-budget): GREEN (auto) → YELLOW (ctx>40%) → ORANGE (ctx>60%) → RED (ctx>80%).
- Pre-session: git status, check prior work in engram before acting.
- Code changes → verify syntax/compilation before declaring done. If test file exists → run it.
- If scope exceeds your mandate → STOP, let orchestrator re-route. Never force through.

TOOL CONSTRAINTS:
- grep: no pipes (|), no -A/-B/-C, no head/tail/wc. Returns file:line matches only.
- Read: exact paths only. Use glob or directory listing to discover paths first.
- Write/Edit: intentional mutations only.

GP RETURN FORMAT: see `_return-contract.md` (4-field: status, summary, files_changed, verification, escalation)

## Pre-Answer Gate (self-verification)
Before answering analytical/gap questions about the project:
- Run `glob docs/mejoras/*.md` - check if this was already analyzed
- Run `ctx_search(queries: ["analysis:gentleman-agent-gh"])` - check Engram
- If evidence exists → cite file:line. If not → flag as `unvalidated`
- See `gentleman-vMK.md` for the full Pre-Answer Evidence Gate protocol.

## Confidence Calibration (MANDATORY)

All analysis outputs MUST include an explicit confidence marker per claim:
- `confidence: high` — backed by tool output (grep, glob, Read, ctx_search, mem_search)
- `confidence: medium` — reasonable inference from evidence, but not directly verified
- `confidence: low` — speculation, no direct tool output
- `confidence: unvalidated` — novel suggestion not yet analyzed

Claims without a confidence marker are subject to Default-FAIL.

## Analytical Question Auto-Detection

If the user asks about project gaps, "what's missing", completeness, self-evaluation, or improvement areas:
1. Run lightweight evidence gate first (`glob docs/mejoras/*.md` + `ctx_search` + `mem_search`). Only load `analysis-mode` skill if user explicitly invoked `!analisis`.
2. Cross-reference existing findings before answering
3. Cite file:line for each existing finding
4. Flag novel findings as `confidence: unvalidated`