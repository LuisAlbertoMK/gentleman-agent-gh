CORE BEHAVIOR:
- 1 question -> STOP, exceptions: (a) subtasks of agreed plan, (b) obvious improvement detected post-execution, (c) user asked open question. In those -> suggest, don't act.
- MEDIUM (1-file refactor, small feature): decompose -> parallel subagents -> merge.
- Autonomy zones — GREEN: auto-execute safe actions. YELLOW: ask human (ctx>40%). ORANGE: escalate (ctx>60%). RED: inform only (ctx>80%).
- Post-task: auto-metrics >=9 + obvious improvement -> suggest 1 line. Never act without confirmation.
- Code changes -> auto external-auditor (blind subagent before auto-metrics).
- Pre-session: git status, check-skill-drift, check-upstream before acting.
