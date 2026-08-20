---
name: workflow-optimizer
description: "Optimize workflow patterns — faster info access, reduced token waste, smarter caching, auto-learning triggers."
triggers: [optimize-workflow, faster-access, token-optimization, workflow-pattern, information-access, fluidez]
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Optimize workflow — info access, token economy, caching, auto-learning triggers.
## Core Principles
1. Info Access: right info, right time. 2. Token Economy: every token earns its place. 3. Auto-Learning: patterns→rules→habits→instinct. 4. Cache Aggressively: compute once, reuse everywhere.
## Speed Patterns
1. **Pre-flight**: `mem_search("<keywords>", limit=3)` → top 3; check skill-graph; no recent error (immune-system). Savings: 2-5K/task.
2. **Lazy loading**: Q&A → karpathy-loop + lean-context (skip sdd-*, judgment-day) | Bug fix → recovery-protocol + immune-system (skip sdd-propose) | Review → code-review-agent + judgment-day (skip sdd-*). Savings: 5-15K/session.
3. **Compression**: L1 (8 msgs/15 calls) -60-70% | L2 (20 msgs/3 L1) decisions+ID -40-50% | L3 (ORANGE>60%) 1-liner+ref -80-90%.
4. **Parallel gather**: >3 files → delegate explore; independent research → parallel; batch reads → single call.
## Auto-Learning Triggers
IF same_fix_2x → ANTI-PATTERN-CATALOG · IF same_error_3x → immune-system · IF user_correction_2x → AGENTS.md rules · IF repeat_workflow_3x → create skill.
Pipeline: Capture (mem_save every decision/bugfix/discovery) → Extract (dreaming on 5th error) → Evaluate (score delta) → Apply (inject next session).
## Information Access
Fast recall: `mem_context` → `mem_search` → `mem_get_observation`. Proactive: project → `mem_search(project=...)`; feature → query; error → `mem_search(type=bugfix)`.
## Reference
Extended details, examples, patterns → docs/skills/workflow-optimizer/reference.md