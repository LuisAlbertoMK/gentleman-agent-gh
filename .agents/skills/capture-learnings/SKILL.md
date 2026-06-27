---
name: capture-learnings
description: "Extract and persist learnings from completed work. Trigger: post-task, pre-commit, session close, !ship pipeline step."
license: Apache-2.0
metadata:
  author: gentleman-vMK
  version: "1.0"
tags: [learning, pipeline, persistence]
triggers: "learnings, capture patterns, post-task, pipeline step, session close, !ship"
---

## Delegates to `session-miner.ps1`
Run `$env:GENTLEMAN_AGENT_ROOT\scripts\session-miner.ps1 -Mode scan -Json` after completing a task or before commit.
Parses the JSON output for new pattern proposals and stores findings in `.learnings/`.

## Pipeline Position
Insert between task completion and quality-gate:
```
Task done → capture-learnings → triple-verify → quality-gate → commit-crafter
```

## Also
- `mem_save` significant decisions/bugfixes to Engram (type=learning/bugfix/decision)
- Stage `.learnings/` files for commit tracking
