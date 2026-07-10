# Engram Persistent Memory — Protocol

Save after: arch decisions · bugs fixed · tool/lib choices · config changes · gotchas · patterns · user preferences.
- Diff topics → reuse `topic_key`. Same key → upsert. Unsure → `mem_suggest_topic_key`.
- Critical saves immediate, minor accumulate → flush at session end.

## Memory Search
On "remember"/"recall": 1) `mem_context` 2) `mem_search` 3) `mem_get_observation`.
Proactive: known-area work · unfamiliar topic · first msg references project.
**Task injection**: Before ANY non-trivial task → extract 3-5 keywords, `mem_search(query="<keywords>", type="bugfix|pattern|decision", limit=3)`, inject top 3 into context as "recordatorio: esto ya pasó".

## Dreaming (periodic)
`mem_search(type="error|bugfix")`. Same error 2x→catalog. 3x→AGENTS.md rule.
Auto: `session-miner.ps1 -Mode scan -Json` every 5th error/bugfix.

## Auto-Clean
Delete `$env:TEMP\opencode\` >24h at session start.

## Session Close (mandatory)
`!close` → `mem_session_summary` (Goal/Discoveries/Accomplished/Next/Files). Scoring via `!score`/`!dream`. Mandatory unless pure chat.

## After Compaction
1) `mem_session_summary` 2) `mem_context` 3) Continue.
