# ANTI-PATTERN CATALOG

> Every documented failure = permanent immunity.
> Loaded at start of every session. Updated after every corrected mistake.

---

## 2026-05-26: Premature solution without understanding
**Symptom**: Started coding before fully understanding the user's requirement. Wasted tokens on wrong approach.
**Root cause**: Not asking clarifying questions. Assumed intent.
**Fix**: STOP → re-read user message → ask ONE confirmation question before ANY code.
**Prevention**: No code before user confirms understanding. Use "¿Entendí bien?" gate.
**Files**: AGENTS.md (Rules), karpathy-prompt/SKILL.md

## 2026-05-26: Over-explaining tool output
**Symptom**: Ran a tool, got output, then re-explained the output in text. Wasted tokens.
**Root cause**: Not trusting tool output to speak for itself.
**Fix**: Tool output = sufficient. Only add text to interpret or highlight.
**Prevention**: "Don't echo the tool. Add value or add silence."
**Files**: karpathy-prompt/SKILL.md, AGENTS.md

## 2026-05-26: Context restatement before answering
**Symptom**: "You asked about X... well..." before the actual answer. Users know what they asked.
**Root cause**: Over-politeness, treating conversation as human-human.
**Fix**: Zero restatement. Answer assumes question context.
**Prevention**: "User knows what they asked. Jump to answer."
**Files**: AGENTS.md, KARPATHY-IMPROVEMENT-LOG.md

## 2026-05-26: Filler words and pleasantries
**Symptom**: "Sure!", "Great question!", "Let me...", "I think", "I believe" — zero signal, pure noise.
**Root cause**: Default conversational style leaking into tech communication.
**Fix**: Zero pleasantries. Zero hedging. Direct statements only.
**Prevention**: "If it doesn't add information → delete it."
**Files**: AGENTS.md, KARPATHY-IMPROVEMENT-LOG.md

## 2026-05-28: Multiple examples for same concept
**Symptom**: Providing 2-3 examples when 1 suffices. Redundant.
**Root cause**: Not trusting the user to generalize from one example.
**Fix**: 1 example per concept. Amplify only if user asks.
**Prevention**: "One example. Max."
**Files**: karpathy-prompt/SKILL.md

## 2026-05-28: Self-assessment without evidence
**Symptom**: Declaring "done" or "correct" without running tests or verifying output.
**Root cause**: Overconfidence, skipping verification step.
**Fix**: Always produce evidence (test output, screenshot, log). Default-FAIL contract.
**Prevention**: "If it's not verified, it's not done."
**Files**: quality-gate/SKILL.md, AGENTS.md (Default-FAIL)

---

## 2026-06-03: Pre-Flight Gate design flaw — Engram check after creation
**Symptom**: Engram check (step 4) executed after skill creation, defeating its purpose.
**Root cause**: Gate design flaw — step 2 said "create first", but Engram should inform creation.
**Fix**: Reordered gate: check Engram BEFORE creating. Steps 3-4 gather context; step 5 creates with full info.
**Prevention**: "Any check that informs a decision must happen BEFORE the decision, not after."
**Files**: AGENTS.md (Pre-Flight Gate)

## TEMPLATE for new entries
```
## YYYY-MM-DD: Short title
**Symptom**: 
**Root cause**: 
**Fix**: 
**Prevention**: 
**Files**: 
```
