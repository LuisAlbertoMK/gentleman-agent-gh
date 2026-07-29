# LEARNING.md — Cross-Session Knowledge for gentleman-agent-gh

> **Purpose**: Durable lessons from prior agent runs. Read on session start, update when you discover something non-obvious.
> **Format**: Newest first. Each entry: date | what was learned | why it matters | evidence.

---

## 2026-07-29 | PEV Gate + Budget constraints added to `_core-behavior-gp.md`
Plan-Execute-Verify (PEV) gate now mandatory for T2+ tasks. Budget constraints (25 tool calls, circuit breaker, 5 min, 15 steps) apply to all executors. Learned from: Harness Engineering (OpenAI Codex), Respan Agent Workflow.

## 2026-07-29 | `gentleman-reviewer` agent created with claude-sonnet-4-6
Dedicated code review agent with read-only tools + task delegation. Separates writer from evaluator (zero shared context). Learned from: LogRocket Harness, Anthropic multi-agent research.

## 2026-07-29 | codebase-memory* added to codex + implementer
codex-auto, codex, implementer-auto, implementer now have graph search access via `codebase-memory*: true`. Needed for convention finding (codex) and multi-file implementation (implementer).

## 2026-07-28 | Pre-Answer Evidence Gate implemented
Before analytical responses: `glob docs/mejoras/*.md` + `ctx_search` + `mem_search`. If finding exists → cite. If novel → flag `unvalidated`. Confidence markers mandatory (`high/medium/low/unvalidated`).

## 2026-07-28 | Orphan skills removed from registry
4 skills removed: analysis-executor, go-testing, skill-creator, sdd-onboard. Their directories didn't exist in `.agents/skills/`. issue-creation merged with decision tree + maintainer workflow.

## 2026-07-24 | Redundancy scan: 0 real dupes across 82 skills
528 unique triggers analyzed. 20 pairs of 2-way overlap (all same-domain vocabulary, 0 true redundancies). Junction drift fixed for all 82 skills.

---

## Template for new entries

```
## YYYY-MM-DD | Short title
What was learned, why it matters, and where it applies. Include file paths if relevant. Source: where the knowledge came from (debug session, research, user feedback).
```
