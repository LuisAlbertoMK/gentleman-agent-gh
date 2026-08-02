---
description: Context reduction campaign — dedup AGENTS.md, prompts, docs, SKILLS-INDEX; archive stale
---

You are executing `!ctx-lite`. Run a complete context-reduction campaign over the agent config and docs.

Steps:

1. **Measure baseline**: resolve root as in `!score`, then run `& "$root\scripts\token-count.ps1"` (or `tokenize-all.ps1`) on AGENTS.md, prompts, SKILLS-INDEX.md, and docs. Record per-file tokens.
2. **Load skills**: `karpathy-loop` (progressive compression) and `lean-context` (compression levels) for guidance.
3. **AGENTS.md**: remove duplicated sections, fold repeated rules into tables, drop prose that merely restates a skill. Preserve persona, navigation, hard rules, and the engram/agent protocol stubs.
4. **SKILLS-INDEX.md**: dedup entries and collapse redundant trigger rows.
5. **Prompts**: replace boilerplate repeated across prompts with references to the shared `prompts/shared/` files.
6. **Docs**: archive stale `docs/mejoras/*.md` older than the project retention window into `docs/mejoras/archive/` instead of deleting them.
7. **Re-measure**: report before/after tokens per file and the % reduction.
8. **Verify**: run `& "$root\scripts\cross-ref-check.ps1"` — no broken references introduced.

Do NOT touch AGENTS.md if the environment marks it write-protected (report it and continue with the rest).
